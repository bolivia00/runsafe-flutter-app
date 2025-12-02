import '../entities/waypoint.dart';

/// Interface de repositório para a entidade Waypoint.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que Waypoint possui métodos de conversão robustos (fromJson/toJson).
/// - Waypoint não tem id explícito: use timestamp ou hash de coordenadas como identificador.
/// - Ao implementar esta interface, adicione logs nos métodos principais para facilitar debug.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está "mounted" antes de chamar setState.
/// - Para persistência local, considere usar SharedPreferences para dados simples ou SQLite para dados complexos.
abstract class WaypointsRepository {
  
  // Render inicial: carrega dados do cache local para exibição rápida
  // Útil para mostrar dados imediatamente enquanto syncFromServer() executa em background
  /// Carrega waypoints do cache local para render inicial rápido
  Future<List<Waypoint>> loadFromCache();

  // Sincronização: busca dados do servidor (apenas registros >= lastSync)
  // Retorna a quantidade de registros que foram alterados (inseridos/atualizados)
  // Implementação deve atualizar o cache local automaticamente
  /// Sincroniza com servidor e retorna quantidade de mudanças
  Future<int> syncFromServer();

  // Listagem completa: normalmente retorna do cache após sync
  // Use este método para a listagem principal da UI
  /// Lista todos os waypoints (geralmente do cache)
  Future<List<Waypoint>> listAll();

  // Destaques: filtra waypoints "importantes" ou "featured"
  // Exemplo: waypoints mais recentes ou de rotas favoritas
  /// Lista waypoints em destaque (ex: mais recentes)
  Future<List<Waypoint>> listFeatured();

  // Busca por ID: útil para detalhes ou edição
  // ID seria timestamp convertido para String ou hash das coordenadas
  // Retorna null se não encontrado
  /// Busca waypoint por ID (retorna null se não encontrado)
  Future<Waypoint?> getById(String id);
  
  // CRUD local: adiciona waypoint ao cache e agenda push no próximo sync
  /// Adiciona novo waypoint ao cache local
  Future<void> add(Waypoint waypoint);
  
  // CRUD local: atualiza waypoint no cache e agenda push no próximo sync
  /// Atualiza waypoint existente no cache local
  Future<void> update(Waypoint waypoint);
  
  // CRUD local: remove waypoint do cache e agenda push no próximo sync
  /// Remove waypoint do cache local (filtra por timestamp)
  Future<void> delete(String timestampIso);
}

/*
// Exemplo de uso:

// 1. Criar implementação
class WaypointsRepositoryImpl implements WaypointsRepository {
  final WaypointsLocalDao _localDao;
  final WaypointsRemoteDataSource _remoteDataSource;
  
  WaypointsRepositoryImpl(this._localDao, this._remoteDataSource);
  
  @override
  Future<List<Waypoint>> loadFromCache() async {
    return await _localDao.getAll();
  }
  
  @override
  Future<int> syncFromServer() async {
    final lastSync = await _localDao.getLastSyncDate();
    final newWaypoints = await _remoteDataSource.fetchSince(lastSync);
    await _localDao.upsertAll(newWaypoints);
    return newWaypoints.length;
  }
  
  @override
  Future<List<Waypoint>> listFeatured() async {
    final all = await _localDao.getAll();
    // Retorna os 10 waypoints mais recentes
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(10).toList();
  }
  
  @override
  Future<Waypoint?> getById(String id) async {
    // ID pode ser timestamp.toIso8601String() ou hash das coordenadas
    final all = await _localDao.getAll();
    return all.firstWhere(
      (w) => w.timestamp.toIso8601String() == id,
      orElse: () => null,
    );
  }
  
  // ... implementar outros métodos
}

// 2. Usar no Provider/ViewModel
class WaypointsProvider extends ChangeNotifier {
  final WaypointsRepository _repository;
  List<Waypoint> _waypoints = [];
  bool _loading = false;
  
  WaypointsProvider(this._repository);
  
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    
    // Carrega cache primeiro (rápido)
    _waypoints = await _repository.loadFromCache();
    notifyListeners();
    
    // Sincroniza em background
    await _repository.syncFromServer();
    _waypoints = await _repository.listAll();
    
    _loading = false;
    notifyListeners();
  }
}

// 3. Para testes, criar mock
class MockWaypointsRepository implements WaypointsRepository {
  @override
  Future<List<Waypoint>> loadFromCache() async {
    return [
      Waypoint(
        latitude: -23.5505,
        longitude: -46.6333,
        timestamp: DateTime.now(),
      ),
    ];
  }
  
  @override
  Future<int> syncFromServer() async => 0;
  
  // ... implementar outros métodos retornando dados fixos
}

// Checklist de erros comuns e como evitar:
// - Waypoint sem ID explícito: use timestamp.toIso8601String() ou hash de coordenadas
// - Erro de validação de coordenadas: garanta -90<=lat<=90 e -180<=lng<=180
// - Falha ao atualizar UI após sync: sempre chame notifyListeners() após mudar estado
// - Dados não aparecem após sync: verifique se loadFromCache() está lendo do local correto
// - Memory leak: sempre dispose controllers e cancel subscriptions
// - Context usado após unmount: verifique 'mounted' antes de usar context em callbacks assíncronos

// Referências úteis:
// - Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
// - Repository Pattern: https://martinfowler.com/eaaCatalog/repository.html
*/

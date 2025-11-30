import '../entities/running_route.dart';

/// Interface de repositório para a entidade RunningRoute.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que RunningRoute possui métodos de conversão robustos (fromJson/toJson).
/// - RunningRoute depende de Waypoint: garanta serialização/desserialização correta da lista.
/// - Ao implementar esta interface, adicione logs nos métodos principais para facilitar debug.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está "mounted" antes de chamar setState.
/// - Para persistência local, considere usar SharedPreferences para dados simples ou SQLite para dados complexos.
abstract class RunningRoutesRepository {
  
  // Render inicial: carrega dados do cache local para exibição rápida
  // Útil para mostrar dados imediatamente enquanto syncFromServer() executa em background
  /// Carrega rotas do cache local para render inicial rápido
  Future<List<RunningRoute>> loadFromCache();

  // Sincronização: busca dados do servidor (apenas registros >= lastSync)
  // Retorna a quantidade de registros que foram alterados (inseridos/atualizados)
  // Implementação deve atualizar o cache local automaticamente
  /// Sincroniza com servidor e retorna quantidade de mudanças
  Future<int> syncFromServer();

  // Listagem completa: normalmente retorna do cache após sync
  // Use este método para a listagem principal da UI
  /// Lista todas as rotas (geralmente do cache)
  Future<List<RunningRoute>> listAll();

  // Destaques: filtra rotas "importantes" ou "featured"
  // Exemplo: rotas favoritas, mais populares, ou recentemente usadas
  /// Lista rotas em destaque (ex: favoritas, populares)
  Future<List<RunningRoute>> listFeatured();

  // Busca por ID: útil para detalhes ou edição
  // Retorna null se não encontrado
  /// Busca rota por ID (retorna null se não encontrado)
  Future<RunningRoute?> getById(String id);
}

/*
// Exemplo de uso:

// 1. Criar implementação
class RunningRoutesRepositoryImpl implements RunningRoutesRepository {
  final RunningRoutesLocalDao _localDao;
  final RunningRoutesRemoteDataSource _remoteDataSource;
  
  RunningRoutesRepositoryImpl(this._localDao, this._remoteDataSource);
  
  @override
  Future<List<RunningRoute>> loadFromCache() async {
    return await _localDao.getAll();
  }
  
  @override
  Future<int> syncFromServer() async {
    final lastSync = await _localDao.getLastSyncDate();
    final newRoutes = await _remoteDataSource.fetchSince(lastSync);
    await _localDao.upsertAll(newRoutes);
    return newRoutes.length;
  }
  
  @override
  Future<List<RunningRoute>> listFeatured() async {
    final all = await _localDao.getAll();
    // Exemplo: retorna rotas marcadas como favoritas
    return all.where((route) => route.isFavorite).toList();
  }
  
  // ... implementar outros métodos
}

// 2. Usar no Provider/ViewModel
class RunningRoutesProvider extends ChangeNotifier {
  final RunningRoutesRepository _repository;
  List<RunningRoute> _routes = [];
  bool _loading = false;
  
  RunningRoutesProvider(this._repository);
  
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    
    // Carrega cache primeiro (rápido)
    _routes = await _repository.loadFromCache();
    notifyListeners();
    
    // Sincroniza em background
    await _repository.syncFromServer();
    _routes = await _repository.listAll();
    
    _loading = false;
    notifyListeners();
  }
}

// 3. Para testes, criar mock
class MockRunningRoutesRepository implements RunningRoutesRepository {
  @override
  Future<List<RunningRoute>> loadFromCache() async {
    return [
      RunningRoute(
        id: '1',
        name: 'Rota Parque Ibirapuera',
        waypoints: [
          Waypoint(latitude: -23.5505, longitude: -46.6333, timestamp: DateTime.now()),
          Waypoint(latitude: -23.5515, longitude: -46.6343, timestamp: DateTime.now()),
        ],
      ),
    ];
  }
  
  @override
  Future<int> syncFromServer() async => 0;
  
  // ... implementar outros métodos retornando dados fixos
}

// Checklist de erros comuns e como evitar:
// - Erro ao serializar List<Waypoint>: garanta que Waypoint também tem fromJson/toJson
// - Rota sem waypoints: valide no construtor que lista não está vazia
// - Falha ao atualizar UI após sync: sempre chame notifyListeners() após mudar estado
// - Dados não aparecem após sync: verifique se loadFromCache() está lendo do local correto
// - Memory leak: sempre dispose controllers e cancel subscriptions
// - Context usado após unmount: verifique 'mounted' antes de usar context em callbacks assíncronos

// Referências úteis:
// - Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
// - Repository Pattern: https://martinfowler.com/eaaCatalog/repository.html
*/

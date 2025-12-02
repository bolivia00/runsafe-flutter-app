import '../entities/safety_alert.dart';

/// Interface de repositório para a entidade SafetyAlert.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que SafetyAlert possui métodos de conversão robustos (fromJson/toJson).
/// - Ao implementar esta interface, adicione logs nos métodos principais para facilitar debug.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está "mounted" antes de chamar setState.
/// - Para persistência local, considere usar SharedPreferences para dados simples ou SQLite para dados complexos.
abstract class SafetyAlertsRepository {
  
  // Render inicial: carrega dados do cache local para exibição rápida
  // Útil para mostrar dados imediatamente enquanto syncFromServer() executa em background
  /// Carrega alertas do cache local para render inicial rápido
  Future<List<SafetyAlert>> loadFromCache();

  // Sincronização: busca dados do servidor (apenas registros >= lastSync)
  // Retorna a quantidade de registros que foram alterados (inseridos/atualizados)
  // Implementação deve atualizar o cache local automaticamente
  /// Sincroniza com servidor e retorna quantidade de mudanças
  Future<int> syncFromServer();

  // Listagem completa: normalmente retorna do cache após sync
  // Use este método para a listagem principal da UI
  /// Lista todos os alertas (geralmente do cache)
  Future<List<SafetyAlert>> listAll();

  // Destaques: filtra alertas "importantes" ou "featured"
  // Exemplo: alertas com severidade >= 4 ou tipos específicos
  /// Lista alertas em destaque (ex: alta severidade)
  Future<List<SafetyAlert>> listFeatured();

  // Busca por ID: útil para detalhes ou edição
  // Retorna null se não encontrado
  /// Busca alerta por ID (retorna null se não encontrado)
  Future<SafetyAlert?> getById(String id);
  
  // CRUD local: adiciona alerta ao cache e agenda push no próximo sync
  /// Adiciona novo alerta ao cache local
  Future<void> add(SafetyAlert alert);
  
  // CRUD local: atualiza alerta no cache e agenda push no próximo sync
  /// Atualiza alerta existente no cache local
  Future<void> update(SafetyAlert alert);
  
  // CRUD local: remove alerta do cache e agenda push no próximo sync
  /// Remove alerta do cache local
  Future<void> delete(String id);
}

/*
// Exemplo de uso:

// 1. Criar implementação
class SafetyAlertsRepositoryImpl implements SafetyAlertsRepository {
  final SafetyAlertsLocalDao _localDao;
  final SafetyAlertsRemoteDataSource _remoteDataSource;
  
  SafetyAlertsRepositoryImpl(this._localDao, this._remoteDataSource);
  
  @override
  Future<List<SafetyAlert>> loadFromCache() async {
    return await _localDao.getAll();
  }
  
  @override
  Future<int> syncFromServer() async {
    final lastSync = await _localDao.getLastSyncDate();
    final newAlerts = await _remoteDataSource.fetchSince(lastSync);
    await _localDao.upsertAll(newAlerts);
    return newAlerts.length;
  }
  
  @override
  Future<List<SafetyAlert>> listFeatured() async {
    final all = await _localDao.getAll();
    return all.where((alert) => alert.severity >= 4).toList();
  }
  
  // ... implementar outros métodos
}

// 2. Usar no Provider/ViewModel
class SafetyAlertsProvider extends ChangeNotifier {
  final SafetyAlertsRepository _repository;
  List<SafetyAlert> _alerts = [];
  bool _loading = false;
  
  SafetyAlertsProvider(this._repository);
  
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    
    // Carrega cache primeiro (rápido)
    _alerts = await _repository.loadFromCache();
    notifyListeners();
    
    // Sincroniza em background
    await _repository.syncFromServer();
    _alerts = await _repository.listAll();
    
    _loading = false;
    notifyListeners();
  }
}

// 3. Para testes, criar mock
class MockSafetyAlertsRepository implements SafetyAlertsRepository {
  @override
  Future<List<SafetyAlert>> loadFromCache() async {
    return [
      SafetyAlert(
        id: '1', 
        description: 'Buraco grande', 
        type: AlertType.pothole,
        timestamp: DateTime.now(),
        severity: 5,
      ),
    ];
  }
  
  @override
  Future<int> syncFromServer() async => 0;
  
  // ... implementar outros métodos retornando dados fixos
}

// Checklist de erros comuns e como evitar:
// - Erro de conversão de tipos (enum): garanta que fromJson/toJson converte corretamente AlertType
// - Falha ao atualizar UI após sync: sempre chame notifyListeners() após mudar estado
// - Dados não aparecem após sync: verifique se loadFromCache() está lendo do local correto
// - Memory leak: sempre dispose controllers e cancel subscriptions
// - Context usado após unmount: verifique 'mounted' antes de usar context em callbacks assíncronos

// Referências úteis:
// - Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
// - Repository Pattern: https://martinfowler.com/eaaCatalog/repository.html
*/

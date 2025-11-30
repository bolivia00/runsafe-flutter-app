import '../entities/weekly_goal.dart';

/// Interface de repositório para a entidade WeeklyGoal.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que WeeklyGoal possui métodos de conversão robustos (fromJson/toJson).
/// - Ao implementar esta interface, adicione logs nos métodos principais para facilitar debug.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está "mounted" antes de chamar setState.
/// - Para persistência local, considere usar SharedPreferences para dados simples ou SQLite para dados complexos.
abstract class WeeklyGoalsRepository {
  
  // Render inicial: carrega dados do cache local para exibição rápida
  // Útil para mostrar dados imediatamente enquanto syncFromServer() executa em background
  /// Carrega metas do cache local para render inicial rápido
  Future<List<WeeklyGoal>> loadFromCache();

  // Sincronização: busca dados do servidor (apenas registros >= lastSync)
  // Retorna a quantidade de registros que foram alterados (inseridos/atualizados)
  // Implementação deve atualizar o cache local automaticamente
  /// Sincroniza com servidor e retorna quantidade de mudanças
  Future<int> syncFromServer();

  // Listagem completa: normalmente retorna do cache após sync
  // Use este método para a listagem principal da UI
  /// Lista todas as metas (geralmente do cache)
  Future<List<WeeklyGoal>> listAll();

  // Destaques: filtra metas "em progresso" ou "featured"
  // Exemplo: metas com 0% < progresso < 100%
  /// Lista metas em destaque (ex: em progresso)
  Future<List<WeeklyGoal>> listFeatured();

  // Busca por ID: útil para detalhes ou edição
  // Retorna null se não encontrado
  /// Busca meta por ID (retorna null se não encontrado)
  Future<WeeklyGoal?> getById(String id);
}

/*
// Exemplo de uso:

// 1. Criar implementação
class WeeklyGoalsRepositoryImpl implements WeeklyGoalsRepository {
  final WeeklyGoalsLocalDao _localDao;
  final WeeklyGoalsRemoteDataSource _remoteDataSource;
  
  WeeklyGoalsRepositoryImpl(this._localDao, this._remoteDataSource);
  
  @override
  Future<List<WeeklyGoal>> loadFromCache() async {
    return await _localDao.getAll();
  }
  
  @override
  Future<int> syncFromServer() async {
    final lastSync = await _localDao.getLastSyncDate();
    final newGoals = await _remoteDataSource.fetchSince(lastSync);
    await _localDao.upsertAll(newGoals);
    return newGoals.length;
  }
  
  // ... implementar outros métodos
}

// 2. Usar no Provider/ViewModel
class WeeklyGoalsProvider extends ChangeNotifier {
  final WeeklyGoalsRepository _repository;
  List<WeeklyGoal> _goals = [];
  bool _loading = false;
  
  WeeklyGoalsProvider(this._repository);
  
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    
    // Carrega cache primeiro (rápido)
    _goals = await _repository.loadFromCache();
    notifyListeners();
    
    // Sincroniza em background
    await _repository.syncFromServer();
    _goals = await _repository.listAll();
    
    _loading = false;
    notifyListeners();
  }
}

// 3. Para testes, criar mock
class MockWeeklyGoalsRepository implements WeeklyGoalsRepository {
  @override
  Future<List<WeeklyGoal>> loadFromCache() async {
    return [
      WeeklyGoal(id: '1', userId: 'test', targetKm: 10.0, currentKm: 5.0),
    ];
  }
  
  @override
  Future<int> syncFromServer() async => 0;
  
  // ... implementar outros métodos retornando dados fixos
}

// Checklist de erros comuns e como evitar:
// - Erro de conversão de tipos (id como int vs String): padronize no fromJson/toJson
// - Falha ao atualizar UI após sync: sempre chame notifyListeners() após mudar estado
// - Dados não aparecem após sync: verifique se loadFromCache() está lendo do local correto
// - Memory leak: sempre dispose controllers e cancel subscriptions
// - Context usado após unmount: verifique 'mounted' antes de usar context em callbacks assíncronos

// Referências úteis:
// - Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
// - Repository Pattern: https://martinfowler.com/eaaCatalog/repository.html
*/

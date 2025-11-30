# Prompt: Gerar interface abstrata do repositório para Waypoint

> **Este prompt foi adaptado do prompt genérico 14_providers_repository_prompt.md para a entidade Waypoint.**

## Objetivo

Gerar um arquivo Dart contendo **apenas a interface (classe abstrata)** do repositório para a entidade `Waypoint`, seguindo as convenções do projeto e com comentários didáticos.

## Contexto e estilo

- Projeto Flutter com Clean Architecture
- Entidade localizada em: `lib/features/routes/domain/entities/waypoint.dart`
- Use import relativo: `../entities/waypoint.dart`
- Inclua comentários explicativos didáticos
- Inclua exemplo de uso ao final (em comentário)

## Parâmetros

- **ENTITY**: `Waypoint`
- **SUFFIX**: `Waypoints`
- **DEST_DIR**: `lib/features/routes/domain/repositories/`
- **IMPORT_PATH**: `../entities/waypoint.dart`

## Arquivo fonte (referência)

Entidade: `lib/features/routes/domain/entities/waypoint.dart`
- Classe: `Waypoint`
- Campos:
  - `latitude: double` (-90 a 90)
  - `longitude: double` (-180 a 180)
  - `timestamp: DateTime`

**Observação:** Waypoint não possui `id` explícito. Pode usar timestamp convertido para String ou hash das coordenadas como identificador.

## Assinaturas exatas da interface

O repositório `WaypointsRepository` deve conter os seguintes métodos:

1. `Future<List<Waypoint>> loadFromCache();`
   - Render inicial rápido a partir do cache local
   - Usado para exibir dados imediatamente enquanto sincroniza

2. `Future<int> syncFromServer();`
   - Sincronização incremental com servidor (>= lastSync)
   - Retorna quantos registros mudaram
   - Atualiza cache local automaticamente

3. `Future<List<Waypoint>> listAll();`
   - Listagem completa (normalmente do cache após sync)
   - Retorna todos os waypoints

4. `Future<List<Waypoint>> listFeatured();`
   - Destaques/waypoints importantes (filtrados por critério específico)
   - Exemplo: waypoints mais recentes ou de rotas favoritas

5. `Future<Waypoint?> getById(String id);`
   - Busca direta por ID no cache
   - ID seria timestamp convertido para String ou hash das coordenadas
   - Retorna null se não encontrado

## Regras e restrições

1. Arquivo contém **somente** a interface abstrata e o import da entidade
2. Não inclua implementações, utilitários ou pacotes externos
3. Cada método tem docstring em português + comentário explicativo
4. Preserve tipos exatos: `Future<List<Waypoint>>`, `Future<Waypoint?>`
5. Use import relativo: `import '../entities/waypoint.dart';`
6. Inclua comentário introdutório no topo do arquivo
7. Inclua bloco de exemplo de uso ao final (comentado)

## Formato de saída esperado

Arquivo: `lib/features/routes/domain/repositories/waypoints_repository.dart`

```dart
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
```

## Instruções de execução

1. Criar arquivo em `lib/features/routes/domain/repositories/waypoints_repository.dart`
2. Copiar o código acima mantendo exatamente a estrutura
3. Verificar que o import relativo está correto
4. Validar com `flutter analyze`

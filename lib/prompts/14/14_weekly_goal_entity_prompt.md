# Prompt: Gerar implementação e artefatos para a entidade WeeklyGoal

Contexto:
- Projeto Flutter com arquitetura em camadas (Clean Architecture).
- Convenção: código compartilhado em `lib/core/*`, features em `lib/features/<feature>/...`.
- Serviço de armazenamento local existente: `StorageService` em `lib/core/services/`.
- Estado usa `Provider` (ChangeNotifier) para a camada de apresentação.

Arquivo fonte (referência): `lib/features/goals/domain/entities/weekly_goal.dart`
Resumo da entidade (extraída do arquivo):
- Classe: `WeeklyGoal`
- Campos:
  - `id: String` (UUID gerado por padrão se não fornecido)
  - `userId: String` (padrão `'default-user'`)
  - `targetKm: double` (required; deve ser > 0)
  - `currentKm: double` (padrão `0.0`; >= 0)
- Validações:
  - `targetKm > 0`
  - `currentKm >= 0`
- Métodos / lógica de domínio:
  - `double get progressPercentage` — retorna `currentKm / targetKm` limitado entre 0.0 e 1.0.
  - `void addRun(double km)` — adiciona quilômetros ao `currentKm` (ignorar números negativos).

Objetivo deste prompt:
Gere, com base na entidade acima, os artefatos necessários para integrar `WeeklyGoal` na camada de dados e apresentação do projeto, seguindo as convenções do repositório.

Saídas esperadas (genere cada item como arquivos Dart separados; indique caminho sugerido e código completo):

1) Data transfer / persistence
- `lib/features/goals/data/models/weekly_goal_model.dart`
  - Classe `WeeklyGoalModel` com `fromJson`/`toJson`, conversão `toEntity()` e `fromEntity(WeeklyGoal)`.
  - Use tipos primitivos e evite dependências desnecessárias.
  - Inclua `equatable`-like `==` e `hashCode` ou `override` simples para igualdade.

2) DAO local (persistência simples usando `StorageService`)
- `lib/features/goals/data/datasources/weekly_goals_local_dao.dart`
  - Implementa métodos: `Future<void> save(WeeklyGoal goal)`, `Future<List<WeeklyGoal>> loadAllForUser(String userId)`, `Future<void> delete(String id)`.
  - Use `StorageService` (p.ex. `storageService.setString(key, json)` / `getString`) — mostre as chamadas e a chave usada (`weekly_goals:<userId>` ou similar).
  - Serialização: liste e armazene uma lista JSON.

3) Repository (contrato + implementação)
- `lib/features/goals/domain/repositories/weekly_goals_repository.dart` (interface)
  - Métodos: `Future<void> add(WeeklyGoal goal)`, `Future<List<WeeklyGoal>> listForUser(String userId)`, `Future<void> remove(String id)`.

- `lib/features/goals/data/repositories/weekly_goals_repository_impl.dart`
  - Implementa a interface usando o `weekly_goals_local_dao`.
  - Trate erros simples com `try/catch` e lance exceções específicas ou rethrow.

4) Provider / ChangeNotifier
- `lib/features/goals/presentation/providers/weekly_goals_provider.dart`
  - `WeeklyGoalsProvider extends ChangeNotifier`
  - Exponha: `List<WeeklyGoal> items`, `bool loading`, `Future<void> load(String userId)`, `Future<void> addRunForGoal(String id, double km)` (usa repository.add / update), `Future<void> addGoal(WeeklyGoal goal)`, `Future<void> remove(String id)`.
  - Ao atualizar um goal (p.ex. `addRunForGoal`) atualize o modelo em memória e chame `notifyListeners()`.

5) Tests unitários sugeridos
- `test/features/goals/domain/entities/weekly_goal_test.dart`:
  - Teste `progressPercentage` com valores limite (0, >target, normal).
  - Teste `addRun` não aceitar negativo e incrementar corretamente.

- `test/features/goals/data/models/weekly_goal_model_test.dart`:
  - Round-trip `entity -> model -> json -> model -> entity` preserva campos e igualdade.

6) Exemplos de uso / snippets
- Exemplo curto mostrando como criar uma `WeeklyGoal`, adicionar corrida e salvar via repository.

Regras e convenções a seguir:
- Use `package:runsafe/...` para imports quando necessário (p.ex. `package:runsafe/features/goals/...`), mas prefira caminhos relativos dentro da feature quando for código local.
- Coloque código compartilhado (StorageService, utils) em `lib/core/...` — suponha que `StorageService` já exista e seja injetável.
- Siga as práticas de Clean Architecture: domain <-> data <-> presentation separadas por pastas.
- Use `const` onde aplicável e verifique `mounted` apenas na UI (este prompt não pede UI direta além do Provider).
- Não dependa de pacotes não declarados; se sugerir um pacote (ex.: `equatable`), indique que o `pubspec.yaml` deve ser atualizado.

Formato de resposta desejado ao executar este prompt com um gerador (por exemplo, outro agente):
- Para cada arquivo: mostrar caminho, depois o conteúdo Dart completo.
- Para testes: mostrar caminho e conteúdo do arquivo de teste (usando `flutter_test`).
- Para snippets: bloco curto de código com comentário de como executar.

Observações específicas da entidade:
- Preserve a geração de `id` via `Uuid()` como comportamento padrão no `WeeklyGoal` original.
- Ao criar o Model/DTO, garanta que `targetKm` e `currentKm` mantenham as mesmas validações (pelo menos asserts no construtor do entity).
- `userId` pode ser mantido como `String` e passado ao DAO para segmentar persistência por usuário.

Tarefas opcionais (marcar como "se possível"):
- Gerar uma pequena página de listagem em `lib/features/goals/presentation/pages/weekly_goals_page.dart` usando `ChangeNotifierProvider` e `Consumer` (exemplo simples com `ListView`).
- Implementar atualização incremental (p.ex. salvar apenas o item alterado em vez de regravar toda a lista) no DAO, com explicação das trade-offs.

---

Instruções finais para o gerador:
- Foque em clareza, pequenas funções e testabilidade.
- Produza código que compile isoladamente (as exceções sobre dependências externas devem ser declaradas como "assuma que `StorageService` existe").
- Ao finalizar, descreva rapidamente onde integrar os novos arquivos no projeto (ex.: registrar providers, importar repositório em páginas existentes).


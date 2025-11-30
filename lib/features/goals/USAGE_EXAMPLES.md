# WeeklyGoal - Exemplos de Uso

Este documento demonstra como usar a implementação completa de WeeklyGoal no projeto.

## Setup Básico

### 1. Criar instâncias necessárias

```dart
import 'package:runsafe/core/services/storage_service.dart';
import 'package:runsafe/features/goals/data/datasources/weekly_goals_local_dao.dart';
import 'package:runsafe/features/goals/data/repositories/weekly_goals_repository_impl.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';

// Inicializar serviços
final storageService = StorageService();
final dao = WeeklyGoalsLocalDao(storageService);
final repository = WeeklyGoalsRepositoryImpl(dao);
```

### 2. Criar uma meta semanal

```dart
// Criar meta com valores padrão
final goal1 = WeeklyGoal(targetKm: 10.0);

// Criar meta para usuário específico
final goal2 = WeeklyGoal(
  userId: 'user-123',
  targetKm: 20.0,
);

// Criar meta com progresso inicial
final goal3 = WeeklyGoal(
  userId: 'user-456',
  targetKm: 15.0,
  currentKm: 5.0,
);
```

### 3. Adicionar corridas

```dart
final goal = WeeklyGoal(targetKm: 10.0);

// Adicionar uma corrida de 3km
goal.addRun(3.0);
print(goal.currentKm); // 3.0

// Adicionar outra corrida
goal.addRun(2.5);
print(goal.currentKm); // 5.5

// Verificar progresso
print(goal.progressPercentage); // 0.55 (55%)
```

### 4. Salvar e carregar metas

```dart
// Salvar uma meta
await repository.add(goal);

// Carregar todas as metas de um usuário
final goals = await repository.listForUser('user-123');

// Remover uma meta
await repository.remove(goal.id);
```

## Usando o Provider

### 1. Registrar o Provider no app

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/goals/presentation/providers/weekly_goals_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WeeklyGoalsProvider(repository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 2. Usar o Provider em um widget

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/goals/presentation/providers/weekly_goals_provider.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeeklyGoalsProvider>(
      builder: (context, provider, child) {
        if (provider.loading) {
          return const CircularProgressIndicator();
        }

        return ListView.builder(
          itemCount: provider.count,
          itemBuilder: (context, index) {
            final goal = provider.items[index];
            return ListTile(
              title: Text('Meta: ${goal.targetKm} km'),
              subtitle: Text('Progresso: ${goal.currentKm} km'),
              trailing: Text('${(goal.progressPercentage * 100).toInt()}%'),
            );
          },
        );
      },
    );
  }
}
```

### 3. Operações com o Provider

```dart
// Carregar metas de um usuário
final provider = context.read<WeeklyGoalsProvider>();
await provider.load('user-123');

// Adicionar nova meta
final newGoal = WeeklyGoal(userId: 'user-123', targetKm: 15.0);
await provider.addGoal(newGoal);

// Adicionar corrida a uma meta existente
await provider.addRunForGoal('goal-id', 5.0);

// Remover meta
await provider.remove('goal-id');

// Limpar todas as metas do usuário
await provider.clearAll();
```

## Exemplo Completo: Fluxo de Uso

```dart
import 'package:flutter/material.dart';
import 'package:runsafe/core/services/storage_service.dart';
import 'package:runsafe/features/goals/data/datasources/weekly_goals_local_dao.dart';
import 'package:runsafe/features/goals/data/repositories/weekly_goals_repository_impl.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';

Future<void> exemploCompleto() async {
  // 1. Setup
  final storageService = StorageService();
  final dao = WeeklyGoalsLocalDao(storageService);
  final repository = WeeklyGoalsRepositoryImpl(dao);

  const userId = 'user-789';

  // 2. Criar meta semanal
  final goal = WeeklyGoal(
    userId: userId,
    targetKm: 20.0,
  );

  print('Meta criada: ${goal.targetKm} km');
  print('ID: ${goal.id}');

  // 3. Adicionar corridas ao longo da semana
  print('\n--- Segunda-feira ---');
  goal.addRun(5.0);
  print('Corrida: 5.0 km');
  print('Total: ${goal.currentKm} km (${(goal.progressPercentage * 100).toInt()}%)');

  print('\n--- Quarta-feira ---');
  goal.addRun(7.5);
  print('Corrida: 7.5 km');
  print('Total: ${goal.currentKm} km (${(goal.progressPercentage * 100).toInt()}%)');

  print('\n--- Sexta-feira ---');
  goal.addRun(8.0);
  print('Corrida: 8.0 km');
  print('Total: ${goal.currentKm} km (${(goal.progressPercentage * 100).toInt()}%)');

  // 4. Salvar progresso
  await repository.add(goal);
  print('\n✓ Meta salva com sucesso!');

  // 5. Carregar metas salvas
  final savedGoals = await repository.listForUser(userId);
  print('\nMetas carregadas: ${savedGoals.length}');

  for (final g in savedGoals) {
    print('- Meta: ${g.targetKm} km | Atual: ${g.currentKm} km | ${(g.progressPercentage * 100).toInt()}% completo');
  }

  // 6. Verificar se completou
  if (goal.progressPercentage >= 1.0) {
    print('\n🎉 Parabéns! Meta semanal concluída!');
  } else {
    final remaining = goal.targetKm - goal.currentKm;
    print('\nFaltam ${remaining.toStringAsFixed(1)} km para completar a meta.');
  }
}
```

## Integração na UI com WeeklyGoalsPage

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/goals/presentation/pages/weekly_goals_page.dart';
import 'package:runsafe/features/goals/presentation/providers/weekly_goals_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunSafe',
      home: ChangeNotifierProvider(
        create: (_) => WeeklyGoalsProvider(repository),
        child: const WeeklyGoalsPage(userId: 'current-user-id'),
      ),
    );
  }
}
```

## Executando Testes

```bash
# Testar entidade
flutter test test/features/goals/domain/entities/weekly_goal_test.dart

# Testar model
flutter test test/features/goals/data/models/weekly_goal_model_test.dart

# Todos os testes do feature goals
flutter test test/features/goals/
```

## Notas Importantes

1. **Validações**: `targetKm` deve ser > 0 e `currentKm` >= 0 (validadas com `assert`)
2. **IDs automáticos**: Se não fornecer `id`, um UUID será gerado automaticamente
3. **userId padrão**: Se não especificar `userId`, usará `'default-user'`
4. **Progresso limitado**: `progressPercentage` sempre retorna valor entre 0.0 e 1.0
5. **Valores negativos**: `addRun()` ignora silenciosamente valores negativos
6. **Persistência por usuário**: O DAO organiza metas por `userId` no storage
7. **Atualização automática**: Provider chama `notifyListeners()` após cada operação

## Trade-offs da Implementação Atual

### ✅ Vantagens
- Simples e direta para casos de uso básicos
- Não requer banco de dados complexo
- Funciona offline nativamente
- Fácil de testar

### ⚠️ Limitações
- Salva lista completa a cada operação (pode ser lento com muitas metas)
- Não suporta sincronização entre dispositivos
- Sem histórico de alterações
- Limite de dados do SharedPreferences (~1MB)

### 🔧 Melhorias Futuras Sugeridas
1. Usar SQLite para persistência mais eficiente
2. Implementar sync com backend/cloud
3. Adicionar campos `startDate` e `endDate` para metas com prazo
4. Histórico de corridas individuais (não apenas total)
5. Notificações/lembretes para motivação

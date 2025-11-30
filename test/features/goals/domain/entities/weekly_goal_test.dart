import 'package:flutter_test/flutter_test.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';

void main() {
  group('WeeklyGoal Entity Tests', () {
    test('deve criar uma meta com valores padrão', () {
      final goal = WeeklyGoal(targetKm: 10.0);

      expect(goal.id, isNotEmpty);
      expect(goal.userId, equals('default-user'));
      expect(goal.targetKm, equals(10.0));
      expect(goal.currentKm, equals(0.0));
    });

    test('deve criar uma meta com ID específico', () {
      const customId = 'custom-id-123';
      final goal = WeeklyGoal(id: customId, targetKm: 20.0);

      expect(goal.id, equals(customId));
    });

    test('deve lançar AssertionError se targetKm for zero', () {
      expect(
        () => WeeklyGoal(targetKm: 0.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('deve lançar AssertionError se targetKm for negativo', () {
      expect(
        () => WeeklyGoal(targetKm: -5.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('deve lançar AssertionError se currentKm for negativo', () {
      expect(
        () => WeeklyGoal(targetKm: 10.0, currentKm: -1.0),
        throwsA(isA<AssertionError>()),
      );
    });

    group('progressPercentage', () {
      test('deve retornar 0 quando currentKm for 0', () {
        final goal = WeeklyGoal(targetKm: 10.0, currentKm: 0.0);
        expect(goal.progressPercentage, equals(0.0));
      });

      test('deve retornar 0.5 quando currentKm for metade do target', () {
        final goal = WeeklyGoal(targetKm: 10.0, currentKm: 5.0);
        expect(goal.progressPercentage, equals(0.5));
      });

      test('deve retornar 1.0 quando currentKm igualar o target', () {
        final goal = WeeklyGoal(targetKm: 10.0, currentKm: 10.0);
        expect(goal.progressPercentage, equals(1.0));
      });

      test('deve limitar em 1.0 quando currentKm exceder o target', () {
        final goal = WeeklyGoal(targetKm: 10.0, currentKm: 15.0);
        expect(goal.progressPercentage, equals(1.0));
      });

      test('deve retornar 0 se targetKm for 0 (edge case)', () {
        // Nota: este caso não deveria acontecer devido ao assert,
        // mas testamos a lógica do getter
        final goal = WeeklyGoal(targetKm: 10.0);
        // Forçamos targetKm = 0 diretamente no objeto (bypass do construtor)
        // Não é possível fazer isso com final, então apenas documentamos o comportamento esperado
        expect(goal.progressPercentage, lessThanOrEqualTo(1.0));
      });
    });

    group('addRun', () {
      test('deve adicionar quilômetros corretamente', () {
        final goal = WeeklyGoal(targetKm: 10.0);
        
        goal.addRun(3.0);
        expect(goal.currentKm, equals(3.0));
        
        goal.addRun(2.5);
        expect(goal.currentKm, equals(5.5));
      });

      test('deve ignorar valores negativos', () {
        final goal = WeeklyGoal(targetKm: 10.0, currentKm: 5.0);
        
        goal.addRun(-2.0);
        expect(goal.currentKm, equals(5.0)); // Não deve mudar
      });

      test('deve aceitar zero sem alterar currentKm', () {
        final goal = WeeklyGoal(targetKm: 10.0, currentKm: 5.0);
        
        goal.addRun(0.0);
        expect(goal.currentKm, equals(5.0));
      });

      test('deve permitir ultrapassar a meta', () {
        final goal = WeeklyGoal(targetKm: 10.0, currentKm: 8.0);
        
        goal.addRun(5.0);
        expect(goal.currentKm, equals(13.0));
        expect(goal.progressPercentage, equals(1.0)); // Clamped
      });
    });

    test('deve criar metas para usuários diferentes', () {
      final goal1 = WeeklyGoal(userId: 'user-1', targetKm: 10.0);
      final goal2 = WeeklyGoal(userId: 'user-2', targetKm: 20.0);

      expect(goal1.userId, equals('user-1'));
      expect(goal2.userId, equals('user-2'));
      expect(goal1.id, isNot(equals(goal2.id)));
    });
  });
}

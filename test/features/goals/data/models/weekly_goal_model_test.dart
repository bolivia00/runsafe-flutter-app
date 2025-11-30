import 'package:flutter_test/flutter_test.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';
import 'package:runsafe/features/goals/data/models/weekly_goal_model.dart';

void main() {
  group('WeeklyGoalModel Tests', () {
    test('deve criar model a partir de JSON válido', () {
      final json = {
        'id': 'test-id-123',
        'userId': 'user-456',
        'targetKm': 15.5,
        'currentKm': 7.25,
      };

      final model = WeeklyGoalModel.fromJson(json);

      expect(model.id, equals('test-id-123'));
      expect(model.userId, equals('user-456'));
      expect(model.targetKm, equals(15.5));
      expect(model.currentKm, equals(7.25));
    });

    test('deve converter model para JSON corretamente', () {
      final model = WeeklyGoalModel(
        id: 'test-id-789',
        userId: 'user-101',
        targetKm: 20.0,
        currentKm: 10.0,
      );

      final json = model.toJson();

      expect(json['id'], equals('test-id-789'));
      expect(json['userId'], equals('user-101'));
      expect(json['targetKm'], equals(20.0));
      expect(json['currentKm'], equals(10.0));
    });

    test('deve fazer round-trip JSON -> Model -> JSON', () {
      final originalJson = {
        'id': 'round-trip-id',
        'userId': 'user-rt',
        'targetKm': 25.0,
        'currentKm': 12.5,
      };

      final model = WeeklyGoalModel.fromJson(originalJson);
      final resultJson = model.toJson();

      expect(resultJson, equals(originalJson));
    });

    test('deve converter entity para model', () {
      final entity = WeeklyGoal(
        id: 'entity-id',
        userId: 'user-entity',
        targetKm: 30.0,
        currentKm: 15.0,
      );

      final model = WeeklyGoalModel.fromEntity(entity);

      expect(model.id, equals(entity.id));
      expect(model.userId, equals(entity.userId));
      expect(model.targetKm, equals(entity.targetKm));
      expect(model.currentKm, equals(entity.currentKm));
    });

    test('deve converter model para entity', () {
      final model = WeeklyGoalModel(
        id: 'model-id',
        userId: 'user-model',
        targetKm: 40.0,
        currentKm: 20.0,
      );

      final entity = model.toEntity();

      expect(entity.id, equals(model.id));
      expect(entity.userId, equals(model.userId));
      expect(entity.targetKm, equals(model.targetKm));
      expect(entity.currentKm, equals(model.currentKm));
    });

    test('deve fazer round-trip completo Entity -> Model -> JSON -> Model -> Entity', () {
      // Entity original
      final originalEntity = WeeklyGoal(
        id: 'complete-rt',
        userId: 'user-complete',
        targetKm: 50.0,
        currentKm: 25.0,
      );

      // Entity -> Model
      final model1 = WeeklyGoalModel.fromEntity(originalEntity);

      // Model -> JSON
      final json = model1.toJson();

      // JSON -> Model
      final model2 = WeeklyGoalModel.fromJson(json);

      // Model -> Entity
      final resultEntity = model2.toEntity();

      // Verificações
      expect(resultEntity.id, equals(originalEntity.id));
      expect(resultEntity.userId, equals(originalEntity.userId));
      expect(resultEntity.targetKm, equals(originalEntity.targetKm));
      expect(resultEntity.currentKm, equals(originalEntity.currentKm));
    });

    test('deve implementar igualdade corretamente', () {
      final model1 = WeeklyGoalModel(
        id: 'eq-id',
        userId: 'user-eq',
        targetKm: 10.0,
        currentKm: 5.0,
      );

      final model2 = WeeklyGoalModel(
        id: 'eq-id',
        userId: 'user-eq',
        targetKm: 10.0,
        currentKm: 5.0,
      );

      final model3 = WeeklyGoalModel(
        id: 'different-id',
        userId: 'user-eq',
        targetKm: 10.0,
        currentKm: 5.0,
      );

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('deve lançar AssertionError se targetKm for <= 0', () {
      expect(
        () => WeeklyGoalModel(
          id: 'test',
          userId: 'user',
          targetKm: 0.0,
          currentKm: 0.0,
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => WeeklyGoalModel(
          id: 'test',
          userId: 'user',
          targetKm: -5.0,
          currentKm: 0.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('deve lançar AssertionError se currentKm for negativo', () {
      expect(
        () => WeeklyGoalModel(
          id: 'test',
          userId: 'user',
          targetKm: 10.0,
          currentKm: -1.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('deve lidar com números inteiros no JSON', () {
      final json = {
        'id': 'int-test',
        'userId': 'user-int',
        'targetKm': 10, // int em vez de double
        'currentKm': 5, // int em vez de double
      };

      final model = WeeklyGoalModel.fromJson(json);

      expect(model.targetKm, equals(10.0));
      expect(model.currentKm, equals(5.0));
    });

    test('toString deve retornar representação legível', () {
      final model = WeeklyGoalModel(
        id: 'str-id',
        userId: 'str-user',
        targetKm: 15.0,
        currentKm: 7.5,
      );

      final str = model.toString();

      expect(str, contains('str-id'));
      expect(str, contains('str-user'));
      expect(str, contains('15.0'));
      expect(str, contains('7.5'));
    });
  });
}

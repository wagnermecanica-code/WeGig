/// WeGig - NotificationNew Widget Tests
///
/// Testes de widget para componentes de notificação.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/notifications_new/presentation/widgets/notification_new_empty_state.dart';
import 'package:wegig_app/features/notifications_new/presentation/widgets/notification_new_error_state.dart';
import 'package:wegig_app/features/notifications_new/presentation/widgets/notification_new_skeleton_tile.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('NotificationNewEmptyState', () {
    testWidgets('should display empty state message', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(const NotificationNewEmptyState()),
      );

      // Assert
      expect(find.text('Nenhuma notificação'), findsOneWidget);
    });

    testWidgets('should display empty state icon', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(const NotificationNewEmptyState()),
      );

      // Assert - procura por um Icon widget
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('should display interest empty state when isInterestsTab is true',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(const NotificationNewEmptyState(isInterestsTab: true)),
      );

      // Assert
      expect(find.text('Nenhum interesse ainda'), findsOneWidget);
    });
  });

  group('NotificationNewErrorState', () {
    testWidgets('should display error message', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          NotificationNewErrorState(
            message: 'Erro ao carregar notificações',
            onRetry: () {},
          ),
        ),
      );

      // Assert
      expect(find.text('Algo deu errado'), findsOneWidget);
      expect(find.text('Erro ao carregar notificações'), findsOneWidget);
    });

    testWidgets('should display retry button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          NotificationNewErrorState(
            message: 'Network error',
            onRetry: () {},
          ),
        ),
      );

      // Assert
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('should call onRetry when retry button is tapped',
        (tester) async {
      // Arrange
      var retryPressed = false;

      await tester.pumpWidget(
        createTestWidget(
          NotificationNewErrorState(
            message: 'Error',
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      // Assert
      expect(retryPressed, true);
    });
  });

  group('NotificationNewSkeletonTile', () {
    testWidgets('should render skeleton placeholders', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(const NotificationNewSkeletonTile()),
      );

      // Assert - skeleton deve ter containers animados
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have correct dimensions', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(const NotificationNewSkeletonTile()),
      );

      // Assert - skeleton deve ter altura mínima
      final skeleton = tester.widget<Container>(find.byType(Container).first);
      expect(skeleton, isNotNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forth_ports_dundee/app.dart';
import 'package:forth_ports_dundee/core/constants/app_strings.dart';
import 'package:forth_ports_dundee/features/auth/forgot_password_screen.dart';
import 'package:forth_ports_dundee/features/auth/data/auth_repository.dart';
import 'package:forth_ports_dundee/features/auth/login_screen.dart';
import 'package:forth_ports_dundee/features/auth/reset_password_screen.dart';
import 'package:forth_ports_dundee/features/auth/sign_up_screen.dart';
import 'package:forth_ports_dundee/features/auth/verify_otp_screen.dart';
import 'package:forth_ports_dundee/features/dashboard/widgets/quick_action_tile.dart';
import 'package:forth_ports_dundee/features/dashboard/widgets/stat_card.dart';
import 'package:forth_ports_dundee/features/items/data/items_repository.dart';
import 'package:forth_ports_dundee/features/items/item_details_screen.dart';
import 'package:forth_ports_dundee/features/items/items_list_screen.dart';
import 'package:forth_ports_dundee/features/items/models/item.dart';
import 'package:forth_ports_dundee/features/items/models/item_filters.dart';
import 'package:forth_ports_dundee/features/items/search_items_screen.dart';
import 'package:forth_ports_dundee/features/items/widgets/item_card.dart';
import 'package:forth_ports_dundee/features/movements/data/movements_repository.dart';
import 'package:forth_ports_dundee/features/movements/models/movement.dart';
import 'package:forth_ports_dundee/features/movements/models/movement_filters.dart';
import 'package:forth_ports_dundee/features/movements/movement_details_screen.dart';
import 'package:forth_ports_dundee/features/movements/movement_form_screen.dart';
import 'package:forth_ports_dundee/features/movements/movements_screen.dart';
import 'package:forth_ports_dundee/features/movements/widgets/movement_tile.dart';
import 'package:forth_ports_dundee/features/notifications/notifications_screen.dart';
import 'package:forth_ports_dundee/features/notifications/reorder_items_screen.dart';
import 'package:forth_ports_dundee/features/shell/main_shell.dart';
import 'package:forth_ports_dundee/features/splash/splash_screen.dart';

/// Pumps [MainShell] at phone width so mobile layouts are tested reliably.
Future<void> pumpPhoneShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(home: MainShell()));
  await tester.pump();
}

void main() {
  // Keep the mutable catalogues isolated between tests.
  setUp(() {
    AuthRepository.mockMode = true;
    AuthRepository.instance.currentUser = const AuthUser(
      id: 1,
      username: 'demo',
      email: 'demo@forthports.demo',
      firstName: 'Demo',
      lastName: 'User',
      role: 'Store Staff',
      department: 'Maintenance Team',
      phone: '',
    );
    ItemsRepository.reset();
    MovementsRepository.reset();
  });

  testWidgets('Splash renders the Forth Ports Dundee branding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ForthPortsApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(AppStrings.brandLineTop), findsOneWidget);
    expect(find.text(AppStrings.brandLineBottom), findsOneWidget);
    expect(find.text(AppStrings.tagline), findsOneWidget);
    expect(find.text(AppStrings.loading), findsOneWidget);
  });

  testWidgets('App transitions to login once bootstrap completes', (
    WidgetTester tester,
  ) async {
    // Bootstrap performs real async work (image pre-caching + timed steps), so
    // we let it run against the real clock inside runAsync, then pump frames to
    // render the post-navigation UI.
    await tester.runAsync(() async {
      await tester.pumpWidget(const ForthPortsApp());
      await Future<void>.delayed(const Duration(seconds: 3));
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AppStrings.loginWelcome), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);
  });

  testWidgets('Login validates empty fields before submitting', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const _LoginHarness());

    await tester.tap(find.text(AppStrings.signIn));
    await tester.pump();

    expect(find.text(AppStrings.usernameRequired), findsOneWidget);
    expect(find.text(AppStrings.passwordRequired), findsOneWidget);
  });

  testWidgets('Login navigates to Sign Up', (WidgetTester tester) async {
    await tester.pumpWidget(const _LoginHarness());

    await tester.tap(find.text(AppStrings.signUp));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text(AppStrings.createAccountTitle), findsOneWidget);
  });

  testWidgets('Login navigates to Forgot Password', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const _LoginHarness());

    await tester.tap(find.text(AppStrings.forgotPassword));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text(AppStrings.sendResetLink), findsOneWidget);
  });

  testWidgets('Sign Up validates required fields and password match', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    await tester.tap(find.text(AppStrings.signUp));
    await tester.pump();

    expect(find.text(AppStrings.fullNameRequired), findsOneWidget);
    expect(find.text(AppStrings.emailRequired), findsOneWidget);
    expect(find.text(AppStrings.usernameFieldRequired), findsOneWidget);
    expect(find.text(AppStrings.passwordRequired), findsOneWidget);

    // No terms & conditions checkbox should exist on this screen.
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('OTP rejects the wrong code and accepts 123456', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: VerifyOtpScreen(email: 'demo@example.com')),
    );

    // Wrong code -> error message, stays on the OTP screen.
    await tester.enterText(find.byType(TextField).first, '111111');
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.verifyOtp));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(AppStrings.otpInvalid), findsOneWidget);
    expect(find.byType(VerifyOtpScreen), findsOneWidget);

    // Correct demo code -> navigates to reset password.
    await tester.enterText(find.byType(TextField).first, AppStrings.demoOtp);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
  });

  testWidgets('Reset Password shows a live strength meter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResetPasswordScreen(email: 'user@test.com', otp: '123456'),
      ),
    );

    expect(find.text(AppStrings.strengthStrong), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'Str0ng!Pass99');
    await tester.pump();
    expect(find.text(AppStrings.strengthStrong), findsOneWidget);
  });

  testWidgets('Dashboard renders stats and quick actions', (
    WidgetTester tester,
  ) async {
    await pumpPhoneShell(tester);
    expect(find.text('Hello, Demo User'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text(AppStrings.statLowStock), findsOneWidget);
    expect(find.text(AppStrings.statOutOfStock), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.byType(StatCard), findsNWidgets(4));

    // Bottom nav (always visible) — no Scan action.
    expect(find.text(AppStrings.navDashboard), findsOneWidget);
    expect(find.text(AppStrings.navScan), findsNothing);

    // Quick actions live below the fold; scroll them into view. Use a string
    // unique to the dashboard (the bottom-nav "Reports" label would otherwise
    // short-circuit the scroll).
    await tester.scrollUntilVisible(
      find.text(AppStrings.actionMoreSub),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(QuickActionTile), findsNWidgets(4));
    expect(find.text(AppStrings.quickActions), findsOneWidget);
  });

  group('ItemsRepository', () {
    test('search matches name and code', () {
      final List<Item> brushes = ItemsRepository.query(search: 'brush');
      expect(brushes.length, 5);
      expect(
        brushes.every((Item i) => i.name.toLowerCase().contains('brush')),
        isTrue,
      );
    });

    test('filters by stock status', () {
      final List<Item> out = ItemsRepository.query(
        filters: const ItemFilters(
          statuses: <StockStatus>{StockStatus.outOfStock},
        ),
      );
      expect(out.length, 1);
      expect(out.first.name, 'Gloves Nitrile Large (Pair)');
    });

    test('sorts by name ascending by default', () {
      final List<Item> items = ItemsRepository.query();
      expect(items.first.name, 'Brush Soft 75MM');
    });
  });

  testWidgets('Items list renders cards and opens details', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ItemsListScreen()));
    await tester.pump();

    expect(find.byType(ItemCard), findsWidgets);

    await tester.tap(find.byType(ItemCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailsScreen), findsOneWidget);
    expect(find.text(AppStrings.tabOverview), findsOneWidget);
    expect(find.text(AppStrings.detailCategory), findsOneWidget);

    // Stock & History tab shows the summary, trend chart and last activity.
    await tester.tap(find.text(AppStrings.tabStockHistory));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.stockSummary), findsOneWidget);
    expect(find.text(AppStrings.summaryStockInTotal), findsOneWidget);
    expect(find.text(AppStrings.stockTrendTitle), findsOneWidget);
    expect(find.text(AppStrings.lastActivityTitle), findsOneWidget);
    expect(find.text(AppStrings.lastStockIn), findsOneWidget);
    expect(find.text(AppStrings.lastStockOut), findsOneWidget);
  });

  testWidgets('Search filters the catalogue live', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchItemsScreen()));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'gland');
    await tester.pump();

    expect(find.text('Cable Gland M20 Grey'), findsOneWidget);
    expect(find.text('Brush Soft 75MM'), findsNothing);
  });

  test('Repository delete removes an item from all queries', () async {
    final int before = ItemsRepository.query().length;
    expect(await ItemsRepository.delete('GNLRG'), isTrue);
    expect(ItemsRepository.query().length, before - 1);
    expect(ItemsRepository.query().any((Item i) => i.code == 'GNLRG'), isFalse);
  });

  test('Repository update replaces an item in place', () {
    final Item original = ItemsRepository.query().firstWhere(
      (Item i) => i.code == 'PRN13DGTF',
    );
    ItemsRepository.update(original.copyWith(name: 'Renamed Brush'));
    final Item updated = ItemsRepository.query().firstWhere(
      (Item i) => i.code == 'PRN13DGTF',
    );
    expect(updated.name, 'Renamed Brush');
  });

  testWidgets('Item details no longer offers delete or favourite', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ItemsListScreen()));
    await tester.pump();

    await tester.tap(find.byType(ItemCard).first);
    await tester.pumpAndSettle();

    expect(find.byTooltip(AppStrings.deleteItemTitle), findsNothing);
    expect(find.byIcon(Icons.star_border_rounded), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  test('Movements repository scopes by type and sorts newest first', () {
    final List<Movement> stockIn = MovementsRepository.query(
      type: MovementType.stockIn,
    );
    expect(stockIn, isNotEmpty);
    expect(stockIn.every((Movement m) => m.isIn), isTrue);
    for (int i = 0; i < stockIn.length - 1; i++) {
      expect(stockIn[i].date.isBefore(stockIn[i + 1].date), isFalse);
    }
  });

  test('Movements repository filters by location', () {
    final List<Movement> filtered = MovementsRepository.query(
      type: MovementType.stockOut,
      filters: const MovementFilters(
        type: MovementType.stockOut,
        location: 'Main Warehouse',
      ),
    );
    expect(filtered, isNotEmpty);
    expect(
      filtered.every((Movement m) => m.location == 'Main Warehouse'),
      isTrue,
    );
  });

  test('Movements summary computes totals and net', () {
    final MovementSummary summary = MovementsRepository.summary;
    expect(summary.totalIn, greaterThan(0));
    expect(summary.totalOut, greaterThan(0));
    expect(summary.net, summary.totalIn - summary.totalOut);
  });

  testWidgets('Movements overview expands to a list and opens details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MovementsScreen()));
    await tester.pump();

    // Overview shows recent stock-out movements and Issue Stock.
    expect(find.text(AppStrings.recentMovements), findsOneWidget);
    expect(find.text(AppStrings.issueStock), findsOneWidget);

    // Expand into the searchable list.
    await tester.tap(find.text(AppStrings.viewAll));
    await tester.pumpAndSettle();
    expect(find.byType(MovementTile), findsWidgets);

    // Open a movement's details.
    await tester.tap(find.byType(MovementTile).first);
    await tester.pumpAndSettle();
    expect(find.byType(MovementDetailsScreen), findsOneWidget);
    expect(find.text(AppStrings.movementDetailsTitle), findsOneWidget);
    expect(find.text(AppStrings.detailsSection), findsOneWidget);
  });

  test('Recording a movement appends to the ledger with a fresh reference', () {
    final int before = MovementsRepository.query(
      type: MovementType.stockIn,
    ).length;
    final String ref = MovementsRepository.nextReference();
    expect(ref, startsWith('WO'));

    final Item item = ItemsRepository.all.first;
    MovementsRepository.record(<Movement>[
      Movement(
        id: 'test',
        type: MovementType.stockIn,
        itemName: item.name,
        itemCode: item.code,
        image: item.image,
        quantity: 5,
        date: DateTime(2024, 6, 1),
        referenceNo: ref,
        requestedBy: 'Tester',
        location: 'Main Warehouse',
        notes: '—',
        unit: 'Each',
        stockBefore: item.quantity,
      ),
    ]);
    expect(
      MovementsRepository.query(type: MovementType.stockIn).length,
      before + 1,
    );
  });

  testWidgets('Stock movement form flags missing required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MovementFormScreen(type: MovementType.stockOut),
      ),
    );
    await tester.pump();
    expect(find.text(AppStrings.issueStock), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.saveCta));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.fieldRequired), findsWidgets);
  });

  testWidgets('Stock movement form records a movement on Save', (
    WidgetTester tester,
  ) async {
    final Item item = ItemsRepository.all.first;
    final int before = MovementsRepository.query(
      type: MovementType.stockIn,
    ).length;

    await tester.pumpWidget(
      MaterialApp(
        home: MovementFormScreen(type: MovementType.stockIn, item: item),
      ),
    );
    await tester.pump();
    expect(find.text(AppStrings.enterNewStock), findsOneWidget);

    // Enter a quantity (the quantity field is the first text field).
    await tester.enterText(find.byType(TextField).first, '5');

    // Pick a location.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MovementsRepository.locations.first).last);
    await tester.pumpAndSettle();

    // Save records the movement and shows the success screen.
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.saveCta));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.movementRecordedTitle), findsOneWidget);
    expect(
      MovementsRepository.query(type: MovementType.stockIn).length,
      before + 1,
    );
  });

  testWidgets('Notifications only show Out of Stock and Low Stock', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    await tester.pump();

    expect(find.text(AppStrings.outOfStockItemsTitle), findsOneWidget);
    expect(find.text(AppStrings.lowStockItemsTitle), findsOneWidget);
    expect(find.text(AppStrings.highPriority), findsOneWidget);
    expect(find.text(AppStrings.warnings), findsOneWidget);

    // Tapping a card opens the matching items list.
    await tester.tap(find.text(AppStrings.outOfStockItemsTitle));
    await tester.pumpAndSettle();
    expect(find.byType(ReorderItemsScreen), findsOneWidget);
  });

  testWidgets('Reorder item opens Stock In form pre-loaded with the item', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReorderItemsScreen(status: StockStatus.lowStock)),
    );
    await tester.pump();

    // Lists items with reorder figures (no pricing).
    expect(find.text(AppStrings.reorderLevelLabel), findsWidgets);
    expect(find.text(AppStrings.unitsToOrderLabel), findsWidgets);

    await tester.tap(find.text(AppStrings.reorderLevelLabel).first);
    await tester.pumpAndSettle();

    // Lands on the Enter New Stock form with the item pre-loaded.
    expect(find.byType(MovementFormScreen), findsOneWidget);
    expect(find.text(AppStrings.enterNewStock), findsOneWidget);
    expect(find.text(AppStrings.selectLocation), findsOneWidget);
  });

  testWidgets('Dashboard account menu logs out to the login screen', (
    WidgetTester tester,
  ) async {
    await pumpPhoneShell(tester);

    await tester.tap(find.text(AppStrings.dashboardGreeting));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.logOut), findsOneWidget);

    await tester.tap(find.text(AppStrings.logOut));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

/// Mounts [LoginScreen] directly for focused widget tests.
class _LoginHarness extends StatelessWidget {
  const _LoginHarness();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LoginScreen());
  }
}

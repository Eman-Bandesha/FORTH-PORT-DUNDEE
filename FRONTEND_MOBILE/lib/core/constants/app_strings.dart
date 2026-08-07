/// User-facing copy.
///
/// Centralising strings keeps wording consistent and provides a single place to
/// wire up localisation later.
abstract final class AppStrings {
  const AppStrings._();

  static const String appName = 'Forth Ports Dundee';
  static const String brandLineTop = 'FORTH PORTS';
  static const String brandLineBottom = 'DUNDEE';
  static const String tagline = 'Stock Management';
  static const String loading = 'Loading…';

  static const String homeTitle = 'Stock Management';
  static const String homeWelcome = 'Welcome to Forth Ports Dundee';
  static const String homeSubtitle =
      'Your stock management workspace is ready.';

  // Dashboard
  static const String dashboardTitle = 'Dashboard';
  static const String dashboardUserName = 'User';
  static const String dashboardGreeting = 'Hello';
  static const String dashboardSubtitle = "Here's what's happening today.";
  static const String logOut = 'Log Out';
  static const String account = 'Account';

  // Notifications
  static const String notificationsTitle = 'Notifications';
  static const String markAllRead = 'Mark all as read';
  static const String allMarkedRead = 'All notifications marked as read';
  static const String highPriority = 'High Priority';
  static const String warnings = 'Warnings';
  static const String outOfStockItemsTitle = 'Out of Stock Items';
  static const String lowStockItemsTitle = 'Low Stock Items';
  static const String outOfStockNotifBody =
      'items are out of stock. Tap to view details and act now.';
  static const String lowStockNotifBody =
      'items are running low. Tap to review and reorder.';

  // Reorder / status item lists
  static const String outOfStockListDesc =
      'These items are currently out of stock.';
  static const String lowStockListDesc =
      'These items are running low on stock.';
  static const String reorderLevelLabel = 'Reorder Level';
  static const String unitsToOrderLabel = 'Units to Order';
  static const String sortPriorityLabel = 'Priority';
  static const String searchOutOfStockHint = 'Search out of stock items';
  static const String searchLowStockHint = 'Search low stock items';
  static const String statTotalItems = 'Total Items';
  static const String statLowStock = 'Low Stock Items';
  static const String statOutOfStock = 'Out of Stock';
  static const String statNearExpiry = 'Near Expiry';
  static const String statStockOutToday = 'Stock Out Today';
  static const String viewAllItemsLink = 'View all items';
  static const String viewLowStockLink = 'View low stock';
  static const String viewOutOfStockLink = 'View out of stock';
  static const String viewRecentStockOutLink = 'View recent stock out';
  static const String alertsTitle = 'Alerts';
  static const String viewAllAlerts = 'View all alerts';
  static const String itemsNeedAttention = 'items need attention';
  static const String itemsRunningLow = 'items running low';
  static const String recentStockOutTitle = 'Recent Stock Out';
  static const String dateTimeHeader = 'Date & Time';
  static const String qtyIssuedHeader = 'Qty Issued';
  static const String actionBrowseItems = 'Browse Items';
  static const String actionBrowseItemsSub = 'View and search inventory';
  static const String actionIssueStock = 'Issue Stock';
  static const String actionIssueStockSub = 'Record a stock-out movement';
  static const String actionViewAlerts = 'View Alerts';
  static const String actionViewAlertsSub = 'Low stock and out of stock';
  static const String appVersionFooter = 'Forth Ports Dundee Staff App v1.0.0';
  static const String quickActions = 'Quick Actions';
  static const String actionScanSearch = 'Scan / Search Item';
  static const String actionScanSearchSub = 'Find item by name or scan barcode';
  static const String actionAddItem = 'Add New Item';
  static const String actionAddItemSub = 'Add a new item to inventory';
  static const String actionStockMovement = 'Stock Movement';
  static const String actionStockMovementSub = 'Record stock in or out';
  static const String actionMore = 'More';
  static const String actionMoreSub = 'Profile, help & app info';

  // Items
  static const String itemsTitle = 'Items';
  static const String itemsSubtitle = 'Browse and search all items';
  static const String searchItemsByNameOrCodeHint =
      'Search items by name or code...';
  static const String filterButtonLabel = 'Filter';
  static const String itemNameHeader = 'Item Name';
  static const String itemCodeHeader = 'Item Code';
  static const String currentStockHeader = 'Current Stock';
  static const String statusHeader = 'Status';
  static const String lastOutHeader = 'Last Out';
  static const String showingItemsRange = 'Showing'; // "Showing 1 to 5 of 50 items"
  static const String ofItemsSuffix = 'of';
  static const String itemsWord = 'items';
  static const String viewGrid = 'Grid view';
  static const String viewList = 'List view';
  static const String searchItemsTitle = 'Search Items';
  static const String searchByNameHint = 'Search by name';
  static const String searchHint = 'Search';
  static const String sortPrefix = 'Sort: ';
  static const String itemsCountSuffix = ' items';
  static const String clearAll = 'Clear All';
  static const String noItemsFound = 'No items found';
  static const String qtyPrefix = 'Qty: ';

  // Filters
  static const String filtersTitle = 'Filters';
  static const String reset = 'Reset';
  static const String stockStatusLabel = 'Stock Status';
  static const String categoryLabel = 'Category';
  static const String selectCategory = 'Select Category';
  static const String locationLabel = 'Location';
  static const String selectLocation = 'Select Location';
  static const String sortByLabel = 'Sort By';
  static const String cancel = 'Cancel';
  static const String applyFilters = 'Apply Filters';

  // Stock status labels
  static const String inStock = 'In Stock';
  static const String lowStock = 'Low Stock';
  static const String outOfStock = 'Out of Stock';

  // Sort labels
  static const String sortNameAsc = 'Name (A-Z)';
  static const String sortNameDesc = 'Name (Z-A)';
  static const String sortQtyHighLow = 'Quantity (High-Low)';
  static const String sortQtyLowHigh = 'Quantity (Low-High)';

  // Item details
  static const String itemDetailsTitle = 'Item Details';
  static const String tabOverview = 'Overview';
  static const String tabStockHistory = 'Stock & History';
  static const String detailCategory = 'Category';
  static const String detailCurrentStock = 'Current Stock';
  static const String detailUnit = 'Unit';
  static const String detailReorderLevel = 'Reorder Level';
  static const String detailLocation = 'Location';
  static const String detailDescription = 'Description';
  static const String detailLastUpdated = 'Last Updated';
  static const String editItem = 'Edit Item';
  static const String stockMovementCta = 'Stock Movement';
  static const String stockHistoryEmpty = 'No stock movements recorded yet.';

  // Stock & History tab
  static const String stockSummary = 'Stock Summary';
  static const String stockHistory = 'Stock History';
  static const String stockIn = 'Stock In';
  static const String stockOut = 'Stock Out';
  static const String summaryInStock = 'In Stock';
  static const String summaryStockInTotal = 'Stock In (Total)';
  static const String summaryStockOutTotal = 'Stock Out (Total)';
  static const String summaryReorderLevel = 'Reorder Level';
  static const String stockTrendTitle = 'Stock Trend (Last 7 Days)';
  static const String trendLegendIn = 'In';
  static const String trendLegendOut = 'Out';
  static const String trendLegendStock = 'Stock';
  static const String lastActivityTitle = 'Last Activity';
  static const String lastStockIn = 'Last Stock In';
  static const String lastStockOut = 'Last Stock Out';

  // Edit item
  static const String editItemTitle = 'Edit Item';
  static const String itemNameLabel = 'Item Name';
  static const String skuLabel = 'SKU / Code';
  static const String saveChanges = 'Save Changes';
  static const String itemUpdated = 'Item updated';
  static const String fieldRequired = 'Required';

  // Create item
  static const String createItemTitle = 'Add New Item';
  static const String initialStockLabel = 'Initial Stock';
  static const String selectCategoryHint = 'Select category';
  static const String selectLocationHint = 'Select location';
  static const String unitHint = 'e.g. Each, Pack, Box';
  static const String saveItemCta = 'Save Item';
  static const String itemCreated = 'Item added successfully';
  static const String codeAlreadyExists = 'An item with this code already exists';
  static const String addPhotoLabel = 'Add Photo (optional)';

  // Delete item
  static const String deleteItemTitle = 'Delete Item';
  static const String deleteItemMessage =
      'Are you sure you want to delete this item?\nThis action cannot be undone.';
  static const String delete = 'Delete';
  static const String itemDeleted = 'Item deleted';

  // Movements
  static const String movementsTitle = 'Movements';
  static const String recentMovements = 'Recent Movements';
  static const String viewAll = 'View All';
  static const String summaryThisMonth = 'Summary (This Month)';
  static const String summaryTotalIn = 'Total In';
  static const String summaryTotalOut = 'Total Out';
  static const String summaryNetMovement = 'Net Movement';
  static const String summaryTransactions = 'Transactions';
  static const String enterNewStock = 'Enter New Stock';
  static const String issueStock = 'Issue Stock';
  static const String searchStockInHint = 'Search stock in';
  static const String searchStockOutHint = 'Search stock out';
  static const String noMovementsFound = 'No movements found';

  // Movement sort labels
  static const String sortNewestFirst = 'Newest First';
  static const String sortOldestFirst = 'Oldest First';

  // Movement details
  static const String movementDetailsTitle = 'Movement Details';
  static const String detailsSection = 'Details';
  static const String referenceNoLabel = 'Reference No.';
  static const String fromLocationLabel = 'From Location';
  static const String totalQuantityLabel = 'Total Quantity';
  static const String notesLabel = 'Notes';
  static const String stockInformation = 'Stock Information';
  static const String stockBeforeMovement = 'Stock Before Movement';
  static const String stockMovedOut = 'Stock Moved Out';
  static const String stockMovedIn = 'Stock Moved In';
  static const String remainingStock = 'Remaining Stock';

  // Movement filters
  static const String dateRangeLabel = 'Date Range';
  static const String fromDateLabel = 'From Date';
  static const String toDateLabel = 'To Date';
  static const String selectDate = 'Select Date';
  static const String clear = 'Clear';

  // Stock movement form (Enter New Stock / Issue Stock)
  static const String selectItemLabel = 'Select Item';
  static const String selectItemHint = 'Select item';
  static const String quantityLabel = 'Quantity';
  static const String quantityHint = 'Enter quantity';
  static const String purposeReasonLabel = 'Purpose / Reason';
  static const String selectReasonHint = 'Select reason';
  static const String optionalNotesHint = 'Optional notes';
  static const String saveCta = 'Save';
  static const String movementRecordedTitle = 'Movement Recorded Successfully!';
  static const String viewMovementCta = 'View Movement';
  static const String backToMovementsCta = 'Back to Movements';

  // Bottom navigation
  static const String navDashboard = 'Dashboard';
  static const String navItems = 'Items';
  static const String navScan = 'Scan';
  static const String navMovements = 'Movements';
  static const String navMore = 'More';
  static const String comingSoon = 'Coming soon';
  static const String toggleNavMenu = 'Show or hide menu';

  // More menu
  static const String moreTitle = 'More';
  static const String profileRole = 'Store Staff';
  static const String profileDepartment = 'Maintenance Team';
  static const String profileEmail = 'john.doe@forthports.co.uk';
  static const String profilePhone = '+44 7XXX XXX XXX';
  static const String myProfile = 'My Profile';
  static const String helpSupport = 'Help & Support';
  static const String aboutApp = 'About Forth Ports Dundee';
  static const String logout = 'Logout';
  static const String roleLabel = 'Role';
  static const String departmentLabel = 'Department';
  static const String phoneLabel = 'Phone';
  static const String changePassword = 'Change Password';
  static const String howToIssueStock = 'How to Issue Stock';
  static const String issueStockStep1 = 'Open the Movements tab';
  static const String issueStockStep2 = 'Tap + Issue Stock';
  static const String issueStockStep3 = 'Search and choose the item';
  static const String issueStockStep4 = 'Enter the quantity';
  static const String issueStockStep5 = 'Select purpose / reason and location';
  static const String issueStockStep6 = 'Save to confirm the issue';
  static const String needHelpTitle = 'Need help?';
  static const String contactAdmin = 'Contact Admin';
  static const String contactAdminSub = 'Get in touch with the system admin';
  static const String technicalHelp = 'Need technical help?';
  static const String technicalHelpSub = 'Report an issue or get support';
  static const String aboutParagraph1 =
      'The Forth Ports Dundee Stock Management app helps you track items, '
      'monitor availability, and respond quickly to low-stock alerts.';
  static const String aboutParagraph2 =
      'Use Movements to issue stock, Items to browse inventory, and '
      'Notifications to act on out-of-stock and low-stock warnings.';
  static const String aboutParagraph3 =
      'This app is designed for store and maintenance teams working across '
      'Dundee port facilities.';
  static const String aboutLocationLabel = 'Location';
  static const String aboutLocationValue = 'Dundee';
  static const String aboutCompanyLabel = 'Company';
  static const String aboutCompanyValue = 'Forth Ports';
  static const String logoutConfirmTitle = 'Are you sure you want to log out?';
  static const String logoutConfirmCta = 'Logout';

  // Authentication
  static const String loginWelcome = 'Welcome Back!';
  static const String loginSubtitle = 'Please sign in to continue';
  static const String usernameLabel = 'Username or Email';
  static const String passwordLabel = 'Password';
  static const String rememberMe = 'Remember me';
  static const String forgotPassword = 'Forgot Password?';
  static const String signIn = 'Sign In';
  static const String orDivider = 'or';
  static const String noAccountPrompt = "Don't have an account? ";
  static const String signUp = 'Sign Up';

  // Sign up
  static const String createAccountTitle = 'Create Account';
  static const String createAccountSubtitle =
      'Fill in the details to get started';
  static const String fullNameLabel = 'Full Name';
  static const String emailLabel = 'Email Address';
  static const String usernameOnlyLabel = 'Username';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String alreadyHaveAccount = 'Already have an account? ';

  // Forgot password
  static const String forgotPasswordTitle = 'Forgot Password?';
  static const String forgotPasswordSubtitle =
      "Enter your email address and we'll send you a link to reset your password.";
  static const String sendResetLink = 'Send Reset Link';
  static const String rememberPasswordPrompt = 'Remember your password? ';

  // Verify OTP
  static const String verifyOtpTitle = 'Verify OTP';
  static const String verifyOtpSubtitle =
      'We have sent a 6-digit code to your email address';
  static const String change = 'Change';
  static const String didntReceiveCodePrompt = "Didn't receive the code? ";
  static const String resendOtp = 'Resend OTP';
  static const String verifyOtp = 'Verify OTP';

  /// Demo OTP accepted by the dummy verification flow.
  static const String demoOtp = '123456';

  // Reset password
  static const String resetPasswordTitle = 'Reset Password';
  static const String resetPasswordSubtitle = 'Enter your new password below';
  static const String newPasswordLabel = 'New Password';
  static const String confirmNewPasswordLabel = 'Confirm New Password';
  static const String resetPasswordCta = 'Reset Password';

  // Password strength labels
  static const String strengthWeak = 'Weak';
  static const String strengthFair = 'Fair';
  static const String strengthGood = 'Good';
  static const String strengthStrong = 'Strong';

  // Success screens
  static const String passwordResetSuccessTitle = 'Password Reset Successful';
  static const String passwordResetSuccessMessage =
      'Your password has been reset successfully.';
  static const String backToLogin = 'Back to Login';
  static const String loginSuccessTitle = 'Login Successful';
  static const String loginSuccessMessage =
      'You have been logged in successfully.';
  static const String goToDashboard = 'Go to Dashboard';

  // Validation messages
  static const String usernameRequired = 'Please enter your username or email';
  static const String passwordRequired = 'Please enter your password';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String fullNameRequired = 'Please enter your full name';
  static const String usernameFieldRequired = 'Please choose a username';
  static const String emailRequired = 'Please enter your email address';
  static const String emailInvalid = 'Please enter a valid email address';
  static const String confirmPasswordRequired = 'Please confirm your password';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String otpIncomplete = 'Please enter the 6-digit code';
  static const String otpInvalid = 'Invalid code. Use 123456 for this demo.';
  static const String newPasswordRequired = 'Please enter a new password';

  // Reports
  static const String reportsTitle = 'Reports';

  static const String reportStockSummary = 'Stock Summary';
  static const String reportStockSummarySub = 'Overview of stock status';
  static const String reportLowStock = 'Low Stock Report';
  static const String reportLowStockSub = 'Items below reorder level';
  static const String reportStockInOut = 'Stock In / Out Report';
  static const String reportStockInOutSub = 'Track stock movements';
  static const String reportIssuedStock = 'Issued Stock Report';
  static const String reportIssuedStockSub = 'View issued stock details';
  static const String reportCategory = 'Category Report';
  static const String reportCategorySub = 'Stock by category';
  static const String reportLocation = 'Location Report';
  static const String reportLocationSub = 'Stock by warehouse / location';
  static const String reportExport = 'Export Reports';
  static const String reportExportSub = 'Export and share reports';

  // Report filters / shared
  static const String dateRangeLabelReport = 'Date Range';
  static const String dateLabelReport = 'Date';
  static const String personLabel = 'Person';
  static const String allLocations = 'All Locations';
  static const String allPersons = 'All Persons';

  // Stock summary report
  static const String totalQuantityReport = 'Total Quantity';
  static const String stockStatusDistribution = 'Stock Status Distribution';
  static const String topCategoriesByQty = 'Top Categories by Quantity';
  static const String rankHeader = 'Rank';
  static const String quantityHeader = 'Quantity';
  static const String percentHeader = '%';

  // Low stock report
  static const String totalLowStockItems = 'Total Low Stock Items';
  static const String itemHeader = 'Item';
  static const String currentHeader = 'Current';
  static const String reorderHeader = 'Reorder';
  static const String lowBadge = 'LOW';
  static const String outBadge = 'OUT';
  static const String searchStockItemsHint = 'Search low stock items';

  // Stock in / out report
  static const String stockMovementTrend = 'Stock Movement Trend';
  static const String totalStockIn = 'Total Stock In';
  static const String totalStockOut = 'Total Stock Out';
  static const String netMovementReport = 'Net Movement';

  // Issued stock report
  static const String totalIssuedItems = 'Total Issued Items';
  static const String issuedToHeader = 'Issued To';
  static const String qtyHeader = 'Qty';

  // Category / location report
  static const String stockByCategory = 'Stock by Category (Quantity)';
  static const String stockByLocation = 'Stock by Location (Quantity)';
  static const String totalQtyShort = 'Total Qty';
  static const String locationHeaderReport = 'Location';

  // Export reports
  static const String reportTypeLabel = 'Report Type';
  static const String formatLabel = 'Format';
  static const String previewCta = 'Preview';
  static const String exportCta = 'Export';
  static const String shareReportCta = 'Share Report';
  static const String reportReadyTitle = 'Report Ready';
  static const String reportReadyBody =
      'Your report is ready to download. You can also share it via email.';
  static const String formatPdf = 'PDF';
  static const String formatExcel = 'Excel';
  static const String formatCsv = 'CSV';
  static const String selectReportType = 'Select report type';
}

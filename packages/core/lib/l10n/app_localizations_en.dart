import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  // Common
  @override
  String get appName => 'Nokta';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get clear => 'Clear';

  @override
  String get refresh => 'Refresh';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get tax => 'Tax';

  @override
  String get discount => 'Discount';

  @override
  String get quantity => 'Quantity';

  @override
  String get price => 'Price';

  @override
  String get category => 'Category';

  @override
  String get description => 'Description';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get status => 'Status';

  @override
  String get actions => 'Actions';

  // POS Screen
  @override
  String get posScreen => 'Point of Sale';

  @override
  String get products => 'Products';

  @override
  String get cart => 'Cart';

  @override
  String get checkout => 'Checkout';

  @override
  String get payment => 'Payment';

  @override
  String get receipt => 'Receipt';

  @override
  String get orderType => 'Order Type';

  @override
  String get dineIn => 'Dine In';

  @override
  String get takeaway => 'Takeaway';

  @override
  String get delivery => 'Delivery';

  @override
  String get online => 'Online';

  @override
  String get tableNumber => 'Table Number';

  @override
  String get customerInfo => 'Customer Info';

  @override
  String get specialInstructions => 'Special Instructions';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get removeFromCart => 'Remove from Cart';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get processPayment => 'Process Payment';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get mobilePayment => 'Mobile Payment';

  @override
  String get bankTransfer => 'Bank Transfer';

  // Kitchen Screen
  @override
  String get kitchenDisplay => 'Kitchen Display';

  @override
  String get pendingOrders => 'Pending Orders';

  @override
  String get preparingOrders => 'Preparing Orders';

  @override
  String get readyOrders => 'Ready Orders';

  @override
  String get startPreparing => 'Start Preparing';

  @override
  String get markReady => 'Mark Ready';

  @override
  String get markCompleted => 'Mark Completed';

  @override
  String get orderNumber => 'Order Number';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get notes => 'Notes';

  // Order Management
  @override
  String get orders => 'Orders';

  @override
  String get orderHistory => 'Order History';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get orderStatus => 'Order Status';

  @override
  String get pending => 'Pending';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get preparing => 'Preparing';

  @override
  String get ready => 'Ready';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get refunded => 'Refunded';

  @override
  String get createOrder => 'Create Order';

  @override
  String get updateOrder => 'Update Order';

  @override
  String get cancelOrder => 'Cancel Order';

  // Product Management
  @override
  String get productManagement => 'Product Management';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String get productName => 'Product Name';

  @override
  String get productPrice => 'Product Price';

  @override
  String get productCategory => 'Product Category';

  @override
  String get productDescription => 'Product Description';

  @override
  String get productImage => 'Product Image';

  @override
  String get isAvailable => 'Available';

  @override
  String get outOfStock => 'Out of Stock';

  // Customer Management
  @override
  String get customers => 'Customers';

  @override
  String get customerManagement => 'Customer Management';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get deleteCustomer => 'Delete Customer';

  @override
  String get customerName => 'Customer Name';

  @override
  String get customerPhone => 'Customer Phone';

  @override
  String get customerEmail => 'Customer Email';

  @override
  String get customerAddress => 'Customer Address';

  @override
  String get loyaltyPoints => 'Loyalty Points';

  // Reports and Analytics
  @override
  String get reports => 'Reports';

  @override
  String get analytics => 'Analytics';

  @override
  String get salesReport => 'Sales Report';

  @override
  String get revenueReport => 'Revenue Report';

  @override
  String get productReport => 'Product Report';

  @override
  String get customerReport => 'Customer Report';

  @override
  String get dailySales => 'Daily Sales';

  @override
  String get weeklySales => 'Weekly Sales';

  @override
  String get monthlySales => 'Monthly Sales';

  @override
  String get yearlyReports => 'Yearly Reports';

  @override
  String get topProducts => 'Top Products';

  @override
  String get topCustomers => 'Top Customers';

  // Admin Panel
  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get tenants => 'Tenants';

  @override
  String get users => 'Users';

  @override
  String get tenantManagement => 'Tenant Management';

  @override
  String get userManagement => 'User Management';

  @override
  String get addTenant => 'Add Tenant';

  @override
  String get editTenant => 'Edit Tenant';

  @override
  String get deleteTenant => 'Delete Tenant';

  @override
  String get tenantName => 'Tenant Name';

  @override
  String get subdomain => 'Subdomain';

  @override
  String get subscriptionPlan => 'Subscription Plan';

  @override
  String get tenantStatus => 'Tenant Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get trial => 'Trial';

  @override
  String get suspended => 'Suspended';

  @override
  String get expired => 'Expired';

  // Settings
  @override
  String get generalSettings => 'General Settings';

  @override
  String get storeSettings => 'Store Settings';

  @override
  String get printSettings => 'Print Settings';

  @override
  String get paymentSettings => 'Payment Settings';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get backupSettings => 'Backup Settings';

  @override
  String get systemSettings => 'System Settings';

  // Error Messages
  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get passwordTooShort => 'Password is too short';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get networkError => 'Network error';

  @override
  String get serverError => 'Server error';

  @override
  String get unknownError => 'Unknown error';

  // Success Messages
  @override
  String get loginSuccess => 'Login successful';

  @override
  String get saveSuccess => 'Saved successfully';

  @override
  String get deleteSuccess => 'Deleted successfully';

  @override
  String get updateSuccess => 'Updated successfully';

  @override
  String get orderCreated => 'Order created';

  @override
  String get paymentProcessed => 'Payment processed';

  // Validation Messages
  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get pleaseConfirmPassword => 'Please confirm password';

  @override
  String get pleaseEnterName => 'Please enter name';

  @override
  String get pleaseEnterPhone => 'Please enter phone number';

  @override
  String get pleaseSelectCategory => 'Please select category';

  @override
  String get pleaseEnterPrice => 'Please enter price';

  @override
  String get pleaseEnterQuantity => 'Please enter quantity';
}
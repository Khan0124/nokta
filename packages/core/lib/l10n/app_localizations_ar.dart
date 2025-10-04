import 'app_localizations.dart';

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  // Common
  @override
  String get appName => 'نقطة';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجح';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'موافق';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get search => 'بحث';

  @override
  String get filter => 'تصفية';

  @override
  String get clear => 'مسح';

  @override
  String get refresh => 'تحديث';

  @override
  String get close => 'إغلاق';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get previous => 'السابق';

  @override
  String get settings => 'الإعدادات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get name => 'الاسم';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get address => 'العنوان';

  @override
  String get total => 'الإجمالي';

  @override
  String get subtotal => 'المجموع الجزئي';

  @override
  String get tax => 'الضريبة';

  @override
  String get discount => 'الخصم';

  @override
  String get quantity => 'الكمية';

  @override
  String get price => 'السعر';

  @override
  String get category => 'الفئة';

  @override
  String get description => 'الوصف';

  @override
  String get date => 'التاريخ';

  @override
  String get time => 'الوقت';

  @override
  String get status => 'الحالة';

  @override
  String get actions => 'الإجراءات';

  // POS Screen
  @override
  String get posScreen => 'نقطة البيع';

  @override
  String get products => 'المنتجات';

  @override
  String get cart => 'السلة';

  @override
  String get checkout => 'الدفع';

  @override
  String get payment => 'الدفع';

  @override
  String get receipt => 'الفاتورة';

  @override
  String get orderType => 'نوع الطلب';

  @override
  String get dineIn => 'محلي';

  @override
  String get takeaway => 'خارجي';

  @override
  String get delivery => 'توصيل';

  @override
  String get online => 'أونلاين';

  @override
  String get tableNumber => 'رقم الطاولة';

  @override
  String get customerInfo => 'بيانات العميل';

  @override
  String get specialInstructions => 'ملاحظات خاصة';

  @override
  String get addToCart => 'إضافة للسلة';

  @override
  String get removeFromCart => 'إزالة من السلة';

  @override
  String get clearCart => 'مسح السلة';

  @override
  String get processPayment => 'معالجة الدفع';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get cash => 'نقد';

  @override
  String get card => 'بطاقة';

  @override
  String get mobilePayment => 'دفع إلكتروني';

  @override
  String get bankTransfer => 'حوالة بنكية';

  // Kitchen Screen
  @override
  String get kitchenDisplay => 'شاشة المطبخ';

  @override
  String get pendingOrders => 'طلبات في الانتظار';

  @override
  String get preparingOrders => 'قيد التحضير';

  @override
  String get readyOrders => 'جاهزة للتقديم';

  @override
  String get startPreparing => 'بدء التحضير';

  @override
  String get markReady => 'جاهز للتقديم';

  @override
  String get markCompleted => 'تم الإنجاز';

  @override
  String get orderNumber => 'رقم الطلب';

  @override
  String get estimatedTime => 'الوقت المتوقع';

  @override
  String get notes => 'ملاحظات';

  // Order Management
  @override
  String get orders => 'الطلبات';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get orderStatus => 'حالة الطلب';

  @override
  String get pending => 'في الانتظار';

  @override
  String get confirmed => 'مؤكد';

  @override
  String get preparing => 'قيد التحضير';

  @override
  String get ready => 'جاهز';

  @override
  String get delivered => 'تم التوصيل';

  @override
  String get cancelled => 'ملغي';

  @override
  String get refunded => 'مسترد';

  @override
  String get createOrder => 'إنشاء طلب';

  @override
  String get updateOrder => 'تحديث الطلب';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  // Product Management
  @override
  String get productManagement => 'إدارة المنتجات';

  @override
  String get addProduct => 'إضافة منتج';

  @override
  String get editProduct => 'تعديل المنتج';

  @override
  String get deleteProduct => 'حذف المنتج';

  @override
  String get productName => 'اسم المنتج';

  @override
  String get productPrice => 'سعر المنتج';

  @override
  String get productCategory => 'فئة المنتج';

  @override
  String get productDescription => 'وصف المنتج';

  @override
  String get productImage => 'صورة المنتج';

  @override
  String get isAvailable => 'متوفر';

  @override
  String get outOfStock => 'غير متوفر';

  // Customer Management
  @override
  String get customers => 'العملاء';

  @override
  String get customerManagement => 'إدارة العملاء';

  @override
  String get addCustomer => 'إضافة عميل';

  @override
  String get editCustomer => 'تعديل العميل';

  @override
  String get deleteCustomer => 'حذف العميل';

  @override
  String get customerName => 'اسم العميل';

  @override
  String get customerPhone => 'هاتف العميل';

  @override
  String get customerEmail => 'بريد العميل';

  @override
  String get customerAddress => 'عنوان العميل';

  @override
  String get loyaltyPoints => 'نقاط الولاء';

  // Reports and Analytics
  @override
  String get reports => 'التقارير';

  @override
  String get analytics => 'التحليلات';

  @override
  String get salesReport => 'تقرير المبيعات';

  @override
  String get revenueReport => 'تقرير الأرباح';

  @override
  String get productReport => 'تقرير المنتجات';

  @override
  String get customerReport => 'تقرير العملاء';

  @override
  String get dailySales => 'المبيعات اليومية';

  @override
  String get weeklySales => 'المبيعات الأسبوعية';

  @override
  String get monthlySales => 'المبيعات الشهرية';

  @override
  String get yearlyReports => 'التقارير السنوية';

  @override
  String get topProducts => 'أفضل المنتجات';

  @override
  String get topCustomers => 'أفضل العملاء';

  // Admin Panel
  @override
  String get adminPanel => 'لوحة الإدارة';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get tenants => 'المتاجر';

  @override
  String get users => 'المستخدمين';

  @override
  String get tenantManagement => 'إدارة المتاجر';

  @override
  String get userManagement => 'إدارة المستخدمين';

  @override
  String get addTenant => 'إضافة متجر';

  @override
  String get editTenant => 'تعديل المتجر';

  @override
  String get deleteTenant => 'حذف المتجر';

  @override
  String get tenantName => 'اسم المتجر';

  @override
  String get subdomain => 'النطاق الفرعي';

  @override
  String get subscriptionPlan => 'خطة الاشتراك';

  @override
  String get tenantStatus => 'حالة المتجر';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get trial => 'تجريبي';

  @override
  String get suspended => 'معلق';

  @override
  String get expired => 'منتهي الصلاحية';

  // Settings
  @override
  String get generalSettings => 'الإعدادات العامة';

  @override
  String get storeSettings => 'إعدادات المتجر';

  @override
  String get printSettings => 'إعدادات الطباعة';

  @override
  String get paymentSettings => 'إعدادات الدفع';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get securitySettings => 'إعدادات الأمان';

  @override
  String get backupSettings => 'إعدادات النسخ الاحتياطي';

  @override
  String get systemSettings => 'إعدادات النظام';

  // Error Messages
  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صحيح';

  @override
  String get passwordTooShort => 'كلمة المرور قصيرة جداً';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get networkError => 'خطأ في الشبكة';

  @override
  String get serverError => 'خطأ في الخادم';

  @override
  String get unknownError => 'خطأ غير محدد';

  // Success Messages
  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح';

  @override
  String get saveSuccess => 'تم الحفظ بنجاح';

  @override
  String get deleteSuccess => 'تم الحذف بنجاح';

  @override
  String get updateSuccess => 'تم التحديث بنجاح';

  @override
  String get orderCreated => 'تم إنشاء الطلب';

  @override
  String get paymentProcessed => 'تم معالجة الدفع';

  // Validation Messages
  @override
  String get pleaseEnterValidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get pleaseConfirmPassword => 'يرجى تأكيد كلمة المرور';

  @override
  String get pleaseEnterName => 'يرجى إدخال الاسم';

  @override
  String get pleaseEnterPhone => 'يرجى إدخال رقم الهاتف';

  @override
  String get pleaseSelectCategory => 'يرجى اختيار الفئة';

  @override
  String get pleaseEnterPrice => 'يرجى إدخال السعر';

  @override
  String get pleaseEnterQuantity => 'يرجى إدخال الكمية';
}
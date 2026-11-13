/// Every route path lives here. Use these, never type a path in a screen.

class AppRoutes {
  AppRoutes._();

  // Auth and onboarding
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String driverPartner = '/driver-partner';
  static const String driverRegister1 = '/driver-register-1';
  static const String driverRegister2 = '/driver-register-2';
  static const String driverProfile = '/driver-profile';
  static const String settings = '/settings';

  // Client
  static const String whereFromTo = '/where-from-to';
  static const String itemDetails = '/item-details';
  static const String findingDriver = '/finding-driver/:requestId';

  // Driver
  static const String driverHome = '/driver-home';
  static const String driverJobs = '/driver-jobs';
  static const String jobLogs = '/job-logs';

  // Deal and completion
  static const String driverContact = '/driver-contact/:requestId';
  static const String delivery = '/delivery/:requestId';
  static const String rate = '/rate/:requestId';

  // Helpers: build the real path for a request.
  // Example: context.go(AppRoutes.findingDriverPath(request.id));
  static String findingDriverPath(String requestId) =>
      '/finding-driver/$requestId';
  static String driverContactPath(String requestId) =>
      '/driver-contact/$requestId';
  static String deliveryPath(String requestId) => '/delivery/$requestId';
  static String ratePath(String requestId) => '/rate/$requestId';
}

class AppConstants {
  // App Info
  static const String appName = "Jean's Flower Shop";
  static const String appTagline = "Beautiful blooms, delivered fresh";

  // Store Info
  static const String storeAddress =
      "Dr Miciano Rd, Dumaguete City, 6200 Negros Oriental";
  static const String storePhone = "(555) 123-FLOWER";
  static const String storeEmail = "contact@jeansflowers.com";

  // Store Hours
  static const String weekdayHours = "Mon-Fri: 8:00 AM - 8:00 PM";
  static const String weekendHours = "Sat-Sun: 9:00 AM - 7:00 PM";

  // Delivery
  static const double deliveryFee = 5.99;
  static const double taxRate = 0.08;
  static const int minStemsForCustomBouquet = 5;

  // Pricing - Custom Bouquet Sizes
  static const double customBouquetSmallPrice = 250.0; // 5-14 stems
  static const double customBouquetMediumPrice = 600.0; // 15-24 stems
  static const double customBouquetLargePrice = 1200.0; // 25+ stems

  static const int smallBouquetMaxStems = 14;
  static const int mediumBouquetMaxStems = 24;

  // Pickup Times
  static const List<String> pickupTimeOptions = [
    'ASAP (30-45 minutes)',
    '1-2 hours',
    '2-4 hours',
    'Tomorrow morning (9-12 PM)',
    'Tomorrow afternoon (12-5 PM)',
    'Tomorrow evening (5-8 PM)',
  ];

  // Categories
  static const Map<String, String> categoryMapping = {
    'wedding': 'Mixed',
    'birthday': 'Mixed',
    'roses': 'Roses',
    'sympathy': 'Lilies',
    'seasonal': 'Sunflowers',
    'anniversary': 'Roses',
  };

  // Admin Credentials
  static const String adminEmail = 'admin@example.com';
  static const String driverEmail = 'willblue234@gmail.com';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1280;

  // Supabase credentials
  static const String supabaseUrl = 'https://evbtyrqefvcvyctfwnje.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2YnR5cnFlZnZjdnljdGZ3bmplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2MTg1MzksImV4cCI6MjA3ODE5NDUzOX0.gWRi_fMYDTO_f_bSwyaq6uDvrqwR7Z44Io7kGqLz1Vc';
}

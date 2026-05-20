class AppConstants {
  // SharedPreferences Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyCurrentUser = 'current_user';
  static const String keyUsers = 'registered_users';
  static const String keyHabits = 'habits';
  static const String keyNotifications = 'notifications';
  static const String keyTheme = 'theme_mode';

  // Default credentials
  static const String defaultUsername = 'demo';
  static const String defaultEmail = 'demo';
  static const String defaultPassword = 'demo123';

  // Days of week
  static const List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Notification times
  static const List<String> notificationTimes = [
    'Morning (7:00 AM)',
    'Afternoon (12:00 PM)',
    'Evening (6:00 PM)',
    'Night (9:00 PM)',
  ];

  // Habit categories
  static const List<String> habitCategories = [
    'Health',
    'Fitness',
    'Learning',
    'Mindfulness',
    'Finance',
    'Social',
    'Creativity',
    'Productivity',
  ];

  // Habit frequencies
  static const List<String> habitFrequencies = [
    'Daily',
    'Weekly',
    'Weekdays',
    'Weekends',
  ];
}

// Countries list
const List<String> kCountries = [
  'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Australia', 'Austria',
  'Bangladesh', 'Belgium', 'Bolivia', 'Brazil', 'Canada', 'Chile', 'China',
  'Colombia', 'Croatia', 'Czech Republic', 'Denmark', 'Ecuador', 'Egypt',
  'Ethiopia', 'Finland', 'France', 'Germany', 'Ghana', 'Greece', 'Hungary',
  'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy',
  'Japan', 'Jordan', 'Kenya', 'Malaysia', 'Mexico', 'Morocco', 'Netherlands',
  'New Zealand', 'Nigeria', 'Norway', 'Pakistan', 'Peru', 'Philippines',
  'Poland', 'Portugal', 'Romania', 'Russia', 'Saudi Arabia', 'Singapore',
  'South Africa', 'South Korea', 'Spain', 'Sweden', 'Switzerland', 'Thailand',
  'Turkey', 'Ukraine', 'United Arab Emirates', 'United Kingdom',
  'United States', 'Venezuela', 'Vietnam',
];
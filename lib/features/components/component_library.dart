/// Categories for components: real kinds of website components.
/// Keep this list identical to the one in Decode-Admin.html.
const userCategories = [
  // Basics
  'Buttons', 'Inputs', 'Forms', 'Toggles & Switches', 'Badges & Tags',
  'Alerts & Toasts',
  // Navigation
  'Navbar', 'Sidebar', 'Menus & Dropdowns', 'Tabs & Accordions', 'Pagination',
  'Search',
  // Content
  'Hero Sections', 'Cards', 'Galleries', 'Testimonials', 'Pricing', 'Stats',
  'Timelines', 'Profiles', 'Tables', 'Footers',
  // Feedback
  'Modals & Popups', 'Tooltips', 'Loaders', 'Animations', 'Progress',
  // Pages
  'Login & Signup', 'Landing Pages', 'Dashboards', 'Chat & Messages',
  'E-commerce',
  // Other
  'UI', //
];

/// Older names (and the old "style" categories) mapped to today's list, so
/// components published earlier still show up in a sensible place.
const _legacyCategories = <String, String>{
  'navigation': 'Navbar',
  'nav': 'Navbar',
  'templates': 'Landing Pages',
  'template': 'Landing Pages',
  'neumorphism': 'UI',
  'glassmorphism': 'UI',
  'minimal': 'UI',
  'gradient': 'UI',
  'dark ui': 'UI',
  'brutalism': 'UI',
  'button': 'Buttons',
  'form': 'Forms',
  'card': 'Cards',
  'hero': 'Hero Sections',
  'footer': 'Footers',
  'modal': 'Modals & Popups',
  'loader': 'Loaders',
  'animation': 'Animations',
  'login': 'Login & Signup',
  'signup': 'Login & Signup',
};

/// Returns a category from [userCategories] for any text, or 'UI'.
String normalizeCategory(String value) {
  final text = value.trim().toLowerCase();
  for (final category in userCategories) {
    if (category.toLowerCase() == text) return category;
  }
  return _legacyCategories[text] ?? 'UI';
}

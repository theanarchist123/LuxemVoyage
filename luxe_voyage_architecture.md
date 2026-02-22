# LuxeVoyage – Curated Travel Experiences

## 📦 Recommended Flutter Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_riverpod: ^2.5.1
  
  # UI & Styling
  google_fonts: ^6.2.1        # For elegant serif/sans-serif fonts
  circle_nav_bar: ^0.1.2      # Requested bottom navigation bar
  lucide_icons: ^1.0.3        # Clean, minimal premium icons
  blur: ^3.1.2                # For glassmorphism effects
  flutter_animate: ^4.5.0     # Smooth, premium transitions and micro-animations
  
  # Map & Location
  google_maps_flutter: ^2.5.3 # Dark themed Map integration
```

## 🎨 Theming Setup (ThemeData Configuration)
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color midnightBlue = Color(0xFF0B1C2D);
  static const Color softGold = Color(0xFFD4AF37);
  static const Color deepNavy = Color(0xFF13293D);
  static const Color offWhite = Color(0xFFF5F5F5);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: midnightBlue,
      primaryColor: softGold,
      colorScheme: const ColorScheme.dark(
        primary: softGold,
        surface: deepNavy,
        background: midnightBlue,
        onBackground: offWhite,
        onSurface: offWhite,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(color: offWhite, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.playfairDisplay(color: offWhite, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.playfairDisplay(color: softGold, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.lato(color: offWhite, fontSize: 16),
        bodyMedium: GoogleFonts.lato(color: offWhite, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: softGold,
          foregroundColor: midnightBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 5,
          shadowColor: softGold.withOpacity(0.3),
        ),
      ),
      cardTheme: CardTheme(
        color: deepNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: deepNavy,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: deepNavy),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: softGold, width: 1.5),
        ),
        labelStyle: GoogleFonts.lato(color: offWhite.withOpacity(0.7)),
      ),
    );
  }
}
```

## 🧩 Reusable Components List
1. **`GoldButton`**: Custom elevated button with soft gold background, deep navy text, and subtle scaling animation on press.
2. **`GlassCard`**: Container using `BackdropFilter` combined with the `blur` package for glassmorphism effects over top hero images.
3. **`ExperienceCard`**: Horizontal scrollable card for "Curated Nearby Experiences" featuring a rounded image, gradient bottom-to-top overlay, gold text overlay for place name, and soft drop shadow.
4. **`CircleNavBar`**: Custom implementation mapping to the `circle_nav_bar` package with horizontal padding to prevent stretching the whole width, floating slightly above the bottom, and matching level icons.
5. **`PremiumTextField`**: Text validation inputs for Auth with elegant rounded corners, no harsh borders, and glowing active states.

## ✨ Suggested Animation Types (using `flutter_animate`)
- **Splash Screen**: `.fadeIn(duration: 1500.ms)` + `.scale(begin: 0.9, end: 1.0, curve: Curves.easeOutCubic)`
- **List Items (Staggered)**: `.animate(interval: 100.ms).fade(duration: 500.ms).slideY(begin: 0.1, end: 0)`
- **Hero Image Transition**: Standard Flutter `Hero()` combined with `.fadeIn()` on surrounding text elements upon navigation.
- **Glassmorphism Overlay**: `.shimmer(duration: 2.seconds, color: softGold.withOpacity(0.2))`
- **Bottom Navigation**: Add slight scale jump on icon selection using standard state changes, plus smooth `.slideY(begin: 1, end: 0)` when appearing.

## 📱 Widget Tree Structure For Each Screen

### 1️⃣ Splash Screen
```text
Scaffold
└── Container (Minimalist Background Gradient)
    └── Center
        └── Column (MainAxisAlignment.center)
            ├── Image / SvgPicture (Centered gold logo)
            ├── SizedBox (Padding)
            └── Text ("Curated Travel Experiences", style: serif)
```

### 2️⃣ Authentication Screens
```text
Scaffold (Background: Midnight Blue)
└── SafeArea
    └── SingleChildScrollView
        └── Padding (Large spacing)
            └── Column
                ├── Text ("Welcome Back", style: elegant serif)
                ├── SizedBox
                ├── PremiumTextField (Email)
                ├── SizedBox
                ├── PremiumTextField (Password)
                ├── SizedBox
                ├── GoldButton ("Login")
                ├── SizedBox
                ├── Row (Divider overlaying deep navy line)
                └── Row (Social login icons, e.g., Google)
```

### 3️⃣ Home Dashboard
```text
Scaffold (Background: Midnight Blue)
├── Stack
│   ├── SingleChildScrollView (Smooth scroll)
│   │   └── Column
│   │       ├── Padding (Top section)
│   │       │   └── Row
│   │       │       ├── Column (Greeting + User name)
│   │       │       └── Weather Strip (GlassCard)
│   │       ├── Padding
│   │       │   └── Text ("Curated Nearby Experiences")
│   │       ├── SizedBox (Height)
│   │       ├── ListView.builder (scrollDirection: Axis.horizontal)
│   │       │   └── ExperienceCard (Large image, gradient overlay, rating, soft shadow)
│   │       └── SizedBox (Bottom padding for nav bar)
│   └── Align (Alignment.bottomCenter)
│       └── Padding (horizontal padding to not occupy whole width)
│           └── CustomCircleNavBar (Floating, Soft Gold Icon active, Deep Navy background)
```

### 4️⃣ Place Detail Screen
```text
Scaffold (Background: Midnight Blue)
└── Stack
    ├── CustomScrollView
    │   ├── SliverAppBar (expandedHeight: 400, pinned: true)
    │   │   ├── FlexibleSpaceBar
    │   │   │   └── Hero(Image with gradient overlay)
    │   │   └── leading: IconButton (Back arrow with transparent backdrop)
    │   └── SliverList
    │       └── SliverChildListDelegate
    │           ├── Padding
    │           │   └── Column
    │           │       ├── Row
    │           │       │   ├── Text ("Place name", style: large serif)
    │           │       │   └── IconButton (Save icon)
    │           │       ├── Row (Rating + Location)
    │           │       ├── SizedBox
    │           │       ├── Text ("Description paragraph", style: clean sans-serif)
    │           │       ├── SizedBox
    │           │       └── ReviewSection (Column of review cards)
    └── Align (Alignment.bottomCenter)
        └── Padding
            └── GoldButton ("Private Audio Guide")
```

### 5️⃣ Private Audio Guide Player
```text
Scaffold (Background image with BackdropFilter blur)
└── Center
    └── GlassCard (Minimal floating card)
        └── Padding
            └── Column
                ├── Text ("Audio Guide Title")
                ├── Text ("Location Name")
                ├── Slider (Progress bar, activeColor: softGold)
                ├── Row (MainAxisAlignment.spaceEvenly)
                │   ├── IconButton (Skip previous)
                │   ├── Container (Shape: Circle, color: softGold) -> IconButton (Play/Pause)
                │   └── IconButton (Skip next)
```

### 6️⃣ Memory Vault
```text
Scaffold (Background: Midnight Blue)
├── CustomScrollView
│   ├── SliverAppBar (title: "Memory Vault")
│   └── SliverPadding
│       └── SliverMasonryGrid (from flutter_staggered_grid_view)
│           └── MemoryDetailCard 
│               ├── Image
│               ├── Gradient overlay (bottom)
│               └── Column (Caption, Date, Location tag)
└── floatingActionButton: FloatingActionButton (Gold, adding memory)
```

### 7️⃣ Trip Planner Screen
```text
Scaffold (Background: Midnight Blue)
└── SafeArea
    └── Column
        ├── Text ("Plan Your Escape", style: large serif subtitle)
        ├── Expanded
        │   └── PageView / Stepper
        │       ├── Step 1: DestinationSelection (ListTile/Cards)
        │       ├── Step 2: DurationSelection (Slider or Calendar)
        │       └── Step 3: LuxuryTierSelection (3 Premium Cards: Standard / Premium / Elite)
        └── Padding
            └── GoldButton ("Generate Itinerary")
```

### 8️⃣ Map Screen
```text
Scaffold
└── Stack
    ├── GoogleMap (dark map style JSON applied)
    │   └── Markers (Custom gold icon generated from asset)
    └── SafeArea
        └── Align (Alignment.topCenter)
            └── GlassCard (Minimal search or filter UI)
```

### 9️⃣ Profile Screen
```text
Scaffold (Background: Midnight Blue)
└── SingleChildScrollView
    └── Column
        ├── SizedBox (Padding)
        ├── Center
        │   └── CircleAvatar (Profile Image with Soft Gold Border)
        ├── SizedBox
        ├── Text ("User Name", style: large serif)
        ├── Divider (color: deepNavy)
        ├── Row (Travel Statistics: Trips, Countries, Memories)
        ├── SizedBox
        ├── Text ("Saved Destinations")
        ├── HorizontalList (Minimal ExperienceCards)
        ├── SizedBox
        └── Column (Settings items: ListsTiles with lucide_icons)

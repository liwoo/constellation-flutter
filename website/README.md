# Wordstellation Landing Page

A static landing page built with [Static Shock](https://staticshock.io/), a Dart-based static site generator.

## Prerequisites

- Dart SDK 3.0+

## Getting Started

1. Install dependencies:
```bash
cd website
dart pub get
```

2. Build the site:
```bash
dart run bin/main.dart
```

3. Serve locally (for development):
```bash
dart pub global activate dhttpd
dart pub global run dhttpd --path build --port 8080
```
Then open http://localhost:8080 in your browser.

## Project Structure

```
website/
├── bin/
│   └── main.dart          # Build configuration
├── source/
│   ├── index.html         # Landing page
│   ├── styles/
│   │   └── main.scss      # Sass styles (compiled to CSS)
│   ├── images/            # Static images
│   └── _layouts/          # Jinja templates (optional)
├── build/                 # Generated output (gitignored)
└── pubspec.yaml           # Dart dependencies
```

## Building for Production

The `build/` directory contains the static site ready for deployment to any static hosting service:
- Netlify
- Vercel
- GitHub Pages
- AWS S3 + CloudFront
- Firebase Hosting

## Customization

- **Styles**: Edit `source/styles/main.scss` - uses the same color palette as the app
- **Content**: Edit `source/index.html` directly
- **Images**: Add to `source/images/` - they're copied automatically

## Fonts

The site uses the same fonts as the game:
- **Orbitron** - For headings and display text
- **Exo 2** - For body text

Loaded from Google Fonts via CDN.

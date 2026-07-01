# QuestArena

A real-time multiplayer quiz battle platform.

## Vercel Deployment Instructions

To fix the **404: NOT_FOUND** error on Vercel, ensure your project is configured with the following settings in the Vercel Dashboard:

1.  **Framework Preset**: `Other`
2.  **Build Command**:
    ```bash
    if [ -d "flutter" ]; then cd flutter && git pull && cd ..; else git clone https://github.com/flutter/flutter.git; fi && ./flutter/bin/flutter build web --release
    ```
    *Note: This command clones the Flutter SDK and builds the web app. If you are deploying manually, just build locally and upload the contents of `build/web`.*
3.  **Output Directory**: `build/web`
4.  **Rewrites**: I have added a `vercel.json` file to your project root. This ensures that all URLs are redirected to `index.html`, preventing 404 errors when refreshing the page.

## Local Development

1.  Ensure you have Flutter installed.
2.  Run `flutter pub get`.
3.  Run `flutter run -d chrome`.

# finance_tracker

Digitalize your receipts! 

Take or upload a picture of a receipt and let Gemini AI fill in everything from the receipt: items bought with respective quanitities and prices, currency, total price, category, date and store name in the app.

## Note

- This app is currently available only for Android APKs or Web. Desktop UI is in development. It works, but it's ugly
- This app uses Firebase for Firestore and Authentication, however the firebase_options.dart file is not in the repository. Make your own! 

## Access the app

1. Via web: https://tracker-f7299.web.app/ (mobile phones are recommended)
2. Build an APK:
     1. Clone the repo
     2. Configure your Firebase project with Firestore and Authentication
     3. Replace lib/firebase_options.dart with your own api keys
     4. Run `flutter build apk --no-tree-shake-icons`

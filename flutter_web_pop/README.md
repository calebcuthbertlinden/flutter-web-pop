# Buy this book | Upload proof of payment

This project allows viewers to complete a purchase of a book. 
Once complete they can upload the proof of payment to complete the process.

It is a web app built with Flutter.

## Getting Started

- Checkout this repository, if you have not already
- Download and install Flutter SDK (this will also install Dart)
- Open the terminal/CLI and run `flutter run -d chrome`

## Firebase project
The storage of references and proof of payments happens on firebase. The web app will also be hosted on firebase hosting.
https://console.firebase.google.com/project/buy-book-pop/overview

#### Install Firebase CLI
`npm install -g firebase-tools`
#### Sign in to Google
`firebase login`
#### Install flutterfire CLI
`dart pub global activate flutterfire_cli`
#### Configure Firebase projects
`flutterfire configure --project=buy-book-pop`
This automatically registers your per-platform apps with Firebase and adds a lib/firebase_options.dart configuration file to your Flutter project.

import 'firebase_options.dart';

### Firestore
https://firebase.google.com/products/firestore?gclid=CjwKCAjw_ISWBhBkEiwAdqxb9pgMoMXUFtAtWu11pBqFVVac4s0FfnSOJK7GlM5XW6aVCGXEZDYtUBoCsAcQAvD_BwE&gclsrc=aw.ds
TODO


### Storage
https://firebase.google.com/products/storage?gclid=CjwKCAjw_ISWBhBkEiwAdqxb9jSvFEZBs5Ql1UY00cnAh70_f51RN4Wa3waPrDa3n8-CX1j0fYPtBRoC8hsQAvD_BwE&gclsrc=aw.ds
TODO


### Firebase hosting
https://firebase.google.com/products/hosting?gclid=CjwKCAjw_ISWBhBkEiwAdqxb9pLnjqte8J0hRCWYpr32E3i0vvldw-ZwR7gLP69jvwn4e-XjpQE7xRoC5hYQAvD_BwE&gclsrc=aw.ds

You can deploy now or later. To deploy now, open a terminal window, then navigate to or create a root directory for your web app.

#### When you’re ready, deploy your web app
Put your static files (e.g., HTML, CSS, JS) in your app’s deploy directory (the default is “public”). Then, run this command from your app’s root directory:
`firebase deploy`
After deploying, view your app at buy-book-pop.web.app
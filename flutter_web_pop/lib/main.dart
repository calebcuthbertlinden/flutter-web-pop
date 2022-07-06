import 'dart:async';

// import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  final FirebaseApp app = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  // FirebaseAnalytics analytics = FirebaseAnalytics();
  // FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  runZonedGuarded(() {
    runApp(MyApp(
      app: app,
      // analytics: analytics,
    ));
  }, (_,__)=>{});
}

class MyApp extends StatelessWidget {
  final FirebaseApp app;
  // final FirebaseAnalytics analytics;
  // ignore: use_key_in_widget_constructors
  const MyApp({required this.app, });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buy this Book | Upload proof of payment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Buy this book'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Text(
                'The Journal',
                style: Theme.of(context).textTheme.headline2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
              child: Text(
                'R249.99',
                style: Theme.of(context).textTheme.headline4,
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: ElevatedButton(
                    onPressed: () => {},
                    child: const Text(
                      'Buy book',
                    )),
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: ElevatedButton(
                      onPressed: () => {},
                      child: const Text(
                        'Upload proof of purchase',
                      )))
            ]),
            SizedBox(
              height: 400,
              child: Image.asset(
                "assets/images/book1.png",
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        tooltip: 'Query',
        child: const Icon(Icons.social_distance),
      ),
    );
  }
}

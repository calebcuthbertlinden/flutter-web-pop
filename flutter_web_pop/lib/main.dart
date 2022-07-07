import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  final FirebaseApp app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runZonedGuarded(() {
    runApp(MyApp(
      app: app,
    ));
  }, (_, __) => {});
}

class MyApp extends StatelessWidget {
  final FirebaseApp app;
  // ignore: use_key_in_widget_constructors
  const MyApp({
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buy this Book | Upload proof of payment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Buy this book'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final Reference storageRef = FirebaseStorage.instance.ref();
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// Upload file to firebase storage
  UploadTask uploadString(String name) {
    const String putStringText =
        'This upload has been generated using the putString method! Check the metadata too!';

    // Create a Reference to the file
    Reference ref = FirebaseStorage.instance.ref().child('proof-of-paymets').child('/$name.txt');

    // Start upload of putString
    return ref.putString(
      putStringText,
      metadata: SettableMetadata(
        contentLanguage: 'en',
        customMetadata: <String, String>{'example': 'putString'},
      ),
    );
  }

  /// Pick file for upload
  filePicker(context) async {
    var picked = await FilePicker.platform.pickFiles();
    if (picked != null) {
      uploadString(picked.files.first.name);
      Navigator.of(context, rootNavigator: true).pop("result");
    }
  }

  /// Show dialog to enter reference number and select file
  showDialogForUpload() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
            title: const Text("Upload proof of payment"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                Padding(
                    padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: Text("First enter the reference number for the payment/order")),
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter reference number',
                  ),
                ),
                Padding(
                    padding: EdgeInsets.fromLTRB(0, 8, 0, 8), child: Text("Select file you want to upload")),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => {Navigator.of(context, rootNavigator: true).pop("result")},
                  child: const Text("Cancel")),
              TextButton(onPressed: () => {filePicker(context)}, child: const Text("Select file"))
            ],
            elevation: 24.0);
      },
    );
  }

  generateReferenceAndEmail(context, address) {
    Navigator.of(context, rootNavigator: true).pop("result");
    SnackBar snackBar = SnackBar(
      duration: const Duration(seconds: 10),
      content: Text('Your reference number has been emailed to this address: $address. Once payment is complete, please proceed to upload proof of payment.'),
    );

    // Find the ScaffoldMessenger in the widget tree
    // and use it to show a SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Show dialog for payment details and emailing reference
  showDialogForDetails() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
            title: const Text("Payment details"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Padding(
                    padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: Text("Please enter the email address for the reference number")),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter email address',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => {Navigator.of(context, rootNavigator: true).pop("result")},
                  child: const Text("Cancel")),
              TextButton(onPressed: () => {generateReferenceAndEmail(context, emailController.text)}, child: const Text("Generate reference")),
            ],
            elevation: 24.0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Stack(
        children: [
          Column(
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
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: ElevatedButton(
                      onPressed: () => {showDialogForDetails()},
                      child: const Text(
                        'Buy book',
                      )),
                ),
                Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: ElevatedButton(
                        onPressed: () async {
                          showDialogForUpload();
                        },
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
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        tooltip: 'Query',
        child: const Icon(Icons.social_distance),
      ),
    );
  }
}

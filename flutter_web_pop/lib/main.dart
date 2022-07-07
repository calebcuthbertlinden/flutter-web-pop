import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:random_string/random_string.dart';

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

  updateDatabaseReference(Map<String, dynamic> doc) {
    var firestoreDb = FirebaseFirestore.instance;
    doc["state"] = "COMPLETE";
    firestoreDb
        .collection("orders")
        .doc(doc["reference"])
        .set(doc)
        .then((value) => print('DocumentSnapshot added'))
        .onError((error, stackTrace) => print('DocumentSnapshot added: $error'));
  }

  sendCompleteEmail(context, address, reference) async {
    late SnackBar snackBar;
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    const serviceId = 'service_vsvho66';
    const templateId = 'template_4rj2e0d';
    const userId = 'lffizDAZyIE4RXMr_';
    const accessToken = 's88QszBbXbVv3sBYPJA2l';
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'accessToken': accessToken,
          'template_params': {'reference': reference, 'to_email': address}
        }));

    if (response.statusCode == 200) {
      snackBar = const SnackBar(
        duration: Duration(seconds: 10),
        content: Text(
            'Thank you for uploading your proof of payment.'),
      );
    } else {
      snackBar = const SnackBar(
        duration: Duration(seconds: 10),
        content: Text('There was an error emailing this reference'),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Pick file for upload
  filePicker(context, reference) async {
    // Check if reference exists
    var firestoreDb = FirebaseFirestore.instance;
    final docRef = firestoreDb.collection("orders").doc(reference);
    var emailAddress = "";
    docRef.get().then(
      (DocumentSnapshot doc) {
        print("Document found: $doc");
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (data["state"] == "INITIATED") {
            emailAddress = data["email"];
            FilePicker.platform.pickFiles().then((value) => {
                  if (value != null)
                    {
                      uploadString(value.files.first.name),
                      updateDatabaseReference(data),
                      sendCompleteEmail(context, emailAddress, reference),
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 10),
                          content: Text('Document uploaded for payment reference $reference'),
                        ),
                      ),
                      Navigator.of(context, rootNavigator: true).pop("result")
                    }
                });
          } else if (data["state"] == "COMPLETE") {
            print("Proof of payment already uploaded");
            SnackBar snackBar = const SnackBar(
              duration: Duration(seconds: 10),
              content: Text('Proof of payment already uploaded for this reference'),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            Navigator.of(context, rootNavigator: true).pop("result");
          } else {
            print("Document doesn't exist");
            SnackBar snackBar = const SnackBar(
              duration: Duration(seconds: 10),
              content: Text('There is no existing payment with this reference'),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            Navigator.of(context, rootNavigator: true).pop("result");
          }
        } else {
          print("Document doesn't exist");
          SnackBar snackBar = const SnackBar(
            duration: Duration(seconds: 10),
            content: Text('There is no existing payment with this reference'),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          Navigator.of(context, rootNavigator: true).pop("result");
        }
      },
      onError: (e) => print("Error getting document: $e"),
    ).onError((error, stackTrace) => null);
  }

  /// Show dialog to enter reference number and select file
  showDialogForUpload() {
    final referenceController = TextEditingController();
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
              children: [
                const Padding(
                    padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: Text("First enter the reference number for the payment/order")),
                TextField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter reference number',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => {Navigator.of(context, rootNavigator: true).pop("result")},
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () => {filePicker(context, referenceController.text)},
                  child: const Text("Select file"))
            ],
            elevation: 24.0);
      },
    );
  }

  generateReferenceAndEmail(context, address) async {
    late SnackBar snackBar;

    String reference = randomAlphaNumeric(10);

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    const serviceId = 'service_vsvho66';
    const templateId = 'template_ywkh5rk';
    const userId = 'lffizDAZyIE4RXMr_';
    const accessToken = 's88QszBbXbVv3sBYPJA2l';
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'accessToken': accessToken,
          'template_params': {'to_name': "Caleb", 'reference': reference, 'to_email': address}
        }));

    if (response.statusCode == 200) {
      snackBar = SnackBar(
        duration: const Duration(seconds: 10),
        content: Text(
            'Your reference number has been emailed to this address: $address. Once payment is complete, please proceed to upload proof of payment.'),
      );
    } else {
      snackBar = const SnackBar(
        duration: Duration(seconds: 10),
        content: Text('There was an error emailing this reference'),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    Navigator.of(context, rootNavigator: true).pop("result");

    var firestoreDb = FirebaseFirestore.instance;
    final order = <String, dynamic>{
      "reference": reference,
      "email": address,
      "state": "INITIATED"
    };
    firestoreDb
        .collection("orders")
        .doc(reference)
        .set(order)
        .then((value) => print('DocumentSnapshot added'))
        .onError((error, stackTrace) => print('DocumentSnapshot added: $error'));
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
              TextButton(
                  onPressed: () => {generateReferenceAndEmail(context, emailController.text)},
                  child: const Text("Generate reference")),
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

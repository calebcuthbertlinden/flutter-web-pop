import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:random_string/random_string.dart';

import 'firebase_options.dart';

const serviceId = 'service_vsvho66';
const userId = 'lffizDAZyIE4RXMr_';
const accessToken = 's88QszBbXbVv3sBYPJA2l';
final emailUrl = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

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

  /// Show snack bar notification
  showSnackBar(context, String snackbarText) {
    late SnackBar snackBar = SnackBar(
      duration: const Duration(seconds: 10),
      content: Text(snackbarText),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  // Firebase firestore integration
  // ---------------------------------------------------------------------------

  createDatabaseReference(reference, address) {
    var firestoreDb = FirebaseFirestore.instance;
    final order = <String, dynamic>{"reference": reference, "email": address, "state": "INITIATED"};
    firestoreDb
        .collection("orders")
        .doc(reference)
        .set(order)
        .then((value) => log('DocumentSnapshot added', name: 'generateReferenceAndEmail'))
        .onError(
            (error, stackTrace) => log('DocumentSnapshot added: $error', name: 'generateReferenceAndEmail'));
  }

  updateDatabaseReference(Map<String, dynamic> doc) {
    const functionName = 'updateDatabaseReference';
    var firestoreDb = FirebaseFirestore.instance;
    doc["state"] = "COMPLETE";
    firestoreDb
        .collection("orders")
        .doc(doc["reference"])
        .set(doc)
        .then((value) => log('DocumentSnapshot added', name: functionName))
        .onError((error, stackTrace) => log('DocumentSnapshot added: $error', name: functionName));
  }

  // Send Email through EmailJS
  // ---------------------------------------------------------------------------

  sendEmail(templateParams, templateId) async {
    return await http.post(emailUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'accessToken': accessToken,
          'template_params': templateParams
        }));
  }

  sendCompleteEmail(context, address, reference) async {
    final response = await sendEmail({'reference': reference, 'to_email': address}, "template_4rj2e0d");
    if (response.statusCode == 200) {
      showSnackBar(context, 'Thank you for uploading your proof of payment.');
    } else {
      showSnackBar(context, 'There was an error emailing this reference');
    }
  }

  sendInitiateEmail(reference, address) async {
    final response = await sendEmail(
        {'reference': reference, 'to_email': address}, "template_ywkh5rk");
    return response;
  }

  // Actions initiated from each alert dialog
  // ---------------------------------------------------------------------------

  filePicker(context, reference) async {
    const functionName = 'filePicker';
    // Check if reference exists
    var firestoreDb = FirebaseFirestore.instance;
    final docRef = firestoreDb.collection("orders").doc(reference);
    var emailAddress = "";
    docRef.get().then(
      (DocumentSnapshot doc) {
        log("Document found: $doc", name: 'filePicker');
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
            log("Proof of payment already uploaded", name: functionName);
            showSnackBar(context, 'Proof of payment already uploaded for this reference');
            Navigator.of(context, rootNavigator: true).pop("result");
          } else {
            log("Document doesn't exist", name: functionName);
            showSnackBar(context, 'There is no existing payment with this reference');
            Navigator.of(context, rootNavigator: true).pop("result");
          }
        } else {
          log("Document doesn't exist", name: functionName);
          showSnackBar(context, 'There is no existing payment with this reference');
          Navigator.of(context, rootNavigator: true).pop("result");
        }
      },
      onError: (e) => log("Error getting document: $e", name: functionName),
    ).onError((error, stackTrace) => null);
  }

  generateReferenceAndEmail(context, address) async {
    String reference = randomAlphaNumeric(10);
    var response = await sendInitiateEmail(reference, address);
    if (response.statusCode == 200) {
      showSnackBar(context,
          'Your reference number has been emailed to this address: $address. Once payment is complete, please proceed to upload proof of payment.');
    } else {
      showSnackBar(context, 'There was an error emailing this reference');
    }
    Navigator.of(context, rootNavigator: true).pop("result");
    createDatabaseReference(reference, address);
  }

  // Alert Dialogs for generating a reference or uploading proof of purchase
  // ---------------------------------------------------------------------------

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

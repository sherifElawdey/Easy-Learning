import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:easy_learning/home/home.dart';
import 'package:easy_learning/login/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_youtube_downloader/flutter_youtube_downloader.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_login_facebook/flutter_login_facebook.dart';
import 'package:path_provider/path_provider.dart';

Color appColor=Color(0xFFFB7445);
Color appColorLight=Color(0xBCFB7445);
Color blueColor=Color(0xFF122132);
Color blueColorLight=Color(0xBE364F6B);



void goToPage(BuildContext context, Widget widget) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return widget;
  }));
}
void goToPageReplace(BuildContext context, Widget widget) {
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
    return widget;
  }));
}
void backToPage(BuildContext context) {
  Navigator.pop(context);
}

void customSnackBar({required String msg,required BuildContext context}) {
  final snackbar= SnackBar(
    backgroundColor: appColor,
    content: Text(msg,
      style: TextStyle(color: Colors.white, letterSpacing: 0.5),
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackbar);
}

void showAlertDialog(String title, Widget widget,BuildContext context){
  AlertDialog alertDialog = AlertDialog(
    title: Text(title),
    content: widget,
  );
  showDialog(context: context, builder: (_) => alertDialog);
}

TextStyle textStyle(double size, FontWeight fontWeight) => TextStyle(
      color: Colors.white,
      fontFamily: 'Montserrat',
      fontSize: size,
      fontWeight: fontWeight
    );

Future<User?> signUpWithEmail(String email, String password, afterRegister(), onError()) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = (await auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  )).user;
  if (user != null) {
    afterRegister();
  } else {
    onError();
  }
}

Future<User?> signInWithGoogle({required BuildContext context,required FirebaseAuth auth}) async {
  User?user;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

  if(googleSignInAccount != null) {
    final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
    );
    try {
    final UserCredential userCredential = await auth.signInWithCredential(credential);
    user = userCredential.user!;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
          customSnackBar(msg: 'The account already exists with a different credential.',context: context);
      }else if (e.code == 'invalid-credential') {
        customSnackBar(msg:'Error occurred while accessing credentials. Try again.',context: context);
      }
    } catch (e) {
        customSnackBar(msg: 'Error occurred using Google Sign-In. Try again.',context: context);
      }
  }

  return user;
}

Future<void>forgotPass(BuildContext context,String email,FirebaseAuth auth) async{
  if(email.isEmpty){
      customSnackBar(msg: 'please add your email!!', context: context);
    return;
  }
  if(!email.contains('@')&& !email.endsWith('.com')){
      customSnackBar(msg: 'please add a valid email !!', context: context);
    return;
  }
  Future<FirebaseAuth> user= (await auth.sendPasswordResetEmail(email:email)) as Future<FirebaseAuth>;
  user.then((value) {
    customSnackBar(msg: 'we have sent you a link on this email', context: context);
  }).onError((error, stackTrace) {customSnackBar(msg: '$error', context: context);});
}

Future<void> signInWithFacebook(BuildContext context,Widget widget)async{
  final facebook= FacebookLogin();
  final result = await facebook.logIn(permissions: [
    FacebookPermission.publicProfile,
    FacebookPermission.email,
  ]);
  // Check result status
  switch (result.status) {
    case FacebookLoginStatus.success:
    // Logged in

    // Send this access token to server for validation and auth
      final accessToken = result.accessToken;
      //print('Access Token: ${accessToken!.token}');
      // Get profile data
      //final profile = await facebook.getUserProfile();
      //print('Hello, ${profile!.name}! You ID: ${profile.userId}');
      // Get email (since we request email permission)
      //final email = await facebook.getUserEmail();
      // But user can decline permission
      //if (email != null) print('And your email is $email');
      goToPage(context, widget);
      customSnackBar(msg: 'signIn successfully ', context: context);
      break;
    case FacebookLoginStatus.cancel:
      customSnackBar(msg: 'signIn canceled ', context: context);
      break;
    case FacebookLoginStatus.error:
    // Log in failed
      print('Error while log in: ${result.error}');
      customSnackBar(msg: 'Error occurred using Facebook Sign-In. please Try again with another email', context: context);
      break;
  }
}

Future<void> signOut({required BuildContext context}) async {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  try {
    if (!kIsWeb) {await googleSignIn.signOut();}
    await FirebaseAuth.instance.signOut();
    goToPageReplace(context, SignIn());
  } catch(e) {
    customSnackBar(msg: 'Error signing out. Try again.',context: context);
  }
}

Future<FirebaseApp> initializeFirebase({required BuildContext context}) async {
  FirebaseApp firebaseApp = await Firebase.initializeApp();
  User? user = FirebaseAuth.instance.currentUser;
  /// for auto login
  if (user != null) {
    goToPageReplace(context, Home());
  }

  return firebaseApp;
}

UploadTask? uploadFile(String destination, File file) {
  try {
    final ref = FirebaseStorage.instance.ref(destination);
    return ref.putFile(file);
  } on FirebaseException catch (e) {
    return null;
  }
}

UploadTask? uploadBytes(String destination, Uint8List data) {
  try {
      final ref = FirebaseStorage.instance.ref(destination);
      return ref.putData(data);
    } on FirebaseException catch (e) {
    return null;
  }
}

class VideoFile{
  final Reference ref;
  final String name;
  final String url;

  VideoFile({required this.ref, required this.name, required this.url});
}

Future downloadFirebaseVideo(Reference ref) async {
final dir = await getApplicationDocumentsDirectory();
final file = File('${dir.path}/${ref.name}');
await ref.writeToFile(file);
}

/*Future<String?> extractYoutubeLink(String youTubeLink) async {
  String link;
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    link = await FlutterYoutubeDownloader.extractYoutubeLink(youTubeLink, 18);
  } on PlatformException {
    link = 'Failed to Extract YouTube Video Link.';
  }

  // If the widget was removed from the tree while the asynchr onous platform
  // message was in flight, we want to discard the reply rather than calling
  // setState to update our non-existent appearance.
  if (link==null) return null;
  return link ;
}*/

/*
Future<void> downloadYoutubeVideo(String youtubeLink,String nameOfVideo) async {
  final result = await FlutterYoutubeDownloader.downloadVideo(youtubeLink, '$nameOfVideo.', 18);
}
*/

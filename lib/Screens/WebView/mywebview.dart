import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyWebView extends StatefulWidget {
  final String url;

  const MyWebView({super.key, required this.url});

  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  late WebView webView;
  final String _prefIsSignedIn = 'is_signed_in';
  bool _isSignedIn = false;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    webView = WebView(
      initialUrl: widget.url,
      javascriptMode: JavascriptMode.unrestricted,
      onPageStarted: (String url) {
        if (_requiresGoogleSignIn(url) && !_isSignedIn) {
          _signInWithGoogle();
        }
      },
      onPageFinished: (String url) {
        // You can add any logic here that needs to be executed when the page finishes loading
      },
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
    );
    _checkSignInStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'W E B V I E W',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.grey[100],
      ),
      body: SafeArea(
        child: webView,
      ),
    );
  }

  bool _requiresGoogleSignIn(String url) {
    return url.contains("https://accounts.google.com/");
  }

  Future<void> _checkSignInStatus() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      _isSignedIn = preferences.getBool(_prefIsSignedIn) ?? false;
    });
  }

  Future<void> _signInWithGoogle() async {
    // For demonstration purposes, let's assume sign-in is successful after 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // Update sign-in status and save to SharedPreferences
    setState(() {
      _isSignedIn = true;
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_prefIsSignedIn, _isSignedIn);

    // Reload the WebView with the desired URL
    _webViewController.reload();
  }
}


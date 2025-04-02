import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void launchURL(String url) async {
  // Ensure URL starts with "https://"
  if (!url.startsWith('http')) {
    url = 'https://$url';
  }

  final Uri uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch $url');
  }
}

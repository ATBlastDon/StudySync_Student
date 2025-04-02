import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Future<void> showZoomedProfile(BuildContext context, String? userProfilePhotoUrl) async {
  ImageProvider? imageProvider;
  if (userProfilePhotoUrl != null) {
    if (userProfilePhotoUrl.startsWith('http')) {
      imageProvider = CachedNetworkImageProvider(userProfilePhotoUrl);
    } else {
      imageProvider = AssetImage(userProfilePhotoUrl);
    }
  }

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withAlpha(0),
              ),
            ),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: CircleAvatar(
                radius: 150,
                backgroundColor: Colors.white,
                backgroundImage: imageProvider,
              ),
            ),
          ],
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperDialog extends StatelessWidget {
  final Function(String?) onWallpaperSelected;
  final VoidCallback? onClearWallpaper;

  const WallpaperDialog({
    super.key,
    required this.onWallpaperSelected,
    this.onClearWallpaper, // Add this line
  });


  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Select Background Wallpaper',
              style: TextStyle(
                fontFamily: "Outfit",
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildWallpaperPreview(
                    'assets/wallpaper/predefined1.jpg',
                    'Wallpaper 1',
                    context,
                  ),
                  const SizedBox(width: 8.0),
                  _buildWallpaperPreview(
                    'assets/wallpaper/predefined2.jpg',
                    'Wallpaper 2',
                    context,
                  ),
                  const SizedBox(width: 8.0),
                  _buildWallpaperPreview(
                    'assets/wallpaper/predefined3.jpg',
                    'Wallpaper 3',
                    context,
                  ),
                  const SizedBox(width: 8.0),
                  _buildWallpaperPreview(
                    'assets/wallpaper/predefined4.jpg',
                    'Wallpaper 4',
                    context,
                  ),
                  const SizedBox(width: 8.0),
                  _buildWallpaperPreview(
                    'assets/wallpaper/predefined5.jpg',
                    'Wallpaper 5',
                    context,
                  ),
                  const SizedBox(width: 8.0),
                  _buildWallpaperPreview(
                    'assets/wallpaper/predefined6.jpg',
                    'Wallpaper 6',
                    context,
                  ),
                  const SizedBox(width: 8.0),
                  _buildWallpaperPreview(
                    'assets/wallpaper/predefined7.jpg',
                    'Wallpaper 7',
                    context,
                  ),
                  const SizedBox(width: 8.0),
                  _buildWallpaperPreview(
                    'assets/wallpaper/predefined8.jpg',
                    'Wallpaper 8',
                    context,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  onClearWallpaper?.call();
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Remove Wallpaper',
                  style: TextStyle(
                    fontFamily: "Outfit",
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWallpaperPreview(String imageUrl, String name, BuildContext context) {
    return GestureDetector(
      onTap: () {
        onWallpaperSelected(imageUrl); // Set selected wallpaper
        _saveSelectedWallpaperUrl(imageUrl); // Save selected wallpaper URL
        Navigator.of(context).pop(); // Close the dialog
      },
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              image: DecorationImage(
                image: AssetImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            name,
            style: const TextStyle(fontSize: 14.0),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSelectedWallpaperUrl(String? url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_wallpaper_url', url ?? ''); // Save selected wallpaper URL
  }
}

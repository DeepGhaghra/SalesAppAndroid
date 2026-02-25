import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sales_app/app/core/utils/extension.dart';

import '../utils/app_colors.dart';

// A map to cache colors based on a unique identifier (e.g., name or id)
final Map<String, Color> _colorCache = {};

class BaseImageView extends StatelessWidget {
  const BaseImageView({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.errorWidget,
    this.nameLetters,
    this.circleColor,
    this.fontSize = 24.0,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final String? nameLetters;
  final Color? circleColor;
  final double? fontSize;

  Color _getPersistentColor(String key) {
    // Check if the color is already cached
    if (_colorCache.containsKey(key)) {
      return _colorCache[key]!;
    } else {
      // Generate a new color and cache it
      final newColor = generateDarkRandomColor();
      _colorCache[key] = newColor;
      return newColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use nameLetters as the unique identifier to generate the same color each time
    final uniqueKey = nameLetters ?? imageUrl;

    // Use cached color for the given key (name or imageUrl)
    final persistentColor = _getPersistentColor(uniqueKey);

    return imageUrl.isNotEmpty
        ? CachedNetworkImage(
      imageUrl: imageUrl,
      width: width ?? 80,
      height: height ?? 80,
      errorWidget: (context, url, error) {
        if (errorWidget == null) {
          return (nameLetters?.isNotEmpty ?? false)
              ? Container(
            width: width ?? 80,
            height: height ?? 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor ?? persistentColor.withAlpha(80),
            ),
            child: Center(
              child: Text(
                "nameLetters?.getFirstTwoWordInitials() "?? "",
                style: TextStyle(fontSize: 16 , color:  persistentColor),
              ),
            ),
          )
              : SvgPicture.asset(
          "",
            width: width ?? 80,
            height: height ?? 80,
            fit: BoxFit.fitWidth,
          );
        } else {
          return errorWidget!;
        }
      },
      placeholder: (context, url) => SvgPicture.asset(
      "",
        width: width ?? 80,
        height: height ?? 80,
        fit: BoxFit.fitWidth,
      ),
      fit: BoxFit.cover,
    )
        : (nameLetters?.isNotEmpty ?? false)
        ? Container(
      width: width ?? 80,
      height: height ?? 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor ?? persistentColor.withAlpha(80),
      ),
      child: Center(
        child: Text(
          nameLetters?.getFirstTwoWordInitials  () ?? "",
          style:TextStyle(color: persistentColor ,fontSize: 16),
        ),
      ),
    )
        : SvgPicture.asset(
    "",
      width: width ?? 80,
      height: height ?? 80,
      fit: BoxFit.fitWidth,
    );
  }
}

Color generateDarkRandomColor() {
  final random = Random();

  // Generate random values for red, green, blue (0 to 127) to ensure a dark color
  int red = random.nextInt(128); // 0-127 (dark shades)
  int green = random.nextInt(128); // 0-127 (dark shades)
  int blue = random.nextInt(128); // 0-127 (dark shades)

  // Return a Color using the generated RGB values
  return Color.fromRGBO(red, green, blue, 1.0); // Alpha value is 1.0 (fully opaque)
}

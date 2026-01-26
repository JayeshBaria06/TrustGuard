import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final iconSize = 1024;
  final purple = img.ColorRgba8(103, 80, 164, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);

  // Background icon
  final icon = img.Image(width: iconSize, height: iconSize);
  img.fill(icon, color: purple);

  // Shield points
  final shieldPoints = [
    img.Point(256, 200),
    img.Point(768, 200),
    img.Point(768, 600),
    img.Point(512, 850),
    img.Point(256, 600),
  ];

  // Draw shield on background icon (optional, but good for preview)
  img.drawPolygon(icon, vertices: shieldPoints, color: white, thickness: 40);

  // Checkmark points
  img.drawLine(
    icon,
    x1: 400,
    y1: 500,
    x2: 500,
    y2: 650,
    color: white,
    thickness: 40,
  );
  img.drawLine(
    icon,
    x1: 500,
    y1: 650,
    x2: 700,
    y2: 350,
    color: white,
    thickness: 40,
  );

  Directory('assets/icons').createSync(recursive: true);
  File('assets/icons/app_icon.png').writeAsBytesSync(img.encodePng(icon));

  // Foreground icon (transparent)
  final fgIcon = img.Image(width: iconSize, height: iconSize, numChannels: 4);
  img.fill(fgIcon, color: img.ColorRgba8(0, 0, 0, 0));

  img.drawPolygon(fgIcon, vertices: shieldPoints, color: white, thickness: 40);
  img.drawLine(
    fgIcon,
    x1: 400,
    y1: 500,
    x2: 500,
    y2: 650,
    color: white,
    thickness: 40,
  );
  img.drawLine(
    fgIcon,
    x1: 500,
    y1: 650,
    x2: 700,
    y2: 350,
    color: white,
    thickness: 40,
  );

  File(
    'assets/icons/app_icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(fgIcon));

  // ignore: avoid_print
  print('Icons generated successfully in assets/icons/');
}

import 'package:flutter/material.dart';

class FutureImage extends StatelessWidget {
  final Future<ImageProvider> future;
  final double? width;
  final double? height;
  final double? opacity;
  const FutureImage({
    super.key,
    required this.future,
    this.width,
    this.height,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? Image(
                image: snapshot.data!,
                width: width,
                height: height,
                fit: BoxFit.cover,
                opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
              )
              : Container(color: Colors.grey);
        },
      ),
    );
  }
}

IconData mediaIcon(String? mediaType) {
  if (mediaType?.contains('audio') == true) {
    return Icons.volume_up_rounded;
  }
  return Icons.question_mark_rounded;
}

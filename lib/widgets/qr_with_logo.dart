import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrWithLogo extends StatelessWidget {
  final String data;
  final double size;

  const QrWithLogo({super.key, required this.data, this.size = 260});

  static const _blue = Color(0xFF002856);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: data,
            size: size,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: _blue,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: _blue,
            ),
          ),
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/monting_logo.jpeg'),
          ),
        ],
      ),
    );
  }
}

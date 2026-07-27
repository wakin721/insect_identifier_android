import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({
    required this.imageBytes,
    super.key,
  });

  final Uint8List imageBytes;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final CropController _cropController = CropController();
  bool _cropping = false;

  void _startCrop() {
    if (_cropping) {
      return;
    }
    setState(() => _cropping = true);
    _cropController.crop();
  }

  void _handleCropResult(CropResult result) {
    if (result is CropSuccess) {
      if (mounted) {
        Navigator.of(context).pop(result.croppedImage);
      }
      return;
    }

    if (result is CropFailure && mounted) {
      setState(() => _cropping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('裁切失败：${result.cause}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('裁切昆虫主体'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Crop(
                  image: widget.imageBytes,
                  controller: _cropController,
                  onCropped: _handleCropResult,
                  aspectRatio: 1,
                  initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                    size: 0.86,
                    aspectRatio: 1,
                  ),
                  interactive: true,
                  fixCropRect: true,
                  radius: 18,
                  baseColor: Colors.black,
                  maskColor: Colors.black.withAlpha(150),
                  progressIndicator: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  overlayBuilder: (context, rect) => const IgnorePointer(
                    child: CustomPaint(painter: _CropGridPainter()),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: <Widget>[
                  const Text(
                    '双指缩放并拖动照片，使昆虫完整位于方框内',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cropping
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _cropping ? null : _startCrop,
                          icon: _cropping
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(_cropping ? '正在裁切' : '裁切并识别'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropGridPainter extends CustomPainter {
  const _CropGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(105)
      ..strokeWidth = 1;
    final oneThirdWidth = size.width / 3;
    final oneThirdHeight = size.height / 3;
    canvas
      ..drawLine(
        Offset(oneThirdWidth, 0),
        Offset(oneThirdWidth, size.height),
        paint,
      )
      ..drawLine(
        Offset(oneThirdWidth * 2, 0),
        Offset(oneThirdWidth * 2, size.height),
        paint,
      )
      ..drawLine(
        Offset(0, oneThirdHeight),
        Offset(size.width, oneThirdHeight),
        paint,
      )
      ..drawLine(
        Offset(0, oneThirdHeight * 2),
        Offset(size.width, oneThirdHeight * 2),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

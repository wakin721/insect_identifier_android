import 'dart:async';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import 'result_screen.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({
    required this.imageBytes,
    required this.controller,
    super.key,
  });

  final Uint8List imageBytes;
  final AppController controller;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final CropController _cropController = CropController();
  bool _cropping = false;
  bool _recognizing = false;

  bool get _busy => _cropping || _recognizing;

  void _startCrop() {
    if (_busy) {
      return;
    }
    setState(() => _cropping = true);
    _cropController.crop();
  }

  Future<void> _handleCropResult(CropResult result) async {
    if (result is CropSuccess) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cropping = false;
        _recognizing = true;
      });
      await WidgetsBinding.instance.endOfFrame;
      try {
        final record = await widget.controller.recognize(
          result.croppedImage,
        );
        if (!mounted) {
          return;
        }
        unawaited(
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute<void>(
              builder: (context) => ResultScreen(
                record: record,
                taxonomy: widget.controller.taxonomy,
              ),
            ),
          ),
        );
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() => _recognizing = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(_recognitionErrorMessage(error))),
          );
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

  String _recognitionErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('MODEL_NOT_FOUND') ||
        raw.contains('insect_classifier_fp32.tflite') ||
        raw.contains('insect_classifier_w8a16.tflite')) {
      return '未找到移动端模型。请让 GitHub Actions 完成模型导出后重新安装应用。';
    }
    if (raw.contains('TimeoutException')) {
      return '模型加载超时。请在开发者选项中关闭 GPU 推理或切换模型后重试。';
    }
    return '识别失败：$raw';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: !_busy,
          title: Text(_recognizing ? '正在识别昆虫' : '裁切昆虫主体'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Stack(
          children: <Widget>[
            Column(
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
                        initialRectBuilder:
                            InitialRectBuilder.withSizeAndRatio(
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
                        overlayBuilder: (context, rect) =>
                            const IgnorePointer(
                          child: CustomPaint(
                            painter: _CropGridPainter(),
                          ),
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
                                onPressed: _busy
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
                                onPressed: _busy ? null : _startCrop,
                                icon: _busy
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.auto_awesome_rounded,
                                      ),
                                label: Text(
                                  _recognizing
                                      ? '正在识别'
                                      : _cropping
                                          ? '正在裁切'
                                          : '裁切并识别',
                                ),
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
            if (_recognizing) ...<Widget>[
              const ModalBarrier(
                dismissible: false,
                color: Colors.black54,
              ),
              Center(
                child: Card(
                  color: const Color(0xFF202124),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        CircularProgressIndicator(),
                        SizedBox(height: 18),
                        Text(
                          '正在识别昆虫',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '本地模型正在分析裁切结果',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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

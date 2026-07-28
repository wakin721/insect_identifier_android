import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/app_controller.dart';
import '../widgets/model_status_banner.dart';
import 'crop_screen.dart';

class RecognizeScreen extends StatefulWidget {
  const RecognizeScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  State<RecognizeScreen> createState() => _RecognizeScreenState();
}

class _RecognizeScreenState extends State<RecognizeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _selectingImage = false;

  bool get _busy => _selectingImage || widget.controller.recognizing;

  Future<void> _selectAndRecognize(ImageSource source) async {
    if (_busy) {
      return;
    }

    setState(() => _selectingImage = true);
    try {
      final selected = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 92,
      );
      if (selected == null || !mounted) {
        return;
      }

      final sourceBytes = await selected.readAsBytes();
      if (!mounted) {
        return;
      }

      final cropRoute = MaterialPageRoute<void>(
        builder: (context) => CropScreen(
          imageBytes: sourceBytes,
          controller: widget.controller,
        ),
      );
      final cropResult = Navigator.of(context).push<void>(cropRoute);
      await WidgetsBinding.instance.endOfFrame;
      unawaited(widget.controller.prepareModel());

      await cropResult;
      await cropRoute.completed;
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _selectingImage = false);
      }
    }
  }

  void _showError(Object error) {
    final raw = error.toString();
    late final String message;
    if (raw.contains('camera_access_denied')) {
      message = '未获得相机权限。请在 Android 系统设置中允许“昆虫识别”使用相机。';
    } else if (raw.contains('MODEL_NOT_FOUND') ||
        raw.contains('insect_classifier_fp32.tflite') ||
        raw.contains('insect_classifier_w8a16.tflite')) {
      message = '未找到移动端模型。请先运行 tool/export_model.py，或让 GitHub Actions 完成模型导出。';
    } else {
      message = '识别失败：$raw';
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      '拍摄或导入昆虫照片',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '将主体裁切为正方形后，YOLO 分类模型会在设备上给出置信度最高的 3 个结果。',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    _CaptureCard(
                      busy: _busy,
                      onCamera: () => _selectAndRecognize(ImageSource.camera),
                      onGallery: () => _selectAndRecognize(ImageSource.gallery),
                    ),
                    const SizedBox(height: 16),
                    ModelStatusBanner(
                      state: widget.controller.modelState,
                      recognizing: widget.controller.recognizing,
                    ),
                    const SizedBox(height: 20),
                    const _TipsCard(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.busy,
    required this.onCamera,
    required this.onGallery,
  });

  final bool busy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bug_report_rounded,
                size: 58,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              busy ? '正在处理…' : '选择照片来源',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: busy ? null : onCamera,
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('拍照识别'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('从相册导入'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '拍摄建议',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const _Tip(icon: Icons.center_focus_strong, text: '让昆虫主体尽量占满裁切框'),
            const _Tip(icon: Icons.wb_sunny_outlined, text: '保持光线均匀，避免强烈反光'),
            const _Tip(icon: Icons.blur_off_rounded, text: '确保翅、触角和体表纹理清晰'),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

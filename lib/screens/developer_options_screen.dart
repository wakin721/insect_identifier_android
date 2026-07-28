import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../controllers/developer_settings_controller.dart';
import '../models/model_variant.dart';

class DeveloperOptionsScreen extends StatefulWidget {
  const DeveloperOptionsScreen({
    required this.appController,
    required this.developerSettingsController,
    super.key,
  });

  final AppController appController;
  final DeveloperSettingsController developerSettingsController;

  @override
  State<DeveloperOptionsScreen> createState() =>
      _DeveloperOptionsScreenState();
}

class _DeveloperOptionsScreenState extends State<DeveloperOptionsScreen> {
  bool _switchingInference = false;
  bool _closingDeveloperMode = false;

  Future<void> _selectModel(ModelVariant variant) async {
    if (_switchingInference ||
        (variant == widget.developerSettingsController.modelVariant &&
            widget.appController.modelState != ModelRuntimeState.error)) {
      return;
    }

    final previousModel =
        widget.developerSettingsController.modelVariant;
    final previousUseGpu = widget.developerSettingsController.useGpu;
    setState(() => _switchingInference = true);
    try {
      await widget.appController.switchInferenceConfiguration(
        modelVariant: variant,
        useGpu: previousUseGpu,
      );
      try {
        await widget.developerSettingsController.updateInferenceSettings(
          modelVariant: variant,
          useGpu: previousUseGpu,
        );
      } catch (error) {
        await widget.appController.switchInferenceConfiguration(
          modelVariant: previousModel,
          useGpu: previousUseGpu,
        );
        rethrow;
      }
      await widget.appController.prepareModel();
      _throwIfModelPreparationFailed();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '已切换到 ${variant.displayName}，本地模型已就绪。',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('模型切换失败：$error')),
        );
    } finally {
      if (mounted) {
        setState(() => _switchingInference = false);
      }
    }
  }

  Future<void> _setUseGpu(bool useGpu) async {
    if (_switchingInference ||
        useGpu == widget.developerSettingsController.useGpu) {
      return;
    }

    final modelVariant =
        widget.developerSettingsController.modelVariant;
    final previous = widget.developerSettingsController.useGpu;
    setState(() => _switchingInference = true);
    try {
      await widget.appController.switchInferenceConfiguration(
        modelVariant: modelVariant,
        useGpu: useGpu,
      );
      try {
        await widget.developerSettingsController.updateInferenceSettings(
          modelVariant: modelVariant,
          useGpu: useGpu,
        );
      } catch (error) {
        await widget.appController.switchInferenceConfiguration(
          modelVariant: modelVariant,
          useGpu: previous,
        );
        rethrow;
      }
      await widget.appController.prepareModel();
      _throwIfModelPreparationFailed();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              useGpu
                  ? '已启用 GPU 推理，本地模型已就绪。'
                  : '已切换为 CPU 推理，本地模型已就绪。',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('推理设备切换失败：$error')),
        );
    } finally {
      if (mounted) {
        setState(() => _switchingInference = false);
      }
    }
  }

  void _throwIfModelPreparationFailed() {
    if (widget.appController.modelState == ModelRuntimeState.error) {
      throw StateError(
        widget.appController.lastError ?? '模型加载失败，请切换推理配置后重试。',
      );
    }
  }

  Future<void> _disableDeveloperMode() async {
    if (_switchingInference ||
        _closingDeveloperMode ||
        widget.appController.recognizing) {
      return;
    }

    setState(() => _closingDeveloperMode = true);
    try {
      await widget.developerSettingsController.disableDeveloperMode();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('关闭开发者选项失败：$error')),
        );
    } finally {
      if (mounted) {
        setState(() => _closingDeveloperMode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('开发者选项')),
      body: ListenableBuilder(
        listenable: widget.developerSettingsController,
        builder: (context, _) {
          return ListenableBuilder(
            listenable: widget.appController,
            builder: (context, _) {
              final selected =
                  widget.developerSettingsController.modelVariant;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Text(
                    '推理模型',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: <Widget>[
                        for (final variant
                            in ModelVariant.values) ...<Widget>[
                          _ModelVariantTile(
                            variant: variant,
                            selected: selected == variant,
                            enabled: !_switchingInference &&
                                !_closingDeveloperMode &&
                                !widget.appController.recognizing,
                            onTap: () => _selectModel(variant),
                          ),
                          if (variant != ModelVariant.values.last)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '推理设备',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: SwitchListTile(
                      secondary: const Icon(Icons.memory_rounded),
                      title: const Text('使用 GPU 推理'),
                      subtitle: const Text(
                        'FP32 和 W8A16 均可请求 GPU；初始化超过 20 秒会提示失败，'
                        '此时可关闭 GPU 或切换模型。',
                      ),
                      value: widget.developerSettingsController.useGpu,
                      onChanged: !_switchingInference &&
                              !_closingDeveloperMode &&
                              !widget.appController.recognizing
                          ? (useGpu) {
                              unawaited(_setUseGpu(useGpu));
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.science_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'W8A16 使用校准后的 INT16 激活，可减小模型体积，'
                              '但速度与精度会因校准数据和设备而异。'
                              '更改选项不会删除识别历史。',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '开发者模式',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: SwitchListTile(
                      secondary: const Icon(Icons.developer_mode_outlined),
                      title: const Text('启用开发者选项'),
                      subtitle: const Text(
                        '关闭后保留当前推理模型和设备设置；再次连续点击版本号 7 次可重新启用。',
                      ),
                      value: true,
                      onChanged: !_switchingInference &&
                              !_closingDeveloperMode &&
                              !widget.appController.recognizing
                          ? (enabled) {
                              if (!enabled) {
                                unawaited(_disableDeveloperMode());
                              }
                            }
                          : null,
                    ),
                  ),
                  if (_switchingInference) ...<Widget>[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ModelVariantTile extends StatelessWidget {
  const _ModelVariantTile({
    required this.variant,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ModelVariant variant;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      enabled: enabled,
      selected: selected,
      leading: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: selected ? colorScheme.primary : null,
      ),
      title: Text(variant.displayName),
      subtitle: Text(variant.description),
      onTap: enabled ? onTap : null,
    );
  }
}

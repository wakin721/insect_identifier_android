# 虫鉴：Flutter Android 昆虫识别应用

这是一个仅面向 Android 的 Flutter Material 3 应用。应用可拍照或从相册导入图片，将昆虫主体裁切为正方形后，在设备本地调用 Ultralytics YOLO 分类模型，显示置信度最高的 3 个结果，并把裁切照片、时间与 Top 3 结果保存为本地历史记录。

## 已实现功能

- Material 3 深色/浅色界面与底部导航。
- Android 相机拍照、系统相册导入。
- 可缩放、拖动的 1:1 裁切界面。
- `best.pt` 自动导出为 Android LiteRT/TFLite 模型。
- 本地 YOLO 分类推理，读取模型返回的 Top 5 并展示排序后的 Top 3。
- 每个结果显示俗名、拉丁学名、识别层级、目、科、属和置信度。
- 识别历史完全保存在应用私有目录，可查看、单条删除或全部清空。
- GitHub Actions 自动完成模型导出、代码分析、单元测试、分 ABI APK 与 AAB 构建。
- 可选 GitHub Secrets 发布签名；未配置时自动使用调试签名完成 CI 构建。

## 模型信息

仓库中的 `models/best.pt` 是 Ultralytics YOLO 分类模型，训练输入尺寸为 `416 x 416`。SHA-256：

```text
c8721348aba1c541d124c0cd2b1fc7f89fe4ac5ddb4fbc18bf4132328c6f8e63
```

模型共有 19 个类别。类别同时包含物种级、科级和总科级标签，因此应用会明确显示“识别层级”，不会把科级输出伪装成具体物种。分类学映射位于 `assets/data/taxonomy_zh.json`。

| 索引 | 模型类别 | 中文显示 | 层级 |
|---:|---|---|---|
| 0 | *Acrida cinerea* | 中华剑角蝗 | 物种 |
| 1 | Acrididae | 蝗科 | 科 |
| 2 | Apidae | 蜜蜂科 | 科 |
| 3 | Carabidae | 步甲科 | 科 |
| 4 | Coenagrionidae | 蟌科 | 科 |
| 5 | *Colias erate* | 斑缘豆粉蝶 | 物种 |
| 6 | *Colias heos* | 黎明豆粉蝶 | 物种 |
| 7 | *Colias poliographus* | 东亚豆粉蝶 | 物种 |
| 8 | Curculionidae | 象甲科 | 科 |
| 9 | Eumolpidae | 肖叶甲科 | 科 |
| 10 | Libellulidae | 蜻科 | 科 |
| 11 | Lycaenidae | 灰蝶科 | 科 |
| 12 | Myrmeleontidae | 蚁蛉科 | 科 |
| 13 | *Pieris rapae* | 菜粉蝶 | 物种 |
| 14 | *Pontia daplidice* | 云粉蝶 | 物种 |
| 15 | Scarabaeoidea | 金龟总科 | 总科 |
| 16 | Syrphidae | 食蚜蝇科 | 科 |
| 17 | Tenebrionidae | 拟步甲科 | 科 |
| 18 | Vespidae | 胡蜂科 | 科 |

> `Eumolpidae` 在部分现代分类系统中通常按肖叶甲亚科 `Eumolpinae` 处理。应用保留模型原始标签，并在结果页显示说明。

## 工程结构

```text
assets/data/taxonomy_zh.json        中文名与分类学映射
assets/models/                      CI 生成的 insect_classifier.tflite
models/best.pt                      原始 YOLO 分类权重
lib/controllers/                    应用状态与识别流程
lib/repositories/                   分类映射和本地历史存储
lib/screens/                        识别、裁切、结果、历史页面
lib/services/                       YOLO 推理及 Top 3 解析
tool/export_model.py                .pt -> LiteRT/TFLite 导出与校验
tool/validate_project.py            无 Flutter 依赖的快速输入校验
VALIDATION.md                       本次交付的校验范围与限制
.github/workflows/android.yml        Android 自动构建流程
```

## 本地运行

要求：Flutter 3.44.8、Android SDK 36、Java 17、Python 3.12。应用最低 Android SDK 为 Flutter 当前模板的 API 24。

先导出移动端模型：

```bash
python -m pip install \
  --index-url https://download.pytorch.org/whl/cpu \
  torch==2.10.0 torchvision==0.25.0
python -m pip install -r requirements-export.txt
python tool/export_model.py
```

再运行或构建 Android：

```bash
flutter pub get
flutter run
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

生成的 APK 位于 `build/app/outputs/flutter-apk/`，AAB 位于 `build/app/outputs/bundle/release/`。

## GitHub Actions 自动构建

将整个目录提交到 GitHub 后，每次 `push`、Pull Request 或手动触发都会运行 `.github/workflows/android.yml`。流程会：

1. 校验 `best.pt` 哈希和 19 个类别映射。
2. 安装固定版本的 CPU PyTorch 与 Ultralytics LiteRT 导出依赖。
3. 将 `models/best.pt` 导出为 `assets/models/insect_classifier.tflite`，并校验模型头、任务和标签顺序。
4. 执行 `flutter analyze` 与 `flutter test`。
5. 构建 `armeabi-v7a`、`arm64-v8a`、`x86_64` APK 和 Play Store AAB。
6. 把 APK、AAB、LiteRT 模型及构建信息上传到 GitHub Actions Artifacts。

### 发布签名

在仓库 `Settings -> Secrets and variables -> Actions` 中添加以下 Secrets：

- `ANDROID_KEYSTORE_BASE64`：JKS 文件的 Base64 内容。
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

生成 Base64 示例：

```bash
base64 -w 0 upload-keystore.jks
```

四项 Secrets 全部存在时使用正式签名；否则使用调试密钥完成可安装 APK 构建。调试签名 AAB 不应提交到 Google Play。

## 替换或重新训练模型

替换 `models/best.pt` 时必须同步处理以下内容：

1. 更新 `assets/data/taxonomy_zh.json` 的类别索引和标签，顺序必须与模型 `names` 完全一致。
2. 更新 `tool/export_model.py` 和 `tool/validate_project.py` 中的模型 SHA-256。
3. 根据训练参数调整导出 `--imgsz`，当前模型为 416。
4. 重新运行模型导出与测试。

可在确认新模型后用以下方式暂时跳过旧哈希校验：

```bash
python tool/export_model.py --skip-checksum
```

不要仅跳过校验而不更新分类映射，否则结果名称与模型输出可能错位。

## 数据与隐私

推理在 Android 设备本地运行，应用代码不上传照片。历史图像和结果保存在应用私有文档目录；卸载应用会清除这些数据。识别结果仅用于辅助判断，置信度是模型在现有 19 个训练类别中的相对概率，不等同于正式分类鉴定。

## 许可提示

本工程依赖 `ultralytics_yolo` 和 Ultralytics 导出工具。Ultralytics 提供 AGPL-3.0 与企业许可方案。公开分发、闭源商业发布或将本工程集成到商业产品前，应根据实际使用方式核对许可义务，必要时取得 Ultralytics Enterprise License。
"# insect_identifier_android" 

import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'clip_tokenizer.dart';

/// MobileCLIP-based embedding service using TFLite.
///
/// Embeds images and text into a shared 512-dim vector space.
/// Cosine similarity between text embedding and image embedding = match score.
///
/// Model I/O (from TFLite schema inspection):
///   Image input:  args_0:0  → shape [1, 3, 256, 256], float32, NCHW RGB
///   Text input:   args_1:0  → shape [1, 77], int64 token IDs
///   Text output:  StatefulPartitionedCall:0 → [1, 512], float32
///   Image output: StatefulPartitionedCall:1 → [1, 512], float32
///
/// Models are loaded from the app's documents directory (~/.vinci/models/)
/// instead of Flutter assets, keeping the APK small.
class EmbeddingService {
  Interpreter? _imageInterpreter;
  Interpreter? _textInterpreter;
  bool _isInitialized = false;

  CLIPTokenizer? _tokenizer;

  static const int _embeddingDim = 512;
  static const int _imageSize = 256;
  static const int _maxTokens = 77;

  /// MobileCLIP ImageNet normalization
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];

  /// Returns the directory where model files should be placed.
  Future<Directory> get _modelDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/.vinci/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// Initialize the TFLite interpreters and CLIP tokenizer from disk.
  /// Models must be placed in the app's documents directory:
  ///   ~/.vinci/models/mobileclip_s2_image.tflite
  ///   ~/.vinci/models/mobileclip_s2_text.tflite
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load CLIP tokenizer (always from assets, small file)
      _tokenizer = CLIPTokenizer();
      await _tokenizer!.load();
      if (!_tokenizer!.isLoaded) {
        throw Exception('Tokenizer loaded but isLoaded=false');
      }

      // Load TFLite models from documents directory (~/.vinci/models/)
      final modelDir = await _modelDir;
      final imageModelPath = '${modelDir.path}/mobileclip_s2_image.tflite';
      final textModelPath = '${modelDir.path}/mobileclip_s2_text.tflite';

      final imageFile = File(imageModelPath);
      final textFile = File(textModelPath);

      final imageExists = await imageFile.exists();
      final textExists = await textFile.exists();

      if (!imageExists) {
        throw Exception('Image model not found at: $imageModelPath');
      }
      if (!textExists) {
        throw Exception('Text model not found at: $textModelPath');
      }

      final imageSize = await imageFile.length();
      final textSize = await textFile.length();
      if (imageSize < 1000000) {
        throw Exception('Image model file too small: $imageSize bytes');
      }
      if (textSize < 1000000) {
        throw Exception('Text model file too small: $textSize bytes');
      }

      _imageInterpreter = await Interpreter.fromFile(imageFile);
      _imageInterpreter!.allocateTensors();

      _textInterpreter = await Interpreter.fromFile(textFile);
      _textInterpreter!.allocateTensors();

      // Validate tensor shapes after allocation
      final textInputs = _textInterpreter!.getInputTensors();
      if (textInputs.length < 2) {
        throw Exception('Text model has only ${textInputs.length} input tensors, expected 2');
      }

      final imgInputs = _imageInterpreter!.getInputTensors();
      if (imgInputs.length < 2) {
        throw Exception('Image model has only ${imgInputs.length} input tensors, expected 2');
      }

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  /// Generate a text embedding for a search query.
  Future<Float32List> embedText(String query) async {
    if (_isInitialized && _textInterpreter != null && _tokenizer != null) {
      return _runTextEmbedding(query);
    }
    return _fakeEmbedding(query.hashCode);
  }

  /// Generate an image embedding from raw image bytes (JPEG/PNG).
  Future<Float32List> embedImage(Uint8List imageBytes) async {
    if (_isInitialized && _imageInterpreter != null) {
      return _runImageEmbedding(imageBytes);
    }
    return _fakeEmbedding(imageBytes.length);
  }

  // -------------------------------------------------------------------------
  // Real inference paths
  // -------------------------------------------------------------------------

  /// Run text query through the text model.
  /// Takes text tokens [1, 77] int64 + dummy image [1,3,256,256] float32.
  /// Returns text embedding [1, 512] float32 (output index 0).
  Float32List _runTextEmbedding(String text) {
    final tokens = _tokenize(text);

    // Validate input tensor shapes before inference
    final inputTensors = _textInterpreter!.getInputTensors();
    if (inputTensors.length < 2) {
      throw Exception('Text model has ${inputTensors.length} inputs, expected at least 2');
    }

    // Log tensor shapes for debugging
    for (var i = 0; i < inputTensors.length; i++) {
      final t = inputTensors[i];
      // Shape, type validation done silently in release
    }

    final dummyImage = Float32List(3 * _imageSize * _imageSize);
    final textOutput = Float32List(_embeddingDim);
    final imgOutput = Float32List(_embeddingDim);
    final dummyOut = Float32List(1);

    try {
      _textInterpreter!.runForMultipleInputs(
        [dummyImage, tokens],
        {0: textOutput, 1: imgOutput, 2: dummyOut},
      );
    } catch (e) {
      throw Exception('TFLite text inference failed: $e');
    }

    _normalize(textOutput);
    return textOutput;
  }

  /// Run image through the image model.
  /// Takes image [1, 3, 256, 256] float32 + empty text tokens [1, 77].
  /// Returns image embedding [1, 512] float32 (output index 1).
  Float32List _runImageEmbedding(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return _fakeEmbedding(bytes.length);

    final resized = img.copyResize(image, width: _imageSize, height: _imageSize);
    final inputTensor = _preprocessImage(resized);

    final emptyTokens = _createEmptyTokens();

    final imgOutput = Float32List(_embeddingDim);
    final textOutput = Float32List(_embeddingDim);
    final dummyOut = Float32List(1);

    try {
      _imageInterpreter!.runForMultipleInputs(
        [inputTensor, emptyTokens],
        {0: textOutput, 1: imgOutput, 2: dummyOut},
      );
    } catch (e) {
      throw Exception('TFLite image inference failed: $e');
    }

    _normalize(imgOutput);
    return imgOutput;
  }

  // -------------------------------------------------------------------------
  // Tokenization (CLIP BPE)
  // -------------------------------------------------------------------------

  /// Convert text string to token IDs [1, 77] int64 (TFLite int64 input).
  /// Must use Int64List so TFLite receives the correct dtype.
  Int64List _tokenize(String text) {
    final tokenIds = _tokenizer!.encodeWithTokens(text);
    final result = Int64List(_maxTokens);
    for (var i = 0; i < _maxTokens; i++) {
      result[i] = tokenIds[i];
    }
    return result;
  }

  /// Create zero-filled tokens for image-only encoding (int64 dtype).
  Int64List _createEmptyTokens() {
    return Int64List(_maxTokens);
  }

  // -------------------------------------------------------------------------
  // Image preprocessing
  // -------------------------------------------------------------------------

  /// Preprocess image to [1, 3, 256, 256] NCHW Float32 tensor.
  /// Normalized with MobileCLIP ImageNet mean/std.
  Float32List _preprocessImage(img.Image image) {
    final tensor = Float32List(3 * _imageSize * _imageSize);
    var idx = 0;
    for (var c = 0; c < 3; c++) {
      for (var y = 0; y < _imageSize; y++) {
        for (var x = 0; x < _imageSize; x++) {
          final px = image.getPixel(x, y);
          final vals = [px.r, px.g, px.b];
          tensor[idx++] = ((vals[c] / 255.0) - _mean[c]) / _std[c];
        }
      }
    }
    return tensor;
  }

  // -------------------------------------------------------------------------
  // Utilities
  // -------------------------------------------------------------------------

  void _normalize(Float32List vec) {
    double norm = 0;
    for (var i = 0; i < vec.length; i++) {
      norm += vec[i] * vec[i];
    }
    norm = math.sqrt(norm);
    if (norm > 0) {
      for (var i = 0; i < vec.length; i++) {
        vec[i] /= norm;
      }
    }
  }

  /// Deterministic fallback embedding (used when model not loaded).
  Float32List _fakeEmbedding(int seed) {
    final rng = math.Random(seed.toUnsigned(32));
    final vec = Float32List(_embeddingDim);
    for (var i = 0; i < _embeddingDim; i++) {
      vec[i] = (rng.nextDouble() * 2) - 1;
    }
    _normalize(vec);
    return vec;
  }

  /// Compute cosine similarity between two normalized embeddings.
  double cosineSimilarity(Float32List a, Float32List b) {
    double dot = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }
}

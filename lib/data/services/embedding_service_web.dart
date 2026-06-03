// Conditional import — resolves to the right implementation per platform.
// Import this file instead of directly importing embedding_service or web_embedding_service.
import 'embedding_service_stub.dart'
    if (dart.library.ffi) 'embedding_service.dart'
    if (dart.library.html) 'web_embedding_service.dart';

export 'embedding_service_stub.dart'
    if (dart.library.ffi) 'embedding_service.dart'
    if (dart.library.html) 'web_embedding_service.dart';
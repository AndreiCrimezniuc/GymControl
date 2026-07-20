import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';

import 'package:gymboss/config/api_config.dart';

/// Network image for exercise media. Resolves relative API paths (e.g. a
/// self-hosted illustration "/api/v1/exercise-images/x.png") to an absolute URL
/// and caches the bytes on disk — so an illustration seen once keeps rendering
/// offline. Shows a spinner while loading and a caller-provided fallback on
/// error (e.g. our drawn mannequin).
class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final int? cacheWidth;
  final double? width;
  final double? height;
  final WidgetBuilder fallback;

  const NetImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.cacheWidth,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: ApiConfig.resolveImageUrl(url),
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: cacheWidth,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) =>
          const Center(child: CupertinoActivityIndicator(radius: 8)),
      errorWidget: (ctx, _, __) => fallback(ctx),
    );
  }
}

import 'package:bargain/productadd/grid_layout/image_model.dart';
import 'package:flutter/material.dart';

class ImageAdapter extends StatelessWidget {
  final List<ImageModel> images;
  final Function(ImageModel) onImageTap;

  const ImageAdapter({
    super.key,
    required this.images,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Center(child: Text("No products available"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 items per row
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imageModel = images[index];

        final String imageUrl =
        imageModel.imageUrls.isNotEmpty ? imageModel.imageUrls.first : "";

        return GestureDetector(
          onTap: () => onImageTap(imageModel),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Thumbnail with safe fallback
                Expanded(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(
                        child: Icon(Icons.broken_image, size: 40)),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_not_supported,
                          size: 40, color: Colors.black54),
                    ),
                  ),
                ),

                // Info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title (subcategory / category)
                      Text(
                        imageModel.subcategory.isNotEmpty
                            ? imageModel.subcategory
                            : imageModel.category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Location
                      Text(
                        imageModel.location.isNotEmpty
                            ? imageModel.location
                            : "Unknown location",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // Price + Likes row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "₹${imageModel.price ?? 'N/A'}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.favorite,
                                  size: 14, color: Colors.redAccent),
                              const SizedBox(width: 3),
                              Text(
                                "${imageModel.likeCount}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

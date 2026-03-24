import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_section.dart';

class LocationPhotoGallerySection extends StatelessWidget {
  const LocationPhotoGallerySection({
    super.key,
    required this.photoUrls,
    required this.category,
  });

  final List<String> photoUrls;
  final LocationCategory category;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(category.colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LocationDetailInset(
          top: 24,
          child: LocationDetailSectionTitle('Photos'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: photoUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final photoUrl = photoUrls[index];
              return ClipRRect(
                key: ValueKey(photoUrl),
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  width: 172,
                  height: 130,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => SizedBox(
                    width: 172,
                    height: 130,
                    child: CategoryShimmer(color: categoryColor),
                  ),
                  errorWidget: (_, _, _) => SizedBox(
                    width: 172,
                    height: 130,
                    child: CategoryGradient(category: category),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

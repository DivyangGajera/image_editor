Implement the image import, cropping, and filter pipeline.

1. Create ImageImportService:
 - Integrate image_picker to select from Camera or Gallery.
 - Pass the picked file to image_cropper with preset aspect ratios: 1:1 (Square), 4:5 (Instagram Post), 9:16 (Story/Reel), 16:9 (Landscape), and Free crop.

2. Once cropped, save the image into the project sandbox via ProjectRepository.saveLayerImage.

3. Implement color filters in lib/core/utils/color_filters.dart:
 - Grayscale, Warm/Cloudy (reddish tint), Cool (blue tint), High Contrast.
 - Represent filters as 4x5 ColorFilter.matrix transformations so Flutter renders them on the GPU with 0 CPU overhead.

4. Create an editing toolbar that lets users toggle filters and flip images horizontally."
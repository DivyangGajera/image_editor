Build the Collage & Filmstrip creation tool in lib/features/collage/.

1. Implement layout algorithms in CollageEngine:
 - horizontalStrip(List<String> imagePaths, double spacing)
 - verticalStrip(List<String> imagePaths, double spacing)
 - gridMatrix(List<String> imagePaths, int rows, int cols, double spacing)

2. Allow user configuration:
 - Border width slider.
 - Border color picker.
 - Outer margin slider.

3. Create a dedicated CollageSetupScreen where users select 2 to 9 images, choose a layout preset, adjust borders, and click 'Create Project'.

4. Convert the generated layout positions into individual ImageLayers on a unified ProjectModel so the user can continue freely editing every piece inside the main canvas.
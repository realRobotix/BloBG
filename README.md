# BloBG

BloBG is a Blob Background shader entirely written in
[GLSL](https://www.khronos.org/opengl/wiki/Core_Language_(GLSL)).  
It's using a custom [Simplex noise](https://en.wikipedia.org/wiki/Simplex_noise) implementation as a base which is then used to create the Blobs.  
The entire image finally gets some film grain applied to it to avoid color banding.

**Update 1:** Now with better performance and easier customization!

**Update 2:** Doesn't use Perlin noise anymore, but simplex noise increasing performance even more!  
Also added a new feature to change the color of the blobs and a new color mix mode.  
The HSV color mix mode will interpolate the colors in the HSV color space instead of RGB.

[![website](https://cdn.jsdelivr.net/npm/@intergrav/devins-badges@3/assets/cozy/documentation/website_vector.svg)](https://realrobotix.github.io/BloBG/)

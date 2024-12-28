/*
See the LICENSE.txt file for this sample’s licensing information.
*/

#ifndef VignetteSettings_h
#define VignetteSettings_h

struct VignetteSettings {
    // Distance at which the vignette effect starts; in uv units from the center.
    float offset;
    // Distance of spread of the vignette effect; in uv units.
    float softness;
};

#endif /* VignetteSettings_h */

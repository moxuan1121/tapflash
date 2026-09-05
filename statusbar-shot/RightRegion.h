#pragma once
#include <stdbool.h>
#include <math.h>

static inline bool RSSInRightRegion(double x, double y, double width, double height) {
    // ponytail: fixed right third; use device-specific notch bounds only if needed.
    return isfinite(x) && isfinite(y) && isfinite(width) && isfinite(height) &&
           width > 0 && height > 0 && x >= width * (2.0 / 3.0) &&
           x < width && y >= 0 && y < height;
}

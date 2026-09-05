#pragma once
#include <stdbool.h>
#include <math.h>

static inline bool RSSInRightRegion(double x, double y, double width, double height) {
    // ponytail: the right half includes the usable area immediately beside the notch.
    return isfinite(x) && isfinite(y) && isfinite(width) && isfinite(height) &&
           width > 0 && height > 0 && x >= width * 0.5 &&
           x < width && y >= 0 && y < height;
}

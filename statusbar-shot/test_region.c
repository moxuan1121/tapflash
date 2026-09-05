#include "RightRegion.h"
#include <assert.h>
#include <stdio.h>

int main(void) {
    assert(RSSInRightRegion(300, 20, 428, 47));
    assert(RSSInRightRegion(200, 0, 300, 47));
    assert(!RSSInRightRegion(199.9, 20, 300, 47));
    assert(!RSSInRightRegion(50, 20, 428, 47));
    assert(!RSSInRightRegion(300, 47, 428, 47));
    assert(!RSSInRightRegion(428, 20, 428, 47));
    assert(!RSSInRightRegion(300, -1, 428, 47));
    assert(!RSSInRightRegion(0, 0, 0, 0));
    assert(!RSSInRightRegion(NAN, 20, 428, 47));
    assert(!RSSInRightRegion(300, 20, INFINITY, 47));
    assert(RSSInRightRegion(800, 10, 926, 24));
    puts("Right-region boundary checks passed");
}

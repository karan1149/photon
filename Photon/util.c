// Copyright (c) 2015-2017 Anish Athalye (me@anishathalye.com)
// Released under GPLv3. See the included LICENSE.txt for details

#include "util.h"
#include <math.h>

double clip(double value, double low, double high)
{
    return (value < low) ? (low) : (value > high ? high : value);
}

double srgb_to_lightness(double red, double green, double blue)
{
    red /= 255.0;
    green /= 255.0;
    blue /= 255.0;
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
}

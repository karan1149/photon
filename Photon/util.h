// Copyright (c) 2015-2017 Anish Athalye (me@anishathalye.com)
// Released under GPLv3. See the included LICENSE.txt for details

#ifndef __Photon__util__
#define __Photon__util__

double linear_interpolate(double x0, double y0, double x1, double y1, double xq);

double clip(double value, double low, double high);

// brightness (L* coordinate) ranges from 0 to 100
double srgb_to_lightness(double red, double green, double blue);

#endif /* defined(__Photon__util__) */

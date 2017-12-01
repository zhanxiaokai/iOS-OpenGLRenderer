#ifndef VIDEO_EFFECT_RGBA_FRAME_H
#define VIDEO_EFFECT_RGBA_FRAME_H

#include <string>

class RGBAFrame {
public:
	float position;
	float duration;
	uint8_t * pixels;
	int width;
	int height;
	RGBAFrame();
	~RGBAFrame();
	RGBAFrame* clone();
};

#endif //VIDEO_EFFECT_RGBA_FRAME_H


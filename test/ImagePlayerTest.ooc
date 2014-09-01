use ooc-image-player
use ooc-draw
use ooc-draw-gpu
use ooc-math
import os/Time

player := ImagePlayer new("input/Z2jpeg/", callBack)
window := Window create(IntSize2D new(1680.0f, 1050.0f), "Video renderer")
player play()
callBack: func (frame: RasterImage) {
  window draw(frame)
}

while(true) {
}

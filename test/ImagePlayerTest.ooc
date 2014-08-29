use ooc-image-player
use ooc-draw
use ooc-draw-gpu
use ooc-math
import os/Time

window := Window create(IntSize2D new(1680.0f, 1050.0f), "Video renderer")
player := ImagePlayer new("input/Z2jpeg/", callBack)
player play()
callBack: func (frame: RasterImage) {
  window draw(frame)
}

while(true) {
}

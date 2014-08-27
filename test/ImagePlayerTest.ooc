use ooc-image-player
use ooc-draw
use ooc-math
import os/Time

renderer := ImageRenderer create(IntSize2D new(1680.0f / 2, 1050.0f / 2))
player := ImagePlayer new("input/Z2/", frameCallback)

frameCallback: func (image: RasterBgra, player: ImagePlayer){
  renderer draw(image)
}

while(true) {
  player play(LoopMode mirror)
  "Playing mirrored" println()
  Time sleepSec(5)
  player stop()
  "Playing restart" println()
  player play(LoopMode restart)
  Time sleepSec(5)
  player stop()
  "Playing once" println()
  player play(LoopMode none)
  Time sleepSec(5)
  player stop()
}

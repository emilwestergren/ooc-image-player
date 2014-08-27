//
// Copyright (c) 2011-2014 Simon Mika <simon@mika.se>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
use ooc-draw
use ooc-math
use ooc-base
use ooc-draw-gpu
import threading/Thread

ImageRenderer: class {
  window: Window
  gpuImage: GpuBgra
  rasterImage: RasterBgra
  redraw: Bool = false
  renderThread: Thread
  mutex: Mutex
  windowSize: IntSize2D

  init: func (=windowSize) {
    this renderThread = Thread new(||
      this renderLoop()
      )
  }

  create: static func (windowSize: IntSize2D) -> This {
    result := This new(windowSize)
    result mutex = Mutex new()
    result renderThread start()
    result
  }

  renderLoop: func {
    this window = Window create(this windowSize, "Video renderer")
    if(this window == null)
      raise("Failed to create window")
    while(true) {
      this mutex lock()
      if(redraw) {
        if(this gpuImage == null)
          this gpuImage = GpuImage create(this rasterImage)
        else if(this gpuImage size == this rasterImage size)
          this gpuImage replace(this rasterImage)
        else {
          this gpuImage dispose()
          this gpuImage = GpuImage create(this rasterImage)
        }
      this window draw(this gpuImage)
      redraw = false
      }
      this mutex unlock()
    }
  }

  draw: func (image: RasterBgra) {
    this mutex lock()
    this rasterImage = image
    this redraw = true
    this mutex unlock()
  }

}

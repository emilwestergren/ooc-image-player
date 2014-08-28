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
import os/Time

ImageRenderer: class {
  _window: Window
  _gpuImage: GpuBgra
  _rasterImage: RasterBgra
  _redraw: Bool = false
  _renderThread: Thread
  _mutex: Mutex
  _windowSize: IntSize2D

  init: func (=_windowSize) {
    this _renderThread = Thread new(||
      this _renderLoop()
      )
  }
  _renderLoop: func {
    this _window = Window create(this _windowSize, "Video renderer")
    if(this _window == null)
      raise("Failed to create window")
    while(true) {
      if(this _redraw) {
        this _mutex lock()
        if(this _gpuImage == null)
          this _gpuImage = GpuImage create(this _rasterImage)
        else if(this _gpuImage size == this _rasterImage size)
          this _gpuImage replace(this _rasterImage)
        else {
          this _gpuImage dispose()
          this _gpuImage = GpuImage create(this _rasterImage)
        }
        this _window draw(this _gpuImage)
        this _redraw = false
        this _mutex unlock()
      }
      Time sleepMilli(800/30)
    }
  }
  draw: func (image: RasterBgra) {
    this _mutex lock()
    this _rasterImage = image
    this _redraw = true
    this _mutex unlock()
  }
  create: static func (windowSize: IntSize2D) -> This {
    result := This new(windowSize)
    result _mutex = Mutex new()
    result _renderThread start()
    result
  }

}

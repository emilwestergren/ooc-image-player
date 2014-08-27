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

import io/File
import structs/ArrayList
import os/Time

LoopMode: enum {
  mirror
  restart
  none
}

ImagePlayer: class {
  path: String
  frameCallback: Func (RasterBgra)
  imageBuffer: RasterBgra[]
  imageCount: UInt
  frameNumber: UInt = 0
  frameIndex: UInt = 0
  loopMode: LoopMode
  increment: Bool = true
  fps: UInt
  init: func (=path, frameCallback: Func (RasterBgra), fps := 30) {
    this frameCallback = frameCallback
    this loopMode = LoopMode mirror
    this fps = fps

    this loadImages()
    this play()
  }
  sortFilenames: func (strings: ArrayList<String>) {
    //FIXME: Couldn't get it to work with ArrayList sort() so using this temporarily
    greaterThan := func (s1: String, s2: String) -> Bool {
    minSize := Int minimum(s1 size, s2 size)
      for(i in 0..minSize) {
        if(s1[i] > s2[i])
          return true
        else if(s1[i] < s2[i])
          return false
      }
      s1 size == minSize
    }
    inOrder := false
    while (!inOrder) {
        inOrder = true
        for (i in 0..strings size - 1) {
            if (greaterThan(strings[i], strings[i + 1])) {
                inOrder = false
                tmp := strings[i]
                strings[i] = strings[i + 1]
                strings[i + 1] = tmp
            }
        }
    }
  }
  loadImages: func {
    directory := File new(path)
    imageFilenames := directory getChildrenNames()

    this sortFilenames(imageFilenames)
    this imageCount = imageFilenames size / 3
    imageBuffer = RasterImage[imageCount] new()

    for(i in 0..this imageCount) {
      ("Loading "  + path + imageFilenames[i]) println()
      imageBuffer[i] = RasterBgra open(path + imageFilenames[i])
    }
  }
  updateFramenumber: func {
    match (this loopMode) {
      case LoopMode mirror =>
        frameNumber += 1
        if(increment) {
          frameIndex += 1
          if(frameIndex == imageCount - 1) {
            increment = false
          }
        }
        else {
          frameIndex -= 1
          if(frameIndex == 0) {
            increment = true
          }
        }
      case LoopMode restart =>
        this frameNumber = (this frameNumber + 1) % this imageCount
        this frameIndex = this frameNumber
      case LoopMode none =>
        this frameNumber += 1
        this frameIndex += 1
      case =>
        raise("Using invalid Loop Mode in Image Player")
    }
  }
  reset: func {
    this frameNumber = this frameIndex = 0
  }

  validFrameIndex: func (index: UInt) -> Bool {
    index >= 0 && index < this imageCount
  }
  play: func {
    while(validFrameIndex(frameIndex)) {
      ("Sending frame nr: " + this frameNumber toString()) println()
      this frameCallback(imageBuffer[frameIndex])
      this updateFramenumber()
      Time sleepMilli(1000 / this fps)
    }
  }
}

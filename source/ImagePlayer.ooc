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
import threading/Thread

LoopMode: enum {
  mirror
  restart
  none
}

ImagePlayer: class {
  _path: String
  _frameCallback: Func (RasterImage)
  _imageBuffer: RasterImage[]
  _imageCount: UInt
  _frameNumber: UInt = 0
  _frameIndex: UInt = 0
  _loopMode: LoopMode
  loopMode: LoopMode { get { this _loopMode } set (value) {this _loopMode = value} }
  _sign: Int = 1
  _fps: UInt
  _maxFrames: UInt = 100
  init: func (=_path, frameCallback: Func (RasterImage), fps := 25) {
    this _frameCallback = frameCallback
    this _loopMode = LoopMode mirror
    this _fps = fps
    this _loadImages(this _path)
  }
  play: func {
    this _playLoop()
  }
  _sortFilenames: func (strings: ArrayList<String>) {
    //FIXME: Couldn't get it to work with ArrayList sort() so using this temporarily
    greaterThan := func (s1: String, s2: String) -> Bool {
    minSize := Int minimum(s1 size, s2 size)
    result := (s1 size == minSize)
      for(i in 0..minSize) {
        if(s1[i] > s2[i]) {
          result = true
          break
        }
        else if(s1[i] < s2[i]) {
          result = false
          break
        }
      }
      result
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
  _loadImages: func (path: String) {
    ("Searching for files in path: " + path) println()
    directory := File new(path)
    if(!directory dir?())
      raise("Filepath for images must be a directory")
    imageFilenames := directory getChildrenNames()

    this _sortFilenames(imageFilenames)
    this _imageCount = Int minimum(imageFilenames size, _maxFrames)
    _imageBuffer = RasterImage[_imageCount] new()

    for(i in 0..this _imageCount) {
      ("Loading "  + _path + imageFilenames[i]) println()
      _imageBuffer[i] = RasterImage open(_path + imageFilenames[i])
    }
    if(this _imageCount == 0)
      "Found no images to load in the specified folder" println()

  }
  _updateFrameNumber: func {
    match (this _loopMode) {
      case LoopMode mirror =>
        this _frameNumber += 1
        this _frameIndex += this _sign
        if(this _frameIndex == this _imageCount - 1)
          this _sign = -1
        else if(this _frameIndex == 0)
          this _sign = 1
      case LoopMode restart =>
        this _frameNumber = (this _frameNumber + 1) % this _imageCount
        this _frameIndex = this _frameNumber
      case LoopMode none =>
        this _frameNumber += 1
        this _frameIndex += 1
      case =>
        raise("Using invalid Loop Mode in Image Player")
    }
  }
  _reset: func {
    this _frameNumber = this _frameIndex = 0
  }
  _validFrameIndex: func (index: UInt) -> Bool {
    index >= 0 && index < this _imageCount
  }
  _playLoop: func {
    while(this _validFrameIndex(this _frameIndex) && this _imageCount > 0) {
      //("Sending frame nr: " + this _frameNumber toString() + "Index number: " + this _frameIndex toString()) println()
      this _frameCallback(_imageBuffer[_frameIndex])
      this _updateFrameNumber()
      Time sleepMilli(1000 / this _fps)
    }
    this _reset()
  }
}

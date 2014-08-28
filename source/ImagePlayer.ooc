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
  _frameCallback: Func (RasterBgra, This)
  _imageBuffer: RasterBgra[]
  _imageCount: UInt
  _frameNumber: UInt = 0
  _frameIndex: UInt = 0
  _loopMode: LoopMode
  _increment: Bool = true
  _fps: UInt
  _playing: Bool = false
  _paused: Bool  = false
  _thread: Thread
  _mutex: Mutex
  init: func (=_path, frameCallback: Func (RasterBgra, This), fps := 30) {
    this _frameCallback = frameCallback
    this _loopMode = LoopMode mirror
    this _fps = fps
    this _loadImages(this _path)
    _mutex = _mutex new()
    _thread = _thread new(|| this _playLoop())
    _thread start()
  }
  play: func (loopMode: LoopMode){
    this _mutex lock()
    this _playing = true
    this _loopMode = loopMode
    this _reset()
    this _mutex unlock()
  }
  _sortFilenames: func (strings: ArrayList<String>) {
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
  _loadImages: func (path: String) {
    directory := File new(path)
    if(!directory dir?())
      raise("Filepath for images must be a directory")
    imageFilenames := directory getChildrenNames()

    this _sortFilenames(imageFilenames)
    this _imageCount = imageFilenames size
    _imageBuffer = RasterImage[_imageCount] new()

    for(i in 0..this _imageCount) {
      ("Loading "  + _path + imageFilenames[i]) println()
      _imageBuffer[i] = RasterBgra open(_path + imageFilenames[i])
    }

  }
  _updateFrameNumber: func {
    match (this _loopMode) {
      case _loopMode mirror =>
        _frameNumber += 1
        if(_increment) {
          _frameIndex += 1
          if(_frameIndex == _imageCount - 1) {
            _increment = false
          }
        }
        else {
          _frameIndex -= 1
          if(_frameIndex == 0) {
            _increment = true
          }
        }
      case _loopMode restart =>
        this _frameNumber = (this _frameNumber + 1) % this _imageCount
        this _frameIndex = this _frameNumber
      case _loopMode none =>
        this _frameNumber += 1
        this _frameIndex += 1
        this _playing = _valid_frameIndex(this _frameIndex)
      case =>
        raise("Using invalid Loop Mode in Image Player")
    }
  }
  _reset: func {
    this _frameNumber = this _frameIndex = 0
  }
  _valid_frameIndex: func (index: UInt) -> Bool {
    index >= 0 && index < this _imageCount
  }
  _playLoop: func {
    while(true) {
      while(_playing) {
        this _mutex lock()
        //("Sending frame nr: " + this _frameNumber toString()) println()
        this _frameCallback(_imageBuffer[_frameIndex], this)
        this _updateFrameNumber()
        this _mutex unlock()
        Time sleepMilli(1000 / this _fps)
      }
      Time sleepMilli(1000 / this _fps)
    }
  }
  stop: func {
    this _mutex lock()
    this _playing = false
    this _reset()
    this _mutex unlock()
  }
}

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/painting.dart';

enum ImageEmitMode { usualLoop, trigger, stored, stop }

class MyImageStreamCompleter extends ImageStreamCompleter {
  ImageEmitMode imageEmitMode;
  int _playIndex = -1;
  bool _shouldEmit = false;
  bool decodeComplete = false;
  ui.Codec _codec;
  final double _scale;
  bool get _hasActiveListeners => true;

  ui.FrameInfo _nextFrame;
  // When the current was first shown.
  Duration _shownTimestamp;
  // The requested duration for the current frame;
  Duration _frameDuration;
  // How many frames have been emitted so far.
  int _framesEmitted;
  List<ImageInfo> _imageInfos = [];

  getImage({index}) {
    imageEmitMode = ImageEmitMode.trigger;
    _shouldEmit = true;
    _playIndex = index ?? -1;

    _fetchNextFrameAndSchedule();
  }

  palyAsUsual(bool asUsual, {int repeatCount}) {
    if (asUsual) {
      if (_playIndex == -1) {
        _playIndex = 0;
      }
      imageEmitMode = ImageEmitMode.usualLoop;
      _fetchNextFrameAndSchedule();
    } else {
      imageEmitMode = ImageEmitMode.stop;
    }
  }

  stop() {
    imageEmitMode = ImageEmitMode.stop;
  }

  MyImageStreamCompleter(
      {@required Future<ui.Codec> codec,
      @required double scale,
      this.imageEmitMode})
      : assert(codec != null),
        _scale = scale,
        _framesEmitted = 0 {
    codec.then<void>(_handleCodecReady,
        onError: (dynamic error, StackTrace stack) {
      FlutterError.reportError(new FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: 'resolving an image codec',
      ));
    });
  }

  void _handleCodecReady(ui.Codec codec) {
    _codec = codec;
    assert(_codec != null);
    imageEmitMode = ImageEmitMode.stored;
    _fetchNextFrameAndSchedule();
  }

  void _handleAppFrame(Duration timestamp) {
    if (!_hasActiveListeners) return;

    switch (imageEmitMode) {
      case ImageEmitMode.usualLoop:
        if (_isFirstFrame() || _hasFrameDurationPassed(timestamp)) {
          _shownTimestamp = timestamp;

          ImageInfo image;
          if (decodeComplete) {
            image = _imageInfos[_playIndex];
            if (_playIndex < _imageInfos.length - 1) {
              _playIndex++;
            } else {
              _playIndex = 0;
            }
          } else {
            image = new ImageInfo(image: _nextFrame.image, scale: _scale);
            _nextFrame = null;
          }
          _emitFrame(image);
          _fetchNextFrameAndSchedule();
          return;
        }
        break;
      case ImageEmitMode.trigger:
        if (_isFirstFrame() || _shouldEmit) {
          _shouldEmit = false;
          ImageInfo image;
          if (_playIndex != -1 && _playIndex < _imageInfos.length) {
            image = _imageInfos[_playIndex];
          } else {
            if (_nextFrame != null) {
              image = new ImageInfo(image: _nextFrame.image, scale: _scale);
            }
          }
          if (image != null) {
            _emitFrame(image);
          }
          _nextFrame = null;
          _fetchNextFrameAndSchedule();
          return;
        }
        break;
      case ImageEmitMode.stored:
        _frameDuration = _nextFrame.duration;

        if (_imageInfos.length >= _codec.frameCount) {
          decodeComplete = true;
          _shownTimestamp = timestamp;
          return;
        } else {
          _fetchNextFrameAndSchedule();
        }
        break;
      case ImageEmitMode.stop:
        if (_playIndex != -1 && _playIndex < _imageInfos.length) {
          _emitFrame(_imageInfos[_playIndex]);
        }
        return;
    }
    SchedulerBinding.instance.scheduleFrameCallback(_handleAppFrame);
  }

  bool _isFirstFrame() {
    return _frameDuration == null;
  }

  bool _hasFrameDurationPassed(Duration timestamp) {
    if (_shownTimestamp == null) {
      return false;
    }
    return timestamp - _shownTimestamp >= _frameDuration;
  }

  Future<Null> _fetchNextFrameAndSchedule() async {
    if (ImageEmitMode.stop == imageEmitMode) {
      return;
    }
    if (decodeComplete == false) {
      try {
        _nextFrame = await _codec.getNextFrame();
        _imageInfos.add(new ImageInfo(image: _nextFrame.image, scale: _scale));
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: stack,
          context: 'resolving an image frame',
        ));
        return;
      }
      if (_codec.frameCount == 1) {
        _emitFrame(new ImageInfo(image: _nextFrame.image, scale: _scale));
        _shouldEmit = false;
        return;
      }
    }

    SchedulerBinding.instance.scheduleFrameCallback(_handleAppFrame);
  }

  void _emitFrame(ImageInfo imageInfo) {
    setImage(imageInfo);
    _framesEmitted += 1;
  }

  @override
  void addListener(ImageListener listener, { ImageErrorListener onError }) {
    if (!_hasActiveListeners && _codec != null) {
      _fetchNextFrameAndSchedule();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(ImageListener listener) {
    super.removeListener(listener);
  }
}

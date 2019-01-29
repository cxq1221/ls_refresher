import 'dart:async';
import 'const.dart';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

import 'image_provider.dart';

typedef Future<void> RefreshCallback();
typedef _RefreshStateCallback(LSRefreshState state);
typedef _RawImageCallback(ui.Image image);
typedef _ExtentChangeCallback(double extent);

class LSBottomRefresher extends StatefulWidget {
  final RefreshCallback onRefresh;
  final RefresherIndicatorBuilder builder;

  const LSBottomRefresher.image(
    this.dragGif,
    this.refreshGif, {
    this.refreshTriggerPullDistance: kDefaultRefreshTriggerPullDistance,
    this.refreshIndicatorExtent: kDefaultRefreshIndicatorExtent,
    this.builder: buildImageRefreshIndicator,
    this.onRefresh,
  });

  const LSBottomRefresher.simple(
      {this.refreshTriggerPullDistance: kDefaultRefreshTriggerPullDistance,
      this.refreshIndicatorExtent: kDefaultRefreshIndicatorExtent,
      this.builder: buildDefaultRefreshIndicator,
      this.onRefresh,
      this.dragGif,
      this.refreshGif})
      : assert(refreshTriggerPullDistance != null),
        assert(refreshTriggerPullDistance > 0.0),
        assert(refreshIndicatorExtent != null),
        assert(refreshIndicatorExtent >= 0.0),
        assert(refreshTriggerPullDistance >= refreshIndicatorExtent,);

  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  final String dragGif;
  final String refreshGif;

  static Widget buildDefaultRefreshIndicator(
      BuildContext context,
      LSRefreshState refreshState,
      double pulledExtent,
      double refreshTriggerPullDistance,
      double refreshIndicatorExtent,
      ui.Image rawImage) {
    const Curve opacityCurve =
        const Interval(0.4, 0.8, curve: Curves.easeInOut);
    return new SizedBox(
      height: refreshIndicatorExtent,
      child: refreshState == LSRefreshState.drag
          ? new Padding(
              padding: const EdgeInsets.only(bottom: 14.0, top: 0.0),
              child: new Opacity(
                opacity: opacityCurve.transform(
                    min(pulledExtent / refreshTriggerPullDistance, 1.0)),
                child: const Icon(
                  CupertinoIcons.down_arrow,
                  color: CupertinoColors.inactiveGray,
                  size: 36.0,
                ),
              ),
            )
          : new Padding(
              padding: const EdgeInsets.only(bottom: 14.0, top: 14.0),
              child: new Opacity(
                opacity: opacityCurve
                    .transform(min(pulledExtent / refreshIndicatorExtent, 1.0)),
                child: const CupertinoActivityIndicator(radius: 14.0),
              ),
            ),
    );
  }

  static Widget buildImageRefreshIndicator(
      BuildContext context,
      LSRefreshState refreshState,
      double pulledExtent,
      double refreshTriggerPullDistance,
      double refreshIndicatorExtent,
      ui.Image rawImage) {
    const Curve opacityCurve =
        const Interval(0.4, 0.8, curve: Curves.easeInOut);
    return new Opacity(
      opacity: refreshState == LSRefreshState.done
          ? opacityCurve
              .transform(min(pulledExtent / refreshIndicatorExtent * 2.0, 1.0))
          : 1.0,
      child: new Container(
        height: 60.0,
        width: 60.0,
        alignment: Alignment.center,
        child: new RawImage(
          image: rawImage,
          height: 50.0,
          width: 50.0,
        ),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() {
    return new LSRefresherState(
        onRefresh: onRefresh, dragGif: dragGif, refreshGif: refreshGif, refreshIndicatorExtent: refreshIndicatorExtent, refreshTriggerPullDistance: refreshTriggerPullDistance);
  }
}

class LSRefresherState extends State<LSBottomRefresher> {
  RefreshCallback onRefresh;
  double lastIndicatorExtent = 0.0;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  LSRefreshState refreshState;

  String dragGif;
  String refreshGif;
  ui.Image rawImage;

  var lastIndexOfGifImage = 0;
  LSRefresherState(
      {this.onRefresh,
      this.refreshTriggerPullDistance,
      this.refreshIndicatorExtent,
      this.refreshGif,
      this.dragGif});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new LSSliverToBoxAdapter(
      refreshTriggerPullDistance: refreshTriggerPullDistance,
      refreshIndicatorExtent: refreshIndicatorExtent,
      onRefresh: onRefresh,
      dragGif: dragGif,
      onImageEmit: (raw) {
        setState(() {
          rawImage = raw;
        });
      },
      refreshGif: refreshGif,
      onScrollExtentChange: (extent) {
        setState(() {
          lastIndicatorExtent = extent;
        });
      },
      onRefreshStateChange: (state) {
        setState(() {
          refreshState = state;
        });
      },
      child: widget.builder(
          context,
          refreshState,
          lastIndicatorExtent,
          widget.refreshTriggerPullDistance,
          widget.refreshIndicatorExtent,
          rawImage),
    );
  }
}

class LSSliverToBoxAdapter extends SingleChildRenderObjectWidget {
  final RefreshCallback onRefresh;
  final _ExtentChangeCallback onScrollExtentChange;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  final _RefreshStateCallback onRefreshStateChange;
  final String dragGif;
  final String refreshGif;
  final _RawImageCallback onImageEmit;

  /// Creates a sliver that contains a single box widget.
  const LSSliverToBoxAdapter(
      {Key key,
      Widget child,
      this.refreshTriggerPullDistance,
      this.refreshIndicatorExtent,
      this.onRefresh,
      this.onScrollExtentChange,
      this.onRefreshStateChange,
      this.dragGif,
      this.refreshGif,
      this.onImageEmit})
      : super(key: key, child: child);

  @override
  LSRenderSliverToBoxAdapter createRenderObject(BuildContext context) =>
      new LSRenderSliverToBoxAdapter(
          refreshTriggerPullDistance: refreshTriggerPullDistance,
          refreshIndicatorExtent: refreshIndicatorExtent,
          onRefresh: onRefresh,
          onImageEmit: onImageEmit,
          onScrollExtentChange: onScrollExtentChange,
          onRefreshStateChange: onRefreshStateChange,
          dragGif: dragGif,
          refreshGif: refreshGif);
}

class LSRenderSliverToBoxAdapter extends RenderSliverSingleBoxAdapter {
  /// Creates a [RenderSliver] that wraps a [RenderBox].
  LSRefreshState _refreshState = LSRefreshState.inactive;
  bool _loadComplete = false;
  RefreshCallback onRefresh;
  RefreshCallback _onRefreshTemp;
  _ExtentChangeCallback onScrollExtentChange;
  _RefreshStateCallback onRefreshStateChange;
  _RawImageCallback onImageEmit;

  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  final String dragGif;
  final String refreshGif;
  int _lastIndexOfGifImage = -1;
  LSImageProvider _dragImageProvider;
  LSImageProvider _refreshImageProvider;
  bool isContentOverSize;

  LSImageProvider get imageProvider {
    if (_refreshState == LSRefreshState.drag) {
      return _dragImageProvider;
    } else {
      return _refreshImageProvider;
    }
  }

  LSRenderSliverToBoxAdapter(
      {RenderBox child,
      this.dragGif,
      this.refreshGif,
      this.onRefresh,
      this.onImageEmit,
      this.onScrollExtentChange,
      this.refreshTriggerPullDistance,
      this.refreshIndicatorExtent,
      this.onRefreshStateChange})
      : super(child: child) {
    createImageProviderIfNull();
  }

  void createImageProviderIfNull() {
    if (dragGif != null && dragGif is String) {
      if (_dragImageProvider == null) {
        _dragImageProvider = new LSImageProvider(dragGif);
        ImageStream str = _dragImageProvider.resolve(new ImageConfiguration());
        str.addListener((ImageInfo info, bool) {
          onImageEmit(info.image);
        });
      }
    }
    if (refreshGif != null && refreshGif is String) {
      if (_refreshImageProvider == null) {
        _refreshImageProvider = new LSImageProvider(refreshGif);
        ImageStream str =
            _refreshImageProvider.resolve(new ImageConfiguration());
        str.addListener((ImageInfo info, bool) {
          onImageEmit(info.image);
        });
      }
    }
  }

  _getChildExtent() {
    switch (constraints.axis) {
      case Axis.horizontal:
        return child.size.width;
      case Axis.vertical:
        return child.size.height;
    }
  }

  _getScrollExtent() {
    if (_refreshState == LSRefreshState.refresh ||
        _refreshState == LSRefreshState.armed) {
      return _getChildExtent();
    } else {
      return 0.0;
    }
  }

  _runStateMachine() {
    bool underTriggerRefreshExtent =
        constraints.remainingPaintExtent <= refreshTriggerPullDistance &&
            constraints.remainingPaintExtent > 0;
    bool beyondTriggerRefreshExtent =
        constraints.remainingPaintExtent > refreshTriggerPullDistance;
    bool onRefreshExtent = (constraints.remainingPaintExtent - _getChildExtent()).abs() < 3;

    bool outOfViewport = constraints.remainingPaintExtent <= 0;
    switch (_refreshState) {
      case LSRefreshState.inactive:
        _loadComplete = false;
        if (underTriggerRefreshExtent) {
          _refreshState = LSRefreshState.drag;
        }
        if (beyondTriggerRefreshExtent) {
          _refreshState = LSRefreshState.armed;
        }
        break;
      case LSRefreshState.drag:
        if (outOfViewport) {
          _refreshState = LSRefreshState.inactive;
        }
        if (beyondTriggerRefreshExtent) {
          _refreshState = LSRefreshState.armed;
        }
        break;
      case LSRefreshState.armed:
        if (underTriggerRefreshExtent) {
          _refreshState = LSRefreshState.drag;
        }
        if (onRefreshExtent) {
          _refreshState = LSRefreshState.refresh;
        }
        if (_loadComplete) {
          _refreshState = LSRefreshState.done;
        }
        break;
      case LSRefreshState.refresh:
        if (_loadComplete) {
          _refreshState = LSRefreshState.done;
        }
        if (outOfViewport) {
          continue done;
        }
        break;
      done:
      case LSRefreshState.done:
        if (outOfViewport) {
          _refreshState = LSRefreshState.inactive;
          _loadComplete = false;
        }
        break;
    }
  }

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    if (isContentOverSize == null) {
      isContentOverSize = constraints.remainingPaintExtent <= 0.0;
    }
    if (!isContentOverSize) {
      geometry = SliverGeometry.zero;
      return;
    }

    double childExtent = _getChildExtent();
    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);

    _runStateMachine();
    _emitImageIfNeeded(paintedChildSize);

    if (constraints.remainingPaintExtent == 0.0) {
      if (geometry != null) {
        if (geometry != null) {}
        if (imageProvider != null) {
          imageProvider.stop();
        }
      }
    }

    geometry = new SliverGeometry(
      scrollExtent: _getScrollExtent(),
      paintExtent: paintedChildSize,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );

    if (_refreshState == LSRefreshState.refresh && onRefresh != null) {
      onRefresh().then((result) {
        _runStateMachine();
        if (imageProvider != null) {
          imageProvider.stop();
        }
        _loadComplete = true;
        onRefresh = _onRefreshTemp;
        markNeedsLayout();

      });
      _onRefreshTemp = onRefresh;
      onRefresh = null;
    }

    setChildParentData(child, constraints, geometry);

    SchedulerBinding.instance.scheduleFrameCallback((timestamp) {
      onRefreshStateChange(_refreshState);
      onScrollExtentChange(paintedChildSize);
    });
  }

  void _emitImageIfNeeded(double paintedChildSize) {
    if (imageProvider != null) {
      if (imageProvider.frameCount != -1) {
        //按策略展示gif图片
        if (_refreshState == LSRefreshState.refresh) {
          imageProvider.palyAsUsual(true);
        } else {
          if (_refreshState != LSRefreshState.done) {
            //根据offset展示图片
            double percent = paintedChildSize / child.size.height;
            int indexOfGifImage =
                (percent * imageProvider.frameCount.toDouble()).toInt();
            if (indexOfGifImage != _lastIndexOfGifImage) {
              imageProvider.getImage(index: indexOfGifImage);
            }
            _lastIndexOfGifImage = indexOfGifImage;
          }
        }
      }
    }
  }
}

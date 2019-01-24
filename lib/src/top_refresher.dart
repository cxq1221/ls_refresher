import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';

import 'image_provider.dart';
import 'ls_image.dart';
import 'const.dart';

class LSTopRefresher extends StatefulWidget {
  const LSTopRefresher.image(
    this.dragGif,
    this.refreshGif, {
    this.refreshTriggerPullDistance: kDefaultRefreshTriggerPullDistance,
    this.refreshIndicatorExtent: kDefaultRefreshIndicatorExtent,
        this.paintOriginYOffset : kDefaultTopRefreshPaintOriginYOffset,
    this.builder: buildImageRefreshIndicator,
    this.onRefresh,
  });

  const LSTopRefresher.simple(
      {this.refreshTriggerPullDistance: kDefaultRefreshTriggerPullDistance,
      this.refreshIndicatorExtent: kDefaultRefreshIndicatorExtent,
        this.paintOriginYOffset : kDefaultTopRefreshPaintOriginYOffset,
      this.builder: buildDefaultRefreshIndicator,
      this.onRefresh,
      this.dragGif,
      this.refreshGif})
      : assert(refreshTriggerPullDistance != null),
        assert(refreshTriggerPullDistance > 0.0),
        assert(refreshIndicatorExtent != null),
        assert(refreshIndicatorExtent >= 0.0),
        assert(
            refreshTriggerPullDistance >= refreshIndicatorExtent,
            'The refresh indicator cannot take more space in its final state '
            'than the amount initially created by overscrolling.');

  final double paintOriginYOffset;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  final RefresherIndicatorBuilder builder;
  final RefreshCallback onRefresh;
  final String dragGif;
  final String refreshGif;

  @visibleForTesting
  static LSRefreshState state(BuildContext context) {
    final _LSTopRefresherState state =
        context.ancestorStateOfType(const TypeMatcher<_LSTopRefresherState>());
    return state.refreshState;
  }

  static Widget buildDefaultRefreshIndicator(
      BuildContext context,
      LSRefreshState refreshState,
      double pulledExtent,
      double refreshTriggerPullDistance,
      double refreshIndicatorExtent,
      ui.Image rawImage) {
    const Curve opacityCurve =
        const Interval(0.4, 0.8, curve: Curves.easeInOut);
    return new Align(
      alignment: Alignment.bottomCenter,
      child: new Padding(
        padding: new EdgeInsets.only(
            bottom: (refreshIndicatorExtent - 14.0 * 2) / 2.0),
        child: refreshState == LSRefreshState.drag
            ? new Opacity(
                opacity: opacityCurve.transform(
                    min(pulledExtent / refreshTriggerPullDistance, 1.0)),
                child: const Icon(
                  CupertinoIcons.down_arrow,
                  color: CupertinoColors.inactiveGray,
                  size: 36.0,
                ),
              )
            : new Opacity(
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
    return new Center(
      child: new SizedBox(
        width: 60.0,
        height: 60.0,
        child: new Stack(children: <Widget>[
          new Positioned(
            child: new LSImage(rawImage, width: 50.0, height: 50.0),
            bottom: 5.0,
          )
        ]),
      ),
    );
  }

  @override
  _LSTopRefresherState createState() {
    return new _LSTopRefresherState(dragGif: dragGif, refreshGif: refreshGif);
  }
}

class _LSTopRefresherState extends State<LSTopRefresher> {
  _LSTopRefresherState({this.dragGif, this.refreshGif}) : super();

  /// Reset the state from done to inactive when only this fraction of the
  /// original `refreshTriggerPullDistance` is left.
  static const double _kInactiveResetOverscrollFraction = 0.1;
  LSImageProvider dragImageProvider;
  LSImageProvider refreshImageProvider;

  String dragGif;
  String refreshGif;
  ui.Image _dragRawImage;
  ui.Image _rereshRawImage;
  LSRefreshState refreshState;
  Future<void> refreshTask;

  double lastIndicatorExtent = 0.0;
  bool hasSliverLayoutExtent = false;

  @override
  void initState() {
    super.initState();
    if (dragGif != null && dragGif is String) {
      dragImageProvider = new LSImageProvider(dragGif);
      ImageStream str = dragImageProvider.resolve(new ImageConfiguration());
      str.addListener((ImageInfo info, bool) {
        setState(() {
          _dragRawImage = info.image;
        });
      });
    }
    if (refreshGif != null && refreshGif is String) {
      refreshImageProvider = new LSImageProvider(refreshGif);
      ImageStream str = refreshImageProvider.resolve(new ImageConfiguration());
      str.addListener((ImageInfo info, bool) {
        setState(() {
          _rereshRawImage = info.image;
        });
      });
    }

    refreshState = LSRefreshState.inactive;
  }

  LSRefreshState transitionNextState() {
    LSRefreshState nextState;
    void goToDone() {
      nextState = LSRefreshState.done;
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        setState(() => hasSliverLayoutExtent = false);
      } else {
        SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
          setState(() => hasSliverLayoutExtent = false);
        });
      }
    }

    switch (refreshState) {
      case LSRefreshState.inactive:
        if (lastIndicatorExtent <= 0) {
          return LSRefreshState.inactive;
        } else {
          nextState = LSRefreshState.drag;
        }
        continue drag;
      drag:
      case LSRefreshState.drag:
        if (lastIndicatorExtent == 0) {
          return LSRefreshState.inactive;
        } else if (lastIndicatorExtent < widget.refreshTriggerPullDistance) {
          return LSRefreshState.drag;
        } else {
          if (widget.onRefresh != null) {
            HapticFeedback.mediumImpact();
            // Call onRefresh after this frame finished since the function is
            // user supplied and we're always here in the middle of the sliver's
            // performLayout.
            SchedulerBinding.instance
                .addPostFrameCallback((Duration timestamp) {
              refreshTask = widget.onRefresh()
                ..then((_) {
                  if (mounted) {
                    setState(() => refreshTask = null);
                    refreshState = transitionNextState();
                  }
                });
              setState(() => hasSliverLayoutExtent = true);
            });
          }
          return LSRefreshState.armed;
        }
        break;
      case LSRefreshState.armed:
        if (refreshState == LSRefreshState.armed && refreshTask == null) {
          goToDone();
          continue done;
        }

        if (lastIndicatorExtent > widget.refreshIndicatorExtent) {
          return LSRefreshState.armed;
        } else {
          nextState = LSRefreshState.refresh;
        }
        continue refresh;
      refresh:
      case LSRefreshState.refresh:
        if (refreshTask != null) {
          return LSRefreshState.refresh;
        } else {
          goToDone();
        }
        continue done;
      done:
      case LSRefreshState.done:
        if (lastIndicatorExtent >
            widget.refreshTriggerPullDistance *
                _kInactiveResetOverscrollFraction) {
          return LSRefreshState.done;
        } else {
          nextState = LSRefreshState.inactive;
        }
        break;
    }

    return nextState;
  }

  var lastIndexOfGifImage = 0;
  get imageProvider {
    if (refreshState == LSRefreshState.drag) {
      return dragImageProvider;
    } else if (refreshState == LSRefreshState.armed) {
      return refreshImageProvider;
    } else if (refreshState == LSRefreshState.refresh) {
      return refreshImageProvider;
    } else if (refreshState == LSRefreshState.done) {
      return refreshImageProvider;
    } else {
      return dragImageProvider;
    }
  }

  get rawImage {
    if (refreshState == LSRefreshState.drag) {
      return _dragRawImage;
    } else if (refreshState == LSRefreshState.armed) {
      return _rereshRawImage;
    } else if (refreshState == LSRefreshState.refresh) {
      return _rereshRawImage;
    } else if (refreshState == LSRefreshState.done) {
      return _rereshRawImage;
    } else {
      return _dragRawImage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new _LSRefreshSliver(
        paintOriginYOffset : widget.paintOriginYOffset,
        refreshIndicatorLayoutExtent: widget.refreshIndicatorExtent,
        hasLayoutExtent: hasSliverLayoutExtent,
        onImageEmit: (rawImage) {},
        child: new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            lastIndicatorExtent = constraints.maxHeight;
            refreshState = transitionNextState();
            //按策略展示gif图片
            buildGif();
            if (widget.builder != null &&
                refreshState != LSRefreshState.inactive) {
              return widget.builder(
                  context,
                  refreshState,
                  lastIndicatorExtent,
                  widget.refreshTriggerPullDistance,
                  widget.refreshIndicatorExtent,
                  rawImage);
            } else {
              return new Container();
            }
          },
        ));
  }

  void buildGif() {
    if (imageProvider == null) {
      return;
    }
    if (refreshState == LSRefreshState.refresh ||
        refreshState == LSRefreshState.done ||
        refreshState == LSRefreshState.armed) {
      imageProvider.palyAsUsual(true);
    } else if (refreshState == LSRefreshState.drag) {
      print(refreshTask == null);
      //根据offset展示图片
      double percent = lastIndicatorExtent / 50.0;
      int indexOfGifImage =
          (percent * imageProvider.frameCount.toDouble()).toInt();
      if (indexOfGifImage != lastIndexOfGifImage) {
        imageProvider.getImage(index: indexOfGifImage);
      }
      lastIndexOfGifImage = indexOfGifImage;
    } else if (refreshState == LSRefreshState.inactive) {
      imageProvider.stop();
    }
  }
}

typedef _RawImageCallback(ui.Image image);

class _LSRefreshSliver extends SingleChildRenderObjectWidget {
  const _LSRefreshSliver(
      {this.refreshIndicatorLayoutExtent: 0.0,
        this.paintOriginYOffset: 0.0,
      this.hasLayoutExtent: false,

      Widget child,
      this.onImageEmit})
      : assert(refreshIndicatorLayoutExtent != null),
        assert(refreshIndicatorLayoutExtent >= 0.0),
        assert(hasLayoutExtent != null),
        super(child: child);

  final double paintOriginYOffset;

  final double refreshIndicatorLayoutExtent;

  final bool hasLayoutExtent;

  final _RawImageCallback onImageEmit;

  @override
  _RenderLSRefreshSliver createRenderObject(BuildContext context) {
    return new _RenderLSRefreshSliver(
        paintOriginYOffset: paintOriginYOffset,
        refreshIndicatorExtent: refreshIndicatorLayoutExtent,
        hasLayoutExtent: hasLayoutExtent,
        onImageEmit: onImageEmit);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderLSRefreshSliver renderObject) {
    renderObject
      ..refreshIndicatorLayoutExtent = refreshIndicatorLayoutExtent
      ..hasLayoutExtent = hasLayoutExtent;
  }
}

class _RenderLSRefreshSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderLSRefreshSliver(
      {@required double refreshIndicatorExtent,
      @required bool hasLayoutExtent,
      RenderBox child,
      this.paintOriginYOffset : 0.0,
      this.onImageEmit})
      : assert(refreshIndicatorExtent != null),
        assert(refreshIndicatorExtent >= 0.0),
        assert(hasLayoutExtent != null),
        _refreshIndicatorExtent = refreshIndicatorExtent,
        _hasLayoutExtent = hasLayoutExtent {
    this.child = child;
  }
  final _RawImageCallback onImageEmit;
  double get refreshIndicatorLayoutExtent => _refreshIndicatorExtent;
  double _refreshIndicatorExtent;
  double paintOriginYOffset;
  set refreshIndicatorLayoutExtent(double value) {
    assert(value != null);
    assert(value >= 0.0);
    if (value == _refreshIndicatorExtent) return;
    _refreshIndicatorExtent = value;
    markNeedsLayout();
  }

  bool get hasLayoutExtent => _hasLayoutExtent;
  bool _hasLayoutExtent;
  set hasLayoutExtent(bool value) {
    assert(value != null);
    if (value == _hasLayoutExtent) return;
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  double layoutExtentOffsetCompensation = 0.0;

  LSImageProvider imageProvider;

  @override
  void performLayout() {
    assert(constraints.axisDirection == AxisDirection.down);
    assert(constraints.growthDirection == GrowthDirection.forward);

    // The new layout extent this sliver should now have.
    final double layoutExtent =
        (_hasLayoutExtent ? 1.0 : 0.0) * _refreshIndicatorExtent;

    if (layoutExtent != layoutExtentOffsetCompensation) {
      geometry = new SliverGeometry(
        scrollOffsetCorrection: layoutExtent - layoutExtentOffsetCompensation,
      );
      layoutExtentOffsetCompensation = layoutExtent;
      return;
    }

    bool active = constraints.overlap < 0.0 || layoutExtent > 0.0;
    final double overscrolledExtent =
        constraints.overlap < 0.0 ? constraints.overlap.abs() : 0.0;

    child.layout(
      constraints.asBoxConstraints(
        maxExtent: layoutExtent + overscrolledExtent,
      ),
      parentUsesSize: true,
    );
    if (active) {
      var paintExtent = max(
        max(child.size.height, layoutExtent) - constraints.scrollOffset,
        0.0,
      );
      var maxPaintExtent = max(
        max(child.size.height, layoutExtent) - constraints.scrollOffset,
        0.0,
      );
      var layoutET = max(layoutExtent - constraints.scrollOffset, 0.0);
      var paintOrigin = -overscrolledExtent - constraints.scrollOffset + paintOriginYOffset;
      geometry = new SliverGeometry(
        scrollExtent: layoutExtent,
        paintOrigin: paintOrigin,
        paintExtent: paintExtent,
        maxPaintExtent: maxPaintExtent,
        layoutExtent: layoutET,
      );

      if (imageProvider != null) {
        imageProvider.getImage(index: 0);
      }
    } else {
      geometry = SliverGeometry.zero;
    }
  }

  @override
  void paint(PaintingContext paintContext, Offset offset) {
    if (constraints.overlap < 0.0 ||
        constraints.scrollOffset + child.size.height > 0) {
      paintContext.paintChild(child, offset);
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}

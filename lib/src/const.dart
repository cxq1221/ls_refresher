import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;

const double kDefaultRefreshTriggerPullDistance = 60.0;
const double kDefaultRefreshIndicatorExtent = 60.0;
const double kDefaultTopRefreshPaintOriginYOffset = 0.0;

enum LSRefreshState {
  /// Initial state, when not being overscrolled into, or after the overscroll
  /// is canceled or after done and the sliver retracted away.
  inactive,

  /// While being overscrolled but not far enough yet to trigger the refresh.
  drag,

  /// Dragged far enough that the onRefresh callback will run and the dragged
  /// displacement is not yet at the final refresh resting state.
  armed,

  /// While the onRefresh task is running.
  refresh,

  /// While the indicator is animating away after refreshing.
  done,
}

typedef Widget RefresherIndicatorBuilder(
    BuildContext context,
    LSRefreshState refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
    ui.Image rawImage);

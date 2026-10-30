import 'package:flutter/widgets.dart';

/// Parts of the game screen a tutorial coach mark can spotlight
enum CoachTarget {
  wheel,
  startBadge,
  category,
  skip,
  timer,
  pause,
  constellation,
  del,
  space,
  x2,
  hint,
  go,
}

/// Global keys that let an overlay find (and spotlight) game UI
class CoachTargets {
  final Map<CoachTarget, GlobalKey> _keys = {
    for (final target in CoachTarget.values)
      target: GlobalKey(debugLabel: 'coach-${target.name}'),
  };

  /// Wrap [child] so it can be spotlighted as [target]
  Widget mark(CoachTarget target, Widget child) =>
      KeyedSubtree(key: _keys[target], child: child);

  /// On-screen rect of [target] in [ancestor]'s coordinates, if laid out
  Rect? rectOf(CoachTarget target, RenderBox ancestor) {
    final box = _keys[target]!.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: ancestor);
    return topLeft & box.size;
  }
}

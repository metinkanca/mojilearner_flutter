import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Three children stacked top to bottom, the middle one taking whatever height
/// the parent has spare.
///
/// [top] and [bottom] are laid out at their natural height. The middle child
/// is then laid out with a minimum height of what is left of the parent's
/// minimum, so it can read how much spare height it has from its own
/// constraints and grow into it. When nothing is spare it gets no minimum and
/// takes its natural height.
///
/// A [Column] cannot do this inside a scroll view: its flexible children need
/// a bounded height, and a scroll view gives it an unbounded one. This is the
/// version for a parent whose height is "at least the screen, more if the
/// content needs it" — put it in a [ConstrainedBox] with a minimum height, in
/// a scroll view, and a screen too short for the content scrolls while a tall
/// one fills.
class SpareHeightColumn extends MultiChildRenderObjectWidget {
  SpareHeightColumn({
    super.key,
    required Widget top,
    required Widget middle,
    required Widget bottom,
  }) : super(children: [top, middle, bottom]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSpareHeightColumn();
}

class _SpareHeightParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderSpareHeightColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SpareHeightParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SpareHeightParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SpareHeightParentData) {
      child.parentData = _SpareHeightParentData();
    }
  }

  List<RenderBox> get _children {
    final out = <RenderBox>[];
    for (var child = firstChild; child != null; child = childAfter(child)) {
      out.add(child);
    }
    assert(out.length == 3, 'SpareHeightColumn has exactly three children');
    return out;
  }

  /// Lays the three out with [layout] and returns their heights.
  List<double> _heights(
    BoxConstraints constraints,
    double Function(RenderBox child, BoxConstraints constraints) layout,
  ) {
    assert(constraints.hasBoundedWidth, 'SpareHeightColumn needs a width');
    final [top, middle, bottom] = _children;
    final natural = BoxConstraints.tightFor(width: constraints.maxWidth);
    final topHeight = layout(top, natural);
    final bottomHeight = layout(bottom, natural);
    final spare =
        math.max(0.0, constraints.minHeight - topHeight - bottomHeight);
    final middleHeight = layout(middle, natural.copyWith(minHeight: spare));
    return [topHeight, middleHeight, bottomHeight];
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final heights =
        _heights(constraints, (child, c) => child.getDryLayout(c).height);
    return constraints
        .constrain(Size(constraints.maxWidth, heights.reduce((a, b) => a + b)));
  }

  @override
  void performLayout() {
    final heights = _heights(constraints, (child, c) {
      child.layout(c, parentUsesSize: true);
      return child.size.height;
    });
    var y = 0.0;
    final children = _children;
    for (var i = 0; i < children.length; i++) {
      (children[i].parentData! as _SpareHeightParentData).offset = Offset(0, y);
      y += heights[i];
    }
    size = constraints.constrain(Size(constraints.maxWidth, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

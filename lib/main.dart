import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

///
///  Note: Just a proof of concept
///
///  Issues:
///   > If the selection box is expanded too fast, it might miss a few children during hit testing
///   > The checking against keys is only done on panEnd, but the expansion via hit test is done on every panUpdate
///     => this results in shrinking selection only beeing applied onEnd
///
///
///

void main() {
  runApp(
    MaterialApp(
      title: '', // TODO add title
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Selector(),
      ),
    ),
  );
}

class Selector extends StatefulWidget {
  const Selector({
    Key? key,
  }) : super(key: key);

  @override
  _SelectorState createState() => _SelectorState();
}

class _SelectorState extends State<Selector> {
  Offset? rectStart;
  Offset? rectEnd;
  Rect? get rect => rectStart == null ? null : Rect.fromPoints(rectStart!, rectEnd!);
  Set<MyMetaData> visitedItems = {};

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => setState(() {
        visitedItems = {};
        rectStart = details.globalPosition;
        rectEnd = details.globalPosition;
      }),
      onPanUpdate: (details) => setState(() {
        rectEnd = details.globalPosition;

        // Collect all items that have been visited at all
        final HitTestResult r = HitTestResult();
        WidgetsBinding.instance?.hitTest(r, rectEnd!);
        for (final HitTestEntry hte in r.path) {
          final target = hte.target;
          if (target is RenderMetaData) {
            final metaData = target.metaData;
            if (metaData is MyMetaData) {
              visitedItems.add(metaData);
            }
          }
        }
      }),
      onPanEnd: (details) => setState(() {
        // Check collection against actual rect
        // (might have shrunken again)
        Set<MyMetaData> rechecked = {};
        for (final visited in visitedItems) {
          final renderObj = visited.key.currentContext?.findRenderObject();
          if (renderObj is RenderBox) {
            final vRect = renderObj.localToGlobal(Offset.zero) & renderObj.size;
            if (rect!.overlaps(vRect)) {
              rechecked.add(visited);
            }
          }
        }

        rectStart = null;
        rectEnd = null;
        visitedItems = rechecked;
      }),
      child: Stack(
        children: [
          MyList(
            selectedItems: visitedItems.map((e) => e.key).toSet(),
          ),
          if (rect != null) ...[
            Positioned(
              top: rect!.top,
              left: rect!.left,
              width: rect!.width,
              height: rect!.height,
              child: Container(
                color: Colors.yellow.withAlpha(100),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class MyMetaData {
  final int index;
  final GlobalKey key;
  MyMetaData({
    required this.index,
    required this.key,
  });
}

class MyList extends StatefulWidget {
  MyList({
    Key? key,
    this.itemCount = 40,
    this.selectedItems = const {},
  }) : super(key: key);

  final int itemCount;
  final Set<GlobalKey> selectedItems;

  @override
  State<MyList> createState() => _MyListState();
}

class _MyListState extends State<MyList> {
  late final List<GlobalKey> keys = [for (int i = 0; i < widget.itemCount; i++) GlobalKey()];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => MetaData(
        metaData: MyMetaData(
          index: index,
          key: keys[index],
        ),
        child: Container(
          key: keys[index],
          margin: const EdgeInsets.all(4),
          color: widget.selectedItems.contains(keys[index]) ? Colors.yellow : Colors.blue,
          child: Text("$index"),
        ),
      ),
    );
  }
}

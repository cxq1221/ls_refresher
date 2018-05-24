
## features
- Drag down refresh, pull up refresh.
- Simply used within CustomScrollView.
- Diy the widget displayed on over-scroll area. (use your own builder)
- Gif image support, image changed along with drag offset.

### warning
LSTopRefresher is based on CupertinoRefreshControl, so it has a bug that when the items can not fill the ScrollView, it would not bounce back when refesh task completed


### Start:
```dart
import 'package:ls_refresher/ls_refresher.dart';
```
### then:
```dart
new CustomScrollView(
            slivers: <Widget>[
//              new LSTopRefresher.image('images/test.gif', 'images/test2.gif',
//                  onRefresh: () {
//                return new Future<void>.delayed(const Duration(seconds: 2))
//                  ..then((re) {
//                    setState(() {
//                      changeRandomList();
//                    });
//                  });
//              }),
              new LSTopRefresher.simple(onRefresh: () {
                return new Future<void>.delayed(const Duration(seconds: 2))
                  ..then((re) {
                    setState(() {
                      changeRandomList();
                    });
                  });
              }),
              new SliverList(
                delegate: new SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return new _ListItem(
                      name: randomizedContacts[index][0] + '$index',
                      place: randomizedContacts[index][1],
                      date: randomizedContacts[index][2],
                      called: randomizedContacts[index][3] == 'true',
                    );
                  },
                  childCount: _listCount,
                ),
              ),
//              new LSBottomRefresher.simple(
//                onRefresh: () {
//                  return new Future<void>.delayed(const Duration(seconds: 2))
//                    ..then((re) {
////                      setState(() {
////                        _listCount += 1;
////                      });
//                    });
//                },
//              )
              new LSBottomRefresher.image(
                'images/test3.gif',
                'images/test4.gif',
                onRefresh: () {
                  return new Future<void>.delayed(const Duration(seconds: 2))
                    ..then((re) {
//                      setState(() {
//                        _listCount += 1;
//                      });
                    });
                },
              )
            ],
          ),
```
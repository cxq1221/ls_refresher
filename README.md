
## features
- Drag down refresh, pull up refresh.
- Simply used within CustomScrollView.
- Diy the widget displayed on over-scroll area. (use your own builder)
- Gif image support, image changed along with drag offset.

![LSTopRefresher](https://github.com/cxq1221/ls_refresher/blob/master/images/top.GIF)

![LSBottomRefresher](https://github.com/cxq1221/ls_refresher/blob/master/images/bottom.GIF)

### start:
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
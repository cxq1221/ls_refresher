// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' show Random;
import 'dart:ui' as ui;
import 'package:ls_refresher/ls_refresher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

class _DemoState extends State<Demo> {
  List<List<String>> randomizedContacts;
  List<ui.Image> rawImages = [];
  ui.Image rawImage;
  @override
  void initState() {
    super.initState();
    changeRandomList();
  }

  double outExtent = 0.0;
  int _listCount = 30;
  ScrollController _scrollController = new ScrollController();
  @override
  Widget build(BuildContext context) {
    return new DefaultTextStyle(
      style: new TextStyle(fontSize: 17.0),
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('Title'),
        ),
        body: new CustomScrollView(
          controller: _scrollController,
          physics: new AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
//            new LSTopRefresher.image('images/giphy.gif', 'images/bread.gif',
//                onRefresh: () {
//              return new Future<void>.delayed(const Duration(seconds: 2))
//                ..then((re) {
//                  setState(() {
//                    changeRandomList();
//                  });
//                });
//            }),
            new LSTopRefresher.simple(onRefresh: () {
              return new Future<void>.delayed(const Duration(seconds: 2))
                ..then((re) {
                  setState(() {
                    changeRandomList();
                    _scrollController.animateTo(0.0,
                        duration: new Duration(milliseconds: 100),
                        curve: Curves.bounceOut);
                  });
                });
            }),
            new SliverSafeArea(
              sliver: new SliverList(
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
            ),
            new LSBottomRefresher.simple(
              onRefresh: () {
                return new Future<void>.delayed(const Duration(seconds: 2))
                  ..then((re) {
                    setState(() {
                      _listCount += 1;
                    });
                  });
              },
            )
//            new LSBottomRefresher.image(
//              'images/ice.gif',
//              'images/sea.gif',
//              onRefresh: () {
//                return new Future<void>.delayed(const Duration(seconds: 2))
//                  ..then((re) {
//                    setState(() {
//                      _listCount += 1;
//                    });
//                  });
//              },
//            )
          ],
        ),
      ),
    );
  }

  void changeRandomList() {
    final Random random = new Random();
//    _listCount -= 1;
    randomizedContacts = new List<List<String>>.generate(100, (int index) {
      return contacts[random.nextInt(contacts.length)]
        // Randomly adds a telephone icon next to the contact or not.
        ..add(random.nextBool().toString());
    });
  }
}

void main() {
  //debugPaintSizeEnabled = true;
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData().copyWith(platform: TargetPlatform.iOS),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

List<Widget> list = <Widget>[
  new ListTile(
    title: new Text('La Ciccia',
        style: new TextStyle(fontWeight: FontWeight.w500, fontSize: 20.0)),
    subtitle: new Text('291 30th St'),
    leading: new Icon(
      Icons.restaurant,
      color: Colors.blue[500],
    ),
  ),
];

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new Demo();
  }
}

class Demo extends StatefulWidget {
  static const String routeName = '/cupertino/refresh';

  test() {
    new Image.network('');
  }

  @override
  _DemoState createState() => new _DemoState();
}

List<List<String>> contacts = <List<String>>[
  <String>['George Washington', 'Westmoreland County', ' 4/30/1789'],
  <String>['John Adams', 'Braintree', ' 3/4/1797'],
  <String>['Thomas Jefferson', 'Shadwell', ' 3/4/1801'],
  <String>['James Madison', 'Port Conway', ' 3/4/1809'],
  <String>['James Monroe', 'Monroe Hall', ' 3/4/1817'],
  <String>['Andrew Jackson', 'Waxhaws Region South/North', ' 3/4/1829'],
  <String>['John Quincy Adams', 'Braintree', ' 3/4/1825'],
  <String>['William Henry Harrison', 'Charles City County', ' 3/4/1841'],
];

class _ListItem extends StatelessWidget {
  const _ListItem({
    this.name,
    this.place,
    this.date,
    this.called,
  });

  final String name;
  final String place;
  final String date;
  final bool called;

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: 60.0,
      padding: const EdgeInsets.only(top: 9.0),
      child: new Row(
        children: <Widget>[
          new Expanded(
            child: new Container(
              decoration: const BoxDecoration(
                border: const Border(
                  bottom: const BorderSide(
                      color: const Color(0xFFBCBBC1), width: 0.0),
                ),
              ),
              padding:
                  const EdgeInsets.only(left: 1.0, bottom: 9.0, right: 10.0),
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        new Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.41,
                          ),
                        ),
                        new Text(
                          place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.0,
                            letterSpacing: -0.24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  new Text(
                    date,
                    style: const TextStyle(
                      fontSize: 15.0,
                      letterSpacing: -0.41,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

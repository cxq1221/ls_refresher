// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:math' show Random;
import 'dart:ui' as ui;
import 'package:ls_refresher/ls_refresher.dart';

// Uncomment lines 7 and 10 to view the visual layout at runtime.
//import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;

class _CupertinoRefreshControlDemoState
    extends State<CupertinoRefreshControlDemo> {
  List<List<String>> randomizedContacts;
  List<ui.Image> rawImages = [];
  ui.Image rawImage;
  @override
  void initState() {
    super.initState();
    repopulateList();
  }

  void repopulateList() {
    final Random random = new Random();
    randomizedContacts = new List<List<String>>.generate(100, (int index) {
      return contacts[random.nextInt(contacts.length)]
        // Randomly adds a telephone icon next to the contact or not.
        ..add(random.nextBool().toString());
    });
  }

  double outExtent = 0.0;
  int _listCount = 10;
  ScrollController _scrollController = new ScrollController();
  @override
  Widget build(BuildContext context) {
    return new DefaultTextStyle(
      style: new TextStyle(fontSize: 17.0),
      child: new CupertinoPageScaffold(
        child: new Container(
          margin: new EdgeInsets.only(top: 60.0),
          height: 550.0,
          decoration: new BoxDecoration(color: Colors.amber),
          child: new CustomScrollView(
            slivers: <Widget>[
              new LSTopRefresher.image('images/test.gif', 'images/test2.gif',
                  onRefresh: () {
                return new Future<void>.delayed(const Duration(seconds: 2))
                  ..then((re) {
                    setState(() {
                      repopulateList();
                    });
                  });
              }),
//              new LSTopRefresher.simple(onRefresh: () {
//                return new Future<void>.delayed(const Duration(seconds: 2))
//                  ..then((re) {
//                    setState(() {
//                      repopulateList();
//                    });
//                  });
//              }),
//              new CupertinoRefreshControl(onRefresh: () {
//                return new Future<void>.delayed(const Duration(seconds: 2));
//              }),
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
        ),
      ),
    );
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
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
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
    return new CupertinoRefreshControlDemo();
  }
}

class CupertinoRefreshControlDemo extends StatefulWidget {
  static const String routeName = '/cupertino/refresh';

  @override
  _CupertinoRefreshControlDemoState createState() =>
      new _CupertinoRefreshControlDemoState();
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
      color: CupertinoColors.activeGreen,
      height: 60.0,
      padding: const EdgeInsets.only(top: 9.0),
      child: new Row(
        children: <Widget>[
          new Container(
            width: 38.0,
            child: called
                ? const Align(
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      CupertinoIcons.phone_solid,
                      color: CupertinoColors.inactiveGray,
                      size: 18.0,
                    ),
                  )
                : null,
          ),
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
                            color: CupertinoColors.inactiveGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  new Text(
                    date,
                    style: const TextStyle(
                      color: CupertinoColors.inactiveGray,
                      fontSize: 15.0,
                      letterSpacing: -0.41,
                    ),
                  ),
                  const Padding(
                    padding: const EdgeInsets.only(left: 9.0),
                    child: const Icon(CupertinoIcons.info,
                        color: CupertinoColors.activeBlue),
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

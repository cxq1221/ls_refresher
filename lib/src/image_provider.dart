import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter/painting.dart';
import 'image_stream_completer.dart';

const String _kAssetManifestFileName = 'AssetManifest.json';

class LSImageProvider extends ImageProvider<AssetBundleImageKey> {
  LSImageProvider(
    this.assetName, {
    this.bundle,
    this.package,
  }) : assert(assetName != null);

  getImage({index}) {
    if (completer != null) {
      completer.getImage(index: index);
    }
  }

  palyAsUsual(bool asUsual) {
    if (completer != null) {
      completer.palyAsUsual(asUsual);
    }
  }

  stop() {
    if (completer != null) {
      completer.stop();
    }
  }

  MyImageStreamCompleter completer;
  int frameCount = -1;

  @override
  ImageStreamCompleter load(AssetBundleImageKey key) {
    completer =
        new MyImageStreamCompleter(codec: _loadAsync(key), scale: key.scale);
    return completer;
  }

  @protected
  Future<ui.Codec> _loadAsync(AssetBundleImageKey key) async {
    final ByteData data = await key.bundle.load(key.name);
    if (data == null) throw 'Unable to read data';
    var codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    frameCount = codec.frameCount;
    return codec;
  }

  final String assetName;
  String get keyName =>
      package == null ? assetName : 'packages/$package/$assetName';
  final AssetBundle bundle;
  final String package;

  static const double _naturalResolution = 1.0;

  @override
  Future<AssetBundleImageKey> obtainKey(ImageConfiguration configuration) {
    final AssetBundle chosenBundle =
        bundle ?? configuration.bundle ?? rootBundle;
    Completer<AssetBundleImageKey> completer;
    Future<AssetBundleImageKey> result;
    chosenBundle
        .loadStructuredData<Map<String, List<String>>>(
            _kAssetManifestFileName, _manifestParser)
        .then<void>((Map<String, List<String>> manifest) {
      final String chosenName = _chooseVariant(
          keyName, configuration, manifest == null ? null : manifest[keyName]);
      final double chosenScale = _parseScale(chosenName);
      final AssetBundleImageKey key = new AssetBundleImageKey(
          bundle: chosenBundle, name: chosenName, scale: chosenScale);
      if (completer != null) {
        completer.complete(key);
      } else {
        result = new SynchronousFuture<AssetBundleImageKey>(key);
      }
    }).catchError((dynamic error, StackTrace stack) {
      assert(completer != null);
      assert(result == null);
      completer.completeError(error, stack);
    });
    if (result != null) {
      return result;
    }
    completer = new Completer<AssetBundleImageKey>();
    return completer.future;
  }

  static Future<Map<String, List<String>>> _manifestParser(String jsonData) {
    if (jsonData == null) return null;
    // TODO(ianh): JSON decoding really shouldn't be on the main thread.
    final Map<String, dynamic> parsedJson = json.decode(jsonData);
    final Iterable<String> keys = parsedJson.keys;
    final Map<String, List<String>> parsedManifest =
        new Map<String, List<String>>.fromIterables(keys,
            keys.map((String key) => new List<String>.from(parsedJson[key])));
    // TODO(ianh): convert that data structure to the right types.
    return new SynchronousFuture<Map<String, List<String>>>(parsedManifest);
  }

  String _chooseVariant(
      String main, ImageConfiguration config, List<String> candidates) {
    if (config.devicePixelRatio == null ||
        candidates == null ||
        candidates.isEmpty) return main;
    // TODO(ianh): Consider moving this parsing logic into _manifestParser.
    final SplayTreeMap<double, String> mapping =
        new SplayTreeMap<double, String>();
    for (String candidate in candidates)
      mapping[_parseScale(candidate)] = candidate;
    // TODO(ianh): implement support for config.locale, config.textDirection,
    return _findNearest(mapping, config.devicePixelRatio);
  }

  String _findNearest(SplayTreeMap<double, String> candidates, double value) {
    if (candidates.containsKey(value)) return candidates[value];
    final double lower = candidates.lastKeyBefore(value);
    final double upper = candidates.firstKeyAfter(value);
    if (lower == null) return candidates[upper];
    if (upper == null) return candidates[lower];
    if (value > (lower + upper) / 2)
      return candidates[upper];
    else
      return candidates[lower];
  }

  static final RegExp _extractRatioRegExp = new RegExp(r'/?(\d+(\.\d*)?)x/');

  double _parseScale(String key) {
    final Match match = _extractRatioRegExp.firstMatch(key);
    if (match != null && match.groupCount > 0)
      return double.parse(match.group(1));
    return _naturalResolution; // i.e. default to 1.0x
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final AssetImage typedOther = other;
    return keyName == typedOther.keyName && bundle == typedOther.bundle;
  }

  @override
  int get hashCode => hashValues(keyName, bundle);

  @override
  String toString() => '$runtimeType(bundle: $bundle, name: "$keyName")';
}

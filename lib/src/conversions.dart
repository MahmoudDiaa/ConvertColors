import 'dart:collection';
import 'dart:core';
import 'dart:mirrors';

import 'routes.dart';

List<String> _getRoute(List<String> path, String current, String to) {
  for (final kv in conversionRoutes[current].entries) {
    final key = kv.key;
    if (path.contains(key)) {
      continue;
    }
    if (path.isNotEmpty && current != path.last) {
      path.add(current);
    }
    path.add(key);
    if (conversionRoutes[key].containsKey(to)) {
      path.add(to);
      return path;
    } else {
      var newPath = _getRoute([...path], key, to);
      if (newPath.last == to) {
        return newPath;
      }
    }
  }
  return path;
}

dynamic _convert(String from, String to, dynamic value) {
  dynamic result;

  if (conversionRoutes[from].containsKey(to)) {
    result = (conversionRoutes[from][to](value));
  } else {
    var path = _getRoute([], from, to);
    var currentFrom = from;
    result = value;
    for (var currentTo in path) {
      result = conversionRoutes[currentFrom][currentTo](result);
      currentFrom = currentTo;
    }
  }

  if (result is List) {
    return ConversionResult(result);
  }
  return result;
}

bool _isValidColorSpace(String name) => colorSpaceNames.contains(name);

class ConversionResult extends Object with ListMixin<int> {
  final List<num> _list = [];
  ConversionResult(List<num> l) {
    l.forEach((element) {
      _list.add(element);
    });
  }

  @override
  set length(int newLength) {
    _list.length = newLength;
  }

  @override
  int get length => _list.length;

  @override
  int operator [](int index) => _list[index].round();

  @override
  void operator []=(int index, num value) {
    _list[index] = value;
  }

  List<double> get raw => _list.map((e) => e.toDouble()).toList();
}

const colorChannels = {
  'rgb': 3,
  'hsl': 3,
  'hsv': 3,
  'hwb': 3,
  'cmyk': 4,
  'xyz': 3,
  'lab': 3,
  'lch': 3,
  'hex': 1,
  'keyword': 1,
  'ansi16': 1,
  'ansi256': 1,
  'hcg': 3,
  'apple': 3,
  'gray': 1,
};

const colorLabels = {
  'rgb': 'rgb',
  'hsl': 'hsl',
  'hsv': 'hsv',
  'hwb': 'hwb',
  'cmyk': 'cmyk',
  'xyz': 'xyz',
  'lab': 'lab',
  'lch': 'lch',
  'hex': ['hex'],
  'keyword': ['keyword'],
  'ansi16': ['ansi16'],
  'ansi256': ['ansi256'],
  'hcg': ['h', 'c', 'g'],
  'apple': ['r16', 'g16', 'b16'],
  'gray': ['gray'],
};

class ConvertRouteReceiver {
  String from = '';
  String to = '';

  @override
  dynamic noSuchMethod(Invocation msg) {
    // from
    var memberName = MirrorSystem.getName(msg.memberName);
    if (from != '') {
      if (memberName == 'channels') {
        return colorChannels[from];
      } else if (memberName == 'labels') {
        return colorLabels[from];
      }
    }
    var isRaw = memberName == 'raw';
    final to_ = to == '' ? memberName : to;
    if (msg.positionalArguments.isEmpty) {
      to = to_;
      return this;
    }
    var arg = msg.positionalArguments[0];
    if (msg.positionalArguments.length > 1) {
      arg = msg.positionalArguments
          .map((e) => e is num ? e.toDouble() : 0)
          .toList();
    }
    if (_isValidColorSpace(from) && _isValidColorSpace(to_)) {
      var result = _convert(from, to_, arg);
      if (isRaw && result is ConversionResult) {
        to = '';
        return result.raw;
      }
      return result;
    }
    return null;
  }
}

class Convert {
  final route = ConvertRouteReceiver() as dynamic;
  @override
  ConvertRouteReceiver noSuchMethod(Invocation msg) {
    route.from = MirrorSystem.getName(msg.memberName);
    return route;
  }
}
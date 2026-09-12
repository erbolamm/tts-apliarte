int levenshteinDistance(String a, String b) {
  if (a == b) {
    return 0;
  }
  if (a.isEmpty) {
    return b.length;
  }
  if (b.isEmpty) {
    return a.length;
  }

  final aLen = a.length;
  final bLen = b.length;
  final costs = List<int>.generate(bLen + 1, (i) => i);

  for (var i = 1; i <= aLen; i++) {
    var prev = i - 1;
    costs[0] = i;
    for (var j = 1; j <= bLen; j++) {
      final temp = costs[j];
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      costs[j] = _min3(
        costs[j] + 1,
        costs[j - 1] + 1,
        prev + cost,
      );
      prev = temp;
    }
  }

  return costs[bLen];
}

int _min3(int a, int b, int c) {
  var min = a;
  if (b < min) {
    min = b;
  }
  if (c < min) {
    min = c;
  }
  return min;
}

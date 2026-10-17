/// Actions remain compatible with the existing scouting API and team replay.
abstract final class AutoRoute {
  static const preloads = ['Preload Left', 'Preload Center', 'Preload Right'];
  static const crossings = [
    'Went Under Left Trench',
    'Went Over Left Bump',
    'Went Over Right Bump',
    'Went Under Right Trench',
  ];
  static const depot = 'Intaked At Depot';
  static const neutral = 'Intaked at Neutral Zone';
  static const shot = 'Shot at Hub';
  static const actions = [...preloads, ...crossings, depot, neutral, shot];

  static bool isPreload(String action) =>
      preloads.contains(action) ||
      const ['Start Left', 'Start Center', 'Start Right'].contains(action);

  static String? lastMovement(List<String> path) {
    for (final action in path.reversed) {
      if (action != shot) return action;
    }
    return null;
  }

  static String? blockedReason(List<String> path, String action) {
    if (!actions.contains(action)) return 'Unknown route action.';
    if (isPreload(action))
      return path.isEmpty ? null : 'Undo to change the preload location.';
    if (path.isEmpty || !isPreload(path.first))
      return 'Choose the preload location first.';
    if (action == shot) return null;
    final inNeutral = path.where(crossings.contains).length.isOdd;
    if (action == neutral && !inNeutral)
      return 'Record a trench or bump crossing before neutral intake.';
    if (action == depot && inNeutral)
      return 'Record the crossing back before depot intake.';
    return null;
  }

  static String? validate(List<String> path) {
    final prefix = <String>[];
    for (var i = 0; i < path.length; i++) {
      // Accept the old preload labels when reading existing pit routines.
      final action = i == 0 && path[i].startsWith('Start ')
          ? path[i].replaceFirst('Start ', 'Preload ')
          : path[i];
      final error = blockedReason(prefix, action);
      if (error != null) return error;
      prefix.add(action);
    }
    return null;
  }

  static String label(String action) => switch (action) {
        'Preload Left' || 'Start Left' => 'Preload left',
        'Preload Center' || 'Start Center' => 'Preload center',
        'Preload Right' || 'Start Right' => 'Preload right',
        'Went Under Left Trench' => 'Left trench',
        'Went Over Left Bump' => 'Left bump',
        'Went Over Right Bump' => 'Right bump',
        'Went Under Right Trench' => 'Right trench',
        depot => 'Depot intake',
        neutral => 'Neutral intake',
        shot => 'Shot at hub',
        _ => action,
      };
}

import 'package:app/models/auto_route.dart';
import 'package:app/widgets/auto_field_map.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final blue in [false, true]) {
    for (final flipped in [false, true]) {
      testWidgets(
          '${blue ? 'blue' : 'red'} field uses mapped landmarks with rotated view=$flipped',
          (tester) async {
        tester.view.physicalSize = const Size(320, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var path = <String>[];
        await tester.pumpWidget(MaterialApp(
            theme: buildMatteTheme(),
            home: Scaffold(
                body: StatefulBuilder(
                    builder: (context, setState) => SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                                textScaler: const TextScaler.linear(1.3)),
                            child: AutoFieldMap(
                                path: path,
                                blue: blue,
                                flipped: flipped,
                                onAction: (action) => setState(
                                    () => path = [...path, action]))))))));
        await tester.pumpAndSettle();
        Finder target(String action) =>
            find.byKey(ValueKey('route-action-$action'));
        final image = tester
            .widget<Image>(find.byKey(const ValueKey('route-field-image')));
        expect(
            (image.image as AssetImage).assetName,
            blue
                ? 'assets/2026FRCFeildImageBlue.png'
                : 'assets/2026FRCFeildImageFull.png');
        final leftTrench = tester.getCenter(target(AutoRoute.crossings.first));
        final rightTrench = tester.getCenter(target(AutoRoute.crossings.last));
        expect(
            (blue != flipped)
                ? leftTrench.dy > rightTrench.dy
                : leftTrench.dy < rightTrench.dy,
            isTrue);
        final preload = tester.getCenter(target('Preload Center'));
        final neutral = tester.getCenter(target(AutoRoute.neutral));
        expect(
            (blue != flipped)
                ? preload.dx > neutral.dx
                : preload.dx < neutral.dx,
            isTrue);
        expect(tester.widget<FilledButton>(target(AutoRoute.neutral)).onPressed,
            isNull);
        await tester.tap(target('Preload Center'));
        await tester.pumpAndSettle();
        await tester.tap(target(AutoRoute.crossings.first));
        await tester.pumpAndSettle();
        await tester.tap(target(AutoRoute.neutral));
        await tester.pumpAndSettle();
        await tester.tap(target(AutoRoute.crossings.first));
        await tester.pumpAndSettle();
        await tester.tap(target(AutoRoute.depot));
        await tester.pumpAndSettle();
        expect(path, [
          'Preload Center',
          AutoRoute.crossings.first,
          AutoRoute.neutral,
          AutoRoute.crossings.first,
          AutoRoute.depot
        ]);
        expect(AutoRoute.validate(path), isNull);
        for (final action in [
          ...AutoRoute.crossings,
          AutoRoute.depot,
          AutoRoute.neutral,
          AutoRoute.shot
        ]) {
          final rect = tester.getRect(target(action));
          expect(rect.width, greaterThanOrEqualTo(47.99));
          expect(rect.height, greaterThanOrEqualTo(47.99));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}

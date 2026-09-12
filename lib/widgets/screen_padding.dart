// Bottom-clearance helpers for scrollable screens.
//
// Screens embedded in MainShell's IndexedStack sit behind the BottomAppBar
// (M3 default height 80dp) which is why their lists must pad past it plus
// the system gesture inset — otherwise the last cards are unreachable.
// Pushed full-screen routes only need the system inset.
import 'package:flutter/material.dart';

const double _kBottomBarHeight = 80.0;

double tabBarBottomClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + _kBottomBarHeight + 8;

double pushedScreenBottomClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + 8;

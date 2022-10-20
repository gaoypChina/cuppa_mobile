/*
 *******************************************************************************
 Package:  cuppa_mobile
 Class:    common.dart
 Author:   Nathan Cosgray | https://www.nathanatos.com
 -------------------------------------------------------------------------------
 Copyright (c) 2017-2022 Nathan Cosgray. All rights reserved.

 This source code is licensed under the BSD-style license found in LICENSE.txt.
 *******************************************************************************
*/

// Cuppa utility widgets

import 'package:cuppa_mobile/data/constants.dart';
import 'package:cuppa_mobile/data/localization.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// List divider
Widget listDivider() {
  return const Divider(
    thickness: 1.0,
    indent: 6.0,
    endIndent: 6.0,
  );
}

// About text linking to app website
Widget aboutText() {
  return InkWell(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppString.about_app.translate(),
                style: const TextStyle(
                  fontSize: 12.0,
                )),
            Row(children: const [
              Text(aboutCopyright,
                  style: TextStyle(
                    fontSize: 12.0,
                  )),
              VerticalDivider(),
              Text(aboutURL,
                  style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.blue,
                      decoration: TextDecoration.underline))
            ])
          ]),
      onTap: () =>
          launchUrl(Uri.parse(aboutURL), mode: LaunchMode.externalApplication));
}

// Dismissible delete warning background
Widget dismissibleBackground(Alignment alignment) {
  return Container(
      padding: const EdgeInsets.all(5.0),
      child: Container(
          color: Colors.red,
          child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Align(
                  alignment: alignment,
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white, size: 28.0)))));
}

// Custom draggable feedback for reorderable list
Widget draggableFeedback(
    BuildContext context, BoxConstraints constraints, Widget child) {
  return Transform(
    transform: Matrix4.rotationZ(0),
    alignment: FractionalOffset.topLeft,
    child: Container(
      decoration: const BoxDecoration(boxShadow: <BoxShadow>[
        BoxShadow(
            color: Colors.black26, blurRadius: 7.0, offset: Offset(0.0, 0.75))
      ]),
      child: ConstrainedBox(constraints: constraints, child: child),
    ),
  );
}
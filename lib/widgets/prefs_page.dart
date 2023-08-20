/*
 *******************************************************************************
 Package:  cuppa_mobile
 Class:    prefs_page.dart
 Author:   Nathan Cosgray | https://www.nathanatos.com
 -------------------------------------------------------------------------------
 Copyright (c) 2017-2023 Nathan Cosgray. All rights reserved.

 This source code is licensed under the BSD-style license found in LICENSE.txt.
 *******************************************************************************
*/

// Cuppa Preferences page
// - Build prefs interface and interactivity

import 'package:cuppa_mobile/helpers.dart';
import 'package:cuppa_mobile/data/constants.dart';
import 'package:cuppa_mobile/data/globals.dart';
import 'package:cuppa_mobile/data/localization.dart';
import 'package:cuppa_mobile/data/prefs.dart';
import 'package:cuppa_mobile/data/presets.dart';
import 'package:cuppa_mobile/data/provider.dart';
import 'package:cuppa_mobile/widgets/about_page.dart';
import 'package:cuppa_mobile/widgets/common.dart';
import 'package:cuppa_mobile/widgets/platform_adaptive.dart';
import 'package:cuppa_mobile/widgets/tea_settings_card.dart';
import 'package:cuppa_mobile/widgets/text_styles.dart';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:sliver_tools/sliver_tools.dart';

// Cuppa Preferences page
class PrefsWidget extends StatelessWidget {
  const PrefsWidget({Key? key}) : super(key: key);

  // Build Prefs page
  @override
  Widget build(BuildContext context) {
    // Determine layout based on device size
    bool layoutColumns = getDeviceSize(context).isLargeDevice;

    return Scaffold(
      appBar: PlatformAdaptiveNavBar(
        isPoppable: true,
        textScaleFactor: appTextScale,
        title: AppString.prefs_title.translate(),
        // Button to navigate to About page
        actionIcon: getPlatformAboutIcon(),
        actionRoute: const AboutWidget(),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
          child: Row(children: [
            Expanded(
              child: CustomScrollView(slivers: [
                // Teas section header
                _prefsHeader(context, AppString.teas_title.translate()),
                // Tea settings info text
                SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 12.0),
                        child: Text(AppString.prefs_header.translate(),
                            style: textStyleSubtitle)),
                  ),
                ),
                // Tea settings cards
                SliverAnimatedPaintExtent(
                  duration: longAnimationDuration,
                  child: _teaSettingsList(),
                ),
                // Add Tea and Remove All buttons
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6.0),
                    child: Row(children: [
                      Expanded(child: _addTeaButton()),
                      _removeAllButton(context),
                    ]),
                  ),
                ),
                // Other settings inline
                SliverToBoxAdapter(
                  child: Visibility(
                    visible: !layoutColumns,
                    child: _otherSettingsList(context),
                  ),
                )
              ]),
            ),
            // Other settings in second column with header
            Visibility(visible: layoutColumns, child: Container(width: 6.0)),
            Visibility(
              visible: layoutColumns,
              child: Expanded(
                child: CustomScrollView(slivers: [
                  _prefsHeader(context, AppString.settings_title.translate()),
                  SliverToBoxAdapter(child: _otherSettingsList(context))
                ]),
              ),
            )
          ]),
        ),
      ),
    );
  }

  // Prefs page column header
  Widget _prefsHeader(BuildContext context, String title) {
    return SliverAppBar(
      elevation: 1,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
      shadowColor: Theme.of(context).shadowColor,
      leadingWidth: 200.0,
      leading: Container(
        margin: const EdgeInsets.fromLTRB(6.0, 18.0, 6.0, 12.0),
        child: Text(title,
            style: textStyleHeader.copyWith(
              color: Theme.of(context).textTheme.bodyLarge!.color!,
            )),
      ),
    );
  }

  // Reoderable list of tea settings cards
  Widget _teaSettingsList() {
    return Consumer<AppProvider>(
        builder: (context, provider, child) => ReorderableSliverList(
            buildDraggableFeedback: draggableFeedback,
            onReorder: (int oldIndex, int newIndex) {
              // Reorder the tea list
              provider.reorderTeas(oldIndex, newIndex);
            },
            delegate: ReorderableSliverChildListDelegate(
                provider.teaList.map<Widget>((tea) {
              if (tea.isActive) {
                // Don't allow deleting if timer is active
                return IgnorePointer(
                    // Disable editing actively brewing tea
                    ignoring: tea.isActive,
                    child: Container(
                        key: Key('${tea.name}${tea.id}'),
                        child: TeaSettingsCard(
                          tea: tea,
                        )));
              } else {
                // Deleteable
                return Dismissible(
                  key: Key('${tea.name}${tea.id}'),
                  onDismissed: (direction) {
                    // Provide an undo option
                    int? teaIndex = provider.teaList
                        .indexWhere((item) => item.id == tea.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      duration: const Duration(milliseconds: 1500),
                      content: Text(
                          AppString.undo_message.translate(teaName: tea.name)),
                      action: SnackBarAction(
                        label: AppString.undo_button.translate(),
                        // Re-add deleted tea in its former position
                        onPressed: () =>
                            provider.addTea(tea, atIndex: teaIndex),
                      ),
                    ));

                    // Delete this from the tea list
                    provider.deleteTea(tea);
                  },
                  // Dismissible delete warning background
                  background:
                      dismissibleBackground(context, Alignment.centerLeft),
                  secondaryBackground:
                      dismissibleBackground(context, Alignment.centerRight),
                  resizeDuration: longAnimationDuration,
                  child: TeaSettingsCard(
                    tea: tea,
                  ),
                );
              }
            }).toList())));
  }

  // Add tea button
  Widget _addTeaButton() {
    return Selector<AppProvider, int>(
        selector: (_, provider) => provider.teaCount,
        builder: (context, count, child) => SizedBox(
            height: 64.0,
            child: Card(
                shadowColor: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                    child: TextButton.icon(
                  label: Text(AppString.add_tea_button.translate(),
                      style: textStyleButton),
                  icon: const Icon(Icons.add_circle, size: 20.0),
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                    const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  )),
                  // Disable adding teas if there are maximum teas
                  onPressed: count < teasMaxCount
                      ? () => openPlatformAdaptiveSelectList(
                          context: context,
                          titleText: AppString.add_tea_button.translate(),
                          buttonTextCancel: AppString.cancel_button.translate(),
                          itemList: Presets.presetList,
                          itemBuilder: _teaPresetItem,
                          separatorBuilder: _separatorBuilder)
                      : null,
                )))));
  }

  // Tea preset option
  Widget _teaPresetItem(BuildContext context, int index) {
    AppProvider provider = Provider.of<AppProvider>(context, listen: false);
    Preset preset = Presets.presetList[index];

    return PlatformAdaptiveSelectListItem(
        itemHeight: 60.0,
        item: Row(children: [
          // Preset tea icon
          SizedBox.square(
              dimension: 48.0,
              child: Icon(
                preset.isCustom ? Icons.add_circle : preset.getIcon(),
                color: preset.getThemeColor(context),
                size: preset.isCustom ? 20.0 : 24.0,
              )),
          // Localized preset tea name
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.localizedName,
                  style: textStyleSetting.copyWith(
                      color: preset.getThemeColor(context)),
                ),
                // Preset tea brew time and temperature
                Container(
                    child: preset.isCustom
                        ? null
                        : Row(children: [
                            Text(
                              formatTimer(preset.brewTime),
                              style: textStyleSettingSeconday.copyWith(
                                  color: preset.getThemeColor(context)),
                            ),
                            ConstrainedBox(
                                constraints: const BoxConstraints(
                                    minWidth: 6.0, maxWidth: 30.0),
                                child: Container()),
                            Text(
                              preset.tempDisplay(provider.useCelsius),
                              style: textStyleSettingSeconday.copyWith(
                                  color: preset.getThemeColor(context)),
                            ),
                            ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxWidth: double.infinity),
                                child: Container()),
                          ]))
              ])
        ]),
        // Add selected tea
        onTap: () {
          provider.addTea(preset.createTea(useCelsius: provider.useCelsius));
          Navigator.of(context).pop(true);
        });
  }

  // Remove all teas button
  Widget _removeAllButton(BuildContext context) {
    AppProvider provider = Provider.of<AppProvider>(context);

    return (provider.teaCount > 0 && provider.activeTeas.isEmpty)
        ? SizedBox(
            width: 64.0,
            height: 64.0,
            child: Card(
                shadowColor: Colors.transparent,
                surfaceTintColor: Theme.of(context).colorScheme.error,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                    child: getPlatformRemoveAllIcon(
                        Theme.of(context).colorScheme.error),
                    onTap: () async {
                      AppProvider provider =
                          Provider.of<AppProvider>(context, listen: false);
                      bool confirmed = await _confirmDelete(context);
                      if (confirmed) {
                        // Clear tea list
                        provider.clearTeaList();
                      }
                    })))
        : const SizedBox.shrink();
  }

  // Delete confirmation dialog
  Future _confirmDelete(BuildContext context) {
    return showAdaptiveDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog.adaptive(
              title: Text(AppString.confirm_title.translate()),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(AppString.confirm_delete.translate()),
                  ],
                ),
              ),
              actions: [
                adaptiveDialogAction(
                  isDefaultAction: true,
                  text: AppString.no_button.translate(),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                adaptiveDialogAction(
                  text: AppString.yes_button.translate(),
                  onPressed: () => Navigator.of(context).pop(true),
                )
              ]);
        });
  }

  // List of other settings
  Widget _otherSettingsList(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 6.0),
        child: Column(children: [
          // Setting: show extra info on buttons
          _showExtraSetting(context),
          listDivider,
          // Setting: default to Celsius or Fahrenheit
          _useCelsiusSetting(context),
          listDivider,
          // Setting: app theme selection
          _appThemeSetting(context),
          listDivider,
          // Setting: app language selection
          _appLanguageSetting(context),
          listDivider,
          // Notification info
          _notificationLink(),
        ]));
  }

  // Setting: show extra info on buttons
  Widget _showExtraSetting(BuildContext context) {
    AppProvider provider = Provider.of<AppProvider>(context);

    return Align(
        alignment: Alignment.topLeft,
        child: SwitchListTile.adaptive(
          title: Text(AppString.prefs_show_extra.translate(),
              style: textStyleTitle),
          value: provider.showExtra,
          // Save showExtra setting to prefs
          onChanged: (bool newValue) {
            provider.showExtra = newValue;
          },
          contentPadding: const EdgeInsets.all(6.0),
          dense: true,
        ));
  }

  // Setting: default to Celsius or Fahrenheit
  Widget _useCelsiusSetting(BuildContext context) {
    AppProvider provider = Provider.of<AppProvider>(context);

    return Align(
        alignment: Alignment.topLeft,
        child: SwitchListTile.adaptive(
          title: Text(AppString.prefs_use_celsius.translate(),
              style: textStyleTitle),
          value: provider.useCelsius,
          // Save useCelsius setting to prefs
          onChanged: (bool newValue) {
            provider.useCelsius = newValue;
          },
          contentPadding: const EdgeInsets.all(6.0),
          dense: true,
        ));
  }

  // Setting: app theme selection
  Widget _appThemeSetting(BuildContext context) {
    AppProvider provider = Provider.of<AppProvider>(context);

    return Align(
        alignment: Alignment.topLeft,
        child: ListTile(
          title: Text(AppString.prefs_app_theme.translate(),
              style: textStyleTitle),
          trailing: Text(
            provider.appTheme.localizedName,
            style: textStyleTitle.copyWith(
                color: Theme.of(context).textTheme.bodySmall!.color!),
          ),
          // Open app theme dialog
          onTap: () => openPlatformAdaptiveSelectList(
              context: context,
              titleText: AppString.prefs_app_theme.translate(),
              buttonTextCancel: AppString.cancel_button.translate(),
              itemList: AppTheme.values,
              itemBuilder: _appThemeItem,
              separatorBuilder: _separatorDummy),
          contentPadding: const EdgeInsets.all(6.0),
          dense: true,
        ));
  }

  // App theme option
  Widget _appThemeItem(BuildContext context, int index) {
    AppProvider provider = Provider.of<AppProvider>(context, listen: false);
    AppTheme value = AppTheme.values.elementAt(index);

    return RadioListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6.0),
        dense: true,
        useCupertinoCheckmarkStyle: true,
        value: value,
        groupValue: provider.appTheme,
        // Theme name
        title: Text(
          value.localizedName,
          style: textStyleTitle,
        ),
        // Save appTheme to prefs
        onChanged: (_) {
          provider.appTheme = value;
          Navigator.of(context).pop(true);
        });
  }

  // Setting: app language selection
  Widget _appLanguageSetting(BuildContext context) {
    AppProvider provider = Provider.of<AppProvider>(context);

    return Align(
        alignment: Alignment.topLeft,
        child: ListTile(
          title:
              Text(AppString.prefs_language.translate(), style: textStyleTitle),
          trailing: Text(
              provider.appLanguage != followSystemLanguage &&
                      supportedLocales
                          .containsKey(parseLocaleString(provider.appLanguage))
                  ? supportedLocales[parseLocaleString(provider.appLanguage)]!
                  : AppString.theme_system.translate(),
              style: textStyleTitle.copyWith(
                  color: Theme.of(context).textTheme.bodySmall!.color!)),
          // Open app language dialog
          onTap: () => openPlatformAdaptiveSelectList(
              context: context,
              titleText: AppString.prefs_language.translate(),
              buttonTextCancel: AppString.cancel_button.translate(),
              itemList: languageOptions,
              itemBuilder: _appLanguageItem,
              separatorBuilder: _separatorDummy),
          contentPadding: const EdgeInsets.all(6.0),
          dense: true,
        ));
  }

  // App language option
  Widget _appLanguageItem(BuildContext context, int index) {
    AppProvider provider = Provider.of<AppProvider>(context, listen: false);
    String value = languageOptions[index];

    return RadioListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6.0),
        dense: true,
        useCupertinoCheckmarkStyle: true,
        value: value,
        groupValue: provider.appLanguage,
        // Language name
        title: Text(
          value != followSystemLanguage &&
                  supportedLocales.containsKey(parseLocaleString(value))
              ? supportedLocales[parseLocaleString(value)]!
              : AppString.theme_system.translate(),
          style: textStyleTitle,
        ),
        // Save appLanguage to prefs
        onChanged: (_) {
          provider.appLanguage = value;
          Navigator.of(context).pop(true);
        });
  }

  // Select list separator
  Widget _separatorBuilder(BuildContext context, int index) {
    return listDivider;
  }

  // Placeholder list separator
  Widget _separatorDummy(BuildContext context, int index) {
    return Container();
  }

  // Notification settings info text and link
  Widget _notificationLink() {
    return InkWell(
        child: ListTile(
      minLeadingWidth: 30.0,
      leading: const SizedBox(
          height: double.infinity,
          child: Icon(
            Icons.info,
            size: 20.0,
          )),
      horizontalTitleGap: 0.0,
      title: Text(AppString.prefs_notifications.translate(),
          style: textStyleSubtitle),
      trailing: const SizedBox(height: double.infinity, child: launchIcon),
      onTap: () =>
          AppSettings.openAppSettings(type: AppSettingsType.notification),
      contentPadding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 18.0),
      dense: true,
    ));
  }
}

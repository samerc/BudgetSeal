import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dashboard sections that can be reordered and toggled.
enum DashboardSection {
  status('Status Card', 'Budget status, velocity, age of money'),
  spending('Spending Overview', 'Donut chart with category breakdown'),
  quickActions('Quick Actions', 'Expense, income, transfer, fund'),
  money('Your Money', 'Net worth and envelope health'),
  unallocated('Ready to Assign', 'Unallocated funds'),
  activity('Recent Activity', 'Templates and recent transactions');

  final String label;
  final String description;
  const DashboardSection(this.label, this.description);
}

class DashboardSectionConfig {
  final DashboardSection section;
  final bool visible;

  const DashboardSectionConfig({
    required this.section,
    this.visible = true,
  });

  Map<String, dynamic> toJson() => {
        'section': section.name,
        'visible': visible,
      };

  factory DashboardSectionConfig.fromJson(Map<String, dynamic> json) {
    return DashboardSectionConfig(
      section: DashboardSection.values
          .firstWhere((s) => s.name == json['section'],
              orElse: () => DashboardSection.status),
      visible: json['visible'] as bool? ?? true,
    );
  }
}

const _defaultOrder = [
  DashboardSectionConfig(section: DashboardSection.status),
  DashboardSectionConfig(section: DashboardSection.spending),
  DashboardSectionConfig(section: DashboardSection.quickActions),
  DashboardSectionConfig(section: DashboardSection.money),
  DashboardSectionConfig(section: DashboardSection.unallocated),
  DashboardSectionConfig(section: DashboardSection.activity),
];

const _prefsKey = 'dashboard_layout';

class DashboardLayoutNotifier extends Notifier<List<DashboardSectionConfig>> {
  @override
  List<DashboardSectionConfig> build() {
    _load();
    return _defaultOrder;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json != null) {
      try {
        final list = (jsonDecode(json) as List)
            .map((e) => DashboardSectionConfig.fromJson(e))
            .toList();
        // Ensure all sections are present (in case new ones were added)
        final existing = list.map((c) => c.section).toSet();
        for (final sec in DashboardSection.values) {
          if (!existing.contains(sec)) {
            list.add(DashboardSectionConfig(section: sec));
          }
        }
        state = list;
      } catch (_) {
        state = _defaultOrder;
      }
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefsKey, jsonEncode(state.map((c) => c.toJson()).toList()));
    } catch (_) {
      // Non-critical — layout will reset to defaults next launch
    }
  }

  void reorder(int oldIndex, int newIndex) {
    final items = [...state];
    if (newIndex > oldIndex) newIndex--;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
    _save();
  }

  void toggleVisibility(DashboardSection section) {
    state = [
      for (final c in state)
        if (c.section == section)
          DashboardSectionConfig(section: section, visible: !c.visible)
        else
          c,
    ];
    _save();
  }

  void reset() {
    state = _defaultOrder;
    _save();
  }
}

final dashboardLayoutProvider =
    NotifierProvider<DashboardLayoutNotifier, List<DashboardSectionConfig>>(
        DashboardLayoutNotifier.new);

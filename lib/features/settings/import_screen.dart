import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';

/// The role a CSV column can be assigned to.
enum ColumnRole { skip, date, description, amount, category }

extension ColumnRoleLabel on ColumnRole {
  String localizedLabel(BuildContext context) {
    switch (this) {
      case ColumnRole.skip:
        return S.of(context).importColSkip;
      case ColumnRole.date:
        return S.of(context).importColDate;
      case ColumnRole.description:
        return S.of(context).importColDescription;
      case ColumnRole.amount:
        return S.of(context).commonAmount;
      case ColumnRole.category:
        return S.of(context).commonCategory;
    }
  }

  IconData get icon {
    switch (this) {
      case ColumnRole.skip:
        return Icons.block_rounded;
      case ColumnRole.date:
        return Icons.calendar_today_rounded;
      case ColumnRole.description:
        return Icons.notes_rounded;
      case ColumnRole.amount:
        return Icons.attach_money_rounded;
      case ColumnRole.category:
        return Icons.category_rounded;
    }
  }
}

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  List<List<dynamic>>? _csvData;
  String? _fileName;
  bool _importing = false;
  int _imported = 0;
  String? _selectedAccountId;
  final bool _hasHeader = true;

  /// One role per CSV column, filled after loading.
  List<ColumnRole> _columnRoles = [];

  // ── CSV Loading ──────────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;

      final content = await File(path).readAsString();
      final data = const CsvDecoder().convert(content);
      if (data.isNotEmpty && mounted) {
        setState(() {
          _csvData = data;
          _fileName = result.files.single.name;
          _columnRoles = _autoDetectRoles(data);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).importFailed)),
        );
      }
    }
  }

  // ── Auto-detection ───────────────────────────────────────────

  /// Scans headers + first data rows and assigns a best-guess role to each column.
  List<ColumnRole> _autoDetectRoles(List<List<dynamic>> data) {
    if (data.isEmpty) return [];
    final colCount = data.first.length;
    final roles = List.filled(colCount, ColumnRole.skip);

    // Collect up to 5 sample rows (header + 4 data rows).
    final samples = data.take(5).toList();

    int? bestDate;
    int? bestAmount;
    int? bestDesc;
    int? bestCategory;
    double bestDateScore = 0;
    double bestAmountScore = 0;
    double bestDescScore = 0;
    double bestCategoryScore = 0;

    for (int col = 0; col < colCount; col++) {
      double dateScore = 0;
      double amountScore = 0;
      double descScore = 0;
      double categoryScore = 0;

      for (int row = 0; row < samples.length; row++) {
        final val = samples[row][col].toString().trim();
        final lower = val.toLowerCase();
        final isHeader = row == 0;

        if (isHeader) {
          // Header keyword heuristics
          if (_matchesAny(lower, ['date', 'time', 'posted', 'transaction date', 'trans date'])) {
            dateScore += 3;
          }
          if (_matchesAny(lower, ['amount', 'sum', 'value', 'debit', 'credit', 'total'])) {
            amountScore += 3;
          }
          if (_matchesAny(lower, ['desc', 'description', 'memo', 'note', 'narrative', 'detail', 'particulars', 'reference'])) {
            descScore += 3;
          }
          if (_matchesAny(lower, ['category', 'cat', 'type', 'group'])) {
            categoryScore += 3;
          }
        } else {
          // Data row heuristics
          if (_looksLikeDate(val)) dateScore += 1;
          if (_looksLikeAmount(val)) amountScore += 1;
          if (_looksLikeDescription(val)) descScore += 1;
          // Short non-numeric strings that aren't dates could be categories
          if (val.length > 1 && val.length < 40 && !_looksLikeDate(val) && !_looksLikeAmount(val)) {
            categoryScore += 0.3;
          }
        }
      }

      if (dateScore > bestDateScore) {
        bestDateScore = dateScore;
        bestDate = col;
      }
      if (amountScore > bestAmountScore) {
        bestAmountScore = amountScore;
        bestAmount = col;
      }
      if (descScore > bestDescScore) {
        bestDescScore = descScore;
        bestDesc = col;
      }
      if (categoryScore > bestCategoryScore) {
        bestCategoryScore = categoryScore;
        bestCategory = col;
      }
    }

    // Assign in priority order, avoiding duplicates.
    final used = <int>{};
    if (bestDate != null && bestDateScore > 0) {
      roles[bestDate] = ColumnRole.date;
      used.add(bestDate);
    }
    if (bestAmount != null && bestAmountScore > 0 && !used.contains(bestAmount)) {
      roles[bestAmount] = ColumnRole.amount;
      used.add(bestAmount);
    }
    if (bestDesc != null && bestDescScore > 0 && !used.contains(bestDesc)) {
      roles[bestDesc] = ColumnRole.description;
      used.add(bestDesc);
    }
    if (bestCategory != null && bestCategoryScore > 1 && !used.contains(bestCategory)) {
      roles[bestCategory] = ColumnRole.category;
    }

    return roles;
  }

  bool _matchesAny(String s, List<String> keywords) =>
      keywords.any((k) => s.contains(k));

  bool _looksLikeDate(String s) {
    if (s.isEmpty) return false;
    // e.g. 2024-01-15, 01/15/2024, 15-Jan-2024
    return RegExp(r'^\d{1,4}[/\-\.]\d{1,2}[/\-\.]\d{1,4}$').hasMatch(s) ||
        RegExp(r'^\d{1,2}[/\-]\w{3}[/\-]\d{2,4}$', caseSensitive: false).hasMatch(s);
  }

  bool _looksLikeAmount(String s) {
    if (s.isEmpty) return false;
    // e.g. -1234.56, $1,234.56, 1234
    final cleaned = s.replaceAll(RegExp(r'[\$\s,]'), '');
    return RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(cleaned);
  }

  bool _looksLikeDescription(String s) {
    // Longer text with spaces is likely a description
    return s.length > 10 && s.contains(' ');
  }

  // ── Helpers for mapped column indices ────────────────────────

  int? _colFor(ColumnRole role) {
    final idx = _columnRoles.indexOf(role);
    return idx == -1 ? null : idx;
  }

  // ── Import Logic ─────────────────────────────────────────────

  Future<void> _import() async {
    if (_csvData == null || _selectedAccountId == null) return;
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    final dateCol = _colFor(ColumnRole.date);
    final descCol = _colFor(ColumnRole.description);
    final amountCol = _colFor(ColumnRole.amount);
    final categoryCol = _colFor(ColumnRole.category);

    if (amountCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).importAssignAmount)),
      );
      return;
    }

    setState(() {
      _importing = true;
      _imported = 0;
    });

    try {
      final db = ref.read(databaseProvider);
      final account = (ref.read(accountsProvider).value ?? [])
          .where((a) => a.id == _selectedAccountId).firstOrNull;
      if (account == null) return;

      // Build a name -> id lookup for category matching
      final categories = ref.read(categoriesProvider).value ?? [];
      final catLookup = <String, String>{};
      for (final cat in categories) {
        catLookup[cat.name.toLowerCase().trim()] = cat.id;
      }

      final rows = _hasHeader ? _csvData!.skip(1) : _csvData!;

      for (final row in rows) {
        if (row.length <= amountCol) continue;

        final desc = descCol != null && row.length > descCol
            ? row[descCol].toString().trim()
            : '';
        final amountStr =
            row[amountCol].toString().replaceAll(RegExp(r'[\$,\s]'), '');
        final amount = double.tryParse(amountStr);
        if (amount == null) continue;
        if (amount.abs() > 1e9) continue;

        // Parse date
        DateTime? date;
        if (dateCol != null && row.length > dateCol) {
          final dateStr = row[dateCol].toString().trim();
          for (final fmt in [
            'yyyy-MM-dd',
            'MM/dd/yyyy',
            'dd/MM/yyyy',
            'M/d/yyyy'
          ]) {
            try {
              date = _parseDate(dateStr, fmt);
              break;
            } catch (e) {
              // Expected: trying multiple date formats until one works.
              debugPrint('Date format $fmt did not match "$dateStr": $e');
            }
          }
        }
        date ??= DateTime.now();

        // Match category by name
        String? matchedCategoryId;
        if (categoryCol != null && row.length > categoryCol) {
          final catName = row[categoryCol].toString().toLowerCase().trim();
          matchedCategoryId = catLookup[catName];
        }

        final isIncome = amount > 0;
        final txId = const Uuid().v4();

        await db.into(db.transactions).insert(TransactionsCompanion.insert(
              id: txId,
              householdId: householdId,
              type: isIncome ? 'income' : 'expense',
              accountId: _selectedAccountId!,
              categoryId: matchedCategoryId != null
                  ? Value(matchedCategoryId)
                  : const Value.absent(),
              amount: amount.abs(),
              currency: account.currency,
              note: Value(desc),
              createdBy: 'import',
              deviceId: 'local',
              createdAt: Value(date),
            ));

        setState(() => _imported++);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).importSuccess(_imported)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  DateTime _parseDate(String s, String fmt) {
    final parts = s.split(RegExp(r'[/\-]'));
    if (parts.length != 3) throw const FormatException();
    if (fmt == 'yyyy-MM-dd') {
      return DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } else if (fmt == 'MM/dd/yyyy' || fmt == 'M/d/yyyy') {
      return DateTime(
          int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
    } else if (fmt == 'dd/MM/yyyy') {
      return DateTime(
          int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    }
    throw const FormatException();
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).importCsvTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilePickerCard(),
            if (_csvData != null) ...[
              const SizedBox(height: 16),
              Text(
                S.of(context).importFoundRows(_csvData!.length, _fileName ?? ''),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildColumnMapper(),
              const SizedBox(height: 16),
              _buildMappedPreview(),
              const SizedBox(height: 16),
              _buildAccountSelector(accounts),
              const SizedBox(height: 20),
              _buildImportButton(),
            ],
          ],
        ),
      ),
    );
  }

  // ── File Picker Card ─────────────────────────────────────────

  Widget _buildFilePickerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file_rounded, size: 24, color: AppColors.accent),
              const SizedBox(width: 12),
              Text(S.of(context).importFromBank,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            S.of(context).importCsvDesc,
            style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: Text(S.of(context).importLoadCsv),
          ),
        ],
      ),
    );
  }

  // ── Column Mapper ────────────────────────────────────────────

  Widget _buildColumnMapper() {
    final headers = _csvData!.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_column_rounded, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                S.of(context).importColumnMapping,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context).importColumnMapDesc,
            style: TextStyle(fontSize: 12, color: AppColors.ts(context)),
          ),
          const SizedBox(height: 12),
          ...List.generate(headers.length, (i) {
            final headerText = headers[i].toString().trim();
            // Show a sample value from the first data row if available
            final sampleValue = _csvData!.length > 1
                ? _csvData![1][i].toString().trim()
                : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // Column info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sampleValue.isNotEmpty)
                          Text(
                            sampleValue,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.ts(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Role dropdown
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _columnRoles[i] != ColumnRole.skip
                              ? AppColors.accent.withValues(alpha:0.4)
                              : AppColors.bd(context),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ColumnRole>(
                          value: _columnRoles[i],
                          isExpanded: true,
                          isDense: true,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.tp(context),
                          ),
                          dropdownColor: AppColors.sf(context),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.ts(context),
                          ),
                          items: ColumnRole.values.map((role) {
                            // Disable roles already assigned to another column
                            // (except Skip, which can be reused).
                            final existingIdx = _columnRoles.indexOf(role);
                            final alreadyUsed = role != ColumnRole.skip &&
                                existingIdx != -1 &&
                                existingIdx != i;

                            return DropdownMenuItem(
                              value: role,
                              enabled: !alreadyUsed,
                              child: Row(
                                children: [
                                  Icon(
                                    role.icon,
                                    size: 14,
                                    color: alreadyUsed
                                        ? AppColors.th(context)
                                        : AppColors.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    role.localizedLabel(context),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: alreadyUsed
                                          ? AppColors.th(context)
                                          : AppColors.tp(context),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (role) {
                            if (role == null) return;
                            setState(() {
                              // If this role was previously assigned elsewhere, clear it.
                              if (role != ColumnRole.skip) {
                                final prev = _columnRoles.indexOf(role);
                                if (prev != -1 && prev != i) {
                                  _columnRoles[prev] = ColumnRole.skip;
                                }
                              }
                              _columnRoles[i] = role;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Mapped Preview ───────────────────────────────────────────

  Widget _buildMappedPreview() {
    final dateCol = _colFor(ColumnRole.date);
    final descCol = _colFor(ColumnRole.description);
    final amountCol = _colFor(ColumnRole.amount);
    final categoryCol = _colFor(ColumnRole.category);

    // Take up to 3 data rows (skip header)
    final previewRows = _csvData!.skip(_hasHeader ? 1 : 0).take(3).toList();

    if (previewRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview_rounded, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                S.of(context).importPreview,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (dateCol != null)
                  _previewHeaderCell(S.of(context).importColDate),
                _previewHeaderCell(S.of(context).importColDescription),
                _previewHeaderCell(S.of(context).commonAmount),
                if (categoryCol != null)
                  _previewHeaderCell(S.of(context).commonCategory),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Data rows
          ...previewRows.map((row) {
            final dateStr = dateCol != null && row.length > dateCol
                ? row[dateCol].toString().trim()
                : '--';
            final descStr = descCol != null && row.length > descCol
                ? row[descCol].toString().trim()
                : '--';
            final amtStr = amountCol != null && row.length > amountCol
                ? row[amountCol].toString().trim()
                : '--';
            final catStr = categoryCol != null && row.length > categoryCol
                ? row[categoryCol].toString().trim()
                : null;

            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.bd(context).withValues(alpha:0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (dateCol != null)
                    _previewDataCell(dateStr),
                  _previewDataCell(descStr),
                  _previewDataCell(
                    amtStr,
                    color: amtStr.startsWith('-')
                        ? AppColors.overspent
                        : AppColors.healthy,
                  ),
                  if (categoryCol != null)
                    _previewDataCell(catStr ?? '--'),
                ],
              ),
            );
          }),
          if (amountCol == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.caution),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      S.of(context).importNoAmount,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.caution),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _previewHeaderCell(String text) {
    return Expanded(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _previewDataCell(String text, {Color? color}) {
    return Expanded(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color ?? AppColors.tp(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Account Selector ─────────────────────────────────────────

  Widget _buildAccountSelector(List<Account> accounts) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedAccountId,
      decoration: InputDecoration(labelText: S.of(context).importIntoAccount),
      items: accounts
          .map((a) => DropdownMenuItem(
              value: a.id, child: Text('${a.name} (${a.currency})')))
          .toList(),
      onChanged: (v) => setState(() => _selectedAccountId = v),
    );
  }

  // ── Import Button ────────────────────────────────────────────

  Widget _buildImportButton() {
    final rowCount = _csvData!.length - (_hasHeader ? 1 : 0);
    return FilledButton(
      onPressed:
          _importing || _selectedAccountId == null || _colFor(ColumnRole.amount) == null
              ? null
              : _import,
      child: _importing
          ? Text(S.of(context).importImporting(_imported))
          : Text(S.of(context).importButton(rowCount)),
    );
  }
}

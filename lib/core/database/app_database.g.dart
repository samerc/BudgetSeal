// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HouseholdsTable extends Households
    with TableInfo<$HouseholdsTable, Household> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseCurrencyMeta =
      const VerificationMeta('baseCurrency');
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
      'base_currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('USD'));
  static const VerificationMeta _periodStartDayMeta =
      const VerificationMeta('periodStartDay');
  @override
  late final GeneratedColumn<int> periodStartDay = GeneratedColumn<int>(
      'period_start_day', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _autoPromptPeriodMeta =
      const VerificationMeta('autoPromptPeriod');
  @override
  late final GeneratedColumn<bool> autoPromptPeriod = GeneratedColumn<bool>(
      'auto_prompt_period', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_prompt_period" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _allowSkipPeriodMeta =
      const VerificationMeta('allowSkipPeriod');
  @override
  late final GeneratedColumn<bool> allowSkipPeriod = GeneratedColumn<bool>(
      'allow_skip_period', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("allow_skip_period" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdByDeviceIdMeta =
      const VerificationMeta('createdByDeviceId');
  @override
  late final GeneratedColumn<String> createdByDeviceId =
      GeneratedColumn<String>('created_by_device_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _settingsJsonMeta =
      const VerificationMeta('settingsJson');
  @override
  late final GeneratedColumn<String> settingsJson = GeneratedColumn<String>(
      'settings_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        baseCurrency,
        periodStartDay,
        autoPromptPeriod,
        allowSkipPeriod,
        createdByDeviceId,
        settingsJson,
        createdAt,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'households';
  @override
  VerificationContext validateIntegrity(Insertable<Household> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_currency')) {
      context.handle(
          _baseCurrencyMeta,
          baseCurrency.isAcceptableOrUnknown(
              data['base_currency']!, _baseCurrencyMeta));
    }
    if (data.containsKey('period_start_day')) {
      context.handle(
          _periodStartDayMeta,
          periodStartDay.isAcceptableOrUnknown(
              data['period_start_day']!, _periodStartDayMeta));
    }
    if (data.containsKey('auto_prompt_period')) {
      context.handle(
          _autoPromptPeriodMeta,
          autoPromptPeriod.isAcceptableOrUnknown(
              data['auto_prompt_period']!, _autoPromptPeriodMeta));
    }
    if (data.containsKey('allow_skip_period')) {
      context.handle(
          _allowSkipPeriodMeta,
          allowSkipPeriod.isAcceptableOrUnknown(
              data['allow_skip_period']!, _allowSkipPeriodMeta));
    }
    if (data.containsKey('created_by_device_id')) {
      context.handle(
          _createdByDeviceIdMeta,
          createdByDeviceId.isAcceptableOrUnknown(
              data['created_by_device_id']!, _createdByDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_createdByDeviceIdMeta);
    }
    if (data.containsKey('settings_json')) {
      context.handle(
          _settingsJsonMeta,
          settingsJson.isAcceptableOrUnknown(
              data['settings_json']!, _settingsJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Household map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Household(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      baseCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_currency'])!,
      periodStartDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_start_day'])!,
      autoPromptPeriod: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}auto_prompt_period'])!,
      allowSkipPeriod: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}allow_skip_period'])!,
      createdByDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}created_by_device_id'])!,
      settingsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}settings_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $HouseholdsTable createAlias(String alias) {
    return $HouseholdsTable(attachedDatabase, alias);
  }
}

class Household extends DataClass implements Insertable<Household> {
  final String id;
  final String name;
  final String baseCurrency;
  final int periodStartDay;
  final bool autoPromptPeriod;
  final bool allowSkipPeriod;
  final String createdByDeviceId;
  final String settingsJson;
  final DateTime createdAt;
  final DateTime lastModified;
  const Household(
      {required this.id,
      required this.name,
      required this.baseCurrency,
      required this.periodStartDay,
      required this.autoPromptPeriod,
      required this.allowSkipPeriod,
      required this.createdByDeviceId,
      required this.settingsJson,
      required this.createdAt,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['base_currency'] = Variable<String>(baseCurrency);
    map['period_start_day'] = Variable<int>(periodStartDay);
    map['auto_prompt_period'] = Variable<bool>(autoPromptPeriod);
    map['allow_skip_period'] = Variable<bool>(allowSkipPeriod);
    map['created_by_device_id'] = Variable<String>(createdByDeviceId);
    map['settings_json'] = Variable<String>(settingsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  HouseholdsCompanion toCompanion(bool nullToAbsent) {
    return HouseholdsCompanion(
      id: Value(id),
      name: Value(name),
      baseCurrency: Value(baseCurrency),
      periodStartDay: Value(periodStartDay),
      autoPromptPeriod: Value(autoPromptPeriod),
      allowSkipPeriod: Value(allowSkipPeriod),
      createdByDeviceId: Value(createdByDeviceId),
      settingsJson: Value(settingsJson),
      createdAt: Value(createdAt),
      lastModified: Value(lastModified),
    );
  }

  factory Household.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Household(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      periodStartDay: serializer.fromJson<int>(json['periodStartDay']),
      autoPromptPeriod: serializer.fromJson<bool>(json['autoPromptPeriod']),
      allowSkipPeriod: serializer.fromJson<bool>(json['allowSkipPeriod']),
      createdByDeviceId: serializer.fromJson<String>(json['createdByDeviceId']),
      settingsJson: serializer.fromJson<String>(json['settingsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'periodStartDay': serializer.toJson<int>(periodStartDay),
      'autoPromptPeriod': serializer.toJson<bool>(autoPromptPeriod),
      'allowSkipPeriod': serializer.toJson<bool>(allowSkipPeriod),
      'createdByDeviceId': serializer.toJson<String>(createdByDeviceId),
      'settingsJson': serializer.toJson<String>(settingsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  Household copyWith(
          {String? id,
          String? name,
          String? baseCurrency,
          int? periodStartDay,
          bool? autoPromptPeriod,
          bool? allowSkipPeriod,
          String? createdByDeviceId,
          String? settingsJson,
          DateTime? createdAt,
          DateTime? lastModified}) =>
      Household(
        id: id ?? this.id,
        name: name ?? this.name,
        baseCurrency: baseCurrency ?? this.baseCurrency,
        periodStartDay: periodStartDay ?? this.periodStartDay,
        autoPromptPeriod: autoPromptPeriod ?? this.autoPromptPeriod,
        allowSkipPeriod: allowSkipPeriod ?? this.allowSkipPeriod,
        createdByDeviceId: createdByDeviceId ?? this.createdByDeviceId,
        settingsJson: settingsJson ?? this.settingsJson,
        createdAt: createdAt ?? this.createdAt,
        lastModified: lastModified ?? this.lastModified,
      );
  Household copyWithCompanion(HouseholdsCompanion data) {
    return Household(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      periodStartDay: data.periodStartDay.present
          ? data.periodStartDay.value
          : this.periodStartDay,
      autoPromptPeriod: data.autoPromptPeriod.present
          ? data.autoPromptPeriod.value
          : this.autoPromptPeriod,
      allowSkipPeriod: data.allowSkipPeriod.present
          ? data.allowSkipPeriod.value
          : this.allowSkipPeriod,
      createdByDeviceId: data.createdByDeviceId.present
          ? data.createdByDeviceId.value
          : this.createdByDeviceId,
      settingsJson: data.settingsJson.present
          ? data.settingsJson.value
          : this.settingsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Household(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('periodStartDay: $periodStartDay, ')
          ..write('autoPromptPeriod: $autoPromptPeriod, ')
          ..write('allowSkipPeriod: $allowSkipPeriod, ')
          ..write('createdByDeviceId: $createdByDeviceId, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      baseCurrency,
      periodStartDay,
      autoPromptPeriod,
      allowSkipPeriod,
      createdByDeviceId,
      settingsJson,
      createdAt,
      lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Household &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseCurrency == this.baseCurrency &&
          other.periodStartDay == this.periodStartDay &&
          other.autoPromptPeriod == this.autoPromptPeriod &&
          other.allowSkipPeriod == this.allowSkipPeriod &&
          other.createdByDeviceId == this.createdByDeviceId &&
          other.settingsJson == this.settingsJson &&
          other.createdAt == this.createdAt &&
          other.lastModified == this.lastModified);
}

class HouseholdsCompanion extends UpdateCompanion<Household> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> baseCurrency;
  final Value<int> periodStartDay;
  final Value<bool> autoPromptPeriod;
  final Value<bool> allowSkipPeriod;
  final Value<String> createdByDeviceId;
  final Value<String> settingsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const HouseholdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.periodStartDay = const Value.absent(),
    this.autoPromptPeriod = const Value.absent(),
    this.allowSkipPeriod = const Value.absent(),
    this.createdByDeviceId = const Value.absent(),
    this.settingsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdsCompanion.insert({
    required String id,
    required String name,
    this.baseCurrency = const Value.absent(),
    this.periodStartDay = const Value.absent(),
    this.autoPromptPeriod = const Value.absent(),
    this.allowSkipPeriod = const Value.absent(),
    required String createdByDeviceId,
    this.settingsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdByDeviceId = Value(createdByDeviceId);
  static Insertable<Household> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? baseCurrency,
    Expression<int>? periodStartDay,
    Expression<bool>? autoPromptPeriod,
    Expression<bool>? allowSkipPeriod,
    Expression<String>? createdByDeviceId,
    Expression<String>? settingsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (periodStartDay != null) 'period_start_day': periodStartDay,
      if (autoPromptPeriod != null) 'auto_prompt_period': autoPromptPeriod,
      if (allowSkipPeriod != null) 'allow_skip_period': allowSkipPeriod,
      if (createdByDeviceId != null) 'created_by_device_id': createdByDeviceId,
      if (settingsJson != null) 'settings_json': settingsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? baseCurrency,
      Value<int>? periodStartDay,
      Value<bool>? autoPromptPeriod,
      Value<bool>? allowSkipPeriod,
      Value<String>? createdByDeviceId,
      Value<String>? settingsJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return HouseholdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      periodStartDay: periodStartDay ?? this.periodStartDay,
      autoPromptPeriod: autoPromptPeriod ?? this.autoPromptPeriod,
      allowSkipPeriod: allowSkipPeriod ?? this.allowSkipPeriod,
      createdByDeviceId: createdByDeviceId ?? this.createdByDeviceId,
      settingsJson: settingsJson ?? this.settingsJson,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (periodStartDay.present) {
      map['period_start_day'] = Variable<int>(periodStartDay.value);
    }
    if (autoPromptPeriod.present) {
      map['auto_prompt_period'] = Variable<bool>(autoPromptPeriod.value);
    }
    if (allowSkipPeriod.present) {
      map['allow_skip_period'] = Variable<bool>(allowSkipPeriod.value);
    }
    if (createdByDeviceId.present) {
      map['created_by_device_id'] = Variable<String>(createdByDeviceId.value);
    }
    if (settingsJson.present) {
      map['settings_json'] = Variable<String>(settingsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('periodStartDay: $periodStartDay, ')
          ..write('autoPromptPeriod: $autoPromptPeriod, ')
          ..write('allowSkipPeriod: $allowSkipPeriod, ')
          ..write('createdByDeviceId: $createdByDeviceId, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES households (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('member'));
  static const VerificationMeta _permissionsJsonMeta =
      const VerificationMeta('permissionsJson');
  @override
  late final GeneratedColumn<String> permissionsJson = GeneratedColumn<String>(
      'permissions_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        name,
        role,
        permissionsJson,
        deviceId,
        createdAt,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('permissions_json')) {
      context.handle(
          _permissionsJsonMeta,
          permissionsJson.isAcceptableOrUnknown(
              data['permissions_json']!, _permissionsJsonMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      permissionsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}permissions_json'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String householdId;
  final String name;
  final String role;
  final String permissionsJson;
  final String deviceId;
  final DateTime createdAt;
  final DateTime lastModified;
  const User(
      {required this.id,
      required this.householdId,
      required this.name,
      required this.role,
      required this.permissionsJson,
      required this.deviceId,
      required this.createdAt,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['permissions_json'] = Variable<String>(permissionsJson);
    map['device_id'] = Variable<String>(deviceId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      role: Value(role),
      permissionsJson: Value(permissionsJson),
      deviceId: Value(deviceId),
      createdAt: Value(createdAt),
      lastModified: Value(lastModified),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      permissionsJson: serializer.fromJson<String>(json['permissionsJson']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'permissionsJson': serializer.toJson<String>(permissionsJson),
      'deviceId': serializer.toJson<String>(deviceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  User copyWith(
          {String? id,
          String? householdId,
          String? name,
          String? role,
          String? permissionsJson,
          String? deviceId,
          DateTime? createdAt,
          DateTime? lastModified}) =>
      User(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        name: name ?? this.name,
        role: role ?? this.role,
        permissionsJson: permissionsJson ?? this.permissionsJson,
        deviceId: deviceId ?? this.deviceId,
        createdAt: createdAt ?? this.createdAt,
        lastModified: lastModified ?? this.lastModified,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      permissionsJson: data.permissionsJson.present
          ? data.permissionsJson.value
          : this.permissionsJson,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, name, role, permissionsJson,
      deviceId, createdAt, lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.role == this.role &&
          other.permissionsJson == this.permissionsJson &&
          other.deviceId == this.deviceId &&
          other.createdAt == this.createdAt &&
          other.lastModified == this.lastModified);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String> role;
  final Value<String> permissionsJson;
  final Value<String> deviceId;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.permissionsJson = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    this.role = const Value.absent(),
    this.permissionsJson = const Value.absent(),
    required String deviceId,
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        name = Value(name),
        deviceId = Value(deviceId);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? permissionsJson,
    Expression<String>? deviceId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (permissionsJson != null) 'permissions_json': permissionsJson,
      if (deviceId != null) 'device_id': deviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? name,
      Value<String>? role,
      Value<String>? permissionsJson,
      Value<String>? deviceId,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      role: role ?? this.role,
      permissionsJson: permissionsJson ?? this.permissionsJson,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (permissionsJson.present) {
      map['permissions_json'] = Variable<String>(permissionsJson.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES households (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _initialBalanceMeta =
      const VerificationMeta('initialBalance');
  @override
  late final GeneratedColumn<double> initialBalance = GeneratedColumn<double>(
      'initial_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        name,
        type,
        currency,
        initialBalance,
        archived,
        deviceId,
        createdAt,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
          _initialBalanceMeta,
          initialBalance.isAcceptableOrUnknown(
              data['initial_balance']!, _initialBalanceMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      initialBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}initial_balance'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String householdId;
  final String name;
  final String type;
  final String currency;
  final double initialBalance;
  final bool archived;
  final String deviceId;
  final DateTime createdAt;
  final DateTime lastModified;
  const Account(
      {required this.id,
      required this.householdId,
      required this.name,
      required this.type,
      required this.currency,
      required this.initialBalance,
      required this.archived,
      required this.deviceId,
      required this.createdAt,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['currency'] = Variable<String>(currency);
    map['initial_balance'] = Variable<double>(initialBalance);
    map['archived'] = Variable<bool>(archived);
    map['device_id'] = Variable<String>(deviceId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      type: Value(type),
      currency: Value(currency),
      initialBalance: Value(initialBalance),
      archived: Value(archived),
      deviceId: Value(deviceId),
      createdAt: Value(createdAt),
      lastModified: Value(lastModified),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      currency: serializer.fromJson<String>(json['currency']),
      initialBalance: serializer.fromJson<double>(json['initialBalance']),
      archived: serializer.fromJson<bool>(json['archived']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'currency': serializer.toJson<String>(currency),
      'initialBalance': serializer.toJson<double>(initialBalance),
      'archived': serializer.toJson<bool>(archived),
      'deviceId': serializer.toJson<String>(deviceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  Account copyWith(
          {String? id,
          String? householdId,
          String? name,
          String? type,
          String? currency,
          double? initialBalance,
          bool? archived,
          String? deviceId,
          DateTime? createdAt,
          DateTime? lastModified}) =>
      Account(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        name: name ?? this.name,
        type: type ?? this.type,
        currency: currency ?? this.currency,
        initialBalance: initialBalance ?? this.initialBalance,
        archived: archived ?? this.archived,
        deviceId: deviceId ?? this.deviceId,
        createdAt: createdAt ?? this.createdAt,
        lastModified: lastModified ?? this.lastModified,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currency: data.currency.present ? data.currency.value : this.currency,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      archived: data.archived.present ? data.archived.value : this.archived,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currency: $currency, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('archived: $archived, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, name, type, currency,
      initialBalance, archived, deviceId, createdAt, lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.type == this.type &&
          other.currency == this.currency &&
          other.initialBalance == this.initialBalance &&
          other.archived == this.archived &&
          other.deviceId == this.deviceId &&
          other.createdAt == this.createdAt &&
          other.lastModified == this.lastModified);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String> type;
  final Value<String> currency;
  final Value<double> initialBalance;
  final Value<bool> archived;
  final Value<String> deviceId;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currency = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.archived = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    required String type,
    required String currency,
    this.initialBalance = const Value.absent(),
    this.archived = const Value.absent(),
    required String deviceId,
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        name = Value(name),
        type = Value(type),
        currency = Value(currency),
        deviceId = Value(deviceId);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? currency,
    Expression<double>? initialBalance,
    Expression<bool>? archived,
    Expression<String>? deviceId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (currency != null) 'currency': currency,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (archived != null) 'archived': archived,
      if (deviceId != null) 'device_id': deviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? name,
      Value<String>? type,
      Value<String>? currency,
      Value<double>? initialBalance,
      Value<bool>? archived,
      Value<String>? deviceId,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return AccountsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      archived: archived ?? this.archived,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<double>(initialBalance.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currency: $currency, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('archived: $archived, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AllocationsTable extends Allocations
    with TableInfo<$AllocationsTable, Allocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AllocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES households (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('spending'));
  static const VerificationMeta _periodicityMeta =
      const VerificationMeta('periodicity');
  @override
  late final GeneratedColumn<String> periodicity = GeneratedColumn<String>(
      'periodicity', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('periodic'));
  static const VerificationMeta _rolloverMeta =
      const VerificationMeta('rollover');
  @override
  late final GeneratedColumn<bool> rollover = GeneratedColumn<bool>(
      'rollover', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("rollover" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _targetAmountMeta =
      const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
      'target_amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _targetCurrencyMeta =
      const VerificationMeta('targetCurrency');
  @override
  late final GeneratedColumn<String> targetCurrency = GeneratedColumn<String>(
      'target_currency', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        name,
        categoryId,
        type,
        periodicity,
        rollover,
        targetAmount,
        targetCurrency,
        archived,
        deviceId,
        createdAt,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'allocations';
  @override
  VerificationContext validateIntegrity(Insertable<Allocation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('periodicity')) {
      context.handle(
          _periodicityMeta,
          periodicity.isAcceptableOrUnknown(
              data['periodicity']!, _periodicityMeta));
    }
    if (data.containsKey('rollover')) {
      context.handle(_rolloverMeta,
          rollover.isAcceptableOrUnknown(data['rollover']!, _rolloverMeta));
    }
    if (data.containsKey('target_amount')) {
      context.handle(
          _targetAmountMeta,
          targetAmount.isAcceptableOrUnknown(
              data['target_amount']!, _targetAmountMeta));
    }
    if (data.containsKey('target_currency')) {
      context.handle(
          _targetCurrencyMeta,
          targetCurrency.isAcceptableOrUnknown(
              data['target_currency']!, _targetCurrencyMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Allocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Allocation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      periodicity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}periodicity'])!,
      rollover: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}rollover'])!,
      targetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_amount']),
      targetCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_currency']),
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $AllocationsTable createAlias(String alias) {
    return $AllocationsTable(attachedDatabase, alias);
  }
}

class Allocation extends DataClass implements Insertable<Allocation> {
  final String id;
  final String householdId;
  final String name;
  final String categoryId;
  final String type;
  final String periodicity;
  final bool rollover;
  final double? targetAmount;
  final String? targetCurrency;
  final bool archived;
  final String deviceId;
  final DateTime createdAt;
  final DateTime lastModified;
  const Allocation(
      {required this.id,
      required this.householdId,
      required this.name,
      required this.categoryId,
      required this.type,
      required this.periodicity,
      required this.rollover,
      this.targetAmount,
      this.targetCurrency,
      required this.archived,
      required this.deviceId,
      required this.createdAt,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['category_id'] = Variable<String>(categoryId);
    map['type'] = Variable<String>(type);
    map['periodicity'] = Variable<String>(periodicity);
    map['rollover'] = Variable<bool>(rollover);
    if (!nullToAbsent || targetAmount != null) {
      map['target_amount'] = Variable<double>(targetAmount);
    }
    if (!nullToAbsent || targetCurrency != null) {
      map['target_currency'] = Variable<String>(targetCurrency);
    }
    map['archived'] = Variable<bool>(archived);
    map['device_id'] = Variable<String>(deviceId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  AllocationsCompanion toCompanion(bool nullToAbsent) {
    return AllocationsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      categoryId: Value(categoryId),
      type: Value(type),
      periodicity: Value(periodicity),
      rollover: Value(rollover),
      targetAmount: targetAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAmount),
      targetCurrency: targetCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCurrency),
      archived: Value(archived),
      deviceId: Value(deviceId),
      createdAt: Value(createdAt),
      lastModified: Value(lastModified),
    );
  }

  factory Allocation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Allocation(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      type: serializer.fromJson<String>(json['type']),
      periodicity: serializer.fromJson<String>(json['periodicity']),
      rollover: serializer.fromJson<bool>(json['rollover']),
      targetAmount: serializer.fromJson<double?>(json['targetAmount']),
      targetCurrency: serializer.fromJson<String?>(json['targetCurrency']),
      archived: serializer.fromJson<bool>(json['archived']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<String>(categoryId),
      'type': serializer.toJson<String>(type),
      'periodicity': serializer.toJson<String>(periodicity),
      'rollover': serializer.toJson<bool>(rollover),
      'targetAmount': serializer.toJson<double?>(targetAmount),
      'targetCurrency': serializer.toJson<String?>(targetCurrency),
      'archived': serializer.toJson<bool>(archived),
      'deviceId': serializer.toJson<String>(deviceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  Allocation copyWith(
          {String? id,
          String? householdId,
          String? name,
          String? categoryId,
          String? type,
          String? periodicity,
          bool? rollover,
          Value<double?> targetAmount = const Value.absent(),
          Value<String?> targetCurrency = const Value.absent(),
          bool? archived,
          String? deviceId,
          DateTime? createdAt,
          DateTime? lastModified}) =>
      Allocation(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        type: type ?? this.type,
        periodicity: periodicity ?? this.periodicity,
        rollover: rollover ?? this.rollover,
        targetAmount:
            targetAmount.present ? targetAmount.value : this.targetAmount,
        targetCurrency:
            targetCurrency.present ? targetCurrency.value : this.targetCurrency,
        archived: archived ?? this.archived,
        deviceId: deviceId ?? this.deviceId,
        createdAt: createdAt ?? this.createdAt,
        lastModified: lastModified ?? this.lastModified,
      );
  Allocation copyWithCompanion(AllocationsCompanion data) {
    return Allocation(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      type: data.type.present ? data.type.value : this.type,
      periodicity:
          data.periodicity.present ? data.periodicity.value : this.periodicity,
      rollover: data.rollover.present ? data.rollover.value : this.rollover,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      targetCurrency: data.targetCurrency.present
          ? data.targetCurrency.value
          : this.targetCurrency,
      archived: data.archived.present ? data.archived.value : this.archived,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Allocation(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('type: $type, ')
          ..write('periodicity: $periodicity, ')
          ..write('rollover: $rollover, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetCurrency: $targetCurrency, ')
          ..write('archived: $archived, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      householdId,
      name,
      categoryId,
      type,
      periodicity,
      rollover,
      targetAmount,
      targetCurrency,
      archived,
      deviceId,
      createdAt,
      lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Allocation &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.type == this.type &&
          other.periodicity == this.periodicity &&
          other.rollover == this.rollover &&
          other.targetAmount == this.targetAmount &&
          other.targetCurrency == this.targetCurrency &&
          other.archived == this.archived &&
          other.deviceId == this.deviceId &&
          other.createdAt == this.createdAt &&
          other.lastModified == this.lastModified);
}

class AllocationsCompanion extends UpdateCompanion<Allocation> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String> categoryId;
  final Value<String> type;
  final Value<String> periodicity;
  final Value<bool> rollover;
  final Value<double?> targetAmount;
  final Value<String?> targetCurrency;
  final Value<bool> archived;
  final Value<String> deviceId;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const AllocationsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.type = const Value.absent(),
    this.periodicity = const Value.absent(),
    this.rollover = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.targetCurrency = const Value.absent(),
    this.archived = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AllocationsCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    required String categoryId,
    this.type = const Value.absent(),
    this.periodicity = const Value.absent(),
    this.rollover = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.targetCurrency = const Value.absent(),
    this.archived = const Value.absent(),
    required String deviceId,
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        name = Value(name),
        categoryId = Value(categoryId),
        deviceId = Value(deviceId);
  static Insertable<Allocation> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? categoryId,
    Expression<String>? type,
    Expression<String>? periodicity,
    Expression<bool>? rollover,
    Expression<double>? targetAmount,
    Expression<String>? targetCurrency,
    Expression<bool>? archived,
    Expression<String>? deviceId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (type != null) 'type': type,
      if (periodicity != null) 'periodicity': periodicity,
      if (rollover != null) 'rollover': rollover,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (targetCurrency != null) 'target_currency': targetCurrency,
      if (archived != null) 'archived': archived,
      if (deviceId != null) 'device_id': deviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AllocationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? name,
      Value<String>? categoryId,
      Value<String>? type,
      Value<String>? periodicity,
      Value<bool>? rollover,
      Value<double?>? targetAmount,
      Value<String?>? targetCurrency,
      Value<bool>? archived,
      Value<String>? deviceId,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return AllocationsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      periodicity: periodicity ?? this.periodicity,
      rollover: rollover ?? this.rollover,
      targetAmount: targetAmount ?? this.targetAmount,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      archived: archived ?? this.archived,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (periodicity.present) {
      map['periodicity'] = Variable<String>(periodicity.value);
    }
    if (rollover.present) {
      map['rollover'] = Variable<bool>(rollover.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (targetCurrency.present) {
      map['target_currency'] = Variable<String>(targetCurrency.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AllocationsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('type: $type, ')
          ..write('periodicity: $periodicity, ')
          ..write('rollover: $rollover, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetCurrency: $targetCurrency, ')
          ..write('archived: $archived, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES households (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transactionTypeMeta =
      const VerificationMeta('transactionType');
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
      'transaction_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('expense'));
  static const VerificationMeta _allocationIdMeta =
      const VerificationMeta('allocationId');
  @override
  late final GeneratedColumn<String> allocationId = GeneratedColumn<String>(
      'allocation_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES allocations (id) ON DELETE SET NULL'));
  static const VerificationMeta _defaultAccountIdMeta =
      const VerificationMeta('defaultAccountId');
  @override
  late final GeneratedColumn<String> defaultAccountId = GeneratedColumn<String>(
      'default_account_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (id) ON DELETE SET NULL'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('category'));
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#607D8B'));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        name,
        parentId,
        transactionType,
        allocationId,
        defaultAccountId,
        icon,
        colorHex,
        archived,
        createdAt,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
          _transactionTypeMeta,
          transactionType.isAcceptableOrUnknown(
              data['transaction_type']!, _transactionTypeMeta));
    }
    if (data.containsKey('allocation_id')) {
      context.handle(
          _allocationIdMeta,
          allocationId.isAcceptableOrUnknown(
              data['allocation_id']!, _allocationIdMeta));
    }
    if (data.containsKey('default_account_id')) {
      context.handle(
          _defaultAccountIdMeta,
          defaultAccountId.isAcceptableOrUnknown(
              data['default_account_id']!, _defaultAccountIdMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      transactionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transaction_type'])!,
      allocationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}allocation_id']),
      defaultAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}default_account_id']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String householdId;
  final String name;
  final String? parentId;
  final String transactionType;

  /// The envelope this category is linked to. Expenses with this category
  /// debit this envelope. Multiple categories can share one envelope.
  final String? allocationId;

  /// Default account for this category.
  final String? defaultAccountId;
  final String icon;
  final String colorHex;
  final bool archived;
  final DateTime createdAt;
  final DateTime lastModified;
  const Category(
      {required this.id,
      required this.householdId,
      required this.name,
      this.parentId,
      required this.transactionType,
      this.allocationId,
      this.defaultAccountId,
      required this.icon,
      required this.colorHex,
      required this.archived,
      required this.createdAt,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['transaction_type'] = Variable<String>(transactionType);
    if (!nullToAbsent || allocationId != null) {
      map['allocation_id'] = Variable<String>(allocationId);
    }
    if (!nullToAbsent || defaultAccountId != null) {
      map['default_account_id'] = Variable<String>(defaultAccountId);
    }
    map['icon'] = Variable<String>(icon);
    map['color_hex'] = Variable<String>(colorHex);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      transactionType: Value(transactionType),
      allocationId: allocationId == null && nullToAbsent
          ? const Value.absent()
          : Value(allocationId),
      defaultAccountId: defaultAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultAccountId),
      icon: Value(icon),
      colorHex: Value(colorHex),
      archived: Value(archived),
      createdAt: Value(createdAt),
      lastModified: Value(lastModified),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      allocationId: serializer.fromJson<String?>(json['allocationId']),
      defaultAccountId: serializer.fromJson<String?>(json['defaultAccountId']),
      icon: serializer.fromJson<String>(json['icon']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'transactionType': serializer.toJson<String>(transactionType),
      'allocationId': serializer.toJson<String?>(allocationId),
      'defaultAccountId': serializer.toJson<String?>(defaultAccountId),
      'icon': serializer.toJson<String>(icon),
      'colorHex': serializer.toJson<String>(colorHex),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  Category copyWith(
          {String? id,
          String? householdId,
          String? name,
          Value<String?> parentId = const Value.absent(),
          String? transactionType,
          Value<String?> allocationId = const Value.absent(),
          Value<String?> defaultAccountId = const Value.absent(),
          String? icon,
          String? colorHex,
          bool? archived,
          DateTime? createdAt,
          DateTime? lastModified}) =>
      Category(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        name: name ?? this.name,
        parentId: parentId.present ? parentId.value : this.parentId,
        transactionType: transactionType ?? this.transactionType,
        allocationId:
            allocationId.present ? allocationId.value : this.allocationId,
        defaultAccountId: defaultAccountId.present
            ? defaultAccountId.value
            : this.defaultAccountId,
        icon: icon ?? this.icon,
        colorHex: colorHex ?? this.colorHex,
        archived: archived ?? this.archived,
        createdAt: createdAt ?? this.createdAt,
        lastModified: lastModified ?? this.lastModified,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      allocationId: data.allocationId.present
          ? data.allocationId.value
          : this.allocationId,
      defaultAccountId: data.defaultAccountId.present
          ? data.defaultAccountId.value
          : this.defaultAccountId,
      icon: data.icon.present ? data.icon.value : this.icon,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('transactionType: $transactionType, ')
          ..write('allocationId: $allocationId, ')
          ..write('defaultAccountId: $defaultAccountId, ')
          ..write('icon: $icon, ')
          ..write('colorHex: $colorHex, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      householdId,
      name,
      parentId,
      transactionType,
      allocationId,
      defaultAccountId,
      icon,
      colorHex,
      archived,
      createdAt,
      lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.transactionType == this.transactionType &&
          other.allocationId == this.allocationId &&
          other.defaultAccountId == this.defaultAccountId &&
          other.icon == this.icon &&
          other.colorHex == this.colorHex &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.lastModified == this.lastModified);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<String> transactionType;
  final Value<String?> allocationId;
  final Value<String?> defaultAccountId;
  final Value<String> icon;
  final Value<String> colorHex;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.allocationId = const Value.absent(),
    this.defaultAccountId = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    this.parentId = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.allocationId = const Value.absent(),
    this.defaultAccountId = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        name = Value(name);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? transactionType,
    Expression<String>? allocationId,
    Expression<String>? defaultAccountId,
    Expression<String>? icon,
    Expression<String>? colorHex,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (transactionType != null) 'transaction_type': transactionType,
      if (allocationId != null) 'allocation_id': allocationId,
      if (defaultAccountId != null) 'default_account_id': defaultAccountId,
      if (icon != null) 'icon': icon,
      if (colorHex != null) 'color_hex': colorHex,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? name,
      Value<String?>? parentId,
      Value<String>? transactionType,
      Value<String?>? allocationId,
      Value<String?>? defaultAccountId,
      Value<String>? icon,
      Value<String>? colorHex,
      Value<bool>? archived,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      transactionType: transactionType ?? this.transactionType,
      allocationId: allocationId ?? this.allocationId,
      defaultAccountId: defaultAccountId ?? this.defaultAccountId,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (allocationId.present) {
      map['allocation_id'] = Variable<String>(allocationId.value);
    }
    if (defaultAccountId.present) {
      map['default_account_id'] = Variable<String>(defaultAccountId.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('transactionType: $transactionType, ')
          ..write('allocationId: $allocationId, ')
          ..write('defaultAccountId: $defaultAccountId, ')
          ..write('icon: $icon, ')
          ..write('colorHex: $colorHex, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES households (id) ON DELETE CASCADE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (id) ON DELETE RESTRICT'));
  static const VerificationMeta _destinationAccountIdMeta =
      const VerificationMeta('destinationAccountId');
  @override
  late final GeneratedColumn<String> destinationAccountId =
      GeneratedColumn<String>(
          'destination_account_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES accounts (id) ON DELETE RESTRICT'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exchangeRateToBaseMeta =
      const VerificationMeta('exchangeRateToBase');
  @override
  late final GeneratedColumn<double> exchangeRateToBase =
      GeneratedColumn<double>('exchange_rate_to_base', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(1.0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _receiptPathMeta =
      const VerificationMeta('receiptPath');
  @override
  late final GeneratedColumn<String> receiptPath = GeneratedColumn<String>(
      'receipt_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        type,
        accountId,
        destinationAccountId,
        categoryId,
        amount,
        currency,
        exchangeRateToBase,
        note,
        receiptPath,
        createdBy,
        deviceId,
        createdAt,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('destination_account_id')) {
      context.handle(
          _destinationAccountIdMeta,
          destinationAccountId.isAcceptableOrUnknown(
              data['destination_account_id']!, _destinationAccountIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('exchange_rate_to_base')) {
      context.handle(
          _exchangeRateToBaseMeta,
          exchangeRateToBase.isAcceptableOrUnknown(
              data['exchange_rate_to_base']!, _exchangeRateToBaseMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('receipt_path')) {
      context.handle(
          _receiptPathMeta,
          receiptPath.isAcceptableOrUnknown(
              data['receipt_path']!, _receiptPathMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      destinationAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}destination_account_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      exchangeRateToBase: attachedDatabase.typeMapping.read(DriftSqlType.double,
          data['${effectivePrefix}exchange_rate_to_base'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      receiptPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_path']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String householdId;
  final String type;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final double amount;
  final String currency;
  final double exchangeRateToBase;
  final String note;

  /// File path to a receipt photo, if attached.
  final String? receiptPath;
  final String createdBy;
  final String deviceId;
  final DateTime createdAt;
  final DateTime lastModified;
  const Transaction(
      {required this.id,
      required this.householdId,
      required this.type,
      required this.accountId,
      this.destinationAccountId,
      this.categoryId,
      required this.amount,
      required this.currency,
      required this.exchangeRateToBase,
      required this.note,
      this.receiptPath,
      required this.createdBy,
      required this.deviceId,
      required this.createdAt,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['type'] = Variable<String>(type);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || destinationAccountId != null) {
      map['destination_account_id'] = Variable<String>(destinationAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['exchange_rate_to_base'] = Variable<double>(exchangeRateToBase);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || receiptPath != null) {
      map['receipt_path'] = Variable<String>(receiptPath);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['device_id'] = Variable<String>(deviceId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      type: Value(type),
      accountId: Value(accountId),
      destinationAccountId: destinationAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amount: Value(amount),
      currency: Value(currency),
      exchangeRateToBase: Value(exchangeRateToBase),
      note: Value(note),
      receiptPath: receiptPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptPath),
      createdBy: Value(createdBy),
      deviceId: Value(deviceId),
      createdAt: Value(createdAt),
      lastModified: Value(lastModified),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      type: serializer.fromJson<String>(json['type']),
      accountId: serializer.fromJson<String>(json['accountId']),
      destinationAccountId:
          serializer.fromJson<String?>(json['destinationAccountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      exchangeRateToBase:
          serializer.fromJson<double>(json['exchangeRateToBase']),
      note: serializer.fromJson<String>(json['note']),
      receiptPath: serializer.fromJson<String?>(json['receiptPath']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'type': serializer.toJson<String>(type),
      'accountId': serializer.toJson<String>(accountId),
      'destinationAccountId': serializer.toJson<String?>(destinationAccountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'exchangeRateToBase': serializer.toJson<double>(exchangeRateToBase),
      'note': serializer.toJson<String>(note),
      'receiptPath': serializer.toJson<String?>(receiptPath),
      'createdBy': serializer.toJson<String>(createdBy),
      'deviceId': serializer.toJson<String>(deviceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  Transaction copyWith(
          {String? id,
          String? householdId,
          String? type,
          String? accountId,
          Value<String?> destinationAccountId = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          double? amount,
          String? currency,
          double? exchangeRateToBase,
          String? note,
          Value<String?> receiptPath = const Value.absent(),
          String? createdBy,
          String? deviceId,
          DateTime? createdAt,
          DateTime? lastModified}) =>
      Transaction(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        type: type ?? this.type,
        accountId: accountId ?? this.accountId,
        destinationAccountId: destinationAccountId.present
            ? destinationAccountId.value
            : this.destinationAccountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
        note: note ?? this.note,
        receiptPath: receiptPath.present ? receiptPath.value : this.receiptPath,
        createdBy: createdBy ?? this.createdBy,
        deviceId: deviceId ?? this.deviceId,
        createdAt: createdAt ?? this.createdAt,
        lastModified: lastModified ?? this.lastModified,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      type: data.type.present ? data.type.value : this.type,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      destinationAccountId: data.destinationAccountId.present
          ? data.destinationAccountId.value
          : this.destinationAccountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      exchangeRateToBase: data.exchangeRateToBase.present
          ? data.exchangeRateToBase.value
          : this.exchangeRateToBase,
      note: data.note.present ? data.note.value : this.note,
      receiptPath:
          data.receiptPath.present ? data.receiptPath.value : this.receiptPath,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('exchangeRateToBase: $exchangeRateToBase, ')
          ..write('note: $note, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('createdBy: $createdBy, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      householdId,
      type,
      accountId,
      destinationAccountId,
      categoryId,
      amount,
      currency,
      exchangeRateToBase,
      note,
      receiptPath,
      createdBy,
      deviceId,
      createdAt,
      lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.type == this.type &&
          other.accountId == this.accountId &&
          other.destinationAccountId == this.destinationAccountId &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.exchangeRateToBase == this.exchangeRateToBase &&
          other.note == this.note &&
          other.receiptPath == this.receiptPath &&
          other.createdBy == this.createdBy &&
          other.deviceId == this.deviceId &&
          other.createdAt == this.createdAt &&
          other.lastModified == this.lastModified);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> type;
  final Value<String> accountId;
  final Value<String?> destinationAccountId;
  final Value<String?> categoryId;
  final Value<double> amount;
  final Value<String> currency;
  final Value<double> exchangeRateToBase;
  final Value<String> note;
  final Value<String?> receiptPath;
  final Value<String> createdBy;
  final Value<String> deviceId;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.type = const Value.absent(),
    this.accountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.exchangeRateToBase = const Value.absent(),
    this.note = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String householdId,
    required String type,
    required String accountId,
    this.destinationAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    required double amount,
    required String currency,
    this.exchangeRateToBase = const Value.absent(),
    this.note = const Value.absent(),
    this.receiptPath = const Value.absent(),
    required String createdBy,
    required String deviceId,
    this.createdAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        type = Value(type),
        accountId = Value(accountId),
        amount = Value(amount),
        currency = Value(currency),
        createdBy = Value(createdBy),
        deviceId = Value(deviceId);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? type,
    Expression<String>? accountId,
    Expression<String>? destinationAccountId,
    Expression<String>? categoryId,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<double>? exchangeRateToBase,
    Expression<String>? note,
    Expression<String>? receiptPath,
    Expression<String>? createdBy,
    Expression<String>? deviceId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (type != null) 'type': type,
      if (accountId != null) 'account_id': accountId,
      if (destinationAccountId != null)
        'destination_account_id': destinationAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (exchangeRateToBase != null)
        'exchange_rate_to_base': exchangeRateToBase,
      if (note != null) 'note': note,
      if (receiptPath != null) 'receipt_path': receiptPath,
      if (createdBy != null) 'created_by': createdBy,
      if (deviceId != null) 'device_id': deviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? type,
      Value<String>? accountId,
      Value<String?>? destinationAccountId,
      Value<String?>? categoryId,
      Value<double>? amount,
      Value<String>? currency,
      Value<double>? exchangeRateToBase,
      Value<String>? note,
      Value<String?>? receiptPath,
      Value<String>? createdBy,
      Value<String>? deviceId,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
      note: note ?? this.note,
      receiptPath: receiptPath ?? this.receiptPath,
      createdBy: createdBy ?? this.createdBy,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (destinationAccountId.present) {
      map['destination_account_id'] =
          Variable<String>(destinationAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (exchangeRateToBase.present) {
      map['exchange_rate_to_base'] = Variable<double>(exchangeRateToBase.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (receiptPath.present) {
      map['receipt_path'] = Variable<String>(receiptPath.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('exchangeRateToBase: $exchangeRateToBase, ')
          ..write('note: $note, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('createdBy: $createdBy, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionLinesTable extends TransactionLines
    with TableInfo<$TransactionLinesTable, TransactionLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES transactions (id) ON DELETE CASCADE'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (id) ON DELETE RESTRICT'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exchangeRateToBaseMeta =
      const VerificationMeta('exchangeRateToBase');
  @override
  late final GeneratedColumn<double> exchangeRateToBase =
      GeneratedColumn<double>('exchange_rate_to_base', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(1.0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        transactionId,
        categoryId,
        accountId,
        amount,
        currency,
        exchangeRateToBase,
        note
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_lines';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionLine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('exchange_rate_to_base')) {
      context.handle(
          _exchangeRateToBaseMeta,
          exchangeRateToBase.isAcceptableOrUnknown(
              data['exchange_rate_to_base']!, _exchangeRateToBaseMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionLine(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      exchangeRateToBase: attachedDatabase.typeMapping.read(DriftSqlType.double,
          data['${effectivePrefix}exchange_rate_to_base'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $TransactionLinesTable createAlias(String alias) {
    return $TransactionLinesTable(attachedDatabase, alias);
  }
}

class TransactionLine extends DataClass implements Insertable<TransactionLine> {
  final String id;
  final String transactionId;
  final String? categoryId;

  /// The account this line draws money from (multi-account support).
  final String? accountId;
  final double amount;
  final String currency;

  /// Rate from this line's currency to household base currency at time of entry.
  final double exchangeRateToBase;
  final String note;
  const TransactionLine(
      {required this.id,
      required this.transactionId,
      this.categoryId,
      this.accountId,
      required this.amount,
      required this.currency,
      required this.exchangeRateToBase,
      required this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['exchange_rate_to_base'] = Variable<double>(exchangeRateToBase);
    map['note'] = Variable<String>(note);
    return map;
  }

  TransactionLinesCompanion toCompanion(bool nullToAbsent) {
    return TransactionLinesCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      amount: Value(amount),
      currency: Value(currency),
      exchangeRateToBase: Value(exchangeRateToBase),
      note: Value(note),
    );
  }

  factory TransactionLine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionLine(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      exchangeRateToBase:
          serializer.fromJson<double>(json['exchangeRateToBase']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String?>(accountId),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'exchangeRateToBase': serializer.toJson<double>(exchangeRateToBase),
      'note': serializer.toJson<String>(note),
    };
  }

  TransactionLine copyWith(
          {String? id,
          String? transactionId,
          Value<String?> categoryId = const Value.absent(),
          Value<String?> accountId = const Value.absent(),
          double? amount,
          String? currency,
          double? exchangeRateToBase,
          String? note}) =>
      TransactionLine(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        accountId: accountId.present ? accountId.value : this.accountId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
        note: note ?? this.note,
      );
  TransactionLine copyWithCompanion(TransactionLinesCompanion data) {
    return TransactionLine(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      exchangeRateToBase: data.exchangeRateToBase.present
          ? data.exchangeRateToBase.value
          : this.exchangeRateToBase,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionLine(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('exchangeRateToBase: $exchangeRateToBase, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionId, categoryId, accountId,
      amount, currency, exchangeRateToBase, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionLine &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.exchangeRateToBase == this.exchangeRateToBase &&
          other.note == this.note);
}

class TransactionLinesCompanion extends UpdateCompanion<TransactionLine> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String?> categoryId;
  final Value<String?> accountId;
  final Value<double> amount;
  final Value<String> currency;
  final Value<double> exchangeRateToBase;
  final Value<String> note;
  final Value<int> rowid;
  const TransactionLinesCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.exchangeRateToBase = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionLinesCompanion.insert({
    required String id,
    required String transactionId,
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    required double amount,
    required String currency,
    this.exchangeRateToBase = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        transactionId = Value(transactionId),
        amount = Value(amount),
        currency = Value(currency);
  static Insertable<TransactionLine> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<double>? exchangeRateToBase,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (exchangeRateToBase != null)
        'exchange_rate_to_base': exchangeRateToBase,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionLinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? transactionId,
      Value<String?>? categoryId,
      Value<String?>? accountId,
      Value<double>? amount,
      Value<String>? currency,
      Value<double>? exchangeRateToBase,
      Value<String>? note,
      Value<int>? rowid}) {
    return TransactionLinesCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (exchangeRateToBase.present) {
      map['exchange_rate_to_base'] = Variable<double>(exchangeRateToBase.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionLinesCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('exchangeRateToBase: $exchangeRateToBase, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AllocationLedgerTable extends AllocationLedger
    with TableInfo<$AllocationLedgerTable, AllocationLedgerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AllocationLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _allocationIdMeta =
      const VerificationMeta('allocationId');
  @override
  late final GeneratedColumn<String> allocationId = GeneratedColumn<String>(
      'allocation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES allocations (id) ON DELETE CASCADE'));
  static const VerificationMeta _sourceTransactionIdMeta =
      const VerificationMeta('sourceTransactionId');
  @override
  late final GeneratedColumn<String> sourceTransactionId =
      GeneratedColumn<String>('source_transaction_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES transactions (id) ON DELETE SET NULL'));
  static const VerificationMeta _sourceAccountIdMeta =
      const VerificationMeta('sourceAccountId');
  @override
  late final GeneratedColumn<String> sourceAccountId = GeneratedColumn<String>(
      'source_account_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (id) ON DELETE SET NULL'));
  static const VerificationMeta _destAccountIdMeta =
      const VerificationMeta('destAccountId');
  @override
  late final GeneratedColumn<String> destAccountId = GeneratedColumn<String>(
      'dest_account_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (id) ON DELETE SET NULL'));
  static const VerificationMeta _entryTypeMeta =
      const VerificationMeta('entryType');
  @override
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
      'entry_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exchangeRateToBaseMeta =
      const VerificationMeta('exchangeRateToBase');
  @override
  late final GeneratedColumn<double> exchangeRateToBase =
      GeneratedColumn<double>('exchange_rate_to_base', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(1.0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        allocationId,
        sourceTransactionId,
        sourceAccountId,
        destAccountId,
        entryType,
        amount,
        currency,
        exchangeRateToBase,
        note,
        createdAt,
        deviceId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'allocation_ledger';
  @override
  VerificationContext validateIntegrity(
      Insertable<AllocationLedgerData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('allocation_id')) {
      context.handle(
          _allocationIdMeta,
          allocationId.isAcceptableOrUnknown(
              data['allocation_id']!, _allocationIdMeta));
    } else if (isInserting) {
      context.missing(_allocationIdMeta);
    }
    if (data.containsKey('source_transaction_id')) {
      context.handle(
          _sourceTransactionIdMeta,
          sourceTransactionId.isAcceptableOrUnknown(
              data['source_transaction_id']!, _sourceTransactionIdMeta));
    }
    if (data.containsKey('source_account_id')) {
      context.handle(
          _sourceAccountIdMeta,
          sourceAccountId.isAcceptableOrUnknown(
              data['source_account_id']!, _sourceAccountIdMeta));
    }
    if (data.containsKey('dest_account_id')) {
      context.handle(
          _destAccountIdMeta,
          destAccountId.isAcceptableOrUnknown(
              data['dest_account_id']!, _destAccountIdMeta));
    }
    if (data.containsKey('entry_type')) {
      context.handle(_entryTypeMeta,
          entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta));
    } else if (isInserting) {
      context.missing(_entryTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('exchange_rate_to_base')) {
      context.handle(
          _exchangeRateToBaseMeta,
          exchangeRateToBase.isAcceptableOrUnknown(
              data['exchange_rate_to_base']!, _exchangeRateToBaseMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AllocationLedgerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AllocationLedgerData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      allocationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}allocation_id'])!,
      sourceTransactionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_transaction_id']),
      sourceAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_account_id']),
      destAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dest_account_id']),
      entryType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      exchangeRateToBase: attachedDatabase.typeMapping.read(DriftSqlType.double,
          data['${effectivePrefix}exchange_rate_to_base'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
    );
  }

  @override
  $AllocationLedgerTable createAlias(String alias) {
    return $AllocationLedgerTable(attachedDatabase, alias);
  }
}

class AllocationLedgerData extends DataClass
    implements Insertable<AllocationLedgerData> {
  final String id;
  final String allocationId;
  final String? sourceTransactionId;
  final String? sourceAccountId;
  final String? destAccountId;
  final String entryType;
  final double amount;
  final String currency;
  final double exchangeRateToBase;
  final String note;
  final DateTime createdAt;
  final String deviceId;
  const AllocationLedgerData(
      {required this.id,
      required this.allocationId,
      this.sourceTransactionId,
      this.sourceAccountId,
      this.destAccountId,
      required this.entryType,
      required this.amount,
      required this.currency,
      required this.exchangeRateToBase,
      required this.note,
      required this.createdAt,
      required this.deviceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['allocation_id'] = Variable<String>(allocationId);
    if (!nullToAbsent || sourceTransactionId != null) {
      map['source_transaction_id'] = Variable<String>(sourceTransactionId);
    }
    if (!nullToAbsent || sourceAccountId != null) {
      map['source_account_id'] = Variable<String>(sourceAccountId);
    }
    if (!nullToAbsent || destAccountId != null) {
      map['dest_account_id'] = Variable<String>(destAccountId);
    }
    map['entry_type'] = Variable<String>(entryType);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['exchange_rate_to_base'] = Variable<double>(exchangeRateToBase);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  AllocationLedgerCompanion toCompanion(bool nullToAbsent) {
    return AllocationLedgerCompanion(
      id: Value(id),
      allocationId: Value(allocationId),
      sourceTransactionId: sourceTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceTransactionId),
      sourceAccountId: sourceAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceAccountId),
      destAccountId: destAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(destAccountId),
      entryType: Value(entryType),
      amount: Value(amount),
      currency: Value(currency),
      exchangeRateToBase: Value(exchangeRateToBase),
      note: Value(note),
      createdAt: Value(createdAt),
      deviceId: Value(deviceId),
    );
  }

  factory AllocationLedgerData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AllocationLedgerData(
      id: serializer.fromJson<String>(json['id']),
      allocationId: serializer.fromJson<String>(json['allocationId']),
      sourceTransactionId:
          serializer.fromJson<String?>(json['sourceTransactionId']),
      sourceAccountId: serializer.fromJson<String?>(json['sourceAccountId']),
      destAccountId: serializer.fromJson<String?>(json['destAccountId']),
      entryType: serializer.fromJson<String>(json['entryType']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      exchangeRateToBase:
          serializer.fromJson<double>(json['exchangeRateToBase']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'allocationId': serializer.toJson<String>(allocationId),
      'sourceTransactionId': serializer.toJson<String?>(sourceTransactionId),
      'sourceAccountId': serializer.toJson<String?>(sourceAccountId),
      'destAccountId': serializer.toJson<String?>(destAccountId),
      'entryType': serializer.toJson<String>(entryType),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'exchangeRateToBase': serializer.toJson<double>(exchangeRateToBase),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  AllocationLedgerData copyWith(
          {String? id,
          String? allocationId,
          Value<String?> sourceTransactionId = const Value.absent(),
          Value<String?> sourceAccountId = const Value.absent(),
          Value<String?> destAccountId = const Value.absent(),
          String? entryType,
          double? amount,
          String? currency,
          double? exchangeRateToBase,
          String? note,
          DateTime? createdAt,
          String? deviceId}) =>
      AllocationLedgerData(
        id: id ?? this.id,
        allocationId: allocationId ?? this.allocationId,
        sourceTransactionId: sourceTransactionId.present
            ? sourceTransactionId.value
            : this.sourceTransactionId,
        sourceAccountId: sourceAccountId.present
            ? sourceAccountId.value
            : this.sourceAccountId,
        destAccountId:
            destAccountId.present ? destAccountId.value : this.destAccountId,
        entryType: entryType ?? this.entryType,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        deviceId: deviceId ?? this.deviceId,
      );
  AllocationLedgerData copyWithCompanion(AllocationLedgerCompanion data) {
    return AllocationLedgerData(
      id: data.id.present ? data.id.value : this.id,
      allocationId: data.allocationId.present
          ? data.allocationId.value
          : this.allocationId,
      sourceTransactionId: data.sourceTransactionId.present
          ? data.sourceTransactionId.value
          : this.sourceTransactionId,
      sourceAccountId: data.sourceAccountId.present
          ? data.sourceAccountId.value
          : this.sourceAccountId,
      destAccountId: data.destAccountId.present
          ? data.destAccountId.value
          : this.destAccountId,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      exchangeRateToBase: data.exchangeRateToBase.present
          ? data.exchangeRateToBase.value
          : this.exchangeRateToBase,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AllocationLedgerData(')
          ..write('id: $id, ')
          ..write('allocationId: $allocationId, ')
          ..write('sourceTransactionId: $sourceTransactionId, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destAccountId: $destAccountId, ')
          ..write('entryType: $entryType, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('exchangeRateToBase: $exchangeRateToBase, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      allocationId,
      sourceTransactionId,
      sourceAccountId,
      destAccountId,
      entryType,
      amount,
      currency,
      exchangeRateToBase,
      note,
      createdAt,
      deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllocationLedgerData &&
          other.id == this.id &&
          other.allocationId == this.allocationId &&
          other.sourceTransactionId == this.sourceTransactionId &&
          other.sourceAccountId == this.sourceAccountId &&
          other.destAccountId == this.destAccountId &&
          other.entryType == this.entryType &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.exchangeRateToBase == this.exchangeRateToBase &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.deviceId == this.deviceId);
}

class AllocationLedgerCompanion extends UpdateCompanion<AllocationLedgerData> {
  final Value<String> id;
  final Value<String> allocationId;
  final Value<String?> sourceTransactionId;
  final Value<String?> sourceAccountId;
  final Value<String?> destAccountId;
  final Value<String> entryType;
  final Value<double> amount;
  final Value<String> currency;
  final Value<double> exchangeRateToBase;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const AllocationLedgerCompanion({
    this.id = const Value.absent(),
    this.allocationId = const Value.absent(),
    this.sourceTransactionId = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destAccountId = const Value.absent(),
    this.entryType = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.exchangeRateToBase = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AllocationLedgerCompanion.insert({
    required String id,
    required String allocationId,
    this.sourceTransactionId = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destAccountId = const Value.absent(),
    required String entryType,
    required double amount,
    required String currency,
    this.exchangeRateToBase = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        allocationId = Value(allocationId),
        entryType = Value(entryType),
        amount = Value(amount),
        currency = Value(currency),
        deviceId = Value(deviceId);
  static Insertable<AllocationLedgerData> custom({
    Expression<String>? id,
    Expression<String>? allocationId,
    Expression<String>? sourceTransactionId,
    Expression<String>? sourceAccountId,
    Expression<String>? destAccountId,
    Expression<String>? entryType,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<double>? exchangeRateToBase,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (allocationId != null) 'allocation_id': allocationId,
      if (sourceTransactionId != null)
        'source_transaction_id': sourceTransactionId,
      if (sourceAccountId != null) 'source_account_id': sourceAccountId,
      if (destAccountId != null) 'dest_account_id': destAccountId,
      if (entryType != null) 'entry_type': entryType,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (exchangeRateToBase != null)
        'exchange_rate_to_base': exchangeRateToBase,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AllocationLedgerCompanion copyWith(
      {Value<String>? id,
      Value<String>? allocationId,
      Value<String?>? sourceTransactionId,
      Value<String?>? sourceAccountId,
      Value<String?>? destAccountId,
      Value<String>? entryType,
      Value<double>? amount,
      Value<String>? currency,
      Value<double>? exchangeRateToBase,
      Value<String>? note,
      Value<DateTime>? createdAt,
      Value<String>? deviceId,
      Value<int>? rowid}) {
    return AllocationLedgerCompanion(
      id: id ?? this.id,
      allocationId: allocationId ?? this.allocationId,
      sourceTransactionId: sourceTransactionId ?? this.sourceTransactionId,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destAccountId: destAccountId ?? this.destAccountId,
      entryType: entryType ?? this.entryType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (allocationId.present) {
      map['allocation_id'] = Variable<String>(allocationId.value);
    }
    if (sourceTransactionId.present) {
      map['source_transaction_id'] =
          Variable<String>(sourceTransactionId.value);
    }
    if (sourceAccountId.present) {
      map['source_account_id'] = Variable<String>(sourceAccountId.value);
    }
    if (destAccountId.present) {
      map['dest_account_id'] = Variable<String>(destAccountId.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (exchangeRateToBase.present) {
      map['exchange_rate_to_base'] = Variable<double>(exchangeRateToBase.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AllocationLedgerCompanion(')
          ..write('id: $id, ')
          ..write('allocationId: $allocationId, ')
          ..write('sourceTransactionId: $sourceTransactionId, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destAccountId: $destAccountId, ')
          ..write('entryType: $entryType, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('exchangeRateToBase: $exchangeRateToBase, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FxRatesTable extends FxRates with TableInfo<$FxRatesTable, FxRate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FxRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromCurrencyMeta =
      const VerificationMeta('fromCurrency');
  @override
  late final GeneratedColumn<String> fromCurrency = GeneratedColumn<String>(
      'from_currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toCurrencyMeta =
      const VerificationMeta('toCurrency');
  @override
  late final GeneratedColumn<String> toCurrency = GeneratedColumn<String>(
      'to_currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
      'rate', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('api'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, fromCurrency, toCurrency, rate, fetchedAt, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fx_rates';
  @override
  VerificationContext validateIntegrity(Insertable<FxRate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('from_currency')) {
      context.handle(
          _fromCurrencyMeta,
          fromCurrency.isAcceptableOrUnknown(
              data['from_currency']!, _fromCurrencyMeta));
    } else if (isInserting) {
      context.missing(_fromCurrencyMeta);
    }
    if (data.containsKey('to_currency')) {
      context.handle(
          _toCurrencyMeta,
          toCurrency.isAcceptableOrUnknown(
              data['to_currency']!, _toCurrencyMeta));
    } else if (isInserting) {
      context.missing(_toCurrencyMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
          _rateMeta, rate.isAcceptableOrUnknown(data['rate']!, _rateMeta));
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FxRate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FxRate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fromCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_currency'])!,
      toCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_currency'])!,
      rate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
    );
  }

  @override
  $FxRatesTable createAlias(String alias) {
    return $FxRatesTable(attachedDatabase, alias);
  }
}

class FxRate extends DataClass implements Insertable<FxRate> {
  final String id;
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime fetchedAt;
  final String source;
  const FxRate(
      {required this.id,
      required this.fromCurrency,
      required this.toCurrency,
      required this.rate,
      required this.fetchedAt,
      required this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['from_currency'] = Variable<String>(fromCurrency);
    map['to_currency'] = Variable<String>(toCurrency);
    map['rate'] = Variable<double>(rate);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['source'] = Variable<String>(source);
    return map;
  }

  FxRatesCompanion toCompanion(bool nullToAbsent) {
    return FxRatesCompanion(
      id: Value(id),
      fromCurrency: Value(fromCurrency),
      toCurrency: Value(toCurrency),
      rate: Value(rate),
      fetchedAt: Value(fetchedAt),
      source: Value(source),
    );
  }

  factory FxRate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FxRate(
      id: serializer.fromJson<String>(json['id']),
      fromCurrency: serializer.fromJson<String>(json['fromCurrency']),
      toCurrency: serializer.fromJson<String>(json['toCurrency']),
      rate: serializer.fromJson<double>(json['rate']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fromCurrency': serializer.toJson<String>(fromCurrency),
      'toCurrency': serializer.toJson<String>(toCurrency),
      'rate': serializer.toJson<double>(rate),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'source': serializer.toJson<String>(source),
    };
  }

  FxRate copyWith(
          {String? id,
          String? fromCurrency,
          String? toCurrency,
          double? rate,
          DateTime? fetchedAt,
          String? source}) =>
      FxRate(
        id: id ?? this.id,
        fromCurrency: fromCurrency ?? this.fromCurrency,
        toCurrency: toCurrency ?? this.toCurrency,
        rate: rate ?? this.rate,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        source: source ?? this.source,
      );
  FxRate copyWithCompanion(FxRatesCompanion data) {
    return FxRate(
      id: data.id.present ? data.id.value : this.id,
      fromCurrency: data.fromCurrency.present
          ? data.fromCurrency.value
          : this.fromCurrency,
      toCurrency:
          data.toCurrency.present ? data.toCurrency.value : this.toCurrency,
      rate: data.rate.present ? data.rate.value : this.rate,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FxRate(')
          ..write('id: $id, ')
          ..write('fromCurrency: $fromCurrency, ')
          ..write('toCurrency: $toCurrency, ')
          ..write('rate: $rate, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fromCurrency, toCurrency, rate, fetchedAt, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FxRate &&
          other.id == this.id &&
          other.fromCurrency == this.fromCurrency &&
          other.toCurrency == this.toCurrency &&
          other.rate == this.rate &&
          other.fetchedAt == this.fetchedAt &&
          other.source == this.source);
}

class FxRatesCompanion extends UpdateCompanion<FxRate> {
  final Value<String> id;
  final Value<String> fromCurrency;
  final Value<String> toCurrency;
  final Value<double> rate;
  final Value<DateTime> fetchedAt;
  final Value<String> source;
  final Value<int> rowid;
  const FxRatesCompanion({
    this.id = const Value.absent(),
    this.fromCurrency = const Value.absent(),
    this.toCurrency = const Value.absent(),
    this.rate = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FxRatesCompanion.insert({
    required String id,
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    this.fetchedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fromCurrency = Value(fromCurrency),
        toCurrency = Value(toCurrency),
        rate = Value(rate);
  static Insertable<FxRate> custom({
    Expression<String>? id,
    Expression<String>? fromCurrency,
    Expression<String>? toCurrency,
    Expression<double>? rate,
    Expression<DateTime>? fetchedAt,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromCurrency != null) 'from_currency': fromCurrency,
      if (toCurrency != null) 'to_currency': toCurrency,
      if (rate != null) 'rate': rate,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FxRatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? fromCurrency,
      Value<String>? toCurrency,
      Value<double>? rate,
      Value<DateTime>? fetchedAt,
      Value<String>? source,
      Value<int>? rowid}) {
    return FxRatesCompanion(
      id: id ?? this.id,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      rate: rate ?? this.rate,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fromCurrency.present) {
      map['from_currency'] = Variable<String>(fromCurrency.value);
    }
    if (toCurrency.present) {
      map['to_currency'] = Variable<String>(toCurrency.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FxRatesCompanion(')
          ..write('id: $id, ')
          ..write('fromCurrency: $fromCurrency, ')
          ..write('toCurrency: $toCurrency, ')
          ..write('rate: $rate, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringTransactionsTable extends RecurringTransactions
    with TableInfo<$RecurringTransactionsTable, RecurringTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES households (id) ON DELETE CASCADE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (id) ON DELETE RESTRICT'));
  static const VerificationMeta _destinationAccountIdMeta =
      const VerificationMeta('destinationAccountId');
  @override
  late final GeneratedColumn<String> destinationAccountId =
      GeneratedColumn<String>(
          'destination_account_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES accounts (id) ON DELETE RESTRICT'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _intervalMeta =
      const VerificationMeta('interval');
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
      'interval', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _nextDueDateMeta =
      const VerificationMeta('nextDueDate');
  @override
  late final GeneratedColumn<DateTime> nextDueDate = GeneratedColumn<DateTime>(
      'next_due_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastGeneratedDateMeta =
      const VerificationMeta('lastGeneratedDate');
  @override
  late final GeneratedColumn<DateTime> lastGeneratedDate =
      GeneratedColumn<DateTime>('last_generated_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        type,
        title,
        amount,
        currency,
        accountId,
        destinationAccountId,
        categoryId,
        note,
        frequency,
        interval,
        nextDueDate,
        lastGeneratedDate,
        endDate,
        enabled,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_transactions';
  @override
  VerificationContext validateIntegrity(
      Insertable<RecurringTransaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('destination_account_id')) {
      context.handle(
          _destinationAccountIdMeta,
          destinationAccountId.isAcceptableOrUnknown(
              data['destination_account_id']!, _destinationAccountIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('interval')) {
      context.handle(_intervalMeta,
          interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta));
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
          _nextDueDateMeta,
          nextDueDate.isAcceptableOrUnknown(
              data['next_due_date']!, _nextDueDateMeta));
    } else if (isInserting) {
      context.missing(_nextDueDateMeta);
    }
    if (data.containsKey('last_generated_date')) {
      context.handle(
          _lastGeneratedDateMeta,
          lastGeneratedDate.isAcceptableOrUnknown(
              data['last_generated_date']!, _lastGeneratedDateMeta));
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringTransaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      destinationAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}destination_account_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      interval: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval'])!,
      nextDueDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_due_date'])!,
      lastGeneratedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_generated_date']),
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RecurringTransactionsTable createAlias(String alias) {
    return $RecurringTransactionsTable(attachedDatabase, alias);
  }
}

class RecurringTransaction extends DataClass
    implements Insertable<RecurringTransaction> {
  final String id;
  final String householdId;
  final String type;
  final String title;
  final double amount;
  final String currency;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final String note;

  /// Frequency: 'daily' | 'weekly' | 'monthly' | 'yearly'
  final String frequency;

  /// The interval multiplier (e.g. every 2 weeks → frequency='weekly', interval=2)
  final int interval;

  /// Next date this recurring transaction is due.
  final DateTime nextDueDate;

  /// Last date a transaction was generated from this template.
  final DateTime? lastGeneratedDate;

  /// End date: stop generating after this date. Null = forever.
  final DateTime? endDate;

  /// Whether auto-generation is active.
  final bool enabled;
  final DateTime createdAt;
  const RecurringTransaction(
      {required this.id,
      required this.householdId,
      required this.type,
      required this.title,
      required this.amount,
      required this.currency,
      required this.accountId,
      this.destinationAccountId,
      this.categoryId,
      required this.note,
      required this.frequency,
      required this.interval,
      required this.nextDueDate,
      this.lastGeneratedDate,
      this.endDate,
      required this.enabled,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || destinationAccountId != null) {
      map['destination_account_id'] = Variable<String>(destinationAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['note'] = Variable<String>(note);
    map['frequency'] = Variable<String>(frequency);
    map['interval'] = Variable<int>(interval);
    map['next_due_date'] = Variable<DateTime>(nextDueDate);
    if (!nullToAbsent || lastGeneratedDate != null) {
      map['last_generated_date'] = Variable<DateTime>(lastGeneratedDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RecurringTransactionsCompanion toCompanion(bool nullToAbsent) {
    return RecurringTransactionsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      type: Value(type),
      title: Value(title),
      amount: Value(amount),
      currency: Value(currency),
      accountId: Value(accountId),
      destinationAccountId: destinationAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      note: Value(note),
      frequency: Value(frequency),
      interval: Value(interval),
      nextDueDate: Value(nextDueDate),
      lastGeneratedDate: lastGeneratedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastGeneratedDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
    );
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringTransaction(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      accountId: serializer.fromJson<String>(json['accountId']),
      destinationAccountId:
          serializer.fromJson<String?>(json['destinationAccountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      note: serializer.fromJson<String>(json['note']),
      frequency: serializer.fromJson<String>(json['frequency']),
      interval: serializer.fromJson<int>(json['interval']),
      nextDueDate: serializer.fromJson<DateTime>(json['nextDueDate']),
      lastGeneratedDate:
          serializer.fromJson<DateTime?>(json['lastGeneratedDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'accountId': serializer.toJson<String>(accountId),
      'destinationAccountId': serializer.toJson<String?>(destinationAccountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'note': serializer.toJson<String>(note),
      'frequency': serializer.toJson<String>(frequency),
      'interval': serializer.toJson<int>(interval),
      'nextDueDate': serializer.toJson<DateTime>(nextDueDate),
      'lastGeneratedDate': serializer.toJson<DateTime?>(lastGeneratedDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RecurringTransaction copyWith(
          {String? id,
          String? householdId,
          String? type,
          String? title,
          double? amount,
          String? currency,
          String? accountId,
          Value<String?> destinationAccountId = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          String? note,
          String? frequency,
          int? interval,
          DateTime? nextDueDate,
          Value<DateTime?> lastGeneratedDate = const Value.absent(),
          Value<DateTime?> endDate = const Value.absent(),
          bool? enabled,
          DateTime? createdAt}) =>
      RecurringTransaction(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        type: type ?? this.type,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        accountId: accountId ?? this.accountId,
        destinationAccountId: destinationAccountId.present
            ? destinationAccountId.value
            : this.destinationAccountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        note: note ?? this.note,
        frequency: frequency ?? this.frequency,
        interval: interval ?? this.interval,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        lastGeneratedDate: lastGeneratedDate.present
            ? lastGeneratedDate.value
            : this.lastGeneratedDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt ?? this.createdAt,
      );
  RecurringTransaction copyWithCompanion(RecurringTransactionsCompanion data) {
    return RecurringTransaction(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      destinationAccountId: data.destinationAccountId.present
          ? data.destinationAccountId.value
          : this.destinationAccountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      note: data.note.present ? data.note.value : this.note,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      interval: data.interval.present ? data.interval.value : this.interval,
      nextDueDate:
          data.nextDueDate.present ? data.nextDueDate.value : this.nextDueDate,
      lastGeneratedDate: data.lastGeneratedDate.present
          ? data.lastGeneratedDate.value
          : this.lastGeneratedDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTransaction(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('accountId: $accountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('frequency: $frequency, ')
          ..write('interval: $interval, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('lastGeneratedDate: $lastGeneratedDate, ')
          ..write('endDate: $endDate, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      householdId,
      type,
      title,
      amount,
      currency,
      accountId,
      destinationAccountId,
      categoryId,
      note,
      frequency,
      interval,
      nextDueDate,
      lastGeneratedDate,
      endDate,
      enabled,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringTransaction &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.type == this.type &&
          other.title == this.title &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.accountId == this.accountId &&
          other.destinationAccountId == this.destinationAccountId &&
          other.categoryId == this.categoryId &&
          other.note == this.note &&
          other.frequency == this.frequency &&
          other.interval == this.interval &&
          other.nextDueDate == this.nextDueDate &&
          other.lastGeneratedDate == this.lastGeneratedDate &&
          other.endDate == this.endDate &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt);
}

class RecurringTransactionsCompanion
    extends UpdateCompanion<RecurringTransaction> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> type;
  final Value<String> title;
  final Value<double> amount;
  final Value<String> currency;
  final Value<String> accountId;
  final Value<String?> destinationAccountId;
  final Value<String?> categoryId;
  final Value<String> note;
  final Value<String> frequency;
  final Value<int> interval;
  final Value<DateTime> nextDueDate;
  final Value<DateTime?> lastGeneratedDate;
  final Value<DateTime?> endDate;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RecurringTransactionsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.accountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    this.frequency = const Value.absent(),
    this.interval = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.lastGeneratedDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringTransactionsCompanion.insert({
    required String id,
    required String householdId,
    required String type,
    this.title = const Value.absent(),
    required double amount,
    required String currency,
    required String accountId,
    this.destinationAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    required String frequency,
    this.interval = const Value.absent(),
    required DateTime nextDueDate,
    this.lastGeneratedDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        type = Value(type),
        amount = Value(amount),
        currency = Value(currency),
        accountId = Value(accountId),
        frequency = Value(frequency),
        nextDueDate = Value(nextDueDate);
  static Insertable<RecurringTransaction> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? accountId,
    Expression<String>? destinationAccountId,
    Expression<String>? categoryId,
    Expression<String>? note,
    Expression<String>? frequency,
    Expression<int>? interval,
    Expression<DateTime>? nextDueDate,
    Expression<DateTime>? lastGeneratedDate,
    Expression<DateTime>? endDate,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (accountId != null) 'account_id': accountId,
      if (destinationAccountId != null)
        'destination_account_id': destinationAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (note != null) 'note': note,
      if (frequency != null) 'frequency': frequency,
      if (interval != null) 'interval': interval,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (lastGeneratedDate != null) 'last_generated_date': lastGeneratedDate,
      if (endDate != null) 'end_date': endDate,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringTransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? type,
      Value<String>? title,
      Value<double>? amount,
      Value<String>? currency,
      Value<String>? accountId,
      Value<String?>? destinationAccountId,
      Value<String?>? categoryId,
      Value<String>? note,
      Value<String>? frequency,
      Value<int>? interval,
      Value<DateTime>? nextDueDate,
      Value<DateTime?>? lastGeneratedDate,
      Value<DateTime?>? endDate,
      Value<bool>? enabled,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return RecurringTransactionsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      endDate: endDate ?? this.endDate,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (destinationAccountId.present) {
      map['destination_account_id'] =
          Variable<String>(destinationAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate.value);
    }
    if (lastGeneratedDate.present) {
      map['last_generated_date'] = Variable<DateTime>(lastGeneratedDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('accountId: $accountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('frequency: $frequency, ')
          ..write('interval: $interval, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('lastGeneratedDate: $lastGeneratedDate, ')
          ..write('endDate: $endDate, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionTemplatesTable extends TransactionTemplates
    with TableInfo<$TransactionTemplatesTable, TransactionTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES households (id) ON DELETE CASCADE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (id) ON DELETE SET NULL'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _useCountMeta =
      const VerificationMeta('useCount');
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
      'use_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        title,
        type,
        amount,
        currency,
        accountId,
        categoryId,
        useCount,
        lastUsedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_templates';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransactionTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('use_count')) {
      context.handle(_useCountMeta,
          useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta));
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      useCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}use_count'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TransactionTemplatesTable createAlias(String alias) {
    return $TransactionTemplatesTable(attachedDatabase, alias);
  }
}

class TransactionTemplate extends DataClass
    implements Insertable<TransactionTemplate> {
  final String id;
  final String householdId;
  final String title;
  final String type;
  final double amount;
  final String currency;
  final String? accountId;
  final String? categoryId;
  final int useCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  const TransactionTemplate(
      {required this.id,
      required this.householdId,
      required this.title,
      required this.type,
      required this.amount,
      required this.currency,
      this.accountId,
      this.categoryId,
      required this.useCount,
      this.lastUsedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['use_count'] = Variable<int>(useCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionTemplatesCompanion toCompanion(bool nullToAbsent) {
    return TransactionTemplatesCompanion(
      id: Value(id),
      householdId: Value(householdId),
      title: Value(title),
      type: Value(type),
      amount: Value(amount),
      currency: Value(currency),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      useCount: Value(useCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      createdAt: Value(createdAt),
    );
  }

  factory TransactionTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionTemplate(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'accountId': serializer.toJson<String?>(accountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransactionTemplate copyWith(
          {String? id,
          String? householdId,
          String? title,
          String? type,
          double? amount,
          String? currency,
          Value<String?> accountId = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          int? useCount,
          Value<DateTime?> lastUsedAt = const Value.absent(),
          DateTime? createdAt}) =>
      TransactionTemplate(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        title: title ?? this.title,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        accountId: accountId.present ? accountId.value : this.accountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        useCount: useCount ?? this.useCount,
        lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  TransactionTemplate copyWithCompanion(TransactionTemplatesCompanion data) {
    return TransactionTemplate(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionTemplate(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, title, type, amount,
      currency, accountId, categoryId, useCount, lastUsedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionTemplate &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.title == this.title &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.createdAt == this.createdAt);
}

class TransactionTemplatesCompanion
    extends UpdateCompanion<TransactionTemplate> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> title;
  final Value<String> type;
  final Value<double> amount;
  final Value<String> currency;
  final Value<String?> accountId;
  final Value<String?> categoryId;
  final Value<int> useCount;
  final Value<DateTime?> lastUsedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransactionTemplatesCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionTemplatesCompanion.insert({
    required String id,
    required String householdId,
    required String title,
    required String type,
    required double amount,
    required String currency,
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        title = Value(title),
        type = Value(type),
        amount = Value(amount),
        currency = Value(currency);
  static Insertable<TransactionTemplate> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? title,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<int>? useCount,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionTemplatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? title,
      Value<String>? type,
      Value<double>? amount,
      Value<String>? currency,
      Value<String?>? accountId,
      Value<String?>? categoryId,
      Value<int>? useCount,
      Value<DateTime?>? lastUsedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TransactionTemplatesCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HouseholdsTable households = $HouseholdsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $AllocationsTable allocations = $AllocationsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $TransactionLinesTable transactionLines =
      $TransactionLinesTable(this);
  late final $AllocationLedgerTable allocationLedger =
      $AllocationLedgerTable(this);
  late final $FxRatesTable fxRates = $FxRatesTable(this);
  late final $RecurringTransactionsTable recurringTransactions =
      $RecurringTransactionsTable(this);
  late final $TransactionTemplatesTable transactionTemplates =
      $TransactionTemplatesTable(this);
  late final AccountsDao accountsDao = AccountsDao(this as AppDatabase);
  late final TransactionsDao transactionsDao =
      TransactionsDao(this as AppDatabase);
  late final AllocationsDao allocationsDao =
      AllocationsDao(this as AppDatabase);
  late final LedgerDao ledgerDao = LedgerDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        households,
        users,
        accounts,
        allocations,
        categories,
        transactions,
        transactionLines,
        allocationLedger,
        fxRates,
        recurringTransactions,
        transactionTemplates
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('households',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('users', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('households',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('accounts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('households',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('allocations', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('households',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('categories', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('allocations',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('categories', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('accounts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('categories', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('households',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transactions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transactions', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('transactions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transaction_lines', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transaction_lines', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('allocations',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('allocation_ledger', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('transactions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('allocation_ledger', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('accounts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('allocation_ledger', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('accounts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('allocation_ledger', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('households',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recurring_transactions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recurring_transactions', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('households',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transaction_templates', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('accounts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transaction_templates', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transaction_templates', kind: UpdateKind.update),
            ],
          ),
        ],
      );
}

typedef $$HouseholdsTableCreateCompanionBuilder = HouseholdsCompanion Function({
  required String id,
  required String name,
  Value<String> baseCurrency,
  Value<int> periodStartDay,
  Value<bool> autoPromptPeriod,
  Value<bool> allowSkipPeriod,
  required String createdByDeviceId,
  Value<String> settingsJson,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});
typedef $$HouseholdsTableUpdateCompanionBuilder = HouseholdsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> baseCurrency,
  Value<int> periodStartDay,
  Value<bool> autoPromptPeriod,
  Value<bool> allowSkipPeriod,
  Value<String> createdByDeviceId,
  Value<String> settingsJson,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

final class $$HouseholdsTableReferences
    extends BaseReferences<_$AppDatabase, $HouseholdsTable, Household> {
  $$HouseholdsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UsersTable, List<User>> _usersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.users,
          aliasName:
              $_aliasNameGenerator(db.households.id, db.users.householdId));

  $$UsersTableProcessedTableManager get usersRefs {
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_usersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AccountsTable, List<Account>> _accountsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.accounts,
          aliasName:
              $_aliasNameGenerator(db.households.id, db.accounts.householdId));

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AllocationsTable, List<Allocation>>
      _allocationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.allocations,
              aliasName: $_aliasNameGenerator(
                  db.households.id, db.allocations.householdId));

  $$AllocationsTableProcessedTableManager get allocationsRefs {
    final manager = $$AllocationsTableTableManager($_db, $_db.allocations)
        .filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_allocationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CategoriesTable, List<Category>>
      _categoriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.categories,
              aliasName: $_aliasNameGenerator(
                  db.households.id, db.categories.householdId));

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.households.id, db.transactions.householdId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecurringTransactionsTable,
      List<RecurringTransaction>> _recurringTransactionsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.recurringTransactions,
          aliasName: $_aliasNameGenerator(
              db.households.id, db.recurringTransactions.householdId));

  $$RecurringTransactionsTableProcessedTableManager
      get recurringTransactionsRefs {
    final manager = $$RecurringTransactionsTableTableManager(
            $_db, $_db.recurringTransactions)
        .filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_recurringTransactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionTemplatesTable,
      List<TransactionTemplate>> _transactionTemplatesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactionTemplates,
          aliasName: $_aliasNameGenerator(
              db.households.id, db.transactionTemplates.householdId));

  $$TransactionTemplatesTableProcessedTableManager
      get transactionTemplatesRefs {
    final manager = $$TransactionTemplatesTableTableManager(
            $_db, $_db.transactionTemplates)
        .filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_transactionTemplatesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$HouseholdsTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseCurrency => $composableBuilder(
      column: $table.baseCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get periodStartDay => $composableBuilder(
      column: $table.periodStartDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoPromptPeriod => $composableBuilder(
      column: $table.autoPromptPeriod,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allowSkipPeriod => $composableBuilder(
      column: $table.allowSkipPeriod,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdByDeviceId => $composableBuilder(
      column: $table.createdByDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get settingsJson => $composableBuilder(
      column: $table.settingsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  Expression<bool> usersRefs(
      Expression<bool> Function($$UsersTableFilterComposer f) f) {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> accountsRefs(
      Expression<bool> Function($$AccountsTableFilterComposer f) f) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> allocationsRefs(
      Expression<bool> Function($$AllocationsTableFilterComposer f) f) {
    final $$AllocationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.allocations,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationsTableFilterComposer(
              $db: $db,
              $table: $db.allocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> categoriesRefs(
      Expression<bool> Function($$CategoriesTableFilterComposer f) f) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recurringTransactionsRefs(
      Expression<bool> Function($$RecurringTransactionsTableFilterComposer f)
          f) {
    final $$RecurringTransactionsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recurringTransactions,
            getReferencedColumn: (t) => t.householdId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurringTransactionsTableFilterComposer(
                  $db: $db,
                  $table: $db.recurringTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> transactionTemplatesRefs(
      Expression<bool> Function($$TransactionTemplatesTableFilterComposer f)
          f) {
    final $$TransactionTemplatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionTemplates,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionTemplatesTableFilterComposer(
              $db: $db,
              $table: $db.transactionTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$HouseholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseCurrency => $composableBuilder(
      column: $table.baseCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get periodStartDay => $composableBuilder(
      column: $table.periodStartDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoPromptPeriod => $composableBuilder(
      column: $table.autoPromptPeriod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allowSkipPeriod => $composableBuilder(
      column: $table.allowSkipPeriod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdByDeviceId => $composableBuilder(
      column: $table.createdByDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get settingsJson => $composableBuilder(
      column: $table.settingsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));
}

class $$HouseholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get baseCurrency => $composableBuilder(
      column: $table.baseCurrency, builder: (column) => column);

  GeneratedColumn<int> get periodStartDay => $composableBuilder(
      column: $table.periodStartDay, builder: (column) => column);

  GeneratedColumn<bool> get autoPromptPeriod => $composableBuilder(
      column: $table.autoPromptPeriod, builder: (column) => column);

  GeneratedColumn<bool> get allowSkipPeriod => $composableBuilder(
      column: $table.allowSkipPeriod, builder: (column) => column);

  GeneratedColumn<String> get createdByDeviceId => $composableBuilder(
      column: $table.createdByDeviceId, builder: (column) => column);

  GeneratedColumn<String> get settingsJson => $composableBuilder(
      column: $table.settingsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  Expression<T> usersRefs<T extends Object>(
      Expression<T> Function($$UsersTableAnnotationComposer a) f) {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> accountsRefs<T extends Object>(
      Expression<T> Function($$AccountsTableAnnotationComposer a) f) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> allocationsRefs<T extends Object>(
      Expression<T> Function($$AllocationsTableAnnotationComposer a) f) {
    final $$AllocationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.allocations,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationsTableAnnotationComposer(
              $db: $db,
              $table: $db.allocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> categoriesRefs<T extends Object>(
      Expression<T> Function($$CategoriesTableAnnotationComposer a) f) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.householdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recurringTransactionsRefs<T extends Object>(
      Expression<T> Function($$RecurringTransactionsTableAnnotationComposer a)
          f) {
    final $$RecurringTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recurringTransactions,
            getReferencedColumn: (t) => t.householdId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurringTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recurringTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> transactionTemplatesRefs<T extends Object>(
      Expression<T> Function($$TransactionTemplatesTableAnnotationComposer a)
          f) {
    final $$TransactionTemplatesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.transactionTemplates,
            getReferencedColumn: (t) => t.householdId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TransactionTemplatesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.transactionTemplates,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$HouseholdsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HouseholdsTable,
    Household,
    $$HouseholdsTableFilterComposer,
    $$HouseholdsTableOrderingComposer,
    $$HouseholdsTableAnnotationComposer,
    $$HouseholdsTableCreateCompanionBuilder,
    $$HouseholdsTableUpdateCompanionBuilder,
    (Household, $$HouseholdsTableReferences),
    Household,
    PrefetchHooks Function(
        {bool usersRefs,
        bool accountsRefs,
        bool allocationsRefs,
        bool categoriesRefs,
        bool transactionsRefs,
        bool recurringTransactionsRefs,
        bool transactionTemplatesRefs})> {
  $$HouseholdsTableTableManager(_$AppDatabase db, $HouseholdsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> baseCurrency = const Value.absent(),
            Value<int> periodStartDay = const Value.absent(),
            Value<bool> autoPromptPeriod = const Value.absent(),
            Value<bool> allowSkipPeriod = const Value.absent(),
            Value<String> createdByDeviceId = const Value.absent(),
            Value<String> settingsJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HouseholdsCompanion(
            id: id,
            name: name,
            baseCurrency: baseCurrency,
            periodStartDay: periodStartDay,
            autoPromptPeriod: autoPromptPeriod,
            allowSkipPeriod: allowSkipPeriod,
            createdByDeviceId: createdByDeviceId,
            settingsJson: settingsJson,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> baseCurrency = const Value.absent(),
            Value<int> periodStartDay = const Value.absent(),
            Value<bool> autoPromptPeriod = const Value.absent(),
            Value<bool> allowSkipPeriod = const Value.absent(),
            required String createdByDeviceId,
            Value<String> settingsJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HouseholdsCompanion.insert(
            id: id,
            name: name,
            baseCurrency: baseCurrency,
            periodStartDay: periodStartDay,
            autoPromptPeriod: autoPromptPeriod,
            allowSkipPeriod: allowSkipPeriod,
            createdByDeviceId: createdByDeviceId,
            settingsJson: settingsJson,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$HouseholdsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {usersRefs = false,
              accountsRefs = false,
              allocationsRefs = false,
              categoriesRefs = false,
              transactionsRefs = false,
              recurringTransactionsRefs = false,
              transactionTemplatesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (usersRefs) db.users,
                if (accountsRefs) db.accounts,
                if (allocationsRefs) db.allocations,
                if (categoriesRefs) db.categories,
                if (transactionsRefs) db.transactions,
                if (recurringTransactionsRefs) db.recurringTransactions,
                if (transactionTemplatesRefs) db.transactionTemplates
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (usersRefs)
                    await $_getPrefetchedData<Household, $HouseholdsTable,
                            User>(
                        currentTable: table,
                        referencedTable:
                            $$HouseholdsTableReferences._usersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HouseholdsTableReferences(db, table, p0)
                                .usersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.householdId == item.id),
                        typedResults: items),
                  if (accountsRefs)
                    await $_getPrefetchedData<Household, $HouseholdsTable,
                            Account>(
                        currentTable: table,
                        referencedTable:
                            $$HouseholdsTableReferences._accountsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HouseholdsTableReferences(db, table, p0)
                                .accountsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.householdId == item.id),
                        typedResults: items),
                  if (allocationsRefs)
                    await $_getPrefetchedData<Household, $HouseholdsTable,
                            Allocation>(
                        currentTable: table,
                        referencedTable: $$HouseholdsTableReferences
                            ._allocationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HouseholdsTableReferences(db, table, p0)
                                .allocationsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.householdId == item.id),
                        typedResults: items),
                  if (categoriesRefs)
                    await $_getPrefetchedData<Household, $HouseholdsTable,
                            Category>(
                        currentTable: table,
                        referencedTable: $$HouseholdsTableReferences
                            ._categoriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HouseholdsTableReferences(db, table, p0)
                                .categoriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.householdId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData<Household, $HouseholdsTable,
                            Transaction>(
                        currentTable: table,
                        referencedTable: $$HouseholdsTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HouseholdsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.householdId == item.id),
                        typedResults: items),
                  if (recurringTransactionsRefs)
                    await $_getPrefetchedData<Household, $HouseholdsTable, RecurringTransaction>(
                        currentTable: table,
                        referencedTable: $$HouseholdsTableReferences
                            ._recurringTransactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HouseholdsTableReferences(db, table, p0)
                                .recurringTransactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.householdId == item.id),
                        typedResults: items),
                  if (transactionTemplatesRefs)
                    await $_getPrefetchedData<Household, $HouseholdsTable,
                            TransactionTemplate>(
                        currentTable: table,
                        referencedTable: $$HouseholdsTableReferences
                            ._transactionTemplatesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HouseholdsTableReferences(db, table, p0)
                                .transactionTemplatesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.householdId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$HouseholdsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HouseholdsTable,
    Household,
    $$HouseholdsTableFilterComposer,
    $$HouseholdsTableOrderingComposer,
    $$HouseholdsTableAnnotationComposer,
    $$HouseholdsTableCreateCompanionBuilder,
    $$HouseholdsTableUpdateCompanionBuilder,
    (Household, $$HouseholdsTableReferences),
    Household,
    PrefetchHooks Function(
        {bool usersRefs,
        bool accountsRefs,
        bool allocationsRefs,
        bool categoriesRefs,
        bool transactionsRefs,
        bool recurringTransactionsRefs,
        bool transactionTemplatesRefs})>;
typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String householdId,
  required String name,
  Value<String> role,
  Value<String> permissionsJson,
  required String deviceId,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> name,
  Value<String> role,
  Value<String> permissionsJson,
  Value<String> deviceId,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
          $_aliasNameGenerator(db.users.householdId, db.households.id));

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager($_db, $_db.households)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get permissionsJson => $composableBuilder(
      column: $table.permissionsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableFilterComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get permissionsJson => $composableBuilder(
      column: $table.permissionsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableOrderingComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get permissionsJson => $composableBuilder(
      column: $table.permissionsJson, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableAnnotationComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function({bool householdId})> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> permissionsJson = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            householdId: householdId,
            name: name,
            role: role,
            permissionsJson: permissionsJson,
            deviceId: deviceId,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String name,
            Value<String> role = const Value.absent(),
            Value<String> permissionsJson = const Value.absent(),
            required String deviceId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            householdId: householdId,
            name: name,
            role: role,
            permissionsJson: permissionsJson,
            deviceId: deviceId,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UsersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({householdId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (householdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.householdId,
                    referencedTable:
                        $$UsersTableReferences._householdIdTable(db),
                    referencedColumn:
                        $$UsersTableReferences._householdIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function({bool householdId})>;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String householdId,
  required String name,
  required String type,
  required String currency,
  Value<double> initialBalance,
  Value<bool> archived,
  required String deviceId,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> name,
  Value<String> type,
  Value<String> currency,
  Value<double> initialBalance,
  Value<bool> archived,
  Value<String> deviceId,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
          $_aliasNameGenerator(db.accounts.householdId, db.households.id));

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager($_db, $_db.households)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$CategoriesTable, List<Category>>
      _categoriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.categories,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.categories.defaultAccountId));

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter(
        (f) => f.defaultAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _sourceTransactionsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.transactions.accountId));

  $$TransactionsTableProcessedTableManager get sourceTransactions {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sourceTransactionsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _destinationTransactionsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.transactions.destinationAccountId));

  $$TransactionsTableProcessedTableManager get destinationTransactions {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) =>
            f.destinationAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_destinationTransactionsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionLinesTable, List<TransactionLine>>
      _transactionLinesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactionLines,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.transactionLines.accountId));

  $$TransactionLinesTableProcessedTableManager get transactionLinesRefs {
    final manager = $$TransactionLinesTableTableManager(
            $_db, $_db.transactionLines)
        .filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_transactionLinesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AllocationLedgerTable, List<AllocationLedgerData>>
      _sourceLedgerEntriesTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.allocationLedger,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.allocationLedger.sourceAccountId));

  $$AllocationLedgerTableProcessedTableManager get sourceLedgerEntries {
    final manager =
        $$AllocationLedgerTableTableManager($_db, $_db.allocationLedger).filter(
            (f) => f.sourceAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_sourceLedgerEntriesTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AllocationLedgerTable, List<AllocationLedgerData>>
      _destLedgerEntriesTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.allocationLedger,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.allocationLedger.destAccountId));

  $$AllocationLedgerTableProcessedTableManager get destLedgerEntries {
    final manager =
        $$AllocationLedgerTableTableManager($_db, $_db.allocationLedger).filter(
            (f) => f.destAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_destLedgerEntriesTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecurringTransactionsTable,
      List<RecurringTransaction>> _recurringSourceAccountTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.recurringTransactions,
          aliasName: $_aliasNameGenerator(
              db.accounts.id, db.recurringTransactions.accountId));

  $$RecurringTransactionsTableProcessedTableManager get recurringSourceAccount {
    final manager = $$RecurringTransactionsTableTableManager(
            $_db, $_db.recurringTransactions)
        .filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_recurringSourceAccountTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecurringTransactionsTable,
      List<RecurringTransaction>> _recurringDestAccountTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.recurringTransactions,
          aliasName: $_aliasNameGenerator(
              db.accounts.id, db.recurringTransactions.destinationAccountId));

  $$RecurringTransactionsTableProcessedTableManager get recurringDestAccount {
    final manager = $$RecurringTransactionsTableTableManager(
            $_db, $_db.recurringTransactions)
        .filter((f) =>
            f.destinationAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_recurringDestAccountTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionTemplatesTable,
      List<TransactionTemplate>> _templateAccountTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactionTemplates,
          aliasName: $_aliasNameGenerator(
              db.accounts.id, db.transactionTemplates.accountId));

  $$TransactionTemplatesTableProcessedTableManager get templateAccount {
    final manager = $$TransactionTemplatesTableTableManager(
            $_db, $_db.transactionTemplates)
        .filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateAccountTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableFilterComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> categoriesRefs(
      Expression<bool> Function($$CategoriesTableFilterComposer f) f) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.defaultAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> sourceTransactions(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> destinationTransactions(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.destinationAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionLinesRefs(
      Expression<bool> Function($$TransactionLinesTableFilterComposer f) f) {
    final $$TransactionLinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionLines,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionLinesTableFilterComposer(
              $db: $db,
              $table: $db.transactionLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> sourceLedgerEntries(
      Expression<bool> Function($$AllocationLedgerTableFilterComposer f) f) {
    final $$AllocationLedgerTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.allocationLedger,
        getReferencedColumn: (t) => t.sourceAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationLedgerTableFilterComposer(
              $db: $db,
              $table: $db.allocationLedger,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> destLedgerEntries(
      Expression<bool> Function($$AllocationLedgerTableFilterComposer f) f) {
    final $$AllocationLedgerTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.allocationLedger,
        getReferencedColumn: (t) => t.destAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationLedgerTableFilterComposer(
              $db: $db,
              $table: $db.allocationLedger,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recurringSourceAccount(
      Expression<bool> Function($$RecurringTransactionsTableFilterComposer f)
          f) {
    final $$RecurringTransactionsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recurringTransactions,
            getReferencedColumn: (t) => t.accountId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurringTransactionsTableFilterComposer(
                  $db: $db,
                  $table: $db.recurringTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> recurringDestAccount(
      Expression<bool> Function($$RecurringTransactionsTableFilterComposer f)
          f) {
    final $$RecurringTransactionsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recurringTransactions,
            getReferencedColumn: (t) => t.destinationAccountId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurringTransactionsTableFilterComposer(
                  $db: $db,
                  $table: $db.recurringTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> templateAccount(
      Expression<bool> Function($$TransactionTemplatesTableFilterComposer f)
          f) {
    final $$TransactionTemplatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionTemplates,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionTemplatesTableFilterComposer(
              $db: $db,
              $table: $db.transactionTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableOrderingComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableAnnotationComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> categoriesRefs<T extends Object>(
      Expression<T> Function($$CategoriesTableAnnotationComposer a) f) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.defaultAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> sourceTransactions<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> destinationTransactions<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.destinationAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionLinesRefs<T extends Object>(
      Expression<T> Function($$TransactionLinesTableAnnotationComposer a) f) {
    final $$TransactionLinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionLines,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionLinesTableAnnotationComposer(
              $db: $db,
              $table: $db.transactionLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> sourceLedgerEntries<T extends Object>(
      Expression<T> Function($$AllocationLedgerTableAnnotationComposer a) f) {
    final $$AllocationLedgerTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.allocationLedger,
        getReferencedColumn: (t) => t.sourceAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationLedgerTableAnnotationComposer(
              $db: $db,
              $table: $db.allocationLedger,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> destLedgerEntries<T extends Object>(
      Expression<T> Function($$AllocationLedgerTableAnnotationComposer a) f) {
    final $$AllocationLedgerTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.allocationLedger,
        getReferencedColumn: (t) => t.destAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationLedgerTableAnnotationComposer(
              $db: $db,
              $table: $db.allocationLedger,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recurringSourceAccount<T extends Object>(
      Expression<T> Function($$RecurringTransactionsTableAnnotationComposer a)
          f) {
    final $$RecurringTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recurringTransactions,
            getReferencedColumn: (t) => t.accountId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurringTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recurringTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> recurringDestAccount<T extends Object>(
      Expression<T> Function($$RecurringTransactionsTableAnnotationComposer a)
          f) {
    final $$RecurringTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recurringTransactions,
            getReferencedColumn: (t) => t.destinationAccountId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurringTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recurringTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> templateAccount<T extends Object>(
      Expression<T> Function($$TransactionTemplatesTableAnnotationComposer a)
          f) {
    final $$TransactionTemplatesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.transactionTemplates,
            getReferencedColumn: (t) => t.accountId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TransactionTemplatesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.transactionTemplates,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function(
        {bool householdId,
        bool categoriesRefs,
        bool sourceTransactions,
        bool destinationTransactions,
        bool transactionLinesRefs,
        bool sourceLedgerEntries,
        bool destLedgerEntries,
        bool recurringSourceAccount,
        bool recurringDestAccount,
        bool templateAccount})> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double> initialBalance = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            householdId: householdId,
            name: name,
            type: type,
            currency: currency,
            initialBalance: initialBalance,
            archived: archived,
            deviceId: deviceId,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String name,
            required String type,
            required String currency,
            Value<double> initialBalance = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            required String deviceId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            householdId: householdId,
            name: name,
            type: type,
            currency: currency,
            initialBalance: initialBalance,
            archived: archived,
            deviceId: deviceId,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {householdId = false,
              categoriesRefs = false,
              sourceTransactions = false,
              destinationTransactions = false,
              transactionLinesRefs = false,
              sourceLedgerEntries = false,
              destLedgerEntries = false,
              recurringSourceAccount = false,
              recurringDestAccount = false,
              templateAccount = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (categoriesRefs) db.categories,
                if (sourceTransactions) db.transactions,
                if (destinationTransactions) db.transactions,
                if (transactionLinesRefs) db.transactionLines,
                if (sourceLedgerEntries) db.allocationLedger,
                if (destLedgerEntries) db.allocationLedger,
                if (recurringSourceAccount) db.recurringTransactions,
                if (recurringDestAccount) db.recurringTransactions,
                if (templateAccount) db.transactionTemplates
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (householdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.householdId,
                    referencedTable:
                        $$AccountsTableReferences._householdIdTable(db),
                    referencedColumn:
                        $$AccountsTableReferences._householdIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (categoriesRefs)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            Category>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._categoriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .categoriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.defaultAccountId == item.id),
                        typedResults: items),
                  if (sourceTransactions)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            Transaction>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._sourceTransactionsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .sourceTransactions,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items),
                  if (destinationTransactions)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            Transaction>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._destinationTransactionsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .destinationTransactions,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.destinationAccountId == item.id),
                        typedResults: items),
                  if (transactionLinesRefs)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            TransactionLine>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._transactionLinesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .transactionLinesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items),
                  if (sourceLedgerEntries)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            AllocationLedgerData>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._sourceLedgerEntriesTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .sourceLedgerEntries,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourceAccountId == item.id),
                        typedResults: items),
                  if (destLedgerEntries)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            AllocationLedgerData>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._destLedgerEntriesTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .destLedgerEntries,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.destAccountId == item.id),
                        typedResults: items),
                  if (recurringSourceAccount)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            RecurringTransaction>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._recurringSourceAccountTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .recurringSourceAccount,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items),
                  if (recurringDestAccount)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            RecurringTransaction>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._recurringDestAccountTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .recurringDestAccount,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.destinationAccountId == item.id),
                        typedResults: items),
                  if (templateAccount)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            TransactionTemplate>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._templateAccountTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .templateAccount,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function(
        {bool householdId,
        bool categoriesRefs,
        bool sourceTransactions,
        bool destinationTransactions,
        bool transactionLinesRefs,
        bool sourceLedgerEntries,
        bool destLedgerEntries,
        bool recurringSourceAccount,
        bool recurringDestAccount,
        bool templateAccount})>;
typedef $$AllocationsTableCreateCompanionBuilder = AllocationsCompanion
    Function({
  required String id,
  required String householdId,
  required String name,
  required String categoryId,
  Value<String> type,
  Value<String> periodicity,
  Value<bool> rollover,
  Value<double?> targetAmount,
  Value<String?> targetCurrency,
  Value<bool> archived,
  required String deviceId,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});
typedef $$AllocationsTableUpdateCompanionBuilder = AllocationsCompanion
    Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> name,
  Value<String> categoryId,
  Value<String> type,
  Value<String> periodicity,
  Value<bool> rollover,
  Value<double?> targetAmount,
  Value<String?> targetCurrency,
  Value<bool> archived,
  Value<String> deviceId,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

final class $$AllocationsTableReferences
    extends BaseReferences<_$AppDatabase, $AllocationsTable, Allocation> {
  $$AllocationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
          $_aliasNameGenerator(db.allocations.householdId, db.households.id));

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager($_db, $_db.households)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$CategoriesTable, List<Category>>
      _categoryAllocationsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.categories,
              aliasName: $_aliasNameGenerator(
                  db.allocations.id, db.categories.allocationId));

  $$CategoriesTableProcessedTableManager get categoryAllocations {
    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter(
        (f) => f.allocationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_categoryAllocationsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AllocationLedgerTable, List<AllocationLedgerData>>
      _allocationLedgerRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.allocationLedger,
              aliasName: $_aliasNameGenerator(
                  db.allocations.id, db.allocationLedger.allocationId));

  $$AllocationLedgerTableProcessedTableManager get allocationLedgerRefs {
    final manager =
        $$AllocationLedgerTableTableManager($_db, $_db.allocationLedger).filter(
            (f) => f.allocationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_allocationLedgerRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AllocationsTableFilterComposer
    extends Composer<_$AppDatabase, $AllocationsTable> {
  $$AllocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get periodicity => $composableBuilder(
      column: $table.periodicity, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get rollover => $composableBuilder(
      column: $table.rollover, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetCurrency => $composableBuilder(
      column: $table.targetCurrency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableFilterComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> categoryAllocations(
      Expression<bool> Function($$CategoriesTableFilterComposer f) f) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.allocationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> allocationLedgerRefs(
      Expression<bool> Function($$AllocationLedgerTableFilterComposer f) f) {
    final $$AllocationLedgerTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.allocationLedger,
        getReferencedColumn: (t) => t.allocationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationLedgerTableFilterComposer(
              $db: $db,
              $table: $db.allocationLedger,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AllocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AllocationsTable> {
  $$AllocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get periodicity => $composableBuilder(
      column: $table.periodicity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get rollover => $composableBuilder(
      column: $table.rollover, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetCurrency => $composableBuilder(
      column: $table.targetCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableOrderingComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AllocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AllocationsTable> {
  $$AllocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get periodicity => $composableBuilder(
      column: $table.periodicity, builder: (column) => column);

  GeneratedColumn<bool> get rollover =>
      $composableBuilder(column: $table.rollover, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => column);

  GeneratedColumn<String> get targetCurrency => $composableBuilder(
      column: $table.targetCurrency, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableAnnotationComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> categoryAllocations<T extends Object>(
      Expression<T> Function($$CategoriesTableAnnotationComposer a) f) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.allocationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> allocationLedgerRefs<T extends Object>(
      Expression<T> Function($$AllocationLedgerTableAnnotationComposer a) f) {
    final $$AllocationLedgerTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.allocationLedger,
        getReferencedColumn: (t) => t.allocationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationLedgerTableAnnotationComposer(
              $db: $db,
              $table: $db.allocationLedger,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AllocationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AllocationsTable,
    Allocation,
    $$AllocationsTableFilterComposer,
    $$AllocationsTableOrderingComposer,
    $$AllocationsTableAnnotationComposer,
    $$AllocationsTableCreateCompanionBuilder,
    $$AllocationsTableUpdateCompanionBuilder,
    (Allocation, $$AllocationsTableReferences),
    Allocation,
    PrefetchHooks Function(
        {bool householdId,
        bool categoryAllocations,
        bool allocationLedgerRefs})> {
  $$AllocationsTableTableManager(_$AppDatabase db, $AllocationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AllocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AllocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AllocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> periodicity = const Value.absent(),
            Value<bool> rollover = const Value.absent(),
            Value<double?> targetAmount = const Value.absent(),
            Value<String?> targetCurrency = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AllocationsCompanion(
            id: id,
            householdId: householdId,
            name: name,
            categoryId: categoryId,
            type: type,
            periodicity: periodicity,
            rollover: rollover,
            targetAmount: targetAmount,
            targetCurrency: targetCurrency,
            archived: archived,
            deviceId: deviceId,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String name,
            required String categoryId,
            Value<String> type = const Value.absent(),
            Value<String> periodicity = const Value.absent(),
            Value<bool> rollover = const Value.absent(),
            Value<double?> targetAmount = const Value.absent(),
            Value<String?> targetCurrency = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            required String deviceId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AllocationsCompanion.insert(
            id: id,
            householdId: householdId,
            name: name,
            categoryId: categoryId,
            type: type,
            periodicity: periodicity,
            rollover: rollover,
            targetAmount: targetAmount,
            targetCurrency: targetCurrency,
            archived: archived,
            deviceId: deviceId,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AllocationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {householdId = false,
              categoryAllocations = false,
              allocationLedgerRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (categoryAllocations) db.categories,
                if (allocationLedgerRefs) db.allocationLedger
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (householdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.householdId,
                    referencedTable:
                        $$AllocationsTableReferences._householdIdTable(db),
                    referencedColumn:
                        $$AllocationsTableReferences._householdIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (categoryAllocations)
                    await $_getPrefetchedData<Allocation, $AllocationsTable,
                            Category>(
                        currentTable: table,
                        referencedTable: $$AllocationsTableReferences
                            ._categoryAllocationsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AllocationsTableReferences(db, table, p0)
                                .categoryAllocations,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.allocationId == item.id),
                        typedResults: items),
                  if (allocationLedgerRefs)
                    await $_getPrefetchedData<Allocation, $AllocationsTable,
                            AllocationLedgerData>(
                        currentTable: table,
                        referencedTable: $$AllocationsTableReferences
                            ._allocationLedgerRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AllocationsTableReferences(db, table, p0)
                                .allocationLedgerRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.allocationId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AllocationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AllocationsTable,
    Allocation,
    $$AllocationsTableFilterComposer,
    $$AllocationsTableOrderingComposer,
    $$AllocationsTableAnnotationComposer,
    $$AllocationsTableCreateCompanionBuilder,
    $$AllocationsTableUpdateCompanionBuilder,
    (Allocation, $$AllocationsTableReferences),
    Allocation,
    PrefetchHooks Function(
        {bool householdId,
        bool categoryAllocations,
        bool allocationLedgerRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String householdId,
  required String name,
  Value<String?> parentId,
  Value<String> transactionType,
  Value<String?> allocationId,
  Value<String?> defaultAccountId,
  Value<String> icon,
  Value<String> colorHex,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> name,
  Value<String?> parentId,
  Value<String> transactionType,
  Value<String?> allocationId,
  Value<String?> defaultAccountId,
  Value<String> icon,
  Value<String> colorHex,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
          $_aliasNameGenerator(db.categories.householdId, db.households.id));

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager($_db, $_db.households)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AllocationsTable _allocationIdTable(_$AppDatabase db) =>
      db.allocations.createAlias(
          $_aliasNameGenerator(db.categories.allocationId, db.allocations.id));

  $$AllocationsTableProcessedTableManager? get allocationId {
    final $_column = $_itemColumn<String>('allocation_id');
    if ($_column == null) return null;
    final manager = $$AllocationsTableTableManager($_db, $_db.allocations)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_allocationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _defaultAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.categories.defaultAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get defaultAccountId {
    final $_column = $_itemColumn<String>('default_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_defaultAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.categories.id, db.transactions.categoryId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionLinesTable, List<TransactionLine>>
      _transactionLinesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactionLines,
              aliasName: $_aliasNameGenerator(
                  db.categories.id, db.transactionLines.categoryId));

  $$TransactionLinesTableProcessedTableManager get transactionLinesRefs {
    final manager = $$TransactionLinesTableTableManager(
            $_db, $_db.transactionLines)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_transactionLinesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecurringTransactionsTable,
      List<RecurringTransaction>> _recurringTransactionsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.recurringTransactions,
          aliasName: $_aliasNameGenerator(
              db.categories.id, db.recurringTransactions.categoryId));

  $$RecurringTransactionsTableProcessedTableManager
      get recurringTransactionsRefs {
    final manager = $$RecurringTransactionsTableTableManager(
            $_db, $_db.recurringTransactions)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_recurringTransactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionTemplatesTable,
      List<TransactionTemplate>> _transactionTemplatesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactionTemplates,
          aliasName: $_aliasNameGenerator(
              db.categories.id, db.transactionTemplates.categoryId));

  $$TransactionTemplatesTableProcessedTableManager
      get transactionTemplatesRefs {
    final manager = $$TransactionTemplatesTableTableManager(
            $_db, $_db.transactionTemplates)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_transactionTemplatesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableFilterComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AllocationsTableFilterComposer get allocationId {
    final $$AllocationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.allocationId,
        referencedTable: $db.allocations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationsTableFilterComposer(
              $db: $db,
              $table: $db.allocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get defaultAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.defaultAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionLinesRefs(
      Expression<bool> Function($$TransactionLinesTableFilterComposer f) f) {
    final $$TransactionLinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionLines,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionLinesTableFilterComposer(
              $db: $db,
              $table: $db.transactionLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recurringTransactionsRefs(
      Expression<bool> Function($$RecurringTransactionsTableFilterComposer f)
          f) {
    final $$RecurringTransactionsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recurringTransactions,
            getReferencedColumn: (t) => t.categoryId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurringTransactionsTableFilterComposer(
                  $db: $db,
                  $table: $db.recurringTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> transactionTemplatesRefs(
      Expression<bool> Function($$TransactionTemplatesTableFilterComposer f)
          f) {
    final $$TransactionTemplatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionTemplates,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionTemplatesTableFilterComposer(
              $db: $db,
              $table: $db.transactionTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableOrderingComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AllocationsTableOrderingComposer get allocationId {
    final $$AllocationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.allocationId,
        referencedTable: $db.allocations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationsTableOrderingComposer(
              $db: $db,
              $table: $db.allocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get defaultAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.defaultAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
      column: $table.transactionType, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableAnnotationComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AllocationsTableAnnotationComposer get allocationId {
    final $$AllocationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.allocationId,
        referencedTable: $db.allocations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationsTableAnnotationComposer(
              $db: $db,
              $table: $db.allocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get defaultAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.defaultAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionLinesRefs<T extends Object>(
      Expression<T> Function($$TransactionLinesTableAnnotationComposer a) f) {
    final $$TransactionLinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionLines,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionLinesTableAnnotationComposer(
              $db: $db,
              $table: $db.transactionLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recurringTransactionsRefs<T extends Object>(
      Expression<T> Function($$RecurringTransactionsTableAnnotationComposer a)
          f) {
    final $$RecurringTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recurringTransactions,
            getReferencedColumn: (t) => t.categoryId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurringTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recurringTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> transactionTemplatesRefs<T extends Object>(
      Expression<T> Function($$TransactionTemplatesTableAnnotationComposer a)
          f) {
    final $$TransactionTemplatesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.transactionTemplates,
            getReferencedColumn: (t) => t.categoryId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TransactionTemplatesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.transactionTemplates,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function(
        {bool householdId,
        bool allocationId,
        bool defaultAccountId,
        bool transactionsRefs,
        bool transactionLinesRefs,
        bool recurringTransactionsRefs,
        bool transactionTemplatesRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String> transactionType = const Value.absent(),
            Value<String?> allocationId = const Value.absent(),
            Value<String?> defaultAccountId = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            householdId: householdId,
            name: name,
            parentId: parentId,
            transactionType: transactionType,
            allocationId: allocationId,
            defaultAccountId: defaultAccountId,
            icon: icon,
            colorHex: colorHex,
            archived: archived,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String name,
            Value<String?> parentId = const Value.absent(),
            Value<String> transactionType = const Value.absent(),
            Value<String?> allocationId = const Value.absent(),
            Value<String?> defaultAccountId = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            householdId: householdId,
            name: name,
            parentId: parentId,
            transactionType: transactionType,
            allocationId: allocationId,
            defaultAccountId: defaultAccountId,
            icon: icon,
            colorHex: colorHex,
            archived: archived,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {householdId = false,
              allocationId = false,
              defaultAccountId = false,
              transactionsRefs = false,
              transactionLinesRefs = false,
              recurringTransactionsRefs = false,
              transactionTemplatesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionsRefs) db.transactions,
                if (transactionLinesRefs) db.transactionLines,
                if (recurringTransactionsRefs) db.recurringTransactions,
                if (transactionTemplatesRefs) db.transactionTemplates
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (householdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.householdId,
                    referencedTable:
                        $$CategoriesTableReferences._householdIdTable(db),
                    referencedColumn:
                        $$CategoriesTableReferences._householdIdTable(db).id,
                  ) as T;
                }
                if (allocationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.allocationId,
                    referencedTable:
                        $$CategoriesTableReferences._allocationIdTable(db),
                    referencedColumn:
                        $$CategoriesTableReferences._allocationIdTable(db).id,
                  ) as T;
                }
                if (defaultAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.defaultAccountId,
                    referencedTable:
                        $$CategoriesTableReferences._defaultAccountIdTable(db),
                    referencedColumn: $$CategoriesTableReferences
                        ._defaultAccountIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            Transaction>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (transactionLinesRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            TransactionLine>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._transactionLinesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .transactionLinesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (recurringTransactionsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            RecurringTransaction>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._recurringTransactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .recurringTransactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (transactionTemplatesRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            TransactionTemplate>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._transactionTemplatesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .transactionTemplatesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function(
        {bool householdId,
        bool allocationId,
        bool defaultAccountId,
        bool transactionsRefs,
        bool transactionLinesRefs,
        bool recurringTransactionsRefs,
        bool transactionTemplatesRefs})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  required String id,
  required String householdId,
  required String type,
  required String accountId,
  Value<String?> destinationAccountId,
  Value<String?> categoryId,
  required double amount,
  required String currency,
  Value<double> exchangeRateToBase,
  Value<String> note,
  Value<String?> receiptPath,
  required String createdBy,
  required String deviceId,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> type,
  Value<String> accountId,
  Value<String?> destinationAccountId,
  Value<String?> categoryId,
  Value<double> amount,
  Value<String> currency,
  Value<double> exchangeRateToBase,
  Value<String> note,
  Value<String?> receiptPath,
  Value<String> createdBy,
  Value<String> deviceId,
  Value<DateTime> createdAt,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
          $_aliasNameGenerator(db.transactions.householdId, db.households.id));

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager($_db, $_db.households)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.transactions.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _destinationAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.transactions.destinationAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get destinationAccountId {
    final $_column = $_itemColumn<String>('destination_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item =
        $_typedResult.readTableOrNull(_destinationAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.transactions.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionLinesTable, List<TransactionLine>>
      _transactionLinesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactionLines,
              aliasName: $_aliasNameGenerator(
                  db.transactions.id, db.transactionLines.transactionId));

  $$TransactionLinesTableProcessedTableManager get transactionLinesRefs {
    final manager =
        $$TransactionLinesTableTableManager($_db, $_db.transactionLines).filter(
            (f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_transactionLinesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AllocationLedgerTable, List<AllocationLedgerData>>
      _allocationLedgerRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.allocationLedger,
              aliasName: $_aliasNameGenerator(
                  db.transactions.id, db.allocationLedger.sourceTransactionId));

  $$AllocationLedgerTableProcessedTableManager get allocationLedgerRefs {
    final manager = $$AllocationLedgerTableTableManager(
            $_db, $_db.allocationLedger)
        .filter((f) =>
            f.sourceTransactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_allocationLedgerRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get exchangeRateToBase => $composableBuilder(
      column: $table.exchangeRateToBase,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptPath => $composableBuilder(
      column: $table.receiptPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableFilterComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get destinationAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionLinesRefs(
      Expression<bool> Function($$TransactionLinesTableFilterComposer f) f) {
    final $$TransactionLinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionLines,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionLinesTableFilterComposer(
              $db: $db,
              $table: $db.transactionLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> allocationLedgerRefs(
      Expression<bool> Function($$AllocationLedgerTableFilterComposer f) f) {
    final $$AllocationLedgerTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.allocationLedger,
        getReferencedColumn: (t) => t.sourceTransactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationLedgerTableFilterComposer(
              $db: $db,
              $table: $db.allocationLedger,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get exchangeRateToBase => $composableBuilder(
      column: $table.exchangeRateToBase,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptPath => $composableBuilder(
      column: $table.receiptPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableOrderingComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get destinationAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get exchangeRateToBase => $composableBuilder(
      column: $table.exchangeRateToBase, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get receiptPath => $composableBuilder(
      column: $table.receiptPath, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableAnnotationComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get destinationAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionLinesRefs<T extends Object>(
      Expression<T> Function($$TransactionLinesTableAnnotationComposer a) f) {
    final $$TransactionLinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionLines,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionLinesTableAnnotationComposer(
              $db: $db,
              $table: $db.transactionLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> allocationLedgerRefs<T extends Object>(
      Expression<T> Function($$AllocationLedgerTableAnnotationComposer a) f) {
    final $$AllocationLedgerTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.allocationLedger,
        getReferencedColumn: (t) => t.sourceTransactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationLedgerTableAnnotationComposer(
              $db: $db,
              $table: $db.allocationLedger,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function(
        {bool householdId,
        bool accountId,
        bool destinationAccountId,
        bool categoryId,
        bool transactionLinesRefs,
        bool allocationLedgerRefs})> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String?> destinationAccountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double> exchangeRateToBase = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String?> receiptPath = const Value.absent(),
            Value<String> createdBy = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            householdId: householdId,
            type: type,
            accountId: accountId,
            destinationAccountId: destinationAccountId,
            categoryId: categoryId,
            amount: amount,
            currency: currency,
            exchangeRateToBase: exchangeRateToBase,
            note: note,
            receiptPath: receiptPath,
            createdBy: createdBy,
            deviceId: deviceId,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String type,
            required String accountId,
            Value<String?> destinationAccountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            required double amount,
            required String currency,
            Value<double> exchangeRateToBase = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String?> receiptPath = const Value.absent(),
            required String createdBy,
            required String deviceId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            householdId: householdId,
            type: type,
            accountId: accountId,
            destinationAccountId: destinationAccountId,
            categoryId: categoryId,
            amount: amount,
            currency: currency,
            exchangeRateToBase: exchangeRateToBase,
            note: note,
            receiptPath: receiptPath,
            createdBy: createdBy,
            deviceId: deviceId,
            createdAt: createdAt,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {householdId = false,
              accountId = false,
              destinationAccountId = false,
              categoryId = false,
              transactionLinesRefs = false,
              allocationLedgerRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionLinesRefs) db.transactionLines,
                if (allocationLedgerRefs) db.allocationLedger
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (householdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.householdId,
                    referencedTable:
                        $$TransactionsTableReferences._householdIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._householdIdTable(db).id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$TransactionsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._accountIdTable(db).id,
                  ) as T;
                }
                if (destinationAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.destinationAccountId,
                    referencedTable: $$TransactionsTableReferences
                        ._destinationAccountIdTable(db),
                    referencedColumn: $$TransactionsTableReferences
                        ._destinationAccountIdTable(db)
                        .id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$TransactionsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionLinesRefs)
                    await $_getPrefetchedData<Transaction, $TransactionsTable,
                            TransactionLine>(
                        currentTable: table,
                        referencedTable: $$TransactionsTableReferences
                            ._transactionLinesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TransactionsTableReferences(db, table, p0)
                                .transactionLinesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.transactionId == item.id),
                        typedResults: items),
                  if (allocationLedgerRefs)
                    await $_getPrefetchedData<Transaction, $TransactionsTable,
                            AllocationLedgerData>(
                        currentTable: table,
                        referencedTable: $$TransactionsTableReferences
                            ._allocationLedgerRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TransactionsTableReferences(db, table, p0)
                                .allocationLedgerRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourceTransactionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function(
        {bool householdId,
        bool accountId,
        bool destinationAccountId,
        bool categoryId,
        bool transactionLinesRefs,
        bool allocationLedgerRefs})>;
typedef $$TransactionLinesTableCreateCompanionBuilder
    = TransactionLinesCompanion Function({
  required String id,
  required String transactionId,
  Value<String?> categoryId,
  Value<String?> accountId,
  required double amount,
  required String currency,
  Value<double> exchangeRateToBase,
  Value<String> note,
  Value<int> rowid,
});
typedef $$TransactionLinesTableUpdateCompanionBuilder
    = TransactionLinesCompanion Function({
  Value<String> id,
  Value<String> transactionId,
  Value<String?> categoryId,
  Value<String?> accountId,
  Value<double> amount,
  Value<String> currency,
  Value<double> exchangeRateToBase,
  Value<String> note,
  Value<int> rowid,
});

final class $$TransactionLinesTableReferences extends BaseReferences<
    _$AppDatabase, $TransactionLinesTable, TransactionLine> {
  $$TransactionLinesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.transactions.createAlias($_aliasNameGenerator(
          db.transactionLines.transactionId, db.transactions.id));

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias($_aliasNameGenerator(
          db.transactionLines.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.transactionLines.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionLinesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionLinesTable> {
  $$TransactionLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get exchangeRateToBase => $composableBuilder(
      column: $table.exchangeRateToBase,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionLinesTable> {
  $$TransactionLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get exchangeRateToBase => $composableBuilder(
      column: $table.exchangeRateToBase,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableOrderingComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionLinesTable> {
  $$TransactionLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get exchangeRateToBase => $composableBuilder(
      column: $table.exchangeRateToBase, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionLinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionLinesTable,
    TransactionLine,
    $$TransactionLinesTableFilterComposer,
    $$TransactionLinesTableOrderingComposer,
    $$TransactionLinesTableAnnotationComposer,
    $$TransactionLinesTableCreateCompanionBuilder,
    $$TransactionLinesTableUpdateCompanionBuilder,
    (TransactionLine, $$TransactionLinesTableReferences),
    TransactionLine,
    PrefetchHooks Function(
        {bool transactionId, bool categoryId, bool accountId})> {
  $$TransactionLinesTableTableManager(
      _$AppDatabase db, $TransactionLinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> transactionId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double> exchangeRateToBase = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionLinesCompanion(
            id: id,
            transactionId: transactionId,
            categoryId: categoryId,
            accountId: accountId,
            amount: amount,
            currency: currency,
            exchangeRateToBase: exchangeRateToBase,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String transactionId,
            Value<String?> categoryId = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            required double amount,
            required String currency,
            Value<double> exchangeRateToBase = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionLinesCompanion.insert(
            id: id,
            transactionId: transactionId,
            categoryId: categoryId,
            accountId: accountId,
            amount: amount,
            currency: currency,
            exchangeRateToBase: exchangeRateToBase,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionLinesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {transactionId = false, categoryId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (transactionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.transactionId,
                    referencedTable: $$TransactionLinesTableReferences
                        ._transactionIdTable(db),
                    referencedColumn: $$TransactionLinesTableReferences
                        ._transactionIdTable(db)
                        .id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$TransactionLinesTableReferences._categoryIdTable(db),
                    referencedColumn: $$TransactionLinesTableReferences
                        ._categoryIdTable(db)
                        .id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$TransactionLinesTableReferences._accountIdTable(db),
                    referencedColumn: $$TransactionLinesTableReferences
                        ._accountIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionLinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionLinesTable,
    TransactionLine,
    $$TransactionLinesTableFilterComposer,
    $$TransactionLinesTableOrderingComposer,
    $$TransactionLinesTableAnnotationComposer,
    $$TransactionLinesTableCreateCompanionBuilder,
    $$TransactionLinesTableUpdateCompanionBuilder,
    (TransactionLine, $$TransactionLinesTableReferences),
    TransactionLine,
    PrefetchHooks Function(
        {bool transactionId, bool categoryId, bool accountId})>;
typedef $$AllocationLedgerTableCreateCompanionBuilder
    = AllocationLedgerCompanion Function({
  required String id,
  required String allocationId,
  Value<String?> sourceTransactionId,
  Value<String?> sourceAccountId,
  Value<String?> destAccountId,
  required String entryType,
  required double amount,
  required String currency,
  Value<double> exchangeRateToBase,
  Value<String> note,
  Value<DateTime> createdAt,
  required String deviceId,
  Value<int> rowid,
});
typedef $$AllocationLedgerTableUpdateCompanionBuilder
    = AllocationLedgerCompanion Function({
  Value<String> id,
  Value<String> allocationId,
  Value<String?> sourceTransactionId,
  Value<String?> sourceAccountId,
  Value<String?> destAccountId,
  Value<String> entryType,
  Value<double> amount,
  Value<String> currency,
  Value<double> exchangeRateToBase,
  Value<String> note,
  Value<DateTime> createdAt,
  Value<String> deviceId,
  Value<int> rowid,
});

final class $$AllocationLedgerTableReferences extends BaseReferences<
    _$AppDatabase, $AllocationLedgerTable, AllocationLedgerData> {
  $$AllocationLedgerTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AllocationsTable _allocationIdTable(_$AppDatabase db) =>
      db.allocations.createAlias($_aliasNameGenerator(
          db.allocationLedger.allocationId, db.allocations.id));

  $$AllocationsTableProcessedTableManager get allocationId {
    final $_column = $_itemColumn<String>('allocation_id')!;

    final manager = $$AllocationsTableTableManager($_db, $_db.allocations)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_allocationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TransactionsTable _sourceTransactionIdTable(_$AppDatabase db) =>
      db.transactions.createAlias($_aliasNameGenerator(
          db.allocationLedger.sourceTransactionId, db.transactions.id));

  $$TransactionsTableProcessedTableManager? get sourceTransactionId {
    final $_column = $_itemColumn<String>('source_transaction_id');
    if ($_column == null) return null;
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceTransactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _sourceAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.allocationLedger.sourceAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get sourceAccountId {
    final $_column = $_itemColumn<String>('source_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _destAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.allocationLedger.destAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get destAccountId {
    final $_column = $_itemColumn<String>('dest_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_destAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AllocationLedgerTableFilterComposer
    extends Composer<_$AppDatabase, $AllocationLedgerTable> {
  $$AllocationLedgerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryType => $composableBuilder(
      column: $table.entryType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get exchangeRateToBase => $composableBuilder(
      column: $table.exchangeRateToBase,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  $$AllocationsTableFilterComposer get allocationId {
    final $$AllocationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.allocationId,
        referencedTable: $db.allocations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationsTableFilterComposer(
              $db: $db,
              $table: $db.allocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TransactionsTableFilterComposer get sourceTransactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceTransactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get sourceAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get destAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AllocationLedgerTableOrderingComposer
    extends Composer<_$AppDatabase, $AllocationLedgerTable> {
  $$AllocationLedgerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryType => $composableBuilder(
      column: $table.entryType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get exchangeRateToBase => $composableBuilder(
      column: $table.exchangeRateToBase,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  $$AllocationsTableOrderingComposer get allocationId {
    final $$AllocationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.allocationId,
        referencedTable: $db.allocations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationsTableOrderingComposer(
              $db: $db,
              $table: $db.allocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TransactionsTableOrderingComposer get sourceTransactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceTransactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableOrderingComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get sourceAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get destAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AllocationLedgerTableAnnotationComposer
    extends Composer<_$AppDatabase, $AllocationLedgerTable> {
  $$AllocationLedgerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get exchangeRateToBase => $composableBuilder(
      column: $table.exchangeRateToBase, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  $$AllocationsTableAnnotationComposer get allocationId {
    final $$AllocationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.allocationId,
        referencedTable: $db.allocations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AllocationsTableAnnotationComposer(
              $db: $db,
              $table: $db.allocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TransactionsTableAnnotationComposer get sourceTransactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceTransactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get sourceAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get destAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AllocationLedgerTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AllocationLedgerTable,
    AllocationLedgerData,
    $$AllocationLedgerTableFilterComposer,
    $$AllocationLedgerTableOrderingComposer,
    $$AllocationLedgerTableAnnotationComposer,
    $$AllocationLedgerTableCreateCompanionBuilder,
    $$AllocationLedgerTableUpdateCompanionBuilder,
    (AllocationLedgerData, $$AllocationLedgerTableReferences),
    AllocationLedgerData,
    PrefetchHooks Function(
        {bool allocationId,
        bool sourceTransactionId,
        bool sourceAccountId,
        bool destAccountId})> {
  $$AllocationLedgerTableTableManager(
      _$AppDatabase db, $AllocationLedgerTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AllocationLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AllocationLedgerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AllocationLedgerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> allocationId = const Value.absent(),
            Value<String?> sourceTransactionId = const Value.absent(),
            Value<String?> sourceAccountId = const Value.absent(),
            Value<String?> destAccountId = const Value.absent(),
            Value<String> entryType = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double> exchangeRateToBase = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AllocationLedgerCompanion(
            id: id,
            allocationId: allocationId,
            sourceTransactionId: sourceTransactionId,
            sourceAccountId: sourceAccountId,
            destAccountId: destAccountId,
            entryType: entryType,
            amount: amount,
            currency: currency,
            exchangeRateToBase: exchangeRateToBase,
            note: note,
            createdAt: createdAt,
            deviceId: deviceId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String allocationId,
            Value<String?> sourceTransactionId = const Value.absent(),
            Value<String?> sourceAccountId = const Value.absent(),
            Value<String?> destAccountId = const Value.absent(),
            required String entryType,
            required double amount,
            required String currency,
            Value<double> exchangeRateToBase = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            required String deviceId,
            Value<int> rowid = const Value.absent(),
          }) =>
              AllocationLedgerCompanion.insert(
            id: id,
            allocationId: allocationId,
            sourceTransactionId: sourceTransactionId,
            sourceAccountId: sourceAccountId,
            destAccountId: destAccountId,
            entryType: entryType,
            amount: amount,
            currency: currency,
            exchangeRateToBase: exchangeRateToBase,
            note: note,
            createdAt: createdAt,
            deviceId: deviceId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AllocationLedgerTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {allocationId = false,
              sourceTransactionId = false,
              sourceAccountId = false,
              destAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (allocationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.allocationId,
                    referencedTable: $$AllocationLedgerTableReferences
                        ._allocationIdTable(db),
                    referencedColumn: $$AllocationLedgerTableReferences
                        ._allocationIdTable(db)
                        .id,
                  ) as T;
                }
                if (sourceTransactionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourceTransactionId,
                    referencedTable: $$AllocationLedgerTableReferences
                        ._sourceTransactionIdTable(db),
                    referencedColumn: $$AllocationLedgerTableReferences
                        ._sourceTransactionIdTable(db)
                        .id,
                  ) as T;
                }
                if (sourceAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourceAccountId,
                    referencedTable: $$AllocationLedgerTableReferences
                        ._sourceAccountIdTable(db),
                    referencedColumn: $$AllocationLedgerTableReferences
                        ._sourceAccountIdTable(db)
                        .id,
                  ) as T;
                }
                if (destAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.destAccountId,
                    referencedTable: $$AllocationLedgerTableReferences
                        ._destAccountIdTable(db),
                    referencedColumn: $$AllocationLedgerTableReferences
                        ._destAccountIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AllocationLedgerTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AllocationLedgerTable,
    AllocationLedgerData,
    $$AllocationLedgerTableFilterComposer,
    $$AllocationLedgerTableOrderingComposer,
    $$AllocationLedgerTableAnnotationComposer,
    $$AllocationLedgerTableCreateCompanionBuilder,
    $$AllocationLedgerTableUpdateCompanionBuilder,
    (AllocationLedgerData, $$AllocationLedgerTableReferences),
    AllocationLedgerData,
    PrefetchHooks Function(
        {bool allocationId,
        bool sourceTransactionId,
        bool sourceAccountId,
        bool destAccountId})>;
typedef $$FxRatesTableCreateCompanionBuilder = FxRatesCompanion Function({
  required String id,
  required String fromCurrency,
  required String toCurrency,
  required double rate,
  Value<DateTime> fetchedAt,
  Value<String> source,
  Value<int> rowid,
});
typedef $$FxRatesTableUpdateCompanionBuilder = FxRatesCompanion Function({
  Value<String> id,
  Value<String> fromCurrency,
  Value<String> toCurrency,
  Value<double> rate,
  Value<DateTime> fetchedAt,
  Value<String> source,
  Value<int> rowid,
});

class $$FxRatesTableFilterComposer
    extends Composer<_$AppDatabase, $FxRatesTable> {
  $$FxRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromCurrency => $composableBuilder(
      column: $table.fromCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$FxRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $FxRatesTable> {
  $$FxRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromCurrency => $composableBuilder(
      column: $table.fromCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$FxRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FxRatesTable> {
  $$FxRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromCurrency => $composableBuilder(
      column: $table.fromCurrency, builder: (column) => column);

  GeneratedColumn<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$FxRatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FxRatesTable,
    FxRate,
    $$FxRatesTableFilterComposer,
    $$FxRatesTableOrderingComposer,
    $$FxRatesTableAnnotationComposer,
    $$FxRatesTableCreateCompanionBuilder,
    $$FxRatesTableUpdateCompanionBuilder,
    (FxRate, BaseReferences<_$AppDatabase, $FxRatesTable, FxRate>),
    FxRate,
    PrefetchHooks Function()> {
  $$FxRatesTableTableManager(_$AppDatabase db, $FxRatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FxRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FxRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FxRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fromCurrency = const Value.absent(),
            Value<String> toCurrency = const Value.absent(),
            Value<double> rate = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FxRatesCompanion(
            id: id,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: rate,
            fetchedAt: fetchedAt,
            source: source,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fromCurrency,
            required String toCurrency,
            required double rate,
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FxRatesCompanion.insert(
            id: id,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: rate,
            fetchedAt: fetchedAt,
            source: source,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FxRatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FxRatesTable,
    FxRate,
    $$FxRatesTableFilterComposer,
    $$FxRatesTableOrderingComposer,
    $$FxRatesTableAnnotationComposer,
    $$FxRatesTableCreateCompanionBuilder,
    $$FxRatesTableUpdateCompanionBuilder,
    (FxRate, BaseReferences<_$AppDatabase, $FxRatesTable, FxRate>),
    FxRate,
    PrefetchHooks Function()>;
typedef $$RecurringTransactionsTableCreateCompanionBuilder
    = RecurringTransactionsCompanion Function({
  required String id,
  required String householdId,
  required String type,
  Value<String> title,
  required double amount,
  required String currency,
  required String accountId,
  Value<String?> destinationAccountId,
  Value<String?> categoryId,
  Value<String> note,
  required String frequency,
  Value<int> interval,
  required DateTime nextDueDate,
  Value<DateTime?> lastGeneratedDate,
  Value<DateTime?> endDate,
  Value<bool> enabled,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$RecurringTransactionsTableUpdateCompanionBuilder
    = RecurringTransactionsCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> type,
  Value<String> title,
  Value<double> amount,
  Value<String> currency,
  Value<String> accountId,
  Value<String?> destinationAccountId,
  Value<String?> categoryId,
  Value<String> note,
  Value<String> frequency,
  Value<int> interval,
  Value<DateTime> nextDueDate,
  Value<DateTime?> lastGeneratedDate,
  Value<DateTime?> endDate,
  Value<bool> enabled,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$RecurringTransactionsTableReferences extends BaseReferences<
    _$AppDatabase, $RecurringTransactionsTable, RecurringTransaction> {
  $$RecurringTransactionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias($_aliasNameGenerator(
          db.recurringTransactions.householdId, db.households.id));

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager($_db, $_db.households)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.recurringTransactions.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _destinationAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.recurringTransactions.destinationAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get destinationAccountId {
    final $_column = $_itemColumn<String>('destination_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item =
        $_typedResult.readTableOrNull(_destinationAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias($_aliasNameGenerator(
          db.recurringTransactions.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecurringTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringTransactionsTable> {
  $$RecurringTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get interval => $composableBuilder(
      column: $table.interval, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastGeneratedDate => $composableBuilder(
      column: $table.lastGeneratedDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableFilterComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get destinationAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurringTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringTransactionsTable> {
  $$RecurringTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get interval => $composableBuilder(
      column: $table.interval, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastGeneratedDate => $composableBuilder(
      column: $table.lastGeneratedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableOrderingComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get destinationAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurringTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringTransactionsTable> {
  $$RecurringTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get lastGeneratedDate => $composableBuilder(
      column: $table.lastGeneratedDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableAnnotationComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get destinationAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurringTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurringTransactionsTable,
    RecurringTransaction,
    $$RecurringTransactionsTableFilterComposer,
    $$RecurringTransactionsTableOrderingComposer,
    $$RecurringTransactionsTableAnnotationComposer,
    $$RecurringTransactionsTableCreateCompanionBuilder,
    $$RecurringTransactionsTableUpdateCompanionBuilder,
    (RecurringTransaction, $$RecurringTransactionsTableReferences),
    RecurringTransaction,
    PrefetchHooks Function(
        {bool householdId,
        bool accountId,
        bool destinationAccountId,
        bool categoryId})> {
  $$RecurringTransactionsTableTableManager(
      _$AppDatabase db, $RecurringTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringTransactionsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringTransactionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String?> destinationAccountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<int> interval = const Value.absent(),
            Value<DateTime> nextDueDate = const Value.absent(),
            Value<DateTime?> lastGeneratedDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringTransactionsCompanion(
            id: id,
            householdId: householdId,
            type: type,
            title: title,
            amount: amount,
            currency: currency,
            accountId: accountId,
            destinationAccountId: destinationAccountId,
            categoryId: categoryId,
            note: note,
            frequency: frequency,
            interval: interval,
            nextDueDate: nextDueDate,
            lastGeneratedDate: lastGeneratedDate,
            endDate: endDate,
            enabled: enabled,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String type,
            Value<String> title = const Value.absent(),
            required double amount,
            required String currency,
            required String accountId,
            Value<String?> destinationAccountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String> note = const Value.absent(),
            required String frequency,
            Value<int> interval = const Value.absent(),
            required DateTime nextDueDate,
            Value<DateTime?> lastGeneratedDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringTransactionsCompanion.insert(
            id: id,
            householdId: householdId,
            type: type,
            title: title,
            amount: amount,
            currency: currency,
            accountId: accountId,
            destinationAccountId: destinationAccountId,
            categoryId: categoryId,
            note: note,
            frequency: frequency,
            interval: interval,
            nextDueDate: nextDueDate,
            lastGeneratedDate: lastGeneratedDate,
            endDate: endDate,
            enabled: enabled,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RecurringTransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {householdId = false,
              accountId = false,
              destinationAccountId = false,
              categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (householdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.householdId,
                    referencedTable: $$RecurringTransactionsTableReferences
                        ._householdIdTable(db),
                    referencedColumn: $$RecurringTransactionsTableReferences
                        ._householdIdTable(db)
                        .id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable: $$RecurringTransactionsTableReferences
                        ._accountIdTable(db),
                    referencedColumn: $$RecurringTransactionsTableReferences
                        ._accountIdTable(db)
                        .id,
                  ) as T;
                }
                if (destinationAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.destinationAccountId,
                    referencedTable: $$RecurringTransactionsTableReferences
                        ._destinationAccountIdTable(db),
                    referencedColumn: $$RecurringTransactionsTableReferences
                        ._destinationAccountIdTable(db)
                        .id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable: $$RecurringTransactionsTableReferences
                        ._categoryIdTable(db),
                    referencedColumn: $$RecurringTransactionsTableReferences
                        ._categoryIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RecurringTransactionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $RecurringTransactionsTable,
        RecurringTransaction,
        $$RecurringTransactionsTableFilterComposer,
        $$RecurringTransactionsTableOrderingComposer,
        $$RecurringTransactionsTableAnnotationComposer,
        $$RecurringTransactionsTableCreateCompanionBuilder,
        $$RecurringTransactionsTableUpdateCompanionBuilder,
        (RecurringTransaction, $$RecurringTransactionsTableReferences),
        RecurringTransaction,
        PrefetchHooks Function(
            {bool householdId,
            bool accountId,
            bool destinationAccountId,
            bool categoryId})>;
typedef $$TransactionTemplatesTableCreateCompanionBuilder
    = TransactionTemplatesCompanion Function({
  required String id,
  required String householdId,
  required String title,
  required String type,
  required double amount,
  required String currency,
  Value<String?> accountId,
  Value<String?> categoryId,
  Value<int> useCount,
  Value<DateTime?> lastUsedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$TransactionTemplatesTableUpdateCompanionBuilder
    = TransactionTemplatesCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> title,
  Value<String> type,
  Value<double> amount,
  Value<String> currency,
  Value<String?> accountId,
  Value<String?> categoryId,
  Value<int> useCount,
  Value<DateTime?> lastUsedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TransactionTemplatesTableReferences extends BaseReferences<
    _$AppDatabase, $TransactionTemplatesTable, TransactionTemplate> {
  $$TransactionTemplatesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias($_aliasNameGenerator(
          db.transactionTemplates.householdId, db.households.id));

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager($_db, $_db.households)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.transactionTemplates.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias($_aliasNameGenerator(
          db.transactionTemplates.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionTemplatesTable> {
  $$TransactionTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get useCount => $composableBuilder(
      column: $table.useCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableFilterComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionTemplatesTable> {
  $$TransactionTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get useCount => $composableBuilder(
      column: $table.useCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableOrderingComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionTemplatesTable> {
  $$TransactionTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.householdId,
        referencedTable: $db.households,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HouseholdsTableAnnotationComposer(
              $db: $db,
              $table: $db.households,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionTemplatesTable,
    TransactionTemplate,
    $$TransactionTemplatesTableFilterComposer,
    $$TransactionTemplatesTableOrderingComposer,
    $$TransactionTemplatesTableAnnotationComposer,
    $$TransactionTemplatesTableCreateCompanionBuilder,
    $$TransactionTemplatesTableUpdateCompanionBuilder,
    (TransactionTemplate, $$TransactionTemplatesTableReferences),
    TransactionTemplate,
    PrefetchHooks Function(
        {bool householdId, bool accountId, bool categoryId})> {
  $$TransactionTemplatesTableTableManager(
      _$AppDatabase db, $TransactionTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionTemplatesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionTemplatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<int> useCount = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionTemplatesCompanion(
            id: id,
            householdId: householdId,
            title: title,
            type: type,
            amount: amount,
            currency: currency,
            accountId: accountId,
            categoryId: categoryId,
            useCount: useCount,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String title,
            required String type,
            required double amount,
            required String currency,
            Value<String?> accountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<int> useCount = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionTemplatesCompanion.insert(
            id: id,
            householdId: householdId,
            title: title,
            type: type,
            amount: amount,
            currency: currency,
            accountId: accountId,
            categoryId: categoryId,
            useCount: useCount,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionTemplatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {householdId = false, accountId = false, categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (householdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.householdId,
                    referencedTable: $$TransactionTemplatesTableReferences
                        ._householdIdTable(db),
                    referencedColumn: $$TransactionTemplatesTableReferences
                        ._householdIdTable(db)
                        .id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable: $$TransactionTemplatesTableReferences
                        ._accountIdTable(db),
                    referencedColumn: $$TransactionTemplatesTableReferences
                        ._accountIdTable(db)
                        .id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable: $$TransactionTemplatesTableReferences
                        ._categoryIdTable(db),
                    referencedColumn: $$TransactionTemplatesTableReferences
                        ._categoryIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionTemplatesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $TransactionTemplatesTable,
        TransactionTemplate,
        $$TransactionTemplatesTableFilterComposer,
        $$TransactionTemplatesTableOrderingComposer,
        $$TransactionTemplatesTableAnnotationComposer,
        $$TransactionTemplatesTableCreateCompanionBuilder,
        $$TransactionTemplatesTableUpdateCompanionBuilder,
        (TransactionTemplate, $$TransactionTemplatesTableReferences),
        TransactionTemplate,
        PrefetchHooks Function(
            {bool householdId, bool accountId, bool categoryId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db, _db.households);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$AllocationsTableTableManager get allocations =>
      $$AllocationsTableTableManager(_db, _db.allocations);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$TransactionLinesTableTableManager get transactionLines =>
      $$TransactionLinesTableTableManager(_db, _db.transactionLines);
  $$AllocationLedgerTableTableManager get allocationLedger =>
      $$AllocationLedgerTableTableManager(_db, _db.allocationLedger);
  $$FxRatesTableTableManager get fxRates =>
      $$FxRatesTableTableManager(_db, _db.fxRates);
  $$RecurringTransactionsTableTableManager get recurringTransactions =>
      $$RecurringTransactionsTableTableManager(_db, _db.recurringTransactions);
  $$TransactionTemplatesTableTableManager get transactionTemplates =>
      $$TransactionTemplatesTableTableManager(_db, _db.transactionTemplates);
}

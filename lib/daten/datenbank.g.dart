// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datenbank.dart';

// ignore_for_file: type=lint
class $ZaehlerTabelleTable extends ZaehlerTabelle
    with TableInfo<$ZaehlerTabelleTable, Zaehler> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ZaehlerTabelleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _geaendertAmMeta = const VerificationMeta(
    'geaendertAm',
  );
  @override
  late final GeneratedColumn<int> geaendertAm = GeneratedColumn<int>(
    'geaendert_am',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _geloeschtMeta = const VerificationMeta(
    'geloescht',
  );
  @override
  late final GeneratedColumn<bool> geloescht = GeneratedColumn<bool>(
    'geloescht',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("geloescht" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ungesendetMeta = const VerificationMeta(
    'ungesendet',
  );
  @override
  late final GeneratedColumn<bool> ungesendet = GeneratedColumn<bool>(
    'ungesendet',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ungesendet" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artMeta = const VerificationMeta('art');
  @override
  late final GeneratedColumn<String> art = GeneratedColumn<String>(
    'art',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _einheitMeta = const VerificationMeta(
    'einheit',
  );
  @override
  late final GeneratedColumn<String> einheit = GeneratedColumn<String>(
    'einheit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zaehlernummerMeta = const VerificationMeta(
    'zaehlernummer',
  );
  @override
  late final GeneratedColumn<String> zaehlernummer = GeneratedColumn<String>(
    'zaehlernummer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notizMeta = const VerificationMeta('notiz');
  @override
  late final GeneratedColumn<String> notiz = GeneratedColumn<String>(
    'notiz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    geaendertAm,
    geloescht,
    ungesendet,
    name,
    art,
    einheit,
    zaehlernummer,
    notiz,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'zaehler';
  @override
  VerificationContext validateIntegrity(
    Insertable<Zaehler> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('geaendert_am')) {
      context.handle(
        _geaendertAmMeta,
        geaendertAm.isAcceptableOrUnknown(
          data['geaendert_am']!,
          _geaendertAmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_geaendertAmMeta);
    }
    if (data.containsKey('geloescht')) {
      context.handle(
        _geloeschtMeta,
        geloescht.isAcceptableOrUnknown(data['geloescht']!, _geloeschtMeta),
      );
    }
    if (data.containsKey('ungesendet')) {
      context.handle(
        _ungesendetMeta,
        ungesendet.isAcceptableOrUnknown(data['ungesendet']!, _ungesendetMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('art')) {
      context.handle(
        _artMeta,
        art.isAcceptableOrUnknown(data['art']!, _artMeta),
      );
    } else if (isInserting) {
      context.missing(_artMeta);
    }
    if (data.containsKey('einheit')) {
      context.handle(
        _einheitMeta,
        einheit.isAcceptableOrUnknown(data['einheit']!, _einheitMeta),
      );
    } else if (isInserting) {
      context.missing(_einheitMeta);
    }
    if (data.containsKey('zaehlernummer')) {
      context.handle(
        _zaehlernummerMeta,
        zaehlernummer.isAcceptableOrUnknown(
          data['zaehlernummer']!,
          _zaehlernummerMeta,
        ),
      );
    }
    if (data.containsKey('notiz')) {
      context.handle(
        _notizMeta,
        notiz.isAcceptableOrUnknown(data['notiz']!, _notizMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Zaehler map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Zaehler(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      geaendertAm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}geaendert_am'],
      )!,
      geloescht: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}geloescht'],
      )!,
      ungesendet: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ungesendet'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      art: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}art'],
      )!,
      einheit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}einheit'],
      )!,
      zaehlernummer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zaehlernummer'],
      )!,
      notiz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notiz'],
      )!,
    );
  }

  @override
  $ZaehlerTabelleTable createAlias(String alias) {
    return $ZaehlerTabelleTable(attachedDatabase, alias);
  }
}

class Zaehler extends DataClass implements Insertable<Zaehler> {
  final String id;

  /// Zeitpunkt der letzten Änderung (ms seit 1970). Bei Konflikten gewinnt
  /// der neuere Stand.
  final int geaendertAm;

  /// Gelöscht wird nur weich, damit die Löschung auch synchronisiert wird.
  final bool geloescht;

  /// Lokal geändert und noch nicht zum Server übertragen.
  final bool ungesendet;
  final String name;
  final String art;
  final String einheit;
  final String zaehlernummer;
  final String notiz;
  const Zaehler({
    required this.id,
    required this.geaendertAm,
    required this.geloescht,
    required this.ungesendet,
    required this.name,
    required this.art,
    required this.einheit,
    required this.zaehlernummer,
    required this.notiz,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['geaendert_am'] = Variable<int>(geaendertAm);
    map['geloescht'] = Variable<bool>(geloescht);
    map['ungesendet'] = Variable<bool>(ungesendet);
    map['name'] = Variable<String>(name);
    map['art'] = Variable<String>(art);
    map['einheit'] = Variable<String>(einheit);
    map['zaehlernummer'] = Variable<String>(zaehlernummer);
    map['notiz'] = Variable<String>(notiz);
    return map;
  }

  ZaehlerTabelleCompanion toCompanion(bool nullToAbsent) {
    return ZaehlerTabelleCompanion(
      id: Value(id),
      geaendertAm: Value(geaendertAm),
      geloescht: Value(geloescht),
      ungesendet: Value(ungesendet),
      name: Value(name),
      art: Value(art),
      einheit: Value(einheit),
      zaehlernummer: Value(zaehlernummer),
      notiz: Value(notiz),
    );
  }

  factory Zaehler.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Zaehler(
      id: serializer.fromJson<String>(json['id']),
      geaendertAm: serializer.fromJson<int>(json['geaendertAm']),
      geloescht: serializer.fromJson<bool>(json['geloescht']),
      ungesendet: serializer.fromJson<bool>(json['ungesendet']),
      name: serializer.fromJson<String>(json['name']),
      art: serializer.fromJson<String>(json['art']),
      einheit: serializer.fromJson<String>(json['einheit']),
      zaehlernummer: serializer.fromJson<String>(json['zaehlernummer']),
      notiz: serializer.fromJson<String>(json['notiz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'geaendertAm': serializer.toJson<int>(geaendertAm),
      'geloescht': serializer.toJson<bool>(geloescht),
      'ungesendet': serializer.toJson<bool>(ungesendet),
      'name': serializer.toJson<String>(name),
      'art': serializer.toJson<String>(art),
      'einheit': serializer.toJson<String>(einheit),
      'zaehlernummer': serializer.toJson<String>(zaehlernummer),
      'notiz': serializer.toJson<String>(notiz),
    };
  }

  Zaehler copyWith({
    String? id,
    int? geaendertAm,
    bool? geloescht,
    bool? ungesendet,
    String? name,
    String? art,
    String? einheit,
    String? zaehlernummer,
    String? notiz,
  }) => Zaehler(
    id: id ?? this.id,
    geaendertAm: geaendertAm ?? this.geaendertAm,
    geloescht: geloescht ?? this.geloescht,
    ungesendet: ungesendet ?? this.ungesendet,
    name: name ?? this.name,
    art: art ?? this.art,
    einheit: einheit ?? this.einheit,
    zaehlernummer: zaehlernummer ?? this.zaehlernummer,
    notiz: notiz ?? this.notiz,
  );
  Zaehler copyWithCompanion(ZaehlerTabelleCompanion data) {
    return Zaehler(
      id: data.id.present ? data.id.value : this.id,
      geaendertAm: data.geaendertAm.present
          ? data.geaendertAm.value
          : this.geaendertAm,
      geloescht: data.geloescht.present ? data.geloescht.value : this.geloescht,
      ungesendet: data.ungesendet.present
          ? data.ungesendet.value
          : this.ungesendet,
      name: data.name.present ? data.name.value : this.name,
      art: data.art.present ? data.art.value : this.art,
      einheit: data.einheit.present ? data.einheit.value : this.einheit,
      zaehlernummer: data.zaehlernummer.present
          ? data.zaehlernummer.value
          : this.zaehlernummer,
      notiz: data.notiz.present ? data.notiz.value : this.notiz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Zaehler(')
          ..write('id: $id, ')
          ..write('geaendertAm: $geaendertAm, ')
          ..write('geloescht: $geloescht, ')
          ..write('ungesendet: $ungesendet, ')
          ..write('name: $name, ')
          ..write('art: $art, ')
          ..write('einheit: $einheit, ')
          ..write('zaehlernummer: $zaehlernummer, ')
          ..write('notiz: $notiz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    geaendertAm,
    geloescht,
    ungesendet,
    name,
    art,
    einheit,
    zaehlernummer,
    notiz,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Zaehler &&
          other.id == this.id &&
          other.geaendertAm == this.geaendertAm &&
          other.geloescht == this.geloescht &&
          other.ungesendet == this.ungesendet &&
          other.name == this.name &&
          other.art == this.art &&
          other.einheit == this.einheit &&
          other.zaehlernummer == this.zaehlernummer &&
          other.notiz == this.notiz);
}

class ZaehlerTabelleCompanion extends UpdateCompanion<Zaehler> {
  final Value<String> id;
  final Value<int> geaendertAm;
  final Value<bool> geloescht;
  final Value<bool> ungesendet;
  final Value<String> name;
  final Value<String> art;
  final Value<String> einheit;
  final Value<String> zaehlernummer;
  final Value<String> notiz;
  final Value<int> rowid;
  const ZaehlerTabelleCompanion({
    this.id = const Value.absent(),
    this.geaendertAm = const Value.absent(),
    this.geloescht = const Value.absent(),
    this.ungesendet = const Value.absent(),
    this.name = const Value.absent(),
    this.art = const Value.absent(),
    this.einheit = const Value.absent(),
    this.zaehlernummer = const Value.absent(),
    this.notiz = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ZaehlerTabelleCompanion.insert({
    required String id,
    required int geaendertAm,
    this.geloescht = const Value.absent(),
    this.ungesendet = const Value.absent(),
    required String name,
    required String art,
    required String einheit,
    this.zaehlernummer = const Value.absent(),
    this.notiz = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       geaendertAm = Value(geaendertAm),
       name = Value(name),
       art = Value(art),
       einheit = Value(einheit);
  static Insertable<Zaehler> custom({
    Expression<String>? id,
    Expression<int>? geaendertAm,
    Expression<bool>? geloescht,
    Expression<bool>? ungesendet,
    Expression<String>? name,
    Expression<String>? art,
    Expression<String>? einheit,
    Expression<String>? zaehlernummer,
    Expression<String>? notiz,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (geaendertAm != null) 'geaendert_am': geaendertAm,
      if (geloescht != null) 'geloescht': geloescht,
      if (ungesendet != null) 'ungesendet': ungesendet,
      if (name != null) 'name': name,
      if (art != null) 'art': art,
      if (einheit != null) 'einheit': einheit,
      if (zaehlernummer != null) 'zaehlernummer': zaehlernummer,
      if (notiz != null) 'notiz': notiz,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ZaehlerTabelleCompanion copyWith({
    Value<String>? id,
    Value<int>? geaendertAm,
    Value<bool>? geloescht,
    Value<bool>? ungesendet,
    Value<String>? name,
    Value<String>? art,
    Value<String>? einheit,
    Value<String>? zaehlernummer,
    Value<String>? notiz,
    Value<int>? rowid,
  }) {
    return ZaehlerTabelleCompanion(
      id: id ?? this.id,
      geaendertAm: geaendertAm ?? this.geaendertAm,
      geloescht: geloescht ?? this.geloescht,
      ungesendet: ungesendet ?? this.ungesendet,
      name: name ?? this.name,
      art: art ?? this.art,
      einheit: einheit ?? this.einheit,
      zaehlernummer: zaehlernummer ?? this.zaehlernummer,
      notiz: notiz ?? this.notiz,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (geaendertAm.present) {
      map['geaendert_am'] = Variable<int>(geaendertAm.value);
    }
    if (geloescht.present) {
      map['geloescht'] = Variable<bool>(geloescht.value);
    }
    if (ungesendet.present) {
      map['ungesendet'] = Variable<bool>(ungesendet.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (art.present) {
      map['art'] = Variable<String>(art.value);
    }
    if (einheit.present) {
      map['einheit'] = Variable<String>(einheit.value);
    }
    if (zaehlernummer.present) {
      map['zaehlernummer'] = Variable<String>(zaehlernummer.value);
    }
    if (notiz.present) {
      map['notiz'] = Variable<String>(notiz.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ZaehlerTabelleCompanion(')
          ..write('id: $id, ')
          ..write('geaendertAm: $geaendertAm, ')
          ..write('geloescht: $geloescht, ')
          ..write('ungesendet: $ungesendet, ')
          ..write('name: $name, ')
          ..write('art: $art, ')
          ..write('einheit: $einheit, ')
          ..write('zaehlernummer: $zaehlernummer, ')
          ..write('notiz: $notiz, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AblesungenTable extends Ablesungen
    with TableInfo<$AblesungenTable, Ablesung> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AblesungenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _geaendertAmMeta = const VerificationMeta(
    'geaendertAm',
  );
  @override
  late final GeneratedColumn<int> geaendertAm = GeneratedColumn<int>(
    'geaendert_am',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _geloeschtMeta = const VerificationMeta(
    'geloescht',
  );
  @override
  late final GeneratedColumn<bool> geloescht = GeneratedColumn<bool>(
    'geloescht',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("geloescht" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ungesendetMeta = const VerificationMeta(
    'ungesendet',
  );
  @override
  late final GeneratedColumn<bool> ungesendet = GeneratedColumn<bool>(
    'ungesendet',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ungesendet" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _zaehlerIdMeta = const VerificationMeta(
    'zaehlerId',
  );
  @override
  late final GeneratedColumn<String> zaehlerId = GeneratedColumn<String>(
    'zaehler_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _datumMeta = const VerificationMeta('datum');
  @override
  late final GeneratedColumn<String> datum = GeneratedColumn<String>(
    'datum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _standMeta = const VerificationMeta('stand');
  @override
  late final GeneratedColumn<double> stand = GeneratedColumn<double>(
    'stand',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notizMeta = const VerificationMeta('notiz');
  @override
  late final GeneratedColumn<String> notiz = GeneratedColumn<String>(
    'notiz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    geaendertAm,
    geloescht,
    ungesendet,
    zaehlerId,
    datum,
    stand,
    notiz,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ablesungen';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ablesung> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('geaendert_am')) {
      context.handle(
        _geaendertAmMeta,
        geaendertAm.isAcceptableOrUnknown(
          data['geaendert_am']!,
          _geaendertAmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_geaendertAmMeta);
    }
    if (data.containsKey('geloescht')) {
      context.handle(
        _geloeschtMeta,
        geloescht.isAcceptableOrUnknown(data['geloescht']!, _geloeschtMeta),
      );
    }
    if (data.containsKey('ungesendet')) {
      context.handle(
        _ungesendetMeta,
        ungesendet.isAcceptableOrUnknown(data['ungesendet']!, _ungesendetMeta),
      );
    }
    if (data.containsKey('zaehler_id')) {
      context.handle(
        _zaehlerIdMeta,
        zaehlerId.isAcceptableOrUnknown(data['zaehler_id']!, _zaehlerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_zaehlerIdMeta);
    }
    if (data.containsKey('datum')) {
      context.handle(
        _datumMeta,
        datum.isAcceptableOrUnknown(data['datum']!, _datumMeta),
      );
    } else if (isInserting) {
      context.missing(_datumMeta);
    }
    if (data.containsKey('stand')) {
      context.handle(
        _standMeta,
        stand.isAcceptableOrUnknown(data['stand']!, _standMeta),
      );
    } else if (isInserting) {
      context.missing(_standMeta);
    }
    if (data.containsKey('notiz')) {
      context.handle(
        _notizMeta,
        notiz.isAcceptableOrUnknown(data['notiz']!, _notizMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ablesung map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ablesung(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      geaendertAm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}geaendert_am'],
      )!,
      geloescht: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}geloescht'],
      )!,
      ungesendet: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ungesendet'],
      )!,
      zaehlerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zaehler_id'],
      )!,
      datum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}datum'],
      )!,
      stand: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stand'],
      )!,
      notiz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notiz'],
      )!,
    );
  }

  @override
  $AblesungenTable createAlias(String alias) {
    return $AblesungenTable(attachedDatabase, alias);
  }
}

class Ablesung extends DataClass implements Insertable<Ablesung> {
  final String id;

  /// Zeitpunkt der letzten Änderung (ms seit 1970). Bei Konflikten gewinnt
  /// der neuere Stand.
  final int geaendertAm;

  /// Gelöscht wird nur weich, damit die Löschung auch synchronisiert wird.
  final bool geloescht;

  /// Lokal geändert und noch nicht zum Server übertragen.
  final bool ungesendet;
  final String zaehlerId;

  /// `JJJJ-MM-TT`
  final String datum;
  final double stand;
  final String notiz;
  const Ablesung({
    required this.id,
    required this.geaendertAm,
    required this.geloescht,
    required this.ungesendet,
    required this.zaehlerId,
    required this.datum,
    required this.stand,
    required this.notiz,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['geaendert_am'] = Variable<int>(geaendertAm);
    map['geloescht'] = Variable<bool>(geloescht);
    map['ungesendet'] = Variable<bool>(ungesendet);
    map['zaehler_id'] = Variable<String>(zaehlerId);
    map['datum'] = Variable<String>(datum);
    map['stand'] = Variable<double>(stand);
    map['notiz'] = Variable<String>(notiz);
    return map;
  }

  AblesungenCompanion toCompanion(bool nullToAbsent) {
    return AblesungenCompanion(
      id: Value(id),
      geaendertAm: Value(geaendertAm),
      geloescht: Value(geloescht),
      ungesendet: Value(ungesendet),
      zaehlerId: Value(zaehlerId),
      datum: Value(datum),
      stand: Value(stand),
      notiz: Value(notiz),
    );
  }

  factory Ablesung.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ablesung(
      id: serializer.fromJson<String>(json['id']),
      geaendertAm: serializer.fromJson<int>(json['geaendertAm']),
      geloescht: serializer.fromJson<bool>(json['geloescht']),
      ungesendet: serializer.fromJson<bool>(json['ungesendet']),
      zaehlerId: serializer.fromJson<String>(json['zaehlerId']),
      datum: serializer.fromJson<String>(json['datum']),
      stand: serializer.fromJson<double>(json['stand']),
      notiz: serializer.fromJson<String>(json['notiz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'geaendertAm': serializer.toJson<int>(geaendertAm),
      'geloescht': serializer.toJson<bool>(geloescht),
      'ungesendet': serializer.toJson<bool>(ungesendet),
      'zaehlerId': serializer.toJson<String>(zaehlerId),
      'datum': serializer.toJson<String>(datum),
      'stand': serializer.toJson<double>(stand),
      'notiz': serializer.toJson<String>(notiz),
    };
  }

  Ablesung copyWith({
    String? id,
    int? geaendertAm,
    bool? geloescht,
    bool? ungesendet,
    String? zaehlerId,
    String? datum,
    double? stand,
    String? notiz,
  }) => Ablesung(
    id: id ?? this.id,
    geaendertAm: geaendertAm ?? this.geaendertAm,
    geloescht: geloescht ?? this.geloescht,
    ungesendet: ungesendet ?? this.ungesendet,
    zaehlerId: zaehlerId ?? this.zaehlerId,
    datum: datum ?? this.datum,
    stand: stand ?? this.stand,
    notiz: notiz ?? this.notiz,
  );
  Ablesung copyWithCompanion(AblesungenCompanion data) {
    return Ablesung(
      id: data.id.present ? data.id.value : this.id,
      geaendertAm: data.geaendertAm.present
          ? data.geaendertAm.value
          : this.geaendertAm,
      geloescht: data.geloescht.present ? data.geloescht.value : this.geloescht,
      ungesendet: data.ungesendet.present
          ? data.ungesendet.value
          : this.ungesendet,
      zaehlerId: data.zaehlerId.present ? data.zaehlerId.value : this.zaehlerId,
      datum: data.datum.present ? data.datum.value : this.datum,
      stand: data.stand.present ? data.stand.value : this.stand,
      notiz: data.notiz.present ? data.notiz.value : this.notiz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ablesung(')
          ..write('id: $id, ')
          ..write('geaendertAm: $geaendertAm, ')
          ..write('geloescht: $geloescht, ')
          ..write('ungesendet: $ungesendet, ')
          ..write('zaehlerId: $zaehlerId, ')
          ..write('datum: $datum, ')
          ..write('stand: $stand, ')
          ..write('notiz: $notiz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    geaendertAm,
    geloescht,
    ungesendet,
    zaehlerId,
    datum,
    stand,
    notiz,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ablesung &&
          other.id == this.id &&
          other.geaendertAm == this.geaendertAm &&
          other.geloescht == this.geloescht &&
          other.ungesendet == this.ungesendet &&
          other.zaehlerId == this.zaehlerId &&
          other.datum == this.datum &&
          other.stand == this.stand &&
          other.notiz == this.notiz);
}

class AblesungenCompanion extends UpdateCompanion<Ablesung> {
  final Value<String> id;
  final Value<int> geaendertAm;
  final Value<bool> geloescht;
  final Value<bool> ungesendet;
  final Value<String> zaehlerId;
  final Value<String> datum;
  final Value<double> stand;
  final Value<String> notiz;
  final Value<int> rowid;
  const AblesungenCompanion({
    this.id = const Value.absent(),
    this.geaendertAm = const Value.absent(),
    this.geloescht = const Value.absent(),
    this.ungesendet = const Value.absent(),
    this.zaehlerId = const Value.absent(),
    this.datum = const Value.absent(),
    this.stand = const Value.absent(),
    this.notiz = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AblesungenCompanion.insert({
    required String id,
    required int geaendertAm,
    this.geloescht = const Value.absent(),
    this.ungesendet = const Value.absent(),
    required String zaehlerId,
    required String datum,
    required double stand,
    this.notiz = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       geaendertAm = Value(geaendertAm),
       zaehlerId = Value(zaehlerId),
       datum = Value(datum),
       stand = Value(stand);
  static Insertable<Ablesung> custom({
    Expression<String>? id,
    Expression<int>? geaendertAm,
    Expression<bool>? geloescht,
    Expression<bool>? ungesendet,
    Expression<String>? zaehlerId,
    Expression<String>? datum,
    Expression<double>? stand,
    Expression<String>? notiz,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (geaendertAm != null) 'geaendert_am': geaendertAm,
      if (geloescht != null) 'geloescht': geloescht,
      if (ungesendet != null) 'ungesendet': ungesendet,
      if (zaehlerId != null) 'zaehler_id': zaehlerId,
      if (datum != null) 'datum': datum,
      if (stand != null) 'stand': stand,
      if (notiz != null) 'notiz': notiz,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AblesungenCompanion copyWith({
    Value<String>? id,
    Value<int>? geaendertAm,
    Value<bool>? geloescht,
    Value<bool>? ungesendet,
    Value<String>? zaehlerId,
    Value<String>? datum,
    Value<double>? stand,
    Value<String>? notiz,
    Value<int>? rowid,
  }) {
    return AblesungenCompanion(
      id: id ?? this.id,
      geaendertAm: geaendertAm ?? this.geaendertAm,
      geloescht: geloescht ?? this.geloescht,
      ungesendet: ungesendet ?? this.ungesendet,
      zaehlerId: zaehlerId ?? this.zaehlerId,
      datum: datum ?? this.datum,
      stand: stand ?? this.stand,
      notiz: notiz ?? this.notiz,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (geaendertAm.present) {
      map['geaendert_am'] = Variable<int>(geaendertAm.value);
    }
    if (geloescht.present) {
      map['geloescht'] = Variable<bool>(geloescht.value);
    }
    if (ungesendet.present) {
      map['ungesendet'] = Variable<bool>(ungesendet.value);
    }
    if (zaehlerId.present) {
      map['zaehler_id'] = Variable<String>(zaehlerId.value);
    }
    if (datum.present) {
      map['datum'] = Variable<String>(datum.value);
    }
    if (stand.present) {
      map['stand'] = Variable<double>(stand.value);
    }
    if (notiz.present) {
      map['notiz'] = Variable<String>(notiz.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AblesungenCompanion(')
          ..write('id: $id, ')
          ..write('geaendertAm: $geaendertAm, ')
          ..write('geloescht: $geloescht, ')
          ..write('ungesendet: $ungesendet, ')
          ..write('zaehlerId: $zaehlerId, ')
          ..write('datum: $datum, ')
          ..write('stand: $stand, ')
          ..write('notiz: $notiz, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatusTable extends SyncStatus
    with TableInfo<$SyncStatusTable, SyncStatusData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatusTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _schluesselMeta = const VerificationMeta(
    'schluessel',
  );
  @override
  late final GeneratedColumn<String> schluessel = GeneratedColumn<String>(
    'schluessel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wertMeta = const VerificationMeta('wert');
  @override
  late final GeneratedColumn<String> wert = GeneratedColumn<String>(
    'wert',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [schluessel, wert];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_status';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStatusData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('schluessel')) {
      context.handle(
        _schluesselMeta,
        schluessel.isAcceptableOrUnknown(data['schluessel']!, _schluesselMeta),
      );
    } else if (isInserting) {
      context.missing(_schluesselMeta);
    }
    if (data.containsKey('wert')) {
      context.handle(
        _wertMeta,
        wert.isAcceptableOrUnknown(data['wert']!, _wertMeta),
      );
    } else if (isInserting) {
      context.missing(_wertMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {schluessel};
  @override
  SyncStatusData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStatusData(
      schluessel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schluessel'],
      )!,
      wert: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wert'],
      )!,
    );
  }

  @override
  $SyncStatusTable createAlias(String alias) {
    return $SyncStatusTable(attachedDatabase, alias);
  }
}

class SyncStatusData extends DataClass implements Insertable<SyncStatusData> {
  final String schluessel;
  final String wert;
  const SyncStatusData({required this.schluessel, required this.wert});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['schluessel'] = Variable<String>(schluessel);
    map['wert'] = Variable<String>(wert);
    return map;
  }

  SyncStatusCompanion toCompanion(bool nullToAbsent) {
    return SyncStatusCompanion(
      schluessel: Value(schluessel),
      wert: Value(wert),
    );
  }

  factory SyncStatusData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStatusData(
      schluessel: serializer.fromJson<String>(json['schluessel']),
      wert: serializer.fromJson<String>(json['wert']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'schluessel': serializer.toJson<String>(schluessel),
      'wert': serializer.toJson<String>(wert),
    };
  }

  SyncStatusData copyWith({String? schluessel, String? wert}) => SyncStatusData(
    schluessel: schluessel ?? this.schluessel,
    wert: wert ?? this.wert,
  );
  SyncStatusData copyWithCompanion(SyncStatusCompanion data) {
    return SyncStatusData(
      schluessel: data.schluessel.present
          ? data.schluessel.value
          : this.schluessel,
      wert: data.wert.present ? data.wert.value : this.wert,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatusData(')
          ..write('schluessel: $schluessel, ')
          ..write('wert: $wert')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(schluessel, wert);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStatusData &&
          other.schluessel == this.schluessel &&
          other.wert == this.wert);
}

class SyncStatusCompanion extends UpdateCompanion<SyncStatusData> {
  final Value<String> schluessel;
  final Value<String> wert;
  final Value<int> rowid;
  const SyncStatusCompanion({
    this.schluessel = const Value.absent(),
    this.wert = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatusCompanion.insert({
    required String schluessel,
    required String wert,
    this.rowid = const Value.absent(),
  }) : schluessel = Value(schluessel),
       wert = Value(wert);
  static Insertable<SyncStatusData> custom({
    Expression<String>? schluessel,
    Expression<String>? wert,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (schluessel != null) 'schluessel': schluessel,
      if (wert != null) 'wert': wert,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatusCompanion copyWith({
    Value<String>? schluessel,
    Value<String>? wert,
    Value<int>? rowid,
  }) {
    return SyncStatusCompanion(
      schluessel: schluessel ?? this.schluessel,
      wert: wert ?? this.wert,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (schluessel.present) {
      map['schluessel'] = Variable<String>(schluessel.value);
    }
    if (wert.present) {
      map['wert'] = Variable<String>(wert.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatusCompanion(')
          ..write('schluessel: $schluessel, ')
          ..write('wert: $wert, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$HauslogDatenbank extends GeneratedDatabase {
  _$HauslogDatenbank(QueryExecutor e) : super(e);
  $HauslogDatenbankManager get managers => $HauslogDatenbankManager(this);
  late final $ZaehlerTabelleTable zaehlerTabelle = $ZaehlerTabelleTable(this);
  late final $AblesungenTable ablesungen = $AblesungenTable(this);
  late final $SyncStatusTable syncStatus = $SyncStatusTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    zaehlerTabelle,
    ablesungen,
    syncStatus,
  ];
}

typedef $$ZaehlerTabelleTableCreateCompanionBuilder =
    ZaehlerTabelleCompanion Function({
      required String id,
      required int geaendertAm,
      Value<bool> geloescht,
      Value<bool> ungesendet,
      required String name,
      required String art,
      required String einheit,
      Value<String> zaehlernummer,
      Value<String> notiz,
      Value<int> rowid,
    });
typedef $$ZaehlerTabelleTableUpdateCompanionBuilder =
    ZaehlerTabelleCompanion Function({
      Value<String> id,
      Value<int> geaendertAm,
      Value<bool> geloescht,
      Value<bool> ungesendet,
      Value<String> name,
      Value<String> art,
      Value<String> einheit,
      Value<String> zaehlernummer,
      Value<String> notiz,
      Value<int> rowid,
    });

class $$ZaehlerTabelleTableFilterComposer
    extends Composer<_$HauslogDatenbank, $ZaehlerTabelleTable> {
  $$ZaehlerTabelleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get geaendertAm => $composableBuilder(
    column: $table.geaendertAm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get geloescht => $composableBuilder(
    column: $table.geloescht,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ungesendet => $composableBuilder(
    column: $table.ungesendet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get art => $composableBuilder(
    column: $table.art,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get einheit => $composableBuilder(
    column: $table.einheit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zaehlernummer => $composableBuilder(
    column: $table.zaehlernummer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notiz => $composableBuilder(
    column: $table.notiz,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ZaehlerTabelleTableOrderingComposer
    extends Composer<_$HauslogDatenbank, $ZaehlerTabelleTable> {
  $$ZaehlerTabelleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get geaendertAm => $composableBuilder(
    column: $table.geaendertAm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get geloescht => $composableBuilder(
    column: $table.geloescht,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ungesendet => $composableBuilder(
    column: $table.ungesendet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get art => $composableBuilder(
    column: $table.art,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get einheit => $composableBuilder(
    column: $table.einheit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zaehlernummer => $composableBuilder(
    column: $table.zaehlernummer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notiz => $composableBuilder(
    column: $table.notiz,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ZaehlerTabelleTableAnnotationComposer
    extends Composer<_$HauslogDatenbank, $ZaehlerTabelleTable> {
  $$ZaehlerTabelleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get geaendertAm => $composableBuilder(
    column: $table.geaendertAm,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get geloescht =>
      $composableBuilder(column: $table.geloescht, builder: (column) => column);

  GeneratedColumn<bool> get ungesendet => $composableBuilder(
    column: $table.ungesendet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get art =>
      $composableBuilder(column: $table.art, builder: (column) => column);

  GeneratedColumn<String> get einheit =>
      $composableBuilder(column: $table.einheit, builder: (column) => column);

  GeneratedColumn<String> get zaehlernummer => $composableBuilder(
    column: $table.zaehlernummer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notiz =>
      $composableBuilder(column: $table.notiz, builder: (column) => column);
}

class $$ZaehlerTabelleTableTableManager
    extends
        RootTableManager<
          _$HauslogDatenbank,
          $ZaehlerTabelleTable,
          Zaehler,
          $$ZaehlerTabelleTableFilterComposer,
          $$ZaehlerTabelleTableOrderingComposer,
          $$ZaehlerTabelleTableAnnotationComposer,
          $$ZaehlerTabelleTableCreateCompanionBuilder,
          $$ZaehlerTabelleTableUpdateCompanionBuilder,
          (
            Zaehler,
            BaseReferences<_$HauslogDatenbank, $ZaehlerTabelleTable, Zaehler>,
          ),
          Zaehler,
          PrefetchHooks Function()
        > {
  $$ZaehlerTabelleTableTableManager(
    _$HauslogDatenbank db,
    $ZaehlerTabelleTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ZaehlerTabelleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ZaehlerTabelleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ZaehlerTabelleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> geaendertAm = const Value.absent(),
                Value<bool> geloescht = const Value.absent(),
                Value<bool> ungesendet = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> art = const Value.absent(),
                Value<String> einheit = const Value.absent(),
                Value<String> zaehlernummer = const Value.absent(),
                Value<String> notiz = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ZaehlerTabelleCompanion(
                id: id,
                geaendertAm: geaendertAm,
                geloescht: geloescht,
                ungesendet: ungesendet,
                name: name,
                art: art,
                einheit: einheit,
                zaehlernummer: zaehlernummer,
                notiz: notiz,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int geaendertAm,
                Value<bool> geloescht = const Value.absent(),
                Value<bool> ungesendet = const Value.absent(),
                required String name,
                required String art,
                required String einheit,
                Value<String> zaehlernummer = const Value.absent(),
                Value<String> notiz = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ZaehlerTabelleCompanion.insert(
                id: id,
                geaendertAm: geaendertAm,
                geloescht: geloescht,
                ungesendet: ungesendet,
                name: name,
                art: art,
                einheit: einheit,
                zaehlernummer: zaehlernummer,
                notiz: notiz,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ZaehlerTabelleTable, Zaehler>(table),
                  BaseReferences<
                    _$HauslogDatenbank,
                    $ZaehlerTabelleTable,
                    Zaehler
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ZaehlerTabelleTableProcessedTableManager =
    ProcessedTableManager<
      _$HauslogDatenbank,
      $ZaehlerTabelleTable,
      Zaehler,
      $$ZaehlerTabelleTableFilterComposer,
      $$ZaehlerTabelleTableOrderingComposer,
      $$ZaehlerTabelleTableAnnotationComposer,
      $$ZaehlerTabelleTableCreateCompanionBuilder,
      $$ZaehlerTabelleTableUpdateCompanionBuilder,
      (
        Zaehler,
        BaseReferences<_$HauslogDatenbank, $ZaehlerTabelleTable, Zaehler>,
      ),
      Zaehler,
      PrefetchHooks Function()
    >;
typedef $$AblesungenTableCreateCompanionBuilder = AblesungenCompanion Function({
  required String id,
  required int geaendertAm,
  Value<bool> geloescht,
  Value<bool> ungesendet,
  required String zaehlerId,
  required String datum,
  required double stand,
  Value<String> notiz,
  Value<int> rowid,
});
typedef $$AblesungenTableUpdateCompanionBuilder = AblesungenCompanion Function({
  Value<String> id,
  Value<int> geaendertAm,
  Value<bool> geloescht,
  Value<bool> ungesendet,
  Value<String> zaehlerId,
  Value<String> datum,
  Value<double> stand,
  Value<String> notiz,
  Value<int> rowid,
});

class $$AblesungenTableFilterComposer
    extends Composer<_$HauslogDatenbank, $AblesungenTable> {
  $$AblesungenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get geaendertAm => $composableBuilder(
    column: $table.geaendertAm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get geloescht => $composableBuilder(
    column: $table.geloescht,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ungesendet => $composableBuilder(
    column: $table.ungesendet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zaehlerId => $composableBuilder(
    column: $table.zaehlerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datum => $composableBuilder(
    column: $table.datum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stand => $composableBuilder(
    column: $table.stand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notiz => $composableBuilder(
    column: $table.notiz,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AblesungenTableOrderingComposer
    extends Composer<_$HauslogDatenbank, $AblesungenTable> {
  $$AblesungenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get geaendertAm => $composableBuilder(
    column: $table.geaendertAm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get geloescht => $composableBuilder(
    column: $table.geloescht,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ungesendet => $composableBuilder(
    column: $table.ungesendet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zaehlerId => $composableBuilder(
    column: $table.zaehlerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datum => $composableBuilder(
    column: $table.datum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stand => $composableBuilder(
    column: $table.stand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notiz => $composableBuilder(
    column: $table.notiz,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AblesungenTableAnnotationComposer
    extends Composer<_$HauslogDatenbank, $AblesungenTable> {
  $$AblesungenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get geaendertAm => $composableBuilder(
    column: $table.geaendertAm,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get geloescht =>
      $composableBuilder(column: $table.geloescht, builder: (column) => column);

  GeneratedColumn<bool> get ungesendet => $composableBuilder(
    column: $table.ungesendet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zaehlerId =>
      $composableBuilder(column: $table.zaehlerId, builder: (column) => column);

  GeneratedColumn<String> get datum =>
      $composableBuilder(column: $table.datum, builder: (column) => column);

  GeneratedColumn<double> get stand =>
      $composableBuilder(column: $table.stand, builder: (column) => column);

  GeneratedColumn<String> get notiz =>
      $composableBuilder(column: $table.notiz, builder: (column) => column);
}

class $$AblesungenTableTableManager
    extends
        RootTableManager<
          _$HauslogDatenbank,
          $AblesungenTable,
          Ablesung,
          $$AblesungenTableFilterComposer,
          $$AblesungenTableOrderingComposer,
          $$AblesungenTableAnnotationComposer,
          $$AblesungenTableCreateCompanionBuilder,
          $$AblesungenTableUpdateCompanionBuilder,
          (
            Ablesung,
            BaseReferences<_$HauslogDatenbank, $AblesungenTable, Ablesung>,
          ),
          Ablesung,
          PrefetchHooks Function()
        > {
  $$AblesungenTableTableManager(_$HauslogDatenbank db, $AblesungenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AblesungenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AblesungenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AblesungenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> geaendertAm = const Value.absent(),
                Value<bool> geloescht = const Value.absent(),
                Value<bool> ungesendet = const Value.absent(),
                Value<String> zaehlerId = const Value.absent(),
                Value<String> datum = const Value.absent(),
                Value<double> stand = const Value.absent(),
                Value<String> notiz = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AblesungenCompanion(
                id: id,
                geaendertAm: geaendertAm,
                geloescht: geloescht,
                ungesendet: ungesendet,
                zaehlerId: zaehlerId,
                datum: datum,
                stand: stand,
                notiz: notiz,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int geaendertAm,
                Value<bool> geloescht = const Value.absent(),
                Value<bool> ungesendet = const Value.absent(),
                required String zaehlerId,
                required String datum,
                required double stand,
                Value<String> notiz = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AblesungenCompanion.insert(
                id: id,
                geaendertAm: geaendertAm,
                geloescht: geloescht,
                ungesendet: ungesendet,
                zaehlerId: zaehlerId,
                datum: datum,
                stand: stand,
                notiz: notiz,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AblesungenTable, Ablesung>(table),
                  BaseReferences<
                    _$HauslogDatenbank,
                    $AblesungenTable,
                    Ablesung
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AblesungenTableProcessedTableManager =
    ProcessedTableManager<
      _$HauslogDatenbank,
      $AblesungenTable,
      Ablesung,
      $$AblesungenTableFilterComposer,
      $$AblesungenTableOrderingComposer,
      $$AblesungenTableAnnotationComposer,
      $$AblesungenTableCreateCompanionBuilder,
      $$AblesungenTableUpdateCompanionBuilder,
      (
        Ablesung,
        BaseReferences<_$HauslogDatenbank, $AblesungenTable, Ablesung>,
      ),
      Ablesung,
      PrefetchHooks Function()
    >;
typedef $$SyncStatusTableCreateCompanionBuilder = SyncStatusCompanion Function({
  required String schluessel,
  required String wert,
  Value<int> rowid,
});
typedef $$SyncStatusTableUpdateCompanionBuilder = SyncStatusCompanion Function({
  Value<String> schluessel,
  Value<String> wert,
  Value<int> rowid,
});

class $$SyncStatusTableFilterComposer
    extends Composer<_$HauslogDatenbank, $SyncStatusTable> {
  $$SyncStatusTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get schluessel => $composableBuilder(
    column: $table.schluessel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wert => $composableBuilder(
    column: $table.wert,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatusTableOrderingComposer
    extends Composer<_$HauslogDatenbank, $SyncStatusTable> {
  $$SyncStatusTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get schluessel => $composableBuilder(
    column: $table.schluessel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wert => $composableBuilder(
    column: $table.wert,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatusTableAnnotationComposer
    extends Composer<_$HauslogDatenbank, $SyncStatusTable> {
  $$SyncStatusTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get schluessel => $composableBuilder(
    column: $table.schluessel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wert =>
      $composableBuilder(column: $table.wert, builder: (column) => column);
}

class $$SyncStatusTableTableManager
    extends
        RootTableManager<
          _$HauslogDatenbank,
          $SyncStatusTable,
          SyncStatusData,
          $$SyncStatusTableFilterComposer,
          $$SyncStatusTableOrderingComposer,
          $$SyncStatusTableAnnotationComposer,
          $$SyncStatusTableCreateCompanionBuilder,
          $$SyncStatusTableUpdateCompanionBuilder,
          (
            SyncStatusData,
            BaseReferences<
              _$HauslogDatenbank,
              $SyncStatusTable,
              SyncStatusData
            >,
          ),
          SyncStatusData,
          PrefetchHooks Function()
        > {
  $$SyncStatusTableTableManager(_$HauslogDatenbank db, $SyncStatusTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatusTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatusTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatusTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> schluessel = const Value.absent(),
                Value<String> wert = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatusCompanion(
                schluessel: schluessel,
                wert: wert,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String schluessel,
                required String wert,
                Value<int> rowid = const Value.absent(),
              }) => SyncStatusCompanion.insert(
                schluessel: schluessel,
                wert: wert,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStatusTable, SyncStatusData>(table),
                  BaseReferences<
                    _$HauslogDatenbank,
                    $SyncStatusTable,
                    SyncStatusData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatusTableProcessedTableManager =
    ProcessedTableManager<
      _$HauslogDatenbank,
      $SyncStatusTable,
      SyncStatusData,
      $$SyncStatusTableFilterComposer,
      $$SyncStatusTableOrderingComposer,
      $$SyncStatusTableAnnotationComposer,
      $$SyncStatusTableCreateCompanionBuilder,
      $$SyncStatusTableUpdateCompanionBuilder,
      (
        SyncStatusData,
        BaseReferences<_$HauslogDatenbank, $SyncStatusTable, SyncStatusData>,
      ),
      SyncStatusData,
      PrefetchHooks Function()
    >;

class $HauslogDatenbankManager {
  final _$HauslogDatenbank _db;
  $HauslogDatenbankManager(this._db);
  $$ZaehlerTabelleTableTableManager get zaehlerTabelle =>
      $$ZaehlerTabelleTableTableManager(_db, _db.zaehlerTabelle);
  $$AblesungenTableTableManager get ablesungen =>
      $$AblesungenTableTableManager(_db, _db.ablesungen);
  $$SyncStatusTableTableManager get syncStatus =>
      $$SyncStatusTableTableManager(_db, _db.syncStatus);
}

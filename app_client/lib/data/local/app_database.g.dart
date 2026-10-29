// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalCapturesTable extends LocalCaptures
    with TableInfo<$LocalCapturesTable, LocalCapture> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCapturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingSessionIdMeta = const VerificationMeta(
    'readingSessionId',
  );
  @override
  late final GeneratedColumn<String> readingSessionId = GeneratedColumn<String>(
    'reading_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _captureTypeMeta = const VerificationMeta(
    'captureType',
  );
  @override
  late final GeneratedColumn<String> captureType = GeneratedColumn<String>(
    'capture_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processingStatusMeta = const VerificationMeta(
    'processingStatus',
  );
  @override
  late final GeneratedColumn<String> processingStatus = GeneratedColumn<String>(
    'processing_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LOCAL_ONLY'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING_SYNC'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageRangeMeta = const VerificationMeta(
    'pageRange',
  );
  @override
  late final GeneratedColumn<String> pageRange = GeneratedColumn<String>(
    'page_range',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userTagsJsonMeta = const VerificationMeta(
    'userTagsJson',
  );
  @override
  late final GeneratedColumn<String> userTagsJson = GeneratedColumn<String>(
    'user_tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _extractedMarkdownMeta = const VerificationMeta(
    'extractedMarkdown',
  );
  @override
  late final GeneratedColumn<String> extractedMarkdown =
      GeneratedColumn<String>(
        'extracted_markdown',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptTextMeta = const VerificationMeta(
    'transcriptText',
  );
  @override
  late final GeneratedColumn<String> transcriptText = GeneratedColumn<String>(
    'transcript_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voiceDistillationJsonMeta =
      const VerificationMeta('voiceDistillationJson');
  @override
  late final GeneratedColumn<String> voiceDistillationJson =
      GeneratedColumn<String>(
        'voice_distillation_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _autoTagsJsonMeta = const VerificationMeta(
    'autoTagsJson',
  );
  @override
  late final GeneratedColumn<String> autoTagsJson = GeneratedColumn<String>(
    'auto_tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _mediaAssetsJsonMeta = const VerificationMeta(
    'mediaAssetsJson',
  );
  @override
  late final GeneratedColumn<String> mediaAssetsJson = GeneratedColumn<String>(
    'media_assets_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _localMediaPathMeta = const VerificationMeta(
    'localMediaPath',
  );
  @override
  late final GeneratedColumn<String> localMediaPath = GeneratedColumn<String>(
    'local_media_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTriageReviewedMeta = const VerificationMeta(
    'isTriageReviewed',
  );
  @override
  late final GeneratedColumn<bool> isTriageReviewed = GeneratedColumn<bool>(
    'is_triage_reviewed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_triage_reviewed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    readingSessionId,
    captureType,
    processingStatus,
    syncStatus,
    title,
    rawText,
    sourceUrl,
    pageRange,
    userTagsJson,
    extractedMarkdown,
    ocrText,
    transcriptText,
    voiceDistillationJson,
    autoTagsJson,
    mediaAssetsJson,
    localMediaPath,
    capturedAt,
    updatedAt,
    isTriageReviewed,
    isArchived,
    isDeleted,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_captures';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCapture> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reading_session_id')) {
      context.handle(
        _readingSessionIdMeta,
        readingSessionId.isAcceptableOrUnknown(
          data['reading_session_id']!,
          _readingSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('capture_type')) {
      context.handle(
        _captureTypeMeta,
        captureType.isAcceptableOrUnknown(
          data['capture_type']!,
          _captureTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_captureTypeMeta);
    }
    if (data.containsKey('processing_status')) {
      context.handle(
        _processingStatusMeta,
        processingStatus.isAcceptableOrUnknown(
          data['processing_status']!,
          _processingStatusMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('page_range')) {
      context.handle(
        _pageRangeMeta,
        pageRange.isAcceptableOrUnknown(data['page_range']!, _pageRangeMeta),
      );
    }
    if (data.containsKey('user_tags_json')) {
      context.handle(
        _userTagsJsonMeta,
        userTagsJson.isAcceptableOrUnknown(
          data['user_tags_json']!,
          _userTagsJsonMeta,
        ),
      );
    }
    if (data.containsKey('extracted_markdown')) {
      context.handle(
        _extractedMarkdownMeta,
        extractedMarkdown.isAcceptableOrUnknown(
          data['extracted_markdown']!,
          _extractedMarkdownMeta,
        ),
      );
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    }
    if (data.containsKey('transcript_text')) {
      context.handle(
        _transcriptTextMeta,
        transcriptText.isAcceptableOrUnknown(
          data['transcript_text']!,
          _transcriptTextMeta,
        ),
      );
    }
    if (data.containsKey('voice_distillation_json')) {
      context.handle(
        _voiceDistillationJsonMeta,
        voiceDistillationJson.isAcceptableOrUnknown(
          data['voice_distillation_json']!,
          _voiceDistillationJsonMeta,
        ),
      );
    }
    if (data.containsKey('auto_tags_json')) {
      context.handle(
        _autoTagsJsonMeta,
        autoTagsJson.isAcceptableOrUnknown(
          data['auto_tags_json']!,
          _autoTagsJsonMeta,
        ),
      );
    }
    if (data.containsKey('media_assets_json')) {
      context.handle(
        _mediaAssetsJsonMeta,
        mediaAssetsJson.isAcceptableOrUnknown(
          data['media_assets_json']!,
          _mediaAssetsJsonMeta,
        ),
      );
    }
    if (data.containsKey('local_media_path')) {
      context.handle(
        _localMediaPathMeta,
        localMediaPath.isAcceptableOrUnknown(
          data['local_media_path']!,
          _localMediaPathMeta,
        ),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_triage_reviewed')) {
      context.handle(
        _isTriageReviewedMeta,
        isTriageReviewed.isAcceptableOrUnknown(
          data['is_triage_reviewed']!,
          _isTriageReviewedMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCapture map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCapture(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      readingSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_session_id'],
      ),
      captureType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capture_type'],
      )!,
      processingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processing_status'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      pageRange: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_range'],
      ),
      userTagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_tags_json'],
      )!,
      extractedMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_markdown'],
      ),
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      ),
      transcriptText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript_text'],
      ),
      voiceDistillationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_distillation_json'],
      ),
      autoTagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auto_tags_json'],
      )!,
      mediaAssetsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_assets_json'],
      )!,
      localMediaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_media_path'],
      ),
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isTriageReviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_triage_reviewed'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $LocalCapturesTable createAlias(String alias) {
    return $LocalCapturesTable(attachedDatabase, alias);
  }
}

class LocalCapture extends DataClass implements Insertable<LocalCapture> {
  final String id;
  final String? readingSessionId;
  final String captureType;
  final String processingStatus;
  final String syncStatus;
  final String? title;
  final String? rawText;
  final String? sourceUrl;
  final String? pageRange;
  final String userTagsJson;
  final String? extractedMarkdown;
  final String? ocrText;
  final String? transcriptText;
  final String? voiceDistillationJson;
  final String autoTagsJson;
  final String mediaAssetsJson;
  final String? localMediaPath;
  final DateTime capturedAt;
  final DateTime updatedAt;
  final bool isTriageReviewed;
  final bool isArchived;
  final bool isDeleted;
  final int syncVersion;
  const LocalCapture({
    required this.id,
    this.readingSessionId,
    required this.captureType,
    required this.processingStatus,
    required this.syncStatus,
    this.title,
    this.rawText,
    this.sourceUrl,
    this.pageRange,
    required this.userTagsJson,
    this.extractedMarkdown,
    this.ocrText,
    this.transcriptText,
    this.voiceDistillationJson,
    required this.autoTagsJson,
    required this.mediaAssetsJson,
    this.localMediaPath,
    required this.capturedAt,
    required this.updatedAt,
    required this.isTriageReviewed,
    required this.isArchived,
    required this.isDeleted,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || readingSessionId != null) {
      map['reading_session_id'] = Variable<String>(readingSessionId);
    }
    map['capture_type'] = Variable<String>(captureType);
    map['processing_status'] = Variable<String>(processingStatus);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || rawText != null) {
      map['raw_text'] = Variable<String>(rawText);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || pageRange != null) {
      map['page_range'] = Variable<String>(pageRange);
    }
    map['user_tags_json'] = Variable<String>(userTagsJson);
    if (!nullToAbsent || extractedMarkdown != null) {
      map['extracted_markdown'] = Variable<String>(extractedMarkdown);
    }
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    if (!nullToAbsent || transcriptText != null) {
      map['transcript_text'] = Variable<String>(transcriptText);
    }
    if (!nullToAbsent || voiceDistillationJson != null) {
      map['voice_distillation_json'] = Variable<String>(voiceDistillationJson);
    }
    map['auto_tags_json'] = Variable<String>(autoTagsJson);
    map['media_assets_json'] = Variable<String>(mediaAssetsJson);
    if (!nullToAbsent || localMediaPath != null) {
      map['local_media_path'] = Variable<String>(localMediaPath);
    }
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_triage_reviewed'] = Variable<bool>(isTriageReviewed);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  LocalCapturesCompanion toCompanion(bool nullToAbsent) {
    return LocalCapturesCompanion(
      id: Value(id),
      readingSessionId: readingSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(readingSessionId),
      captureType: Value(captureType),
      processingStatus: Value(processingStatus),
      syncStatus: Value(syncStatus),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      rawText: rawText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawText),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      pageRange: pageRange == null && nullToAbsent
          ? const Value.absent()
          : Value(pageRange),
      userTagsJson: Value(userTagsJson),
      extractedMarkdown: extractedMarkdown == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedMarkdown),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      transcriptText: transcriptText == null && nullToAbsent
          ? const Value.absent()
          : Value(transcriptText),
      voiceDistillationJson: voiceDistillationJson == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceDistillationJson),
      autoTagsJson: Value(autoTagsJson),
      mediaAssetsJson: Value(mediaAssetsJson),
      localMediaPath: localMediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localMediaPath),
      capturedAt: Value(capturedAt),
      updatedAt: Value(updatedAt),
      isTriageReviewed: Value(isTriageReviewed),
      isArchived: Value(isArchived),
      isDeleted: Value(isDeleted),
      syncVersion: Value(syncVersion),
    );
  }

  factory LocalCapture.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCapture(
      id: serializer.fromJson<String>(json['id']),
      readingSessionId: serializer.fromJson<String?>(json['readingSessionId']),
      captureType: serializer.fromJson<String>(json['captureType']),
      processingStatus: serializer.fromJson<String>(json['processingStatus']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      title: serializer.fromJson<String?>(json['title']),
      rawText: serializer.fromJson<String?>(json['rawText']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      pageRange: serializer.fromJson<String?>(json['pageRange']),
      userTagsJson: serializer.fromJson<String>(json['userTagsJson']),
      extractedMarkdown: serializer.fromJson<String?>(
        json['extractedMarkdown'],
      ),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      transcriptText: serializer.fromJson<String?>(json['transcriptText']),
      voiceDistillationJson: serializer.fromJson<String?>(
        json['voiceDistillationJson'],
      ),
      autoTagsJson: serializer.fromJson<String>(json['autoTagsJson']),
      mediaAssetsJson: serializer.fromJson<String>(json['mediaAssetsJson']),
      localMediaPath: serializer.fromJson<String?>(json['localMediaPath']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isTriageReviewed: serializer.fromJson<bool>(json['isTriageReviewed']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'readingSessionId': serializer.toJson<String?>(readingSessionId),
      'captureType': serializer.toJson<String>(captureType),
      'processingStatus': serializer.toJson<String>(processingStatus),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'title': serializer.toJson<String?>(title),
      'rawText': serializer.toJson<String?>(rawText),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'pageRange': serializer.toJson<String?>(pageRange),
      'userTagsJson': serializer.toJson<String>(userTagsJson),
      'extractedMarkdown': serializer.toJson<String?>(extractedMarkdown),
      'ocrText': serializer.toJson<String?>(ocrText),
      'transcriptText': serializer.toJson<String?>(transcriptText),
      'voiceDistillationJson': serializer.toJson<String?>(
        voiceDistillationJson,
      ),
      'autoTagsJson': serializer.toJson<String>(autoTagsJson),
      'mediaAssetsJson': serializer.toJson<String>(mediaAssetsJson),
      'localMediaPath': serializer.toJson<String?>(localMediaPath),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isTriageReviewed': serializer.toJson<bool>(isTriageReviewed),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  LocalCapture copyWith({
    String? id,
    Value<String?> readingSessionId = const Value.absent(),
    String? captureType,
    String? processingStatus,
    String? syncStatus,
    Value<String?> title = const Value.absent(),
    Value<String?> rawText = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
    Value<String?> pageRange = const Value.absent(),
    String? userTagsJson,
    Value<String?> extractedMarkdown = const Value.absent(),
    Value<String?> ocrText = const Value.absent(),
    Value<String?> transcriptText = const Value.absent(),
    Value<String?> voiceDistillationJson = const Value.absent(),
    String? autoTagsJson,
    String? mediaAssetsJson,
    Value<String?> localMediaPath = const Value.absent(),
    DateTime? capturedAt,
    DateTime? updatedAt,
    bool? isTriageReviewed,
    bool? isArchived,
    bool? isDeleted,
    int? syncVersion,
  }) => LocalCapture(
    id: id ?? this.id,
    readingSessionId: readingSessionId.present
        ? readingSessionId.value
        : this.readingSessionId,
    captureType: captureType ?? this.captureType,
    processingStatus: processingStatus ?? this.processingStatus,
    syncStatus: syncStatus ?? this.syncStatus,
    title: title.present ? title.value : this.title,
    rawText: rawText.present ? rawText.value : this.rawText,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    pageRange: pageRange.present ? pageRange.value : this.pageRange,
    userTagsJson: userTagsJson ?? this.userTagsJson,
    extractedMarkdown: extractedMarkdown.present
        ? extractedMarkdown.value
        : this.extractedMarkdown,
    ocrText: ocrText.present ? ocrText.value : this.ocrText,
    transcriptText: transcriptText.present
        ? transcriptText.value
        : this.transcriptText,
    voiceDistillationJson: voiceDistillationJson.present
        ? voiceDistillationJson.value
        : this.voiceDistillationJson,
    autoTagsJson: autoTagsJson ?? this.autoTagsJson,
    mediaAssetsJson: mediaAssetsJson ?? this.mediaAssetsJson,
    localMediaPath: localMediaPath.present
        ? localMediaPath.value
        : this.localMediaPath,
    capturedAt: capturedAt ?? this.capturedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isTriageReviewed: isTriageReviewed ?? this.isTriageReviewed,
    isArchived: isArchived ?? this.isArchived,
    isDeleted: isDeleted ?? this.isDeleted,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  LocalCapture copyWithCompanion(LocalCapturesCompanion data) {
    return LocalCapture(
      id: data.id.present ? data.id.value : this.id,
      readingSessionId: data.readingSessionId.present
          ? data.readingSessionId.value
          : this.readingSessionId,
      captureType: data.captureType.present
          ? data.captureType.value
          : this.captureType,
      processingStatus: data.processingStatus.present
          ? data.processingStatus.value
          : this.processingStatus,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      title: data.title.present ? data.title.value : this.title,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      pageRange: data.pageRange.present ? data.pageRange.value : this.pageRange,
      userTagsJson: data.userTagsJson.present
          ? data.userTagsJson.value
          : this.userTagsJson,
      extractedMarkdown: data.extractedMarkdown.present
          ? data.extractedMarkdown.value
          : this.extractedMarkdown,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      transcriptText: data.transcriptText.present
          ? data.transcriptText.value
          : this.transcriptText,
      voiceDistillationJson: data.voiceDistillationJson.present
          ? data.voiceDistillationJson.value
          : this.voiceDistillationJson,
      autoTagsJson: data.autoTagsJson.present
          ? data.autoTagsJson.value
          : this.autoTagsJson,
      mediaAssetsJson: data.mediaAssetsJson.present
          ? data.mediaAssetsJson.value
          : this.mediaAssetsJson,
      localMediaPath: data.localMediaPath.present
          ? data.localMediaPath.value
          : this.localMediaPath,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isTriageReviewed: data.isTriageReviewed.present
          ? data.isTriageReviewed.value
          : this.isTriageReviewed,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCapture(')
          ..write('id: $id, ')
          ..write('readingSessionId: $readingSessionId, ')
          ..write('captureType: $captureType, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('title: $title, ')
          ..write('rawText: $rawText, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('pageRange: $pageRange, ')
          ..write('userTagsJson: $userTagsJson, ')
          ..write('extractedMarkdown: $extractedMarkdown, ')
          ..write('ocrText: $ocrText, ')
          ..write('transcriptText: $transcriptText, ')
          ..write('voiceDistillationJson: $voiceDistillationJson, ')
          ..write('autoTagsJson: $autoTagsJson, ')
          ..write('mediaAssetsJson: $mediaAssetsJson, ')
          ..write('localMediaPath: $localMediaPath, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isTriageReviewed: $isTriageReviewed, ')
          ..write('isArchived: $isArchived, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    readingSessionId,
    captureType,
    processingStatus,
    syncStatus,
    title,
    rawText,
    sourceUrl,
    pageRange,
    userTagsJson,
    extractedMarkdown,
    ocrText,
    transcriptText,
    voiceDistillationJson,
    autoTagsJson,
    mediaAssetsJson,
    localMediaPath,
    capturedAt,
    updatedAt,
    isTriageReviewed,
    isArchived,
    isDeleted,
    syncVersion,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCapture &&
          other.id == this.id &&
          other.readingSessionId == this.readingSessionId &&
          other.captureType == this.captureType &&
          other.processingStatus == this.processingStatus &&
          other.syncStatus == this.syncStatus &&
          other.title == this.title &&
          other.rawText == this.rawText &&
          other.sourceUrl == this.sourceUrl &&
          other.pageRange == this.pageRange &&
          other.userTagsJson == this.userTagsJson &&
          other.extractedMarkdown == this.extractedMarkdown &&
          other.ocrText == this.ocrText &&
          other.transcriptText == this.transcriptText &&
          other.voiceDistillationJson == this.voiceDistillationJson &&
          other.autoTagsJson == this.autoTagsJson &&
          other.mediaAssetsJson == this.mediaAssetsJson &&
          other.localMediaPath == this.localMediaPath &&
          other.capturedAt == this.capturedAt &&
          other.updatedAt == this.updatedAt &&
          other.isTriageReviewed == this.isTriageReviewed &&
          other.isArchived == this.isArchived &&
          other.isDeleted == this.isDeleted &&
          other.syncVersion == this.syncVersion);
}

class LocalCapturesCompanion extends UpdateCompanion<LocalCapture> {
  final Value<String> id;
  final Value<String?> readingSessionId;
  final Value<String> captureType;
  final Value<String> processingStatus;
  final Value<String> syncStatus;
  final Value<String?> title;
  final Value<String?> rawText;
  final Value<String?> sourceUrl;
  final Value<String?> pageRange;
  final Value<String> userTagsJson;
  final Value<String?> extractedMarkdown;
  final Value<String?> ocrText;
  final Value<String?> transcriptText;
  final Value<String?> voiceDistillationJson;
  final Value<String> autoTagsJson;
  final Value<String> mediaAssetsJson;
  final Value<String?> localMediaPath;
  final Value<DateTime> capturedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isTriageReviewed;
  final Value<bool> isArchived;
  final Value<bool> isDeleted;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const LocalCapturesCompanion({
    this.id = const Value.absent(),
    this.readingSessionId = const Value.absent(),
    this.captureType = const Value.absent(),
    this.processingStatus = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.title = const Value.absent(),
    this.rawText = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.pageRange = const Value.absent(),
    this.userTagsJson = const Value.absent(),
    this.extractedMarkdown = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.transcriptText = const Value.absent(),
    this.voiceDistillationJson = const Value.absent(),
    this.autoTagsJson = const Value.absent(),
    this.mediaAssetsJson = const Value.absent(),
    this.localMediaPath = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isTriageReviewed = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCapturesCompanion.insert({
    required String id,
    this.readingSessionId = const Value.absent(),
    required String captureType,
    this.processingStatus = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.title = const Value.absent(),
    this.rawText = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.pageRange = const Value.absent(),
    this.userTagsJson = const Value.absent(),
    this.extractedMarkdown = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.transcriptText = const Value.absent(),
    this.voiceDistillationJson = const Value.absent(),
    this.autoTagsJson = const Value.absent(),
    this.mediaAssetsJson = const Value.absent(),
    this.localMediaPath = const Value.absent(),
    required DateTime capturedAt,
    required DateTime updatedAt,
    this.isTriageReviewed = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       captureType = Value(captureType),
       capturedAt = Value(capturedAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalCapture> custom({
    Expression<String>? id,
    Expression<String>? readingSessionId,
    Expression<String>? captureType,
    Expression<String>? processingStatus,
    Expression<String>? syncStatus,
    Expression<String>? title,
    Expression<String>? rawText,
    Expression<String>? sourceUrl,
    Expression<String>? pageRange,
    Expression<String>? userTagsJson,
    Expression<String>? extractedMarkdown,
    Expression<String>? ocrText,
    Expression<String>? transcriptText,
    Expression<String>? voiceDistillationJson,
    Expression<String>? autoTagsJson,
    Expression<String>? mediaAssetsJson,
    Expression<String>? localMediaPath,
    Expression<DateTime>? capturedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isTriageReviewed,
    Expression<bool>? isArchived,
    Expression<bool>? isDeleted,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (readingSessionId != null) 'reading_session_id': readingSessionId,
      if (captureType != null) 'capture_type': captureType,
      if (processingStatus != null) 'processing_status': processingStatus,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (title != null) 'title': title,
      if (rawText != null) 'raw_text': rawText,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (pageRange != null) 'page_range': pageRange,
      if (userTagsJson != null) 'user_tags_json': userTagsJson,
      if (extractedMarkdown != null) 'extracted_markdown': extractedMarkdown,
      if (ocrText != null) 'ocr_text': ocrText,
      if (transcriptText != null) 'transcript_text': transcriptText,
      if (voiceDistillationJson != null)
        'voice_distillation_json': voiceDistillationJson,
      if (autoTagsJson != null) 'auto_tags_json': autoTagsJson,
      if (mediaAssetsJson != null) 'media_assets_json': mediaAssetsJson,
      if (localMediaPath != null) 'local_media_path': localMediaPath,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isTriageReviewed != null) 'is_triage_reviewed': isTriageReviewed,
      if (isArchived != null) 'is_archived': isArchived,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCapturesCompanion copyWith({
    Value<String>? id,
    Value<String?>? readingSessionId,
    Value<String>? captureType,
    Value<String>? processingStatus,
    Value<String>? syncStatus,
    Value<String?>? title,
    Value<String?>? rawText,
    Value<String?>? sourceUrl,
    Value<String?>? pageRange,
    Value<String>? userTagsJson,
    Value<String?>? extractedMarkdown,
    Value<String?>? ocrText,
    Value<String?>? transcriptText,
    Value<String?>? voiceDistillationJson,
    Value<String>? autoTagsJson,
    Value<String>? mediaAssetsJson,
    Value<String?>? localMediaPath,
    Value<DateTime>? capturedAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isTriageReviewed,
    Value<bool>? isArchived,
    Value<bool>? isDeleted,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return LocalCapturesCompanion(
      id: id ?? this.id,
      readingSessionId: readingSessionId ?? this.readingSessionId,
      captureType: captureType ?? this.captureType,
      processingStatus: processingStatus ?? this.processingStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      title: title ?? this.title,
      rawText: rawText ?? this.rawText,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      pageRange: pageRange ?? this.pageRange,
      userTagsJson: userTagsJson ?? this.userTagsJson,
      extractedMarkdown: extractedMarkdown ?? this.extractedMarkdown,
      ocrText: ocrText ?? this.ocrText,
      transcriptText: transcriptText ?? this.transcriptText,
      voiceDistillationJson:
          voiceDistillationJson ?? this.voiceDistillationJson,
      autoTagsJson: autoTagsJson ?? this.autoTagsJson,
      mediaAssetsJson: mediaAssetsJson ?? this.mediaAssetsJson,
      localMediaPath: localMediaPath ?? this.localMediaPath,
      capturedAt: capturedAt ?? this.capturedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isTriageReviewed: isTriageReviewed ?? this.isTriageReviewed,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (readingSessionId.present) {
      map['reading_session_id'] = Variable<String>(readingSessionId.value);
    }
    if (captureType.present) {
      map['capture_type'] = Variable<String>(captureType.value);
    }
    if (processingStatus.present) {
      map['processing_status'] = Variable<String>(processingStatus.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (pageRange.present) {
      map['page_range'] = Variable<String>(pageRange.value);
    }
    if (userTagsJson.present) {
      map['user_tags_json'] = Variable<String>(userTagsJson.value);
    }
    if (extractedMarkdown.present) {
      map['extracted_markdown'] = Variable<String>(extractedMarkdown.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (transcriptText.present) {
      map['transcript_text'] = Variable<String>(transcriptText.value);
    }
    if (voiceDistillationJson.present) {
      map['voice_distillation_json'] = Variable<String>(
        voiceDistillationJson.value,
      );
    }
    if (autoTagsJson.present) {
      map['auto_tags_json'] = Variable<String>(autoTagsJson.value);
    }
    if (mediaAssetsJson.present) {
      map['media_assets_json'] = Variable<String>(mediaAssetsJson.value);
    }
    if (localMediaPath.present) {
      map['local_media_path'] = Variable<String>(localMediaPath.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isTriageReviewed.present) {
      map['is_triage_reviewed'] = Variable<bool>(isTriageReviewed.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCapturesCompanion(')
          ..write('id: $id, ')
          ..write('readingSessionId: $readingSessionId, ')
          ..write('captureType: $captureType, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('title: $title, ')
          ..write('rawText: $rawText, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('pageRange: $pageRange, ')
          ..write('userTagsJson: $userTagsJson, ')
          ..write('extractedMarkdown: $extractedMarkdown, ')
          ..write('ocrText: $ocrText, ')
          ..write('transcriptText: $transcriptText, ')
          ..write('voiceDistillationJson: $voiceDistillationJson, ')
          ..write('autoTagsJson: $autoTagsJson, ')
          ..write('mediaAssetsJson: $mediaAssetsJson, ')
          ..write('localMediaPath: $localMediaPath, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isTriageReviewed: $isTriageReviewed, ')
          ..write('isArchived: $isArchived, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCaptureAnnotationsTable extends LocalCaptureAnnotations
    with TableInfo<$LocalCaptureAnnotationsTable, LocalCaptureAnnotation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCaptureAnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captureIdMeta = const VerificationMeta(
    'captureId',
  );
  @override
  late final GeneratedColumn<String> captureId = GeneratedColumn<String>(
    'capture_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    captureId,
    content,
    createdAt,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_capture_annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCaptureAnnotation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('capture_id')) {
      context.handle(
        _captureIdMeta,
        captureId.isAcceptableOrUnknown(data['capture_id']!, _captureIdMeta),
      );
    } else if (isInserting) {
      context.missing(_captureIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCaptureAnnotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCaptureAnnotation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      captureId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capture_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $LocalCaptureAnnotationsTable createAlias(String alias) {
    return $LocalCaptureAnnotationsTable(attachedDatabase, alias);
  }
}

class LocalCaptureAnnotation extends DataClass
    implements Insertable<LocalCaptureAnnotation> {
  final String id;
  final String captureId;
  final String content;
  final DateTime createdAt;
  final int syncVersion;
  const LocalCaptureAnnotation({
    required this.id,
    required this.captureId,
    required this.content,
    required this.createdAt,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['capture_id'] = Variable<String>(captureId);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  LocalCaptureAnnotationsCompanion toCompanion(bool nullToAbsent) {
    return LocalCaptureAnnotationsCompanion(
      id: Value(id),
      captureId: Value(captureId),
      content: Value(content),
      createdAt: Value(createdAt),
      syncVersion: Value(syncVersion),
    );
  }

  factory LocalCaptureAnnotation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCaptureAnnotation(
      id: serializer.fromJson<String>(json['id']),
      captureId: serializer.fromJson<String>(json['captureId']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'captureId': serializer.toJson<String>(captureId),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  LocalCaptureAnnotation copyWith({
    String? id,
    String? captureId,
    String? content,
    DateTime? createdAt,
    int? syncVersion,
  }) => LocalCaptureAnnotation(
    id: id ?? this.id,
    captureId: captureId ?? this.captureId,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  LocalCaptureAnnotation copyWithCompanion(
    LocalCaptureAnnotationsCompanion data,
  ) {
    return LocalCaptureAnnotation(
      id: data.id.present ? data.id.value : this.id,
      captureId: data.captureId.present ? data.captureId.value : this.captureId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCaptureAnnotation(')
          ..write('id: $id, ')
          ..write('captureId: $captureId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, captureId, content, createdAt, syncVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCaptureAnnotation &&
          other.id == this.id &&
          other.captureId == this.captureId &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.syncVersion == this.syncVersion);
}

class LocalCaptureAnnotationsCompanion
    extends UpdateCompanion<LocalCaptureAnnotation> {
  final Value<String> id;
  final Value<String> captureId;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const LocalCaptureAnnotationsCompanion({
    this.id = const Value.absent(),
    this.captureId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCaptureAnnotationsCompanion.insert({
    required String id,
    required String captureId,
    required String content,
    required DateTime createdAt,
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       captureId = Value(captureId),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<LocalCaptureAnnotation> custom({
    Expression<String>? id,
    Expression<String>? captureId,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (captureId != null) 'capture_id': captureId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCaptureAnnotationsCompanion copyWith({
    Value<String>? id,
    Value<String>? captureId,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return LocalCaptureAnnotationsCompanion(
      id: id ?? this.id,
      captureId: captureId ?? this.captureId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (captureId.present) {
      map['capture_id'] = Variable<String>(captureId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCaptureAnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('captureId: $captureId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalReadingSessionsTable extends LocalReadingSessions
    with TableInfo<$LocalReadingSessionsTable, LocalReadingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTitleMeta = const VerificationMeta(
    'sourceTitle',
  );
  @override
  late final GeneratedColumn<String> sourceTitle = GeneratedColumn<String>(
    'source_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultTagsJsonMeta = const VerificationMeta(
    'defaultTagsJson',
  );
  @override
  late final GeneratedColumn<String> defaultTagsJson = GeneratedColumn<String>(
    'default_tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('["book"]'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceTitle,
    author,
    defaultTagsJson,
    isActive,
    createdAt,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_reading_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalReadingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_title')) {
      context.handle(
        _sourceTitleMeta,
        sourceTitle.isAcceptableOrUnknown(
          data['source_title']!,
          _sourceTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceTitleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('default_tags_json')) {
      context.handle(
        _defaultTagsJsonMeta,
        defaultTagsJson.isAcceptableOrUnknown(
          data['default_tags_json']!,
          _defaultTagsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalReadingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReadingSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      defaultTagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_tags_json'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $LocalReadingSessionsTable createAlias(String alias) {
    return $LocalReadingSessionsTable(attachedDatabase, alias);
  }
}

class LocalReadingSession extends DataClass
    implements Insertable<LocalReadingSession> {
  final String id;
  final String sourceTitle;
  final String? author;
  final String defaultTagsJson;
  final bool isActive;
  final DateTime createdAt;
  final int syncVersion;
  const LocalReadingSession({
    required this.id,
    required this.sourceTitle,
    this.author,
    required this.defaultTagsJson,
    required this.isActive,
    required this.createdAt,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_title'] = Variable<String>(sourceTitle);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    map['default_tags_json'] = Variable<String>(defaultTagsJson);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  LocalReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalReadingSessionsCompanion(
      id: Value(id),
      sourceTitle: Value(sourceTitle),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      defaultTagsJson: Value(defaultTagsJson),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      syncVersion: Value(syncVersion),
    );
  }

  factory LocalReadingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReadingSession(
      id: serializer.fromJson<String>(json['id']),
      sourceTitle: serializer.fromJson<String>(json['sourceTitle']),
      author: serializer.fromJson<String?>(json['author']),
      defaultTagsJson: serializer.fromJson<String>(json['defaultTagsJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceTitle': serializer.toJson<String>(sourceTitle),
      'author': serializer.toJson<String?>(author),
      'defaultTagsJson': serializer.toJson<String>(defaultTagsJson),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  LocalReadingSession copyWith({
    String? id,
    String? sourceTitle,
    Value<String?> author = const Value.absent(),
    String? defaultTagsJson,
    bool? isActive,
    DateTime? createdAt,
    int? syncVersion,
  }) => LocalReadingSession(
    id: id ?? this.id,
    sourceTitle: sourceTitle ?? this.sourceTitle,
    author: author.present ? author.value : this.author,
    defaultTagsJson: defaultTagsJson ?? this.defaultTagsJson,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  LocalReadingSession copyWithCompanion(LocalReadingSessionsCompanion data) {
    return LocalReadingSession(
      id: data.id.present ? data.id.value : this.id,
      sourceTitle: data.sourceTitle.present
          ? data.sourceTitle.value
          : this.sourceTitle,
      author: data.author.present ? data.author.value : this.author,
      defaultTagsJson: data.defaultTagsJson.present
          ? data.defaultTagsJson.value
          : this.defaultTagsJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReadingSession(')
          ..write('id: $id, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('author: $author, ')
          ..write('defaultTagsJson: $defaultTagsJson, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceTitle,
    author,
    defaultTagsJson,
    isActive,
    createdAt,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReadingSession &&
          other.id == this.id &&
          other.sourceTitle == this.sourceTitle &&
          other.author == this.author &&
          other.defaultTagsJson == this.defaultTagsJson &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.syncVersion == this.syncVersion);
}

class LocalReadingSessionsCompanion
    extends UpdateCompanion<LocalReadingSession> {
  final Value<String> id;
  final Value<String> sourceTitle;
  final Value<String?> author;
  final Value<String> defaultTagsJson;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const LocalReadingSessionsCompanion({
    this.id = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.author = const Value.absent(),
    this.defaultTagsJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReadingSessionsCompanion.insert({
    required String id,
    required String sourceTitle,
    this.author = const Value.absent(),
    this.defaultTagsJson = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceTitle = Value(sourceTitle),
       createdAt = Value(createdAt);
  static Insertable<LocalReadingSession> custom({
    Expression<String>? id,
    Expression<String>? sourceTitle,
    Expression<String>? author,
    Expression<String>? defaultTagsJson,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceTitle != null) 'source_title': sourceTitle,
      if (author != null) 'author': author,
      if (defaultTagsJson != null) 'default_tags_json': defaultTagsJson,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReadingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceTitle,
    Value<String?>? author,
    Value<String>? defaultTagsJson,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return LocalReadingSessionsCompanion(
      id: id ?? this.id,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      author: author ?? this.author,
      defaultTagsJson: defaultTagsJson ?? this.defaultTagsJson,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceTitle.present) {
      map['source_title'] = Variable<String>(sourceTitle.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (defaultTagsJson.present) {
      map['default_tags_json'] = Variable<String>(defaultTagsJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReadingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('author: $author, ')
          ..write('defaultTagsJson: $defaultTagsJson, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxSyncQueueTable extends OutboxSyncQueue
    with TableInfo<$OutboxSyncQueueTable, OutboxSyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxSyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqIdMeta = const VerificationMeta('seqId');
  @override
  late final GeneratedColumn<int> seqId = GeneratedColumn<int>(
    'seq_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seqId,
    entityId,
    operation,
    payloadJson,
    localFilePath,
    retryCount,
    nextRetryAt,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxSyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq_id')) {
      context.handle(
        _seqIdMeta,
        seqId.isAcceptableOrUnknown(data['seq_id']!, _seqIdMeta),
      );
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seqId};
  @override
  OutboxSyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxSyncQueueData(
      seqId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxSyncQueueTable createAlias(String alias) {
    return $OutboxSyncQueueTable(attachedDatabase, alias);
  }
}

class OutboxSyncQueueData extends DataClass
    implements Insertable<OutboxSyncQueueData> {
  final int seqId;
  final String entityId;
  final String operation;
  final String payloadJson;
  final String? localFilePath;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime createdAt;
  const OutboxSyncQueueData({
    required this.seqId,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    this.localFilePath,
    required this.retryCount,
    this.nextRetryAt,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq_id'] = Variable<int>(seqId);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || localFilePath != null) {
      map['local_file_path'] = Variable<String>(localFilePath);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxSyncQueueCompanion toCompanion(bool nullToAbsent) {
    return OutboxSyncQueueCompanion(
      seqId: Value(seqId),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      localFilePath: localFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localFilePath),
      retryCount: Value(retryCount),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxSyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxSyncQueueData(
      seqId: serializer.fromJson<int>(json['seqId']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      localFilePath: serializer.fromJson<String?>(json['localFilePath']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seqId': serializer.toJson<int>(seqId),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'localFilePath': serializer.toJson<String?>(localFilePath),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxSyncQueueData copyWith({
    int? seqId,
    String? entityId,
    String? operation,
    String? payloadJson,
    Value<String?> localFilePath = const Value.absent(),
    int? retryCount,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => OutboxSyncQueueData(
    seqId: seqId ?? this.seqId,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    localFilePath: localFilePath.present
        ? localFilePath.value
        : this.localFilePath,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxSyncQueueData copyWithCompanion(OutboxSyncQueueCompanion data) {
    return OutboxSyncQueueData(
      seqId: data.seqId.present ? data.seqId.value : this.seqId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxSyncQueueData(')
          ..write('seqId: $seqId, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seqId,
    entityId,
    operation,
    payloadJson,
    localFilePath,
    retryCount,
    nextRetryAt,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxSyncQueueData &&
          other.seqId == this.seqId &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.localFilePath == this.localFilePath &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class OutboxSyncQueueCompanion extends UpdateCompanion<OutboxSyncQueueData> {
  final Value<int> seqId;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<String?> localFilePath;
  final Value<int> retryCount;
  final Value<DateTime?> nextRetryAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const OutboxSyncQueueCompanion({
    this.seqId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxSyncQueueCompanion.insert({
    this.seqId = const Value.absent(),
    required String entityId,
    required String operation,
    required String payloadJson,
    this.localFilePath = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : entityId = Value(entityId),
       operation = Value(operation),
       payloadJson = Value(payloadJson);
  static Insertable<OutboxSyncQueueData> custom({
    Expression<int>? seqId,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<String>? localFilePath,
    Expression<int>? retryCount,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (seqId != null) 'seq_id': seqId,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxSyncQueueCompanion copyWith({
    Value<int>? seqId,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<String?>? localFilePath,
    Value<int>? retryCount,
    Value<DateTime?>? nextRetryAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return OutboxSyncQueueCompanion(
      seqId: seqId ?? this.seqId,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      localFilePath: localFilePath ?? this.localFilePath,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seqId.present) {
      map['seq_id'] = Variable<int>(seqId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxSyncQueueCompanion(')
          ..write('seqId: $seqId, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalAiSparksTable extends LocalAiSparks
    with TableInfo<$LocalAiSparksTable, LocalAiSpark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAiSparksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sparkMarkdownMeta = const VerificationMeta(
    'sparkMarkdown',
  );
  @override
  late final GeneratedColumn<String> sparkMarkdown = GeneratedColumn<String>(
    'spark_markdown',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sparkRationaleMeta = const VerificationMeta(
    'sparkRationale',
  );
  @override
  late final GeneratedColumn<String> sparkRationale = GeneratedColumn<String>(
    'spark_rationale',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedProjectMeta = const VerificationMeta(
    'relatedProject',
  );
  @override
  late final GeneratedColumn<String> relatedProject = GeneratedColumn<String>(
    'related_project',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sourceCaptureIdsJsonMeta =
      const VerificationMeta('sourceCaptureIdsJson');
  @override
  late final GeneratedColumn<String> sourceCaptureIdsJson =
      GeneratedColumn<String>(
        'source_capture_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    sparkMarkdown,
    sparkRationale,
    relatedProject,
    tagsJson,
    sourceCaptureIdsJson,
    isRead,
    isPinned,
    createdAt,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_ai_sparks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAiSpark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('spark_markdown')) {
      context.handle(
        _sparkMarkdownMeta,
        sparkMarkdown.isAcceptableOrUnknown(
          data['spark_markdown']!,
          _sparkMarkdownMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sparkMarkdownMeta);
    }
    if (data.containsKey('spark_rationale')) {
      context.handle(
        _sparkRationaleMeta,
        sparkRationale.isAcceptableOrUnknown(
          data['spark_rationale']!,
          _sparkRationaleMeta,
        ),
      );
    }
    if (data.containsKey('related_project')) {
      context.handle(
        _relatedProjectMeta,
        relatedProject.isAcceptableOrUnknown(
          data['related_project']!,
          _relatedProjectMeta,
        ),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('source_capture_ids_json')) {
      context.handle(
        _sourceCaptureIdsJsonMeta,
        sourceCaptureIdsJson.isAcceptableOrUnknown(
          data['source_capture_ids_json']!,
          _sourceCaptureIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAiSpark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAiSpark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sparkMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spark_markdown'],
      )!,
      sparkRationale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spark_rationale'],
      ),
      relatedProject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_project'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      sourceCaptureIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_capture_ids_json'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $LocalAiSparksTable createAlias(String alias) {
    return $LocalAiSparksTable(attachedDatabase, alias);
  }
}

class LocalAiSpark extends DataClass implements Insertable<LocalAiSpark> {
  final String id;
  final String title;
  final String sparkMarkdown;
  final String? sparkRationale;
  final String? relatedProject;
  final String tagsJson;
  final String sourceCaptureIdsJson;
  final bool isRead;
  final bool isPinned;
  final DateTime createdAt;
  final int syncVersion;
  const LocalAiSpark({
    required this.id,
    required this.title,
    required this.sparkMarkdown,
    this.sparkRationale,
    this.relatedProject,
    required this.tagsJson,
    required this.sourceCaptureIdsJson,
    required this.isRead,
    required this.isPinned,
    required this.createdAt,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['spark_markdown'] = Variable<String>(sparkMarkdown);
    if (!nullToAbsent || sparkRationale != null) {
      map['spark_rationale'] = Variable<String>(sparkRationale);
    }
    if (!nullToAbsent || relatedProject != null) {
      map['related_project'] = Variable<String>(relatedProject);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    map['source_capture_ids_json'] = Variable<String>(sourceCaptureIdsJson);
    map['is_read'] = Variable<bool>(isRead);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  LocalAiSparksCompanion toCompanion(bool nullToAbsent) {
    return LocalAiSparksCompanion(
      id: Value(id),
      title: Value(title),
      sparkMarkdown: Value(sparkMarkdown),
      sparkRationale: sparkRationale == null && nullToAbsent
          ? const Value.absent()
          : Value(sparkRationale),
      relatedProject: relatedProject == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedProject),
      tagsJson: Value(tagsJson),
      sourceCaptureIdsJson: Value(sourceCaptureIdsJson),
      isRead: Value(isRead),
      isPinned: Value(isPinned),
      createdAt: Value(createdAt),
      syncVersion: Value(syncVersion),
    );
  }

  factory LocalAiSpark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAiSpark(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      sparkMarkdown: serializer.fromJson<String>(json['sparkMarkdown']),
      sparkRationale: serializer.fromJson<String?>(json['sparkRationale']),
      relatedProject: serializer.fromJson<String?>(json['relatedProject']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      sourceCaptureIdsJson: serializer.fromJson<String>(
        json['sourceCaptureIdsJson'],
      ),
      isRead: serializer.fromJson<bool>(json['isRead']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'sparkMarkdown': serializer.toJson<String>(sparkMarkdown),
      'sparkRationale': serializer.toJson<String?>(sparkRationale),
      'relatedProject': serializer.toJson<String?>(relatedProject),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'sourceCaptureIdsJson': serializer.toJson<String>(sourceCaptureIdsJson),
      'isRead': serializer.toJson<bool>(isRead),
      'isPinned': serializer.toJson<bool>(isPinned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  LocalAiSpark copyWith({
    String? id,
    String? title,
    String? sparkMarkdown,
    Value<String?> sparkRationale = const Value.absent(),
    Value<String?> relatedProject = const Value.absent(),
    String? tagsJson,
    String? sourceCaptureIdsJson,
    bool? isRead,
    bool? isPinned,
    DateTime? createdAt,
    int? syncVersion,
  }) => LocalAiSpark(
    id: id ?? this.id,
    title: title ?? this.title,
    sparkMarkdown: sparkMarkdown ?? this.sparkMarkdown,
    sparkRationale: sparkRationale.present
        ? sparkRationale.value
        : this.sparkRationale,
    relatedProject: relatedProject.present
        ? relatedProject.value
        : this.relatedProject,
    tagsJson: tagsJson ?? this.tagsJson,
    sourceCaptureIdsJson: sourceCaptureIdsJson ?? this.sourceCaptureIdsJson,
    isRead: isRead ?? this.isRead,
    isPinned: isPinned ?? this.isPinned,
    createdAt: createdAt ?? this.createdAt,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  LocalAiSpark copyWithCompanion(LocalAiSparksCompanion data) {
    return LocalAiSpark(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      sparkMarkdown: data.sparkMarkdown.present
          ? data.sparkMarkdown.value
          : this.sparkMarkdown,
      sparkRationale: data.sparkRationale.present
          ? data.sparkRationale.value
          : this.sparkRationale,
      relatedProject: data.relatedProject.present
          ? data.relatedProject.value
          : this.relatedProject,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      sourceCaptureIdsJson: data.sourceCaptureIdsJson.present
          ? data.sourceCaptureIdsJson.value
          : this.sourceCaptureIdsJson,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAiSpark(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sparkMarkdown: $sparkMarkdown, ')
          ..write('sparkRationale: $sparkRationale, ')
          ..write('relatedProject: $relatedProject, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('sourceCaptureIdsJson: $sourceCaptureIdsJson, ')
          ..write('isRead: $isRead, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    sparkMarkdown,
    sparkRationale,
    relatedProject,
    tagsJson,
    sourceCaptureIdsJson,
    isRead,
    isPinned,
    createdAt,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAiSpark &&
          other.id == this.id &&
          other.title == this.title &&
          other.sparkMarkdown == this.sparkMarkdown &&
          other.sparkRationale == this.sparkRationale &&
          other.relatedProject == this.relatedProject &&
          other.tagsJson == this.tagsJson &&
          other.sourceCaptureIdsJson == this.sourceCaptureIdsJson &&
          other.isRead == this.isRead &&
          other.isPinned == this.isPinned &&
          other.createdAt == this.createdAt &&
          other.syncVersion == this.syncVersion);
}

class LocalAiSparksCompanion extends UpdateCompanion<LocalAiSpark> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> sparkMarkdown;
  final Value<String?> sparkRationale;
  final Value<String?> relatedProject;
  final Value<String> tagsJson;
  final Value<String> sourceCaptureIdsJson;
  final Value<bool> isRead;
  final Value<bool> isPinned;
  final Value<DateTime> createdAt;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const LocalAiSparksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.sparkMarkdown = const Value.absent(),
    this.sparkRationale = const Value.absent(),
    this.relatedProject = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.sourceCaptureIdsJson = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAiSparksCompanion.insert({
    required String id,
    required String title,
    required String sparkMarkdown,
    this.sparkRationale = const Value.absent(),
    this.relatedProject = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.sourceCaptureIdsJson = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isPinned = const Value.absent(),
    required DateTime createdAt,
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       sparkMarkdown = Value(sparkMarkdown),
       createdAt = Value(createdAt);
  static Insertable<LocalAiSpark> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? sparkMarkdown,
    Expression<String>? sparkRationale,
    Expression<String>? relatedProject,
    Expression<String>? tagsJson,
    Expression<String>? sourceCaptureIdsJson,
    Expression<bool>? isRead,
    Expression<bool>? isPinned,
    Expression<DateTime>? createdAt,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (sparkMarkdown != null) 'spark_markdown': sparkMarkdown,
      if (sparkRationale != null) 'spark_rationale': sparkRationale,
      if (relatedProject != null) 'related_project': relatedProject,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (sourceCaptureIdsJson != null)
        'source_capture_ids_json': sourceCaptureIdsJson,
      if (isRead != null) 'is_read': isRead,
      if (isPinned != null) 'is_pinned': isPinned,
      if (createdAt != null) 'created_at': createdAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAiSparksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? sparkMarkdown,
    Value<String?>? sparkRationale,
    Value<String?>? relatedProject,
    Value<String>? tagsJson,
    Value<String>? sourceCaptureIdsJson,
    Value<bool>? isRead,
    Value<bool>? isPinned,
    Value<DateTime>? createdAt,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return LocalAiSparksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      sparkMarkdown: sparkMarkdown ?? this.sparkMarkdown,
      sparkRationale: sparkRationale ?? this.sparkRationale,
      relatedProject: relatedProject ?? this.relatedProject,
      tagsJson: tagsJson ?? this.tagsJson,
      sourceCaptureIdsJson: sourceCaptureIdsJson ?? this.sourceCaptureIdsJson,
      isRead: isRead ?? this.isRead,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sparkMarkdown.present) {
      map['spark_markdown'] = Variable<String>(sparkMarkdown.value);
    }
    if (sparkRationale.present) {
      map['spark_rationale'] = Variable<String>(sparkRationale.value);
    }
    if (relatedProject.present) {
      map['related_project'] = Variable<String>(relatedProject.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (sourceCaptureIdsJson.present) {
      map['source_capture_ids_json'] = Variable<String>(
        sourceCaptureIdsJson.value,
      );
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAiSparksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sparkMarkdown: $sparkMarkdown, ')
          ..write('sparkRationale: $sparkRationale, ')
          ..write('relatedProject: $relatedProject, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('sourceCaptureIdsJson: $sourceCaptureIdsJson, ')
          ..write('isRead: $isRead, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateMetaTable extends SyncStateMeta
    with TableInfo<$SyncStateMetaTable, SyncStateMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncStateMetaTable createAlias(String alias) {
    return $SyncStateMetaTable(attachedDatabase, alias);
  }
}

class SyncStateMetaData extends DataClass
    implements Insertable<SyncStateMetaData> {
  final String key;
  final String value;
  const SyncStateMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncStateMetaCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateMetaData copyWith({String? key, String? value}) =>
      SyncStateMetaData(key: key ?? this.key, value: value ?? this.value);
  SyncStateMetaData copyWithCompanion(SyncStateMetaCompanion data) {
    return SyncStateMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateMetaCompanion extends UpdateCompanion<SyncStateMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalCapturesTable localCaptures = $LocalCapturesTable(this);
  late final $LocalCaptureAnnotationsTable localCaptureAnnotations =
      $LocalCaptureAnnotationsTable(this);
  late final $LocalReadingSessionsTable localReadingSessions =
      $LocalReadingSessionsTable(this);
  late final $OutboxSyncQueueTable outboxSyncQueue = $OutboxSyncQueueTable(
    this,
  );
  late final $LocalAiSparksTable localAiSparks = $LocalAiSparksTable(this);
  late final $SyncStateMetaTable syncStateMeta = $SyncStateMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localCaptures,
    localCaptureAnnotations,
    localReadingSessions,
    outboxSyncQueue,
    localAiSparks,
    syncStateMeta,
  ];
}

typedef $$LocalCapturesTableCreateCompanionBuilder =
    LocalCapturesCompanion Function({
      required String id,
      Value<String?> readingSessionId,
      required String captureType,
      Value<String> processingStatus,
      Value<String> syncStatus,
      Value<String?> title,
      Value<String?> rawText,
      Value<String?> sourceUrl,
      Value<String?> pageRange,
      Value<String> userTagsJson,
      Value<String?> extractedMarkdown,
      Value<String?> ocrText,
      Value<String?> transcriptText,
      Value<String?> voiceDistillationJson,
      Value<String> autoTagsJson,
      Value<String> mediaAssetsJson,
      Value<String?> localMediaPath,
      required DateTime capturedAt,
      required DateTime updatedAt,
      Value<bool> isTriageReviewed,
      Value<bool> isArchived,
      Value<bool> isDeleted,
      Value<int> syncVersion,
      Value<int> rowid,
    });
typedef $$LocalCapturesTableUpdateCompanionBuilder =
    LocalCapturesCompanion Function({
      Value<String> id,
      Value<String?> readingSessionId,
      Value<String> captureType,
      Value<String> processingStatus,
      Value<String> syncStatus,
      Value<String?> title,
      Value<String?> rawText,
      Value<String?> sourceUrl,
      Value<String?> pageRange,
      Value<String> userTagsJson,
      Value<String?> extractedMarkdown,
      Value<String?> ocrText,
      Value<String?> transcriptText,
      Value<String?> voiceDistillationJson,
      Value<String> autoTagsJson,
      Value<String> mediaAssetsJson,
      Value<String?> localMediaPath,
      Value<DateTime> capturedAt,
      Value<DateTime> updatedAt,
      Value<bool> isTriageReviewed,
      Value<bool> isArchived,
      Value<bool> isDeleted,
      Value<int> syncVersion,
      Value<int> rowid,
    });

class $$LocalCapturesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCapturesTable> {
  $$LocalCapturesTableFilterComposer({
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

  ColumnFilters<String> get readingSessionId => $composableBuilder(
    column: $table.readingSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get captureType => $composableBuilder(
    column: $table.captureType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageRange => $composableBuilder(
    column: $table.pageRange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userTagsJson => $composableBuilder(
    column: $table.userTagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedMarkdown => $composableBuilder(
    column: $table.extractedMarkdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcriptText => $composableBuilder(
    column: $table.transcriptText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceDistillationJson => $composableBuilder(
    column: $table.voiceDistillationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get autoTagsJson => $composableBuilder(
    column: $table.autoTagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaAssetsJson => $composableBuilder(
    column: $table.mediaAssetsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localMediaPath => $composableBuilder(
    column: $table.localMediaPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTriageReviewed => $composableBuilder(
    column: $table.isTriageReviewed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCapturesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCapturesTable> {
  $$LocalCapturesTableOrderingComposer({
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

  ColumnOrderings<String> get readingSessionId => $composableBuilder(
    column: $table.readingSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get captureType => $composableBuilder(
    column: $table.captureType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageRange => $composableBuilder(
    column: $table.pageRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userTagsJson => $composableBuilder(
    column: $table.userTagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedMarkdown => $composableBuilder(
    column: $table.extractedMarkdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcriptText => $composableBuilder(
    column: $table.transcriptText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceDistillationJson => $composableBuilder(
    column: $table.voiceDistillationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get autoTagsJson => $composableBuilder(
    column: $table.autoTagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaAssetsJson => $composableBuilder(
    column: $table.mediaAssetsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localMediaPath => $composableBuilder(
    column: $table.localMediaPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTriageReviewed => $composableBuilder(
    column: $table.isTriageReviewed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCapturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCapturesTable> {
  $$LocalCapturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get readingSessionId => $composableBuilder(
    column: $table.readingSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get captureType => $composableBuilder(
    column: $table.captureType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get pageRange =>
      $composableBuilder(column: $table.pageRange, builder: (column) => column);

  GeneratedColumn<String> get userTagsJson => $composableBuilder(
    column: $table.userTagsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extractedMarkdown => $composableBuilder(
    column: $table.extractedMarkdown,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<String> get transcriptText => $composableBuilder(
    column: $table.transcriptText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voiceDistillationJson => $composableBuilder(
    column: $table.voiceDistillationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get autoTagsJson => $composableBuilder(
    column: $table.autoTagsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaAssetsJson => $composableBuilder(
    column: $table.mediaAssetsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localMediaPath => $composableBuilder(
    column: $table.localMediaPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isTriageReviewed => $composableBuilder(
    column: $table.isTriageReviewed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );
}

class $$LocalCapturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCapturesTable,
          LocalCapture,
          $$LocalCapturesTableFilterComposer,
          $$LocalCapturesTableOrderingComposer,
          $$LocalCapturesTableAnnotationComposer,
          $$LocalCapturesTableCreateCompanionBuilder,
          $$LocalCapturesTableUpdateCompanionBuilder,
          (
            LocalCapture,
            BaseReferences<_$AppDatabase, $LocalCapturesTable, LocalCapture>,
          ),
          LocalCapture,
          PrefetchHooks Function()
        > {
  $$LocalCapturesTableTableManager(_$AppDatabase db, $LocalCapturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCapturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCapturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCapturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> readingSessionId = const Value.absent(),
                Value<String> captureType = const Value.absent(),
                Value<String> processingStatus = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> pageRange = const Value.absent(),
                Value<String> userTagsJson = const Value.absent(),
                Value<String?> extractedMarkdown = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String?> transcriptText = const Value.absent(),
                Value<String?> voiceDistillationJson = const Value.absent(),
                Value<String> autoTagsJson = const Value.absent(),
                Value<String> mediaAssetsJson = const Value.absent(),
                Value<String?> localMediaPath = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isTriageReviewed = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCapturesCompanion(
                id: id,
                readingSessionId: readingSessionId,
                captureType: captureType,
                processingStatus: processingStatus,
                syncStatus: syncStatus,
                title: title,
                rawText: rawText,
                sourceUrl: sourceUrl,
                pageRange: pageRange,
                userTagsJson: userTagsJson,
                extractedMarkdown: extractedMarkdown,
                ocrText: ocrText,
                transcriptText: transcriptText,
                voiceDistillationJson: voiceDistillationJson,
                autoTagsJson: autoTagsJson,
                mediaAssetsJson: mediaAssetsJson,
                localMediaPath: localMediaPath,
                capturedAt: capturedAt,
                updatedAt: updatedAt,
                isTriageReviewed: isTriageReviewed,
                isArchived: isArchived,
                isDeleted: isDeleted,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> readingSessionId = const Value.absent(),
                required String captureType,
                Value<String> processingStatus = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> pageRange = const Value.absent(),
                Value<String> userTagsJson = const Value.absent(),
                Value<String?> extractedMarkdown = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String?> transcriptText = const Value.absent(),
                Value<String?> voiceDistillationJson = const Value.absent(),
                Value<String> autoTagsJson = const Value.absent(),
                Value<String> mediaAssetsJson = const Value.absent(),
                Value<String?> localMediaPath = const Value.absent(),
                required DateTime capturedAt,
                required DateTime updatedAt,
                Value<bool> isTriageReviewed = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCapturesCompanion.insert(
                id: id,
                readingSessionId: readingSessionId,
                captureType: captureType,
                processingStatus: processingStatus,
                syncStatus: syncStatus,
                title: title,
                rawText: rawText,
                sourceUrl: sourceUrl,
                pageRange: pageRange,
                userTagsJson: userTagsJson,
                extractedMarkdown: extractedMarkdown,
                ocrText: ocrText,
                transcriptText: transcriptText,
                voiceDistillationJson: voiceDistillationJson,
                autoTagsJson: autoTagsJson,
                mediaAssetsJson: mediaAssetsJson,
                localMediaPath: localMediaPath,
                capturedAt: capturedAt,
                updatedAt: updatedAt,
                isTriageReviewed: isTriageReviewed,
                isArchived: isArchived,
                isDeleted: isDeleted,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalCapturesTable, LocalCapture>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalCapturesTable,
                    LocalCapture
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCapturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCapturesTable,
      LocalCapture,
      $$LocalCapturesTableFilterComposer,
      $$LocalCapturesTableOrderingComposer,
      $$LocalCapturesTableAnnotationComposer,
      $$LocalCapturesTableCreateCompanionBuilder,
      $$LocalCapturesTableUpdateCompanionBuilder,
      (
        LocalCapture,
        BaseReferences<_$AppDatabase, $LocalCapturesTable, LocalCapture>,
      ),
      LocalCapture,
      PrefetchHooks Function()
    >;
typedef $$LocalCaptureAnnotationsTableCreateCompanionBuilder =
    LocalCaptureAnnotationsCompanion Function({
      required String id,
      required String captureId,
      required String content,
      required DateTime createdAt,
      Value<int> syncVersion,
      Value<int> rowid,
    });
typedef $$LocalCaptureAnnotationsTableUpdateCompanionBuilder =
    LocalCaptureAnnotationsCompanion Function({
      Value<String> id,
      Value<String> captureId,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<int> syncVersion,
      Value<int> rowid,
    });

class $$LocalCaptureAnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCaptureAnnotationsTable> {
  $$LocalCaptureAnnotationsTableFilterComposer({
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

  ColumnFilters<String> get captureId => $composableBuilder(
    column: $table.captureId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCaptureAnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCaptureAnnotationsTable> {
  $$LocalCaptureAnnotationsTableOrderingComposer({
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

  ColumnOrderings<String> get captureId => $composableBuilder(
    column: $table.captureId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCaptureAnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCaptureAnnotationsTable> {
  $$LocalCaptureAnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get captureId =>
      $composableBuilder(column: $table.captureId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );
}

class $$LocalCaptureAnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCaptureAnnotationsTable,
          LocalCaptureAnnotation,
          $$LocalCaptureAnnotationsTableFilterComposer,
          $$LocalCaptureAnnotationsTableOrderingComposer,
          $$LocalCaptureAnnotationsTableAnnotationComposer,
          $$LocalCaptureAnnotationsTableCreateCompanionBuilder,
          $$LocalCaptureAnnotationsTableUpdateCompanionBuilder,
          (
            LocalCaptureAnnotation,
            BaseReferences<
              _$AppDatabase,
              $LocalCaptureAnnotationsTable,
              LocalCaptureAnnotation
            >,
          ),
          LocalCaptureAnnotation,
          PrefetchHooks Function()
        > {
  $$LocalCaptureAnnotationsTableTableManager(
    _$AppDatabase db,
    $LocalCaptureAnnotationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCaptureAnnotationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalCaptureAnnotationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalCaptureAnnotationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> captureId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCaptureAnnotationsCompanion(
                id: id,
                captureId: captureId,
                content: content,
                createdAt: createdAt,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String captureId,
                required String content,
                required DateTime createdAt,
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCaptureAnnotationsCompanion.insert(
                id: id,
                captureId: captureId,
                content: content,
                createdAt: createdAt,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalCaptureAnnotationsTable,
                    LocalCaptureAnnotation
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalCaptureAnnotationsTable,
                    LocalCaptureAnnotation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCaptureAnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCaptureAnnotationsTable,
      LocalCaptureAnnotation,
      $$LocalCaptureAnnotationsTableFilterComposer,
      $$LocalCaptureAnnotationsTableOrderingComposer,
      $$LocalCaptureAnnotationsTableAnnotationComposer,
      $$LocalCaptureAnnotationsTableCreateCompanionBuilder,
      $$LocalCaptureAnnotationsTableUpdateCompanionBuilder,
      (
        LocalCaptureAnnotation,
        BaseReferences<
          _$AppDatabase,
          $LocalCaptureAnnotationsTable,
          LocalCaptureAnnotation
        >,
      ),
      LocalCaptureAnnotation,
      PrefetchHooks Function()
    >;
typedef $$LocalReadingSessionsTableCreateCompanionBuilder =
    LocalReadingSessionsCompanion Function({
      required String id,
      required String sourceTitle,
      Value<String?> author,
      Value<String> defaultTagsJson,
      Value<bool> isActive,
      required DateTime createdAt,
      Value<int> syncVersion,
      Value<int> rowid,
    });
typedef $$LocalReadingSessionsTableUpdateCompanionBuilder =
    LocalReadingSessionsCompanion Function({
      Value<String> id,
      Value<String> sourceTitle,
      Value<String?> author,
      Value<String> defaultTagsJson,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> syncVersion,
      Value<int> rowid,
    });

class $$LocalReadingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReadingSessionsTable> {
  $$LocalReadingSessionsTableFilterComposer({
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

  ColumnFilters<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultTagsJson => $composableBuilder(
    column: $table.defaultTagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalReadingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReadingSessionsTable> {
  $$LocalReadingSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultTagsJson => $composableBuilder(
    column: $table.defaultTagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalReadingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReadingSessionsTable> {
  $$LocalReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get defaultTagsJson => $composableBuilder(
    column: $table.defaultTagsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );
}

class $$LocalReadingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalReadingSessionsTable,
          LocalReadingSession,
          $$LocalReadingSessionsTableFilterComposer,
          $$LocalReadingSessionsTableOrderingComposer,
          $$LocalReadingSessionsTableAnnotationComposer,
          $$LocalReadingSessionsTableCreateCompanionBuilder,
          $$LocalReadingSessionsTableUpdateCompanionBuilder,
          (
            LocalReadingSession,
            BaseReferences<
              _$AppDatabase,
              $LocalReadingSessionsTable,
              LocalReadingSession
            >,
          ),
          LocalReadingSession,
          PrefetchHooks Function()
        > {
  $$LocalReadingSessionsTableTableManager(
    _$AppDatabase db,
    $LocalReadingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalReadingSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalReadingSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceTitle = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String> defaultTagsJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalReadingSessionsCompanion(
                id: id,
                sourceTitle: sourceTitle,
                author: author,
                defaultTagsJson: defaultTagsJson,
                isActive: isActive,
                createdAt: createdAt,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceTitle,
                Value<String?> author = const Value.absent(),
                Value<String> defaultTagsJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalReadingSessionsCompanion.insert(
                id: id,
                sourceTitle: sourceTitle,
                author: author,
                defaultTagsJson: defaultTagsJson,
                isActive: isActive,
                createdAt: createdAt,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalReadingSessionsTable, LocalReadingSession>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalReadingSessionsTable,
                    LocalReadingSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalReadingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalReadingSessionsTable,
      LocalReadingSession,
      $$LocalReadingSessionsTableFilterComposer,
      $$LocalReadingSessionsTableOrderingComposer,
      $$LocalReadingSessionsTableAnnotationComposer,
      $$LocalReadingSessionsTableCreateCompanionBuilder,
      $$LocalReadingSessionsTableUpdateCompanionBuilder,
      (
        LocalReadingSession,
        BaseReferences<
          _$AppDatabase,
          $LocalReadingSessionsTable,
          LocalReadingSession
        >,
      ),
      LocalReadingSession,
      PrefetchHooks Function()
    >;
typedef $$OutboxSyncQueueTableCreateCompanionBuilder =
    OutboxSyncQueueCompanion Function({
      Value<int> seqId,
      required String entityId,
      required String operation,
      required String payloadJson,
      Value<String?> localFilePath,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });
typedef $$OutboxSyncQueueTableUpdateCompanionBuilder =
    OutboxSyncQueueCompanion Function({
      Value<int> seqId,
      Value<String> entityId,
      Value<String> operation,
      Value<String> payloadJson,
      Value<String?> localFilePath,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });

class $$OutboxSyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxSyncQueueTable> {
  $$OutboxSyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seqId => $composableBuilder(
    column: $table.seqId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxSyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxSyncQueueTable> {
  $$OutboxSyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seqId => $composableBuilder(
    column: $table.seqId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxSyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxSyncQueueTable> {
  $$OutboxSyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seqId =>
      $composableBuilder(column: $table.seqId, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxSyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxSyncQueueTable,
          OutboxSyncQueueData,
          $$OutboxSyncQueueTableFilterComposer,
          $$OutboxSyncQueueTableOrderingComposer,
          $$OutboxSyncQueueTableAnnotationComposer,
          $$OutboxSyncQueueTableCreateCompanionBuilder,
          $$OutboxSyncQueueTableUpdateCompanionBuilder,
          (
            OutboxSyncQueueData,
            BaseReferences<
              _$AppDatabase,
              $OutboxSyncQueueTable,
              OutboxSyncQueueData
            >,
          ),
          OutboxSyncQueueData,
          PrefetchHooks Function()
        > {
  $$OutboxSyncQueueTableTableManager(
    _$AppDatabase db,
    $OutboxSyncQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxSyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxSyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxSyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seqId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> localFilePath = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxSyncQueueCompanion(
                seqId: seqId,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                localFilePath: localFilePath,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seqId = const Value.absent(),
                required String entityId,
                required String operation,
                required String payloadJson,
                Value<String?> localFilePath = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxSyncQueueCompanion.insert(
                seqId: seqId,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                localFilePath: localFilePath,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxSyncQueueTable, OutboxSyncQueueData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $OutboxSyncQueueTable,
                    OutboxSyncQueueData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxSyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxSyncQueueTable,
      OutboxSyncQueueData,
      $$OutboxSyncQueueTableFilterComposer,
      $$OutboxSyncQueueTableOrderingComposer,
      $$OutboxSyncQueueTableAnnotationComposer,
      $$OutboxSyncQueueTableCreateCompanionBuilder,
      $$OutboxSyncQueueTableUpdateCompanionBuilder,
      (
        OutboxSyncQueueData,
        BaseReferences<
          _$AppDatabase,
          $OutboxSyncQueueTable,
          OutboxSyncQueueData
        >,
      ),
      OutboxSyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$LocalAiSparksTableCreateCompanionBuilder =
    LocalAiSparksCompanion Function({
      required String id,
      required String title,
      required String sparkMarkdown,
      Value<String?> sparkRationale,
      Value<String?> relatedProject,
      Value<String> tagsJson,
      Value<String> sourceCaptureIdsJson,
      Value<bool> isRead,
      Value<bool> isPinned,
      required DateTime createdAt,
      Value<int> syncVersion,
      Value<int> rowid,
    });
typedef $$LocalAiSparksTableUpdateCompanionBuilder =
    LocalAiSparksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> sparkMarkdown,
      Value<String?> sparkRationale,
      Value<String?> relatedProject,
      Value<String> tagsJson,
      Value<String> sourceCaptureIdsJson,
      Value<bool> isRead,
      Value<bool> isPinned,
      Value<DateTime> createdAt,
      Value<int> syncVersion,
      Value<int> rowid,
    });

class $$LocalAiSparksTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAiSparksTable> {
  $$LocalAiSparksTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sparkMarkdown => $composableBuilder(
    column: $table.sparkMarkdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sparkRationale => $composableBuilder(
    column: $table.sparkRationale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedProject => $composableBuilder(
    column: $table.relatedProject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceCaptureIdsJson => $composableBuilder(
    column: $table.sourceCaptureIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAiSparksTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAiSparksTable> {
  $$LocalAiSparksTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sparkMarkdown => $composableBuilder(
    column: $table.sparkMarkdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sparkRationale => $composableBuilder(
    column: $table.sparkRationale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedProject => $composableBuilder(
    column: $table.relatedProject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceCaptureIdsJson => $composableBuilder(
    column: $table.sourceCaptureIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAiSparksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAiSparksTable> {
  $$LocalAiSparksTableAnnotationComposer({
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

  GeneratedColumn<String> get sparkMarkdown => $composableBuilder(
    column: $table.sparkMarkdown,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sparkRationale => $composableBuilder(
    column: $table.sparkRationale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedProject => $composableBuilder(
    column: $table.relatedProject,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get sourceCaptureIdsJson => $composableBuilder(
    column: $table.sourceCaptureIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );
}

class $$LocalAiSparksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAiSparksTable,
          LocalAiSpark,
          $$LocalAiSparksTableFilterComposer,
          $$LocalAiSparksTableOrderingComposer,
          $$LocalAiSparksTableAnnotationComposer,
          $$LocalAiSparksTableCreateCompanionBuilder,
          $$LocalAiSparksTableUpdateCompanionBuilder,
          (
            LocalAiSpark,
            BaseReferences<_$AppDatabase, $LocalAiSparksTable, LocalAiSpark>,
          ),
          LocalAiSpark,
          PrefetchHooks Function()
        > {
  $$LocalAiSparksTableTableManager(_$AppDatabase db, $LocalAiSparksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAiSparksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAiSparksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAiSparksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> sparkMarkdown = const Value.absent(),
                Value<String?> sparkRationale = const Value.absent(),
                Value<String?> relatedProject = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String> sourceCaptureIdsJson = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAiSparksCompanion(
                id: id,
                title: title,
                sparkMarkdown: sparkMarkdown,
                sparkRationale: sparkRationale,
                relatedProject: relatedProject,
                tagsJson: tagsJson,
                sourceCaptureIdsJson: sourceCaptureIdsJson,
                isRead: isRead,
                isPinned: isPinned,
                createdAt: createdAt,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String sparkMarkdown,
                Value<String?> sparkRationale = const Value.absent(),
                Value<String?> relatedProject = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String> sourceCaptureIdsJson = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                required DateTime createdAt,
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAiSparksCompanion.insert(
                id: id,
                title: title,
                sparkMarkdown: sparkMarkdown,
                sparkRationale: sparkRationale,
                relatedProject: relatedProject,
                tagsJson: tagsJson,
                sourceCaptureIdsJson: sourceCaptureIdsJson,
                isRead: isRead,
                isPinned: isPinned,
                createdAt: createdAt,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalAiSparksTable, LocalAiSpark>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalAiSparksTable,
                    LocalAiSpark
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAiSparksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAiSparksTable,
      LocalAiSpark,
      $$LocalAiSparksTableFilterComposer,
      $$LocalAiSparksTableOrderingComposer,
      $$LocalAiSparksTableAnnotationComposer,
      $$LocalAiSparksTableCreateCompanionBuilder,
      $$LocalAiSparksTableUpdateCompanionBuilder,
      (
        LocalAiSpark,
        BaseReferences<_$AppDatabase, $LocalAiSparksTable, LocalAiSpark>,
      ),
      LocalAiSpark,
      PrefetchHooks Function()
    >;
typedef $$SyncStateMetaTableCreateCompanionBuilder =
    SyncStateMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncStateMetaTableUpdateCompanionBuilder =
    SyncStateMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncStateMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateMetaTable> {
  $$SyncStateMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateMetaTable> {
  $$SyncStateMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateMetaTable> {
  $$SyncStateMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStateMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateMetaTable,
          SyncStateMetaData,
          $$SyncStateMetaTableFilterComposer,
          $$SyncStateMetaTableOrderingComposer,
          $$SyncStateMetaTableAnnotationComposer,
          $$SyncStateMetaTableCreateCompanionBuilder,
          $$SyncStateMetaTableUpdateCompanionBuilder,
          (
            SyncStateMetaData,
            BaseReferences<
              _$AppDatabase,
              $SyncStateMetaTable,
              SyncStateMetaData
            >,
          ),
          SyncStateMetaData,
          PrefetchHooks Function()
        > {
  $$SyncStateMetaTableTableManager(_$AppDatabase db, $SyncStateMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncStateMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncStateMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateMetaTable, SyncStateMetaData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncStateMetaTable,
                    SyncStateMetaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateMetaTable,
      SyncStateMetaData,
      $$SyncStateMetaTableFilterComposer,
      $$SyncStateMetaTableOrderingComposer,
      $$SyncStateMetaTableAnnotationComposer,
      $$SyncStateMetaTableCreateCompanionBuilder,
      $$SyncStateMetaTableUpdateCompanionBuilder,
      (
        SyncStateMetaData,
        BaseReferences<_$AppDatabase, $SyncStateMetaTable, SyncStateMetaData>,
      ),
      SyncStateMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalCapturesTableTableManager get localCaptures =>
      $$LocalCapturesTableTableManager(_db, _db.localCaptures);
  $$LocalCaptureAnnotationsTableTableManager get localCaptureAnnotations =>
      $$LocalCaptureAnnotationsTableTableManager(
        _db,
        _db.localCaptureAnnotations,
      );
  $$LocalReadingSessionsTableTableManager get localReadingSessions =>
      $$LocalReadingSessionsTableTableManager(_db, _db.localReadingSessions);
  $$OutboxSyncQueueTableTableManager get outboxSyncQueue =>
      $$OutboxSyncQueueTableTableManager(_db, _db.outboxSyncQueue);
  $$LocalAiSparksTableTableManager get localAiSparks =>
      $$LocalAiSparksTableTableManager(_db, _db.localAiSparks);
  $$SyncStateMetaTableTableManager get syncStateMeta =>
      $$SyncStateMetaTableTableManager(_db, _db.syncStateMeta);
}

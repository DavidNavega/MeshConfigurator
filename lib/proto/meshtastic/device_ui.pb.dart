//
//  Generated code. Do not modify.
//  source: meshtastic/device_ui.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'device_ui.pbenum.dart';

export 'device_ui.pbenum.dart';

class DeviceUIConfig extends $pb.GeneratedMessage {
  factory DeviceUIConfig({
    $core.int? version,
    $core.int? screenBrightness,
    $core.int? screenTimeout,
    $core.bool? screenLock,
    $core.bool? settingsLock,
    $core.int? pinCode,
    Theme? theme,
    $core.bool? alertEnabled,
    $core.bool? bannerEnabled,
    $core.int? ringToneId,
    Language? language,
    NodeFilter? nodeFilter,
    NodeHighlight? nodeHighlight,
    $core.List<$core.int>? calibrationData,
    Map_? mapData,
  }) {
    final $result = create();
    if (version != null) {
      $result.version = version;
    }
    if (screenBrightness != null) {
      $result.screenBrightness = screenBrightness;
    }
    if (screenTimeout != null) {
      $result.screenTimeout = screenTimeout;
    }
    if (screenLock != null) {
      $result.screenLock = screenLock;
    }
    if (settingsLock != null) {
      $result.settingsLock = settingsLock;
    }
    if (pinCode != null) {
      $result.pinCode = pinCode;
    }
    if (theme != null) {
      $result.theme = theme;
    }
    if (alertEnabled != null) {
      $result.alertEnabled = alertEnabled;
    }
    if (bannerEnabled != null) {
      $result.bannerEnabled = bannerEnabled;
    }
    if (ringToneId != null) {
      $result.ringToneId = ringToneId;
    }
    if (language != null) {
      $result.language = language;
    }
    if (nodeFilter != null) {
      $result.nodeFilter = nodeFilter;
    }
    if (nodeHighlight != null) {
      $result.nodeHighlight = nodeHighlight;
    }
    if (calibrationData != null) {
      $result.calibrationData = calibrationData;
    }
    if (mapData != null) {
      $result.mapData = mapData;
    }
    return $result;
  }
  DeviceUIConfig._() : super();
  factory DeviceUIConfig.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeviceUIConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeviceUIConfig', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'screenBrightness', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'screenTimeout', $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'screenLock')
    ..aOB(5, _omitFieldNames ? '' : 'settingsLock')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'pinCode', $pb.PbFieldType.OU3)
    ..e<Theme>(7, _omitFieldNames ? '' : 'theme', $pb.PbFieldType.OE, defaultOrMaker: Theme.DARK, valueOf: Theme.valueOf, enumValues: Theme.values)
    ..aOB(8, _omitFieldNames ? '' : 'alertEnabled')
    ..aOB(9, _omitFieldNames ? '' : 'bannerEnabled')
    ..a<$core.int>(10, _omitFieldNames ? '' : 'ringToneId', $pb.PbFieldType.OU3)
    ..e<Language>(11, _omitFieldNames ? '' : 'language', $pb.PbFieldType.OE, defaultOrMaker: Language.ENGLISH, valueOf: Language.valueOf, enumValues: Language.values)
    ..aOM<NodeFilter>(12, _omitFieldNames ? '' : 'nodeFilter', subBuilder: NodeFilter.create)
    ..aOM<NodeHighlight>(13, _omitFieldNames ? '' : 'nodeHighlight', subBuilder: NodeHighlight.create)
    ..a<$core.List<$core.int>>(14, _omitFieldNames ? '' : 'calibrationData', $pb.PbFieldType.OY)
    ..aOM<Map_>(15, _omitFieldNames ? '' : 'mapData', subBuilder: Map_.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeviceUIConfig clone() => DeviceUIConfig()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeviceUIConfig copyWith(void Function(DeviceUIConfig) updates) => super.copyWith((message) => updates(message as DeviceUIConfig)) as DeviceUIConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceUIConfig create() => DeviceUIConfig._();
  DeviceUIConfig createEmptyInstance() => create();
  static $pb.PbList<DeviceUIConfig> createRepeated() => $pb.PbList<DeviceUIConfig>();
  @$core.pragma('dart2js:noInline')
  static DeviceUIConfig getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeviceUIConfig>(create);
  static DeviceUIConfig? _defaultInstance;

  ///
  ///  A version integer used to invalidate saved files when we make incompatible changes.
  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => clearField(1);

  ///
  ///  TFT display brightness 1..255
  @$pb.TagNumber(2)
  $core.int get screenBrightness => $_getIZ(1);
  @$pb.TagNumber(2)
  set screenBrightness($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasScreenBrightness() => $_has(1);
  @$pb.TagNumber(2)
  void clearScreenBrightness() => clearField(2);

  ///
  ///  Screen timeout 0..900
  @$pb.TagNumber(3)
  $core.int get screenTimeout => $_getIZ(2);
  @$pb.TagNumber(3)
  set screenTimeout($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasScreenTimeout() => $_has(2);
  @$pb.TagNumber(3)
  void clearScreenTimeout() => clearField(3);

  ///
  ///  Screen/Settings lock enabled
  @$pb.TagNumber(4)
  $core.bool get screenLock => $_getBF(3);
  @$pb.TagNumber(4)
  set screenLock($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasScreenLock() => $_has(3);
  @$pb.TagNumber(4)
  void clearScreenLock() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get settingsLock => $_getBF(4);
  @$pb.TagNumber(5)
  set settingsLock($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasSettingsLock() => $_has(4);
  @$pb.TagNumber(5)
  void clearSettingsLock() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get pinCode => $_getIZ(5);
  @$pb.TagNumber(6)
  set pinCode($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPinCode() => $_has(5);
  @$pb.TagNumber(6)
  void clearPinCode() => clearField(6);

  ///
  ///  Color theme
  @$pb.TagNumber(7)
  Theme get theme => $_getN(6);
  @$pb.TagNumber(7)
  set theme(Theme v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasTheme() => $_has(6);
  @$pb.TagNumber(7)
  void clearTheme() => clearField(7);

  ///
  ///  Audible message, banner and ring tone
  @$pb.TagNumber(8)
  $core.bool get alertEnabled => $_getBF(7);
  @$pb.TagNumber(8)
  set alertEnabled($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasAlertEnabled() => $_has(7);
  @$pb.TagNumber(8)
  void clearAlertEnabled() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get bannerEnabled => $_getBF(8);
  @$pb.TagNumber(9)
  set bannerEnabled($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasBannerEnabled() => $_has(8);
  @$pb.TagNumber(9)
  void clearBannerEnabled() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get ringToneId => $_getIZ(9);
  @$pb.TagNumber(10)
  set ringToneId($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasRingToneId() => $_has(9);
  @$pb.TagNumber(10)
  void clearRingToneId() => clearField(10);

  ///
  ///  Localization
  @$pb.TagNumber(11)
  Language get language => $_getN(10);
  @$pb.TagNumber(11)
  set language(Language v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasLanguage() => $_has(10);
  @$pb.TagNumber(11)
  void clearLanguage() => clearField(11);

  ///
  ///  Node list filter
  @$pb.TagNumber(12)
  NodeFilter get nodeFilter => $_getN(11);
  @$pb.TagNumber(12)
  set nodeFilter(NodeFilter v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasNodeFilter() => $_has(11);
  @$pb.TagNumber(12)
  void clearNodeFilter() => clearField(12);
  @$pb.TagNumber(12)
  NodeFilter ensureNodeFilter() => $_ensure(11);

  ///
  ///  Node list highlightening
  @$pb.TagNumber(13)
  NodeHighlight get nodeHighlight => $_getN(12);
  @$pb.TagNumber(13)
  set nodeHighlight(NodeHighlight v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasNodeHighlight() => $_has(12);
  @$pb.TagNumber(13)
  void clearNodeHighlight() => clearField(13);
  @$pb.TagNumber(13)
  NodeHighlight ensureNodeHighlight() => $_ensure(12);

  ///
  ///  8 integers for screen calibration data
  @$pb.TagNumber(14)
  $core.List<$core.int> get calibrationData => $_getN(13);
  @$pb.TagNumber(14)
  set calibrationData($core.List<$core.int> v) { $_setBytes(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasCalibrationData() => $_has(13);
  @$pb.TagNumber(14)
  void clearCalibrationData() => clearField(14);

  ///
  ///  Map related data
  @$pb.TagNumber(15)
  Map_ get mapData => $_getN(14);
  @$pb.TagNumber(15)
  set mapData(Map_ v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasMapData() => $_has(14);
  @$pb.TagNumber(15)
  void clearMapData() => clearField(15);
  @$pb.TagNumber(15)
  Map_ ensureMapData() => $_ensure(14);
}

class NodeFilter extends $pb.GeneratedMessage {
  factory NodeFilter({
    $core.bool? unknownSwitch,
    $core.bool? offlineSwitch,
    $core.bool? publicKeySwitch,
    $core.int? hopsAway,
    $core.bool? positionSwitch,
    $core.String? nodeName,
    $core.int? channel,
  }) {
    final $result = create();
    if (unknownSwitch != null) {
      $result.unknownSwitch = unknownSwitch;
    }
    if (offlineSwitch != null) {
      $result.offlineSwitch = offlineSwitch;
    }
    if (publicKeySwitch != null) {
      $result.publicKeySwitch = publicKeySwitch;
    }
    if (hopsAway != null) {
      $result.hopsAway = hopsAway;
    }
    if (positionSwitch != null) {
      $result.positionSwitch = positionSwitch;
    }
    if (nodeName != null) {
      $result.nodeName = nodeName;
    }
    if (channel != null) {
      $result.channel = channel;
    }
    return $result;
  }
  NodeFilter._() : super();
  factory NodeFilter.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NodeFilter.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NodeFilter', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'unknownSwitch')
    ..aOB(2, _omitFieldNames ? '' : 'offlineSwitch')
    ..aOB(3, _omitFieldNames ? '' : 'publicKeySwitch')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'hopsAway', $pb.PbFieldType.O3)
    ..aOB(5, _omitFieldNames ? '' : 'positionSwitch')
    ..aOS(6, _omitFieldNames ? '' : 'nodeName')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'channel', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NodeFilter clone() => NodeFilter()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NodeFilter copyWith(void Function(NodeFilter) updates) => super.copyWith((message) => updates(message as NodeFilter)) as NodeFilter;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeFilter create() => NodeFilter._();
  NodeFilter createEmptyInstance() => create();
  static $pb.PbList<NodeFilter> createRepeated() => $pb.PbList<NodeFilter>();
  @$core.pragma('dart2js:noInline')
  static NodeFilter getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NodeFilter>(create);
  static NodeFilter? _defaultInstance;

  ///
  ///  Filter unknown nodes
  @$pb.TagNumber(1)
  $core.bool get unknownSwitch => $_getBF(0);
  @$pb.TagNumber(1)
  set unknownSwitch($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUnknownSwitch() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnknownSwitch() => clearField(1);

  ///
  ///  Filter offline nodes
  @$pb.TagNumber(2)
  $core.bool get offlineSwitch => $_getBF(1);
  @$pb.TagNumber(2)
  set offlineSwitch($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOfflineSwitch() => $_has(1);
  @$pb.TagNumber(2)
  void clearOfflineSwitch() => clearField(2);

  ///
  ///  Filter nodes w/o public key
  @$pb.TagNumber(3)
  $core.bool get publicKeySwitch => $_getBF(2);
  @$pb.TagNumber(3)
  set publicKeySwitch($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPublicKeySwitch() => $_has(2);
  @$pb.TagNumber(3)
  void clearPublicKeySwitch() => clearField(3);

  ///
  ///  Filter based on hops away
  @$pb.TagNumber(4)
  $core.int get hopsAway => $_getIZ(3);
  @$pb.TagNumber(4)
  set hopsAway($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasHopsAway() => $_has(3);
  @$pb.TagNumber(4)
  void clearHopsAway() => clearField(4);

  ///
  ///  Filter nodes w/o position
  @$pb.TagNumber(5)
  $core.bool get positionSwitch => $_getBF(4);
  @$pb.TagNumber(5)
  set positionSwitch($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPositionSwitch() => $_has(4);
  @$pb.TagNumber(5)
  void clearPositionSwitch() => clearField(5);

  ///
  ///  Filter nodes by matching name string
  @$pb.TagNumber(6)
  $core.String get nodeName => $_getSZ(5);
  @$pb.TagNumber(6)
  set nodeName($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasNodeName() => $_has(5);
  @$pb.TagNumber(6)
  void clearNodeName() => clearField(6);

  ///
  ///  Filter based on channel
  @$pb.TagNumber(7)
  $core.int get channel => $_getIZ(6);
  @$pb.TagNumber(7)
  set channel($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasChannel() => $_has(6);
  @$pb.TagNumber(7)
  void clearChannel() => clearField(7);
}

class NodeHighlight extends $pb.GeneratedMessage {
  factory NodeHighlight({
    $core.bool? chatSwitch,
    $core.bool? positionSwitch,
    $core.bool? telemetrySwitch,
    $core.bool? iaqSwitch,
    $core.String? nodeName,
  }) {
    final $result = create();
    if (chatSwitch != null) {
      $result.chatSwitch = chatSwitch;
    }
    if (positionSwitch != null) {
      $result.positionSwitch = positionSwitch;
    }
    if (telemetrySwitch != null) {
      $result.telemetrySwitch = telemetrySwitch;
    }
    if (iaqSwitch != null) {
      $result.iaqSwitch = iaqSwitch;
    }
    if (nodeName != null) {
      $result.nodeName = nodeName;
    }
    return $result;
  }
  NodeHighlight._() : super();
  factory NodeHighlight.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NodeHighlight.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NodeHighlight', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'chatSwitch')
    ..aOB(2, _omitFieldNames ? '' : 'positionSwitch')
    ..aOB(3, _omitFieldNames ? '' : 'telemetrySwitch')
    ..aOB(4, _omitFieldNames ? '' : 'iaqSwitch')
    ..aOS(5, _omitFieldNames ? '' : 'nodeName')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NodeHighlight clone() => NodeHighlight()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NodeHighlight copyWith(void Function(NodeHighlight) updates) => super.copyWith((message) => updates(message as NodeHighlight)) as NodeHighlight;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeHighlight create() => NodeHighlight._();
  NodeHighlight createEmptyInstance() => create();
  static $pb.PbList<NodeHighlight> createRepeated() => $pb.PbList<NodeHighlight>();
  @$core.pragma('dart2js:noInline')
  static NodeHighlight getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NodeHighlight>(create);
  static NodeHighlight? _defaultInstance;

  ///
  ///  Hightlight nodes w/ active chat
  @$pb.TagNumber(1)
  $core.bool get chatSwitch => $_getBF(0);
  @$pb.TagNumber(1)
  set chatSwitch($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatSwitch() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatSwitch() => clearField(1);

  ///
  ///  Highlight nodes w/ position
  @$pb.TagNumber(2)
  $core.bool get positionSwitch => $_getBF(1);
  @$pb.TagNumber(2)
  set positionSwitch($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPositionSwitch() => $_has(1);
  @$pb.TagNumber(2)
  void clearPositionSwitch() => clearField(2);

  ///
  ///  Highlight nodes w/ telemetry data
  @$pb.TagNumber(3)
  $core.bool get telemetrySwitch => $_getBF(2);
  @$pb.TagNumber(3)
  set telemetrySwitch($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTelemetrySwitch() => $_has(2);
  @$pb.TagNumber(3)
  void clearTelemetrySwitch() => clearField(3);

  ///
  ///  Highlight nodes w/ iaq data
  @$pb.TagNumber(4)
  $core.bool get iaqSwitch => $_getBF(3);
  @$pb.TagNumber(4)
  set iaqSwitch($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasIaqSwitch() => $_has(3);
  @$pb.TagNumber(4)
  void clearIaqSwitch() => clearField(4);

  ///
  ///  Highlight nodes by matching name string
  @$pb.TagNumber(5)
  $core.String get nodeName => $_getSZ(4);
  @$pb.TagNumber(5)
  set nodeName($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasNodeName() => $_has(4);
  @$pb.TagNumber(5)
  void clearNodeName() => clearField(5);
}

class GeoPoint extends $pb.GeneratedMessage {
  factory GeoPoint({
    $core.int? zoom,
    $core.int? latitude,
    $core.int? longitude,
  }) {
    final $result = create();
    if (zoom != null) {
      $result.zoom = zoom;
    }
    if (latitude != null) {
      $result.latitude = latitude;
    }
    if (longitude != null) {
      $result.longitude = longitude;
    }
    return $result;
  }
  GeoPoint._() : super();
  factory GeoPoint.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GeoPoint.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GeoPoint', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'zoom', $pb.PbFieldType.O3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'latitude', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'longitude', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GeoPoint clone() => GeoPoint()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GeoPoint copyWith(void Function(GeoPoint) updates) => super.copyWith((message) => updates(message as GeoPoint)) as GeoPoint;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GeoPoint create() => GeoPoint._();
  GeoPoint createEmptyInstance() => create();
  static $pb.PbList<GeoPoint> createRepeated() => $pb.PbList<GeoPoint>();
  @$core.pragma('dart2js:noInline')
  static GeoPoint getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GeoPoint>(create);
  static GeoPoint? _defaultInstance;

  ///
  ///  Zoom level
  @$pb.TagNumber(1)
  $core.int get zoom => $_getIZ(0);
  @$pb.TagNumber(1)
  set zoom($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasZoom() => $_has(0);
  @$pb.TagNumber(1)
  void clearZoom() => clearField(1);

  ///
  ///  Coordinate: latitude
  @$pb.TagNumber(2)
  $core.int get latitude => $_getIZ(1);
  @$pb.TagNumber(2)
  set latitude($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLatitude() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatitude() => clearField(2);

  ///
  ///  Coordinate: longitude
  @$pb.TagNumber(3)
  $core.int get longitude => $_getIZ(2);
  @$pb.TagNumber(3)
  set longitude($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLongitude() => $_has(2);
  @$pb.TagNumber(3)
  void clearLongitude() => clearField(3);
}

class Map_ extends $pb.GeneratedMessage {
  factory Map_({
    GeoPoint? home,
    $core.String? style,
    $core.bool? followGps,
  }) {
    final $result = create();
    if (home != null) {
      $result.home = home;
    }
    if (style != null) {
      $result.style = style;
    }
    if (followGps != null) {
      $result.followGps = followGps;
    }
    return $result;
  }
  Map_._() : super();
  factory Map_.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Map_.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Map', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..aOM<GeoPoint>(1, _omitFieldNames ? '' : 'home', subBuilder: GeoPoint.create)
    ..aOS(2, _omitFieldNames ? '' : 'style')
    ..aOB(3, _omitFieldNames ? '' : 'followGps')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Map_ clone() => Map_()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Map_ copyWith(void Function(Map_) updates) => super.copyWith((message) => updates(message as Map_)) as Map_;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Map_ create() => Map_._();
  Map_ createEmptyInstance() => create();
  static $pb.PbList<Map_> createRepeated() => $pb.PbList<Map_>();
  @$core.pragma('dart2js:noInline')
  static Map_ getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Map_>(create);
  static Map_? _defaultInstance;

  ///
  ///  Home coordinates
  @$pb.TagNumber(1)
  GeoPoint get home => $_getN(0);
  @$pb.TagNumber(1)
  set home(GeoPoint v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasHome() => $_has(0);
  @$pb.TagNumber(1)
  void clearHome() => clearField(1);
  @$pb.TagNumber(1)
  GeoPoint ensureHome() => $_ensure(0);

  ///
  ///  Map tile style
  @$pb.TagNumber(2)
  $core.String get style => $_getSZ(1);
  @$pb.TagNumber(2)
  set style($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStyle() => $_has(1);
  @$pb.TagNumber(2)
  void clearStyle() => clearField(2);

  ///
  ///  Map scroll follows GPS
  @$pb.TagNumber(3)
  $core.bool get followGps => $_getBF(2);
  @$pb.TagNumber(3)
  set followGps($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFollowGps() => $_has(2);
  @$pb.TagNumber(3)
  void clearFollowGps() => clearField(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');

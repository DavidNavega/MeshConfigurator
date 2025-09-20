//
//  Generated code. Do not modify.
//  source: meshtastic/clientonly.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'localonly.pb.dart' as $9;
import 'mesh.pb.dart' as $7;

///
///  This abstraction is used to contain any configuration for provisioning a node on any client.
///  It is useful for importing and exporting configurations.
class DeviceProfile extends $pb.GeneratedMessage {
  factory DeviceProfile({
    $core.String? longName,
    $core.String? shortName,
    $core.String? channelUrl,
    $9.LocalConfig? config,
    $9.LocalModuleConfig? moduleConfig,
    $7.Position? fixedPosition,
    $core.String? ringtone,
    $core.String? cannedMessages,
  }) {
    final $result = create();
    if (longName != null) {
      $result.longName = longName;
    }
    if (shortName != null) {
      $result.shortName = shortName;
    }
    if (channelUrl != null) {
      $result.channelUrl = channelUrl;
    }
    if (config != null) {
      $result.config = config;
    }
    if (moduleConfig != null) {
      $result.moduleConfig = moduleConfig;
    }
    if (fixedPosition != null) {
      $result.fixedPosition = fixedPosition;
    }
    if (ringtone != null) {
      $result.ringtone = ringtone;
    }
    if (cannedMessages != null) {
      $result.cannedMessages = cannedMessages;
    }
    return $result;
  }
  DeviceProfile._() : super();
  factory DeviceProfile.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeviceProfile.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeviceProfile', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'longName')
    ..aOS(2, _omitFieldNames ? '' : 'shortName')
    ..aOS(3, _omitFieldNames ? '' : 'channelUrl')
    ..aOM<$9.LocalConfig>(4, _omitFieldNames ? '' : 'config', subBuilder: $9.LocalConfig.create)
    ..aOM<$9.LocalModuleConfig>(5, _omitFieldNames ? '' : 'moduleConfig', subBuilder: $9.LocalModuleConfig.create)
    ..aOM<$7.Position>(6, _omitFieldNames ? '' : 'fixedPosition', subBuilder: $7.Position.create)
    ..aOS(7, _omitFieldNames ? '' : 'ringtone')
    ..aOS(8, _omitFieldNames ? '' : 'cannedMessages')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeviceProfile clone() => DeviceProfile()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeviceProfile copyWith(void Function(DeviceProfile) updates) => super.copyWith((message) => updates(message as DeviceProfile)) as DeviceProfile;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceProfile create() => DeviceProfile._();
  DeviceProfile createEmptyInstance() => create();
  static $pb.PbList<DeviceProfile> createRepeated() => $pb.PbList<DeviceProfile>();
  @$core.pragma('dart2js:noInline')
  static DeviceProfile getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeviceProfile>(create);
  static DeviceProfile? _defaultInstance;

  ///
  ///  Long name for the node
  @$pb.TagNumber(1)
  $core.String get longName => $_getSZ(0);
  @$pb.TagNumber(1)
  set longName($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasLongName() => $_has(0);
  @$pb.TagNumber(1)
  void clearLongName() => clearField(1);

  ///
  ///  Short name of the node
  @$pb.TagNumber(2)
  $core.String get shortName => $_getSZ(1);
  @$pb.TagNumber(2)
  set shortName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasShortName() => $_has(1);
  @$pb.TagNumber(2)
  void clearShortName() => clearField(2);

  ///
  ///  The url of the channels from our node
  @$pb.TagNumber(3)
  $core.String get channelUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set channelUrl($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasChannelUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearChannelUrl() => clearField(3);

  ///
  ///  The Config of the node
  @$pb.TagNumber(4)
  $9.LocalConfig get config => $_getN(3);
  @$pb.TagNumber(4)
  set config($9.LocalConfig v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasConfig() => $_has(3);
  @$pb.TagNumber(4)
  void clearConfig() => clearField(4);
  @$pb.TagNumber(4)
  $9.LocalConfig ensureConfig() => $_ensure(3);

  ///
  ///  The ModuleConfig of the node
  @$pb.TagNumber(5)
  $9.LocalModuleConfig get moduleConfig => $_getN(4);
  @$pb.TagNumber(5)
  set moduleConfig($9.LocalModuleConfig v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasModuleConfig() => $_has(4);
  @$pb.TagNumber(5)
  void clearModuleConfig() => clearField(5);
  @$pb.TagNumber(5)
  $9.LocalModuleConfig ensureModuleConfig() => $_ensure(4);

  ///
  ///  Fixed position data
  @$pb.TagNumber(6)
  $7.Position get fixedPosition => $_getN(5);
  @$pb.TagNumber(6)
  set fixedPosition($7.Position v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasFixedPosition() => $_has(5);
  @$pb.TagNumber(6)
  void clearFixedPosition() => clearField(6);
  @$pb.TagNumber(6)
  $7.Position ensureFixedPosition() => $_ensure(5);

  ///
  ///  Ringtone for ExternalNotification
  @$pb.TagNumber(7)
  $core.String get ringtone => $_getSZ(6);
  @$pb.TagNumber(7)
  set ringtone($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasRingtone() => $_has(6);
  @$pb.TagNumber(7)
  void clearRingtone() => clearField(7);

  ///
  ///  Predefined messages for CannedMessage
  @$pb.TagNumber(8)
  $core.String get cannedMessages => $_getSZ(7);
  @$pb.TagNumber(8)
  set cannedMessages($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasCannedMessages() => $_has(7);
  @$pb.TagNumber(8)
  void clearCannedMessages() => clearField(8);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');

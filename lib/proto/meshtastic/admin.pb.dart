//
//  Generated code. Do not modify.
//  source: meshtastic/admin.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'admin.pbenum.dart';
import 'channel.pb.dart' as $4;
import 'config.pb.dart' as $2;
import 'connection_status.pb.dart' as $8;
import 'device_ui.pb.dart' as $0;
import 'mesh.pb.dart' as $7;
import 'module_config.pb.dart' as $3;

export 'admin.pbenum.dart';

enum AdminMessage_PayloadVariant {
  getChannelRequest, 
  getChannelResponse, 
  getOwnerRequest, 
  getOwnerResponse, 
  getConfigRequest, 
  getConfigResponse, 
  getModuleConfigRequest, 
  getModuleConfigResponse, 
  getCannedMessageModuleMessagesRequest, 
  getCannedMessageModuleMessagesResponse, 
  getDeviceMetadataRequest, 
  getDeviceMetadataResponse, 
  getRingtoneRequest, 
  getRingtoneResponse, 
  getDeviceConnectionStatusRequest, 
  getDeviceConnectionStatusResponse, 
  setHamMode, 
  getNodeRemoteHardwarePinsRequest, 
  getNodeRemoteHardwarePinsResponse, 
  enterDfuModeRequest, 
  deleteFileRequest, 
  setScale, 
  backupPreferences, 
  restorePreferences, 
  removeBackupPreferences, 
  setOwner, 
  setChannel, 
  setConfig, 
  setModuleConfig, 
  setCannedMessageModuleMessages, 
  setRingtoneMessage, 
  removeByNodenum, 
  setFavoriteNode, 
  removeFavoriteNode, 
  setFixedPosition, 
  removeFixedPosition, 
  setTimeOnly, 
  getUiConfigRequest, 
  getUiConfigResponse, 
  storeUiConfig, 
  setIgnoredNode, 
  removeIgnoredNode, 
  beginEditSettings, 
  commitEditSettings, 
  factoryResetDevice, 
  rebootOtaSeconds, 
  exitSimulator, 
  rebootSeconds, 
  shutdownSeconds, 
  factoryResetConfig, 
  nodedbReset, 
  notSet
}

///
///  This message is handled by the Admin module and is responsible for all settings/channel read/write operations.
///  This message is used to do settings operations to both remote AND local nodes.
///  (Prior to 1.2 these operations were done via special ToRadio operations)
class AdminMessage extends $pb.GeneratedMessage {
  factory AdminMessage({
    $core.int? getChannelRequest,
    $4.Channel? getChannelResponse,
    $core.bool? getOwnerRequest,
    $7.User? getOwnerResponse,
    AdminMessage_ConfigType? getConfigRequest,
    $2.Config? getConfigResponse,
    AdminMessage_ModuleConfigType? getModuleConfigRequest,
    $3.ModuleConfig? getModuleConfigResponse,
    $core.bool? getCannedMessageModuleMessagesRequest,
    $core.String? getCannedMessageModuleMessagesResponse,
    $core.bool? getDeviceMetadataRequest,
    $7.DeviceMetadata? getDeviceMetadataResponse,
    $core.bool? getRingtoneRequest,
    $core.String? getRingtoneResponse,
    $core.bool? getDeviceConnectionStatusRequest,
    $8.DeviceConnectionStatus? getDeviceConnectionStatusResponse,
    HamParameters? setHamMode,
    $core.bool? getNodeRemoteHardwarePinsRequest,
    NodeRemoteHardwarePinsResponse? getNodeRemoteHardwarePinsResponse,
    $core.bool? enterDfuModeRequest,
    $core.String? deleteFileRequest,
    $core.int? setScale,
    AdminMessage_BackupLocation? backupPreferences,
    AdminMessage_BackupLocation? restorePreferences,
    AdminMessage_BackupLocation? removeBackupPreferences,
    $7.User? setOwner,
    $4.Channel? setChannel,
    $2.Config? setConfig,
    $3.ModuleConfig? setModuleConfig,
    $core.String? setCannedMessageModuleMessages,
    $core.String? setRingtoneMessage,
    $core.int? removeByNodenum,
    $core.int? setFavoriteNode,
    $core.int? removeFavoriteNode,
    $7.Position? setFixedPosition,
    $core.bool? removeFixedPosition,
    $core.int? setTimeOnly,
    $core.bool? getUiConfigRequest,
    $0.DeviceUIConfig? getUiConfigResponse,
    $0.DeviceUIConfig? storeUiConfig,
    $core.int? setIgnoredNode,
    $core.int? removeIgnoredNode,
    $core.bool? beginEditSettings,
    $core.bool? commitEditSettings,
    $core.int? factoryResetDevice,
    $core.int? rebootOtaSeconds,
    $core.bool? exitSimulator,
    $core.int? rebootSeconds,
    $core.int? shutdownSeconds,
    $core.int? factoryResetConfig,
    $core.int? nodedbReset,
    $core.List<$core.int>? sessionPasskey,
  }) {
    final $result = create();
    if (getChannelRequest != null) {
      $result.getChannelRequest = getChannelRequest;
    }
    if (getChannelResponse != null) {
      $result.getChannelResponse = getChannelResponse;
    }
    if (getOwnerRequest != null) {
      $result.getOwnerRequest = getOwnerRequest;
    }
    if (getOwnerResponse != null) {
      $result.getOwnerResponse = getOwnerResponse;
    }
    if (getConfigRequest != null) {
      $result.getConfigRequest = getConfigRequest;
    }
    if (getConfigResponse != null) {
      $result.getConfigResponse = getConfigResponse;
    }
    if (getModuleConfigRequest != null) {
      $result.getModuleConfigRequest = getModuleConfigRequest;
    }
    if (getModuleConfigResponse != null) {
      $result.getModuleConfigResponse = getModuleConfigResponse;
    }
    if (getCannedMessageModuleMessagesRequest != null) {
      $result.getCannedMessageModuleMessagesRequest = getCannedMessageModuleMessagesRequest;
    }
    if (getCannedMessageModuleMessagesResponse != null) {
      $result.getCannedMessageModuleMessagesResponse = getCannedMessageModuleMessagesResponse;
    }
    if (getDeviceMetadataRequest != null) {
      $result.getDeviceMetadataRequest = getDeviceMetadataRequest;
    }
    if (getDeviceMetadataResponse != null) {
      $result.getDeviceMetadataResponse = getDeviceMetadataResponse;
    }
    if (getRingtoneRequest != null) {
      $result.getRingtoneRequest = getRingtoneRequest;
    }
    if (getRingtoneResponse != null) {
      $result.getRingtoneResponse = getRingtoneResponse;
    }
    if (getDeviceConnectionStatusRequest != null) {
      $result.getDeviceConnectionStatusRequest = getDeviceConnectionStatusRequest;
    }
    if (getDeviceConnectionStatusResponse != null) {
      $result.getDeviceConnectionStatusResponse = getDeviceConnectionStatusResponse;
    }
    if (setHamMode != null) {
      $result.setHamMode = setHamMode;
    }
    if (getNodeRemoteHardwarePinsRequest != null) {
      $result.getNodeRemoteHardwarePinsRequest = getNodeRemoteHardwarePinsRequest;
    }
    if (getNodeRemoteHardwarePinsResponse != null) {
      $result.getNodeRemoteHardwarePinsResponse = getNodeRemoteHardwarePinsResponse;
    }
    if (enterDfuModeRequest != null) {
      $result.enterDfuModeRequest = enterDfuModeRequest;
    }
    if (deleteFileRequest != null) {
      $result.deleteFileRequest = deleteFileRequest;
    }
    if (setScale != null) {
      $result.setScale = setScale;
    }
    if (backupPreferences != null) {
      $result.backupPreferences = backupPreferences;
    }
    if (restorePreferences != null) {
      $result.restorePreferences = restorePreferences;
    }
    if (removeBackupPreferences != null) {
      $result.removeBackupPreferences = removeBackupPreferences;
    }
    if (setOwner != null) {
      $result.setOwner = setOwner;
    }
    if (setChannel != null) {
      $result.setChannel = setChannel;
    }
    if (setConfig != null) {
      $result.setConfig = setConfig;
    }
    if (setModuleConfig != null) {
      $result.setModuleConfig = setModuleConfig;
    }
    if (setCannedMessageModuleMessages != null) {
      $result.setCannedMessageModuleMessages = setCannedMessageModuleMessages;
    }
    if (setRingtoneMessage != null) {
      $result.setRingtoneMessage = setRingtoneMessage;
    }
    if (removeByNodenum != null) {
      $result.removeByNodenum = removeByNodenum;
    }
    if (setFavoriteNode != null) {
      $result.setFavoriteNode = setFavoriteNode;
    }
    if (removeFavoriteNode != null) {
      $result.removeFavoriteNode = removeFavoriteNode;
    }
    if (setFixedPosition != null) {
      $result.setFixedPosition = setFixedPosition;
    }
    if (removeFixedPosition != null) {
      $result.removeFixedPosition = removeFixedPosition;
    }
    if (setTimeOnly != null) {
      $result.setTimeOnly = setTimeOnly;
    }
    if (getUiConfigRequest != null) {
      $result.getUiConfigRequest = getUiConfigRequest;
    }
    if (getUiConfigResponse != null) {
      $result.getUiConfigResponse = getUiConfigResponse;
    }
    if (storeUiConfig != null) {
      $result.storeUiConfig = storeUiConfig;
    }
    if (setIgnoredNode != null) {
      $result.setIgnoredNode = setIgnoredNode;
    }
    if (removeIgnoredNode != null) {
      $result.removeIgnoredNode = removeIgnoredNode;
    }
    if (beginEditSettings != null) {
      $result.beginEditSettings = beginEditSettings;
    }
    if (commitEditSettings != null) {
      $result.commitEditSettings = commitEditSettings;
    }
    if (factoryResetDevice != null) {
      $result.factoryResetDevice = factoryResetDevice;
    }
    if (rebootOtaSeconds != null) {
      $result.rebootOtaSeconds = rebootOtaSeconds;
    }
    if (exitSimulator != null) {
      $result.exitSimulator = exitSimulator;
    }
    if (rebootSeconds != null) {
      $result.rebootSeconds = rebootSeconds;
    }
    if (shutdownSeconds != null) {
      $result.shutdownSeconds = shutdownSeconds;
    }
    if (factoryResetConfig != null) {
      $result.factoryResetConfig = factoryResetConfig;
    }
    if (nodedbReset != null) {
      $result.nodedbReset = nodedbReset;
    }
    if (sessionPasskey != null) {
      $result.sessionPasskey = sessionPasskey;
    }
    return $result;
  }
  AdminMessage._() : super();
  factory AdminMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AdminMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, AdminMessage_PayloadVariant> _AdminMessage_PayloadVariantByTag = {
    1 : AdminMessage_PayloadVariant.getChannelRequest,
    2 : AdminMessage_PayloadVariant.getChannelResponse,
    3 : AdminMessage_PayloadVariant.getOwnerRequest,
    4 : AdminMessage_PayloadVariant.getOwnerResponse,
    5 : AdminMessage_PayloadVariant.getConfigRequest,
    6 : AdminMessage_PayloadVariant.getConfigResponse,
    7 : AdminMessage_PayloadVariant.getModuleConfigRequest,
    8 : AdminMessage_PayloadVariant.getModuleConfigResponse,
    10 : AdminMessage_PayloadVariant.getCannedMessageModuleMessagesRequest,
    11 : AdminMessage_PayloadVariant.getCannedMessageModuleMessagesResponse,
    12 : AdminMessage_PayloadVariant.getDeviceMetadataRequest,
    13 : AdminMessage_PayloadVariant.getDeviceMetadataResponse,
    14 : AdminMessage_PayloadVariant.getRingtoneRequest,
    15 : AdminMessage_PayloadVariant.getRingtoneResponse,
    16 : AdminMessage_PayloadVariant.getDeviceConnectionStatusRequest,
    17 : AdminMessage_PayloadVariant.getDeviceConnectionStatusResponse,
    18 : AdminMessage_PayloadVariant.setHamMode,
    19 : AdminMessage_PayloadVariant.getNodeRemoteHardwarePinsRequest,
    20 : AdminMessage_PayloadVariant.getNodeRemoteHardwarePinsResponse,
    21 : AdminMessage_PayloadVariant.enterDfuModeRequest,
    22 : AdminMessage_PayloadVariant.deleteFileRequest,
    23 : AdminMessage_PayloadVariant.setScale,
    24 : AdminMessage_PayloadVariant.backupPreferences,
    25 : AdminMessage_PayloadVariant.restorePreferences,
    26 : AdminMessage_PayloadVariant.removeBackupPreferences,
    32 : AdminMessage_PayloadVariant.setOwner,
    33 : AdminMessage_PayloadVariant.setChannel,
    34 : AdminMessage_PayloadVariant.setConfig,
    35 : AdminMessage_PayloadVariant.setModuleConfig,
    36 : AdminMessage_PayloadVariant.setCannedMessageModuleMessages,
    37 : AdminMessage_PayloadVariant.setRingtoneMessage,
    38 : AdminMessage_PayloadVariant.removeByNodenum,
    39 : AdminMessage_PayloadVariant.setFavoriteNode,
    40 : AdminMessage_PayloadVariant.removeFavoriteNode,
    41 : AdminMessage_PayloadVariant.setFixedPosition,
    42 : AdminMessage_PayloadVariant.removeFixedPosition,
    43 : AdminMessage_PayloadVariant.setTimeOnly,
    44 : AdminMessage_PayloadVariant.getUiConfigRequest,
    45 : AdminMessage_PayloadVariant.getUiConfigResponse,
    46 : AdminMessage_PayloadVariant.storeUiConfig,
    47 : AdminMessage_PayloadVariant.setIgnoredNode,
    48 : AdminMessage_PayloadVariant.removeIgnoredNode,
    64 : AdminMessage_PayloadVariant.beginEditSettings,
    65 : AdminMessage_PayloadVariant.commitEditSettings,
    94 : AdminMessage_PayloadVariant.factoryResetDevice,
    95 : AdminMessage_PayloadVariant.rebootOtaSeconds,
    96 : AdminMessage_PayloadVariant.exitSimulator,
    97 : AdminMessage_PayloadVariant.rebootSeconds,
    98 : AdminMessage_PayloadVariant.shutdownSeconds,
    99 : AdminMessage_PayloadVariant.factoryResetConfig,
    100 : AdminMessage_PayloadVariant.nodedbReset,
    0 : AdminMessage_PayloadVariant.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AdminMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 64, 65, 94, 95, 96, 97, 98, 99, 100])
    ..a<$core.int>(1, _omitFieldNames ? '' : 'getChannelRequest', $pb.PbFieldType.OU3)
    ..aOM<$4.Channel>(2, _omitFieldNames ? '' : 'getChannelResponse', subBuilder: $4.Channel.create)
    ..aOB(3, _omitFieldNames ? '' : 'getOwnerRequest')
    ..aOM<$7.User>(4, _omitFieldNames ? '' : 'getOwnerResponse', subBuilder: $7.User.create)
    ..e<AdminMessage_ConfigType>(5, _omitFieldNames ? '' : 'getConfigRequest', $pb.PbFieldType.OE, defaultOrMaker: AdminMessage_ConfigType.DEVICE_CONFIG, valueOf: AdminMessage_ConfigType.valueOf, enumValues: AdminMessage_ConfigType.values)
    ..aOM<$2.Config>(6, _omitFieldNames ? '' : 'getConfigResponse', subBuilder: $2.Config.create)
    ..e<AdminMessage_ModuleConfigType>(7, _omitFieldNames ? '' : 'getModuleConfigRequest', $pb.PbFieldType.OE, defaultOrMaker: AdminMessage_ModuleConfigType.MQTT_CONFIG, valueOf: AdminMessage_ModuleConfigType.valueOf, enumValues: AdminMessage_ModuleConfigType.values)
    ..aOM<$3.ModuleConfig>(8, _omitFieldNames ? '' : 'getModuleConfigResponse', subBuilder: $3.ModuleConfig.create)
    ..aOB(10, _omitFieldNames ? '' : 'getCannedMessageModuleMessagesRequest')
    ..aOS(11, _omitFieldNames ? '' : 'getCannedMessageModuleMessagesResponse')
    ..aOB(12, _omitFieldNames ? '' : 'getDeviceMetadataRequest')
    ..aOM<$7.DeviceMetadata>(13, _omitFieldNames ? '' : 'getDeviceMetadataResponse', subBuilder: $7.DeviceMetadata.create)
    ..aOB(14, _omitFieldNames ? '' : 'getRingtoneRequest')
    ..aOS(15, _omitFieldNames ? '' : 'getRingtoneResponse')
    ..aOB(16, _omitFieldNames ? '' : 'getDeviceConnectionStatusRequest')
    ..aOM<$8.DeviceConnectionStatus>(17, _omitFieldNames ? '' : 'getDeviceConnectionStatusResponse', subBuilder: $8.DeviceConnectionStatus.create)
    ..aOM<HamParameters>(18, _omitFieldNames ? '' : 'setHamMode', subBuilder: HamParameters.create)
    ..aOB(19, _omitFieldNames ? '' : 'getNodeRemoteHardwarePinsRequest')
    ..aOM<NodeRemoteHardwarePinsResponse>(20, _omitFieldNames ? '' : 'getNodeRemoteHardwarePinsResponse', subBuilder: NodeRemoteHardwarePinsResponse.create)
    ..aOB(21, _omitFieldNames ? '' : 'enterDfuModeRequest')
    ..aOS(22, _omitFieldNames ? '' : 'deleteFileRequest')
    ..a<$core.int>(23, _omitFieldNames ? '' : 'setScale', $pb.PbFieldType.OU3)
    ..e<AdminMessage_BackupLocation>(24, _omitFieldNames ? '' : 'backupPreferences', $pb.PbFieldType.OE, defaultOrMaker: AdminMessage_BackupLocation.FLASH, valueOf: AdminMessage_BackupLocation.valueOf, enumValues: AdminMessage_BackupLocation.values)
    ..e<AdminMessage_BackupLocation>(25, _omitFieldNames ? '' : 'restorePreferences', $pb.PbFieldType.OE, defaultOrMaker: AdminMessage_BackupLocation.FLASH, valueOf: AdminMessage_BackupLocation.valueOf, enumValues: AdminMessage_BackupLocation.values)
    ..e<AdminMessage_BackupLocation>(26, _omitFieldNames ? '' : 'removeBackupPreferences', $pb.PbFieldType.OE, defaultOrMaker: AdminMessage_BackupLocation.FLASH, valueOf: AdminMessage_BackupLocation.valueOf, enumValues: AdminMessage_BackupLocation.values)
    ..aOM<$7.User>(32, _omitFieldNames ? '' : 'setOwner', subBuilder: $7.User.create)
    ..aOM<$4.Channel>(33, _omitFieldNames ? '' : 'setChannel', subBuilder: $4.Channel.create)
    ..aOM<$2.Config>(34, _omitFieldNames ? '' : 'setConfig', subBuilder: $2.Config.create)
    ..aOM<$3.ModuleConfig>(35, _omitFieldNames ? '' : 'setModuleConfig', subBuilder: $3.ModuleConfig.create)
    ..aOS(36, _omitFieldNames ? '' : 'setCannedMessageModuleMessages')
    ..aOS(37, _omitFieldNames ? '' : 'setRingtoneMessage')
    ..a<$core.int>(38, _omitFieldNames ? '' : 'removeByNodenum', $pb.PbFieldType.OU3)
    ..a<$core.int>(39, _omitFieldNames ? '' : 'setFavoriteNode', $pb.PbFieldType.OU3)
    ..a<$core.int>(40, _omitFieldNames ? '' : 'removeFavoriteNode', $pb.PbFieldType.OU3)
    ..aOM<$7.Position>(41, _omitFieldNames ? '' : 'setFixedPosition', subBuilder: $7.Position.create)
    ..aOB(42, _omitFieldNames ? '' : 'removeFixedPosition')
    ..a<$core.int>(43, _omitFieldNames ? '' : 'setTimeOnly', $pb.PbFieldType.OF3)
    ..aOB(44, _omitFieldNames ? '' : 'getUiConfigRequest')
    ..aOM<$0.DeviceUIConfig>(45, _omitFieldNames ? '' : 'getUiConfigResponse', subBuilder: $0.DeviceUIConfig.create)
    ..aOM<$0.DeviceUIConfig>(46, _omitFieldNames ? '' : 'storeUiConfig', subBuilder: $0.DeviceUIConfig.create)
    ..a<$core.int>(47, _omitFieldNames ? '' : 'setIgnoredNode', $pb.PbFieldType.OU3)
    ..a<$core.int>(48, _omitFieldNames ? '' : 'removeIgnoredNode', $pb.PbFieldType.OU3)
    ..aOB(64, _omitFieldNames ? '' : 'beginEditSettings')
    ..aOB(65, _omitFieldNames ? '' : 'commitEditSettings')
    ..a<$core.int>(94, _omitFieldNames ? '' : 'factoryResetDevice', $pb.PbFieldType.O3)
    ..a<$core.int>(95, _omitFieldNames ? '' : 'rebootOtaSeconds', $pb.PbFieldType.O3)
    ..aOB(96, _omitFieldNames ? '' : 'exitSimulator')
    ..a<$core.int>(97, _omitFieldNames ? '' : 'rebootSeconds', $pb.PbFieldType.O3)
    ..a<$core.int>(98, _omitFieldNames ? '' : 'shutdownSeconds', $pb.PbFieldType.O3)
    ..a<$core.int>(99, _omitFieldNames ? '' : 'factoryResetConfig', $pb.PbFieldType.O3)
    ..a<$core.int>(100, _omitFieldNames ? '' : 'nodedbReset', $pb.PbFieldType.O3)
    ..a<$core.List<$core.int>>(101, _omitFieldNames ? '' : 'sessionPasskey', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AdminMessage clone() => AdminMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AdminMessage copyWith(void Function(AdminMessage) updates) => super.copyWith((message) => updates(message as AdminMessage)) as AdminMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdminMessage create() => AdminMessage._();
  AdminMessage createEmptyInstance() => create();
  static $pb.PbList<AdminMessage> createRepeated() => $pb.PbList<AdminMessage>();
  @$core.pragma('dart2js:noInline')
  static AdminMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AdminMessage>(create);
  static AdminMessage? _defaultInstance;

  AdminMessage_PayloadVariant whichPayloadVariant() => _AdminMessage_PayloadVariantByTag[$_whichOneof(0)]!;
  void clearPayloadVariant() => clearField($_whichOneof(0));

  ///
  ///  Send the specified channel in the response to this message
  ///  NOTE: This field is sent with the channel index + 1 (to ensure we never try to send 'zero' - which protobufs treats as not present)
  @$pb.TagNumber(1)
  $core.int get getChannelRequest => $_getIZ(0);
  @$pb.TagNumber(1)
  set getChannelRequest($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGetChannelRequest() => $_has(0);
  @$pb.TagNumber(1)
  void clearGetChannelRequest() => clearField(1);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(2)
  $4.Channel get getChannelResponse => $_getN(1);
  @$pb.TagNumber(2)
  set getChannelResponse($4.Channel v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGetChannelResponse() => $_has(1);
  @$pb.TagNumber(2)
  void clearGetChannelResponse() => clearField(2);
  @$pb.TagNumber(2)
  $4.Channel ensureGetChannelResponse() => $_ensure(1);

  ///
  ///  Send the current owner data in the response to this message.
  @$pb.TagNumber(3)
  $core.bool get getOwnerRequest => $_getBF(2);
  @$pb.TagNumber(3)
  set getOwnerRequest($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasGetOwnerRequest() => $_has(2);
  @$pb.TagNumber(3)
  void clearGetOwnerRequest() => clearField(3);

  ///
  ///  TODO: REPLACE
  @$pb.TagNumber(4)
  $7.User get getOwnerResponse => $_getN(3);
  @$pb.TagNumber(4)
  set getOwnerResponse($7.User v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasGetOwnerResponse() => $_has(3);
  @$pb.TagNumber(4)
  void clearGetOwnerResponse() => clearField(4);
  @$pb.TagNumber(4)
  $7.User ensureGetOwnerResponse() => $_ensure(3);

  ///
  ///  Ask for the following config data to be sent
  @$pb.TagNumber(5)
  AdminMessage_ConfigType get getConfigRequest => $_getN(4);
  @$pb.TagNumber(5)
  set getConfigRequest(AdminMessage_ConfigType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasGetConfigRequest() => $_has(4);
  @$pb.TagNumber(5)
  void clearGetConfigRequest() => clearField(5);

  ///
  ///  Send the current Config in the response to this message.
  @$pb.TagNumber(6)
  $2.Config get getConfigResponse => $_getN(5);
  @$pb.TagNumber(6)
  set getConfigResponse($2.Config v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasGetConfigResponse() => $_has(5);
  @$pb.TagNumber(6)
  void clearGetConfigResponse() => clearField(6);
  @$pb.TagNumber(6)
  $2.Config ensureGetConfigResponse() => $_ensure(5);

  ///
  ///  Ask for the following config data to be sent
  @$pb.TagNumber(7)
  AdminMessage_ModuleConfigType get getModuleConfigRequest => $_getN(6);
  @$pb.TagNumber(7)
  set getModuleConfigRequest(AdminMessage_ModuleConfigType v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasGetModuleConfigRequest() => $_has(6);
  @$pb.TagNumber(7)
  void clearGetModuleConfigRequest() => clearField(7);

  ///
  ///  Send the current Config in the response to this message.
  @$pb.TagNumber(8)
  $3.ModuleConfig get getModuleConfigResponse => $_getN(7);
  @$pb.TagNumber(8)
  set getModuleConfigResponse($3.ModuleConfig v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasGetModuleConfigResponse() => $_has(7);
  @$pb.TagNumber(8)
  void clearGetModuleConfigResponse() => clearField(8);
  @$pb.TagNumber(8)
  $3.ModuleConfig ensureGetModuleConfigResponse() => $_ensure(7);

  ///
  ///  Get the Canned Message Module messages in the response to this message.
  @$pb.TagNumber(10)
  $core.bool get getCannedMessageModuleMessagesRequest => $_getBF(8);
  @$pb.TagNumber(10)
  set getCannedMessageModuleMessagesRequest($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(10)
  $core.bool hasGetCannedMessageModuleMessagesRequest() => $_has(8);
  @$pb.TagNumber(10)
  void clearGetCannedMessageModuleMessagesRequest() => clearField(10);

  ///
  ///  Get the Canned Message Module messages in the response to this message.
  @$pb.TagNumber(11)
  $core.String get getCannedMessageModuleMessagesResponse => $_getSZ(9);
  @$pb.TagNumber(11)
  set getCannedMessageModuleMessagesResponse($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(11)
  $core.bool hasGetCannedMessageModuleMessagesResponse() => $_has(9);
  @$pb.TagNumber(11)
  void clearGetCannedMessageModuleMessagesResponse() => clearField(11);

  ///
  ///  Request the node to send device metadata (firmware, protobuf version, etc)
  @$pb.TagNumber(12)
  $core.bool get getDeviceMetadataRequest => $_getBF(10);
  @$pb.TagNumber(12)
  set getDeviceMetadataRequest($core.bool v) { $_setBool(10, v); }
  @$pb.TagNumber(12)
  $core.bool hasGetDeviceMetadataRequest() => $_has(10);
  @$pb.TagNumber(12)
  void clearGetDeviceMetadataRequest() => clearField(12);

  ///
  ///  Device metadata response
  @$pb.TagNumber(13)
  $7.DeviceMetadata get getDeviceMetadataResponse => $_getN(11);
  @$pb.TagNumber(13)
  set getDeviceMetadataResponse($7.DeviceMetadata v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasGetDeviceMetadataResponse() => $_has(11);
  @$pb.TagNumber(13)
  void clearGetDeviceMetadataResponse() => clearField(13);
  @$pb.TagNumber(13)
  $7.DeviceMetadata ensureGetDeviceMetadataResponse() => $_ensure(11);

  ///
  ///  Get the Ringtone in the response to this message.
  @$pb.TagNumber(14)
  $core.bool get getRingtoneRequest => $_getBF(12);
  @$pb.TagNumber(14)
  set getRingtoneRequest($core.bool v) { $_setBool(12, v); }
  @$pb.TagNumber(14)
  $core.bool hasGetRingtoneRequest() => $_has(12);
  @$pb.TagNumber(14)
  void clearGetRingtoneRequest() => clearField(14);

  ///
  ///  Get the Ringtone in the response to this message.
  @$pb.TagNumber(15)
  $core.String get getRingtoneResponse => $_getSZ(13);
  @$pb.TagNumber(15)
  set getRingtoneResponse($core.String v) { $_setString(13, v); }
  @$pb.TagNumber(15)
  $core.bool hasGetRingtoneResponse() => $_has(13);
  @$pb.TagNumber(15)
  void clearGetRingtoneResponse() => clearField(15);

  ///
  ///  Request the node to send it's connection status
  @$pb.TagNumber(16)
  $core.bool get getDeviceConnectionStatusRequest => $_getBF(14);
  @$pb.TagNumber(16)
  set getDeviceConnectionStatusRequest($core.bool v) { $_setBool(14, v); }
  @$pb.TagNumber(16)
  $core.bool hasGetDeviceConnectionStatusRequest() => $_has(14);
  @$pb.TagNumber(16)
  void clearGetDeviceConnectionStatusRequest() => clearField(16);

  ///
  ///  Device connection status response
  @$pb.TagNumber(17)
  $8.DeviceConnectionStatus get getDeviceConnectionStatusResponse => $_getN(15);
  @$pb.TagNumber(17)
  set getDeviceConnectionStatusResponse($8.DeviceConnectionStatus v) { setField(17, v); }
  @$pb.TagNumber(17)
  $core.bool hasGetDeviceConnectionStatusResponse() => $_has(15);
  @$pb.TagNumber(17)
  void clearGetDeviceConnectionStatusResponse() => clearField(17);
  @$pb.TagNumber(17)
  $8.DeviceConnectionStatus ensureGetDeviceConnectionStatusResponse() => $_ensure(15);

  ///
  ///  Setup a node for licensed amateur (ham) radio operation
  @$pb.TagNumber(18)
  HamParameters get setHamMode => $_getN(16);
  @$pb.TagNumber(18)
  set setHamMode(HamParameters v) { setField(18, v); }
  @$pb.TagNumber(18)
  $core.bool hasSetHamMode() => $_has(16);
  @$pb.TagNumber(18)
  void clearSetHamMode() => clearField(18);
  @$pb.TagNumber(18)
  HamParameters ensureSetHamMode() => $_ensure(16);

  ///
  ///  Get the mesh's nodes with their available gpio pins for RemoteHardware module use
  @$pb.TagNumber(19)
  $core.bool get getNodeRemoteHardwarePinsRequest => $_getBF(17);
  @$pb.TagNumber(19)
  set getNodeRemoteHardwarePinsRequest($core.bool v) { $_setBool(17, v); }
  @$pb.TagNumber(19)
  $core.bool hasGetNodeRemoteHardwarePinsRequest() => $_has(17);
  @$pb.TagNumber(19)
  void clearGetNodeRemoteHardwarePinsRequest() => clearField(19);

  ///
  ///  Respond with the mesh's nodes with their available gpio pins for RemoteHardware module use
  @$pb.TagNumber(20)
  NodeRemoteHardwarePinsResponse get getNodeRemoteHardwarePinsResponse => $_getN(18);
  @$pb.TagNumber(20)
  set getNodeRemoteHardwarePinsResponse(NodeRemoteHardwarePinsResponse v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasGetNodeRemoteHardwarePinsResponse() => $_has(18);
  @$pb.TagNumber(20)
  void clearGetNodeRemoteHardwarePinsResponse() => clearField(20);
  @$pb.TagNumber(20)
  NodeRemoteHardwarePinsResponse ensureGetNodeRemoteHardwarePinsResponse() => $_ensure(18);

  ///
  ///  Enter (UF2) DFU mode
  ///  Only implemented on NRF52 currently
  @$pb.TagNumber(21)
  $core.bool get enterDfuModeRequest => $_getBF(19);
  @$pb.TagNumber(21)
  set enterDfuModeRequest($core.bool v) { $_setBool(19, v); }
  @$pb.TagNumber(21)
  $core.bool hasEnterDfuModeRequest() => $_has(19);
  @$pb.TagNumber(21)
  void clearEnterDfuModeRequest() => clearField(21);

  ///
  ///  Delete the file by the specified path from the device
  @$pb.TagNumber(22)
  $core.String get deleteFileRequest => $_getSZ(20);
  @$pb.TagNumber(22)
  set deleteFileRequest($core.String v) { $_setString(20, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeleteFileRequest() => $_has(20);
  @$pb.TagNumber(22)
  void clearDeleteFileRequest() => clearField(22);

  ///
  ///  Set zero and offset for scale chips
  @$pb.TagNumber(23)
  $core.int get setScale => $_getIZ(21);
  @$pb.TagNumber(23)
  set setScale($core.int v) { $_setUnsignedInt32(21, v); }
  @$pb.TagNumber(23)
  $core.bool hasSetScale() => $_has(21);
  @$pb.TagNumber(23)
  void clearSetScale() => clearField(23);

  ///
  ///  Backup the node's preferences
  @$pb.TagNumber(24)
  AdminMessage_BackupLocation get backupPreferences => $_getN(22);
  @$pb.TagNumber(24)
  set backupPreferences(AdminMessage_BackupLocation v) { setField(24, v); }
  @$pb.TagNumber(24)
  $core.bool hasBackupPreferences() => $_has(22);
  @$pb.TagNumber(24)
  void clearBackupPreferences() => clearField(24);

  ///
  ///  Restore the node's preferences
  @$pb.TagNumber(25)
  AdminMessage_BackupLocation get restorePreferences => $_getN(23);
  @$pb.TagNumber(25)
  set restorePreferences(AdminMessage_BackupLocation v) { setField(25, v); }
  @$pb.TagNumber(25)
  $core.bool hasRestorePreferences() => $_has(23);
  @$pb.TagNumber(25)
  void clearRestorePreferences() => clearField(25);

  ///
  ///  Remove backups of the node's preferences
  @$pb.TagNumber(26)
  AdminMessage_BackupLocation get removeBackupPreferences => $_getN(24);
  @$pb.TagNumber(26)
  set removeBackupPreferences(AdminMessage_BackupLocation v) { setField(26, v); }
  @$pb.TagNumber(26)
  $core.bool hasRemoveBackupPreferences() => $_has(24);
  @$pb.TagNumber(26)
  void clearRemoveBackupPreferences() => clearField(26);

  ///
  ///  Set the owner for this node
  @$pb.TagNumber(32)
  $7.User get setOwner => $_getN(25);
  @$pb.TagNumber(32)
  set setOwner($7.User v) { setField(32, v); }
  @$pb.TagNumber(32)
  $core.bool hasSetOwner() => $_has(25);
  @$pb.TagNumber(32)
  void clearSetOwner() => clearField(32);
  @$pb.TagNumber(32)
  $7.User ensureSetOwner() => $_ensure(25);

  ///
  ///  Set channels (using the new API).
  ///  A special channel is the "primary channel".
  ///  The other records are secondary channels.
  ///  Note: only one channel can be marked as primary.
  ///  If the client sets a particular channel to be primary, the previous channel will be set to SECONDARY automatically.
  @$pb.TagNumber(33)
  $4.Channel get setChannel => $_getN(26);
  @$pb.TagNumber(33)
  set setChannel($4.Channel v) { setField(33, v); }
  @$pb.TagNumber(33)
  $core.bool hasSetChannel() => $_has(26);
  @$pb.TagNumber(33)
  void clearSetChannel() => clearField(33);
  @$pb.TagNumber(33)
  $4.Channel ensureSetChannel() => $_ensure(26);

  ///
  ///  Set the current Config
  @$pb.TagNumber(34)
  $2.Config get setConfig => $_getN(27);
  @$pb.TagNumber(34)
  set setConfig($2.Config v) { setField(34, v); }
  @$pb.TagNumber(34)
  $core.bool hasSetConfig() => $_has(27);
  @$pb.TagNumber(34)
  void clearSetConfig() => clearField(34);
  @$pb.TagNumber(34)
  $2.Config ensureSetConfig() => $_ensure(27);

  ///
  ///  Set the current Config
  @$pb.TagNumber(35)
  $3.ModuleConfig get setModuleConfig => $_getN(28);
  @$pb.TagNumber(35)
  set setModuleConfig($3.ModuleConfig v) { setField(35, v); }
  @$pb.TagNumber(35)
  $core.bool hasSetModuleConfig() => $_has(28);
  @$pb.TagNumber(35)
  void clearSetModuleConfig() => clearField(35);
  @$pb.TagNumber(35)
  $3.ModuleConfig ensureSetModuleConfig() => $_ensure(28);

  ///
  ///  Set the Canned Message Module messages text.
  @$pb.TagNumber(36)
  $core.String get setCannedMessageModuleMessages => $_getSZ(29);
  @$pb.TagNumber(36)
  set setCannedMessageModuleMessages($core.String v) { $_setString(29, v); }
  @$pb.TagNumber(36)
  $core.bool hasSetCannedMessageModuleMessages() => $_has(29);
  @$pb.TagNumber(36)
  void clearSetCannedMessageModuleMessages() => clearField(36);

  ///
  ///  Set the ringtone for ExternalNotification.
  @$pb.TagNumber(37)
  $core.String get setRingtoneMessage => $_getSZ(30);
  @$pb.TagNumber(37)
  set setRingtoneMessage($core.String v) { $_setString(30, v); }
  @$pb.TagNumber(37)
  $core.bool hasSetRingtoneMessage() => $_has(30);
  @$pb.TagNumber(37)
  void clearSetRingtoneMessage() => clearField(37);

  ///
  ///  Remove the node by the specified node-num from the NodeDB on the device
  @$pb.TagNumber(38)
  $core.int get removeByNodenum => $_getIZ(31);
  @$pb.TagNumber(38)
  set removeByNodenum($core.int v) { $_setUnsignedInt32(31, v); }
  @$pb.TagNumber(38)
  $core.bool hasRemoveByNodenum() => $_has(31);
  @$pb.TagNumber(38)
  void clearRemoveByNodenum() => clearField(38);

  ///
  ///  Set specified node-num to be favorited on the NodeDB on the device
  @$pb.TagNumber(39)
  $core.int get setFavoriteNode => $_getIZ(32);
  @$pb.TagNumber(39)
  set setFavoriteNode($core.int v) { $_setUnsignedInt32(32, v); }
  @$pb.TagNumber(39)
  $core.bool hasSetFavoriteNode() => $_has(32);
  @$pb.TagNumber(39)
  void clearSetFavoriteNode() => clearField(39);

  ///
  ///  Set specified node-num to be un-favorited on the NodeDB on the device
  @$pb.TagNumber(40)
  $core.int get removeFavoriteNode => $_getIZ(33);
  @$pb.TagNumber(40)
  set removeFavoriteNode($core.int v) { $_setUnsignedInt32(33, v); }
  @$pb.TagNumber(40)
  $core.bool hasRemoveFavoriteNode() => $_has(33);
  @$pb.TagNumber(40)
  void clearRemoveFavoriteNode() => clearField(40);

  ///
  ///  Set fixed position data on the node and then set the position.fixed_position = true
  @$pb.TagNumber(41)
  $7.Position get setFixedPosition => $_getN(34);
  @$pb.TagNumber(41)
  set setFixedPosition($7.Position v) { setField(41, v); }
  @$pb.TagNumber(41)
  $core.bool hasSetFixedPosition() => $_has(34);
  @$pb.TagNumber(41)
  void clearSetFixedPosition() => clearField(41);
  @$pb.TagNumber(41)
  $7.Position ensureSetFixedPosition() => $_ensure(34);

  ///
  ///  Clear fixed position coordinates and then set position.fixed_position = false
  @$pb.TagNumber(42)
  $core.bool get removeFixedPosition => $_getBF(35);
  @$pb.TagNumber(42)
  set removeFixedPosition($core.bool v) { $_setBool(35, v); }
  @$pb.TagNumber(42)
  $core.bool hasRemoveFixedPosition() => $_has(35);
  @$pb.TagNumber(42)
  void clearRemoveFixedPosition() => clearField(42);

  ///
  ///  Set time only on the node
  ///  Convenience method to set the time on the node (as Net quality) without any other position data
  @$pb.TagNumber(43)
  $core.int get setTimeOnly => $_getIZ(36);
  @$pb.TagNumber(43)
  set setTimeOnly($core.int v) { $_setUnsignedInt32(36, v); }
  @$pb.TagNumber(43)
  $core.bool hasSetTimeOnly() => $_has(36);
  @$pb.TagNumber(43)
  void clearSetTimeOnly() => clearField(43);

  ///
  ///  Tell the node to send the stored ui data.
  @$pb.TagNumber(44)
  $core.bool get getUiConfigRequest => $_getBF(37);
  @$pb.TagNumber(44)
  set getUiConfigRequest($core.bool v) { $_setBool(37, v); }
  @$pb.TagNumber(44)
  $core.bool hasGetUiConfigRequest() => $_has(37);
  @$pb.TagNumber(44)
  void clearGetUiConfigRequest() => clearField(44);

  ///
  ///  Reply stored device ui data.
  @$pb.TagNumber(45)
  $0.DeviceUIConfig get getUiConfigResponse => $_getN(38);
  @$pb.TagNumber(45)
  set getUiConfigResponse($0.DeviceUIConfig v) { setField(45, v); }
  @$pb.TagNumber(45)
  $core.bool hasGetUiConfigResponse() => $_has(38);
  @$pb.TagNumber(45)
  void clearGetUiConfigResponse() => clearField(45);
  @$pb.TagNumber(45)
  $0.DeviceUIConfig ensureGetUiConfigResponse() => $_ensure(38);

  ///
  ///  Tell the node to store UI data persistently.
  @$pb.TagNumber(46)
  $0.DeviceUIConfig get storeUiConfig => $_getN(39);
  @$pb.TagNumber(46)
  set storeUiConfig($0.DeviceUIConfig v) { setField(46, v); }
  @$pb.TagNumber(46)
  $core.bool hasStoreUiConfig() => $_has(39);
  @$pb.TagNumber(46)
  void clearStoreUiConfig() => clearField(46);
  @$pb.TagNumber(46)
  $0.DeviceUIConfig ensureStoreUiConfig() => $_ensure(39);

  ///
  ///  Set specified node-num to be ignored on the NodeDB on the device
  @$pb.TagNumber(47)
  $core.int get setIgnoredNode => $_getIZ(40);
  @$pb.TagNumber(47)
  set setIgnoredNode($core.int v) { $_setUnsignedInt32(40, v); }
  @$pb.TagNumber(47)
  $core.bool hasSetIgnoredNode() => $_has(40);
  @$pb.TagNumber(47)
  void clearSetIgnoredNode() => clearField(47);

  ///
  ///  Set specified node-num to be un-ignored on the NodeDB on the device
  @$pb.TagNumber(48)
  $core.int get removeIgnoredNode => $_getIZ(41);
  @$pb.TagNumber(48)
  set removeIgnoredNode($core.int v) { $_setUnsignedInt32(41, v); }
  @$pb.TagNumber(48)
  $core.bool hasRemoveIgnoredNode() => $_has(41);
  @$pb.TagNumber(48)
  void clearRemoveIgnoredNode() => clearField(48);

  ///
  ///  Begins an edit transaction for config, module config, owner, and channel settings changes
  ///  This will delay the standard *implicit* save to the file system and subsequent reboot behavior until committed (commit_edit_settings)
  @$pb.TagNumber(64)
  $core.bool get beginEditSettings => $_getBF(42);
  @$pb.TagNumber(64)
  set beginEditSettings($core.bool v) { $_setBool(42, v); }
  @$pb.TagNumber(64)
  $core.bool hasBeginEditSettings() => $_has(42);
  @$pb.TagNumber(64)
  void clearBeginEditSettings() => clearField(64);

  ///
  ///  Commits an open transaction for any edits made to config, module config, owner, and channel settings
  @$pb.TagNumber(65)
  $core.bool get commitEditSettings => $_getBF(43);
  @$pb.TagNumber(65)
  set commitEditSettings($core.bool v) { $_setBool(43, v); }
  @$pb.TagNumber(65)
  $core.bool hasCommitEditSettings() => $_has(43);
  @$pb.TagNumber(65)
  void clearCommitEditSettings() => clearField(65);

  ///
  ///  Tell the node to factory reset config everything; all device state and configuration will be returned to factory defaults and BLE bonds will be cleared.
  @$pb.TagNumber(94)
  $core.int get factoryResetDevice => $_getIZ(44);
  @$pb.TagNumber(94)
  set factoryResetDevice($core.int v) { $_setSignedInt32(44, v); }
  @$pb.TagNumber(94)
  $core.bool hasFactoryResetDevice() => $_has(44);
  @$pb.TagNumber(94)
  void clearFactoryResetDevice() => clearField(94);

  ///
  ///  Tell the node to reboot into the OTA Firmware in this many seconds (or <0 to cancel reboot)
  ///  Only Implemented for ESP32 Devices. This needs to be issued to send a new main firmware via bluetooth.
  @$pb.TagNumber(95)
  $core.int get rebootOtaSeconds => $_getIZ(45);
  @$pb.TagNumber(95)
  set rebootOtaSeconds($core.int v) { $_setSignedInt32(45, v); }
  @$pb.TagNumber(95)
  $core.bool hasRebootOtaSeconds() => $_has(45);
  @$pb.TagNumber(95)
  void clearRebootOtaSeconds() => clearField(95);

  ///
  ///  This message is only supported for the simulator Portduino build.
  ///  If received the simulator will exit successfully.
  @$pb.TagNumber(96)
  $core.bool get exitSimulator => $_getBF(46);
  @$pb.TagNumber(96)
  set exitSimulator($core.bool v) { $_setBool(46, v); }
  @$pb.TagNumber(96)
  $core.bool hasExitSimulator() => $_has(46);
  @$pb.TagNumber(96)
  void clearExitSimulator() => clearField(96);

  ///
  ///  Tell the node to reboot in this many seconds (or <0 to cancel reboot)
  @$pb.TagNumber(97)
  $core.int get rebootSeconds => $_getIZ(47);
  @$pb.TagNumber(97)
  set rebootSeconds($core.int v) { $_setSignedInt32(47, v); }
  @$pb.TagNumber(97)
  $core.bool hasRebootSeconds() => $_has(47);
  @$pb.TagNumber(97)
  void clearRebootSeconds() => clearField(97);

  ///
  ///  Tell the node to shutdown in this many seconds (or <0 to cancel shutdown)
  @$pb.TagNumber(98)
  $core.int get shutdownSeconds => $_getIZ(48);
  @$pb.TagNumber(98)
  set shutdownSeconds($core.int v) { $_setSignedInt32(48, v); }
  @$pb.TagNumber(98)
  $core.bool hasShutdownSeconds() => $_has(48);
  @$pb.TagNumber(98)
  void clearShutdownSeconds() => clearField(98);

  ///
  ///  Tell the node to factory reset config; all device state and configuration will be returned to factory defaults; BLE bonds will be preserved.
  @$pb.TagNumber(99)
  $core.int get factoryResetConfig => $_getIZ(49);
  @$pb.TagNumber(99)
  set factoryResetConfig($core.int v) { $_setSignedInt32(49, v); }
  @$pb.TagNumber(99)
  $core.bool hasFactoryResetConfig() => $_has(49);
  @$pb.TagNumber(99)
  void clearFactoryResetConfig() => clearField(99);

  ///
  ///  Tell the node to reset the nodedb.
  @$pb.TagNumber(100)
  $core.int get nodedbReset => $_getIZ(50);
  @$pb.TagNumber(100)
  set nodedbReset($core.int v) { $_setSignedInt32(50, v); }
  @$pb.TagNumber(100)
  $core.bool hasNodedbReset() => $_has(50);
  @$pb.TagNumber(100)
  void clearNodedbReset() => clearField(100);

  ///
  ///  The node generates this key and sends it with any get_x_response packets.
  ///  The client MUST include the same key with any set_x commands. Key expires after 300 seconds.
  ///  Prevents replay attacks for admin messages.
  @$pb.TagNumber(101)
  $core.List<$core.int> get sessionPasskey => $_getN(51);
  @$pb.TagNumber(101)
  set sessionPasskey($core.List<$core.int> v) { $_setBytes(51, v); }
  @$pb.TagNumber(101)
  $core.bool hasSessionPasskey() => $_has(51);
  @$pb.TagNumber(101)
  void clearSessionPasskey() => clearField(101);
}

///
///  Parameters for setting up Meshtastic for ameteur radio usage
class HamParameters extends $pb.GeneratedMessage {
  factory HamParameters({
    $core.String? callSign,
    $core.int? txPower,
    $core.double? frequency,
    $core.String? shortName,
  }) {
    final $result = create();
    if (callSign != null) {
      $result.callSign = callSign;
    }
    if (txPower != null) {
      $result.txPower = txPower;
    }
    if (frequency != null) {
      $result.frequency = frequency;
    }
    if (shortName != null) {
      $result.shortName = shortName;
    }
    return $result;
  }
  HamParameters._() : super();
  factory HamParameters.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HamParameters.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HamParameters', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'callSign')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'txPower', $pb.PbFieldType.O3)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'frequency', $pb.PbFieldType.OF)
    ..aOS(4, _omitFieldNames ? '' : 'shortName')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HamParameters clone() => HamParameters()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HamParameters copyWith(void Function(HamParameters) updates) => super.copyWith((message) => updates(message as HamParameters)) as HamParameters;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HamParameters create() => HamParameters._();
  HamParameters createEmptyInstance() => create();
  static $pb.PbList<HamParameters> createRepeated() => $pb.PbList<HamParameters>();
  @$core.pragma('dart2js:noInline')
  static HamParameters getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HamParameters>(create);
  static HamParameters? _defaultInstance;

  ///
  ///  Amateur radio call sign, eg. KD2ABC
  @$pb.TagNumber(1)
  $core.String get callSign => $_getSZ(0);
  @$pb.TagNumber(1)
  set callSign($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCallSign() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallSign() => clearField(1);

  ///
  ///  Transmit power in dBm at the LoRA transceiver, not including any amplification
  @$pb.TagNumber(2)
  $core.int get txPower => $_getIZ(1);
  @$pb.TagNumber(2)
  set txPower($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTxPower() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxPower() => clearField(2);

  ///
  ///  The selected frequency of LoRA operation
  ///  Please respect your local laws, regulations, and band plans.
  ///  Ensure your radio is capable of operating of the selected frequency before setting this.
  @$pb.TagNumber(3)
  $core.double get frequency => $_getN(2);
  @$pb.TagNumber(3)
  set frequency($core.double v) { $_setFloat(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFrequency() => $_has(2);
  @$pb.TagNumber(3)
  void clearFrequency() => clearField(3);

  ///
  ///  Optional short name of user
  @$pb.TagNumber(4)
  $core.String get shortName => $_getSZ(3);
  @$pb.TagNumber(4)
  set shortName($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasShortName() => $_has(3);
  @$pb.TagNumber(4)
  void clearShortName() => clearField(4);
}

///
///  Response envelope for node_remote_hardware_pins
class NodeRemoteHardwarePinsResponse extends $pb.GeneratedMessage {
  factory NodeRemoteHardwarePinsResponse({
    $core.Iterable<$7.NodeRemoteHardwarePin>? nodeRemoteHardwarePins,
  }) {
    final $result = create();
    if (nodeRemoteHardwarePins != null) {
      $result.nodeRemoteHardwarePins.addAll(nodeRemoteHardwarePins);
    }
    return $result;
  }
  NodeRemoteHardwarePinsResponse._() : super();
  factory NodeRemoteHardwarePinsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NodeRemoteHardwarePinsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NodeRemoteHardwarePinsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..pc<$7.NodeRemoteHardwarePin>(1, _omitFieldNames ? '' : 'nodeRemoteHardwarePins', $pb.PbFieldType.PM, subBuilder: $7.NodeRemoteHardwarePin.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NodeRemoteHardwarePinsResponse clone() => NodeRemoteHardwarePinsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NodeRemoteHardwarePinsResponse copyWith(void Function(NodeRemoteHardwarePinsResponse) updates) => super.copyWith((message) => updates(message as NodeRemoteHardwarePinsResponse)) as NodeRemoteHardwarePinsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeRemoteHardwarePinsResponse create() => NodeRemoteHardwarePinsResponse._();
  NodeRemoteHardwarePinsResponse createEmptyInstance() => create();
  static $pb.PbList<NodeRemoteHardwarePinsResponse> createRepeated() => $pb.PbList<NodeRemoteHardwarePinsResponse>();
  @$core.pragma('dart2js:noInline')
  static NodeRemoteHardwarePinsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NodeRemoteHardwarePinsResponse>(create);
  static NodeRemoteHardwarePinsResponse? _defaultInstance;

  ///
  ///  Nodes and their respective remote hardware GPIO pins
  @$pb.TagNumber(1)
  $core.List<$7.NodeRemoteHardwarePin> get nodeRemoteHardwarePins => $_getList(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');

//
//  Generated code. Do not modify.
//  source: meshtastic/interdevice.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'interdevice.pbenum.dart';

export 'interdevice.pbenum.dart';

enum SensorData_Data {
  floatValue, 
  uint32Value, 
  notSet
}

class SensorData extends $pb.GeneratedMessage {
  factory SensorData({
    MessageType? type,
    $core.double? floatValue,
    $core.int? uint32Value,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (floatValue != null) {
      $result.floatValue = floatValue;
    }
    if (uint32Value != null) {
      $result.uint32Value = uint32Value;
    }
    return $result;
  }
  SensorData._() : super();
  factory SensorData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SensorData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, SensorData_Data> _SensorData_DataByTag = {
    2 : SensorData_Data.floatValue,
    3 : SensorData_Data.uint32Value,
    0 : SensorData_Data.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SensorData', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..e<MessageType>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: MessageType.ACK, valueOf: MessageType.valueOf, enumValues: MessageType.values)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'floatValue', $pb.PbFieldType.OF)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'uint32Value', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SensorData clone() => SensorData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SensorData copyWith(void Function(SensorData) updates) => super.copyWith((message) => updates(message as SensorData)) as SensorData;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SensorData create() => SensorData._();
  SensorData createEmptyInstance() => create();
  static $pb.PbList<SensorData> createRepeated() => $pb.PbList<SensorData>();
  @$core.pragma('dart2js:noInline')
  static SensorData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SensorData>(create);
  static SensorData? _defaultInstance;

  SensorData_Data whichData() => _SensorData_DataByTag[$_whichOneof(0)]!;
  void clearData() => clearField($_whichOneof(0));

  /// The message type
  @$pb.TagNumber(1)
  MessageType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(MessageType v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get floatValue => $_getN(1);
  @$pb.TagNumber(2)
  set floatValue($core.double v) { $_setFloat(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFloatValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearFloatValue() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get uint32Value => $_getIZ(2);
  @$pb.TagNumber(3)
  set uint32Value($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUint32Value() => $_has(2);
  @$pb.TagNumber(3)
  void clearUint32Value() => clearField(3);
}

enum InterdeviceMessage_Data {
  nmea, 
  sensor, 
  notSet
}

class InterdeviceMessage extends $pb.GeneratedMessage {
  factory InterdeviceMessage({
    $core.String? nmea,
    SensorData? sensor,
  }) {
    final $result = create();
    if (nmea != null) {
      $result.nmea = nmea;
    }
    if (sensor != null) {
      $result.sensor = sensor;
    }
    return $result;
  }
  InterdeviceMessage._() : super();
  factory InterdeviceMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InterdeviceMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, InterdeviceMessage_Data> _InterdeviceMessage_DataByTag = {
    1 : InterdeviceMessage_Data.nmea,
    2 : InterdeviceMessage_Data.sensor,
    0 : InterdeviceMessage_Data.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InterdeviceMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'nmea')
    ..aOM<SensorData>(2, _omitFieldNames ? '' : 'sensor', subBuilder: SensorData.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InterdeviceMessage clone() => InterdeviceMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InterdeviceMessage copyWith(void Function(InterdeviceMessage) updates) => super.copyWith((message) => updates(message as InterdeviceMessage)) as InterdeviceMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InterdeviceMessage create() => InterdeviceMessage._();
  InterdeviceMessage createEmptyInstance() => create();
  static $pb.PbList<InterdeviceMessage> createRepeated() => $pb.PbList<InterdeviceMessage>();
  @$core.pragma('dart2js:noInline')
  static InterdeviceMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InterdeviceMessage>(create);
  static InterdeviceMessage? _defaultInstance;

  InterdeviceMessage_Data whichData() => _InterdeviceMessage_DataByTag[$_whichOneof(0)]!;
  void clearData() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get nmea => $_getSZ(0);
  @$pb.TagNumber(1)
  set nmea($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNmea() => $_has(0);
  @$pb.TagNumber(1)
  void clearNmea() => clearField(1);

  @$pb.TagNumber(2)
  SensorData get sensor => $_getN(1);
  @$pb.TagNumber(2)
  set sensor(SensorData v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasSensor() => $_has(1);
  @$pb.TagNumber(2)
  void clearSensor() => clearField(2);
  @$pb.TagNumber(2)
  SensorData ensureSensor() => $_ensure(1);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');

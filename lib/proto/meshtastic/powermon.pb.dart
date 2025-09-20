//
//  Generated code. Do not modify.
//  source: meshtastic/powermon.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'powermon.pbenum.dart';

export 'powermon.pbenum.dart';

///  Note: There are no 'PowerMon' messages normally in use (PowerMons are sent only as structured logs - slogs).
/// But we wrap our State enum in this message to effectively nest a namespace (without our linter yelling at us)
class PowerMon extends $pb.GeneratedMessage {
  factory PowerMon() => create();
  PowerMon._() : super();
  factory PowerMon.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PowerMon.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PowerMon', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PowerMon clone() => PowerMon()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PowerMon copyWith(void Function(PowerMon) updates) => super.copyWith((message) => updates(message as PowerMon)) as PowerMon;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PowerMon create() => PowerMon._();
  PowerMon createEmptyInstance() => create();
  static $pb.PbList<PowerMon> createRepeated() => $pb.PbList<PowerMon>();
  @$core.pragma('dart2js:noInline')
  static PowerMon getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PowerMon>(create);
  static PowerMon? _defaultInstance;
}

///
///  PowerStress testing support via the C++ PowerStress module
class PowerStressMessage extends $pb.GeneratedMessage {
  factory PowerStressMessage({
    PowerStressMessage_Opcode? cmd,
    $core.double? numSeconds,
  }) {
    final $result = create();
    if (cmd != null) {
      $result.cmd = cmd;
    }
    if (numSeconds != null) {
      $result.numSeconds = numSeconds;
    }
    return $result;
  }
  PowerStressMessage._() : super();
  factory PowerStressMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PowerStressMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PowerStressMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'meshtastic'), createEmptyInstance: create)
    ..e<PowerStressMessage_Opcode>(1, _omitFieldNames ? '' : 'cmd', $pb.PbFieldType.OE, defaultOrMaker: PowerStressMessage_Opcode.UNSET, valueOf: PowerStressMessage_Opcode.valueOf, enumValues: PowerStressMessage_Opcode.values)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'numSeconds', $pb.PbFieldType.OF)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PowerStressMessage clone() => PowerStressMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PowerStressMessage copyWith(void Function(PowerStressMessage) updates) => super.copyWith((message) => updates(message as PowerStressMessage)) as PowerStressMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PowerStressMessage create() => PowerStressMessage._();
  PowerStressMessage createEmptyInstance() => create();
  static $pb.PbList<PowerStressMessage> createRepeated() => $pb.PbList<PowerStressMessage>();
  @$core.pragma('dart2js:noInline')
  static PowerStressMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PowerStressMessage>(create);
  static PowerStressMessage? _defaultInstance;

  ///
  ///  What type of HardwareMessage is this?
  @$pb.TagNumber(1)
  PowerStressMessage_Opcode get cmd => $_getN(0);
  @$pb.TagNumber(1)
  set cmd(PowerStressMessage_Opcode v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCmd() => $_has(0);
  @$pb.TagNumber(1)
  void clearCmd() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get numSeconds => $_getN(1);
  @$pb.TagNumber(2)
  set numSeconds($core.double v) { $_setFloat(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNumSeconds() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumSeconds() => clearField(2);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');

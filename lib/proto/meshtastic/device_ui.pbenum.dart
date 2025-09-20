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

class Theme extends $pb.ProtobufEnum {
  static const Theme DARK = Theme._(0, _omitEnumNames ? '' : 'DARK');
  static const Theme LIGHT = Theme._(1, _omitEnumNames ? '' : 'LIGHT');
  static const Theme RED = Theme._(2, _omitEnumNames ? '' : 'RED');

  static const $core.List<Theme> values = <Theme> [
    DARK,
    LIGHT,
    RED,
  ];

  static final $core.Map<$core.int, Theme> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Theme? valueOf($core.int value) => _byValue[value];

  const Theme._($core.int v, $core.String n) : super(v, n);
}

///
///  Localization
class Language extends $pb.ProtobufEnum {
  static const Language ENGLISH = Language._(0, _omitEnumNames ? '' : 'ENGLISH');
  static const Language FRENCH = Language._(1, _omitEnumNames ? '' : 'FRENCH');
  static const Language GERMAN = Language._(2, _omitEnumNames ? '' : 'GERMAN');
  static const Language ITALIAN = Language._(3, _omitEnumNames ? '' : 'ITALIAN');
  static const Language PORTUGUESE = Language._(4, _omitEnumNames ? '' : 'PORTUGUESE');
  static const Language SPANISH = Language._(5, _omitEnumNames ? '' : 'SPANISH');
  static const Language SWEDISH = Language._(6, _omitEnumNames ? '' : 'SWEDISH');
  static const Language FINNISH = Language._(7, _omitEnumNames ? '' : 'FINNISH');
  static const Language POLISH = Language._(8, _omitEnumNames ? '' : 'POLISH');
  static const Language TURKISH = Language._(9, _omitEnumNames ? '' : 'TURKISH');
  static const Language SERBIAN = Language._(10, _omitEnumNames ? '' : 'SERBIAN');
  static const Language RUSSIAN = Language._(11, _omitEnumNames ? '' : 'RUSSIAN');
  static const Language DUTCH = Language._(12, _omitEnumNames ? '' : 'DUTCH');
  static const Language GREEK = Language._(13, _omitEnumNames ? '' : 'GREEK');
  static const Language NORWEGIAN = Language._(14, _omitEnumNames ? '' : 'NORWEGIAN');
  static const Language SLOVENIAN = Language._(15, _omitEnumNames ? '' : 'SLOVENIAN');
  static const Language SIMPLIFIED_CHINESE = Language._(30, _omitEnumNames ? '' : 'SIMPLIFIED_CHINESE');
  static const Language TRADITIONAL_CHINESE = Language._(31, _omitEnumNames ? '' : 'TRADITIONAL_CHINESE');

  static const $core.List<Language> values = <Language> [
    ENGLISH,
    FRENCH,
    GERMAN,
    ITALIAN,
    PORTUGUESE,
    SPANISH,
    SWEDISH,
    FINNISH,
    POLISH,
    TURKISH,
    SERBIAN,
    RUSSIAN,
    DUTCH,
    GREEK,
    NORWEGIAN,
    SLOVENIAN,
    SIMPLIFIED_CHINESE,
    TRADITIONAL_CHINESE,
  ];

  static final $core.Map<$core.int, Language> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Language? valueOf($core.int value) => _byValue[value];

  const Language._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');

//
//  Generated code. Do not modify.
//  source: meshtastic/telemetry.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

///
///  Supported I2C Sensors for telemetry in Meshtastic
class TelemetrySensorType extends $pb.ProtobufEnum {
  static const TelemetrySensorType SENSOR_UNSET = TelemetrySensorType._(0, _omitEnumNames ? '' : 'SENSOR_UNSET');
  static const TelemetrySensorType BME280 = TelemetrySensorType._(1, _omitEnumNames ? '' : 'BME280');
  static const TelemetrySensorType BME680 = TelemetrySensorType._(2, _omitEnumNames ? '' : 'BME680');
  static const TelemetrySensorType MCP9808 = TelemetrySensorType._(3, _omitEnumNames ? '' : 'MCP9808');
  static const TelemetrySensorType INA260 = TelemetrySensorType._(4, _omitEnumNames ? '' : 'INA260');
  static const TelemetrySensorType INA219 = TelemetrySensorType._(5, _omitEnumNames ? '' : 'INA219');
  static const TelemetrySensorType BMP280 = TelemetrySensorType._(6, _omitEnumNames ? '' : 'BMP280');
  static const TelemetrySensorType SHTC3 = TelemetrySensorType._(7, _omitEnumNames ? '' : 'SHTC3');
  static const TelemetrySensorType LPS22 = TelemetrySensorType._(8, _omitEnumNames ? '' : 'LPS22');
  static const TelemetrySensorType QMC6310 = TelemetrySensorType._(9, _omitEnumNames ? '' : 'QMC6310');
  static const TelemetrySensorType QMI8658 = TelemetrySensorType._(10, _omitEnumNames ? '' : 'QMI8658');
  static const TelemetrySensorType QMC5883L = TelemetrySensorType._(11, _omitEnumNames ? '' : 'QMC5883L');
  static const TelemetrySensorType SHT31 = TelemetrySensorType._(12, _omitEnumNames ? '' : 'SHT31');
  static const TelemetrySensorType PMSA003I = TelemetrySensorType._(13, _omitEnumNames ? '' : 'PMSA003I');
  static const TelemetrySensorType INA3221 = TelemetrySensorType._(14, _omitEnumNames ? '' : 'INA3221');
  static const TelemetrySensorType BMP085 = TelemetrySensorType._(15, _omitEnumNames ? '' : 'BMP085');
  static const TelemetrySensorType RCWL9620 = TelemetrySensorType._(16, _omitEnumNames ? '' : 'RCWL9620');
  static const TelemetrySensorType SHT4X = TelemetrySensorType._(17, _omitEnumNames ? '' : 'SHT4X');
  static const TelemetrySensorType VEML7700 = TelemetrySensorType._(18, _omitEnumNames ? '' : 'VEML7700');
  static const TelemetrySensorType MLX90632 = TelemetrySensorType._(19, _omitEnumNames ? '' : 'MLX90632');
  static const TelemetrySensorType OPT3001 = TelemetrySensorType._(20, _omitEnumNames ? '' : 'OPT3001');
  static const TelemetrySensorType LTR390UV = TelemetrySensorType._(21, _omitEnumNames ? '' : 'LTR390UV');
  static const TelemetrySensorType TSL25911FN = TelemetrySensorType._(22, _omitEnumNames ? '' : 'TSL25911FN');
  static const TelemetrySensorType AHT10 = TelemetrySensorType._(23, _omitEnumNames ? '' : 'AHT10');
  static const TelemetrySensorType DFROBOT_LARK = TelemetrySensorType._(24, _omitEnumNames ? '' : 'DFROBOT_LARK');
  static const TelemetrySensorType NAU7802 = TelemetrySensorType._(25, _omitEnumNames ? '' : 'NAU7802');
  static const TelemetrySensorType BMP3XX = TelemetrySensorType._(26, _omitEnumNames ? '' : 'BMP3XX');
  static const TelemetrySensorType ICM20948 = TelemetrySensorType._(27, _omitEnumNames ? '' : 'ICM20948');
  static const TelemetrySensorType MAX17048 = TelemetrySensorType._(28, _omitEnumNames ? '' : 'MAX17048');
  static const TelemetrySensorType CUSTOM_SENSOR = TelemetrySensorType._(29, _omitEnumNames ? '' : 'CUSTOM_SENSOR');
  static const TelemetrySensorType MAX30102 = TelemetrySensorType._(30, _omitEnumNames ? '' : 'MAX30102');
  static const TelemetrySensorType MLX90614 = TelemetrySensorType._(31, _omitEnumNames ? '' : 'MLX90614');
  static const TelemetrySensorType SCD4X = TelemetrySensorType._(32, _omitEnumNames ? '' : 'SCD4X');
  static const TelemetrySensorType RADSENS = TelemetrySensorType._(33, _omitEnumNames ? '' : 'RADSENS');
  static const TelemetrySensorType INA226 = TelemetrySensorType._(34, _omitEnumNames ? '' : 'INA226');
  static const TelemetrySensorType DFROBOT_RAIN = TelemetrySensorType._(35, _omitEnumNames ? '' : 'DFROBOT_RAIN');
  static const TelemetrySensorType DPS310 = TelemetrySensorType._(36, _omitEnumNames ? '' : 'DPS310');
  static const TelemetrySensorType RAK12035 = TelemetrySensorType._(37, _omitEnumNames ? '' : 'RAK12035');

  static const $core.List<TelemetrySensorType> values = <TelemetrySensorType> [
    SENSOR_UNSET,
    BME280,
    BME680,
    MCP9808,
    INA260,
    INA219,
    BMP280,
    SHTC3,
    LPS22,
    QMC6310,
    QMI8658,
    QMC5883L,
    SHT31,
    PMSA003I,
    INA3221,
    BMP085,
    RCWL9620,
    SHT4X,
    VEML7700,
    MLX90632,
    OPT3001,
    LTR390UV,
    TSL25911FN,
    AHT10,
    DFROBOT_LARK,
    NAU7802,
    BMP3XX,
    ICM20948,
    MAX17048,
    CUSTOM_SENSOR,
    MAX30102,
    MLX90614,
    SCD4X,
    RADSENS,
    INA226,
    DFROBOT_RAIN,
    DPS310,
    RAK12035,
  ];

  static final $core.Map<$core.int, TelemetrySensorType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TelemetrySensorType? valueOf($core.int value) => _byValue[value];

  const TelemetrySensorType._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');

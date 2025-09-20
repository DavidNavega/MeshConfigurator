// This is a generated file - do not edit.
//
// Generated from meshtastic/config.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use configDescriptor instead')
const Config$json = {
  '1': 'Config',
  '2': [
    {
      '1': 'device',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.DeviceConfig',
      '9': 0,
      '10': 'device'
    },
    {
      '1': 'position',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.PositionConfig',
      '9': 0,
      '10': 'position'
    },
    {
      '1': 'power',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.PowerConfig',
      '9': 0,
      '10': 'power'
    },
    {
      '1': 'network',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.NetworkConfig',
      '9': 0,
      '10': 'network'
    },
    {
      '1': 'display',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.DisplayConfig',
      '9': 0,
      '10': 'display'
    },
    {
      '1': 'lora',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.LoRaConfig',
      '9': 0,
      '10': 'lora'
    },
    {
      '1': 'bluetooth',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.BluetoothConfig',
      '9': 0,
      '10': 'bluetooth'
    },
    {
      '1': 'security',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.SecurityConfig',
      '9': 0,
      '10': 'security'
    },
    {
      '1': 'sessionkey',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.SessionkeyConfig',
      '9': 0,
      '10': 'sessionkey'
    },
    {
      '1': 'device_ui',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DeviceUIConfig',
      '9': 0,
      '10': 'deviceUi'
    },
  ],
  '3': [
    Config_DeviceConfig$json,
    Config_PositionConfig$json,
    Config_PowerConfig$json,
    Config_NetworkConfig$json,
    Config_DisplayConfig$json,
    Config_LoRaConfig$json,
    Config_BluetoothConfig$json,
    Config_SecurityConfig$json,
    Config_SessionkeyConfig$json
  ],
  '8': [
    {'1': 'payload_variant'},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DeviceConfig$json = {
  '1': 'DeviceConfig',
  '2': [
    {
      '1': 'role',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DeviceConfig.Role',
      '10': 'role'
    },
    {
      '1': 'serial_enabled',
      '3': 2,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'serialEnabled',
    },
    {'1': 'button_gpio', '3': 4, '4': 1, '5': 13, '10': 'buttonGpio'},
    {'1': 'buzzer_gpio', '3': 5, '4': 1, '5': 13, '10': 'buzzerGpio'},
    {
      '1': 'rebroadcast_mode',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DeviceConfig.RebroadcastMode',
      '10': 'rebroadcastMode'
    },
    {
      '1': 'node_info_broadcast_secs',
      '3': 7,
      '4': 1,
      '5': 13,
      '10': 'nodeInfoBroadcastSecs'
    },
    {
      '1': 'double_tap_as_button_press',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'doubleTapAsButtonPress'
    },
    {
      '1': 'is_managed',
      '3': 9,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'isManaged',
    },
    {
      '1': 'disable_triple_click',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'disableTripleClick'
    },
    {'1': 'tzdef', '3': 11, '4': 1, '5': 9, '10': 'tzdef'},
    {
      '1': 'led_heartbeat_disabled',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'ledHeartbeatDisabled'
    },
  ],
  '4': [
    Config_DeviceConfig_Role$json,
    Config_DeviceConfig_RebroadcastMode$json
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DeviceConfig_Role$json = {
  '1': 'Role',
  '2': [
    {'1': 'CLIENT', '2': 0},
    {'1': 'CLIENT_MUTE', '2': 1},
    {'1': 'ROUTER', '2': 2},
    {
      '1': 'ROUTER_CLIENT',
      '2': 3,
      '3': {'1': true},
    },
    {'1': 'REPEATER', '2': 4},
    {'1': 'TRACKER', '2': 5},
    {'1': 'SENSOR', '2': 6},
    {'1': 'TAK', '2': 7},
    {'1': 'CLIENT_HIDDEN', '2': 8},
    {'1': 'LOST_AND_FOUND', '2': 9},
    {'1': 'TAK_TRACKER', '2': 10},
    {'1': 'ROUTER_LATE', '2': 11},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DeviceConfig_RebroadcastMode$json = {
  '1': 'RebroadcastMode',
  '2': [
    {'1': 'ALL', '2': 0},
    {'1': 'ALL_SKIP_DECODING', '2': 1},
    {'1': 'LOCAL_ONLY', '2': 2},
    {'1': 'KNOWN_ONLY', '2': 3},
    {'1': 'NONE', '2': 4},
    {'1': 'CORE_PORTNUMS_ONLY', '2': 5},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_PositionConfig$json = {
  '1': 'PositionConfig',
  '2': [
    {
      '1': 'position_broadcast_secs',
      '3': 1,
      '4': 1,
      '5': 13,
      '10': 'positionBroadcastSecs'
    },
    {
      '1': 'position_broadcast_smart_enabled',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'positionBroadcastSmartEnabled'
    },
    {'1': 'fixed_position', '3': 3, '4': 1, '5': 8, '10': 'fixedPosition'},
    {
      '1': 'gps_enabled',
      '3': 4,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'gpsEnabled',
    },
    {
      '1': 'gps_update_interval',
      '3': 5,
      '4': 1,
      '5': 13,
      '10': 'gpsUpdateInterval'
    },
    {
      '1': 'gps_attempt_time',
      '3': 6,
      '4': 1,
      '5': 13,
      '8': {'3': true},
      '10': 'gpsAttemptTime',
    },
    {'1': 'position_flags', '3': 7, '4': 1, '5': 13, '10': 'positionFlags'},
    {'1': 'rx_gpio', '3': 8, '4': 1, '5': 13, '10': 'rxGpio'},
    {'1': 'tx_gpio', '3': 9, '4': 1, '5': 13, '10': 'txGpio'},
    {
      '1': 'broadcast_smart_minimum_distance',
      '3': 10,
      '4': 1,
      '5': 13,
      '10': 'broadcastSmartMinimumDistance'
    },
    {
      '1': 'broadcast_smart_minimum_interval_secs',
      '3': 11,
      '4': 1,
      '5': 13,
      '10': 'broadcastSmartMinimumIntervalSecs'
    },
    {'1': 'gps_en_gpio', '3': 12, '4': 1, '5': 13, '10': 'gpsEnGpio'},
    {
      '1': 'gps_mode',
      '3': 13,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.PositionConfig.GpsMode',
      '10': 'gpsMode'
    },
  ],
  '4': [
    Config_PositionConfig_PositionFlags$json,
    Config_PositionConfig_GpsMode$json
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_PositionConfig_PositionFlags$json = {
  '1': 'PositionFlags',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'ALTITUDE', '2': 1},
    {'1': 'ALTITUDE_MSL', '2': 2},
    {'1': 'GEOIDAL_SEPARATION', '2': 4},
    {'1': 'DOP', '2': 8},
    {'1': 'HVDOP', '2': 16},
    {'1': 'SATINVIEW', '2': 32},
    {'1': 'SEQ_NO', '2': 64},
    {'1': 'TIMESTAMP', '2': 128},
    {'1': 'HEADING', '2': 256},
    {'1': 'SPEED', '2': 512},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_PositionConfig_GpsMode$json = {
  '1': 'GpsMode',
  '2': [
    {'1': 'DISABLED', '2': 0},
    {'1': 'ENABLED', '2': 1},
    {'1': 'NOT_PRESENT', '2': 2},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_PowerConfig$json = {
  '1': 'PowerConfig',
  '2': [
    {'1': 'is_power_saving', '3': 1, '4': 1, '5': 8, '10': 'isPowerSaving'},
    {
      '1': 'on_battery_shutdown_after_secs',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'onBatteryShutdownAfterSecs'
    },
    {
      '1': 'adc_multiplier_override',
      '3': 3,
      '4': 1,
      '5': 2,
      '10': 'adcMultiplierOverride'
    },
    {
      '1': 'wait_bluetooth_secs',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'waitBluetoothSecs'
    },
    {'1': 'sds_secs', '3': 6, '4': 1, '5': 13, '10': 'sdsSecs'},
    {'1': 'ls_secs', '3': 7, '4': 1, '5': 13, '10': 'lsSecs'},
    {'1': 'min_wake_secs', '3': 8, '4': 1, '5': 13, '10': 'minWakeSecs'},
    {
      '1': 'device_battery_ina_address',
      '3': 9,
      '4': 1,
      '5': 13,
      '10': 'deviceBatteryInaAddress'
    },
    {'1': 'powermon_enables', '3': 32, '4': 1, '5': 4, '10': 'powermonEnables'},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_NetworkConfig$json = {
  '1': 'NetworkConfig',
  '2': [
    {'1': 'wifi_enabled', '3': 1, '4': 1, '5': 8, '10': 'wifiEnabled'},
    {'1': 'wifi_ssid', '3': 3, '4': 1, '5': 9, '10': 'wifiSsid'},
    {'1': 'wifi_psk', '3': 4, '4': 1, '5': 9, '10': 'wifiPsk'},
    {'1': 'ntp_server', '3': 5, '4': 1, '5': 9, '10': 'ntpServer'},
    {'1': 'eth_enabled', '3': 6, '4': 1, '5': 8, '10': 'ethEnabled'},
    {
      '1': 'address_mode',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.NetworkConfig.AddressMode',
      '10': 'addressMode'
    },
    {
      '1': 'ipv4_config',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config.NetworkConfig.IpV4Config',
      '10': 'ipv4Config'
    },
    {'1': 'rsyslog_server', '3': 9, '4': 1, '5': 9, '10': 'rsyslogServer'},
    {
      '1': 'enabled_protocols',
      '3': 10,
      '4': 1,
      '5': 13,
      '10': 'enabledProtocols'
    },
  ],
  '3': [Config_NetworkConfig_IpV4Config$json],
  '4': [
    Config_NetworkConfig_AddressMode$json,
    Config_NetworkConfig_ProtocolFlags$json
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_NetworkConfig_IpV4Config$json = {
  '1': 'IpV4Config',
  '2': [
    {'1': 'ip', '3': 1, '4': 1, '5': 7, '10': 'ip'},
    {'1': 'gateway', '3': 2, '4': 1, '5': 7, '10': 'gateway'},
    {'1': 'subnet', '3': 3, '4': 1, '5': 7, '10': 'subnet'},
    {'1': 'dns', '3': 4, '4': 1, '5': 7, '10': 'dns'},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_NetworkConfig_AddressMode$json = {
  '1': 'AddressMode',
  '2': [
    {'1': 'DHCP', '2': 0},
    {'1': 'STATIC', '2': 1},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_NetworkConfig_ProtocolFlags$json = {
  '1': 'ProtocolFlags',
  '2': [
    {'1': 'NO_BROADCAST', '2': 0},
    {'1': 'UDP_BROADCAST', '2': 1},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig$json = {
  '1': 'DisplayConfig',
  '2': [
    {'1': 'screen_on_secs', '3': 1, '4': 1, '5': 13, '10': 'screenOnSecs'},
    {
      '1': 'gps_format',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DisplayConfig.GpsCoordinateFormat',
      '10': 'gpsFormat'
    },
    {
      '1': 'auto_screen_carousel_secs',
      '3': 3,
      '4': 1,
      '5': 13,
      '10': 'autoScreenCarouselSecs'
    },
    {'1': 'compass_north_top', '3': 4, '4': 1, '5': 8, '10': 'compassNorthTop'},
    {'1': 'flip_screen', '3': 5, '4': 1, '5': 8, '10': 'flipScreen'},
    {
      '1': 'units',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DisplayConfig.DisplayUnits',
      '10': 'units'
    },
    {
      '1': 'oled',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DisplayConfig.OledType',
      '10': 'oled'
    },
    {
      '1': 'displaymode',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DisplayConfig.DisplayMode',
      '10': 'displaymode'
    },
    {'1': 'heading_bold', '3': 9, '4': 1, '5': 8, '10': 'headingBold'},
    {
      '1': 'wake_on_tap_or_motion',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'wakeOnTapOrMotion'
    },
    {
      '1': 'compass_orientation',
      '3': 11,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.DisplayConfig.CompassOrientation',
      '10': 'compassOrientation'
    },
    {'1': 'use_12h_clock', '3': 12, '4': 1, '5': 8, '10': 'use12hClock'},
  ],
  '4': [
    Config_DisplayConfig_GpsCoordinateFormat$json,
    Config_DisplayConfig_DisplayUnits$json,
    Config_DisplayConfig_OledType$json,
    Config_DisplayConfig_DisplayMode$json,
    Config_DisplayConfig_CompassOrientation$json
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig_GpsCoordinateFormat$json = {
  '1': 'GpsCoordinateFormat',
  '2': [
    {'1': 'DEC', '2': 0},
    {'1': 'DMS', '2': 1},
    {'1': 'UTM', '2': 2},
    {'1': 'MGRS', '2': 3},
    {'1': 'OLC', '2': 4},
    {'1': 'OSGR', '2': 5},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig_DisplayUnits$json = {
  '1': 'DisplayUnits',
  '2': [
    {'1': 'METRIC', '2': 0},
    {'1': 'IMPERIAL', '2': 1},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig_OledType$json = {
  '1': 'OledType',
  '2': [
    {'1': 'OLED_AUTO', '2': 0},
    {'1': 'OLED_SSD1306', '2': 1},
    {'1': 'OLED_SH1106', '2': 2},
    {'1': 'OLED_SH1107', '2': 3},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig_DisplayMode$json = {
  '1': 'DisplayMode',
  '2': [
    {'1': 'DEFAULT', '2': 0},
    {'1': 'TWOCOLOR', '2': 1},
    {'1': 'INVERTED', '2': 2},
    {'1': 'COLOR', '2': 3},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_DisplayConfig_CompassOrientation$json = {
  '1': 'CompassOrientation',
  '2': [
    {'1': 'DEGREES_0', '2': 0},
    {'1': 'DEGREES_90', '2': 1},
    {'1': 'DEGREES_180', '2': 2},
    {'1': 'DEGREES_270', '2': 3},
    {'1': 'DEGREES_0_INVERTED', '2': 4},
    {'1': 'DEGREES_90_INVERTED', '2': 5},
    {'1': 'DEGREES_180_INVERTED', '2': 6},
    {'1': 'DEGREES_270_INVERTED', '2': 7},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_LoRaConfig$json = {
  '1': 'LoRaConfig',
  '2': [
    {'1': 'use_preset', '3': 1, '4': 1, '5': 8, '10': 'usePreset'},
    {
      '1': 'modem_preset',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.LoRaConfig.ModemPreset',
      '10': 'modemPreset'
    },
    {'1': 'bandwidth', '3': 3, '4': 1, '5': 13, '10': 'bandwidth'},
    {'1': 'spread_factor', '3': 4, '4': 1, '5': 13, '10': 'spreadFactor'},
    {'1': 'coding_rate', '3': 5, '4': 1, '5': 13, '10': 'codingRate'},
    {'1': 'frequency_offset', '3': 6, '4': 1, '5': 2, '10': 'frequencyOffset'},
    {
      '1': 'region',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.LoRaConfig.RegionCode',
      '10': 'region'
    },
    {'1': 'hop_limit', '3': 8, '4': 1, '5': 13, '10': 'hopLimit'},
    {'1': 'tx_enabled', '3': 9, '4': 1, '5': 8, '10': 'txEnabled'},
    {'1': 'tx_power', '3': 10, '4': 1, '5': 5, '10': 'txPower'},
    {'1': 'channel_num', '3': 11, '4': 1, '5': 13, '10': 'channelNum'},
    {
      '1': 'override_duty_cycle',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'overrideDutyCycle'
    },
    {
      '1': 'sx126x_rx_boosted_gain',
      '3': 13,
      '4': 1,
      '5': 8,
      '10': 'sx126xRxBoostedGain'
    },
    {
      '1': 'override_frequency',
      '3': 14,
      '4': 1,
      '5': 2,
      '10': 'overrideFrequency'
    },
    {'1': 'pa_fan_disabled', '3': 15, '4': 1, '5': 8, '10': 'paFanDisabled'},
    {'1': 'ignore_incoming', '3': 103, '4': 3, '5': 13, '10': 'ignoreIncoming'},
    {'1': 'ignore_mqtt', '3': 104, '4': 1, '5': 8, '10': 'ignoreMqtt'},
    {
      '1': 'config_ok_to_mqtt',
      '3': 105,
      '4': 1,
      '5': 8,
      '10': 'configOkToMqtt'
    },
  ],
  '4': [Config_LoRaConfig_RegionCode$json, Config_LoRaConfig_ModemPreset$json],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_LoRaConfig_RegionCode$json = {
  '1': 'RegionCode',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'US', '2': 1},
    {'1': 'EU_433', '2': 2},
    {'1': 'EU_868', '2': 3},
    {'1': 'CN', '2': 4},
    {'1': 'JP', '2': 5},
    {'1': 'ANZ', '2': 6},
    {'1': 'KR', '2': 7},
    {'1': 'TW', '2': 8},
    {'1': 'RU', '2': 9},
    {'1': 'IN', '2': 10},
    {'1': 'NZ_865', '2': 11},
    {'1': 'TH', '2': 12},
    {'1': 'LORA_24', '2': 13},
    {'1': 'UA_433', '2': 14},
    {'1': 'UA_868', '2': 15},
    {'1': 'MY_433', '2': 16},
    {'1': 'MY_919', '2': 17},
    {'1': 'SG_923', '2': 18},
    {'1': 'PH_433', '2': 19},
    {'1': 'PH_868', '2': 20},
    {'1': 'PH_915', '2': 21},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_LoRaConfig_ModemPreset$json = {
  '1': 'ModemPreset',
  '2': [
    {'1': 'LONG_FAST', '2': 0},
    {'1': 'LONG_SLOW', '2': 1},
    {
      '1': 'VERY_LONG_SLOW',
      '2': 2,
      '3': {'1': true},
    },
    {'1': 'MEDIUM_SLOW', '2': 3},
    {'1': 'MEDIUM_FAST', '2': 4},
    {'1': 'SHORT_SLOW', '2': 5},
    {'1': 'SHORT_FAST', '2': 6},
    {'1': 'LONG_MODERATE', '2': 7},
    {'1': 'SHORT_TURBO', '2': 8},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_BluetoothConfig$json = {
  '1': 'BluetoothConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {
      '1': 'mode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.Config.BluetoothConfig.PairingMode',
      '10': 'mode'
    },
    {'1': 'fixed_pin', '3': 3, '4': 1, '5': 13, '10': 'fixedPin'},
  ],
  '4': [Config_BluetoothConfig_PairingMode$json],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_BluetoothConfig_PairingMode$json = {
  '1': 'PairingMode',
  '2': [
    {'1': 'RANDOM_PIN', '2': 0},
    {'1': 'FIXED_PIN', '2': 1},
    {'1': 'NO_PIN', '2': 2},
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_SecurityConfig$json = {
  '1': 'SecurityConfig',
  '2': [
    {'1': 'public_key', '3': 1, '4': 1, '5': 12, '10': 'publicKey'},
    {'1': 'private_key', '3': 2, '4': 1, '5': 12, '10': 'privateKey'},
    {'1': 'admin_key', '3': 3, '4': 3, '5': 12, '10': 'adminKey'},
    {'1': 'is_managed', '3': 4, '4': 1, '5': 8, '10': 'isManaged'},
    {'1': 'serial_enabled', '3': 5, '4': 1, '5': 8, '10': 'serialEnabled'},
    {
      '1': 'debug_log_api_enabled',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'debugLogApiEnabled'
    },
    {
      '1': 'admin_channel_enabled',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'adminChannelEnabled'
    },
  ],
};

@$core.Deprecated('Use configDescriptor instead')
const Config_SessionkeyConfig$json = {
  '1': 'SessionkeyConfig',
};

/// Descriptor for `Config`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List configDescriptor = $convert.base64Decode(
    'CgZDb25maWcSOQoGZGV2aWNlGAEgASgLMh8ubWVzaHRhc3RpYy5Db25maWcuRGV2aWNlQ29uZm'
    'lnSABSBmRldmljZRI/Cghwb3NpdGlvbhgCIAEoCzIhLm1lc2h0YXN0aWMuQ29uZmlnLlBvc2l0'
    'aW9uQ29uZmlnSABSCHBvc2l0aW9uEjYKBXBvd2VyGAMgASgLMh4ubWVzaHRhc3RpYy5Db25maW'
    'cuUG93ZXJDb25maWdIAFIFcG93ZXISPAoHbmV0d29yaxgEIAEoCzIgLm1lc2h0YXN0aWMuQ29u'
    'ZmlnLk5ldHdvcmtDb25maWdIAFIHbmV0d29yaxI8CgdkaXNwbGF5GAUgASgLMiAubWVzaHRhc3'
    'RpYy5Db25maWcuRGlzcGxheUNvbmZpZ0gAUgdkaXNwbGF5EjMKBGxvcmEYBiABKAsyHS5tZXNo'
    'dGFzdGljLkNvbmZpZy5Mb1JhQ29uZmlnSABSBGxvcmESQgoJYmx1ZXRvb3RoGAcgASgLMiIubW'
    'VzaHRhc3RpYy5Db25maWcuQmx1ZXRvb3RoQ29uZmlnSABSCWJsdWV0b290aBI/CghzZWN1cml0'
    'eRgIIAEoCzIhLm1lc2h0YXN0aWMuQ29uZmlnLlNlY3VyaXR5Q29uZmlnSABSCHNlY3VyaXR5Ek'
    'UKCnNlc3Npb25rZXkYCSABKAsyIy5tZXNodGFzdGljLkNvbmZpZy5TZXNzaW9ua2V5Q29uZmln'
    'SABSCnNlc3Npb25rZXkSOQoJZGV2aWNlX3VpGAogASgLMhoubWVzaHRhc3RpYy5EZXZpY2VVSU'
    'NvbmZpZ0gAUghkZXZpY2VVaRreBgoMRGV2aWNlQ29uZmlnEjgKBHJvbGUYASABKA4yJC5tZXNo'
    'dGFzdGljLkNvbmZpZy5EZXZpY2VDb25maWcuUm9sZVIEcm9sZRIpCg5zZXJpYWxfZW5hYmxlZB'
    'gCIAEoCEICGAFSDXNlcmlhbEVuYWJsZWQSHwoLYnV0dG9uX2dwaW8YBCABKA1SCmJ1dHRvbkdw'
    'aW8SHwoLYnV6emVyX2dwaW8YBSABKA1SCmJ1enplckdwaW8SWgoQcmVicm9hZGNhc3RfbW9kZR'
    'gGIAEoDjIvLm1lc2h0YXN0aWMuQ29uZmlnLkRldmljZUNvbmZpZy5SZWJyb2FkY2FzdE1vZGVS'
    'D3JlYnJvYWRjYXN0TW9kZRI3Chhub2RlX2luZm9fYnJvYWRjYXN0X3NlY3MYByABKA1SFW5vZG'
    'VJbmZvQnJvYWRjYXN0U2VjcxI6Chpkb3VibGVfdGFwX2FzX2J1dHRvbl9wcmVzcxgIIAEoCFIW'
    'ZG91YmxlVGFwQXNCdXR0b25QcmVzcxIhCgppc19tYW5hZ2VkGAkgASgIQgIYAVIJaXNNYW5hZ2'
    'VkEjAKFGRpc2FibGVfdHJpcGxlX2NsaWNrGAogASgIUhJkaXNhYmxlVHJpcGxlQ2xpY2sSFAoF'
    'dHpkZWYYCyABKAlSBXR6ZGVmEjQKFmxlZF9oZWFydGJlYXRfZGlzYWJsZWQYDCABKAhSFGxlZE'
    'hlYXJ0YmVhdERpc2FibGVkIr8BCgRSb2xlEgoKBkNMSUVOVBAAEg8KC0NMSUVOVF9NVVRFEAES'
    'CgoGUk9VVEVSEAISFQoNUk9VVEVSX0NMSUVOVBADGgIIARIMCghSRVBFQVRFUhAEEgsKB1RSQU'
    'NLRVIQBRIKCgZTRU5TT1IQBhIHCgNUQUsQBxIRCg1DTElFTlRfSElEREVOEAgSEgoOTE9TVF9B'
    'TkRfRk9VTkQQCRIPCgtUQUtfVFJBQ0tFUhAKEg8KC1JPVVRFUl9MQVRFEAsicwoPUmVicm9hZG'
    'Nhc3RNb2RlEgcKA0FMTBAAEhUKEUFMTF9TS0lQX0RFQ09ESU5HEAESDgoKTE9DQUxfT05MWRAC'
    'Eg4KCktOT1dOX09OTFkQAxIICgROT05FEAQSFgoSQ09SRV9QT1JUTlVNU19PTkxZEAUa+gYKDl'
    'Bvc2l0aW9uQ29uZmlnEjYKF3Bvc2l0aW9uX2Jyb2FkY2FzdF9zZWNzGAEgASgNUhVwb3NpdGlv'
    'bkJyb2FkY2FzdFNlY3MSRwogcG9zaXRpb25fYnJvYWRjYXN0X3NtYXJ0X2VuYWJsZWQYAiABKA'
    'hSHXBvc2l0aW9uQnJvYWRjYXN0U21hcnRFbmFibGVkEiUKDmZpeGVkX3Bvc2l0aW9uGAMgASgI'
    'Ug1maXhlZFBvc2l0aW9uEiMKC2dwc19lbmFibGVkGAQgASgIQgIYAVIKZ3BzRW5hYmxlZBIuCh'
    'NncHNfdXBkYXRlX2ludGVydmFsGAUgASgNUhFncHNVcGRhdGVJbnRlcnZhbBIsChBncHNfYXR0'
    'ZW1wdF90aW1lGAYgASgNQgIYAVIOZ3BzQXR0ZW1wdFRpbWUSJQoOcG9zaXRpb25fZmxhZ3MYBy'
    'ABKA1SDXBvc2l0aW9uRmxhZ3MSFwoHcnhfZ3BpbxgIIAEoDVIGcnhHcGlvEhcKB3R4X2dwaW8Y'
    'CSABKA1SBnR4R3BpbxJHCiBicm9hZGNhc3Rfc21hcnRfbWluaW11bV9kaXN0YW5jZRgKIAEoDV'
    'IdYnJvYWRjYXN0U21hcnRNaW5pbXVtRGlzdGFuY2USUAolYnJvYWRjYXN0X3NtYXJ0X21pbmlt'
    'dW1faW50ZXJ2YWxfc2VjcxgLIAEoDVIhYnJvYWRjYXN0U21hcnRNaW5pbXVtSW50ZXJ2YWxTZW'
    'NzEh4KC2dwc19lbl9ncGlvGAwgASgNUglncHNFbkdwaW8SRAoIZ3BzX21vZGUYDSABKA4yKS5t'
    'ZXNodGFzdGljLkNvbmZpZy5Qb3NpdGlvbkNvbmZpZy5HcHNNb2RlUgdncHNNb2RlIqsBCg1Qb3'
    'NpdGlvbkZsYWdzEgkKBVVOU0VUEAASDAoIQUxUSVRVREUQARIQCgxBTFRJVFVERV9NU0wQAhIW'
    'ChJHRU9JREFMX1NFUEFSQVRJT04QBBIHCgNET1AQCBIJCgVIVkRPUBAQEg0KCVNBVElOVklFVx'
    'AgEgoKBlNFUV9OTxBAEg4KCVRJTUVTVEFNUBCAARIMCgdIRUFESU5HEIACEgoKBVNQRUVEEIAE'
    'IjUKB0dwc01vZGUSDAoIRElTQUJMRUQQABILCgdFTkFCTEVEEAESDwoLTk9UX1BSRVNFTlQQAh'
    'qhAwoLUG93ZXJDb25maWcSJgoPaXNfcG93ZXJfc2F2aW5nGAEgASgIUg1pc1Bvd2VyU2F2aW5n'
    'EkIKHm9uX2JhdHRlcnlfc2h1dGRvd25fYWZ0ZXJfc2VjcxgCIAEoDVIab25CYXR0ZXJ5U2h1dG'
    'Rvd25BZnRlclNlY3MSNgoXYWRjX211bHRpcGxpZXJfb3ZlcnJpZGUYAyABKAJSFWFkY011bHRp'
    'cGxpZXJPdmVycmlkZRIuChN3YWl0X2JsdWV0b290aF9zZWNzGAQgASgNUhF3YWl0Qmx1ZXRvb3'
    'RoU2VjcxIZCghzZHNfc2VjcxgGIAEoDVIHc2RzU2VjcxIXCgdsc19zZWNzGAcgASgNUgZsc1Nl'
    'Y3MSIgoNbWluX3dha2Vfc2VjcxgIIAEoDVILbWluV2FrZVNlY3MSOwoaZGV2aWNlX2JhdHRlcn'
    'lfaW5hX2FkZHJlc3MYCSABKA1SF2RldmljZUJhdHRlcnlJbmFBZGRyZXNzEikKEHBvd2VybW9u'
    'X2VuYWJsZXMYICABKARSD3Bvd2VybW9uRW5hYmxlcxraBAoNTmV0d29ya0NvbmZpZxIhCgx3aW'
    'ZpX2VuYWJsZWQYASABKAhSC3dpZmlFbmFibGVkEhsKCXdpZmlfc3NpZBgDIAEoCVIId2lmaVNz'
    'aWQSGQoId2lmaV9wc2sYBCABKAlSB3dpZmlQc2sSHQoKbnRwX3NlcnZlchgFIAEoCVIJbnRwU2'
    'VydmVyEh8KC2V0aF9lbmFibGVkGAYgASgIUgpldGhFbmFibGVkEk8KDGFkZHJlc3NfbW9kZRgH'
    'IAEoDjIsLm1lc2h0YXN0aWMuQ29uZmlnLk5ldHdvcmtDb25maWcuQWRkcmVzc01vZGVSC2FkZH'
    'Jlc3NNb2RlEkwKC2lwdjRfY29uZmlnGAggASgLMisubWVzaHRhc3RpYy5Db25maWcuTmV0d29y'
    'a0NvbmZpZy5JcFY0Q29uZmlnUgppcHY0Q29uZmlnEiUKDnJzeXNsb2dfc2VydmVyGAkgASgJUg'
    '1yc3lzbG9nU2VydmVyEisKEWVuYWJsZWRfcHJvdG9jb2xzGAogASgNUhBlbmFibGVkUHJvdG9j'
    'b2xzGmAKCklwVjRDb25maWcSDgoCaXAYASABKAdSAmlwEhgKB2dhdGV3YXkYAiABKAdSB2dhdG'
    'V3YXkSFgoGc3VibmV0GAMgASgHUgZzdWJuZXQSEAoDZG5zGAQgASgHUgNkbnMiIwoLQWRkcmVz'
    'c01vZGUSCAoEREhDUBAAEgoKBlNUQVRJQxABIjQKDVByb3RvY29sRmxhZ3MSEAoMTk9fQlJPQU'
    'RDQVNUEAASEQoNVURQX0JST0FEQ0FTVBABGo0JCg1EaXNwbGF5Q29uZmlnEiQKDnNjcmVlbl9v'
    'bl9zZWNzGAEgASgNUgxzY3JlZW5PblNlY3MSUwoKZ3BzX2Zvcm1hdBgCIAEoDjI0Lm1lc2h0YX'
    'N0aWMuQ29uZmlnLkRpc3BsYXlDb25maWcuR3BzQ29vcmRpbmF0ZUZvcm1hdFIJZ3BzRm9ybWF0'
    'EjkKGWF1dG9fc2NyZWVuX2Nhcm91c2VsX3NlY3MYAyABKA1SFmF1dG9TY3JlZW5DYXJvdXNlbF'
    'NlY3MSKgoRY29tcGFzc19ub3J0aF90b3AYBCABKAhSD2NvbXBhc3NOb3J0aFRvcBIfCgtmbGlw'
    'X3NjcmVlbhgFIAEoCFIKZmxpcFNjcmVlbhJDCgV1bml0cxgGIAEoDjItLm1lc2h0YXN0aWMuQ2'
    '9uZmlnLkRpc3BsYXlDb25maWcuRGlzcGxheVVuaXRzUgV1bml0cxI9CgRvbGVkGAcgASgOMiku'
    'bWVzaHRhc3RpYy5Db25maWcuRGlzcGxheUNvbmZpZy5PbGVkVHlwZVIEb2xlZBJOCgtkaXNwbG'
    'F5bW9kZRgIIAEoDjIsLm1lc2h0YXN0aWMuQ29uZmlnLkRpc3BsYXlDb25maWcuRGlzcGxheU1v'
    'ZGVSC2Rpc3BsYXltb2RlEiEKDGhlYWRpbmdfYm9sZBgJIAEoCFILaGVhZGluZ0JvbGQSMAoVd2'
    'FrZV9vbl90YXBfb3JfbW90aW9uGAogASgIUhF3YWtlT25UYXBPck1vdGlvbhJkChNjb21wYXNz'
    'X29yaWVudGF0aW9uGAsgASgOMjMubWVzaHRhc3RpYy5Db25maWcuRGlzcGxheUNvbmZpZy5Db2'
    '1wYXNzT3JpZW50YXRpb25SEmNvbXBhc3NPcmllbnRhdGlvbhIiCg11c2VfMTJoX2Nsb2NrGAwg'
    'ASgIUgt1c2UxMmhDbG9jayJNChNHcHNDb29yZGluYXRlRm9ybWF0EgcKA0RFQxAAEgcKA0RNUx'
    'ABEgcKA1VUTRACEggKBE1HUlMQAxIHCgNPTEMQBBIICgRPU0dSEAUiKAoMRGlzcGxheVVuaXRz'
    'EgoKBk1FVFJJQxAAEgwKCElNUEVSSUFMEAEiTQoIT2xlZFR5cGUSDQoJT0xFRF9BVVRPEAASEA'
    'oMT0xFRF9TU0QxMzA2EAESDwoLT0xFRF9TSDExMDYQAhIPCgtPTEVEX1NIMTEwNxADIkEKC0Rp'
    'c3BsYXlNb2RlEgsKB0RFRkFVTFQQABIMCghUV09DT0xPUhABEgwKCElOVkVSVEVEEAISCQoFQ0'
    '9MT1IQAyK6AQoSQ29tcGFzc09yaWVudGF0aW9uEg0KCURFR1JFRVNfMBAAEg4KCkRFR1JFRVNf'
    'OTAQARIPCgtERUdSRUVTXzE4MBACEg8KC0RFR1JFRVNfMjcwEAMSFgoSREVHUkVFU18wX0lOVk'
    'VSVEVEEAQSFwoTREVHUkVFU185MF9JTlZFUlRFRBAFEhgKFERFR1JFRVNfMTgwX0lOVkVSVEVE'
    'EAYSGAoUREVHUkVFU18yNzBfSU5WRVJURUQQBxqTCQoKTG9SYUNvbmZpZxIdCgp1c2VfcHJlc2'
    'V0GAEgASgIUgl1c2VQcmVzZXQSTAoMbW9kZW1fcHJlc2V0GAIgASgOMikubWVzaHRhc3RpYy5D'
    'b25maWcuTG9SYUNvbmZpZy5Nb2RlbVByZXNldFILbW9kZW1QcmVzZXQSHAoJYmFuZHdpZHRoGA'
    'MgASgNUgliYW5kd2lkdGgSIwoNc3ByZWFkX2ZhY3RvchgEIAEoDVIMc3ByZWFkRmFjdG9yEh8K'
    'C2NvZGluZ19yYXRlGAUgASgNUgpjb2RpbmdSYXRlEikKEGZyZXF1ZW5jeV9vZmZzZXQYBiABKA'
    'JSD2ZyZXF1ZW5jeU9mZnNldBJACgZyZWdpb24YByABKA4yKC5tZXNodGFzdGljLkNvbmZpZy5M'
    'b1JhQ29uZmlnLlJlZ2lvbkNvZGVSBnJlZ2lvbhIbCglob3BfbGltaXQYCCABKA1SCGhvcExpbW'
    'l0Eh0KCnR4X2VuYWJsZWQYCSABKAhSCXR4RW5hYmxlZBIZCgh0eF9wb3dlchgKIAEoBVIHdHhQ'
    'b3dlchIfCgtjaGFubmVsX251bRgLIAEoDVIKY2hhbm5lbE51bRIuChNvdmVycmlkZV9kdXR5X2'
    'N5Y2xlGAwgASgIUhFvdmVycmlkZUR1dHlDeWNsZRIzChZzeDEyNnhfcnhfYm9vc3RlZF9nYWlu'
    'GA0gASgIUhNzeDEyNnhSeEJvb3N0ZWRHYWluEi0KEm92ZXJyaWRlX2ZyZXF1ZW5jeRgOIAEoAl'
    'IRb3ZlcnJpZGVGcmVxdWVuY3kSJgoPcGFfZmFuX2Rpc2FibGVkGA8gASgIUg1wYUZhbkRpc2Fi'
    'bGVkEicKD2lnbm9yZV9pbmNvbWluZxhnIAMoDVIOaWdub3JlSW5jb21pbmcSHwoLaWdub3JlX2'
    '1xdHQYaCABKAhSCmlnbm9yZU1xdHQSKQoRY29uZmlnX29rX3RvX21xdHQYaSABKAhSDmNvbmZp'
    'Z09rVG9NcXR0IvEBCgpSZWdpb25Db2RlEgkKBVVOU0VUEAASBgoCVVMQARIKCgZFVV80MzMQAh'
    'IKCgZFVV84NjgQAxIGCgJDThAEEgYKAkpQEAUSBwoDQU5aEAYSBgoCS1IQBxIGCgJUVxAIEgYK'
    'AlJVEAkSBgoCSU4QChIKCgZOWl84NjUQCxIGCgJUSBAMEgsKB0xPUkFfMjQQDRIKCgZVQV80Mz'
    'MQDhIKCgZVQV84NjgQDxIKCgZNWV80MzMQEBIKCgZNWV85MTkQERIKCgZTR185MjMQEhIKCgZQ'
    'SF80MzMQExIKCgZQSF84NjgQFBIKCgZQSF85MTUQFSKpAQoLTW9kZW1QcmVzZXQSDQoJTE9OR1'
    '9GQVNUEAASDQoJTE9OR19TTE9XEAESFgoOVkVSWV9MT05HX1NMT1cQAhoCCAESDwoLTUVESVVN'
    'X1NMT1cQAxIPCgtNRURJVU1fRkFTVBAEEg4KClNIT1JUX1NMT1cQBRIOCgpTSE9SVF9GQVNUEA'
    'YSEQoNTE9OR19NT0RFUkFURRAHEg8KC1NIT1JUX1RVUkJPEAgaxgEKD0JsdWV0b290aENvbmZp'
    'ZxIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEkIKBG1vZGUYAiABKA4yLi5tZXNodGFzdGljLk'
    'NvbmZpZy5CbHVldG9vdGhDb25maWcuUGFpcmluZ01vZGVSBG1vZGUSGwoJZml4ZWRfcGluGAMg'
    'ASgNUghmaXhlZFBpbiI4CgtQYWlyaW5nTW9kZRIOCgpSQU5ET01fUElOEAASDQoJRklYRURfUE'
    'lOEAESCgoGTk9fUElOEAIamgIKDlNlY3VyaXR5Q29uZmlnEh0KCnB1YmxpY19rZXkYASABKAxS'
    'CXB1YmxpY0tleRIfCgtwcml2YXRlX2tleRgCIAEoDFIKcHJpdmF0ZUtleRIbCglhZG1pbl9rZX'
    'kYAyADKAxSCGFkbWluS2V5Eh0KCmlzX21hbmFnZWQYBCABKAhSCWlzTWFuYWdlZBIlCg5zZXJp'
    'YWxfZW5hYmxlZBgFIAEoCFINc2VyaWFsRW5hYmxlZBIxChVkZWJ1Z19sb2dfYXBpX2VuYWJsZW'
    'QYBiABKAhSEmRlYnVnTG9nQXBpRW5hYmxlZBIyChVhZG1pbl9jaGFubmVsX2VuYWJsZWQYCCAB'
    'KAhSE2FkbWluQ2hhbm5lbEVuYWJsZWQaEgoQU2Vzc2lvbmtleUNvbmZpZ0IRCg9wYXlsb2FkX3'
    'ZhcmlhbnQ=');

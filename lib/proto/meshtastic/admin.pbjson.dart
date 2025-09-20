// This is a generated file - do not edit.
//
// Generated from meshtastic/admin.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use adminMessageDescriptor instead')
const AdminMessage$json = {
  '1': 'AdminMessage',
  '2': [
    {'1': 'session_passkey', '3': 101, '4': 1, '5': 12, '10': 'sessionPasskey'},
    {
      '1': 'get_channel_request',
      '3': 1,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'getChannelRequest'
    },
    {
      '1': 'get_channel_response',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Channel',
      '9': 0,
      '10': 'getChannelResponse'
    },
    {
      '1': 'get_owner_request',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'getOwnerRequest'
    },
    {
      '1': 'get_owner_response',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.User',
      '9': 0,
      '10': 'getOwnerResponse'
    },
    {
      '1': 'get_config_request',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.AdminMessage.ConfigType',
      '9': 0,
      '10': 'getConfigRequest'
    },
    {
      '1': 'get_config_response',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config',
      '9': 0,
      '10': 'getConfigResponse'
    },
    {
      '1': 'get_module_config_request',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.AdminMessage.ModuleConfigType',
      '9': 0,
      '10': 'getModuleConfigRequest'
    },
    {
      '1': 'get_module_config_response',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig',
      '9': 0,
      '10': 'getModuleConfigResponse'
    },
    {
      '1': 'get_canned_message_module_messages_request',
      '3': 10,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'getCannedMessageModuleMessagesRequest'
    },
    {
      '1': 'get_canned_message_module_messages_response',
      '3': 11,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'getCannedMessageModuleMessagesResponse'
    },
    {
      '1': 'get_device_metadata_request',
      '3': 12,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'getDeviceMetadataRequest'
    },
    {
      '1': 'get_device_metadata_response',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DeviceMetadata',
      '9': 0,
      '10': 'getDeviceMetadataResponse'
    },
    {
      '1': 'get_ringtone_request',
      '3': 14,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'getRingtoneRequest'
    },
    {
      '1': 'get_ringtone_response',
      '3': 15,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'getRingtoneResponse'
    },
    {
      '1': 'get_device_connection_status_request',
      '3': 16,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'getDeviceConnectionStatusRequest'
    },
    {
      '1': 'get_device_connection_status_response',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DeviceConnectionStatus',
      '9': 0,
      '10': 'getDeviceConnectionStatusResponse'
    },
    {
      '1': 'set_ham_mode',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.HamParameters',
      '9': 0,
      '10': 'setHamMode'
    },
    {
      '1': 'get_node_remote_hardware_pins_request',
      '3': 19,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'getNodeRemoteHardwarePinsRequest'
    },
    {
      '1': 'get_node_remote_hardware_pins_response',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.NodeRemoteHardwarePinsResponse',
      '9': 0,
      '10': 'getNodeRemoteHardwarePinsResponse'
    },
    {
      '1': 'enter_dfu_mode_request',
      '3': 21,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'enterDfuModeRequest'
    },
    {
      '1': 'delete_file_request',
      '3': 22,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'deleteFileRequest'
    },
    {'1': 'set_scale', '3': 23, '4': 1, '5': 13, '9': 0, '10': 'setScale'},
    {
      '1': 'backup_preferences',
      '3': 24,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.AdminMessage.BackupLocation',
      '9': 0,
      '10': 'backupPreferences'
    },
    {
      '1': 'restore_preferences',
      '3': 25,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.AdminMessage.BackupLocation',
      '9': 0,
      '10': 'restorePreferences'
    },
    {
      '1': 'remove_backup_preferences',
      '3': 26,
      '4': 1,
      '5': 14,
      '6': '.meshtastic.AdminMessage.BackupLocation',
      '9': 0,
      '10': 'removeBackupPreferences'
    },
    {
      '1': 'set_owner',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.User',
      '9': 0,
      '10': 'setOwner'
    },
    {
      '1': 'set_channel',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Channel',
      '9': 0,
      '10': 'setChannel'
    },
    {
      '1': 'set_config',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Config',
      '9': 0,
      '10': 'setConfig'
    },
    {
      '1': 'set_module_config',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.ModuleConfig',
      '9': 0,
      '10': 'setModuleConfig'
    },
    {
      '1': 'set_canned_message_module_messages',
      '3': 36,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'setCannedMessageModuleMessages'
    },
    {
      '1': 'set_ringtone_message',
      '3': 37,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'setRingtoneMessage'
    },
    {
      '1': 'remove_by_nodenum',
      '3': 38,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'removeByNodenum'
    },
    {
      '1': 'set_favorite_node',
      '3': 39,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'setFavoriteNode'
    },
    {
      '1': 'remove_favorite_node',
      '3': 40,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'removeFavoriteNode'
    },
    {
      '1': 'set_fixed_position',
      '3': 41,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.Position',
      '9': 0,
      '10': 'setFixedPosition'
    },
    {
      '1': 'remove_fixed_position',
      '3': 42,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'removeFixedPosition'
    },
    {
      '1': 'set_time_only',
      '3': 43,
      '4': 1,
      '5': 7,
      '9': 0,
      '10': 'setTimeOnly'
    },
    {
      '1': 'get_ui_config_request',
      '3': 44,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'getUiConfigRequest'
    },
    {
      '1': 'get_ui_config_response',
      '3': 45,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DeviceUIConfig',
      '9': 0,
      '10': 'getUiConfigResponse'
    },
    {
      '1': 'store_ui_config',
      '3': 46,
      '4': 1,
      '5': 11,
      '6': '.meshtastic.DeviceUIConfig',
      '9': 0,
      '10': 'storeUiConfig'
    },
    {
      '1': 'set_ignored_node',
      '3': 47,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'setIgnoredNode'
    },
    {
      '1': 'remove_ignored_node',
      '3': 48,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'removeIgnoredNode'
    },
    {
      '1': 'begin_edit_settings',
      '3': 64,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'beginEditSettings'
    },
    {
      '1': 'commit_edit_settings',
      '3': 65,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'commitEditSettings'
    },
    {
      '1': 'factory_reset_device',
      '3': 94,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'factoryResetDevice'
    },
    {
      '1': 'reboot_ota_seconds',
      '3': 95,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'rebootOtaSeconds'
    },
    {
      '1': 'exit_simulator',
      '3': 96,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'exitSimulator'
    },
    {
      '1': 'reboot_seconds',
      '3': 97,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'rebootSeconds'
    },
    {
      '1': 'shutdown_seconds',
      '3': 98,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'shutdownSeconds'
    },
    {
      '1': 'factory_reset_config',
      '3': 99,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'factoryResetConfig'
    },
    {
      '1': 'nodedb_reset',
      '3': 100,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'nodedbReset'
    },
  ],
  '4': [
    AdminMessage_ConfigType$json,
    AdminMessage_ModuleConfigType$json,
    AdminMessage_BackupLocation$json
  ],
  '8': [
    {'1': 'payload_variant'},
  ],
};

@$core.Deprecated('Use adminMessageDescriptor instead')
const AdminMessage_ConfigType$json = {
  '1': 'ConfigType',
  '2': [
    {'1': 'DEVICE_CONFIG', '2': 0},
    {'1': 'POSITION_CONFIG', '2': 1},
    {'1': 'POWER_CONFIG', '2': 2},
    {'1': 'NETWORK_CONFIG', '2': 3},
    {'1': 'DISPLAY_CONFIG', '2': 4},
    {'1': 'LORA_CONFIG', '2': 5},
    {'1': 'BLUETOOTH_CONFIG', '2': 6},
    {'1': 'SECURITY_CONFIG', '2': 7},
    {'1': 'SESSIONKEY_CONFIG', '2': 8},
    {'1': 'DEVICEUI_CONFIG', '2': 9},
  ],
};

@$core.Deprecated('Use adminMessageDescriptor instead')
const AdminMessage_ModuleConfigType$json = {
  '1': 'ModuleConfigType',
  '2': [
    {'1': 'MQTT_CONFIG', '2': 0},
    {'1': 'SERIAL_CONFIG', '2': 1},
    {'1': 'EXTNOTIF_CONFIG', '2': 2},
    {'1': 'STOREFORWARD_CONFIG', '2': 3},
    {'1': 'RANGETEST_CONFIG', '2': 4},
    {'1': 'TELEMETRY_CONFIG', '2': 5},
    {'1': 'CANNEDMSG_CONFIG', '2': 6},
    {'1': 'AUDIO_CONFIG', '2': 7},
    {'1': 'REMOTEHARDWARE_CONFIG', '2': 8},
    {'1': 'NEIGHBORINFO_CONFIG', '2': 9},
    {'1': 'AMBIENTLIGHTING_CONFIG', '2': 10},
    {'1': 'DETECTIONSENSOR_CONFIG', '2': 11},
    {'1': 'PAXCOUNTER_CONFIG', '2': 12},
  ],
};

@$core.Deprecated('Use adminMessageDescriptor instead')
const AdminMessage_BackupLocation$json = {
  '1': 'BackupLocation',
  '2': [
    {'1': 'FLASH', '2': 0},
    {'1': 'SD', '2': 1},
  ],
};

/// Descriptor for `AdminMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminMessageDescriptor = $convert.base64Decode(
    'CgxBZG1pbk1lc3NhZ2USJwoPc2Vzc2lvbl9wYXNza2V5GGUgASgMUg5zZXNzaW9uUGFzc2tleR'
    'IwChNnZXRfY2hhbm5lbF9yZXF1ZXN0GAEgASgNSABSEWdldENoYW5uZWxSZXF1ZXN0EkcKFGdl'
    'dF9jaGFubmVsX3Jlc3BvbnNlGAIgASgLMhMubWVzaHRhc3RpYy5DaGFubmVsSABSEmdldENoYW'
    '5uZWxSZXNwb25zZRIsChFnZXRfb3duZXJfcmVxdWVzdBgDIAEoCEgAUg9nZXRPd25lclJlcXVl'
    'c3QSQAoSZ2V0X293bmVyX3Jlc3BvbnNlGAQgASgLMhAubWVzaHRhc3RpYy5Vc2VySABSEGdldE'
    '93bmVyUmVzcG9uc2USUwoSZ2V0X2NvbmZpZ19yZXF1ZXN0GAUgASgOMiMubWVzaHRhc3RpYy5B'
    'ZG1pbk1lc3NhZ2UuQ29uZmlnVHlwZUgAUhBnZXRDb25maWdSZXF1ZXN0EkQKE2dldF9jb25maW'
    'dfcmVzcG9uc2UYBiABKAsyEi5tZXNodGFzdGljLkNvbmZpZ0gAUhFnZXRDb25maWdSZXNwb25z'
    'ZRJmChlnZXRfbW9kdWxlX2NvbmZpZ19yZXF1ZXN0GAcgASgOMikubWVzaHRhc3RpYy5BZG1pbk'
    '1lc3NhZ2UuTW9kdWxlQ29uZmlnVHlwZUgAUhZnZXRNb2R1bGVDb25maWdSZXF1ZXN0ElcKGmdl'
    'dF9tb2R1bGVfY29uZmlnX3Jlc3BvbnNlGAggASgLMhgubWVzaHRhc3RpYy5Nb2R1bGVDb25maW'
    'dIAFIXZ2V0TW9kdWxlQ29uZmlnUmVzcG9uc2USWwoqZ2V0X2Nhbm5lZF9tZXNzYWdlX21vZHVs'
    'ZV9tZXNzYWdlc19yZXF1ZXN0GAogASgISABSJWdldENhbm5lZE1lc3NhZ2VNb2R1bGVNZXNzYW'
    'dlc1JlcXVlc3QSXQorZ2V0X2Nhbm5lZF9tZXNzYWdlX21vZHVsZV9tZXNzYWdlc19yZXNwb25z'
    'ZRgLIAEoCUgAUiZnZXRDYW5uZWRNZXNzYWdlTW9kdWxlTWVzc2FnZXNSZXNwb25zZRI/ChtnZX'
    'RfZGV2aWNlX21ldGFkYXRhX3JlcXVlc3QYDCABKAhIAFIYZ2V0RGV2aWNlTWV0YWRhdGFSZXF1'
    'ZXN0El0KHGdldF9kZXZpY2VfbWV0YWRhdGFfcmVzcG9uc2UYDSABKAsyGi5tZXNodGFzdGljLk'
    'RldmljZU1ldGFkYXRhSABSGWdldERldmljZU1ldGFkYXRhUmVzcG9uc2USMgoUZ2V0X3Jpbmd0'
    'b25lX3JlcXVlc3QYDiABKAhIAFISZ2V0UmluZ3RvbmVSZXF1ZXN0EjQKFWdldF9yaW5ndG9uZV'
    '9yZXNwb25zZRgPIAEoCUgAUhNnZXRSaW5ndG9uZVJlc3BvbnNlElAKJGdldF9kZXZpY2VfY29u'
    'bmVjdGlvbl9zdGF0dXNfcmVxdWVzdBgQIAEoCEgAUiBnZXREZXZpY2VDb25uZWN0aW9uU3RhdH'
    'VzUmVxdWVzdBJ2CiVnZXRfZGV2aWNlX2Nvbm5lY3Rpb25fc3RhdHVzX3Jlc3BvbnNlGBEgASgL'
    'MiIubWVzaHRhc3RpYy5EZXZpY2VDb25uZWN0aW9uU3RhdHVzSABSIWdldERldmljZUNvbm5lY3'
    'Rpb25TdGF0dXNSZXNwb25zZRI9CgxzZXRfaGFtX21vZGUYEiABKAsyGS5tZXNodGFzdGljLkhh'
    'bVBhcmFtZXRlcnNIAFIKc2V0SGFtTW9kZRJRCiVnZXRfbm9kZV9yZW1vdGVfaGFyZHdhcmVfcG'
    'luc19yZXF1ZXN0GBMgASgISABSIGdldE5vZGVSZW1vdGVIYXJkd2FyZVBpbnNSZXF1ZXN0En8K'
    'JmdldF9ub2RlX3JlbW90ZV9oYXJkd2FyZV9waW5zX3Jlc3BvbnNlGBQgASgLMioubWVzaHRhc3'
    'RpYy5Ob2RlUmVtb3RlSGFyZHdhcmVQaW5zUmVzcG9uc2VIAFIhZ2V0Tm9kZVJlbW90ZUhhcmR3'
    'YXJlUGluc1Jlc3BvbnNlEjUKFmVudGVyX2RmdV9tb2RlX3JlcXVlc3QYFSABKAhIAFITZW50ZX'
    'JEZnVNb2RlUmVxdWVzdBIwChNkZWxldGVfZmlsZV9yZXF1ZXN0GBYgASgJSABSEWRlbGV0ZUZp'
    'bGVSZXF1ZXN0Eh0KCXNldF9zY2FsZRgXIAEoDUgAUghzZXRTY2FsZRJYChJiYWNrdXBfcHJlZm'
    'VyZW5jZXMYGCABKA4yJy5tZXNodGFzdGljLkFkbWluTWVzc2FnZS5CYWNrdXBMb2NhdGlvbkgA'
    'UhFiYWNrdXBQcmVmZXJlbmNlcxJaChNyZXN0b3JlX3ByZWZlcmVuY2VzGBkgASgOMicubWVzaH'
    'Rhc3RpYy5BZG1pbk1lc3NhZ2UuQmFja3VwTG9jYXRpb25IAFIScmVzdG9yZVByZWZlcmVuY2Vz'
    'EmUKGXJlbW92ZV9iYWNrdXBfcHJlZmVyZW5jZXMYGiABKA4yJy5tZXNodGFzdGljLkFkbWluTW'
    'Vzc2FnZS5CYWNrdXBMb2NhdGlvbkgAUhdyZW1vdmVCYWNrdXBQcmVmZXJlbmNlcxIvCglzZXRf'
    'b3duZXIYICABKAsyEC5tZXNodGFzdGljLlVzZXJIAFIIc2V0T3duZXISNgoLc2V0X2NoYW5uZW'
    'wYISABKAsyEy5tZXNodGFzdGljLkNoYW5uZWxIAFIKc2V0Q2hhbm5lbBIzCgpzZXRfY29uZmln'
    'GCIgASgLMhIubWVzaHRhc3RpYy5Db25maWdIAFIJc2V0Q29uZmlnEkYKEXNldF9tb2R1bGVfY2'
    '9uZmlnGCMgASgLMhgubWVzaHRhc3RpYy5Nb2R1bGVDb25maWdIAFIPc2V0TW9kdWxlQ29uZmln'
    'EkwKInNldF9jYW5uZWRfbWVzc2FnZV9tb2R1bGVfbWVzc2FnZXMYJCABKAlIAFIec2V0Q2Fubm'
    'VkTWVzc2FnZU1vZHVsZU1lc3NhZ2VzEjIKFHNldF9yaW5ndG9uZV9tZXNzYWdlGCUgASgJSABS'
    'EnNldFJpbmd0b25lTWVzc2FnZRIsChFyZW1vdmVfYnlfbm9kZW51bRgmIAEoDUgAUg9yZW1vdm'
    'VCeU5vZGVudW0SLAoRc2V0X2Zhdm9yaXRlX25vZGUYJyABKA1IAFIPc2V0RmF2b3JpdGVOb2Rl'
    'EjIKFHJlbW92ZV9mYXZvcml0ZV9ub2RlGCggASgNSABSEnJlbW92ZUZhdm9yaXRlTm9kZRJECh'
    'JzZXRfZml4ZWRfcG9zaXRpb24YKSABKAsyFC5tZXNodGFzdGljLlBvc2l0aW9uSABSEHNldEZp'
    'eGVkUG9zaXRpb24SNAoVcmVtb3ZlX2ZpeGVkX3Bvc2l0aW9uGCogASgISABSE3JlbW92ZUZpeG'
    'VkUG9zaXRpb24SJAoNc2V0X3RpbWVfb25seRgrIAEoB0gAUgtzZXRUaW1lT25seRIzChVnZXRf'
    'dWlfY29uZmlnX3JlcXVlc3QYLCABKAhIAFISZ2V0VWlDb25maWdSZXF1ZXN0ElEKFmdldF91aV'
    '9jb25maWdfcmVzcG9uc2UYLSABKAsyGi5tZXNodGFzdGljLkRldmljZVVJQ29uZmlnSABSE2dl'
    'dFVpQ29uZmlnUmVzcG9uc2USRAoPc3RvcmVfdWlfY29uZmlnGC4gASgLMhoubWVzaHRhc3RpYy'
    '5EZXZpY2VVSUNvbmZpZ0gAUg1zdG9yZVVpQ29uZmlnEioKEHNldF9pZ25vcmVkX25vZGUYLyAB'
    'KA1IAFIOc2V0SWdub3JlZE5vZGUSMAoTcmVtb3ZlX2lnbm9yZWRfbm9kZRgwIAEoDUgAUhFyZW'
    '1vdmVJZ25vcmVkTm9kZRIwChNiZWdpbl9lZGl0X3NldHRpbmdzGEAgASgISABSEWJlZ2luRWRp'
    'dFNldHRpbmdzEjIKFGNvbW1pdF9lZGl0X3NldHRpbmdzGEEgASgISABSEmNvbW1pdEVkaXRTZX'
    'R0aW5ncxIyChRmYWN0b3J5X3Jlc2V0X2RldmljZRheIAEoBUgAUhJmYWN0b3J5UmVzZXREZXZp'
    'Y2USLgoScmVib290X290YV9zZWNvbmRzGF8gASgFSABSEHJlYm9vdE90YVNlY29uZHMSJwoOZX'
    'hpdF9zaW11bGF0b3IYYCABKAhIAFINZXhpdFNpbXVsYXRvchInCg5yZWJvb3Rfc2Vjb25kcxhh'
    'IAEoBUgAUg1yZWJvb3RTZWNvbmRzEisKEHNodXRkb3duX3NlY29uZHMYYiABKAVIAFIPc2h1dG'
    'Rvd25TZWNvbmRzEjIKFGZhY3RvcnlfcmVzZXRfY29uZmlnGGMgASgFSABSEmZhY3RvcnlSZXNl'
    'dENvbmZpZxIjCgxub2RlZGJfcmVzZXQYZCABKAVIAFILbm9kZWRiUmVzZXQi1gEKCkNvbmZpZ1'
    'R5cGUSEQoNREVWSUNFX0NPTkZJRxAAEhMKD1BPU0lUSU9OX0NPTkZJRxABEhAKDFBPV0VSX0NP'
    'TkZJRxACEhIKDk5FVFdPUktfQ09ORklHEAMSEgoORElTUExBWV9DT05GSUcQBBIPCgtMT1JBX0'
    'NPTkZJRxAFEhQKEEJMVUVUT09USF9DT05GSUcQBhITCg9TRUNVUklUWV9DT05GSUcQBxIVChFT'
    'RVNTSU9OS0VZX0NPTkZJRxAIEhMKD0RFVklDRVVJX0NPTkZJRxAJIrsCChBNb2R1bGVDb25maW'
    'dUeXBlEg8KC01RVFRfQ09ORklHEAASEQoNU0VSSUFMX0NPTkZJRxABEhMKD0VYVE5PVElGX0NP'
    'TkZJRxACEhcKE1NUT1JFRk9SV0FSRF9DT05GSUcQAxIUChBSQU5HRVRFU1RfQ09ORklHEAQSFA'
    'oQVEVMRU1FVFJZX0NPTkZJRxAFEhQKEENBTk5FRE1TR19DT05GSUcQBhIQCgxBVURJT19DT05G'
    'SUcQBxIZChVSRU1PVEVIQVJEV0FSRV9DT05GSUcQCBIXChNORUlHSEJPUklORk9fQ09ORklHEA'
    'kSGgoWQU1CSUVOVExJR0hUSU5HX0NPTkZJRxAKEhoKFkRFVEVDVElPTlNFTlNPUl9DT05GSUcQ'
    'CxIVChFQQVhDT1VOVEVSX0NPTkZJRxAMIiMKDkJhY2t1cExvY2F0aW9uEgkKBUZMQVNIEAASBg'
    'oCU0QQAUIRCg9wYXlsb2FkX3ZhcmlhbnQ=');

@$core.Deprecated('Use hamParametersDescriptor instead')
const HamParameters$json = {
  '1': 'HamParameters',
  '2': [
    {'1': 'call_sign', '3': 1, '4': 1, '5': 9, '10': 'callSign'},
    {'1': 'tx_power', '3': 2, '4': 1, '5': 5, '10': 'txPower'},
    {'1': 'frequency', '3': 3, '4': 1, '5': 2, '10': 'frequency'},
    {'1': 'short_name', '3': 4, '4': 1, '5': 9, '10': 'shortName'},
  ],
};

/// Descriptor for `HamParameters`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hamParametersDescriptor = $convert.base64Decode(
    'Cg1IYW1QYXJhbWV0ZXJzEhsKCWNhbGxfc2lnbhgBIAEoCVIIY2FsbFNpZ24SGQoIdHhfcG93ZX'
    'IYAiABKAVSB3R4UG93ZXISHAoJZnJlcXVlbmN5GAMgASgCUglmcmVxdWVuY3kSHQoKc2hvcnRf'
    'bmFtZRgEIAEoCVIJc2hvcnROYW1l');

@$core.Deprecated('Use nodeRemoteHardwarePinsResponseDescriptor instead')
const NodeRemoteHardwarePinsResponse$json = {
  '1': 'NodeRemoteHardwarePinsResponse',
  '2': [
    {
      '1': 'node_remote_hardware_pins',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.meshtastic.NodeRemoteHardwarePin',
      '10': 'nodeRemoteHardwarePins'
    },
  ],
};

/// Descriptor for `NodeRemoteHardwarePinsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeRemoteHardwarePinsResponseDescriptor =
    $convert.base64Decode(
        'Ch5Ob2RlUmVtb3RlSGFyZHdhcmVQaW5zUmVzcG9uc2USXAoZbm9kZV9yZW1vdGVfaGFyZHdhcm'
        'VfcGlucxgBIAMoCzIhLm1lc2h0YXN0aWMuTm9kZVJlbW90ZUhhcmR3YXJlUGluUhZub2RlUmVt'
        'b3RlSGFyZHdhcmVQaW5z');

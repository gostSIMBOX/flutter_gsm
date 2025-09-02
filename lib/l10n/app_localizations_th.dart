// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'เกตเวย์ GOSTsimbox';

  @override
  String get configureSipCredentials => 'กำหนดค่าข้อมูลประจำตัว SIP ของคุณ';

  @override
  String get sipUsername => 'ชื่อผู้ใช้ SIP';

  @override
  String get sipPassword => 'รหัสผ่าน SIP';

  @override
  String get sipServer => 'เซิร์ฟเวอร์ SIP';

  @override
  String get sipPort => 'พอร์ต SIP';

  @override
  String get connect => 'เชื่อมต่อ';

  @override
  String get rememberCredentials => 'จดจำข้อมูลประจำตัวและเข้าสู่ระบบอัตโนมัติ';

  @override
  String get pleaseEnterSipUsername => 'กรุณาป้อนชื่อผู้ใช้ SIP';

  @override
  String get pleaseEnterSipPassword => 'กรุณาป้อนรหัสผ่าน SIP';

  @override
  String get pleaseEnterSipServer => 'กรุณาป้อนเซิร์ฟเวอร์ SIP';

  @override
  String get pleaseEnterSipPort => 'กรุณาป้อนพอร์ต SIP';

  @override
  String get pleaseEnterValidPort => 'กรุณาป้อนหมายเลขพอร์ตที่ถูกต้อง';

  @override
  String get authenticationFailed => 'การยืนยันตัวตนล้มเหลว';

  @override
  String get gatewayStatus => 'สถานะเกตเวย์';

  @override
  String get sipConnection => 'การเชื่อมต่อ SIP';

  @override
  String get gsmConnection => 'การเชื่อมต่อ GSM';

  @override
  String get activeCalls => 'การโทรที่ใช้งานอยู่';

  @override
  String get registered => 'ลงทะเบียนแล้ว';

  @override
  String get disconnected => 'ตัดการเชื่อมต่อ';

  @override
  String get connected => 'เชื่อมต่อแล้ว';

  @override
  String get noCalls => 'ไม่มีสาย';

  @override
  String get oneActive => '1 ใช้งาน';

  @override
  String get gatewayControls => 'การควบคุมเกตเวย์';

  @override
  String get startGateway => 'เริ่มเกตเวย์';

  @override
  String get stopGateway => 'หยุดเกตเวย์';

  @override
  String get endCall => 'จบการโทร';

  @override
  String get recentLogs => 'บันทึกล่าสุด';

  @override
  String get viewAll => 'ดูทั้งหมด';

  @override
  String get noLogsAvailable => 'ไม่มีบันทึก';

  @override
  String get gatewayLogsWillAppearHere => 'บันทึกเกตเวย์จะปรากฏที่นี่';

  @override
  String get testControls => 'การควบคุมทดสอบ';

  @override
  String get testSipCall => 'ทดสอบการโทร SIP';

  @override
  String get testGsmCall => 'ทดสอบการโทร GSM';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get sipConfiguration => 'การกำหนดค่า SIP';

  @override
  String get gatewayOptions => 'ตัวเลือกเกตเวย์';

  @override
  String get autoStartGateway => 'เริ่มเกตเวย์อัตโนมัติ';

  @override
  String get autoStartGatewayDesc => 'เริ่มเกตเวย์อัตโนมัติเมื่อเปิดแอป';

  @override
  String get replaceDefaultDialer => 'แทนที่เครื่องโทรเริ่มต้น';

  @override
  String get replaceDefaultDialerDesc =>
      'แทนที่เครื่องโทรระบบด้วยเครื่องโทรเกตเวย์';

  @override
  String get enablePermissions => 'เปิดใช้งานสิทธิ์';

  @override
  String get enablePermissionsDesc => 'ขอสิทธิ์ขั้นสูงสำหรับโทรศัพท์';

  @override
  String get rememberCredentialsSettings => 'จดจำข้อมูลประจำตัว';

  @override
  String get rememberCredentialsDesc =>
      'บันทึกข้อมูลประจำตัวและเข้าสู่ระบบอัตโนมัติ';

  @override
  String get saveSettings => 'บันทึกการตั้งค่า';

  @override
  String get settingsSavedSuccessfully => 'บันทึกการตั้งค่าสำเร็จแล้ว';

  @override
  String get errorSavingSettings => 'เกิดข้อผิดพลาดในการบันทึกการตั้งค่า';

  @override
  String get gatewayLogs => 'บันทึกเกตเวย์';

  @override
  String get searchLogs => 'ค้นหาบันทึก...';

  @override
  String get clearLogs => 'ลบบันทึก';

  @override
  String get clearLogsConfirmation =>
      'คุณแน่ใจหรือไม่ที่จะลบบันทึกทั้งหมด? การดำเนินการนี้ไม่สามารถยกเลิกได้';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get clear => 'ลบ';

  @override
  String get logsClearedSuccessfully => 'ลบบันทึกสำเร็จแล้ว';

  @override
  String get errorClearingLogs => 'เกิดข้อผิดพลาดในการลบบันทึก';

  @override
  String get errorLoadingLogs => 'เกิดข้อผิดพลาดในการโหลดบันทึก';

  @override
  String get stopped => 'หยุดแล้ว';

  @override
  String get starting => 'กำลังเริ่ม...';

  @override
  String get running => 'กำลังทำงาน';

  @override
  String get runningRegistered => 'กำลังทำงาน (ลงทะเบียนแล้ว)';

  @override
  String get runningConnecting => 'กำลังทำงาน (กำลังเชื่อมต่อ)';

  @override
  String get runningDisconnected => 'กำลังทำงาน (ตัดการเชื่อมต่อ)';

  @override
  String get error => 'ข้อผิดพลาด';

  @override
  String get connecting => 'กำลังเชื่อมต่อ...';

  @override
  String get registeredStatus => 'ลงทะเบียนแล้ว';

  @override
  String get callInProgress => 'การโทรกำลังดำเนินการ';

  @override
  String get unknownError => 'ข้อผิดพลาดที่ไม่ทราบสาเหตุ';

  @override
  String get smppConfiguration => 'SMPP Configuration';

  @override
  String get smppServerHost => 'SMPP Server Host';

  @override
  String get smppPort => 'SMPP Port';

  @override
  String get systemId => 'System ID';

  @override
  String get systemPassword => 'System Password';

  @override
  String get systemType => 'System Type';

  @override
  String get connectionStatus => 'Connection Status';

  @override
  String get bound => 'Bound';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get saveConfiguration => 'Save Configuration';

  @override
  String get resetConfiguration => 'Reset Configuration';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get enableDeliveryReceipts => 'Enable Delivery Receipts';

  @override
  String get enableDeliveryReceiptsDesc =>
      'Receive delivery confirmations for sent messages';

  @override
  String get enableLogging => 'Enable Logging';

  @override
  String get enableLoggingDesc => 'Log SMPP protocol messages for debugging';

  @override
  String get configurationInfo => 'Configuration Info';

  @override
  String get protocolVersion => 'Protocol Version';

  @override
  String get defaultPort => 'Default Port';

  @override
  String get connectionType => 'Connection Type';

  @override
  String get keepAlive => 'Keep-alive';

  @override
  String get reconnectInterval => 'Reconnect Interval';

  @override
  String get pleaseEnterSmppHost => 'Please enter SMPP server host';

  @override
  String get pleaseEnterPort => 'Please enter port number';

  @override
  String get pleaseEnterSystemId => 'Please enter System ID';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get configurationSaved => 'Configuration saved successfully';

  @override
  String get errorSavingConfiguration => 'Error saving configuration';

  @override
  String get connectionTestSuccess => 'Connection test successful';

  @override
  String get connectionTestFailed => 'Connection test failed';

  @override
  String get showPassword => 'Show Password';

  @override
  String get hidePassword => 'Hide Password';

  @override
  String get transceiver => 'Transceiver';

  @override
  String get transmitter => 'Transmitter';

  @override
  String get receiver => 'Receiver';

  @override
  String get seconds => 'seconds';

  @override
  String get callHistory => 'Call History';

  @override
  String get loadingCalls => 'Loading calls...';

  @override
  String get errorLoadingCalls => 'Error loading calls';

  @override
  String get noCallsFound => 'No calls found';

  @override
  String get callHistoryWillAppearHere => 'Your call history will appear here';

  @override
  String get all => 'All';

  @override
  String get incoming => 'Incoming';

  @override
  String get outgoing => 'Outgoing';

  @override
  String get missed => 'Missed';

  @override
  String get completed => 'Completed';

  @override
  String get rejected => 'Rejected';

  @override
  String get unknown => 'Unknown';

  @override
  String get makeCall => 'Make Call';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get callInformation => 'Call Information';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get duration => 'Duration';

  @override
  String get status => 'Status';

  @override
  String get lineId => 'Line ID';

  @override
  String get recording => 'Recording';

  @override
  String get filterCalls => 'Filter Calls';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get apply => 'Apply';

  @override
  String get calling => 'Calling';

  @override
  String get openingSmsTo => 'Opening SMS to';
}

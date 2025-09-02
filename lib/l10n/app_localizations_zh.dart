// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'GOSTsimbox 网关';

  @override
  String get configureSipCredentials => '配置您的 SIP 凭据';

  @override
  String get sipUsername => 'SIP 用户名';

  @override
  String get sipPassword => 'SIP 密码';

  @override
  String get sipServer => 'SIP 服务器';

  @override
  String get sipPort => 'SIP 端口';

  @override
  String get connect => '连接';

  @override
  String get rememberCredentials => '记住凭据并自动登录';

  @override
  String get pleaseEnterSipUsername => '请输入 SIP 用户名';

  @override
  String get pleaseEnterSipPassword => '请输入 SIP 密码';

  @override
  String get pleaseEnterSipServer => '请输入 SIP 服务器';

  @override
  String get pleaseEnterSipPort => '请输入 SIP 端口';

  @override
  String get pleaseEnterValidPort => '请输入有效的端口号';

  @override
  String get authenticationFailed => '身份验证失败';

  @override
  String get gatewayStatus => '网关状态';

  @override
  String get sipConnection => 'SIP 连接';

  @override
  String get gsmConnection => 'GSM 连接';

  @override
  String get activeCalls => '活跃通话';

  @override
  String get registered => '已注册';

  @override
  String get disconnected => '已断开';

  @override
  String get connected => '已连接';

  @override
  String get noCalls => '无通话';

  @override
  String get oneActive => '1 个活跃';

  @override
  String get gatewayControls => '网关控制';

  @override
  String get startGateway => '启动网关';

  @override
  String get stopGateway => '停止网关';

  @override
  String get endCall => '结束通话';

  @override
  String get recentLogs => '最近日志';

  @override
  String get viewAll => '查看全部';

  @override
  String get noLogsAvailable => '无可用日志';

  @override
  String get gatewayLogsWillAppearHere => '网关日志将在此显示';

  @override
  String get testControls => '测试控制';

  @override
  String get testSipCall => '测试 SIP 通话';

  @override
  String get testGsmCall => '测试 GSM 通话';

  @override
  String get settings => '设置';

  @override
  String get sipConfiguration => 'SIP 配置';

  @override
  String get gatewayOptions => '网关选项';

  @override
  String get autoStartGateway => '自动启动网关';

  @override
  String get autoStartGatewayDesc => '应用启动时自动启动网关';

  @override
  String get replaceDefaultDialer => '替换默认拨号器';

  @override
  String get replaceDefaultDialerDesc => '用网关拨号器替换系统拨号器';

  @override
  String get enablePermissions => '启用权限';

  @override
  String get enablePermissionsDesc => '请求电话功能的高级权限';

  @override
  String get rememberCredentialsSettings => '记住凭据';

  @override
  String get rememberCredentialsDesc => '保存凭据并自动登录';

  @override
  String get saveSettings => '保存设置';

  @override
  String get settingsSavedSuccessfully => '设置保存成功';

  @override
  String get errorSavingSettings => '保存设置时出错';

  @override
  String get gatewayLogs => '网关日志';

  @override
  String get searchLogs => '搜索日志...';

  @override
  String get clearLogs => '清除日志';

  @override
  String get clearLogsConfirmation => '您确定要清除所有日志吗？此操作无法撤销。';

  @override
  String get cancel => '取消';

  @override
  String get clear => '清除';

  @override
  String get logsClearedSuccessfully => '日志清除成功';

  @override
  String get errorClearingLogs => '清除日志时出错';

  @override
  String get errorLoadingLogs => '加载日志时出错';

  @override
  String get stopped => '已停止';

  @override
  String get starting => '启动中...';

  @override
  String get running => '运行中';

  @override
  String get runningRegistered => '运行中（已注册）';

  @override
  String get runningConnecting => '运行中（连接中）';

  @override
  String get runningDisconnected => '运行中（已断开）';

  @override
  String get error => '错误';

  @override
  String get connecting => '连接中...';

  @override
  String get registeredStatus => '已注册';

  @override
  String get callInProgress => '通话进行中';

  @override
  String get unknownError => '未知错误';

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

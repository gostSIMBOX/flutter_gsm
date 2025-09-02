// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'GOSTsimbox Шлюз';

  @override
  String get configureSipCredentials => 'Настройте ваши SIP учетные данные';

  @override
  String get sipUsername => 'SIP Имя пользователя';

  @override
  String get sipPassword => 'SIP Пароль';

  @override
  String get sipServer => 'SIP Сервер';

  @override
  String get sipPort => 'SIP Порт';

  @override
  String get connect => 'Подключиться';

  @override
  String get rememberCredentials => 'Запомнить учетные данные и автовход';

  @override
  String get pleaseEnterSipUsername =>
      'Пожалуйста, введите SIP имя пользователя';

  @override
  String get pleaseEnterSipPassword => 'Пожалуйста, введите SIP пароль';

  @override
  String get pleaseEnterSipServer => 'Пожалуйста, введите SIP сервер';

  @override
  String get pleaseEnterSipPort => 'Пожалуйста, введите SIP порт';

  @override
  String get pleaseEnterValidPort =>
      'Пожалуйста, введите корректный номер порта (1-65535)';

  @override
  String get authenticationFailed => 'Ошибка аутентификации';

  @override
  String get gatewayStatus => 'Статус Шлюза';

  @override
  String get sipConnection => 'SIP Соединение';

  @override
  String get gsmConnection => 'GSM Соединение';

  @override
  String get activeCalls => 'Активные Звонки';

  @override
  String get registered => 'Зарегистрирован';

  @override
  String get disconnected => 'Отключен';

  @override
  String get connected => 'Подключенные';

  @override
  String get noCalls => 'Нет Звонков';

  @override
  String get oneActive => '1 Активный';

  @override
  String get gatewayControls => 'Управление Шлюзом';

  @override
  String get startGateway => 'Запустить Шлюз';

  @override
  String get stopGateway => 'Остановить Шлюз';

  @override
  String get endCall => 'Завершить Звонок';

  @override
  String get recentLogs => 'Последние Логи';

  @override
  String get viewAll => 'Посмотреть Все';

  @override
  String get noLogsAvailable => 'Логи недоступны';

  @override
  String get gatewayLogsWillAppearHere => 'Логи шлюза появятся здесь';

  @override
  String get testControls => 'Тестовые Элементы';

  @override
  String get testSipCall => 'Тест SIP Звонка';

  @override
  String get testGsmCall => 'Тест GSM Звонка';

  @override
  String get settings => 'Настройки';

  @override
  String get sipConfiguration => 'SIP Конфигурация';

  @override
  String get gatewayOptions => 'Опции Шлюза';

  @override
  String get autoStartGateway => 'Автозапуск Шлюза';

  @override
  String get autoStartGatewayDesc =>
      'Автоматически запускать шлюз при запуске приложения';

  @override
  String get replaceDefaultDialer => 'Заменить Стандартный Наборщик';

  @override
  String get replaceDefaultDialerDesc =>
      'Заменить системный наборщик на наборщик шлюза';

  @override
  String get enablePermissions => 'Включить Разрешения';

  @override
  String get enablePermissionsDesc =>
      'Запрашивать повышенные разрешения для телефонии';

  @override
  String get rememberCredentialsSettings => 'Запомнить Учетные Данные';

  @override
  String get rememberCredentialsDesc => 'Сохранить учетные данные и автовход';

  @override
  String get saveSettings => 'Сохранить Настройки';

  @override
  String get settingsSavedSuccessfully => 'Настройки успешно сохранены';

  @override
  String get errorSavingSettings => 'Ошибка сохранения настроек';

  @override
  String get gatewayLogs => 'Логи Шлюза';

  @override
  String get searchLogs => 'Поиск логов...';

  @override
  String get clearLogs => 'Очистить Логи';

  @override
  String get clearLogsConfirmation =>
      'Вы уверены, что хотите очистить все логи? Это действие нельзя отменить.';

  @override
  String get cancel => 'Отмена';

  @override
  String get clear => 'Очистить';

  @override
  String get logsClearedSuccessfully => 'Логи успешно очищены';

  @override
  String get errorClearingLogs => 'Ошибка очистки логов';

  @override
  String get errorLoadingLogs => 'Ошибка загрузки логов';

  @override
  String get stopped => 'Остановлен';

  @override
  String get starting => 'Запуск...';

  @override
  String get running => 'Работает';

  @override
  String get runningRegistered => 'Работает (Зарегистрирован)';

  @override
  String get runningConnecting => 'Работает (Подключение)';

  @override
  String get runningDisconnected => 'Работает (Отключен)';

  @override
  String get error => 'Ошибка';

  @override
  String get connecting => 'Подключение...';

  @override
  String get registeredStatus => 'Зарегистрирован';

  @override
  String get callInProgress => 'Звонок в процессе';

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get smppConfiguration => 'SMPP Конфигурация';

  @override
  String get smppServerHost => 'SMPP Сервер';

  @override
  String get smppPort => 'SMPP Порт';

  @override
  String get systemId => 'ID Системы';

  @override
  String get systemPassword => 'Пароль Системы';

  @override
  String get systemType => 'Тип Системы';

  @override
  String get connectionStatus => 'Статус Соединения';

  @override
  String get bound => 'Привязан';

  @override
  String get disconnect => 'Отключиться';

  @override
  String get testConnection => 'Тест Соединения';

  @override
  String get saveConfiguration => 'Сохранить Конфигурацию';

  @override
  String get resetConfiguration => 'Сбросить Конфигурацию';

  @override
  String get advancedSettings => 'Дополнительные Настройки';

  @override
  String get enableDeliveryReceipts => 'Включить Подтверждения Доставки';

  @override
  String get enableDeliveryReceiptsDesc =>
      'Получать подтверждения доставки отправленных сообщений';

  @override
  String get enableLogging => 'Включить Логирование';

  @override
  String get enableLoggingDesc =>
      'Логировать SMPP протокольные сообщения для отладки';

  @override
  String get configurationInfo => 'Информация о Конфигурации';

  @override
  String get protocolVersion => 'Версия Протокола';

  @override
  String get defaultPort => 'Порт по Умолчанию';

  @override
  String get connectionType => 'Тип Соединения';

  @override
  String get keepAlive => 'Поддержание Соединения';

  @override
  String get reconnectInterval => 'Интервал Переподключения';

  @override
  String get pleaseEnterSmppHost => 'Пожалуйста, введите SMPP сервер';

  @override
  String get pleaseEnterPort => 'Пожалуйста, введите номер порта';

  @override
  String get pleaseEnterSystemId => 'Пожалуйста, введите ID системы';

  @override
  String get pleaseEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String get configurationSaved => 'Конфигурация успешно сохранена';

  @override
  String get errorSavingConfiguration => 'Ошибка сохранения конфигурации';

  @override
  String get connectionTestSuccess => 'Тест соединения успешен';

  @override
  String get connectionTestFailed => 'Тест соединения не удался';

  @override
  String get showPassword => 'Показать Пароль';

  @override
  String get hidePassword => 'Скрыть Пароль';

  @override
  String get transceiver => 'Приемопередатчик';

  @override
  String get transmitter => 'Передатчик';

  @override
  String get receiver => 'Приемник';

  @override
  String get seconds => 'секунд';

  @override
  String get callHistory => 'История Звонков';

  @override
  String get loadingCalls => 'Загрузка звонков...';

  @override
  String get errorLoadingCalls => 'Ошибка загрузки звонков';

  @override
  String get noCallsFound => 'Звонки не найдены';

  @override
  String get callHistoryWillAppearHere => 'История звонков появится здесь';

  @override
  String get all => 'Все';

  @override
  String get incoming => 'Входящие';

  @override
  String get outgoing => 'Исходящие';

  @override
  String get missed => 'Пропущенные';

  @override
  String get completed => 'Завершенные';

  @override
  String get rejected => 'Отклоненные';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get makeCall => 'Совершить Звонок';

  @override
  String get phoneNumber => 'Номер Телефона';

  @override
  String get enterPhoneNumber => 'Введите номер телефона';

  @override
  String get callInformation => 'Информация о Звонке';

  @override
  String get from => 'От';

  @override
  String get to => 'К';

  @override
  String get duration => 'Длительность';

  @override
  String get status => 'Статус';

  @override
  String get lineId => 'ID Линии';

  @override
  String get recording => 'Запись';

  @override
  String get filterCalls => 'Фильтр Звонков';

  @override
  String get retry => 'Повторить';

  @override
  String get close => 'Закрыть';

  @override
  String get apply => 'Применить';

  @override
  String get calling => 'Звоню';

  @override
  String get openingSmsTo => 'Открываю SMS для';
}

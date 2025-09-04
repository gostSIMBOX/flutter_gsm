import 'dart:math';

class EasterEggs {
  static const List<String> developerMessages = [
    'Мозгач108 активирован! 🧠✨',
    'Код написан с любовью и кофе ☕',
    'Если видите это сообщение, вы настоящий хакер! 🕵️‍♂️',
    'Разработчик был здесь 👨‍💻',
    'Этот код работает на магии и кофе 🪄☕',
    'GOSTsimbox - лучший шлюз в галактике! 🌌',
    'Сделано с ❤️ в России',
    'Код проверен котами 🐱',
    'Если что-то сломается, вините кота 🐱',
    'Этот шлюз может связаться даже с инопланетянами 👽',
  ];

  static const List<String> secretCommands = [
    'Мозгач108',
    'Мозгач',
    'Brain',
    'Easter Egg',
    'Пасхалка',
    'Секрет',
    'Магия',
    'Кофе',
    'Кот',
  ];

  static const Map<String, String> secretResponses = {
    'Мозгач108': 'Активирован режим "Мозгач108"! 🧠✨ Все системы работают на максимальной мощности!',
    'Мозгач': 'Мозгач обнаружен! 🧠 Активируем интеллектуальный режим!',
    'Brain': 'Brain mode activated! 🧠 Switching to English mode!',
    'Easter Egg': 'You found an Easter Egg! 🥚 Congratulations, developer!',
    'Пасхалка': 'Пасхалка найдена! 🥚 Вы настоящий исследователь!',
    'Секрет': 'Секретный режим активирован! 🤫',
    'Магия': 'Магия активирована! 🪄 Шлюз теперь работает на волшебстве!',
    'Кофе': 'Кофе загружен! ☕ Разработчик доволен!',
    'Кот': 'Кот активирован! 🐱 Все системы проверены пушистым инспектором!',
  };

  static String getRandomDeveloperMessage() {
    final random = Random();
    return developerMessages[random.nextInt(developerMessages.length)];
  }

  static String? checkSecretCommand(String input) {
    final normalizedInput = input.toLowerCase().trim();
    
    for (final command in secretCommands) {
      if (normalizedInput.contains(command.toLowerCase())) {
        return secretResponses[command];
      }
    }
    
    return null;
  }

  static bool isSecretCommand(String input) {
    return checkSecretCommand(input) != null;
  }

  static String getMotivationalQuote() {
    final quotes = [
      'Код - это поэзия, написанная на языке логики 📝',
      'Каждая ошибка - это возможность стать лучше 🚀',
      'Программирование - это искусство решения проблем 🎨',
      'Лучший код - это тот, который понятен даже котам 🐱',
      'Технологии меняют мир, а мы меняем технологии 🌍',
      'В коде есть красота, если уметь её видеть ✨',
      'Каждая строка кода - это шаг к будущему 🔮',
    ];
    
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }
}

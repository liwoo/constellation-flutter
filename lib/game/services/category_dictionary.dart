/// Category dictionary service for Alpha Quest game mode
/// Contains categories with valid words for each starting letter
class CategoryDictionary {
  CategoryDictionary._();

  static final CategoryDictionary instance = CategoryDictionary._();

  /// All available categories
  static const List<String> categories = [
    'ANIMALS',
    'COUNTRIES',
    'FOODS',
    'SPORTS',
    'MOVIES',
    'CITIES',
    'BRANDS',
    'COLORS',
    'JOBS',
    'FRUITS',
  ];

  /// Dictionary of categories with valid words organized by starting letter
  /// Structure: { 'CATEGORY': { 'A': ['word1', 'word2'], 'B': [...] } }
  static const Map<String, Map<String, List<String>>> dictionary = {
    'ANIMALS': {
      'A': ['ANT', 'APE', 'ALLIGATOR', 'ANTELOPE', 'ARMADILLO'],
      'B': ['BEAR', 'BAT', 'BEE', 'BUFFALO', 'BUTTERFLY'],
      'C': ['CAT', 'COW', 'CAMEL', 'CHEETAH', 'CROCODILE'],
      'D': ['DOG', 'DEER', 'DOLPHIN', 'DUCK', 'DONKEY'],
      'E': ['ELEPHANT', 'EAGLE', 'EEL', 'EMU', 'ELK'],
      'F': ['FOX', 'FROG', 'FISH', 'FLAMINGO', 'FALCON'],
      'G': ['GOAT', 'GIRAFFE', 'GORILLA', 'GOOSE', 'GECKO'],
      'H': ['HORSE', 'HIPPO', 'HAWK', 'HAMSTER', 'HARE'],
      'I': ['IGUANA', 'IMPALA', 'IBIS'],
      'J': ['JAGUAR', 'JELLYFISH', 'JACKAL'],
      'K': ['KANGAROO', 'KOALA', 'KIWI', 'KINGFISHER'],
      'L': ['LION', 'LEOPARD', 'LLAMA', 'LIZARD', 'LOBSTER'],
      'M': ['MONKEY', 'MOUSE', 'MOOSE', 'MOLE', 'MEERKAT'],
      'N': ['NEWT', 'NIGHTINGALE', 'NARWHAL'],
      'O': ['OWL', 'OTTER', 'OSTRICH', 'OCTOPUS', 'OCELOT'],
      'P': ['PANDA', 'PENGUIN', 'PIG', 'PARROT', 'PANTHER'],
      'Q': ['QUAIL', 'QUOKKA'],
      'R': ['RABBIT', 'RAT', 'RHINO', 'RACCOON', 'RAVEN'],
      'S': ['SNAKE', 'SHARK', 'SPIDER', 'SQUIRREL', 'SEAL'],
      'T': ['TIGER', 'TURTLE', 'TOUCAN', 'TOAD', 'TAPIR'],
      'U': ['UNICORN', 'URCHIN'],
      'V': ['VULTURE', 'VIPER'],
      'W': ['WOLF', 'WHALE', 'WALRUS', 'WOMBAT', 'WEASEL'],
      'X': ['XERUS'],
      'Y': ['YAK'],
      'Z': ['ZEBRA', 'ZEBU'],
    },
    'COUNTRIES': {
      'A': ['ARGENTINA', 'AUSTRALIA', 'AUSTRIA', 'ALBANIA'],
      'B': ['BRAZIL', 'BELGIUM', 'BOLIVIA', 'BANGLADESH'],
      'C': ['CANADA', 'CHINA', 'CHILE', 'COLOMBIA', 'CUBA'],
      'D': ['DENMARK', 'DOMINICA'],
      'E': ['EGYPT', 'ENGLAND', 'ECUADOR', 'ESTONIA'],
      'F': ['FRANCE', 'FINLAND', 'FIJI'],
      'G': ['GERMANY', 'GREECE', 'GHANA', 'GUATEMALA'],
      'H': ['HUNGARY', 'HAITI', 'HONDURAS'],
      'I': ['INDIA', 'IRELAND', 'ITALY', 'ICELAND', 'INDONESIA'],
      'J': ['JAPAN', 'JAMAICA', 'JORDAN'],
      'K': ['KENYA', 'KOREA', 'KUWAIT'],
      'L': ['LIBYA', 'LEBANON', 'LAOS', 'LATVIA'],
      'M': ['MEXICO', 'MOROCCO', 'MALAYSIA', 'MONGOLIA'],
      'N': ['NORWAY', 'NEPAL', 'NIGERIA', 'NETHERLANDS'],
      'O': ['OMAN'],
      'P': ['POLAND', 'PERU', 'PORTUGAL', 'PAKISTAN', 'PANAMA'],
      'Q': ['QATAR'],
      'R': ['RUSSIA', 'ROMANIA', 'RWANDA'],
      'S': ['SPAIN', 'SWEDEN', 'SWITZERLAND', 'SINGAPORE'],
      'T': ['TURKEY', 'THAILAND', 'TAIWAN', 'TUNISIA'],
      'U': ['USA', 'UGANDA', 'UKRAINE', 'URUGUAY'],
      'V': ['VIETNAM', 'VENEZUELA'],
      'W': ['WALES'],
      'X': [],
      'Y': ['YEMEN'],
      'Z': ['ZAMBIA', 'ZIMBABWE'],
    },
    'FOODS': {
      'A': ['APPLE', 'AVOCADO', 'ALMOND', 'ASPARAGUS'],
      'B': ['BREAD', 'BANANA', 'BACON', 'BURRITO', 'BROCCOLI'],
      'C': ['CAKE', 'CHEESE', 'CHICKEN', 'CARROT', 'COOKIE'],
      'D': ['DONUT', 'DUMPLING', 'DATE'],
      'E': ['EGG', 'EGGPLANT', 'EDAMAME'],
      'F': ['FISH', 'FRIES', 'FRUIT'],
      'G': ['GRAPE', 'GARLIC', 'GINGER'],
      'H': ['HAM', 'HONEY', 'HUMMUS', 'HOTDOG'],
      'I': ['ICECREAM'],
      'J': ['JAM', 'JUICE', 'JELLY'],
      'K': ['KALE', 'KETCHUP', 'KEBAB'],
      'L': ['LEMON', 'LETTUCE', 'LOBSTER', 'LASAGNA'],
      'M': ['MANGO', 'MILK', 'MUSHROOM', 'MUFFIN'],
      'N': ['NOODLE', 'NUT', 'NACHOS'],
      'O': ['ORANGE', 'OLIVE', 'ONION', 'OATMEAL'],
      'P': ['PIZZA', 'PASTA', 'PIE', 'PANCAKE', 'PEAR'],
      'Q': ['QUINOA', 'QUICHE'],
      'R': ['RICE', 'RAISIN', 'RADISH'],
      'S': ['SALAD', 'SOUP', 'STEAK', 'SUSHI', 'SANDWICH'],
      'T': ['TACO', 'TOAST', 'TOMATO', 'TOFU'],
      'U': ['UBE'],
      'V': ['VANILLA', 'VEGETABLE'],
      'W': ['WAFFLE', 'WATERMELON', 'WALNUT'],
      'X': [],
      'Y': ['YOGURT', 'YAM'],
      'Z': ['ZUCCHINI'],
    },
    'SPORTS': {
      'A': ['ARCHERY', 'ATHLETICS'],
      'B': ['BASKETBALL', 'BASEBALL', 'BOXING', 'BADMINTON'],
      'C': ['CRICKET', 'CYCLING', 'CLIMBING'],
      'D': ['DIVING', 'DARTS'],
      'E': ['EQUESTRIAN'],
      'F': ['FOOTBALL', 'FENCING', 'FISHING'],
      'G': ['GOLF', 'GYMNASTICS'],
      'H': ['HOCKEY', 'HANDBALL', 'HIKING'],
      'I': ['ICESKATING'],
      'J': ['JUDO', 'JAVELIN'],
      'K': ['KARATE', 'KAYAKING'],
      'L': ['LACROSSE'],
      'M': ['MARATHON', 'MMA'],
      'N': ['NETBALL'],
      'O': ['OLYMPICS'],
      'P': ['POLO', 'PINGPONG'],
      'Q': [],
      'R': ['RUGBY', 'ROWING', 'RUNNING'],
      'S': ['SOCCER', 'SWIMMING', 'SKIING', 'SURFING', 'SKATING'],
      'T': ['TENNIS', 'TRIATHLON', 'TAEKWONDO'],
      'U': [],
      'V': ['VOLLEYBALL'],
      'W': ['WRESTLING', 'WEIGHTLIFTING', 'WAKEBOARDING'],
      'X': [],
      'Y': ['YOGA'],
      'Z': [],
    },
    'MOVIES': {
      'A': ['AVATAR', 'AVENGERS', 'ALIEN', 'ALADDIN'],
      'B': ['BATMAN', 'BRAVE', 'BAMBI'],
      'C': ['CARS', 'COCO', 'CINDERELLA'],
      'D': ['DUMBO', 'DUNE'],
      'E': ['ET', 'ENCANTO', 'EXTRACTION'],
      'F': ['FROZEN', 'FINDING', 'FURY'],
      'G': ['GLADIATOR', 'GRAVITY', 'GREASE'],
      'H': ['HERCULES', 'HARRY'],
      'I': ['INCEPTION', 'IRON', 'INTERSTELLAR'],
      'J': ['JAWS', 'JOKER', 'JUMANJI'],
      'K': ['KONG', 'KARATE'],
      'L': ['LION', 'LUCA'],
      'M': ['MATRIX', 'MULAN', 'MOANA'],
      'N': ['NEMO'],
      'O': ['ONWARD'],
      'P': ['PIRATES', 'PETER'],
      'Q': [],
      'R': ['ROCKY', 'RATATOUILLE', 'RAMBO'],
      'S': ['SHREK', 'SPIDERMAN', 'STAR'],
      'T': ['TITANIC', 'TARZAN', 'THOR', 'TANGLED', 'TOY'],
      'U': ['UP'],
      'V': ['VENOM'],
      'W': ['WONDER', 'WALL'],
      'X': ['XMEN'],
      'Y': [],
      'Z': ['ZOOTOPIA', 'ZODIAC'],
    },
    'CITIES': {
      'A': ['ATLANTA', 'AMSTERDAM', 'ATHENS', 'AUSTIN'],
      'B': ['BOSTON', 'BERLIN', 'BARCELONA', 'BANGKOK'],
      'C': ['CHICAGO', 'CAIRO', 'COPENHAGEN'],
      'D': ['DALLAS', 'DUBAI', 'DUBLIN', 'DENVER'],
      'E': ['EDINBURGH'],
      'F': ['FLORENCE'],
      'G': ['GENEVA'],
      'H': ['HOUSTON', 'HANOI', 'HELSINKI'],
      'I': ['ISTANBUL'],
      'J': ['JAKARTA'],
      'K': ['KYOTO'],
      'L': ['LONDON', 'LISBON', 'LAGOS', 'LIMA'],
      'M': ['MIAMI', 'MADRID', 'MOSCOW', 'MELBOURNE', 'MUNICH'],
      'N': ['NAIROBI', 'NAPLES'],
      'O': ['OSLO', 'OSAKA', 'ORLANDO'],
      'P': ['PARIS', 'PRAGUE', 'PERTH'],
      'Q': ['QUEBEC'],
      'R': ['ROME', 'RIO'],
      'S': ['SYDNEY', 'SEATTLE', 'SEOUL', 'SINGAPORE'],
      'T': ['TOKYO', 'TORONTO', 'TAIPEI'],
      'U': [],
      'V': ['VENICE', 'VIENNA', 'VANCOUVER'],
      'W': ['WASHINGTON', 'WARSAW'],
      'X': [],
      'Y': ['YOKOHAMA'],
      'Z': ['ZURICH', 'ZAGREB'],
    },
    'BRANDS': {
      'A': ['APPLE', 'AMAZON', 'ADIDAS', 'AUDI'],
      'B': ['BMW', 'BURBERRY', 'BURGER'],
      'C': ['COCA', 'CHANEL', 'CHEVROLET'],
      'D': ['DISNEY', 'DELL', 'DIOR'],
      'E': ['ESPN'],
      'F': ['FORD', 'FACEBOOK', 'FERRARI'],
      'G': ['GOOGLE', 'GUCCI', 'GAP'],
      'H': ['HONDA', 'HP', 'HERMES'],
      'I': ['INTEL', 'IBM', 'IKEA'],
      'J': ['JAGUAR'],
      'K': ['KFC'],
      'L': ['LEGO', 'LEXUS', 'LEVIS'],
      'M': ['MERCEDES', 'MICROSOFT', 'MARVEL'],
      'N': ['NIKE', 'NINTENDO', 'NETFLIX', 'NESTLE'],
      'O': ['ORACLE'],
      'P': ['PEPSI', 'PRADA', 'PORSCHE', 'PUMA'],
      'Q': [],
      'R': ['ROLEX', 'REEBOK'],
      'S': ['SAMSUNG', 'SONY', 'STARBUCKS', 'SUBWAY'],
      'T': ['TESLA', 'TOYOTA', 'TWITTER'],
      'U': ['UBER', 'UNIQLO'],
      'V': ['VISA', 'VERSACE', 'VOLKSWAGEN'],
      'W': ['WALMART'],
      'X': ['XBOX', 'XEROX'],
      'Y': ['YAHOO', 'YOUTUBE'],
      'Z': ['ZARA', 'ZOOM'],
    },
    'COLORS': {
      'A': ['AQUA', 'AMBER', 'AZURE'],
      'B': ['BLUE', 'BLACK', 'BROWN', 'BEIGE'],
      'C': ['CYAN', 'CORAL', 'CRIMSON', 'CREAM'],
      'D': ['DENIM'],
      'E': ['EMERALD', 'EBONY'],
      'F': ['FUCHSIA'],
      'G': ['GREEN', 'GOLD', 'GRAY', 'GREY'],
      'H': ['HAZEL'],
      'I': ['INDIGO', 'IVORY'],
      'J': ['JADE'],
      'K': ['KHAKI'],
      'L': ['LAVENDER', 'LIME', 'LILAC'],
      'M': ['MAROON', 'MAGENTA', 'MINT', 'MAUVE'],
      'N': ['NAVY'],
      'O': ['ORANGE', 'OLIVE'],
      'P': ['PINK', 'PURPLE', 'PEACH', 'PLUM'],
      'Q': [],
      'R': ['RED', 'ROSE', 'RUBY'],
      'S': ['SILVER', 'SALMON', 'SCARLET', 'SKY'],
      'T': ['TAN', 'TEAL', 'TURQUOISE'],
      'U': ['UMBER'],
      'V': ['VIOLET', 'VERMILION'],
      'W': ['WHITE', 'WHEAT'],
      'X': [],
      'Y': ['YELLOW'],
      'Z': [],
    },
    'JOBS': {
      'A': ['ACTOR', 'ARCHITECT', 'ACCOUNTANT', 'ASTRONAUT'],
      'B': ['BAKER', 'BANKER', 'BARBER', 'BUILDER'],
      'C': ['CHEF', 'CARPENTER', 'CASHIER', 'CLERK'],
      'D': ['DOCTOR', 'DENTIST', 'DESIGNER', 'DRIVER'],
      'E': ['ENGINEER', 'EDITOR', 'ELECTRICIAN'],
      'F': ['FARMER', 'FIREFIGHTER', 'FLORIST'],
      'G': ['GARDENER', 'GUARD'],
      'H': ['HAIRDRESSER', 'HOST'],
      'I': ['INSPECTOR'],
      'J': ['JOURNALIST', 'JUDGE', 'JANITOR'],
      'K': [],
      'L': ['LAWYER', 'LIBRARIAN'],
      'M': ['MECHANIC', 'MUSICIAN', 'MANAGER'],
      'N': ['NURSE', 'NARRATOR'],
      'O': ['OFFICER'],
      'P': ['PILOT', 'PLUMBER', 'PAINTER', 'PHARMACIST'],
      'Q': [],
      'R': ['RECEPTIONIST', 'REPORTER'],
      'S': ['SCIENTIST', 'SURGEON', 'SALESMAN', 'SECRETARY'],
      'T': ['TEACHER', 'TRAINER', 'TAILOR'],
      'U': ['UMPIRE'],
      'V': ['VET', 'VENDOR'],
      'W': ['WAITER', 'WRITER', 'WELDER'],
      'X': [],
      'Y': [],
      'Z': ['ZOOKEEPER'],
    },
    'FRUITS': {
      'A': ['APPLE', 'APRICOT', 'AVOCADO'],
      'B': ['BANANA', 'BLUEBERRY', 'BLACKBERRY'],
      'C': ['CHERRY', 'COCONUT', 'CANTALOUPE', 'CRANBERRY'],
      'D': ['DATE', 'DRAGONFRUIT', 'DURIAN'],
      'E': ['ELDERBERRY'],
      'F': ['FIG'],
      'G': ['GRAPE', 'GRAPEFRUIT', 'GUAVA'],
      'H': ['HONEYDEW'],
      'I': [],
      'J': ['JACKFRUIT'],
      'K': ['KIWI', 'KUMQUAT'],
      'L': ['LEMON', 'LIME', 'LYCHEE'],
      'M': ['MANGO', 'MELON', 'MULBERRY'],
      'N': ['NECTARINE'],
      'O': ['ORANGE'],
      'P': ['PAPAYA', 'PEACH', 'PEAR', 'PINEAPPLE', 'PLUM', 'POMEGRANATE'],
      'Q': ['QUINCE'],
      'R': ['RASPBERRY', 'RAMBUTAN'],
      'S': ['STRAWBERRY', 'STARFRUIT'],
      'T': ['TANGERINE', 'TOMATO'],
      'U': ['UGI'],
      'V': [],
      'W': ['WATERMELON'],
      'X': [],
      'Y': ['YUZU'],
      'Z': [],
    },
  };

  /// Get a random category
  String getRandomCategory() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return categories[random % categories.length];
  }

  /// Get a random category that has words for the given letter
  String? getRandomCategoryForLetter(String letter) {
    final upperLetter = letter.toUpperCase();
    final validCategories = categories.where((category) {
      final words = dictionary[category]?[upperLetter];
      return words != null && words.isNotEmpty;
    }).toList();

    if (validCategories.isEmpty) return null;

    final random = DateTime.now().millisecondsSinceEpoch;
    return validCategories[random % validCategories.length];
  }

  /// Check if a word is valid for the given category and starting letter
  bool isValidWord(String word, String category, String startingLetter) {
    final upperWord = word.toUpperCase();
    final upperLetter = startingLetter.toUpperCase();
    final upperCategory = category.toUpperCase();

    // Check if word starts with the required letter
    if (!upperWord.startsWith(upperLetter)) return false;

    // Check if word exists in the category dictionary
    final words = dictionary[upperCategory]?[upperLetter];
    if (words == null) return false;

    return words.contains(upperWord);
  }

  /// Get all valid words for a category and letter
  List<String> getWordsForCategoryAndLetter(String category, String letter) {
    final upperCategory = category.toUpperCase();
    final upperLetter = letter.toUpperCase();
    return dictionary[upperCategory]?[upperLetter] ?? [];
  }

  /// Check if a category has any words for the given letter
  bool categoryHasWordsForLetter(String category, String letter) {
    final words = getWordsForCategoryAndLetter(category, letter);
    return words.isNotEmpty;
  }
}

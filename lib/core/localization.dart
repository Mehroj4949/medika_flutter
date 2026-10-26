class MedikaText {
  final String lang;
  const MedikaText(this.lang);

  bool get isTajik => lang == 'tj';
  String tr(String ru, String tj) => isTajik ? tj : ru;

  String get home => tr('Главная', 'Асосӣ');
  String get catalog => 'Каталог';
  String get select => 'SELECT';
  String get favorites => tr('Избранное', 'Писандида');
  String get profile => tr('Профиль', 'Профил');
  String get search => tr('Поиск оборудования, модели или бренда', 'Ҷустуҷӯи таҷҳизот, модел ё бренд');
  String get priceRequest => tr('Цена по запросу', 'Нарх бо дархост');
  String get quote => tr('Получить предложение', 'Пешниҳод гиред');
  String get details => tr('Подробнее', 'Муфассал');
  String get compare => tr('Сравнить', 'Муқоиса');
  String get brands => tr('Бренды', 'Брендҳо');
  String get categories => tr('Категории', 'Категорияҳо');
  String get popular => tr('Популярное оборудование', 'Таҷҳизоти машҳур');
  String get newItems => tr('Новинки', 'Навгониҳо');
  String get all => tr('Все', 'Ҳама');
  String get service => 'MEDIKA CARE';
  String get delivery => tr('Доставка', 'Расонидан');
  String get installation => tr('Установка', 'Насб');
  String get warranty => tr('Гарантия', 'Кафолат');
}

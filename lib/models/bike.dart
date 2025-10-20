enum Bike {
  yamahaR7('Yamaha R7', 'assets/images/yamahaR7'),
  hondaSBR('Honda CBR 605 R', 'assets/images/hondaCBR650R'),
  kawasakiZX('Kawasaki ZX4R', 'assets/images/kawasakiZX4R');

  final String displayName;
  final String assetPath;
  const Bike(this.displayName, this.assetPath);

  @override
  String toString() => displayName;
}

final List<Bike> allBikes = Bike.values;
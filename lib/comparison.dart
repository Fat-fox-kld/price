enum Dimension { mass, volume, count }
enum Unit {
  gram('г', Dimension.mass, 1),
  kilogram('кг', Dimension.mass, 1000),
  milliliter('мл', Dimension.volume, 1),
  liter('л', Dimension.volume, 1000),
  piece('шт', Dimension.count, 1);
  const Unit(this.label, this.dimension, this.factor);
  final String label;
  final Dimension dimension;
  final double factor;
}
class Product {
  Product(this.name, this.price, this.quantity, this.unit) {
    if (!price.isFinite || !quantity.isFinite || price <= 0 || quantity <= 0) {
      throw ArgumentError('Цена и количество должны быть положительными');
    }
  }
  final String name;
  final double price, quantity;
  final Unit unit;
  double get baseQuantity => quantity * unit.factor;
  double get basePrice => price / baseQuantity;
}
class Basis {
  const Basis(this.label, this.factor);
  final String label;
  final double factor;
  @override
  bool operator ==(Object other) => other is Basis && other.label == label && other.factor == factor;
  @override
  int get hashCode => Object.hash(label, factor);
}
List<Basis> bases(Dimension d) => switch (d) {
  Dimension.mass => [const Basis('100 г', 100), const Basis('1 кг', 1000)],
  Dimension.volume => [const Basis('100 мл', 100), const Basis('1 л', 1000)],
  Dimension.count => [const Basis('1 шт', 1)],
};
Basis smartBasis(List<Product> items) {
  if (items.isEmpty) throw ArgumentError('Нет товаров');
  final d = items.first.unit.dimension;
  if (items.any((p) => p.unit.dimension != d)) throw ArgumentError('Несовместимые единицы');
  final options = bases(d);
  if (d == Dimension.count) return options.first;
  final names = items.map((p) => p.name.toLowerCase()).join(' ');
  final large = d == Dimension.mass
      ? RegExp(r'картоф|морков|лук|яблок|мук|сахар|рис|круп')
      : RegExp(r'молок|сок|вод[аы]|кефир');
  final small = d == Dimension.mass
      ? RegExp(r'шоколад|печень|конфет|сыр')
      : RegExp(r'духи|сироп');
  if (large.hasMatch(names) && !small.hasMatch(names)) return options.last;
  if (small.hasMatch(names) && !large.hasMatch(names)) return options.first;
  final sizes = items.map((p) => p.baseQuantity).toList()..sort();
  final n = sizes.length;
  final median = n.isOdd ? sizes[n ~/ 2] : (sizes[n ~/ 2 - 1] + sizes[n ~/ 2]) / 2;
  return median < 500 ? options.first : options.last;
}
bool isWinner(Product p, List<Product> items) {
  if (items.length < 2) return false;
  final compatible = items.where((x) => x.unit.dimension == p.unit.dimension).toList();
  if (compatible.length < 2) return false;
  final best = compatible.map((x) => x.basePrice).reduce((a, b) => a < b ? a : b);
  return (p.basePrice - best).abs() <= best.abs() * 1e-9;
}
double? number(String text) => double.tryParse(text.trim().replaceAll(' ', '').replaceAll(',', '.'));

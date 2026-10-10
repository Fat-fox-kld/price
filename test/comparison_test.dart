import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare/comparison.dart';
import 'package:price_compare/scanner.dart';
void main() {
  test('Шоколад: 120 рублей за 100 г выгоднее 100 за 80 г', () {
    final a = Product('Шоколад', 100, 80, Unit.gram);
    final b = Product('Шоколад', 120, 100, Unit.gram);
    expect(a.basePrice * 100, 125);
    expect(isWinner(a, [a, b]), false);
    expect(isWinner(b, [a, b]), true);
    expect(smartBasis([a, b]).label, '100 г');
  });
  test('Литры и миллилитры приводятся к одной базе; ничьи подсвечиваются', () {
    final a = Product('Молоко', 110, 0.9, Unit.liter);
    final b = Product('Молоко', 120, 1000, Unit.milliliter);
    final c = Product('Молоко', 60, 500, Unit.milliliter);
    expect(smartBasis([a, b, c]).label, '1 л');
    expect(isWinner(b, [a, b, c]), true);
    expect(isWinner(c, [a, b, c]), true);
  });
  test('Один товар и несовместимые единицы не дают победителя', () {
    final a = Product('Товар', 10, 100, Unit.gram);
    final b = Product('Товар', 10, 100, Unit.milliliter);
    expect(isWinner(a, [a]), false);
    expect(isWinner(a, [a, b]), false);
    expect(() => smartBasis([a, b]), throwsArgumentError);
  });
  test('Некорректные значения запрещены, десятичная запятая поддерживается', () {
    expect(number('119,90'), 119.9);
    expect(() => Product('X', 0, 1, Unit.piece), throwsArgumentError);
    expect(() => Product('X', 1, double.nan, Unit.piece), throwsArgumentError);
  });
  test('Картофель сравнивается за килограмм', () {
    expect(smartBasis([Product('Картофель', 180, 2, Unit.kilogram)]).label, '1 кг');
  });
  test('Не выбираем одну из двух цен по карте автоматически', () {
    final draft = parseDraft('Chocolate 90 g 119,90 RUB 99,90 RUB');
    expect(draft.quantity, '90');
    expect(draft.price, isEmpty);
  });
}

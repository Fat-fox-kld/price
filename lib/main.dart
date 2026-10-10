import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'comparison.dart';
import 'scanner.dart';
void main() => runApp(const PriceApp());
class PriceApp extends StatelessWidget {
  const PriceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Выгоднее',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xff15803d)),
    home: const ComparisonPage(),
  );
}
class ComparisonPage extends StatefulWidget {
  const ComparisonPage({super.key});
  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}
class _ComparisonPageState extends State<ComparisonPage> {
  final items = <Product>[];
  final overrides = <Dimension, Basis>{};
  bool busy = false;
  Future<void> edit({Product? original, Draft? draft}) async {
    final p = await showDialog<Product>(context: context,
      builder: (_) => ProductDialog(original: original, draft: draft));
    if (!mounted || p == null) return;
    setState(() {
      if (original == null) { items.add(p); } else { items[items.indexOf(original)] = p; }
    });
  }
  Future<void> scan(bool multiple, ImageSource source) async {
    setState(() => busy = true);
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;
      final drafts = await MlKitScanner().scan(image.path, multiple: multiple);
      if (!mounted) return;
      if (drafts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Текст не найден. Попробуйте другой снимок или ручной ввод.')));
      }
      for (final draft in drafts) {
        if (!mounted) break;
        await edit(draft: draft);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось обработать фото. Повторите попытку или введите данные вручную.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Выгоднее')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Сравните цену за одинаковое количество', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Масса, объём и штуки сравниваются отдельно. Зелёная рамка отмечает минимальную цену в группе.'),
      if (busy) const LinearProgressIndicator(),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: busy ? null : () => edit(), icon: const Icon(Icons.add), label: const Text('Ввести вручную')),
      Wrap(spacing: 8, children: [
        OutlinedButton.icon(onPressed: busy ? null : () => scan(false, ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Один ценник')),
        OutlinedButton(onPressed: busy ? null : () => scan(true, ImageSource.camera), child: const Text('Несколько · эксперимент')),
        TextButton(onPressed: busy ? null : () => scan(false, ImageSource.gallery), child: const Text('Фото из галереи')),
      ]),
      if (items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text('Добавьте два товара — приложение покажет, какой выгоднее.')),
      for (final d in Dimension.values)
        if (items.any((p) => p.unit.dimension == d)) ...group(d),
    ]),
  );
  List<Widget> group(Dimension dimension) {
    final group = items.where((p) => p.unit.dimension == dimension).toList();
    final basis = overrides[dimension] ?? smartBasis(group);
    return [
      const SizedBox(height: 16),
      DropdownButton<Basis>(value: bases(dimension).firstWhere((b) => b.label == basis.label),
        items: bases(dimension).map((b) => DropdownMenuItem(value: b, child: Text('Цена за ${b.label}'))).toList(),
        onChanged: busy ? null : (b) => setState(() { if (b != null) overrides[dimension] = b; })),
      TextButton(onPressed: busy ? null : () => setState(() => overrides.remove(dimension)), child: const Text('Выбирать единицу автоматически')),
      for (final p in group) Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: isWinner(p, group) ? const Color(0xfff0fdf4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isWinner(p, group) ? const Color(0xff16a34a) : Colors.black12, width: isWinner(p, group) ? 3 : 1)),
        child: ListTile(contentPadding: const EdgeInsets.all(16),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${p.price.toStringAsFixed(2)} ₽ · ${p.quantity} ${p.unit.label}\n${(p.basePrice * basis.factor).toStringAsFixed(2)} ₽ / ${basis.label}${isWinner(p, group) ? '\nСамая выгодная цена' : ''}'),
          onTap: busy ? null : () => edit(original: p),
          trailing: IconButton(onPressed: busy ? null : () => setState(() => items.remove(p)), icon: const Icon(Icons.delete_outline))),
      ),
    ];
  }
}
class ProductDialog extends StatefulWidget {
  const ProductDialog({super.key, this.original, this.draft});
  final Product? original;
  final Draft? draft;
  @override
  State<ProductDialog> createState() => _ProductDialogState();
}
class _ProductDialogState extends State<ProductDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, price, quantity;
  late Unit unit;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.original?.name ?? '');
    price = TextEditingController(text: widget.original?.price.toString() ?? widget.draft?.price ?? '');
    quantity = TextEditingController(text: widget.original?.quantity.toString() ?? widget.draft?.quantity ?? '');
    unit = widget.original?.unit ?? widget.draft?.unit ?? Unit.gram;
  }
  @override
  void dispose() { name.dispose(); price.dispose(); quantity.dispose(); super.dispose(); }
  String? positive(String? text) {
    final n = number(text ?? '');
    return n == null || !n.isFinite || n <= 0 ? 'Введите число больше нуля' : null;
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.draft == null ? 'Товар' : 'Проверьте данные с фото'),
    content: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (widget.draft != null) ...[
        const Text('OCR экспериментальный. Проверьте цену, единицу и количество. Блок текста может быть частью ценника; отмените лишние блоки.'),
        SelectableText(widget.draft!.text),
      ],
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Название'), validator: (s) => s == null || s.trim().isEmpty ? 'Введите название' : null),
      TextFormField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Цена упаковки, ₽'), validator: positive),
      TextFormField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Количество в упаковке'), validator: positive),
      DropdownButtonFormField<Unit>(initialValue: unit, items: Unit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.label))).toList(), onChanged: (u) { if (u != null) unit = u; }),
    ]))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
      FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(context, Product(name.text.trim(), number(price.text)!, number(quantity.text)!, unit)); }, child: const Text('Сохранить'))],
  );
}

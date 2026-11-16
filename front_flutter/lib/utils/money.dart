import 'package:intl/intl.dart';

String formatMoney(String value) => NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
).format(num.parse(value));

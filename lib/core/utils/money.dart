import 'package:intl/intl.dart';

/// Supported currencies and their display precision.
class Currencies {
  const Currencies._();

  static const String usd = 'USD';
  static const String khr = 'KHR';
  static const List<String> all = [usd, khr];

  /// USD has 2 decimals, KHR has 0.
  static int decimalsOf(String currency) => currency == khr ? 0 : 2;
}

/// Exact decimal number backed by a [BigInt] (unscaled value + scale).
///
/// The API sends every amount as a decimal STRING. Amounts must never be
/// parsed into a `double`; all client-side arithmetic (summing balances,
/// comparing against the available balance) goes through this type.
class DecimalAmount implements Comparable<DecimalAmount> {
  const DecimalAmount._(this.unscaled, this.scale);

  /// Value = unscaled / 10^scale.
  final BigInt unscaled;
  final int scale;

  static final RegExp _pattern = RegExp(r'^([+-])?(\d+)(?:\.(\d+))?$');

  static final DecimalAmount zero = DecimalAmount._(BigInt.zero, 0);

  /// Parses `"1250.00"`, `"-10.5"`, `"41000"`. Thousands separators and
  /// whitespace are tolerated. Throws [FormatException] otherwise.
  factory DecimalAmount.parse(String input) {
    final value = tryParse(input);
    if (value == null) {
      throw FormatException('Invalid decimal amount', input);
    }
    return value;
  }

  static DecimalAmount? tryParse(String? input) {
    if (input == null) return null;
    final cleaned = input.replaceAll(',', '').replaceAll(' ', '').trim();
    final match = _pattern.firstMatch(cleaned);
    if (match == null) return null;
    final negative = match.group(1) == '-';
    final intPart = match.group(2)!;
    final fraction = match.group(3) ?? '';
    var unscaled = BigInt.parse('$intPart$fraction');
    if (negative) unscaled = -unscaled;
    return DecimalAmount._(unscaled, fraction.length);
  }

  bool get isZero => unscaled == BigInt.zero;
  bool get isNegative => unscaled < BigInt.zero;
  bool get isPositive => unscaled > BigInt.zero;

  /// Number of significant fraction digits (ignores trailing zeros).
  int get significantScale {
    var s = scale;
    var u = unscaled;
    final ten = BigInt.from(10);
    while (s > 0 && u % ten == BigInt.zero) {
      u = u ~/ ten;
      s--;
    }
    return s;
  }

  DecimalAmount _withScale(int newScale) {
    assert(newScale >= scale);
    if (newScale == scale) return this;
    return DecimalAmount._(
      unscaled * BigInt.from(10).pow(newScale - scale),
      newScale,
    );
  }

  DecimalAmount operator +(DecimalAmount other) {
    final s = scale > other.scale ? scale : other.scale;
    return DecimalAmount._(
      _withScale(s).unscaled + other._withScale(s).unscaled,
      s,
    );
  }

  DecimalAmount operator -(DecimalAmount other) => this + other.negate();

  DecimalAmount negate() => DecimalAmount._(-unscaled, scale);

  DecimalAmount abs() => isNegative ? negate() : this;

  /// Rounds half-up (away from zero) to [decimals] fraction digits.
  DecimalAmount round(int decimals) {
    if (decimals >= scale) return _withScale(decimals);
    final divisor = BigInt.from(10).pow(scale - decimals);
    final absValue = unscaled.abs();
    var quotient = absValue ~/ divisor;
    final remainder = absValue % divisor;
    if (remainder * BigInt.two >= divisor) quotient += BigInt.one;
    return DecimalAmount._(isNegative ? -quotient : quotient, decimals);
  }

  @override
  int compareTo(DecimalAmount other) {
    final s = scale > other.scale ? scale : other.scale;
    return _withScale(s).unscaled.compareTo(other._withScale(s).unscaled);
  }

  bool operator >(DecimalAmount other) => compareTo(other) > 0;
  bool operator <(DecimalAmount other) => compareTo(other) < 0;
  bool operator >=(DecimalAmount other) => compareTo(other) >= 0;
  bool operator <=(DecimalAmount other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is DecimalAmount && compareTo(other) == 0;

  @override
  int get hashCode => round(significantScale).unscaled.hashCode;

  /// Integer part (absolute value) as a [BigInt].
  BigInt get _absIntegerPart =>
      unscaled.abs() ~/ BigInt.from(10).pow(scale);

  /// Fraction digits (absolute value), zero padded to [scale].
  String get _fractionDigits {
    if (scale == 0) return '';
    final f = unscaled.abs() % BigInt.from(10).pow(scale);
    return f.toString().padLeft(scale, '0');
  }

  /// Plain representation with exactly [scale] decimals, e.g. `"1250.00"`.
  String toPlainString() {
    final sign = isNegative ? '-' : '';
    final frac = _fractionDigits;
    return '$sign$_absIntegerPart${frac.isEmpty ? '' : '.$frac'}';
  }

  /// Canonical API string for [currency] (USD `"10.00"`, KHR `"41000"`).
  String toApiString(String currency) =>
      round(Currencies.decimalsOf(currency)).toPlainString();

  @override
  String toString() => toPlainString();
}

/// Display formatting for money and rates. Always works from strings.
class MoneyFormatter {
  const MoneyFormatter._();

  static const String hiddenMask = '••••••';
  static final NumberFormat _grouping = NumberFormat('#,##0', 'en_US');

  /// Groups an integer with thousands separators using `intl`.
  static String _group(BigInt value) {
    // NumberFormat works on `num`; integers up to 2^53 are exact on every
    // platform. Larger values fall back to manual grouping.
    if (value.bitLength < 53) return _grouping.format(value.toInt());
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// `format("1250.5", "USD")` → `$1,250.50`;
  /// `format("41000", "KHR")` → `41,000 ៛`.
  /// [signed] prefixes `+` for positive values (e.g. credits).
  static String format(
    String amount,
    String currency, {
    bool withSymbol = true,
    bool signed = false,
  }) {
    final parsed = DecimalAmount.tryParse(amount);
    if (parsed == null) return amount;
    return formatDecimal(
      parsed,
      currency,
      withSymbol: withSymbol,
      signed: signed,
    );
  }

  static String formatDecimal(
    DecimalAmount value,
    String currency, {
    bool withSymbol = true,
    bool signed = false,
  }) {
    final decimals = Currencies.decimalsOf(currency);
    final rounded = value.round(decimals);
    final plain = rounded.abs().toPlainString();
    final dot = plain.indexOf('.');
    final intPart = BigInt.parse(dot < 0 ? plain : plain.substring(0, dot));
    final fraction = dot < 0 ? '' : plain.substring(dot);
    final number = '${_group(intPart)}$fraction';
    final sign = rounded.isNegative
        ? '-'
        : (signed && rounded.isPositive ? '+' : '');
    if (!withSymbol) return '$sign$number';
    switch (currency) {
      case Currencies.usd:
        return '$sign\$$number';
      case Currencies.khr:
        return '$sign$number ៛';
      default:
        return '$sign$number $currency';
    }
  }

  /// Formats an exchange rate string with up to 4 decimals, trimming
  /// trailing zeros: `"4100.0000"` → `4,100`, `"0.000244"` → `0.0002`.
  static String formatRate(String rate) {
    final parsed = DecimalAmount.tryParse(rate);
    if (parsed == null) return rate;
    final rounded = parsed.round(4);
    final decimals = rounded.significantScale;
    final plain = rounded.round(decimals).abs().toPlainString();
    final dot = plain.indexOf('.');
    final intPart = BigInt.parse(dot < 0 ? plain : plain.substring(0, dot));
    final fraction = dot < 0 ? '' : plain.substring(dot);
    return '${rounded.isNegative ? '-' : ''}${_group(intPart)}$fraction';
  }

  /// Sums decimal strings exactly. Invalid entries are ignored.
  static DecimalAmount sum(Iterable<String> amounts) {
    var total = DecimalAmount.zero;
    for (final a in amounts) {
      final parsed = DecimalAmount.tryParse(a);
      if (parsed != null) total += parsed;
    }
    return total;
  }
}

/// Validation/normalisation of user-typed amounts.
class MoneyInput {
  const MoneyInput._();

  static final RegExp _typed = RegExp(r'^\d+(\.\d*)?$');

  /// Returns the canonical API string (e.g. `"10.00"` for USD, `"41000"`
  /// for KHR) or `null` when the input is not a positive amount with at most
  /// the currency's number of decimals.
  static String? normalize(String raw, String currency) {
    final cleaned = raw.replaceAll(',', '').replaceAll(' ', '').trim();
    if (cleaned.isEmpty || !_typed.hasMatch(cleaned)) return null;
    final withoutTrailingDot =
        cleaned.endsWith('.') ? cleaned.substring(0, cleaned.length - 1) : cleaned;
    final parsed = DecimalAmount.tryParse(withoutTrailingDot);
    if (parsed == null || !parsed.isPositive) return null;
    if (parsed.significantScale > Currencies.decimalsOf(currency)) return null;
    return parsed.toApiString(currency);
  }
}

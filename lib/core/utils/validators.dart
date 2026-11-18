/// Input validation helpers. They return `true`/`false`; presentation code
/// maps failures to localized messages.
class Validators {
  const Validators._();

  static final RegExp _khPhone = RegExp(r'^\+855[1-9]\d{7,8}$');
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _accountNumber = RegExp(r'^\d{8,20}$');
  static final RegExp _digits6 = RegExp(r'^\d{6}$');

  /// Normalises Cambodian numbers to E.164: `012 345 678` → `+85512345678`.
  static String normalizePhone(String input) {
    var p = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (p.startsWith('00855')) p = '+${p.substring(2)}';
    if (p.startsWith('855')) p = '+$p';
    if (p.startsWith('0')) p = '+855${p.substring(1)}';
    if (!p.startsWith('+') && p.isNotEmpty) p = '+855$p';
    return p;
  }

  static bool isValidPhone(String input) =>
      _khPhone.hasMatch(normalizePhone(input));

  static bool isValidEmail(String input) => _email.hasMatch(input.trim());

  /// Backend policy: ≥8 chars, upper, lower, digit and symbol.
  static bool isStrongPassword(String input) {
    if (input.length < 8) return false;
    final hasUpper = input.contains(RegExp(r'[A-Z]'));
    final hasLower = input.contains(RegExp(r'[a-z]'));
    final hasDigit = input.contains(RegExp(r'\d'));
    final hasSymbol = input.contains(RegExp(r'[^A-Za-z0-9]'));
    return hasUpper && hasLower && hasDigit && hasSymbol;
  }

  static bool isValidAccountNumber(String input) =>
      _accountNumber.hasMatch(input.replaceAll(' ', ''));

  static bool isSixDigits(String input) => _digits6.hasMatch(input);

  /// Rejects trivially guessable PINs (all same digit or straight runs).
  static bool isWeakPin(String pin) {
    if (!isSixDigits(pin)) return true;
    if (pin.split('').toSet().length == 1) return true;
    const ascending = '0123456789';
    const descending = '9876543210';
    return ascending.contains(pin) || descending.contains(pin);
  }
}

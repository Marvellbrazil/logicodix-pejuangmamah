class Money implements Comparable<Money> {
  const Money(this.rupiah);

  static const zero = Money(0);

  final int rupiah;

  Money operator +(Money other) => Money(rupiah + other.rupiah);

  Money operator *(int factor) => Money(rupiah * factor);

  bool operator >(Money other) => rupiah > other.rupiah;

  bool operator <(Money other) => rupiah < other.rupiah;

  String format() {
    final digits = rupiah.abs().toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
      grouped.write(digits[i]);
    }
    return '${rupiah < 0 ? '-' : ''}Rp $grouped';
  }

  String formatShort() {
    if (rupiah >= 1000000) {
      final millions = rupiah / 1000000;
      return 'Rp ${_trim(millions)}jt';
    }
    if (rupiah >= 1000) {
      final thousands = rupiah / 1000;
      return 'Rp ${_trim(thousands)}rb';
    }
    return format();
  }

  static String _trim(double value) {
    final fixed = value.toStringAsFixed(1).replaceAll('.', ',');
    return fixed.endsWith(',0')
        ? fixed.substring(0, fixed.length - 2)
        : fixed;
  }

  @override
  int compareTo(Money other) => rupiah.compareTo(other.rupiah);

  @override
  bool operator ==(Object other) => other is Money && other.rupiah == rupiah;

  @override
  int get hashCode => rupiah.hashCode;

  @override
  String toString() => format();
}

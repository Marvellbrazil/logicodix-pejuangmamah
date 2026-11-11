class Money implements Comparable<Money> {
  const Money(this.rupiah);

  static const zero = Money(0);

  final int rupiah;

  Money operator +(Money other) => Money(rupiah + other.rupiah);

  Money operator *(int factor) => Money(rupiah * factor);

  String format() {
    final digits = rupiah.abs().toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
      grouped.write(digits[i]);
    }
    return '${rupiah < 0 ? '-' : ''}Rp $grouped';
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

class Tokens {
  final String access;
  final String refresh;

  const Tokens({required this.access, required this.refresh});

  bool get isValid => access.isNotEmpty && refresh.isNotEmpty;
}

class TtlCache<T> {
  T? _value;
  DateTime? _lastFetch;
  final Duration _ttl;

  TtlCache({int ttlMinutes = 5}) : _ttl = Duration(minutes: ttlMinutes);

  bool get isFresh =>
      _value != null &&
      _lastFetch != null &&
      DateTime.now().difference(_lastFetch!).inMinutes < _ttl.inMinutes;

  T? get value => isFresh ? _value : null;

  void set(T value) {
    _value = value;
    _lastFetch = DateTime.now();
  }

  void invalidate() {
    _value = null;
    _lastFetch = null;
  }
}

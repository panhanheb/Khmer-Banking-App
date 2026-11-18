/// Generic async status used by feature states.
enum LoadStatus { initial, loading, success, failure }

extension LoadStatusX on LoadStatus {
  bool get isLoading => this == LoadStatus.loading;
  bool get isSuccess => this == LoadStatus.success;
  bool get isFailure => this == LoadStatus.failure;
}

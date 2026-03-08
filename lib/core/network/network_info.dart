import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';


abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}

@LazySingleton(as: NetworkInfo)
class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    // ignore: unrelated_type_equality_checks
    return result != ConnectivityResult.none;
  }
}

// Note: The [NetworkInfo] interface and its implementation are used to check the network connectivity status of the device. The [isConnected] getter returns a Future that resolves to true if the device is connected to the internet, and false otherwise. The implementation uses the [connectivity_plus] package to check the connectivity status.
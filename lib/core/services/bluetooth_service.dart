import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:audira_receipt/models/thermal_printer.dart';

enum BluetoothConnState {
  disconnected,
  connecting,
  connected,
}

class BluetoothService extends ChangeNotifier {
  BluetoothConnState _connectionState = BluetoothConnState.disconnected;
  ThermalPrinter? _connectedPrinter;
  List<ThermalPrinter> _availableDevices = [];
  bool _isScanning = false;
  String _lastErrorMessage = '';

  BluetoothConnState get connectionState => _connectionState;
  ThermalPrinter? get connectedPrinter => _connectedPrinter;
  List<ThermalPrinter> get availableDevices => _availableDevices;
  bool get isScanning => _isScanning;
  String get lastErrorMessage => _lastErrorMessage;
  bool get isConnected => _connectionState == BluetoothConnState.connected;

  BluetoothService() {
    _initLister();
  }

  void _initLister() {
    // Periodically verify connection status if supposedly connected
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_connectionState == BluetoothConnState.connected && _connectedPrinter != null) {
        final status = await checkActualConnection();
        if (!status && _connectionState == BluetoothConnState.connected) {
          _connectionState = BluetoothConnState.disconnected;
          notifyListeners();
        }
      }
    });
  }

  /// Request Bluetooth & Location permissions for Android
  Future<bool> requestPermissions() async {
    if (!kIsWeb && Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? true;
      final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? true;
      final locationGranted = statuses[Permission.locationWhenInUse]?.isGranted ?? true;

      // Also check plugin permission helper
      try {
        final pluginPerm = await PrintBluetoothThermal.isPermissionBluetoothGranted;
        if (!pluginPerm) {
          debugPrint('Bluetooth permission reported false by plugin');
        }
      } catch (e) {
        debugPrint('Plugin permission check exception: $e');
      }

      return (scanGranted && connectGranted) || locationGranted;
    }
    return true;
  }

  /// Check if Bluetooth is turned ON on the device
  Future<bool> isBluetoothEnabled() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        return await PrintBluetoothThermal.bluetoothEnabled;
      }
      return true;
    } catch (e) {
      debugPrint('Error checking bluetooth enabled: $e');
      return true; // allow testing on other platforms
    }
  }

  /// Scan for paired Bluetooth thermal printers
  Future<List<ThermalPrinter>> scanPrinters() async {
    _isScanning = true;
    _lastErrorMessage = '';
    notifyListeners();

    try {
      final permOk = await requestPermissions();
      if (!permOk) {
        _lastErrorMessage = 'Izin Bluetooth belum diberikan';
        _isScanning = false;
        notifyListeners();
        return [];
      }

      final enabled = await isBluetoothEnabled();
      if (!enabled) {
        _lastErrorMessage = 'Bluetooth belum diaktifkan';
        _isScanning = false;
        notifyListeners();
        return [];
      }

      if (!kIsWeb && Platform.isAndroid) {
        final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;
        _availableDevices = list.map((info) {
          final isCurrConnected = _connectedPrinter != null &&
              _connectedPrinter!.macAddress == info.macAdress &&
              _connectionState == BluetoothConnState.connected;
          return ThermalPrinter(
            name: info.name.isNotEmpty ? info.name : 'Unknown Printer',
            macAddress: info.macAdress,
            isConnected: isCurrConnected,
          );
        }).toList();
      } else {
        // Fallback demo mock devices for desktop / emulator / web
        await Future.delayed(const Duration(milliseconds: 600));
        _availableDevices = [
          ThermalPrinter(
            name: 'AUDIRA XP-58 (Demo)',
            macAddress: '66:22:33:44:55:66',
            paperSize: '58mm',
          ),
          ThermalPrinter(
            name: 'EPSON TM-T88VI (Demo)',
            macAddress: '11:22:33:AA:BB:CC',
            paperSize: '80mm',
          ),
          ThermalPrinter(
            name: 'RPP-02N Bluetooth (Demo)',
            macAddress: '88:99:AA:BB:CC:DD',
            paperSize: '58mm',
          ),
        ];
      }
    } catch (e) {
      _lastErrorMessage = 'Gagal memindai printer: $e';
      debugPrint('Scan error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }

    return _availableDevices;
  }

  /// Connect to a thermal printer by MAC Address
  Future<bool> connect(ThermalPrinter printer) async {
    _connectionState = BluetoothConnState.connecting;
    _lastErrorMessage = '';
    notifyListeners();

    try {
      final enabled = await isBluetoothEnabled();
      if (!enabled) {
        _lastErrorMessage = 'Bluetooth tidak aktif. Silakan aktifkan Bluetooth.';
        _connectionState = BluetoothConnState.disconnected;
        notifyListeners();
        return false;
      }

      bool success = false;
      if (!kIsWeb && Platform.isAndroid) {
        // First disconnect any previous connection
        await PrintBluetoothThermal.disconnect;
        success = await PrintBluetoothThermal.connect(macPrinterAddress: printer.macAddress);
      } else {
        // Mock connection for testing / desktop
        await Future.delayed(const Duration(milliseconds: 700));
        success = true;
      }

      if (success) {
        _connectionState = BluetoothConnState.connected;
        _connectedPrinter = printer.copyWith(isConnected: true);
        _lastErrorMessage = '';
      } else {
        _connectionState = BluetoothConnState.disconnected;
        _lastErrorMessage = 'Gagal menyambung ke ${printer.name}. Pastikan printer menyala dan dekat.';
      }
    } catch (e) {
      _connectionState = BluetoothConnState.disconnected;
      _lastErrorMessage = 'Koneksi error: $e';
    } finally {
      notifyListeners();
    }

    return _connectionState == BluetoothConnState.connected;
  }

  /// Disconnect current printer
  Future<bool> disconnect() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await PrintBluetoothThermal.disconnect;
      }
      _connectionState = BluetoothConnState.disconnected;
      if (_connectedPrinter != null) {
        _connectedPrinter = _connectedPrinter!.copyWith(isConnected: false);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Disconnect error: $e');
      return false;
    }
  }

  /// Check actual hardware connection
  Future<bool> checkActualConnection() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        return await PrintBluetoothThermal.connectionStatus;
      }
      return _connectionState == BluetoothConnState.connected;
    } catch (e) {
      return false;
    }
  }

  /// Send raw bytes to connected Bluetooth printer
  Future<bool> sendBytes(Uint8List bytes) async {
    if (_connectionState != BluetoothConnState.connected) {
      _lastErrorMessage = 'Printer tidak terhubung';
      notifyListeners();
      return false;
    }

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final result = await PrintBluetoothThermal.writeBytes(bytes);
        return result;
      } else {
        // Mock output success
        debugPrint('Mock Print: Sent ${bytes.length} bytes to thermal printer');
        return true;
      }
    } catch (e) {
      _lastErrorMessage = 'Gagal mengirim data cetak: $e';
      notifyListeners();
      return false;
    }
  }

  /// Force set printer state (e.g. for testing / restored state)
  void setConnectedPrinter(ThermalPrinter? printer) {
    _connectedPrinter = printer;
    _connectionState = printer != null ? BluetoothConnState.connected : BluetoothConnState.disconnected;
    notifyListeners();
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:audira_receipt/models/thermal_printer.dart';

enum BluetoothConnState {
  disconnected,
  connecting,
  connected,
}

class BluetoothService extends ChangeNotifier {
  static const MethodChannel _nativeChannel = MethodChannel('com.audira.receipt/bluetooth');

  BluetoothConnState _connectionState = BluetoothConnState.disconnected;
  ThermalPrinter? _connectedPrinter;
  List<ThermalPrinter> _availableDevices = [];
  List<ThermalPrinter> _pairedDevices = [];
  List<ThermalPrinter> _discoveredDevices = [];
  bool _isScanning = false;
  String _lastErrorMessage = '';

  BluetoothConnState get connectionState => _connectionState;
  ThermalPrinter? get connectedPrinter => _connectedPrinter;
  List<ThermalPrinter> get availableDevices => _availableDevices;
  List<ThermalPrinter> get pairedDevices => _pairedDevices;
  List<ThermalPrinter> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;
  String get lastErrorMessage => _lastErrorMessage;
  bool get isConnected => _connectionState == BluetoothConnState.connected && _connectedPrinter != null;

  BluetoothService() {
    _initListener();
    _initNativeChannel();
  }

  void _initNativeChannel() {
    if (!kIsWeb && Platform.isAndroid) {
      _nativeChannel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onDeviceDiscovered':
            final map = Map<String, dynamic>.from(call.arguments as Map);
            final name = map['name'] as String? ?? 'Perangkat Bluetooth';
            final address = map['address'] as String? ?? '';
            final isBonded = map['isBonded'] as bool? ?? false;

            if (address.isNotEmpty) {
              _addDiscoveredDevice(name: name, address: address, isBonded: isBonded);
            }
            break;

          case 'onDiscoveryFinished':
            _isScanning = false;
            notifyListeners();
            break;

          case 'onBondStateChanged':
            final map = Map<String, dynamic>.from(call.arguments as Map);
            final address = map['address'] as String? ?? '';
            final isBonded = map['isBonded'] as bool? ?? false;

            if (address.isNotEmpty && isBonded) {
              // Move from discovered to paired
              final idx = _discoveredDevices.indexWhere((p) => p.macAddress == address);
              if (idx != -1) {
                final printer = _discoveredDevices[idx].copyWith(isBonded: true);
                _discoveredDevices.removeAt(idx);
                if (!_pairedDevices.any((p) => p.macAddress == address)) {
                  _pairedDevices.add(printer);
                }
              }
              _updateAvailableList();
            }
            break;
        }
      });
    }
  }

  void _addDiscoveredDevice({required String name, required String address, required bool isBonded}) {
    // Avoid duplicates
    if (_pairedDevices.any((p) => p.macAddress == address)) return;
    final existingIdx = _discoveredDevices.indexWhere((p) => p.macAddress == address);

    final newPrinter = ThermalPrinter(
      name: name.isNotEmpty ? name : 'Bluetooth Printer ($address)',
      macAddress: address,
      isBonded: isBonded,
      isConnected: _connectedPrinter?.macAddress == address && _connectionState == BluetoothConnState.connected,
    );

    if (existingIdx != -1) {
      _discoveredDevices[existingIdx] = newPrinter;
    } else {
      _discoveredDevices.add(newPrinter);
    }
    _updateAvailableList();
  }

  void _updateAvailableList() {
    final Map<String, ThermalPrinter> merged = {};
    for (final p in _pairedDevices) {
      merged[p.macAddress] = p;
    }
    for (final p in _discoveredDevices) {
      if (!merged.containsKey(p.macAddress)) {
        merged[p.macAddress] = p;
      }
    }
    _availableDevices = merged.values.toList();
    notifyListeners();
  }

  void _initListener() {
    // Periodically verify hardware connection status if supposedly connected
    Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_connectionState == BluetoothConnState.connected && _connectedPrinter != null) {
        final status = await checkActualConnection();
        if (!status && _connectionState == BluetoothConnState.connected) {
          _connectionState = BluetoothConnState.disconnected;
          _connectedPrinter = null;
          notifyListeners();
        }
      }
    });
  }

  /// Request Bluetooth & Location permissions for Android
  Future<bool> requestPermissions() async {
    if (!kIsWeb && Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
      final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;

      if (scanGranted && connectGranted) {
        // Also request location for discovery of unbonded devices on some devices
        await Permission.locationWhenInUse.request();
        return true;
      }

      final locationStatus = await Permission.locationWhenInUse.request();
      final locationGranted = locationStatus.isGranted;

      try {
        final pluginPerm = await PrintBluetoothThermal.isPermissionBluetoothGranted;
        if (!pluginPerm) {
          debugPrint('Bluetooth permission reported false by plugin');
        }
      } catch (e) {
        debugPrint('Plugin permission check exception: $e');
      }

      return locationGranted || (scanGranted && connectGranted);
    }
    return true;
  }

  /// Check if Bluetooth is turned ON on the device
  Future<bool> isBluetoothEnabled() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final bool enabledNative = await _nativeChannel.invokeMethod('isBluetoothEnabled') ?? false;
        final bool enabledPlugin = await PrintBluetoothThermal.bluetoothEnabled;
        return enabledNative || enabledPlugin;
      }
      return true;
    } catch (e) {
      debugPrint('Error checking bluetooth enabled: $e');
      return true;
    }
  }

  /// Automatically prompt to activate Bluetooth if turned off
  Future<bool> enableBluetooth() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final bool? res = await _nativeChannel.invokeMethod('enableBluetooth');
        await Future.delayed(const Duration(milliseconds: 600));
        return res ?? await isBluetoothEnabled();
      }
      return true;
    } catch (e) {
      debugPrint('Error enabling bluetooth: $e');
      return false;
    }
  }

  /// Open phone's Bluetooth system settings screen
  Future<void> openBluetoothSettings() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _nativeChannel.invokeMethod('openBluetoothSettings');
      }
    } catch (e) {
      debugPrint('Error opening bluetooth settings: $e');
    }
  }

  /// Pair / Bond an unpaired Bluetooth device
  Future<bool> pairDevice(ThermalPrinter printer) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final bool? res = await _nativeChannel.invokeMethod('pairDevice', {
          'address': printer.macAddress,
        });
        return res ?? false;
      }
      return true;
    } catch (e) {
      _lastErrorMessage = 'Gagal memasangkan perangkat: $e';
      notifyListeners();
      return false;
    }
  }

  /// Stop ongoing Bluetooth discovery
  Future<void> stopScan() async {
    if (!_isScanning) return;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _nativeChannel.invokeMethod('stopDiscovery');
      }
    } catch (_) {}
    _isScanning = false;
    notifyListeners();
  }

  /// Scan for BOTH paired and newly discovered Bluetooth thermal printers
  Future<List<ThermalPrinter>> scanPrinters() async {
    _isScanning = true;
    _lastErrorMessage = '';
    _discoveredDevices = [];
    notifyListeners();

    try {
      final permOk = await requestPermissions();
      if (!permOk) {
        _lastErrorMessage = 'Izin Bluetooth belum diberikan';
        _isScanning = false;
        notifyListeners();
        return [];
      }

      // Check Bluetooth enabled, try auto enabling if disabled
      var enabled = await isBluetoothEnabled();
      if (!enabled) {
        await enableBluetooth();
        await Future.delayed(const Duration(milliseconds: 600));
        enabled = await isBluetoothEnabled();
      }

      if (!enabled) {
        _lastErrorMessage = 'Bluetooth belum diaktifkan. Silakan aktifkan Bluetooth.';
        _isScanning = false;
        notifyListeners();
        return [];
      }

      if (!kIsWeb && Platform.isAndroid) {
        // 1. Fetch bonded / paired devices
        final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;
        _pairedDevices = list.map((info) {
          final isCurrConnected = _connectedPrinter != null &&
              _connectedPrinter!.macAddress == info.macAdress &&
              _connectionState == BluetoothConnState.connected;
          return ThermalPrinter(
            name: info.name.isNotEmpty ? info.name : 'Printer Bluetooth',
            macAddress: info.macAdress,
            isConnected: isCurrConnected,
            isBonded: true,
          );
        }).toList();

        _updateAvailableList();

        // 2. Start native discovery for unbonded / new Bluetooth printers
        try {
          await _nativeChannel.invokeMethod('startDiscovery');
        } catch (e) {
          debugPrint('Discovery start error: $e');
        }

        // Keep scanning indicator alive for a reasonable window
        Timer(const Duration(seconds: 12), () {
          if (_isScanning) {
            stopScan();
          }
        });


      } else {
        // Fallback demo mock devices for desktop / emulator / web
        await Future.delayed(const Duration(milliseconds: 500));
        _pairedDevices = [
          ThermalPrinter(
            name: 'AUDIRA XP-58 (Demo)',
            macAddress: '66:22:33:44:55:66',
            paperSize: '58mm',
            isBonded: true,
          ),
          ThermalPrinter(
            name: 'EPSON TM-T88VI (Demo)',
            macAddress: '11:22:33:AA:BB:CC',
            paperSize: '80mm',
            isBonded: true,
          ),
        ];
        _discoveredDevices = [
          ThermalPrinter(
            name: 'RPP-02N Bluetooth Baru',
            macAddress: '88:99:AA:BB:CC:DD',
            paperSize: '58mm',
            isBonded: false,
          ),
          ThermalPrinter(
            name: 'POS-5802DD Portable',
            macAddress: '77:88:99:AA:BB:CC',
            paperSize: '58mm',
            isBonded: false,
          ),
        ];
        _updateAvailableList();
      }
    } catch (e) {
      _lastErrorMessage = 'Gagal memindai printer: $e';
      debugPrint('Scan error: $e');
    }

    return _availableDevices;
  }

  /// Connect to a thermal printer by MAC Address
  Future<bool> connect(ThermalPrinter printer) async {
    _connectionState = BluetoothConnState.connecting;
    _lastErrorMessage = '';
    notifyListeners();

    try {
      var enabled = await isBluetoothEnabled();
      if (!enabled) {
        await enableBluetooth();
        await Future.delayed(const Duration(milliseconds: 600));
        enabled = await isBluetoothEnabled();
      }

      if (!enabled) {
        _lastErrorMessage = 'Bluetooth tidak aktif. Silakan aktifkan Bluetooth.';
        _connectionState = BluetoothConnState.disconnected;
        notifyListeners();
        return false;
      }

      // Stop discovery before connecting to guarantee stable RFCOMM socket
      await stopScan();

      // If device is not yet bonded, request pairing first
      if (!printer.isBonded && !printer.name.contains('(Demo)')) {
        await pairDevice(printer);
        await Future.delayed(const Duration(milliseconds: 1200));
      }

      bool success = false;
      if (printer.name.contains('(Demo)')) {
        await Future.delayed(const Duration(milliseconds: 600));
        success = true;
      } else if (!kIsWeb && Platform.isAndroid) {
        // Disconnect any existing socket first
        await PrintBluetoothThermal.disconnect;
        await Future.delayed(const Duration(milliseconds: 250));

        // Connect RFCOMM socket
        success = await PrintBluetoothThermal.connect(macPrinterAddress: printer.macAddress);

        // Verify socket
        if (success) {
          final actual = await PrintBluetoothThermal.connectionStatus;
          success = actual;
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        success = true;
      }

      if (success) {
        _connectionState = BluetoothConnState.connected;
        _connectedPrinter = printer.copyWith(isConnected: true, isBonded: true);
        _lastErrorMessage = '';
      } else {
        _connectionState = BluetoothConnState.disconnected;
        _connectedPrinter = null;
        _lastErrorMessage = 'Gagal menyambung ke ${printer.name} (${printer.macAddress}). Pastikan printer menyala, lampu biru/hijau aktif, dan dalam jangkauan dekat.';
      }
    } catch (e) {
      _connectionState = BluetoothConnState.disconnected;
      _connectedPrinter = null;
      _lastErrorMessage = 'Koneksi error: $e';
    } finally {
      notifyListeners();
    }

    return _connectionState == BluetoothConnState.connected;
  }

  /// Reconnect to the last known or currently assigned printer
  Future<bool> reconnect([ThermalPrinter? targetPrinter]) async {
    final printer = targetPrinter ?? _connectedPrinter;
    if (printer == null) {
      _lastErrorMessage = 'Tidak ada printer yang dipilih untuk dihubungkan ulang.';
      return false;
    }
    return await connect(printer);
  }

  /// Disconnect current printer - REAL DISCONNECT
  Future<bool> disconnect() async {
    try {
      await stopScan();
      if (!kIsWeb && Platform.isAndroid) {
        await PrintBluetoothThermal.disconnect;
      }
      _connectionState = BluetoothConnState.disconnected;
      _connectedPrinter = null; // Cleared completely so UI state is clean and real!
      _lastErrorMessage = '';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Disconnect error: $e');
      _connectionState = BluetoothConnState.disconnected;
      _connectedPrinter = null;
      notifyListeners();
      return false;
    }
  }

  /// Check actual hardware connection
  Future<bool> checkActualConnection() async {
    try {
      if (_connectedPrinter?.name.contains('(Demo)') == true) {
        return _connectionState == BluetoothConnState.connected;
      }
      if (!kIsWeb && Platform.isAndroid) {
        final actual = await PrintBluetoothThermal.connectionStatus;
        if (!actual && _connectionState == BluetoothConnState.connected) {
          _connectionState = BluetoothConnState.disconnected;
          _connectedPrinter = null;
          notifyListeners();
        }
        return actual;
      }
      return _connectionState == BluetoothConnState.connected;
    } catch (e) {
      return false;
    }
  }

  /// Send raw bytes to connected Bluetooth printer
  Future<bool> sendBytes(Uint8List bytes) async {
    if (_connectionState != BluetoothConnState.connected || _connectedPrinter == null) {
      _lastErrorMessage = 'Printer belum terhubung. Silakan pilih dan sambungkan printer.';
      notifyListeners();
      return false;
    }

    try {
      if (_connectedPrinter?.name.contains('(Demo)') == true) {
        await Future.delayed(const Duration(milliseconds: 300));
        debugPrint('Demo Print: Sent ${bytes.length} bytes to ${_connectedPrinter?.name}');
        return true;
      } else if (!kIsWeb && Platform.isAndroid) {
        // 1. Verify socket is still active
        final isAlive = await PrintBluetoothThermal.connectionStatus;
        if (!isAlive) {
          // Attempt automatic socket revival
          debugPrint('Socket lost, attempting auto-reconnect before writeBytes...');
          final reconnected = await connect(_connectedPrinter!);
          if (!reconnected) {
            _lastErrorMessage = 'Koneksi ke ${_connectedPrinter?.name} terputus (socket RFCOMM tertutup). Printer mungkin mati, kehabisan baterai, atau di luar jangkauan.';
            notifyListeners();
            return false;
          }
        }

        final result = await PrintBluetoothThermal.writeBytes(bytes);
        if (!result) {
          _lastErrorMessage = 'Printer tidak merespons perintah cetak (${bytes.length} bytes). Pastikan kertas printer terpasang dengan benar dan penutup tertutup rapat.';
          notifyListeners();
        }
        return result;
      } else {
        // Mock output success for desktop/testing
        debugPrint('Mock Print: Sent ${bytes.length} bytes to ${_connectedPrinter?.name}');
        return true;
      }
    } catch (e) {
      _lastErrorMessage = 'Gagal mengirim data cetak ke ${_connectedPrinter?.name}: $e';
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

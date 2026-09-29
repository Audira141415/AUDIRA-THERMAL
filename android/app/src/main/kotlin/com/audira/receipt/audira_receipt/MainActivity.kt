package com.audira.receipt.audira_receipt

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.audira.receipt/bluetooth"
    private var methodChannel: MethodChannel? = null
    private var isReceiverRegistered = false
    private val mainHandler = Handler(Looper.getMainLooper())

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            when (action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    }

                    if (device != null) {
                        val name = try {
                            device.name ?: "Perangkat Bluetooth"
                        } catch (e: SecurityException) {
                            "Perangkat Bluetooth"
                        }
                        val address = device.address ?: ""
                        val isBonded = try {
                            device.bondState == BluetoothDevice.BOND_BONDED
                        } catch (e: SecurityException) {
                            false
                        }
                        val deviceType = try {
                            device.bluetoothClass?.majorDeviceClass ?: 0
                        } catch (e: SecurityException) {
                            0
                        }

                        mainHandler.post {
                            methodChannel?.invokeMethod("onDeviceDiscovered", mapOf(
                                "name" to name,
                                "address" to address,
                                "isBonded" to isBonded,
                                "type" to deviceType
                            ))
                        }
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    mainHandler.post {
                        methodChannel?.invokeMethod("onDiscoveryFinished", null)
                    }
                }
                BluetoothDevice.ACTION_BOND_STATE_CHANGED -> {
                    val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    }
                    val bondState = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.BOND_NONE)
                    val address = device?.address ?: ""
                    val name = try { device?.name ?: "" } catch (_: SecurityException) { "" }

                    mainHandler.post {
                        methodChannel?.invokeMethod("onBondStateChanged", mapOf(
                            "name" to name,
                            "address" to address,
                            "bondState" to bondState, // 10: NONE, 11: BONDING, 12: BONDED
                            "isBonded" to (bondState == BluetoothDevice.BOND_BONDED)
                        ))
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothEnabled" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    result.success(adapter?.isEnabled == true)
                }
                "enableBluetooth" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    if (adapter == null) {
                        result.error("NO_BLUETOOTH", "Perangkat tidak memiliki hardware Bluetooth", null)
                        return@setMethodCallHandler
                    }
                    if (adapter.isEnabled) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    try {
                        // Launch system prompt to enable Bluetooth
                        val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(enableBtIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            @Suppress("DEPRECATION")
                            val enabled = adapter.enable()
                            result.success(enabled)
                        } catch (se: SecurityException) {
                            result.error("PERMISSION_DENIED", se.message, null)
                        }
                    }
                }
                "openBluetoothSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("FAILED", "Tidak dapat membuka pengaturan Bluetooth: ${e.message}", null)
                    }
                }
                "startDiscovery" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    if (adapter == null || !adapter.isEnabled) {
                        result.error("BT_OFF", "Bluetooth belum aktif", null)
                        return@setMethodCallHandler
                    }

                    try {
                        // Register receiver if not yet registered
                        if (!isReceiverRegistered) {
                            val filter = IntentFilter().apply {
                                addAction(BluetoothDevice.ACTION_FOUND)
                                addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
                                addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
                            }
                            registerReceiver(bluetoothReceiver, filter)
                            isReceiverRegistered = true
                        }

                        if (adapter.isDiscovering) {
                            adapter.cancelDiscovery()
                        }
                        val started = adapter.startDiscovery()
                        result.success(started)
                    } catch (e: SecurityException) {
                        result.error("PERMISSION_DENIED", "Izin scan Bluetooth belum diberikan: ${e.message}", null)
                    } catch (e: Exception) {
                        result.error("ERROR", "Gagal memulai discovery: ${e.message}", null)
                    }
                }
                "stopDiscovery" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    try {
                        if (adapter?.isDiscovering == true) {
                            adapter.cancelDiscovery()
                        }
                        unregisterDiscoveryReceiver()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "pairDevice" -> {
                    val address = call.argument<String>("address")
                    if (address.isNullOrEmpty()) {
                        result.error("INVALID_ARG", "Alamat MAC Bluetooth tidak boleh kosong", null)
                        return@setMethodCallHandler
                    }

                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    if (adapter == null) {
                        result.error("NO_BT", "Bluetooth tidak tersedia", null)
                        return@setMethodCallHandler
                    }

                    try {
                        if (adapter.isDiscovering) {
                            adapter.cancelDiscovery()
                        }
                        val device = adapter.getRemoteDevice(address)
                        if (device.bondState == BluetoothDevice.BOND_BONDED) {
                            result.success(true)
                        } else {
                            val bonded = device.createBond()
                            result.success(bonded)
                        }
                    } catch (e: SecurityException) {
                        result.error("PERMISSION_DENIED", "Izin pairing Bluetooth belum diberikan: ${e.message}", null)
                    } catch (e: Exception) {
                        result.error("ERROR", "Gagal pairing ke perangkat: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun unregisterDiscoveryReceiver() {
        if (isReceiverRegistered) {
            try {
                unregisterReceiver(bluetoothReceiver)
            } catch (_: Exception) {}
            isReceiverRegistered = false
        }
    }

    override fun onDestroy() {
        unregisterDiscoveryReceiver()
        super.onDestroy()
    }
}

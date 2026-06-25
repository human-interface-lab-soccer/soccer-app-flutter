package jp.ac.saitama_u.mech.human.soccerAppFlutter

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth.GeneralBleScanner
import jp.ac.saitama_u.mech.human.soccerAppFlutter.flutterchannels.FlutterChannelManager

class MainActivity : FlutterActivity() {

    companion object {
        private const val REQUEST_BLUETOOTH_PERMISSION = 1001
    }

    private lateinit var bleScanner: GeneralBleScanner
    private lateinit var flutterChannelManager: FlutterChannelManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        requestBluetoothPermissions()

        bleScanner = GeneralBleScanner(this)

        flutterChannelManager = FlutterChannelManager(
            messenger = flutterEngine.dartExecutor.binaryMessenger,
            bleScanner = bleScanner
        )

        flutterChannelManager.setupChannels()
    }

    /**
     * Bluetooth権限を要求
     */
    private fun requestBluetoothPermissions() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {

            val permissions = mutableListOf<String>()

            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH_SCAN
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            }

            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
            }

            if (permissions.isNotEmpty()) {
                ActivityCompat.requestPermissions(
                    this,
                    permissions.toTypedArray(),
                    REQUEST_BLUETOOTH_PERMISSION
                )
            }

        } else {

            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                    REQUEST_BLUETOOTH_PERMISSION
                )
            }
        }
    }
}
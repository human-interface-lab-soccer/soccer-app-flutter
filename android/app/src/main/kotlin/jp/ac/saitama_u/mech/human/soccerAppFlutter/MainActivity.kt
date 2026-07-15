package jp.ac.saitama_u.mech.human.soccerAppFlutter

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth.GeneralBleScanner
import jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth.ProvisioningService
import jp.ac.saitama_u.mech.human.soccerAppFlutter.flutterchannels.FlutterChannelManager
import jp.ac.saitama_u.mech.human.soccerAppFlutter.flutterchannels.ProvisioningEventStreamHandler
import no.nordicsemi.android.mesh.MeshManagerApi

/**
 * Android Native層の初期化を担当するActivity。
 *
 * iOS版AppDelegate.swiftに近い役割を持ち、
 * 各クラスを生成して依存関係を接続する。
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val REQUEST_BLUETOOTH_PERMISSIONS = 1001
    }

    /**
     * Nordic Mesh SDKの中心となる管理クラス。
     *
     * アプリ内で同一インスタンスを共有する。
     */
    private lateinit var meshManagerApi: MeshManagerApi

    /**
     * 未Provisioningデバイスのスキャン担当。
     */
    private lateinit var bleScanner: GeneralBleScanner

    /**
     * Provisioning進捗をFlutterへ送る担当。
     */
    private lateinit var provisioningEventStreamHandler:
        ProvisioningEventStreamHandler

    /**
     * Provisioning全体の進行管理担当。
     */
    private lateinit var provisioningService:
        ProvisioningService

    /**
     * Flutterから届いた命令の振り分け担当。
     */
    private lateinit var flutterChannelManager:
        FlutterChannelManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        requestBluetoothPermissions()
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        initializeNativeComponents()
        setupFlutterChannels(flutterEngine)
    }

    /**
     * Android Native層で使うクラスを生成する。
     *
     * 生成順:
     * 1. MeshManagerApi
     * 2. GeneralBleScanner
     * 3. ProvisioningEventStreamHandler
     * 4. ProvisioningService
     */
    private fun initializeNativeComponents() {
        meshManagerApi =
            MeshManagerApi(applicationContext)

        bleScanner =
            GeneralBleScanner(applicationContext)

        provisioningEventStreamHandler =
            ProvisioningEventStreamHandler()

        provisioningService =
            ProvisioningService(
                context = applicationContext,
                meshManagerApi = meshManagerApi,
                bleScanner = bleScanner,
                eventHandler =
                    provisioningEventStreamHandler
            )
    }

    /**
     * FlutterとAndroid Native層のPlatform Channelを設定する。
     */
    private fun setupFlutterChannels(
        flutterEngine: FlutterEngine
    ) {
        flutterChannelManager =
            FlutterChannelManager(
                messenger =
                    flutterEngine
                        .dartExecutor
                        .binaryMessenger,
                bleScanner = bleScanner,
                provisioningService =
                    provisioningService,
                provisioningEventStreamHandler =
                    provisioningEventStreamHandler
            )

        flutterChannelManager.setupChannels()
    }

    /**
     * Androidバージョンに応じて、
     * 必要なBluetooth実行時権限を要求する。
     */
    private fun requestBluetoothPermissions() {
        val requiredPermissions =
            mutableListOf<String>()

        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.S
        ) {
            if (
                !hasPermission(
                    Manifest.permission.BLUETOOTH_SCAN
                )
            ) {
                requiredPermissions.add(
                    Manifest.permission.BLUETOOTH_SCAN
                )
            }

            if (
                !hasPermission(
                    Manifest.permission.BLUETOOTH_CONNECT
                )
            ) {
                requiredPermissions.add(
                    Manifest.permission.BLUETOOTH_CONNECT
                )
            }
        } else {
            if (
                !hasPermission(
                    Manifest.permission.ACCESS_FINE_LOCATION
                )
            ) {
                requiredPermissions.add(
                    Manifest.permission.ACCESS_FINE_LOCATION
                )
            }
        }

        if (requiredPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                requiredPermissions.toTypedArray(),
                REQUEST_BLUETOOTH_PERMISSIONS
            )
        }
    }

    private fun hasPermission(
        permission: String
    ): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Activity破棄時にスキャンとGATT接続を終了する。
     */
    override fun onDestroy() {
        if (::bleScanner.isInitialized) {
            bleScanner.stopScan()
        }

        if (::provisioningService.isInitialized) {
            provisioningService.close()
        }

        super.onDestroy()
    }
}
package top.myneri.insectidentifier

import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var backgroundYoloChannel: BackgroundYoloChannel? = null

    private val prefs by lazy {
        getSharedPreferences("launcher_icon", Context.MODE_PRIVATE)
    }

    override fun onPause() {
        super.onPause()
        applyPendingLauncherIcon()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        backgroundYoloChannel?.dispose()
        backgroundYoloChannel =
            BackgroundYoloChannel(flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LAUNCHER_ICON_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleLauncherIcon" -> {
                    val alias = call.argument<String>("alias")
                    if (alias == null) {
                        result.error("invalid_alias", "Missing alias", null)
                    } else {
                        prefs.edit().putString(KEY_PENDING_ALIAS, alias).apply()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        backgroundYoloChannel?.dispose()
        backgroundYoloChannel = null
        super.onDestroy()
    }

    private fun applyPendingLauncherIcon() {
        val alias = prefs.getString(KEY_PENDING_ALIAS, null) ?: return
        if (setLauncherIcon(alias)) {
            prefs.edit().remove(KEY_PENDING_ALIAS).apply()
        }
    }

    private fun setLauncherIcon(alias: String): Boolean {
        val targetAlias = LAUNCHER_ALIASES[alias] ?: return false
        return try {
            packageManager.setComponentEnabledSetting(
                ComponentName(this, "$packageName.$targetAlias"),
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )
            LAUNCHER_ALIASES.values.filterNot { it == targetAlias }.forEach {
                packageManager.setComponentEnabledSetting(
                    ComponentName(this, "$packageName.$it"),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP,
                )
            }
            true
        } catch (_: IllegalArgumentException) {
            false
        }
    }

    companion object {
        private const val LAUNCHER_ICON_CHANNEL =
            "top.myneri.insectidentifier/launcher_icon"
        private const val KEY_PENDING_ALIAS = "pending_alias"

        private val LAUNCHER_ALIASES = mapOf(
            "green" to "LauncherGreen",
            "teal" to "LauncherTeal",
            "blue" to "LauncherBlue",
            "purple" to "LauncherPurple",
            "rose" to "LauncherRose",
            "orange" to "LauncherOrange",
            "cyan" to "LauncherCyan",
            "gold" to "LauncherGold",
            "dynamic" to "LauncherDynamic",
        )
    }
}

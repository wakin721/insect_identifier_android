package top.myneri.insectidentifier

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LAUNCHER_ICON_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "setLauncherIcon") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val alias = call.argument<String>("alias")
            if (alias == null) {
                result.error("invalid_alias", "Launcher icon alias is missing.", null)
                return@setMethodCallHandler
            }

            if (setLauncherIcon(alias)) {
                result.success(null)
            } else {
                result.error(
                    "invalid_alias",
                    "Unknown or unavailable launcher icon alias: $alias",
                    null,
                )
            }
        }
    }

    private fun setLauncherIcon(alias: String): Boolean {
        val targetAlias = LAUNCHER_ALIASES[alias] ?: return false
        val targetComponent = ComponentName(this, "$packageName.$targetAlias")

        return try {
            packageManager.setComponentEnabledSetting(
                targetComponent,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )

            LAUNCHER_ALIASES.values
                .filterNot { it == targetAlias }
                .forEach { componentAlias ->
                    packageManager.setComponentEnabledSetting(
                        ComponentName(this, "$packageName.$componentAlias"),
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

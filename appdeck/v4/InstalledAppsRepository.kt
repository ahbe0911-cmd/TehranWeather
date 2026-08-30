package ir.appdeck.launcher.data

import android.content.Context
import android.content.Intent
import ir.appdeck.launcher.model.InstalledApp
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/**
 * Launcher app discovery is intentionally cached on disk. PackageManager scans can be
 * surprisingly expensive on phones with many apps, so normal startup uses the last
 * catalog instantly and only a manual refresh forces a new scan.
 */
class InstalledAppsRepository(private val context: Context) {
    private val prefs = context.getSharedPreferences("appdeck_app_catalog", Context.MODE_PRIVATE)

    fun loadLauncherApps(forceRefresh: Boolean = false): List<InstalledApp> {
        if (!forceRefresh) {
            processCache?.let { return it }
            readDiskCache()?.takeIf { it.isNotEmpty() }?.let {
                processCache = it
                return it
            }
        }

        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val apps = context.packageManager
            .queryIntentActivities(intent, 0)
            .asSequence()
            .map { info ->
                val packageName = info.activityInfo.packageName
                val label = info.loadLabel(context.packageManager)?.toString().orEmpty()
                    .ifBlank { packageName }
                InstalledApp(
                    packageName = packageName,
                    label = label,
                    searchText = normalizeForSearch("$label $packageName")
                )
            }
            .filterNot { it.packageName == context.packageName }
            .distinctBy { it.packageName }
            .sortedBy { normalizeForSearch(it.label) }
            .toList()

        processCache = apps
        writeDiskCache(apps)
        return apps
    }

    private fun readDiskCache(): List<InstalledApp>? = runCatching {
        val raw = prefs.getString(KEY_CATALOG, null) ?: return@runCatching emptyList<InstalledApp>()
        if (raw.isBlank()) return@runCatching emptyList<InstalledApp>()

        val array = JSONArray(raw)
        val result = ArrayList<InstalledApp>(array.length())
        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue
            val packageName: String = item.optString("p", "").toString().trim()
            if (packageName.isBlank()) continue

            val rawLabel: String = item.optString("l", "").toString().trim()
            val label = if (rawLabel.isBlank()) packageName else rawLabel
            result += InstalledApp(
                packageName = packageName,
                label = label,
                searchText = normalizeForSearch("$label $packageName")
            )
        }
        result
    }.getOrNull()

    private fun writeDiskCache(apps: List<InstalledApp>) {
        runCatching {
            val array = JSONArray()
            apps.forEach { app ->
                array.put(JSONObject().apply {
                    put("p", app.packageName)
                    put("l", app.label)
                })
            }
            prefs.edit().putString(KEY_CATALOG, array.toString()).apply()
        }
    }

    private fun normalizeForSearch(value: String): String = value
        .lowercase(Locale.ROOT)
        .replace('ي', 'ی')
        .replace('ك', 'ک')
        .replace("\u200c", "")
        .trim()

    companion object {
        @Volatile
        private var processCache: List<InstalledApp>? = null
        private const val KEY_CATALOG = "launcher_apps_v1"
    }
}

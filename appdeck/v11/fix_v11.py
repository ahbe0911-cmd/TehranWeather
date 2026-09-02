from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

old = """                    installedApps = installedApps,
                    dashboardTitle = dashboardTitle,"""
new = """                    installedApps = installedApps,
                    favorites = favorites,
                    dashboardTitle = dashboardTitle,"""
if old in s:
    s = s.replace(old, new, 1)

old = """                SectionCard(
                    section = section,
                    appMap = appMap,
                    gridColumns = gridColumns,
                    showLabels = showLabels,
                    cardRows = cardRows,
                    favorites = favorites,
                    iconSize = iconSize,"""
new = """                SectionCard(
                    section = section,
                    appMap = appMap,
                    gridColumns = gridColumns,
                    showLabels = showLabels,
                    cardRows = cardRows,
                    iconSize = iconSize,"""
if old in s:
    s = s.replace(old, new, 1)

favorites_old = """private fun FavoritesCard(
    favorites: List<String>,
    sections: List<AppSection>,
    appMap: Map<String, InstalledApp>,
    columns: Int,
    iconSize: Int,
    compact: Boolean,
    ultraFastMode: Boolean,
    onToggleFavorite: (String) -> Unit,
    onSetFavoriteOrder: (List<String>) -> Unit
) {
    val context = LocalContext.current
    val aliases = remember(sections) {
        buildMap<String, String> {
            sections.forEach { section ->
                section.aliases.forEach { (pkg, alias) ->
                    if (alias.isNotBlank() && pkg !in this) put(pkg, alias)
                }
            }
        }
    }
    val synthetic = remember(favorites, aliases) {
        AppSection(
            id = -100L,
            title = "علاقه‌مندی‌ها",
            color = SectionColor.PURPLE,
            icon = SectionIcon.FAVORITE,
            packages = favorites,
            aliases = aliases
        )
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.18f)),
        elevation = CardDefaults.cardElevation(defaultElevation = if (ultraFastMode) 0.dp else 1.dp)
    ) {
        Column(Modifier.padding(horizontal = 11.dp, vertical = if (compact) 8.dp else 11.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Surface(shape = CircleShape, color = MaterialTheme.colorScheme.primary.copy(alpha = 0.10f)) {
                    Icon(
                        Icons.Default.Star,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(7.dp).size(18.dp)
                    )
                }
                Spacer(Modifier.width(8.dp))
                Text("علاقه‌مندی‌ها", fontWeight = FontWeight.Black, fontSize = 15.sp, modifier = Modifier.weight(1f))
                Text("${favorites.size}", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 10.sp)
            }
            Spacer(Modifier.height(if (compact) 5.dp else 8.dp))
            AppGrid(
                section = synthetic,
                appMap = appMap,
                columns = columns,
                showLabels = true,
                iconSize = iconSize,
                compact = compact,
                ultraFastMode = ultraFastMode,
                onEditApp = { pkg ->
                    onToggleFavorite(pkg)
                    Toast.makeText(context, "از علاقه‌مندی‌ها حذف شد", Toast.LENGTH_SHORT).show()
                },
                onCommitOrder = onSetFavoriteOrder
            )
        }
    }
}
"""

favorites_new = """private fun FavoritesCard(
    favorites: List<String>,
    sections: List<AppSection>,
    appMap: Map<String, InstalledApp>,
    columns: Int,
    iconSize: Int,
    compact: Boolean,
    ultraFastMode: Boolean,
    onToggleFavorite: (String) -> Unit,
    onSetFavoriteOrder: (List<String>) -> Unit
) {
    val context = LocalContext.current
    val aliases = remember(sections) {
        buildMap<String, String> {
            sections.forEach { section ->
                section.aliases.forEach { (pkg, alias) ->
                    if (alias.isNotBlank() && pkg !in this) put(pkg, alias)
                }
            }
        }
    }
    val synthetic = remember(favorites, aliases) {
        AppSection(
            id = -100L,
            title = "علاقه‌مندی‌ها",
            color = SectionColor.PURPLE,
            icon = SectionIcon.FAVORITE,
            packages = favorites,
            aliases = aliases
        )
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.16f)),
        elevation = CardDefaults.cardElevation(defaultElevation = if (ultraFastMode) 0.dp else 3.dp)
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            MaterialTheme.colorScheme.primary.copy(alpha = 0.05f),
                            MaterialTheme.colorScheme.surface,
                            MaterialTheme.colorScheme.surface
                        )
                    )
                )
        ) {
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(3.dp)
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.78f))
            )
            Column(Modifier.padding(horizontal = 12.dp, vertical = if (compact) 10.dp else 12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        shape = RoundedCornerShape(16.dp),
                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.10f)
                    ) {
                        Icon(
                            Icons.Default.Star,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(9.dp).size(19.dp)
                        )
                    }
                    Spacer(Modifier.width(9.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text("علاقه‌مندی‌ها", fontWeight = FontWeight.Black, fontSize = 15.sp, maxLines = 1)
                        Text(
                            "برنامه‌های ستاره‌دار شما",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            fontSize = 9.5.sp,
                            maxLines = 1
                        )
                    }
                    Surface(
                        shape = RoundedCornerShape(50),
                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.10f),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.14f))
                    ) {
                        Text(
                            "${favorites.size} برنامه",
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 10.sp,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                        )
                    }
                }
                Spacer(Modifier.height(if (compact) 8.dp else 10.dp))
                AppGrid(
                    section = synthetic,
                    appMap = appMap,
                    columns = columns,
                    showLabels = true,
                    iconSize = iconSize,
                    compact = compact,
                    ultraFastMode = ultraFastMode,
                    onEditApp = { pkg ->
                        onToggleFavorite(pkg)
                        Toast.makeText(context, "از علاقه‌مندی‌ها حذف شد", Toast.LENGTH_SHORT).show()
                    },
                    onCommitOrder = onSetFavoriteOrder
                )
            }
        }
    }
}
"""
if favorites_old in s:
    s = s.replace(favorites_old, favorites_new, 1)

section_start = s.index("private fun SectionCard(")
section_end = s.index("@Composable\nprivate fun AppGrid", section_start)
section_new = """private fun SectionCard(
    section: AppSection,
    appMap: Map<String, InstalledApp>,
    gridColumns: Int,
    showLabels: Boolean,
    cardRows: Int,
    iconSize: Int,
    compact: Boolean,
    ultraFastMode: Boolean,
    onAddClick: () -> Unit,
    onEditClick: () -> Unit,
    onManageClick: () -> Unit,
    onDeleteClick: () -> Unit,
    onToggleCollapsed: () -> Unit,
    onEditApp: (String) -> Unit,
    onSetPackageOrder: (List<String>) -> Unit
) {
    var menuOpen by remember { mutableStateOf(false) }
    var showAll by remember(section.id) { mutableStateOf(false) }
    val accent = section.color.toColor()
    val safeColumns = gridColumns.coerceIn(4, 6)
    val capacity = if (cardRows == 0) Int.MAX_VALUE else safeColumns * cardRows.coerceIn(1, 3)
    val visiblePackages = if (showAll || capacity == Int.MAX_VALUE) section.packages else section.packages.take(capacity)
    val hiddenCount = (section.packages.size - visiblePackages.size).coerceAtLeast(0)
    val headerPad = if (compact) 10.dp else 12.dp

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, accent.copy(alpha = 0.16f)),
        elevation = CardDefaults.cardElevation(defaultElevation = if (ultraFastMode) 0.dp else 3.dp)
    ) {
        Column(
            Modifier.fillMaxWidth().background(
                Brush.verticalGradient(
                    listOf(accent.copy(alpha = 0.05f), MaterialTheme.colorScheme.surface, MaterialTheme.colorScheme.surface)
                )
            )
        ) {
            Box(Modifier.fillMaxWidth().height(4.dp).background(accent.copy(alpha = 0.82f)))
            Column(Modifier.padding(horizontal = 12.dp, vertical = headerPad)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(shape = RoundedCornerShape(16.dp), color = accent.copy(alpha = 0.10f)) {
                        Icon(
                            section.icon.toImageVector(), contentDescription = null, tint = accent,
                            modifier = Modifier.padding(if (compact) 9.dp else 10.dp).size(if (compact) 20.dp else 22.dp)
                        )
                    }
                    Spacer(Modifier.width(10.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(section.title, fontWeight = FontWeight.Black, fontSize = if (compact) 16.sp else 18.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Text(
                            if (section.packages.isEmpty()) "بخش خالی" else "دسترسی سریع به برنامه‌های این بخش",
                            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 9.5.sp, maxLines = 1
                        )
                    }
                    if (section.packages.isNotEmpty()) {
                        Surface(
                            shape = RoundedCornerShape(50), color = accent.copy(alpha = 0.10f),
                            border = BorderStroke(1.dp, accent.copy(alpha = 0.14f))
                        ) {
                            Text(
                                "${section.packages.size} برنامه", color = accent, fontWeight = FontWeight.Bold, fontSize = 10.sp,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                            )
                        }
                        Spacer(Modifier.width(6.dp))
                    }
                    Surface(shape = CircleShape, color = accent.copy(alpha = 0.08f)) {
                        IconButton(onClick = onAddClick, modifier = Modifier.size(if (compact) 34.dp else 36.dp)) {
                            Icon(Icons.Default.Add, contentDescription = "افزودن برنامه", tint = accent, modifier = Modifier.size(20.dp))
                        }
                    }
                    Spacer(Modifier.width(4.dp))
                    Surface(shape = CircleShape, color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f)) {
                        IconButton(onClick = onToggleCollapsed, modifier = Modifier.size(if (compact) 34.dp else 36.dp)) {
                            Icon(if (section.collapsed) Icons.Default.ExpandMore else Icons.Default.ExpandLess, contentDescription = null, modifier = Modifier.size(20.dp))
                        }
                    }
                    Spacer(Modifier.width(4.dp))
                    Box {
                        Surface(shape = CircleShape, color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f)) {
                            IconButton(onClick = { menuOpen = true }, modifier = Modifier.size(if (compact) 34.dp else 36.dp)) {
                                Icon(Icons.Default.MoreVert, contentDescription = "منوی بخش", modifier = Modifier.size(20.dp))
                            }
                        }
                        DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                            DropdownMenuItem(text = { Text("ویرایش بخش") }, leadingIcon = { Icon(Icons.Default.Edit, null) }, onClick = { menuOpen = false; onEditClick() })
                            DropdownMenuItem(text = { Text("افزودن برنامه") }, leadingIcon = { Icon(Icons.Default.Add, null) }, onClick = { menuOpen = false; onAddClick() })
                            DropdownMenuItem(text = { Text("نام و ترتیب برنامه‌ها") }, leadingIcon = { Icon(Icons.Default.Apps, null) }, onClick = { menuOpen = false; onManageClick() })
                            DropdownMenuItem(text = { Text("حذف بخش") }, leadingIcon = { Icon(Icons.Default.Delete, null) }, onClick = { menuOpen = false; onDeleteClick() })
                        }
                    }
                }

                if (!section.collapsed) {
                    Spacer(Modifier.height(if (compact) 8.dp else 10.dp))
                    if (section.packages.isEmpty()) {
                        Surface(
                            shape = RoundedCornerShape(16.dp), color = accent.copy(alpha = 0.08f),
                            border = BorderStroke(1.dp, accent.copy(alpha = 0.10f)),
                            modifier = Modifier.fillMaxWidth().combinedClickable(onClick = onAddClick)
                        ) {
                            Text("افزودن برنامه", modifier = Modifier.padding(vertical = if (compact) 12.dp else 14.dp), textAlign = TextAlign.Center, color = accent, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    } else {
                        AppGrid(
                            section = section.copy(packages = visiblePackages), appMap = appMap, columns = safeColumns,
                            showLabels = showLabels, iconSize = iconSize, compact = compact, ultraFastMode = ultraFastMode,
                            onEditApp = onEditApp,
                            onCommitOrder = { visibleOrder ->
                                val hiddenPackages = section.packages.filterNot { it in visibleOrder }
                                onSetPackageOrder(visibleOrder + hiddenPackages)
                            }
                        )
                        if (hiddenCount > 0 || (showAll && section.packages.size > capacity)) {
                            TextButton(onClick = { showAll = !showAll }, modifier = Modifier.fillMaxWidth()) {
                                Icon(if (showAll) Icons.Default.ExpandLess else Icons.Default.ExpandMore, contentDescription = null, modifier = Modifier.size(17.dp))
                                Spacer(Modifier.width(5.dp))
                                Text(if (showAll) "کمتر" else "$hiddenCount برنامه دیگر", fontWeight = FontWeight.Bold, fontSize = 11.sp, color = accent)
                            }
                        }
                    }
                }
            }
        }
    }
}

"""
s = s[:section_start] + section_new + s[section_end:]

appgrid_start = s.index("private fun AppGrid(")
appgrid_end = s.index("@Composable\nprivate fun AppTile", appgrid_start)
appgrid_new = """private fun AppGrid(
    section: AppSection,
    appMap: Map<String, InstalledApp>,
    columns: Int,
    showLabels: Boolean,
    iconSize: Int,
    compact: Boolean,
    ultraFastMode: Boolean,
    onEditApp: (String) -> Unit,
    onCommitOrder: (List<String>) -> Unit
) {
    val safeColumns = columns.coerceIn(4, 6)
    var localOrder by remember(section.id) { mutableStateOf(section.packages) }
    var activeDrag by remember(section.id) { mutableStateOf<String?>(null) }

    LaunchedEffect(section.packages) {
        if (activeDrag == null && localOrder != section.packages) localOrder = section.packages
    }

    fun moveLocal(pkg: String, direction: Int) {
        val from = localOrder.indexOf(pkg)
        if (from < 0 || localOrder.isEmpty()) return
        val to = (from + direction).coerceIn(0, localOrder.lastIndex)
        if (to == from) return
        localOrder = localOrder.toMutableList().apply {
            val item = removeAt(from)
            add(to, item)
        }
    }

    Column(verticalArrangement = Arrangement.spacedBy(if (compact) 6.dp else 10.dp)) {
        localOrder.chunked(safeColumns).forEach { rowApps ->
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(if (compact) 2.dp else 4.dp)) {
                rowApps.forEach { pkg ->
                    key(pkg) {
                        val app = appMap[pkg]
                        val label = section.aliases[pkg].orEmpty().ifBlank { app?.label ?: "حذف‌شده" }
                        Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.TopCenter) {
                            AppTile(
                                packageName = pkg, label = label, showLabel = showLabels, columns = safeColumns,
                                iconSize = iconSize, compact = compact, ultraFastMode = ultraFastMode,
                                onMove = { direction -> moveLocal(pkg, direction) },
                                onLongPress = { onEditApp(pkg) },
                                onDragStateChange = { dragging ->
                                    if (dragging) activeDrag = pkg
                                    else if (activeDrag == pkg) {
                                        activeDrag = null
                                        if (localOrder != section.packages) onCommitOrder(localOrder)
                                    }
                                }
                            )
                        }
                    }
                }
                val missing = safeColumns - rowApps.size
                if (missing > 0) Spacer(Modifier.weight(missing.toFloat()))
            }
        }
    }
}

"""
s = s[:appgrid_start] + appgrid_new + s[appgrid_end:]

for token in [
    'favorites = favorites,',
    'shape = RoundedCornerShape(24.dp)',
    '"دسترسی سریع به برنامه‌های این بخش"',
    'Spacer(Modifier.weight(missing.toFloat()))'
]:
    if token not in s:
        raise SystemExit(f'V11 patch failed: missing token {token!r}')

p.write_text(s)
print('AppDeck V11 visual and RTL grid patch applied')

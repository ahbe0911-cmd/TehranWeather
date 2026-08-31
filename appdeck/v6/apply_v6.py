from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
def rep(a,b):
    global s
    if a not in s: raise SystemExit('missing anchor: '+a[:80])
    s=s.replace(a,b,1)
rep('import androidx.compose.ui.graphics.graphicsLayer\n','import androidx.compose.ui.graphics.graphicsLayer\nimport androidx.compose.ui.zIndex\n')
rep('    var editApp by remember { mutableStateOf<Pair<AppSection, String>?>(null) }\n\n    val appMap','    var editApp by remember { mutableStateOf<Pair<AppSection, String>?>(null) }\n    var actionApp by remember { mutableStateOf<Pair<AppSection, String>?>(null) }\n    var removeApp by remember { mutableStateOf<Pair<AppSection, String>?>(null) }\n\n    val appMap')
rep('                    onEditApp = { pkg -> editApp = section to pkg },\n                    onMovePackage = { pkg, direction -> onMovePackage(section.id, pkg, direction) }','                    onEditApp = { pkg -> actionApp = section to pkg },\n                    onMovePackage = { pkg, direction -> onMovePackage(section.id, pkg, direction) }')
anchor='    editApp?.let { (section, packageName) ->\n'
actions='''    actionApp?.let { (section, packageName) ->
        val liveSection = sections.firstOrNull { it.id == section.id } ?: section
        val displayName = liveSection.aliases[packageName].orEmpty().ifBlank { appMap[packageName]?.label ?: packageName }
        AppQuickActionsDialog(
            appName = displayName,
            onDismiss = { actionApp = null },
            onEdit = { manageSection = liveSection; actionApp = null },
            onRename = { editApp = liveSection to packageName; actionApp = null },
            onDelete = { removeApp = liveSection to packageName; actionApp = null }
        )
    }

    removeApp?.let { (section, packageName) ->
        val liveSection = sections.firstOrNull { it.id == section.id } ?: section
        val displayName = liveSection.aliases[packageName].orEmpty().ifBlank { appMap[packageName]?.label ?: packageName }
        ConfirmDeleteDialog(
            title = "حذف «$displayName» از این بخش؟",
            message = "خود برنامه از گوشی حذف نمی‌شود؛ فقط از این کارت برداشته می‌شود.",
            onDismiss = { removeApp = null },
            onConfirm = { onRemovePackage(liveSection.id, packageName); removeApp = null }
        )
    }

'''
if anchor not in s: raise SystemExit('missing edit dialog anchor')
s=s.replace(anchor,actions+anchor,1)
rep('''                            columns = safeColumns,
                            onMove = { direction -> onMovePackage(pkg, direction) }
                        )''','''                            columns = safeColumns,
                            onMove = { direction -> onMovePackage(pkg, direction) },
                            onLongPress = { onEditApp(pkg) }
                        )''')
start=s.index('@Composable\nprivate fun AppTile('); end=s.index('@Composable\nprivate fun CachedAppIcon',start)
new='''@Composable
private fun AppTile(
    packageName: String,
    label: String,
    showLabel: Boolean,
    columns: Int,
    onMove: (Int) -> Unit,
    onLongPress: () -> Unit
) {
    val context = LocalContext.current
    val density = LocalDensity.current
    val haptic = LocalHapticFeedback.current
    val tileTint = remember(packageName) { appAccent(packageName) }
    var dragX by remember(packageName) { mutableFloatStateOf(0f) }
    var dragY by remember(packageName) { mutableFloatStateOf(0f) }
    var dragging by remember(packageName) { mutableStateOf(false) }
    var moved by remember(packageName) { mutableStateOf(false) }
    val threshold = with(density) { 30.dp.toPx() }
    val maxOffset = threshold * 1.55f

    Column(
        modifier = Modifier
            .zIndex(if (dragging) 4f else 0f)
            .graphicsLayer {
                translationX = dragX.coerceIn(-maxOffset, maxOffset)
                translationY = dragY.coerceIn(-maxOffset, maxOffset)
                scaleX = if (dragging) 1.075f else 1f
                scaleY = if (dragging) 1.075f else 1f
                alpha = if (dragging) 0.96f else 1f
            }
            .clip(RoundedCornerShape(15.dp))
            .pointerInput(packageName, columns) {
                detectDragGesturesAfterLongPress(
                    onDragStart = { dragging = true; moved = false; haptic.performHapticFeedback(HapticFeedbackType.LongPress) },
                    onDragCancel = { dragX = 0f; dragY = 0f; dragging = false; moved = false },
                    onDragEnd = {
                        if (!moved) onLongPress()
                        dragX = 0f; dragY = 0f; dragging = false; moved = false
                    },
                    onDrag = { change, amount ->
                        change.consume(); dragX += amount.x; dragY += amount.y
                        if (abs(dragX) >= threshold) {
                            onMove(if (dragX < 0f) 1 else -1); moved = true
                            dragX += if (dragX < 0f) threshold else -threshold
                        }
                        if (abs(dragY) >= threshold) {
                            onMove(if (dragY > 0f) columns else -columns); moved = true
                            dragY += if (dragY > 0f) -threshold else threshold
                        }
                    }
                )
            }
            .combinedClickable(onClick = { launchPackage(context, packageName) })
            .padding(horizontal = 2.dp, vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Surface(
            shape = RoundedCornerShape(16.dp),
            color = tileTint.copy(alpha = if (dragging) 0.18f else 0.09f),
            border = BorderStroke(1.dp, tileTint.copy(alpha = if (dragging) 0.42f else 0.17f)),
            shadowElevation = if (dragging) 10.dp else 1.dp
        ) {
            CachedAppIcon(packageName, label, Modifier.padding(6.dp), 42)
        }
        if (showLabel) {
            Spacer(Modifier.height(5.dp))
            Text(label,maxLines=1,overflow=TextOverflow.Ellipsis,fontSize=10.sp,textAlign=TextAlign.Center,modifier=Modifier.fillMaxWidth())
        }
    }
}

@Composable
private fun AppQuickActionsDialog(appName:String,onDismiss:()->Unit,onEdit:()->Unit,onRename:()->Unit,onDelete:()->Unit) {
    AlertDialog(
        onDismissRequest=onDismiss,
        title={ Text(appName,fontWeight=FontWeight.ExtraBold) },
        text={ Column(Modifier.fillMaxWidth()) {
            TextButton(onClick=onEdit,modifier=Modifier.fillMaxWidth()) { Icon(Icons.Default.Edit,null); Spacer(Modifier.width(8.dp)); Text("ویرایش",modifier=Modifier.weight(1f),textAlign=TextAlign.Start) }
            TextButton(onClick=onRename,modifier=Modifier.fillMaxWidth()) { Icon(Icons.Default.TextFields,null); Spacer(Modifier.width(8.dp)); Text("تغییر نام",modifier=Modifier.weight(1f),textAlign=TextAlign.Start) }
            TextButton(onClick=onDelete,modifier=Modifier.fillMaxWidth()) { Icon(Icons.Default.Delete,null,tint=MaterialTheme.colorScheme.error); Spacer(Modifier.width(8.dp)); Text("حذف از این بخش",modifier=Modifier.weight(1f),textAlign=TextAlign.Start,color=MaterialTheme.colorScheme.error) }
        } },
        confirmButton={},
        dismissButton={ TextButton(onClick=onDismiss){ Text("بستن") } }
    )
}

'''
s=s[:start]+new+s[end:]
s=s.replace('"برای جابه‌جایی، آیکون برنامه را کمی نگه‌دار و به جای جدید بکش.",','"نگه‌داشتن بدون حرکت: ویرایش / تغییر نام / حذف — نگه‌داشتن و کشیدن: جابه‌جایی روان",',1)
p.write_text(s)
print('AppDeck V6 patch applied')

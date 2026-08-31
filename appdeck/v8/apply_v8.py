from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

def rep(old, new, count=1):
    global s
    if old not in s:
        raise SystemExit('missing V8 anchor: ' + old[:120])
    s = s.replace(old, new, count)

rep(
'''    var actionJob by remember(packageName) { mutableStateOf<Job?>(null) }\n    var actionShown by remember(packageName) { mutableStateOf(false) }\n''',
'''    var actionJob by remember(packageName) { mutableStateOf<Job?>(null) }\n    var launchResetJob by remember(packageName) { mutableStateOf<Job?>(null) }\n    var actionShown by remember(packageName) { mutableStateOf(false) }\n    var suppressLaunch by remember(packageName) { mutableStateOf(false) }\n'''
)

rep(
'''    fun resetGesture() {\n        actionJob?.cancel()\n        actionJob = null\n        if (dragging) onDragStateChange(false)\n        dragX = 0f\n        dragY = 0f\n        dragging = false\n        moved = false\n        actionShown = false\n    }\n''',
'''    fun resetGesture() {\n        actionJob?.cancel()\n        actionJob = null\n        if (dragging) onDragStateChange(false)\n        dragX = 0f\n        dragY = 0f\n        dragging = false\n        moved = false\n        actionShown = false\n        if (suppressLaunch) {\n            launchResetJob?.cancel()\n            launchResetJob = gestureScope.launch {\n                delay(450L)\n                suppressLaunch = false\n            }\n        }\n    }\n'''
)

rep(
'''                    onDragStart = {\n                        dragging = true\n                        moved = false\n                        actionShown = false\n                        onDragStateChange(true)\n''',
'''                    onDragStart = {\n                        dragging = true\n                        moved = false\n                        actionShown = false\n                        suppressLaunch = true\n                        launchResetJob?.cancel()\n                        launchResetJob = null\n                        onDragStateChange(true)\n'''
)

rep(
'''            .combinedClickable(onClick = { launchPackage(context, packageName) })\n''',
'''            .combinedClickable(\n                onClick = {\n                    if (suppressLaunch) {\n                        suppressLaunch = false\n                        launchResetJob?.cancel()\n                        launchResetJob = null\n                    } else {\n                        launchPackage(context, packageName)\n                    }\n                }\n            )\n'''
)

p.write_text(s)
print('AppDeck V8 patch applied: long press no longer launches app')

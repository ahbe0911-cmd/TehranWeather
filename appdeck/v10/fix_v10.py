from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

old = '''                    installedApps = installedApps,\n                    dashboardTitle = dashboardTitle,'''
new = '''                    installedApps = installedApps,\n                    favorites = favorites,\n                    dashboardTitle = dashboardTitle,'''
if old in s:
    s = s.replace(old, new, 1)

old = '''                SectionCard(\n                    section = section,\n                    appMap = appMap,\n                    gridColumns = gridColumns,\n                    showLabels = showLabels,\n                    cardRows = cardRows,\n                    favorites = favorites,\n                    iconSize = iconSize,'''
new = '''                SectionCard(\n                    section = section,\n                    appMap = appMap,\n                    gridColumns = gridColumns,\n                    showLabels = showLabels,\n                    cardRows = cardRows,\n                    iconSize = iconSize,'''
if old in s:
    s = s.replace(old, new, 1)

# Guard the two intended fixes so CI fails early if the generated source drifts.
if '''DashboardScreen(\n                    modifier = Modifier.padding(padding),\n                    sections = sections,\n                    installedApps = installedApps,\n                    favorites = favorites,''' not in s:
    raise SystemExit('V10 fix failed: DashboardScreen favorites argument missing')
if '''SectionCard(\n                    section = section,\n                    appMap = appMap,\n                    gridColumns = gridColumns,\n                    showLabels = showLabels,\n                    cardRows = cardRows,\n                    favorites = favorites,''' in s:
    raise SystemExit('V10 fix failed: invalid SectionCard favorites argument still present')

p.write_text(s)
print('AppDeck V10 compile fix applied')

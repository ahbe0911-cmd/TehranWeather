from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
s = s.replace('Surface(CircleShape, color=MaterialTheme.colorScheme.primary.copy(alpha=.12f))', 'Surface(shape=CircleShape, color=MaterialTheme.colorScheme.primary.copy(alpha=.12f))')
s = s.replace('Surface(CircleShape,color=MaterialTheme.colorScheme.secondary.copy(alpha=.12f))', 'Surface(shape=CircleShape,color=MaterialTheme.colorScheme.secondary.copy(alpha=.12f))')
p.write_text(s)
print('AppDeck V9 compile fix applied')

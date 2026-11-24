## fn
fn parse_input -> czyta liste sciezek z JSON stdin (tool_input)
fn parse_input(Bash) -> cele zapisu: sed -i, >, >>, tee; tylko istniejace pliki
fn check_file -> cala analiza per plik; petla po liste sciezek
fn extract_functions -> regex per jezyk: PHP/JS/TS/CSS/Py/Bash
fn find_doc -> szuka docs/<basename>.md, fallback CLAUDE.md
fn check_documented -> porownuje symbole z doc, zwraca nieudokumentowane

## vars
const FILE_PATH -> sciezka edytowanego pliku (z stdin)
const PROJECT_ROOT -> git rev-parse --show-toplevel
const NEAREST_DOC -> docs/<basename>.md lub CLAUDE.md
const SIGNIFICANCE -> minor/moderate/significant wg LINE_COUNT + ext
const FUNCTIONS -> lista wykrytych symboli
const UNDOCUMENTED -> symbole nieobecne w doc

## fx
- stdout: DOC-ADD (brakujace symbole) lub DOC-NEW (nowy plik)
- silent gdy wszystko zaindeksowane

## deps
< settings.json (registered as PostToolUse hook)

## Jezyki
- PHP: funkcje, klasy, add_action/filter, wp_enqueue
- JS/TS/JSX/TSX: export fn, const, class, interface, type
- CSS/SCSS: klasy, zmienne, @media, @keyframes
- Python: def, class, lambda
- Vue/Svelte: defineProps, defineEmits

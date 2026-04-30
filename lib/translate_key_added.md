# Translation keys added — medicare-doctor-app

Tracking file for translation keys added during the i18n cleanup pass.
Locale files live in `lib/languages/` (`en`, `es`, `pt`, `zh`, `zh_tw`).

## Convention

- Keys are lowercase snake_case. Punctuation in the value goes in the value, not the key.
- **Named placeholders use `@name`** with `.trParams({...})`:
  - `"booking_id": "Booking #@id"` → `"booking_id".trParams({"id": "123"})`
  - Use this when there is **1 placeholder**, or when the substituted values have semantic meaning.
- **Positional placeholders use `%s`** with `.trArgs([...])`:
  - `"full_name": "%s %s"` → `"full_name".trArgs(["Pablo", "Lin"])`
  - Use this when there are **2+ placeholders** with similar/uniform meaning, or for
    pure formatting templates (separators, ordering).
- Do **not** use `{name}` — that is the i18next/Vue style; GetX `.trParams` does not interpolate it.

## Cross-locale parity audit

Before this pass:
- `en` / `es` / `pt` / `zh`: 243 keys each (parity OK).
- `zh_tw`: 242 keys — `blood_pressure` was present but on the **same line** as the
  preceding entry, which my key-extraction grep missed. The map parses fine; just bad
  formatting. Fixed by splitting onto its own line.

After this pass: **all five locales hold 247 keys**, zero diffs.

## Keys added (alphabetical)

| Key | en | es | pt | zh | zh_tw |
|---|---|---|---|---|---|
| `failed_to_load_image` | Failed to load image: @error | Error al cargar la imagen: @error | Falha ao carregar a imagem: @error | 加载图片失败：@error | 載入圖片失敗：@error |
| `full_name` | `%s %s` | `%s %s` | `%s %s` | `%s %s` | `%s %s` |
| `item_index_name` | `%s - %s` | `%s - %s` | `%s - %s` | `%s - %s` | `%s - %s` |
| `or` | or | o | ou | 或 | 或 |

(`%s`-only format strings are deliberately identical across locales — only ordering/separators, no translatable text.)

## Sites converted

### Plain `.tr`

| File:Line | Was | Now |
|---|---|---|
| `pages/login_page.dart:404` | `Text("or")` | `Text("or".tr)` |

### `.trParams({...})` — 1 named placeholder

| File:Line | Was | Now |
|---|---|---|
| `pages/write_prescription_page.dart:470` | `Text('Failed to load image: $e')` | `Text("failed_to_load_image".trParams({"error": "$e"}))` |

### `.trArgs([...])` — 2+ positional placeholders

| File:Line | Was | Now |
|---|---|---|
| `pages/add_prescription_page.dart:611` | `Text("${index+1} - ${medication.medicineName}")` | `Text("item_index_name".trArgs(["${index+1}", medicineName ?? ""]))` |
| `pages/patient_file_page.dart:133` | `Text("${pf.pFName} ${pf.pLName}")` | `Text("full_name".trArgs([pFName ?? "", pLName ?? ""]))` |
| `pages/prescription_page.dart:117` | `Text("${pr.patientFName} ${pr.patientLName}")` | `Text("full_name".trArgs([patientFName ?? "", patientLName ?? ""]))` |

## Pure-data interpolations left as-is (intentional)

`Text("${var}")` widgets that contain a single variable with no surrounding translatable text
were not converted, because wrapping a runtime value in `.trParams` adds verbosity without
i18n benefit. Examples kept verbatim:

- `pages/contact_us_page.dart:57` — `Text("${snapshot.data?.value}")`
- `pages/share_page.dart:88` — `Text("${snapshot.data?.value}")`
- `pages/notification_page.dart:106` — `Text("${notificationModel.id}${notificationModel.title}")`
  (id+title concatenation, no separator, pure data)

If you want these wrapped for full consistency, say so — mechanical from here.

## `{param}` → `@param` migration

Audited all five locale files (`grep '\{[a-zA-Z]'` over `lib/languages/`):
**no values use `{param}` style**. Already in `@param`. No migration needed.

## Verification

`flutter analyze --no-pub` shows **79 issues, none in the touched files** (all preexisting:
unused_import, deprecated_member_use, missing type annotation, etc.).

# Carrousel — content editor

A tiny local WYSIWYG editor for the **copy** on the Carrousel landing page
(`../landing/index.html`). Click any text to edit it in place, in both French
and English, then save — and publish with one button.

It edits page text only: it never touches the layout, styles, or the drifting
iPad rotation. It lives outside `landing/`, so it is **never deployed**.

## Run

```bash
cd editor
npm start           # → http://127.0.0.1:4620   (or: node server.mjs)
```

Open the URL. The real landing loads inside the editor.

## Use

- **Click any text** → it becomes editable. Type, then click away (or press
  Enter) to commit. `Esc` cancels the current field.
- **FR / EN** (top-left) switches the preview language so you can edit the other
  language's copy. Edits in both languages are kept until you save.
- **Enregistrer** (`⌘S`) writes your changes back into `../landing/index.html`.
  Every save first copies the file into `backups/` (and keeps the pristine
  original as `backups/index.original.html`).
- **Publier** deploys the current saved page live to
  https://carrousel-app.netlify.app via the Netlify CLI.
- **Réinitialiser** reloads the page, discarding unsaved edits.

## How saving stays safe

The server locates each `<span class="fr">` / `<span class="en">` copy span by
its position in the document (depth-aware, so nested `.soft` spans and `&nbsp;`
are preserved) and splices only the changed spans back into the file — the rest
of `index.html` is left byte-for-byte untouched. If the file's span count no
longer matches what the editor loaded, the save is refused (reload first).

To edit photos, captions, the reminder card, or the rotation order, use the
image pipeline instead: `../store/screenshots/gen-extra.mjs`.

# 6.1 What the fabricator receives

Not your KiCad project, but:

| Files | Contents |
|---|---|
| Gerber (`.gbr`) | each layer separately: copper, mask, silkscreen, outline |
| Drill (`.drl`) | position and diameter of every hole |
| BOM (`.csv`) | which components, and how many |
| CPL / Pick&Place (`.csv`) | position and rotation of every component |

Gerber is an old, textual and surprisingly simple format — essentially a list of *"move here, draw this"* commands. Open one in a text editor; it is worth seeing what you actually send.

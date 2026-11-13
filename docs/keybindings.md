# Keybindings & Movement — Design Doc

**Status:** Draft (v0.3 — baseline implemented, editing commands added, search added)
**Scope:** Navigation and editing input model, covering keyboard, mouse, leader key, and mode behavior.

---

## 1. Overview

This document defines the input model for navigation and editing. The goals are:

- Familiar movement for Vim users (HJKL) without excluding arrow-key users.
- A simple, predictable mode system (insert vs. non-insert).
- A single, consistent "reset" action via ESC.
- A leader key as the extensible entry point for future commands.

Everything here is intentionally minimal — a baseline to build on, not a final spec.

---

## 2. Modes

Two modes exist at this stage:

| Mode | Purpose | Behavior |
|---|---|---|
| **Insert Mode** | Typing/editing content | Keystrokes are entered as text |
| **Command Mode** (non-insert) | Navigating and issuing commands | Keystrokes are interpreted as movement/commands, not text |

**Entering Insert Mode:** pressing `i` while in Command Mode switches to Insert Mode.

Leader is not a third mode — it is an *armed sub-state* of Command Mode (see §6).

---

## 3. Keyboard Movement

### 3.1 Vim-style movement
Standard HJKL directional movement, matching Vim conventions:

| Key | Action |
|---|---|
| `h` | Move left |
| `j` | Move down |
| `k` | Move up |
| `l` | Move right |

### 3.2 Arrow key movement
Arrow keys mirror HJKL as a default, non-Vim-native alternative:

| Key | Action |
|---|---|
| `←` | Move left |
| `↓` | Move down |
| `↑` | Move up |
| `→` | Move right |

Arrow keys also work in Insert Mode, where they always move exactly one step (repeat counts are Command Mode only — in Insert Mode digits are text).

### 3.3 Movement clamping
Movement never fails or wraps; it saturates at the buffer edges:

- Vertical movement clamps to the last line.
- After any vertical move, the column is clamped to the length of the destination line.
- Horizontal movement clamps to the start/end of the current line — it does **not** wrap to the previous/next line.

### 3.4 Line jumping
Two distinct mechanisms exist for jumping the cursor by number:

| Mechanism | Input | Result |
|---|---|---|
| **Repeat-count movement** | Number, then an arrow key or HJKL movement | Moves the cursor that many steps in the given direction |
| **Absolute line jump** | Leader key → number → `Enter` | Jumps the cursor directly to that line |

These are kept separate: repeat-count movement is a modifier on directional movement, while the leader-driven jump is an absolute positioning command routed through the leader key.

**Count semantics:**

- Digits accumulate decimally, so `1` `2` `j` moves down 12 lines.
- A count is consumed by the movement that follows it; a count of `0` or no count means 1.
- Absolute line numbers are 1-based, matching the gutter. A number past the end of the buffer jumps to the last line.
- The pending count is discarded by `i`, `d`, `u`, `c`, `v`, and `ESC`, and is shown in the status line while it is being entered (see §8).

---

## 4. Editing Commands

Available in Command Mode:

| Key | Action |
|---|---|
| `i` | Enter Insert Mode |
| `d` | Delete the selection, or the current line when nothing is selected |
| `c` / `Ctrl+C` | Copy the selection to the system clipboard |
| `v` / `Ctrl+V` | Paste from the system clipboard at the cursor |
| `u` | Undo the last change |

**Delete (`d`):** with a selection, removes the selected text and places the cursor where the selection started. Without one, removes the line under the cursor. The cursor clamps to the last line if the final line was deleted. Deleting the only line of a buffer clears it rather than leaving an empty buffer.

**Copy (`c`):** copies the selected text to the system clipboard (macOS `pbcopy`), so it can be pasted in any other application. Lines are joined with `\n`. The selection stays visible after copying. Without a selection, `c` is a no-op.

**Paste (`v`):** inserts the system clipboard contents (macOS `pbpaste`) at the cursor, so text copied in any other application can be pasted too. If there is a selection, the pasted text replaces it. `\r` characters are dropped, so CRLF text pastes as normal lines. An empty clipboard is a no-op.

**Undo (`u`):** restores the most recent snapshot. A snapshot is pushed *before* entering Insert Mode (`i`), *before* each delete (`d`) and *before* each paste (`v`) — so an undo rolls back a whole insert session, not a single character. Undo with an empty history is a no-op. Undo also clears the selection.

### 4.1 Selection

Text is selected with the mouse (see §6):

- Pressing the button stores the **start** point (`x`, `y`); dragging updates the **end** point; releasing finishes the selection.
- Start and end are kept as dragged and put in document order when used, so dragging backwards selects the same text.
- The end point is exclusive: dragging from column 2 to column 5 selects 3 characters. Lines between the first and last line are selected in full.
- A click without dragging clears the selection.
- Selected text is drawn with a different background color; the foreground (syntax) colors are unchanged so it stays readable.
- Moving the cursor with `hjkl` or the arrow keys keeps the selection. `ESC`, `u`, `d` and `v` clear it.

---

## 5. Insert Mode Keys

| Key | Action |
|---|---|
| Printable characters | Inserted at the cursor |
| `Enter` | Split the line at the cursor; the remainder moves to a new line below |
| `Backspace` | Delete the character before the cursor; at column 0 joins the line onto the one above |
| Arrow keys | Move one step (no repeat counts) |
| Scroll wheel | Move one step up/down |
| `ESC` | Return to Command Mode |

`Backspace` at the very start of the buffer (line 0, column 0) is a no-op.

---

## 6. Mouse

Mouse support is enabled for direct cursor placement and scrolling.

- **Click:** moves the cursor to the clicked location. The click position is translated through the gutter width and the current scroll offset, then clamped to the target line's length.
- **Drag:** selects text from where the button was pressed to where it is released; the cursor follows the drag (see §4.1). Dragging past the edge of the screen does not scroll yet.
- **Scroll wheel up/down:** moves the cursor one line up/down, which pulls the viewport with it (see §8).
- **Behavior is identical across modes** — clicking and scrolling work the same way in both Insert and Command Mode.
- **Source tree:** a click inside the tree panel expands/collapses a directory or opens a file (see §7.2), instead of moving the cursor.

---

## 7. Leader Key

The leader key is the entry point for higher-level commands. It does not move the cursor itself — it opens a command context.

**Binding:** `Space` is the leader key.

**Commands routed through leader:**

| Key | Command | Description |
|---|---|---|
| `w` | Save | Write the buffer to its path; status shows `SAVED` |
| `q` | Quit | Exit the editor |
| `f` | Find file | Open the file picker |
| `g` | Search content | Open the content picker |
| `Space` | Open buffer | Open the buffer picker |
| `t` | Toggle tree | Show or hide the source tree panel |
| digits + `Enter` | Absolute line jump | Jump to the given line number (see §3.4) |
| `ESC` | Cancel | Disarm leader, return to Command Mode |

Unbound keys pressed while leader is armed are ignored — leader stays armed.

**Cancel behavior:** Leader mode does not time out — it requires `ESC` to cancel.

### 7.1 Search Overlay

`leader f` searches file paths, `leader g` searches file contents, and `leader Space` lists the files opened this session. All three open a centered overlay that takes every keystroke until it closes.

| Key | Action |
|---|---|
| Printable characters | Append to the query |
| `Backspace` | Delete the last query character |
| `↑` / `↓`, scroll wheel | Move the selection |
| `Enter` | Open the selected result |
| `ESC` | Close the overlay |

### 7.2 Source Tree

A panel on the left edge lists the directory juno was launched from. It is open at startup and `leader t` hides/shows it; while it is shown, the gutter, text and cursor shift right by the panel width.

- Directories are listed first, then files, each alphabetically. Dotfiles and the directories ignored by search (`node_modules`, `zig-out`, `target`, `vendor`) are hidden.
- Directories are read lazily, on first expand, and re-read on every expand.
- The file that is currently open is highlighted.
- The panel does not scroll yet; entries past the bottom of the screen are cut off.

---

## 8. Status Line & Indicators

The bottom row of the terminal is reserved for editor state; the canvas draws into the remaining rows.

**Contents, left to right:** mode indicator, current file path, pending count (as `| <n>`) when one is being entered.

| Indicator | Meaning |
|---|---|
| `NORMAL` | Command Mode |
| `INSERT` | Insert Mode |
| `SAVED` | Buffer was just written |
| `LEADER` | Leader armed, awaiting a command |
| `SEARCH` | A search overlay is open |

This resolves v0.1's open question: leader mode **does** have a visible armed indicator. It is signalled twice — the `LEADER` block is drawn in its own highlight colors, and the terminal cursor changes color while leader is armed.

**Viewport:** scrolling is sticky. The view stays put until the cursor moves above the top visible row or below the bottom visible row, at which point it scrolls by the minimum needed to keep the cursor on screen.

---

## 9. Escape (ESC) Behavior

`ESC` acts as the universal reset:

| State when ESC is pressed | Result |
|---|---|
| Text selected | Clear the selection |
| Insert mode | Return to command (non-insert) mode |
| Leader key armed (awaiting command) | Cancel leader, return to normal command state |
| Search overlay open | Close the overlay, discarding the query; the buffer is unchanged |
| Any in-progress movement input (e.g. line-jump entry) | Cancel and discard the partial input |

A reset clears insert, leader, the selection, and the pending count together, and returns the status indicator to `NORMAL`.

**Design intent:** ESC should always be a safe, predictable "back out" — no matter what sub-state the user is in, one ESC returns them to a known baseline (command mode, no pending input).

---

## 10. Summary Table

| Feature | Behavior |
|---|---|
| Movement (Vim) | `h` `j` `k` `l` |
| Movement (arrows) | Arrow keys, mirrors HJKL, also active in Insert Mode |
| Insert mode entry | `i` from Command Mode |
| Line jump (relative) | Number + arrow/HJKL = repeat-count movement |
| Line jump (absolute) | `Space` (leader) → number → `Enter`, 1-based |
| Find file | `Space` → `f` |
| Search content | `Space` → `g` |
| Open buffer | `Space` → `Space` |
| Toggle source tree | `Space` → `t`; click to expand a directory or open a file |
| Select text | Mouse drag; click to clear |
| Delete | `d` deletes the selection, or the current line without one |
| Copy | `c` / `Ctrl+C`, to the system clipboard |
| Paste | `v` / `Ctrl+V`, from the system clipboard; replaces the selection |
| Undo | `u`, snapshots taken before `i`, `d` and `v` |
| Split line | `Enter` in Insert Mode |
| Join line | `Backspace` at column 0 in Insert Mode |
| Mouse | Click to reposition cursor, drag to select, scroll wheel moves one line, identical in both modes |
| Leader key | `Space` → `w` save, `q` quit, `f` find file, `g` search content, `Space` open buffer, `t` toggle tree, digits + `Enter` jump, `ESC` cancel |
| ESC | Resets insert, leader, selection, and pending input states |
| Status line | Bottom row: `NORMAL` / `INSERT` / `SAVED` / `LEADER` / `SEARCH`, path, pending count |
| Modes | Insert vs. Command (non-insert) |

---

Remaining items for next iteration: whether leader commands need grouping as the command set grows. Search is bound flat as `leader f`, `leader g` and `leader Space` rather than under a `leader s` namespace.

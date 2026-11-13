# `src/` Structure

This document explains how the source tree is organized, what belongs where,
and the conventions to follow when adding new code. The goal is to keep
responsibilities cleanly separated so each part of the codebase can be
reasoned about (and tested) in isolation.

## Guiding principle: dependency injection

Objects and structs should **not** initialize their own dependencies
internally. Instead:

- Construct dependencies once (currently in `main.zig`).
- Pass them in via `init(...)` parameters, struct fields, or function
  arguments.
- Favor accepting an already-constructed dependency (or an interface/vtable
  where behavior needs to vary) over reaching out and creating/looking up
  that dependency from within a module.

This keeps modules reusable and decoupled from *how* their dependencies were
built, and it keeps `main.zig` as the single place that knows how the whole
object graph fits together.

## `main.zig`

`main.zig` is the composition root. It is responsible for:

- **Initialization** of all top-level objects and structs (terminal handle,
  config, editor state, canvas/renderer, file service, etc.), and wiring
  them together via dependency injection.
- **The event loop.** This is where input is read, dispatched to the
  editor, and a frame is rendered each iteration.

Nothing outside `main.zig` should be performing this kind of top-level
initialization. If a module needs something, it should receive it as a
parameter rather than constructing it itself.

> **Note:** Centralizing initialization in `main.zig` is a *temporary*
> arrangement. As the project grows this will likely move to a dedicated
> setup/bootstrap module. Until then, treat `main.zig` as the only place
> object graphs get built.
>
> **Exception:** a module may construct something internally if there's a
> concrete, specific reason to (e.g. a short-lived helper value, a scratch
> allocator, something that genuinely has no reason to be shared or
> injected). Default to injection; only opt out when there's a clear case
> for it.

## Folders (packages)

Each folder below groups related logic. In Zig terms these are directories
of modules (each `.zig` file is a module); a folder generally exposes itself
through a single entry file (e.g. `folder/folder.zig` or `folder/root.zig`)
that re-exports what the rest of the project is meant to use. Informally,
each folder is treated as a "package", a unit with one responsibility.

### `file/`

Owns all file I/O. Reading files, writing files, and any logic around
locating/handling files on disk lives here. Other packages that need file
contents (e.g. the canvas, when it needs buffer data to render) should be
handed a file-service dependency rather than touching the filesystem
themselves.

### `terminal/`

Owns everything related to the terminal the program is running in:
detecting terminal capabilities/behavior, and exposing the information
other packages need about the terminal (size, raw-mode handling, capability
flags, etc.). This is the single source of truth for "what can/does the
terminal do," and it's what `canvas/` uses for rendering context.

### `config/`

Small, early-stage home for configuration. The project aims to work
correctly out of the box with no configuration required, but this package
exists to leave room for user-adjustable settings later (theme colors, etc.).
Keep this minimal and additive, it shouldn't be a dependency of core logic
yet, just a place for optional overrides to eventually live.

### `editor/`

Owns editor behavior: key listener/input-handling logic and editor state
(cursor position, buffers, modes, etc.). This is the "brain" of the
application, it decides what should happen in response to input, but it
does not draw anything or talk to the terminal directly.

### `canvas/`

Owns rendering. It:

- Uses context/capabilities from `terminal/` to know how to draw.
- Retrieves data (e.g. file/buffer contents) from `file/`.
- Composes that into a final frame and draws it to the terminal screen.

`canvas/` is the compositor, it pulls together state and data from other
packages and turns it into terminal output. It shouldn't own state itself
beyond what's needed to render (that belongs in `editor/`).

## Quick reference

| Location      | Responsibility                                                        |
|---------------|-------------------------------------------------------------------------|
| `main.zig`    | Initialize everything (DI), wire dependencies, run the event loop      |
| `file/`       | Reading/writing files                                                  |
| `terminal/`   | Terminal detection, capabilities, terminal-related info                |
| `config/`     | User-adjustable settings (theme, etc.), small, early-stage            |
| `editor/`     | Key handling, editor state                                             |
| `canvas/`     | Rendering: terminal context + file data → drawn frame                  |

## Adding new code

Before adding a new top-level folder, check whether the logic actually fits
one of the packages above.

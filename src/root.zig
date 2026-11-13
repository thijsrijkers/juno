//! By convention, root.zig is the root source file when making a package.

pub const editor = @import("editor/editor.zig");
pub const canvas = @import("canvas/canvas.zig");
pub const modelState = @import("terminal/modelState.zig");
pub const modelSize = @import("terminal/modelSize.zig");
pub const input = @import("terminal/input.zig");
pub const fileTree = @import("file/fileTree.zig");


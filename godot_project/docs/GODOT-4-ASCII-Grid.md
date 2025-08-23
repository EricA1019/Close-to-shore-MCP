# GODOT-4-ASCII-Grid Notes

This project uses the ASCII terminal addon.

## Local adjustments (2025-08-23)

To improve headless stability and fix rendering bugs, we made these local changes:

- `term_rect.gd`: preloaded `term_buffer.gd` and `term_cell.gd`; export `term_root` as `Node`; added method guards.
- `term_buffer.gd`: removed strict `TermCell` type hints for `put_cell`/`get_cell`.
- `term_container.gd`: path-based `extends` to `term_element.gd`; fixed border drawing (right column); robust title alignment; exported `border`/`title` as `Resource`.
- `term_container_hbox.gd` and `term_container_vbox.gd`: path-based `extends`; loosened lambda param typing.
- `term_label.gd`: fixed grid building for no-wrap and arbitrary wrap; iterates keys when blitting.

These are minimal, surgical edits to support CI. Consider upstreaming fixes if they generalize.

# Add Plugin Workflow

This workflow ensures all plugins are added, documented, and integrated consistently.

## Steps
1. **Download Plugin**
   - Obtain the plugin from the official source (Godot Asset Library, GitHub, etc.).
2. **Add to Project**
   - Place the plugin in `godot_project/addons/<plugin_name>/`.
3. **Create Plugin README**
   - Add a `README.md` in the plugin folder with installation and usage instructions.
4. **Document Plugin**
   - Create a documentation file in `MCP/GODOT_TOOLS/<plugin_name>_plugin.md`.
   - Include overview, features, installation, usage, links, license, changelog, and credits.
5. **Update Plugin List**
   - Add the plugin to `godot_project/docs/PLUGINS_LIST.md`.
6. **Automate Updates**
   - Ensure update tasks exist in `.vscode/tasks.json` for plugin maintenance.
7. **Test Integration**
   - Run project and plugin-specific tests to verify correct installation and operation.

## Example
- See `ghost_camera_plugin.md` and `addons/ghost_camera/README.md` for reference.

---
This workflow keeps plugin management uniform and maintainable across all projects.

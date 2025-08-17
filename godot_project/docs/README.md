# Godot Project Docs

This folder contains documentation for the Godot MCP template project, including engine and testing docs.

- GODOT_ENGINE_DOCS/: Local copy of Godot Engine documentation
- GUT_DOCS/: Local copy of GUT testing framework documentation

## Everything in Its Home: Project Hygiene & Best Practices

A well-organized project is easier to maintain, scale, and collaborate on. Follow these guidelines to keep everything in its proper place:

- **Source Code**: All scripts, scenes, and assets belong in the `src/` and `scenes/` folders.
- **Addons & Plugins**: Place all third-party plugins in `addons/`, each in its own subfolder.
- **Documentation**: Keep all docs in the `docs/` folder, with subfolders for engine, testing, and plugin docs.
- **Tests**: Store all automated and manual tests in the `tests/` folder, organized by feature or module.
- **Data**: Use the `data/` folder for game data, configs, and resources.
- **MCP & Tools**: Workflow, style, and automation scripts live in the `MCP/` folder.
- **Personalization**: User preferences and style guides go in `Personal Style/`.
- **Version Control**: Commit only necessary files, use `.gitignore` for build artifacts and local configs.
- **Naming**: Use clear, consistent names for files and folders.
- **Readmes**: Every major folder should have a `README.md` explaining its purpose and contents.
- **Updates**: Regularly update plugins and docs using the provided automation tasks.

By following these practices, your project will remain clean, discoverable, and easy to work with for everyone.

---

## General Guidelines & Best Practices

- **Clear Folder Structure**: Group related files (e.g., `src/`, `scenes/`, `addons/`, `docs/`, `tests/`, `data/`).
- **Consistent Naming Conventions**: Use lowercase, hyphens, or underscores for files and folders. Name scripts and scenes after their main function or entity.
- **Documentation**: Keep docs up to date; document new features, changes, and workflows. Use changelogs for plugins and major components.
- **Version Control Hygiene**: Use `.gitignore` to exclude build artifacts, local configs, and sensitive data. Commit early, commit often, and write clear commit messages.
- **Automation**: Use tasks for updating plugins, syncing docs, and running tests. Automate repetitive tasks with scripts or CI/CD pipelines.
- **Testing**: Write tests for critical features and keep them in the `tests/` folder. Run tests before merging or deploying changes.
- **Dependency Management**: Track plugin and package versions. Regularly update dependencies and document changes.
- **Code Quality**: Follow a style guide (indentation, naming, comments). Use linters and formatters where possible.
- **Onboarding**: Provide a project overview and setup instructions in the main `README.md`. Document how to add new plugins, assets, or features.
- **Feedback & Review**: Encourage code reviews and feedback. Log changes and lessons learned for future reference.

---

## Workflow Improvements: Make It Easy to Improve

To keep your workflow agile and adaptable, use these strategies:

- **Quick Task Automation**: Add or update VS Code tasks for new build, test, or update routines.
- **Script Everything**: Use small scripts for repetitive actions (e.g., plugin updates, doc syncs, asset imports).
- **Document Improvements**: Log workflow changes and improvement ideas in a dedicated section or file (e.g., `LESSONS_LEARNED.md`).
- **Feedback Channels**: Encourage team members to suggest improvements and log feedback.
- **Modular Design**: Structure code and assets so new features or plugins can be added with minimal disruption.
- **Continuous Integration**: Use CI/CD pipelines to automate testing and deployment.
- **Regular Reviews**: Schedule periodic reviews of workflow and project structure to identify areas for improvement.

By making workflow improvements easy and visible, your project will stay efficient and ready for change.

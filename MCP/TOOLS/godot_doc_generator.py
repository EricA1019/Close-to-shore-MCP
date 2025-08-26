#!/usr/bin/env python3
"""
Godot Project Documentation Generator
Automatically generates documentation from GDScript files and project structure
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Any, Optional, Set

class GDScriptClass:
    def __init__(self, name: str, file_path: str):
        self.name = name
        self.file_path = file_path
        self.extends = ""
        self.class_name = ""
        self.description = ""
        self.properties: List[Dict[str, str]] = []
        self.methods: List[Dict[str, Any]] = []
        self.signals: List[Dict[str, str]] = []
        self.enums: List[Dict[str, Any]] = []
        self.constants: List[Dict[str, str]] = []

class ProjectDocumentationGenerator:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.classes: List[GDScriptClass] = []
        self.scenes: List[Dict[str, Any]] = []
        
        # Regex patterns for parsing GDScript
        self.patterns = {
            'class_name': re.compile(r'^class_name\s+(\w+)'),
            'extends': re.compile(r'^extends\s+(.+)'),
            'signal': re.compile(r'^signal\s+(\w+)(?:\(([^)]*)\))?'),
            'enum': re.compile(r'^enum\s+(\w+)?\s*\{([^}]*)\}'),
            'const': re.compile(r'^const\s+(\w+)\s*:\s*(\w+)\s*=\s*(.+)'),
            'var': re.compile(r'^(?:@export\s+)?var\s+(\w+)\s*:\s*(\w+)(?:\s*=\s*(.+))?'),
            'func': re.compile(r'^func\s+(\w+)\s*\(([^)]*)\)(?:\s*->\s*(\w+))?:'),
            'comment': re.compile(r'^\s*#\s*(.+)'),
            'doc_comment': re.compile(r'^\s*##\s*(.+)'),
        }
    
    def analyze_project(self) -> None:
        """Analyze the entire project structure"""
        print("Analyzing Godot project...")
        
        # Find and analyze all GDScript files
        gd_files = list(self.project_root.rglob("*.gd"))
        print(f"Found {len(gd_files)} GDScript files")
        
        for gd_file in gd_files:
            self._analyze_script_file(gd_file)
        
        # Find and catalog scene files
        scene_files = list(self.project_root.rglob("*.tscn"))
        print(f"Found {len(scene_files)} scene files")
        
        for scene_file in scene_files:
            self._analyze_scene_file(scene_file)
    
    def _analyze_script_file(self, file_path: Path) -> None:
        """Analyze a single GDScript file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            relative_path = str(file_path.relative_to(self.project_root))
            
            # Create class object
            gd_class = GDScriptClass(file_path.stem, relative_path)
            
            lines = content.split('\n')
            current_description = []
            
            i = 0
            while i < len(lines):
                line = lines[i].strip()
                
                # Skip empty lines
                if not line:
                    i += 1
                    continue
                
                # Collect documentation comments
                if self.patterns['doc_comment'].match(line):
                    match = self.patterns['doc_comment'].match(line)
                    if match:
                        current_description.append(match.group(1))
                    i += 1
                    continue
                
                # Parse class_name
                match = self.patterns['class_name'].match(line)
                if match:
                    gd_class.class_name = match.group(1)
                    if current_description:
                        gd_class.description = '\n'.join(current_description)
                        current_description = []
                    i += 1
                    continue
                
                # Parse extends
                match = self.patterns['extends'].match(line)
                if match:
                    gd_class.extends = match.group(1)
                    i += 1
                    continue
                
                # Parse signals
                match = self.patterns['signal'].match(line)
                if match:
                    signal_name = match.group(1)
                    signal_params = match.group(2) if match.group(2) else ""
                    description = '\n'.join(current_description) if current_description else ""
                    
                    gd_class.signals.append({
                        'name': signal_name,
                        'parameters': signal_params,
                        'description': description
                    })
                    current_description = []
                    i += 1
                    continue
                
                # Parse enums
                match = self.patterns['enum'].match(line)
                if match:
                    enum_name = match.group(1) if match.group(1) else "Anonymous"
                    enum_values = [v.strip() for v in match.group(2).split(',') if v.strip()]
                    description = '\n'.join(current_description) if current_description else ""
                    
                    gd_class.enums.append({
                        'name': enum_name,
                        'values': enum_values,
                        'description': description
                    })
                    current_description = []
                    i += 1
                    continue
                
                # Parse constants
                match = self.patterns['const'].match(line)
                if match:
                    const_name = match.group(1)
                    const_type = match.group(2)
                    const_value = match.group(3)
                    description = '\n'.join(current_description) if current_description else ""
                    
                    gd_class.constants.append({
                        'name': const_name,
                        'type': const_type,
                        'value': const_value,
                        'description': description
                    })
                    current_description = []
                    i += 1
                    continue
                
                # Parse variables
                match = self.patterns['var'].match(line)
                if match:
                    var_name = match.group(1)
                    var_type = match.group(2)
                    var_default = match.group(3) if match.group(3) else ""
                    description = '\n'.join(current_description) if current_description else ""
                    
                    gd_class.properties.append({
                        'name': var_name,
                        'type': var_type,
                        'default': var_default,
                        'description': description
                    })
                    current_description = []
                    i += 1
                    continue
                
                # Parse functions
                match = self.patterns['func'].match(line)
                if match:
                    func_name = match.group(1)
                    func_params = match.group(2)
                    func_return = match.group(3) if match.group(3) else "void"
                    description = '\n'.join(current_description) if current_description else ""
                    
                    # Parse function body for additional info
                    func_body = []
                    j = i + 1
                    indent_level = len(lines[i]) - len(lines[i].lstrip())
                    
                    while j < len(lines):
                        next_line = lines[j]
                        if next_line.strip() and len(next_line) - len(next_line.lstrip()) <= indent_level:
                            break
                        func_body.append(next_line)
                        j += 1
                    
                    gd_class.methods.append({
                        'name': func_name,
                        'parameters': func_params,
                        'return_type': func_return,
                        'description': description,
                        'body_lines': len(func_body)
                    })
                    current_description = []
                    i = j
                    continue
                
                # Regular comment (not documentation)
                if line.startswith('#'):
                    i += 1
                    continue
                
                # Clear accumulated description if we hit non-comment code
                current_description = []
                i += 1
            
            self.classes.append(gd_class)
            
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}")
    
    def _analyze_scene_file(self, file_path: Path) -> None:
        """Analyze a scene file"""
        try:
            relative_path = str(file_path.relative_to(self.project_root))
            
            # Basic scene info - would need full parser for detailed analysis
            self.scenes.append({
                'name': file_path.stem,
                'path': relative_path,
                'size': file_path.stat().st_size
            })
            
        except Exception as e:
            print(f"Error analyzing scene {file_path}: {e}")
    
    def generate_markdown_docs(self, output_dir: str = "docs") -> None:
        """Generate markdown documentation"""
        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)
        
        # Generate main index
        self._generate_index(output_path)
        
        # Generate class documentation
        classes_dir = output_path / "classes"
        classes_dir.mkdir(exist_ok=True)
        
        for gd_class in self.classes:
            self._generate_class_doc(gd_class, classes_dir)
        
        # Generate scenes documentation
        self._generate_scenes_doc(output_path)
        
        print(f"Documentation generated in {output_path}")
    
    def _generate_index(self, output_path: Path) -> None:
        """Generate main index.md"""
        content = f"""# {self.project_root.name} Documentation

## Project Overview

This documentation was automatically generated from the project source code.

## Classes ({len(self.classes)})

"""
        
        for gd_class in sorted(self.classes, key=lambda c: c.name):
            class_name = gd_class.class_name or gd_class.name
            content += f"- [{class_name}](classes/{gd_class.name}.md)\n"
        
        content += f"""
## Scenes ({len(self.scenes)})

"""
        
        for scene in sorted(self.scenes, key=lambda s: s['name']):
            content += f"- [{scene['name']}](scenes.md#{scene['name'].lower().replace(' ', '-')})\n"
        
        with open(output_path / "README.md", 'w') as f:
            f.write(content)
    
    def _generate_class_doc(self, gd_class: GDScriptClass, output_dir: Path) -> None:
        """Generate documentation for a single class"""
        class_name = gd_class.class_name or gd_class.name
        
        content = f"""# {class_name}

**File:** `{gd_class.file_path}`

"""
        
        if gd_class.extends:
            content += f"**Extends:** {gd_class.extends}\n\n"
        
        if gd_class.description:
            content += f"{gd_class.description}\n\n"
        
        # Constants
        if gd_class.constants:
            content += "## Constants\n\n"
            for const in gd_class.constants:
                content += f"### {const['name']}\n\n"
                content += f"**Type:** {const['type']}  \n"
                content += f"**Value:** `{const['value']}`\n\n"
                if const['description']:
                    content += f"{const['description']}\n\n"
        
        # Enums
        if gd_class.enums:
            content += "## Enums\n\n"
            for enum in gd_class.enums:
                content += f"### {enum['name']}\n\n"
                if enum['description']:
                    content += f"{enum['description']}\n\n"
                content += "```gdscript\n"
                for value in enum['values']:
                    content += f"{value}\n"
                content += "```\n\n"
        
        # Signals
        if gd_class.signals:
            content += "## Signals\n\n"
            for signal in gd_class.signals:
                content += f"### {signal['name']}\n\n"
                content += f"```gdscript\n{signal['name']}({signal['parameters']})\n```\n\n"
                if signal['description']:
                    content += f"{signal['description']}\n\n"
        
        # Properties
        if gd_class.properties:
            content += "## Properties\n\n"
            for prop in gd_class.properties:
                content += f"### {prop['name']}\n\n"
                content += f"**Type:** {prop['type']}\n\n"
                if prop['default']:
                    content += f"**Default:** `{prop['default']}`\n\n"
                if prop['description']:
                    content += f"{prop['description']}\n\n"
        
        # Methods
        if gd_class.methods:
            content += "## Methods\n\n"
            for method in gd_class.methods:
                content += f"### {method['name']}\n\n"
                content += f"```gdscript\n{method['name']}({method['parameters']}) -> {method['return_type']}\n```\n\n"
                if method['description']:
                    content += f"{method['description']}\n\n"
        
        with open(output_dir / f"{gd_class.name}.md", 'w') as f:
            f.write(content)
    
    def _generate_scenes_doc(self, output_path: Path) -> None:
        """Generate scenes documentation"""
        content = "# Scenes\n\n"
        
        for scene in sorted(self.scenes, key=lambda s: s['name']):
            content += f"## {scene['name']}\n\n"
            content += f"**File:** `{scene['path']}`\n\n"
            content += f"**Size:** {scene['size']} bytes\n\n"
        
        with open(output_path / "scenes.md", 'w') as f:
            f.write(content)
    
    def generate_json_docs(self, output_file: str = "project_docs.json") -> None:
        """Generate JSON documentation"""
        docs = {
            "project_name": self.project_root.name,
            "classes": [],
            "scenes": self.scenes
        }
        
        for gd_class in self.classes:
            class_doc = {
                "name": gd_class.class_name or gd_class.name,
                "file_path": gd_class.file_path,
                "extends": gd_class.extends,
                "description": gd_class.description,
                "constants": gd_class.constants,
                "enums": gd_class.enums,
                "signals": gd_class.signals,
                "properties": gd_class.properties,
                "methods": gd_class.methods
            }
            docs["classes"].append(class_doc)
        
        with open(output_file, 'w') as f:
            json.dump(docs, f, indent=2)
        
        print(f"JSON documentation saved to {output_file}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python godot_doc_generator.py <project_root> [--format markdown|json] [--output <path>]")
        sys.exit(1)
    
    project_root = sys.argv[1]
    output_format = "markdown"
    output_path = "docs"
    
    if "--format" in sys.argv:
        format_index = sys.argv.index("--format") + 1
        if format_index < len(sys.argv):
            output_format = sys.argv[format_index]
    
    if "--output" in sys.argv:
        output_index = sys.argv.index("--output") + 1
        if output_index < len(sys.argv):
            output_path = sys.argv[output_index]
    
    if not os.path.exists(project_root):
        print(f"Error: Project root '{project_root}' does not exist")
        sys.exit(1)
    
    generator = ProjectDocumentationGenerator(project_root)
    generator.analyze_project()
    
    if output_format == "markdown":
        generator.generate_markdown_docs(output_path)
    elif output_format == "json":
        generator.generate_json_docs(output_path)
    else:
        print(f"Unknown format: {output_format}")
        sys.exit(1)

if __name__ == "__main__":
    import sys
    main()

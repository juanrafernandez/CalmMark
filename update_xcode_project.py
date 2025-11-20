#!/usr/bin/env python3
"""
Script para actualizar las referencias del proyecto Xcode después de reorganizar archivos.
"""

import re
import sys

# Mapeo de archivos a sus nuevas ubicaciones
file_mappings = {
    # App
    "CalmMarkApp.swift": "App/CalmMarkApp.swift",
    "AppSettings.swift": "App/AppSettings.swift",

    # Models
    "CalmMarkDocument.swift": "Models/CalmMarkDocument.swift",
    "FileItem.swift": "Models/FileItem.swift",
    "OpenFile.swift": "Models/OpenFile.swift",

    # ViewModels
    "TabManager.swift": "ViewModels/TabManager.swift",
    "FileSystemManager.swift": "ViewModels/FileSystemManager.swift",

    # Views
    "ContentView.swift": "Views/ContentView.swift",
    "ProjectContentView.swift": "Views/Project/ProjectContentView.swift",
    "FileNavigatorView.swift": "Views/Project/FileNavigatorView.swift",
    "TabBarView.swift": "Views/Project/TabBarView.swift",
    "EditorView.swift": "Views/Editor/EditorView.swift",
    "MarkdownFormattingToolbar.swift": "Views/Editor/MarkdownFormattingToolbar.swift",
    "PreviewView.swift": "Views/Preview/PreviewView.swift",
    "ExportView.swift": "Views/Export/ExportView.swift",
    "PreferencesView.swift": "Views/Settings/PreferencesView.swift",
    "CommandTemplatesView.swift": "Views/Commands/CommandTemplatesView.swift",
    "OutlinePanelView.swift": "Views/Panels/OutlinePanelView.swift",
    "LogPanelView.swift": "Views/Panels/LogPanelView.swift",
    "SplitView.swift": "Views/Shared/SplitView.swift",
    "StatusBarView.swift": "Views/Shared/StatusBarView.swift",

    # Services
    "LogManager.swift": "Services/LogManager.swift",
    "CommandTemplateManager.swift": "Services/CommandTemplateManager.swift",
    "ScrollSyncManager.swift": "Services/ScrollSyncManager.swift",
    "HotExitManager.swift": "Services/HotExitManager.swift",
    "Protocols.swift": "Services/Protocols.swift",

    # Utilities
    "MarkdownRenderer.swift": "Utilities/Markdown/MarkdownRenderer.swift",
    "StylesheetGenerator.swift": "Utilities/Markdown/StylesheetGenerator.swift",
    "DocumentAnalyzer.swift": "Utilities/DocumentAnalyzer.swift",
    "ExportManager.swift": "Utilities/ExportManager.swift",
}

def update_project_file(content):
    """Actualiza las rutas en el contenido del project.pbxproj"""

    for old_name, new_path in file_mappings.items():
        # Actualizar referencias de path
        # Busca: path = "FileName.swift"
        # Reemplaza con: path = "New/Path/FileName.swift"
        pattern = rf'path = {old_name};'
        replacement = f'path = {new_path};'
        content = content.replace(pattern, replacement)

        # También buscar sin comillas
        pattern = rf'path = "{old_name}";'
        replacement = f'path = "{new_path}";'
        content = content.replace(pattern, replacement)

    return content

def main():
    project_file = "/home/user/CalmMark/CalmMark/CalmMark.xcodeproj/project.pbxproj"

    print("Leyendo project.pbxproj...")
    with open(project_file, 'r') as f:
        content = f.read()

    print("Actualizando rutas...")
    updated_content = update_project_file(content)

    print("Guardando project.pbxproj...")
    with open(project_file, 'w') as f:
        f.write(updated_content)

    print("✅ Proyecto actualizado exitosamente")
    print(f"   Archivos actualizados: {len(file_mappings)}")

if __name__ == "__main__":
    main()

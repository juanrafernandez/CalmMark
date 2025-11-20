#!/usr/bin/env python3
"""
Script para reorganizar los grupos en project.pbxproj para reflejar la nueva estructura de carpetas.
"""

import re

# Estructura de grupos deseada
group_structure = """		AA0001001A000003 /* CalmMark */ = {
			isa = PBXGroup;
			children = (
				GROUPAPP00000001 /* App */,
				GROUPMODEL000001 /* Models */,
				GROUPVIEWM000001 /* ViewModels */,
				GROUPVIEWS000001 /* Views */,
				GROUPSERVICES001 /* Services */,
				GROUPUTILS000001 /* Utilities */,
				AA0002001A000002 /* Assets.xcassets */,
				AA0003001A000002 /* Info.plist */,
				AA0003011A000002 /* CalmMark.entitlements */,
				AA0002001A000003 /* Preview Content */,
			);
			path = CalmMark;
			sourceTree = "<group>";
		};
		GROUPAPP00000001 /* App */ = {
			isa = PBXGroup;
			children = (
				AA0001001A000002 /* CalmMarkApp.swift */,
				AA0001061A000002 /* AppSettings.swift */,
			);
			path = App;
			sourceTree = "<group>";
		};
		GROUPMODEL000001 /* Models */ = {
			isa = PBXGroup;
			children = (
				AA0001011A000002 /* CalmMarkDocument.swift */,
				NEWFILEIT0000001 /* FileItem.swift */,
				NEWFILEOPN000001 /* OpenFile.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		};
		GROUPVIEWM000001 /* ViewModels */ = {
			isa = PBXGroup;
			children = (
				AA0001131A000002 /* TabManager.swift */,
				AA0001111A000002 /* FileSystemManager.swift */,
			);
			path = ViewModels;
			sourceTree = "<group>";
		};
		GROUPVIEWS000001 /* Views */ = {
			isa = PBXGroup;
			children = (
				AA0001021A000002 /* ContentView.swift */,
				GROUPPROJECT0001 /* Project */,
				GROUPEDITOR0001 /* Editor */,
				GROUPPREVIEW0001 /* Preview */,
				GROUPEXPORT0001 /* Export */,
				GROUPSETTINGS001 /* Settings */,
				GROUPCOMMANDS001 /* Commands */,
				GROUPPANELS00001 /* Panels */,
				GROUPSHARED00001 /* Shared */,
			);
			path = Views;
			sourceTree = "<group>";
		};
		GROUPPROJECT0001 /* Project */ = {
			isa = PBXGroup;
			children = (
				AA0001151A000002 /* ProjectContentView.swift */,
				AA0001121A000002 /* FileNavigatorView.swift */,
				AA0001141A000002 /* TabBarView.swift */,
			);
			path = Project;
			sourceTree = "<group>";
		};
		GROUPEDITOR0001 /* Editor */ = {
			isa = PBXGroup;
			children = (
				AA0001031A000002 /* EditorView.swift */,
				35782CF02EC8EDAD00427117 /* MarkdownFormattingToolbar.swift */,
			);
			path = Editor;
			sourceTree = "<group>";
		};
		GROUPPREVIEW0001 /* Preview */ = {
			isa = PBXGroup;
			children = (
				AA0001041A000002 /* PreviewView.swift */,
			);
			path = Preview;
			sourceTree = "<group>";
		};
		GROUPEXPORT0001 /* Export */ = {
			isa = PBXGroup;
			children = (
				AA0001101A000002 /* ExportView.swift */,
			);
			path = Export;
			sourceTree = "<group>";
		};
		GROUPSETTINGS001 /* Settings */ = {
			isa = PBXGroup;
			children = (
				AA0001051A000002 /* PreferencesView.swift */,
			);
			path = Settings;
			sourceTree = "<group>";
		};
		GROUPCOMMANDS001 /* Commands */ = {
			isa = PBXGroup;
			children = (
				AA0001171A000002 /* CommandTemplatesView.swift */,
			);
			path = Commands;
			sourceTree = "<group>";
		};
		GROUPPANELS00001 /* Panels */ = {
			isa = PBXGroup;
			children = (
				AA0001191A000002 /* OutlinePanelView.swift */,
				35782CF22EC8F5D600427117 /* LogPanelView.swift */,
			);
			path = Panels;
			sourceTree = "<group>";
		};
		GROUPSHARED00001 /* Shared */ = {
			isa = PBXGroup;
			children = (
				35782CF92EC930E900427117 /* SplitView.swift */,
				AA0001201A000002 /* StatusBarView.swift */,
			);
			path = Shared;
			sourceTree = "<group>";
		};
		GROUPSERVICES001 /* Services */ = {
			isa = PBXGroup;
			children = (
				35782CF42EC8F5DD00427117 /* LogManager.swift */,
				AA0001161A000002 /* CommandTemplateManager.swift */,
				35782D052ECB971600427117 /* ScrollSyncManager.swift */,
				NEWHOTEX0000001 /* HotExitManager.swift */,
				NEWPROTO0000001 /* Protocols.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		};
		GROUPUTILS000001 /* Utilities */ = {
			isa = PBXGroup;
			children = (
				AA0001181A000002 /* DocumentAnalyzer.swift */,
				AA0001091A000002 /* ExportManager.swift */,
				GROUPMARKDOWN001 /* Markdown */,
			);
			path = Utilities;
			sourceTree = "<group>";
		};
		GROUPMARKDOWN001 /* Markdown */ = {
			isa = PBXGroup;
			children = (
				AA0001071A000002 /* MarkdownRenderer.swift */,
				AA0001081A000002 /* StylesheetGenerator.swift */,
			);
			path = Markdown;
			sourceTree = "<group>";
		};"""

# Nuevas referencias de archivos
new_file_references = """		NEWFILEIT0000001 /* FileItem.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Models/FileItem.swift; sourceTree = "<group>"; };
		NEWFILEOPN000001 /* OpenFile.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Models/OpenFile.swift; sourceTree = "<group>"; };
		NEWHOTEX0000001 /* HotExitManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Services/HotExitManager.swift; sourceTree = "<group>"; };
		NEWPROTO0000001 /* Protocols.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Services/Protocols.swift; sourceTree = "<group>"; };"""

# Nuevos build files
new_build_files = """		NEWFILEIT0000002 /* FileItem.swift in Sources */ = {isa = PBXBuildFile; fileRef = NEWFILEIT0000001 /* FileItem.swift */; };
		NEWFILEOPN000002 /* OpenFile.swift in Sources */ = {isa = PBXBuildFile; fileRef = NEWFILEOPN000001 /* OpenFile.swift */; };
		NEWHOTEX0000002 /* HotExitManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = NEWHOTEX0000001 /* HotExitManager.swift */; };
		NEWPROTO0000002 /* Protocols.swift in Sources */ = {isa = PBXBuildFile; fileRef = NEWPROTO0000001 /* Protocols.swift */; };"""

def main():
    project_file = "/home/user/CalmMark/CalmMark/CalmMark.xcodeproj/project.pbxproj"

    print("Leyendo project.pbxproj...")
    with open(project_file, 'r') as f:
        content = f.read()

    # 1. Añadir nuevas referencias de archivos
    print("Añadiendo nuevas referencias de archivos...")
    file_ref_end = content.find("/* End PBXFileReference section */")
    content = content[:file_ref_end] + new_file_references + "\n" + content[file_ref_end:]

    # 2. Añadir nuevos build files
    print("Añadiendo nuevos build files...")
    build_file_end = content.find("/* End PBXBuildFile section */")
    content = content[:build_file_end] + new_build_files + "\n" + content[build_file_end:]

    # 3. Reemplazar la sección de grupos
    print("Reorganizando grupos...")
    # Encontrar el inicio del grupo CalmMark
    group_start = content.find("AA0001001A000003 /* CalmMark */ = {")
    if group_start == -1:
        print("❌ No se encontró el grupo CalmMark")
        return

    # Encontrar el final de todos los grupos (antes de /* End PBXGroup section */)
    # Primero encontrar dónde termina el grupo Components
    components_end = content.find("35782CF72EC9234E00427117 /* Components */ = {")
    if components_end != -1:
        # Encontrar el cierre de ese grupo
        brace_count = 0
        pos = components_end
        while pos < len(content):
            if content[pos] == '{':
                brace_count += 1
            elif content[pos] == '}':
                brace_count -= 1
                if brace_count == 0:
                    # Encontrar el final de la línea
                    newline_pos = content.find('\n', pos)
                    # Eliminar el grupo Components
                    components_section_end = newline_pos + 1
                    content = content[:components_end] + content[components_section_end:]
                    break
            pos += 1

    # Ahora encontrar de nuevo el grupo CalmMark después de eliminar Components
    group_start = content.find("AA0001001A000003 /* CalmMark */ = {")

    # Encontrar el final de la sección de grupos
    group_section_end = content.find("/* End PBXGroup section */", group_start)

    # Encontrar dónde termina el último grupo antes de End PBXGroup
    # Buscar hacia atrás desde group_section_end hasta encontrar "};"
    temp_pos = group_section_end - 1
    while temp_pos > group_start:
        if content[temp_pos:temp_pos+2] == '};':
            group_end = temp_pos + 3  # Incluir el newline después de };
            break
        temp_pos -= 1

    # Reemplazar todo desde el grupo CalmMark hasta el final de los grupos
    content = content[:group_start] + group_structure + "\n" + content[group_end:]

    # 4. Añadir los nuevos archivos a la fase de compilación
    print("Añadiendo nuevos archivos a Sources...")
    sources_section = content.find("AA0000001A000007 /* Sources */ = {")
    if sources_section != -1:
        # Encontrar la lista de files en Sources
        files_start = content.find("files = (", sources_section)
        files_end = content.find(");", files_start)

        # Añadir las nuevas referencias antes del cierre
        new_sources = """\n\t\t\t\tNEWFILEIT0000002 /* FileItem.swift in Sources */,
				NEWFILEOPN000002 /* OpenFile.swift in Sources */,
				NEWHOTEX0000002 /* HotExitManager.swift in Sources */,
				NEWPROTO0000002 /* Protocols.swift in Sources */,"""

        content = content[:files_end] + new_sources + "\n\t\t\t" + content[files_end:]

    print("Guardando project.pbxproj...")
    with open(project_file, 'w') as f:
        f.write(content)

    print("✅ Proyecto reorganizado exitosamente")

if __name__ == "__main__":
    main()

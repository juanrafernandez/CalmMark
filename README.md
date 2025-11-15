# CalmMark 🍃

Un editor de Markdown minimalista, elegante y nativo para macOS que proporciona una experiencia de escritura tranquila y enfocada.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

---

## ✨ Características Principales

### 📁 Modo Proyecto con Sidebar
- **Navegación de archivos** estilo Xcode con tree view jerárquico
- **Abrir carpetas** completas y trabajar con múltiples archivos (`⌘⇧O`)
- **Sidebar colapsable** con toggle rápido (`⌘0`)
- **Iconos inteligentes** que identifican tipos de archivos
- **Detección automática** de archivos de comandos IA (`.claude/commands/*.md`)

### 📑 Sistema de Pestañas
- **Múltiples archivos abiertos** simultáneamente
- **Tab bar horizontal** con indicadores de cambios no guardados
- **Cerrar tabs** individualmente (`⌘W`) o todos a la vez (`⌘⌥W`)
- **Guardar individual** (`⌘S`) o guardar todos (`⌘⌥S`)
- **Navegación rápida** entre archivos abiertos

### 🤖 Plantillas de Comandos para Agentes IA
- **10+ plantillas profesionales** para Claude Code y otros agentes IA
- **Categorías organizadas**: Code, Documentation, Testing, Git, Custom
- **Variables inteligentes** con sintaxis `{{variable}}`
- **Creación asistida** con preview en tiempo real
- **Detección automática** de archivos `.claude/commands/*.md`
- **Iconografía especial** para comandos (terminal púrpura ⚡)

### 📝 Edición Markdown
- **Editor potente** con resaltado de sintaxis en tiempo real
- **Fuente monoespaciada** (SF Mono) optimizada para escritura de código y texto
- **Auto-pares** de paréntesis, corchetes y comillas
- **Ajuste de línea** configurable
- **Números de línea** opcionales

### 👁️ Vista Previa en Tiempo Real
- **Renderizado HTML instantáneo** de tu Markdown
- **CSS elegante** con soporte para modo claro y oscuro
- **Scroll suave** y rendimiento optimizado
- **Vista previa en vivo** mientras escribes

### 🎨 Tres Modos de Visualización
1. **Solo Editor** - Enfoque completo en la escritura (`⌘1`)
2. **Solo Vista Previa** - Ver el resultado final (`⌘2`)
3. **Vista Dividida** - Editor y preview lado a lado (`⌘3`)

### 🎭 Temas y Apariencia
- **Modo claro/oscuro** automático que sigue el sistema
- **Personalización de fuentes** (editor y preview)
- **Ancho máximo de contenido** configurable para mejor legibilidad
- **Diseño minimalista** al estilo macOS moderno

### 📤 Exportación
- **HTML** con CSS embebido para visualización standalone (`⌘⇧E`)
- **PDF** de alta calidad para impresión o distribución (`⌘⇧P`)

### ⚙️ Preferencias Completas
- **Apariencia**: Tema, tamaños de fuente, ancho de contenido
- **Editor**: Números de línea, resaltado, auto-pares
- **Markdown**: Habilitar extensiones como tablas y task lists

---

## 🚀 Inicio Rápido

### Requisitos
- **macOS 14.0 (Sonoma)** o superior
- **Xcode 15.0** o superior
- **Swift 5.9** o superior

### Compilación e Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/CalmMark.git
   cd CalmMark
   ```

2. **Abrir en Xcode**
   ```bash
   open CalmMark/CalmMark.xcodeproj
   ```

3. **Compilar y ejecutar**
   - Selecciona el scheme `CalmMark`
   - Presiona `⌘R` para compilar y ejecutar
   - O usa el menú: `Product > Run`

4. **Crear un build de distribución**
   - Menú: `Product > Archive`
   - Luego: `Distribute App > Copy App`

---

## 📖 Uso

### Modo Proyecto

#### Abrir Carpeta
- `⌘⇧O` - Abrir carpeta/proyecto
- Haz clic en "Open Folder" en la pantalla de bienvenida
- El sidebar mostrará la estructura de archivos completa

#### Sidebar
- `⌘0` - Toggle mostrar/ocultar sidebar
- Click en carpetas para expandir/contraer
- Click en archivos Markdown para abrirlos en pestañas
- Iconos especiales para archivos de comandos IA (⚡)

#### Tabs (Pestañas)
- `⌘W` - Cerrar pestaña activa
- `⌘⌥W` - Cerrar todas las pestañas
- Click en tabs para cambiar entre archivos
- Los tabs muestran un punto (•) cuando hay cambios sin guardar

#### Comandos IA
- Click en el icono del terminal (⌘) en el toolbar
- Selecciona una categoría y plantilla
- Personaliza el nombre del archivo
- Click en "Create Command" para generar
- Ver [AI_COMMANDS.md](AI_COMMANDS.md) para guía completa

### Modo Documento (Archivo Individual)

#### Abrir Documentos
- `⌘O` - Abrir archivo Markdown existente
- `⌘N` - Crear nuevo documento
- `⌘S` - Guardar documento
- `⌘⌥S` - Guardar todos los archivos abiertos
- `⌘⇧S` - Guardar como...

### Navegación entre Vistas
- `⌘1` - Modo solo editor
- `⌘2` - Modo solo vista previa
- `⌘3` - Modo vista dividida

### Exportación
- `⌘⇧E` - Exportar como HTML
- `⌘⇧P` - Exportar como PDF

### Preferencias
- `⌘,` - Abrir ventana de preferencias

---

## 🏗️ Arquitectura del Proyecto

```
CalmMark/
├── CalmMark.xcodeproj/            # Proyecto Xcode
│   ├── project.pbxproj
│   └── xcshareddata/
└── CalmMark/                       # Código fuente
    ├── CalmMarkApp.swift           # Punto de entrada de la app
    ├── CalmMarkDocument.swift      # Modelo de documento
    ├── ContentView.swift           # Vista principal (modo documento)
    ├── ProjectContentView.swift   # Vista principal (modo proyecto) ✨ NUEVO
    ├── EditorView.swift            # Editor de texto con sintaxis
    ├── PreviewView.swift           # Vista previa WebView
    ├── PreferencesView.swift       # Ventana de preferencias
    ├── ExportView.swift            # Diálogo de exportación
    ├── AppSettings.swift           # Configuración global
    ├── FileSystemManager.swift     # Gestor de sistema de archivos ✨ NUEVO
    ├── FileNavigatorView.swift     # Sidebar de navegación ✨ NUEVO
    ├── TabManager.swift            # Gestor de pestañas ✨ NUEVO
    ├── TabBarView.swift            # Barra de pestañas ✨ NUEVO
    ├── CommandTemplateManager.swift # Plantillas de comandos IA ✨ NUEVO
    ├── CommandTemplatesView.swift  # Vista de plantillas ✨ NUEVO
    ├── MarkdownRenderer.swift      # Motor de renderizado MD→HTML
    ├── StylesheetGenerator.swift   # Generador de CSS
    ├── ExportManager.swift         # Gestión de exportaciones
    ├── Assets.xcassets/            # Recursos e iconos
    ├── Info.plist                  # Configuración de la app
    └── CalmMark.entitlements       # Permisos de sandbox
```

---

## 🎯 Roadmap Futuro (v2.0+)

### ✅ Completado (v1.5)

- [x] **Sidebar de navegación** - Tree view estilo Xcode
- [x] **Abrir carpetas** - Modo proyecto completo
- [x] **Pestañas múltiples** - Editar varios documentos simultáneamente
- [x] **Plantillas de comandos IA** - 10+ templates para Claude Code

### 🔜 Próximas Características

- [ ] **Búsqueda y reemplazo** (`⌘F`) con highlight
- [ ] **Búsqueda en proyecto** - Find in files
- [ ] **Outline de headings** - Navegación rápida por secciones
- [ ] **Modo Zen/Focus** - Escritura sin distracciones
- [ ] **Resaltado avanzado** similar a VSCode con TreeSitter
- [ ] **Sincronización iCloud** - Documentos en la nube
- [ ] **Extensión QuickLook** - Preview en Finder
- [ ] **Themes personalizables** - Crear tus propios estilos
- [ ] **Snippets** - Fragmentos de código reutilizables
- [ ] **Estadísticas** - Contador de palabras, tiempo de lectura
- [ ] **Soporte para tablas** con editor visual
- [ ] **Diagramas Mermaid** - Renderizado de gráficos
- [ ] **Math (LaTeX)** - Ecuaciones matemáticas
- [ ] **Git integration** - Ver cambios inline
- [ ] **Variables en plantillas** - Auto-completion para `{{variables}}`

---

## 🧩 Sintaxis Markdown Soportada

CalmMark soporta la sintaxis Markdown estándar:

### Encabezados
```markdown
# H1
## H2
### H3
#### H4
##### H5
###### H6
```

### Énfasis
```markdown
**Negrita** o __Negrita__
*Cursiva* o _Cursiva_
`Código inline`
```

### Listas
```markdown
- Item sin orden
* Otro item
+ Otro más

1. Item ordenado
2. Segundo item
```

### Enlaces e Imágenes
```markdown
[Texto del enlace](https://url.com)
![Texto alternativo](ruta/imagen.png)
```

### Bloques de Código
````markdown
```swift
func hola() {
    print("Hola, mundo!")
}
```
````

### Citas
```markdown
> Esta es una cita
> que puede tener múltiples líneas
```

### Líneas Horizontales
```markdown
---
***
```

---

## 🛠️ Tecnologías Utilizadas

- **Swift 5.9** - Lenguaje de programación
- **SwiftUI** - Framework de interfaz de usuario
- **AppKit** - Para componentes nativos (NSTextView, WKWebView)
- **WebKit** - Renderizado de HTML/CSS
- **UserDefaults** - Persistencia de preferencias
- **DocumentGroup** - Manejo de documentos nativo

---

## 🤝 Contribuir

Las contribuciones son bienvenidas! Si quieres contribuir:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📝 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo `LICENSE` para más detalles.

---

## 👤 Autor

Desarrollado con ❤️ para la comunidad macOS

---

## 🙏 Agradecimientos

- Inspirado en aplicaciones como iA Writer, Bear y Ulysses
- Diseño siguiendo las Human Interface Guidelines de Apple
- Comunidad de desarrolladores Swift y SwiftUI

---

## 📸 Screenshots

*(Agrega capturas de pantalla aquí cuando tengas la app compilada)*

### Editor con Sintaxis
![Editor](docs/screenshots/editor.png)

### Vista Previa
![Preview](docs/screenshots/preview.png)

### Vista Dividida
![Split View](docs/screenshots/split.png)

### Preferencias
![Preferences](docs/screenshots/preferences.png)

---

## 🐛 Reportar Bugs

Si encuentras un bug o tienes una sugerencia:

1. Revisa si ya existe un issue similar
2. Si no existe, crea uno nuevo con:
   - Descripción clara del problema
   - Pasos para reproducirlo
   - Versión de macOS y CalmMark
   - Screenshots si es posible

---

## ❓ FAQ

**P: ¿Por qué CalmMark en lugar de otras apps?**
R: CalmMark es completamente gratuito, open source, nativo de macOS, y enfocado en simplicidad y rendimiento.

**P: ¿Funcionará en versiones anteriores de macOS?**
R: La versión actual requiere macOS 14.0+, pero puedes modificar el deployment target en Xcode para versiones anteriores (puede requerir ajustes en el código).

**P: ¿Habrá versión para iOS/iPadOS?**
R: Está en el roadmap! El código está diseñado con SwiftUI para facilitar la portabilidad.

**P: ¿Puedo personalizar los estilos de preview?**
R: En la versión actual los estilos son fijos pero elegantes. El soporte para themes personalizables está planificado para v2.0.

---

**¡Disfruta escribiendo con CalmMark!** 🍃✨

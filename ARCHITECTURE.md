# Arquitectura de CalmMark

Este documento describe la arquitectura y organización del proyecto CalmMark.

## Estructura del Proyecto

```
CalmMark/CalmMark/
├── App/                          # Configuración de la aplicación
│   ├── CalmMarkApp.swift        # Entry point, AppDelegate
│   └── AppSettings.swift        # Settings globales con @AppStorage
│
├── Models/                       # Modelos de datos
│   ├── OpenFile.swift           # Modelo de archivo abierto en tab
│   ├── FileItem.swift           # Modelo de ítem del sistema de archivos
│   └── CalmMarkDocument.swift   # Documento para modo single-file
│
├── ViewModels/                   # Lógica de negocio (MVVM)
│   ├── TabManager.swift         # Gestión de tabs y archivos abiertos
│   └── FileSystemManager.swift  # Operaciones del sistema de archivos
│
├── Views/                        # Componentes de UI
│   ├── Project/                 # Vistas del modo proyecto
│   │   ├── ProjectContentView.swift
│   │   ├── FileNavigatorView.swift
│   │   └── TabBarView.swift
│   ├── Editor/                  # Editor Markdown
│   │   ├── EditorView.swift
│   │   └── MarkdownFormattingToolbar.swift
│   ├── Preview/                 # Vista previa
│   │   └── PreviewView.swift
│   ├── Export/                  # Exportación
│   │   └── ExportView.swift
│   ├── Settings/                # Preferencias
│   │   └── PreferencesView.swift
│   ├── Commands/                # Comandos AI
│   │   └── CommandTemplatesView.swift
│   ├── Panels/                  # Paneles laterales
│   │   ├── OutlinePanelView.swift
│   │   └── LogPanelView.swift
│   ├── Shared/                  # Componentes compartidos
│   │   ├── SplitView.swift
│   │   └── StatusBarView.swift
│   └── ContentView.swift        # Vista para modo single-file
│
├── Services/                     # Servicios compartidos
│   ├── Protocols.swift          # Protocolos de servicios
│   ├── HotExitManager.swift     # Auto-save de contenido sin guardar
│   ├── LogManager.swift         # Sistema de logging
│   ├── ScrollSyncManager.swift  # Sincronización de scroll
│   └── CommandTemplateManager.swift # Plantillas de comandos AI
│
└── Utilities/                    # Utilidades y helpers
    ├── Markdown/
    │   ├── MarkdownRenderer.swift
    │   └── StylesheetGenerator.swift
    ├── DocumentAnalyzer.swift
    └── ExportManager.swift
```

## Patrones de Arquitectura

### MVVM (Model-View-ViewModel)

- **Models**: `OpenFile`, `FileItem`, `CalmMarkDocument`
  - Datos puros sin lógica de negocio
  - Conforman `Identifiable`, `ObservableObject`, `Equatable`

- **ViewModels**: `TabManager`, `FileSystemManager`
  - Lógica de negocio
  - `ObservableObject` con `@Published` properties
  - Intermediarios entre Models y Views

- **Views**: SwiftUI views organizadas por funcionalidad
  - UI reactiva mediante bindings
  - Observan ViewModels con `@ObservedObject` o `@StateObject`

### Singleton Pattern

Servicios compartidos globalmente:
- `AppSettings.shared` - Configuración global
- `LogManager.shared` - Logging
- `HotExitManager.shared` - Hot exit cache
- `ScrollSyncManager.shared` - Sincronización de scroll
- `CommandTemplateManager.shared` - Plantillas de comandos

### Service Protocols

Protocolos definidos para mejorar testabilidad (ver `Services/Protocols.swift`):
- `HotExitService` - Interfaz para hot exit
- `LoggingService` - Interfaz para logging
- `TemplateService` - Interfaz para plantillas

## Gestión de Estado

### SwiftUI Native State Management

1. **@Published Properties** (ObservableObject)
   - `TabManager`: `openFiles`, `activeFile`
   - `FileSystemManager`: `rootFolder`, `selectedFile`
   - `OpenFile`: `content`, `isDirty`, `isNew`

2. **@AppStorage** (UserDefaults-backed)
   - Preferencias de apariencia
   - Configuración del editor
   - Opciones de Markdown

3. **UserDefaults** (Persistencia adicional)
   - Hot Exit cache
   - Security-scoped bookmarks

4. **NotificationCenter** (Comunicación cross-component)
   - `.changeViewMode`, `.exportHTML`, `.exportPDF`
   - `.saveActiveFile`, `.saveAllFiles`
   - `.closeActiveTab`, `.closeAllTabs`
   - etc.

## Flujo de Datos

```
User Interaction
      ↓
   View (SwiftUI)
      ↓
   ViewModel (ObservableObject)
      ↓
   Service / Manager
      ↓
   Model (Data)
      ↓
   File System / UserDefaults
```

## Características Principales

### 1. Dual Mode Operation
- **Project Mode**: Carpeta con sidebar + múltiples tabs
- **Document Mode**: Archivo individual

### 2. Hot Exit
- Auto-save de contenido sin guardar en UserDefaults
- Restauración automática al reabrir archivos
- Limpieza cuando se guarda o descarta

### 3. Security-Scoped Bookmarks
- Acceso persistente a carpetas en macOS Sandbox
- Restauración automática de última carpeta abierta

### 4. Logging System
- Niveles: debug, info, warning, error, success
- Contextos para filtrado
- Panel de logs UI integrado

### 5. AI Commands Integration
- Plantillas predefinidas para Claude Code
- Detección automática de `.claude/commands/*.md`
- Sistema de variables `{{variable}}`

## Mejoras Implementadas

### ✅ Reorganización de Carpetas
- Arquitectura clara MVVM
- Separación por funcionalidad
- Fácil navegación

### ✅ Extracción de Modelos
- Archivos separados para cada modelo
- Responsabilidad única

### ✅ Consolidación de Logging
- Reemplazo de `print()` por `LogManager`
- Logging consistente

### ✅ Protocolos de Servicios
- Interfaces para servicios principales
- Mejora testabilidad y DIP

## Próximas Mejoras Recomendadas

### 🟡 Prioridad Media
1. Reducir uso de NotificationCenter
   - Crear `AppCoordinator` o `CommandHandler`
   - Usar más `@EnvironmentObject`

2. Inyección de dependencias
   - Reducir dependencia de singletons
   - Constructor injection para ViewModels

### 🟢 Prioridad Baja
3. Extraer lógica de UI de ViewModels
   - Coordinadores para navegación
   - Diálogos reutilizables

4. Tests unitarios
   - Aprovechar protocolos nuevos
   - Mock implementations

## Convenciones de Código

1. **Nomenclatura**
   - Views: `*View.swift`
   - ViewModels: `*Manager.swift`
   - Services: `*Manager.swift` o `*Service.swift`

2. **Organización de archivos**
   - MARK comments para secciones
   - Grupos lógicos en archivos

3. **Logging**
   - Usar `LogManager.shared.log()`
   - Especificar nivel y contexto
   - Evitar `print()` directo

## Referencias

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftUI Data Flow](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
- [MVVM Pattern](https://en.wikipedia.org/wiki/Model–view–viewmodel)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)

# 🤖 AI Commands - Guía Completa

CalmMark incluye soporte avanzado para **comandos de agentes IA** (como Claude Code), facilitando la creación y gestión de archivos de comandos en `.claude/commands/`.

---

## 📁 ¿Qué son los Comandos de Agentes IA?

Los comandos de agentes IA son archivos Markdown que contienen instrucciones específicas para agentes como Claude. Estos archivos:

- Se almacenan en `.claude/commands/` en tu proyecto
- Tienen extensión `.md`
- Contienen plantillas con variables (`{{variable}}`)
- Se ejecutan mediante slash commands (ej: `/review`)
- Permiten automatizar tareas de desarrollo comunes

---

## ✨ Características de CalmMark para Comandos IA

### 🎯 Detección Automática

CalmMark detecta automáticamente archivos de comandos y los marca con:
- **Icono especial**: Terminal púrpura (⌘)
- **Badge distintivo**: Indicador visual en el sidebar
- **Agrupación**: Fácil de encontrar en la navegación

### 📝 Plantillas Predefinidas

CalmMark incluye 10+ plantillas profesionales para:

- **Código**
  - Code Review
  - Explicar Código
  - Refactorizar Código
  - Optimizar Rendimiento
  - Fix Bug

- **Documentación**
  - Escribir Documentación
  - API Documentation
  - Generar README

- **Testing**
  - Generar Tests Unitarios

- **Git**
  - Generar Commit Messages

- **Custom**
  - Plantillas personalizadas

---

## 🚀 Cómo Usar los Comandos IA en CalmMark

### 1. Abrir una Carpeta/Proyecto

```
File → Open Folder (⌘⇧O)
```

O usa el botón "Open Folder" en la pantalla de bienvenida.

### 2. Acceder a las Plantillas

Hay tres formas de acceder a las plantillas de comandos:

**Opción A: Desde el Toolbar**
- Haz clic en el icono del terminal (⌘) en la barra superior

**Opción B: Desde el Welcome Screen**
- Haz clic en "AI Commands" en la pantalla de bienvenida

**Opción C: Desde el Sidebar**
- Haz clic en el menú `⋯` → "New File..."
- Navega a `.claude/commands/`

### 3. Seleccionar una Plantilla

1. En el panel de plantillas, selecciona una categoría
2. Haz clic en la plantilla que deseas usar
3. Revisa el preview del contenido
4. Modifica el nombre del archivo si deseas
5. Haz clic en "Create Command"

### 4. Personalizar el Comando

El archivo creado contendrá variables en formato `{{variable}}`. Por ejemplo:

```markdown
# Code Review

Review the following code:

{{code}}

Provide feedback on:
- Code quality and readability
- Potential bugs or issues

Language: {{language}}
```

Reemplaza las variables con tus valores:

```markdown
# Code Review

Review the following code:

\```swift
func fetchData() async throws -> Data {
    let url = URL(string: "https://api.example.com/data")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
\```

Provide feedback on:
- Code quality and readability
- Potential bugs or issues

Language: Swift
```

### 5. Ejecutar el Comando

En Claude Code (CLI), ejecuta el comando con:

```bash
/review  # Ejecuta .claude/commands/review.md
```

---

## 📚 Plantillas Disponibles

### Code Review (`review.md`)

Revisa código para calidad, bugs y mejores prácticas.

**Variables:**
- `{{code}}` - Código a revisar

**Ejemplo de uso:**
```markdown
{{code}} → Tu código Swift/Python/etc
```

---

### Generate Tests (`generate-tests.md`)

Genera tests unitarios comprehensivos.

**Variables:**
- `{{code}}` - Código para testear
- `{{language}}` - Lenguaje de programación
- `{{framework}}` - Framework de testing (XCTest, Jest, etc)

---

### Explain Code (`explain.md`)

Obtén explicaciones detalladas de código complejo.

**Variables:**
- `{{code}}` - Código a explicar
- `{{level}}` - Nivel de audiencia (beginner/intermediate/advanced)

---

### Refactor Code (`refactor.md`)

Sugerencias de refactorización para mejorar código.

**Variables:**
- `{{code}}` - Código a refactorizar
- `{{improvements}}` - Áreas a mejorar (performance, readability, etc)
- `{{language}}` - Lenguaje

---

### Write Documentation (`document.md`)

Genera documentación profesional.

**Variables:**
- `{{code}}` - Código a documentar
- `{{style}}` - Estilo de documentación (JSDoc, Javadoc, etc)

---

### Generate Commit Message (`commit-message.md`)

Crea mensajes de commit convencionales.

**Variables:**
- `{{diff}}` - Diferencias de git

**Tip:** Ejecuta `git diff` y pega el resultado

---

### Fix Bug (`fix-bug.md`)

Analiza y corrige bugs.

**Variables:**
- `{{description}}` - Descripción del bug
- `{{error}}` - Mensaje de error
- `{{code}}` - Código relevante
- `{{language}}` - Lenguaje

---

### API Documentation (`api-docs.md`)

Documenta endpoints de API.

**Variables:**
- `{{code}}` - Código del endpoint
- `{{format}}` - Formato de salida (OpenAPI, Markdown, etc)

---

### Optimize Performance (`optimize.md`)

Optimiza código para rendimiento.

**Variables:**
- `{{code}}` - Código a optimizar
- `{{focus}}` - Áreas de enfoque (speed, memory, I/O)
- `{{target}}` - Objetivo (speed/memory/both)
- `{{language}}` - Lenguaje

---

### Generate README (`readme-generator.md`)

Crea README completos para proyectos.

**Variables:**
- `{{name}}` - Nombre del proyecto
- `{{description}}` - Descripción
- `{{tone}}` - Tono (professional/casual/technical)

---

## 💡 Tips y Mejores Prácticas

### 1. Organiza tus Comandos

```
.claude/
└── commands/
    ├── code/
    │   ├── review.md
    │   └── refactor.md
    ├── docs/
    │   ├── api-docs.md
    │   └── readme.md
    └── testing/
        └── generate-tests.md
```

### 2. Usa Variables Descriptivas

```markdown
# Malo
{{x}}

# Bueno
{{code_to_review}}
{{target_language}}
{{optimization_focus}}
```

### 3. Incluye Contexto

```markdown
# Code Review

## Context
This code is part of a REST API for user authentication.

## Requirements
- Must be secure against SQL injection
- Should follow OAuth 2.0 best practices

## Code to Review
{{code}}
```

### 4. Crea Comandos Específicos del Proyecto

```markdown
# Review Swift UI Code

Review this SwiftUI view for:
- Proper use of @State and @Binding
- Performance (avoid unnecessary re-renders)
- Accessibility (VoiceOver support)
- SwiftUI best practices

Code:
{{code}}
```

### 5. Combina Múltiples Variables

```markdown
# Migrate Code

Migrate this {{source_language}} code to {{target_language}}:

{{code}}

Requirements:
- {{requirements}}

Target framework: {{target_framework}}
```

---

## 🎨 Iconografía en CalmMark

En el sidebar, los archivos de comandos se muestran con iconos distintivos:

| Icono | Significado |
|-------|-------------|
| 📁 | Carpeta normal |
| 📄 | Archivo Markdown normal |
| ⚡ | Archivo de comando IA (`.claude/commands/*.md`) |
| 🟣 | Badge púrpura para comandos |

---

## ⌨️ Atajos de Teclado

| Atajo | Acción |
|-------|--------|
| `⌘⇧O` | Abrir carpeta |
| `⌘0` | Toggle sidebar |
| `⌘W` | Cerrar pestaña activa |
| `⌘S` | Guardar archivo activo |
| `⌘⌥S` | Guardar todos los archivos |
| `⌘1/2/3` | Cambiar modo de vista |

---

## 🔧 Creando Comandos Personalizados

### Desde Cero

1. Crea un archivo en `.claude/commands/mi-comando.md`
2. Añade tu contenido:

```markdown
# Mi Comando Personalizado

Descripción de lo que hace este comando.

## Inputs
{{input1}}
{{input2}}

## Instructions
1. Analiza {{input1}}
2. Compara con {{input2}}
3. Genera recomendaciones
```

3. Guarda y úsalo con `/mi-comando`

### Desde Plantilla

1. Usa el panel de plantillas
2. Selecciona "Custom"
3. Modifica la plantilla base
4. Guarda con un nombre descriptivo

---

## 📖 Ejemplos Prácticos

### Ejemplo 1: Review de Pull Request

```markdown
# PR Review

Review this pull request:

## Title
{{pr_title}}

## Description
{{pr_description}}

## Changes
{{git_diff}}

Provide:
1. Summary of changes
2. Potential issues
3. Suggestions for improvement
4. Security considerations
```

Uso:
```bash
# 1. Copia título y descripción del PR
# 2. Ejecuta: git diff main...feature-branch
# 3. Pega en el comando
# 4. Ejecuta: /pr-review
```

### Ejemplo 2: Generar Tests para Swift

Archivo: `.claude/commands/swift-tests.md`

```markdown
# Generate XCTests

Generate comprehensive XCTests for this Swift code:

\```swift
{{code}}
\```

Requirements:
- Use XCTest framework
- Test all public methods
- Include edge cases
- Add mock objects if needed
- Follow Given-When-Then pattern

Class under test: {{class_name}}
```

### Ejemplo 3: Documentar API REST

Archivo: `.claude/commands/document-api.md`

```markdown
# API Endpoint Documentation

Generate OpenAPI 3.0 documentation for:

## Endpoint
{{method}} {{path}}

## Implementation
\```{{language}}
{{code}}
\```

Include:
- Request parameters
- Request body schema
- Response schemas (success & error)
- Status codes
- Example requests/responses
- Authentication requirements
```

---

## 🤝 Integración con Claude Code

CalmMark está optimizado para trabajar con Claude Code (CLI). Los comandos creados son 100% compatibles con:

```bash
# Ejecutar comando
claude /review

# Listar comandos disponibles
claude /

# Ver contenido de un comando
cat .claude/commands/review.md
```

---

## 📝 Formato de Variables

Las variables en CalmMark usan la sintaxis:

```markdown
{{nombre_variable}}
```

### Variables Comunes

| Variable | Uso | Ejemplo |
|----------|-----|---------|
| `{{code}}` | Código a procesar | Cualquier snippet |
| `{{language}}` | Lenguaje de programación | Swift, Python, JS |
| `{{description}}` | Descripción general | "API de usuarios" |
| `{{error}}` | Mensaje de error | Stack trace |
| `{{diff}}` | Git diff | Salida de `git diff` |
| `{{framework}}` | Framework usado | React, SwiftUI |
| `{{requirements}}` | Requisitos específicos | "Must be secure" |

---

## 🎓 Casos de Uso Avanzados

### 1. Pipeline de Code Review Automatizado

Crea múltiples comandos encadenados:

```
/review-security → /review-performance → /review-style → /generate-report
```

### 2. Generación de Documentación Completa

```
/document-api → /generate-openapi → /create-postman-collection
```

### 3. Testing Comprehensivo

```
/generate-unit-tests → /generate-integration-tests → /generate-e2e-tests
```

---

## 🐛 Troubleshooting

### Problema: Los comandos no aparecen marcados

**Solución:** Asegúrate de que:
- El archivo está en `.claude/commands/`
- Tiene extensión `.md`
- El proyecto está abierto como carpeta (`⌘⇧O`)

### Problema: Las variables no se reemplazan

**Solución:**
- Verifica la sintaxis: `{{variable}}` (con llaves dobles)
- No uses espacios: `{{mi variable}}` ❌ → `{{mi_variable}}` ✅

### Problema: El comando no se ejecuta en Claude Code

**Solución:**
- Verifica que el archivo existe
- Usa el nombre correcto: `/review` para `review.md`
- Asegúrate de estar en el directorio correcto del proyecto

---

## 📚 Recursos Adicionales

- [Claude Code Documentation](https://docs.claude.ai/code)
- [Markdown Guide](https://www.markdownguide.org)
- [Conventional Commits](https://www.conventionalcommits.org)

---

## 🎯 Conclusión

CalmMark facilita la creación y gestión de comandos para agentes IA, integrando perfectamente esta funcionalidad en tu flujo de trabajo de Markdown. Con plantillas predefinidas, detección automática y una interfaz intuitiva, puedes aprovechar al máximo Claude Code y otros agentes IA.

**¡Feliz automatización!** 🤖✨

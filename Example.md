# Bienvenido a CalmMark 🍃

CalmMark es un **editor de Markdown** elegante y minimalista para macOS. Este documento demuestra todas las características soportadas.

---

## ¿Qué es Markdown?

Markdown es un lenguaje de marcado ligero que te permite escribir usando un formato de texto plano fácil de leer y escribir, que luego se puede convertir a HTML.

---

## Características de Texto

### Énfasis

Puedes usar *cursiva* con asteriscos o _guiones bajos_.

También puedes usar **negrita** con doble asterisco o __doble guión bajo__.

Y por supuesto, puedes ***combinar ambos***.

### Código Inline

Usa `código inline` para resaltar comandos o variables como `let nombre = "CalmMark"`.

---

## Encabezados

# Encabezado Nivel 1
## Encabezado Nivel 2
### Encabezado Nivel 3
#### Encabezado Nivel 4
##### Encabezado Nivel 5
###### Encabezado Nivel 6

---

## Listas

### Lista sin Orden

- Primer item
- Segundo item
- Tercer item
  - Sub-item A
  - Sub-item B
- Cuarto item

### Lista Ordenada

1. Primero haz esto
2. Luego haz esto
3. Finalmente esto
4. Y ya está!

---

## Enlaces e Imágenes

### Enlaces

Visita [CalmMark en GitHub](https://github.com/tu-usuario/CalmMark) para ver el código fuente.

Aquí hay otro enlace: [Apple Developer](https://developer.apple.com)

### Imágenes

![Markdown Logo](https://markdown-here.com/img/icon256.png)

---

## Bloques de Código

### Swift

```swift
import SwiftUI

struct ContentView: View {
    @State private var text = "Hola, CalmMark!"

    var body: some View {
        Text(text)
            .font(.title)
            .foregroundColor(.blue)
    }
}
```

### Python

```python
def fibonacci(n):
    if n <= 1:
        return n
    else:
        return fibonacci(n-1) + fibonacci(n-2)

# Imprimir los primeros 10 números de Fibonacci
for i in range(10):
    print(fibonacci(i))
```

### JavaScript

```javascript
const greet = (name) => {
  console.log(`¡Hola, ${name}!`);
};

greet('CalmMark');
```

---

## Citas

> "La simplicidad es la máxima sofisticación."
>
> — Leonardo da Vinci

> "El diseño no es solo cómo se ve y cómo se siente. El diseño es cómo funciona."
>
> — Steve Jobs

---

## Líneas Horizontales

Puedes crear líneas horizontales con tres o más guiones:

---

O tres o más asteriscos:

***

---

## Tablas

| Característica | CalmMark | Otros Editores |
|----------------|----------|----------------|
| Gratis         | ✅       | ❌             |
| Open Source    | ✅       | ❌             |
| Nativo macOS   | ✅       | ⚠️             |
| Minimalista    | ✅       | ⚠️             |
| Vista Previa   | ✅       | ✅             |
| Exportar PDF   | ✅       | ✅             |

---

## Atajos de Teclado Útiles

| Atajo | Acción |
|-------|--------|
| `⌘N` | Nuevo documento |
| `⌘O` | Abrir documento |
| `⌘S` | Guardar |
| `⌘1` | Modo Editor |
| `⌘2` | Modo Preview |
| `⌘3` | Modo Split |
| `⌘⇧E` | Exportar HTML |
| `⌘⇧P` | Exportar PDF |
| `⌘,` | Preferencias |

---

## Tips para Escritura

1. **Usa el modo Split** para ver tus cambios en tiempo real
2. **Configura el tema oscuro** en Preferencias para escribir de noche
3. **Ajusta el tamaño de fuente** según tu preferencia
4. **Exporta a PDF** cuando necesites compartir tus documentos
5. **Usa el modo Editor solo** para enfocarte sin distracciones

---

## Próximas Características

Estas son algunas de las características planeadas para futuras versiones:

- [ ] Pestañas múltiples
- [ ] Búsqueda y reemplazo
- [ ] Outline de encabezados
- [ ] Modo Zen/Focus
- [ ] Sincronización iCloud
- [ ] Themes personalizables
- [ ] Diagramas Mermaid
- [ ] Ecuaciones LaTeX

---

## ¿Necesitas Ayuda?

Si tienes preguntas o encuentras bugs:

1. Revisa el [README.md](README.md)
2. Visita la sección de Issues en GitHub
3. Lee la documentación completa

---

## Conclusión

**CalmMark** está diseñado para ofrecerte la mejor experiencia de escritura en Markdown para macOS. Simple, elegante y poderoso.

¡Feliz escritura! ✨

---

*Generado con CalmMark v1.0*

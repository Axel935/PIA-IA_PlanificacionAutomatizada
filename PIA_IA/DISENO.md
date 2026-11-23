# Robot repartidor de medicamentos en un hospital: así se diseñó 

Proyecto Final (PIA) — Planificación Automatizada con PDDL

**Autor:** Mario Axel Aleman Rangel
**Archivos:** `domain.pddl`, `problem.pddl`

---

## 1. De qué trata

Tenemos un robot de hospital que tiene que llevarle un medicamento a un paciente que está en aislamiento. Suena fácil, pero en el camino se complica:

1. Primero hay que conseguir una tarjeta de acceso en el cuarto de seguridad.
2. Luego recoger el medicamento en la farmacia y esterilizarlo.
3. Subir al piso 2 en elevador.
4. Entrar al aislamiento (la puerta pide tarjeta) y entregar.
5. Al salir, el robot queda contaminado, así que tiene que descontaminarse y regresar a la farmacia en el piso 1.

**Meta formal:** `(and (delivered med1 paciente1) (clean) (robot-at farmacia))`

### Mapa

```
PISO 2:  lobby2 ── pasillo ── (puerta, tarjeta) ── aislamiento
                      │                                 │
                      └──── descontaminacion ◄──────────┘ (salida)
            ▲ elevador (solo si el robot está limpio)
            ▼
PISO 1:  lobby1 ── farmacia
            ├───── esterilizacion
            └───── seguridad (tarjeta)
```

## 2. Cómo llegamos hasta aquí

### 2.1 Escoger el escenario

Primero pensé en cinco ideas: cocina de restaurante, robot de hospital, mudanza o evento, laboratorio y taller mecánico. Preferí el robot de hospital porque se prestaba para meter mecánicas propias (puertas con acceso restringido, contaminación) que no aparecen en los dominios que vimos en clase.

### 2.2 Qué mecánicas meter

Arrancamos con la contaminación como idea principal y luego sumamos el elevador. Lo que las amarra es una sola regla: **un robot contaminado no puede usar el elevador**. Con eso, descontaminarse deja de ser un paso de relleno y se vuelve obligatorio para poder cambiar de piso otra vez.

### 2.3 Ir por capas

Para no volverme loco depurando, la idea fue construir el dominio en capas y probar cada una antes de seguir:

| Capa | Qué tenía |
|---|---|
| 1 | `move` y `deliver` en un problema de 2 cuartos |
| 2 | Se agrega esterilización |
| 3 | Se agrega la tarjeta y la puerta bloqueada |
| 4 | Se agrega el elevador y la contaminación |

## 3. Predicados y para qué sirve cada uno

| Predicado | Por qué lo pusimos |
|---|---|
| `(connected ?a ?b)` | Pasillos normales. Es dirigido, así que el aislamiento puede tener solo salida hacia descontaminación. |
| `(door-link ?a ?b)` | Separa las puertas restringidas de los pasillos normales, para que `move` nunca pueda entrar al aislamiento por su cuenta. |
| `(elevator-link ?a ?b)` | Conecta los vestíbulos de los dos pisos. |
| `(isolation ?l)`, `(sterilizer-room ?l)`, `(decon-station ?l)` | Marcan los cuartos especiales. Así escribimos cada acción una vez y no una por cuarto. |
| `(opens ?k ?l)` | Dice qué tarjeta abre qué cuarto. |
| `(robot-at ?l)` | Dónde está el robot. |
| `(hand-free)` / `(carrying ?m)` | Para que el robot solo pueda cargar una cosa a la vez. |
| `(has-key ?k)` | La tarjeta como permiso, sin ocupar la mano (ver 4.3). |
| `(clean)` | Si el robot está descontaminado, en positivo (ver 4.4). |
| `(med-at)`, `(key-at)`, `(patient-at)` | Dónde están los medicamentos, las tarjetas y el paciente. |
| `(sterile ?m)` | El medicamento tiene que pasar por aquí antes de entregarse. |
| `(delivered ?m ?p)` | Es la que usamos en la meta. |

En total son 17 predicados (el mínimo era 4).

## 4. Las acciones y cómo decidimos cada una

El dominio tiene 9 acciones (el mínimo era 3).

| Acción | Precondiciones | Efectos (agrega / elimina) |
|---|---|---|
| `move ?from ?to` | `robot-at ?from`, `connected ?from ?to` | agrega `robot-at ?to` / elimina `robot-at ?from` |
| `pick-up ?m ?l` | `robot-at ?l`, `med-at ?m ?l`, `hand-free` | agrega `carrying ?m` / elimina `med-at`, `hand-free` |
| `drop ?m ?l` | `robot-at ?l`, `carrying ?m` | agrega `med-at ?m ?l`, `hand-free` / elimina `carrying` |
| `take-key ?k ?l` | `robot-at ?l`, `key-at ?k ?l` | agrega `has-key ?k` / elimina `key-at` |
| `sterilize ?m ?l` | `robot-at ?l`, `sterilizer-room ?l`, `carrying ?m` | agrega `sterile ?m` |
| `use-elevator ?from ?to` | `robot-at ?from`, `elevator-link ?from ?to`, `clean` | agrega `robot-at ?to` / elimina `robot-at ?from` |
| `enter-isolation ?k ?from ?to` | `robot-at ?from`, `door-link ?from ?to`, `isolation ?to`, `has-key ?k`, `opens ?k ?to` | agrega `robot-at ?to` / elimina `robot-at ?from`, `clean` |
| `deliver ?m ?p ?l` | `robot-at ?l`, `patient-at ?p ?l`, `carrying ?m`, `sterile ?m` | agrega `delivered ?m ?p`, `hand-free` / elimina `carrying ?m` |
| `decontaminate ?l` | `robot-at ?l`, `decon-station ?l` | agrega `clean` |

### 4.1 Por qué `enter-isolation` no es un simple `move`

Si `move` contaminara al robot cuando el destino es el aislamiento, necesitaría un efecto condicional (`when`). Eso complica el dominio y no todos los planificadores lo soportan. Con una acción aparte el efecto es directo y nos ahorramos el problema.

### 4.2 Puertas separadas de los pasillos (`door-link`)

Si el aislamiento estuviera dentro de `connected`, `move` podría entrar sin tarjeta y la puerta no serviría de nada. Al separarlo, la única forma de entrar es `enter-isolation`.

### 4.3 La tarjeta no ocupa la mano

Pensé en dos opciones: que la tarjeta ocupara la mano como el medicamento, o que fuera un permiso (`has-key`). Con la primera, el robot nunca podría entrar con tarjeta y medicamento a la vez y el problema no tendría solución. Nos quedamos con el permiso.

### 4.4 `clean` en positivo

En vez de `(contaminated)` usé `(clean)`. Así `use-elevator` pide algo positivo y se evitan precondiciones negativas, que algunos planificadores manejan mal.

### 4.5 La meta pide `(clean)` y `(robot-at farmacia)`

Si la meta solo pidiera entregar, saldría un plan de 13 pasos sin descontaminarse ni regresar, y la contaminación y el elevador no pintarían nada. Pidiendo que el robot termine limpio y en el piso 1, esas mecánicas sí cuentan (ver sección 6).

## 5. En qué se diferencia de lo que nos inspiró

Me basé en la idea general de transportar cosas entre lugares (Air Cargo) y en la restricción de cargar una sola cosa (Blocks World). Pero el dominio es otro:

| Aspecto | Air Cargo / Blocks World | Nuestro dominio |
|---|---|---|
| Transporte | Se carga y descarga sin que el objeto cambie | El medicamento cambia de estado (`sterile`) y no se puede entregar sin eso |
| Estado del agente | El avión o el brazo siempre están igual | El robot cambia (`clean`) y eso limita lo que puede hacer después |
| Acceso | Cualquier ruta está disponible | Puerta con tarjeta y elevador que exige `clean` |
| Estructura | Aeropuertos conectados entre sí | Dos pisos y caminos dirigidos (el aislamiento solo sale a descontaminación) |
| Capacidad | Un avión lleva varias cargas | Una sola carga a la vez |
| Orden de las acciones | Bastante libre | Obligatorio: esterilizar antes de entregar, tarjeta antes de entrar, descontaminar antes del elevador |

## 6. ¿Funciona de verdad?

Además de probarlo en el planificador, resolvi el problema con un solucionador de búsqueda en anchura que lee directamente los archivos `.pddl`. Salió que el problema sí tiene solución y que el plan más corto es de **19 pasos**.

También probamos variantes para comprobar que cada mecánica de verdad limita el plan:

| Variante | Resultado | Qué nos dice |
|---|---|---|
| Original | Plan de 19 pasos | Línea base |
| Sin la tarjeta en el cuarto de seguridad | Sin solución | La puerta del aislamiento sí exige la tarjeta |
| Robot contaminado desde el inicio | Sin solución | No puede usar el elevador y la estación de descontaminación está en el piso 2 |
| Meta solo `(delivered med1 paciente1)` | Plan de 13 pasos | Sin las condiciones finales no hace falta descontaminarse ni regresar |
| Meta sin `(clean)` pero con `(robot-at farmacia)` | Plan de 19 pasos | El elevador exige `clean` aunque la meta no lo pida |

## 7. El plan que salió

1. `move lobby1 farmacia`
2. `pick-up med1 farmacia`
3. `move farmacia lobby1`
4. `move lobby1 esterilizacion`
5. `sterilize med1 esterilizacion`
6. `move esterilizacion lobby1`
7. `move lobby1 seguridad`
8. `take-key tarjeta1 seguridad`
9. `move seguridad lobby1`
10. `use-elevator lobby1 lobby2`
11. `move lobby2 pasillo`
12. `enter-isolation tarjeta1 pasillo aislamiento`
13. `deliver med1 paciente1 aislamiento`
14. `move aislamiento descontaminacion`
15. `decontaminate descontaminacion`
16. `move descontaminacion pasillo`
17. `move pasillo lobby2`
18. `use-elevator lobby2 lobby1`
19. `move lobby1 farmacia`

Ojo: el orden de los pasos independientes (por ejemplo, agarrar la tarjeta antes o después del medicamento) puede cambiar según el planificador.

## 9. Cómo correrlo

1. Abrir [editor.planning.domains](https://editor.planning.domains).
2. Pegar `domain.pddl` y `problem.pddl`.
3. Elegir un planificador y darle a Solve.

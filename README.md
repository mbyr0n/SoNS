# SoNS - Self-organizing Nervous Systems

## Descripcion

Este repositorio contiene una exploracion en ARGoS3 inspirada en el enfoque **Self-organizing Nervous Systems (SoNS)** para enjambres roboticos. El objetivo es experimentar con controladores Lua y configuraciones de simulacion para robots terrestres QUPA y un robot aereo Crazyflie dentro de un entorno heterogeneo.

El proyecto no busca ser una reproduccion completa del paper original, sino una base experimental para estudiar ideas como jerarquia auto-organizada, comunicacion local, formacion de estructuras tipo arbol y coordinacion entre robots terrestres y aereos.

## Inspiracion

El paper **"Self-organizing Nervous Systems for Robot Swarms"** propone una arquitectura donde un enjambre puede organizarse en jerarquias dinamicas de multiples niveles. En estas estructuras, algunos robots pueden actuar temporalmente como "cerebro" de un sistema, coordinando sensado, actuacion y toma de decisiones, mientras el conjunto conserva propiedades importantes de los enjambres: escalabilidad, flexibilidad y tolerancia a fallos.

Una idea central de SoNS es que la jerarquia no se impone desde afuera. Los robots establecen, mantienen y reconfiguran sus conexiones usando comunicacion local, lo que permite que varios robots funcionen como un cuerpo virtual distribuido.

## Robots utilizados

Este repositorio trabaja con dos plataformas simuladas en ARGoS3:

- **QUPA**: robot terrestre diferencial usado como plataforma base del enjambre. Plugin y modelo disponibles en [mbyr0n/qupa_v2](https://github.com/mbyr0n/qupa_v2).
- **Crazyflie**: robot aereo usado para escenarios heterogeneos aire-tierra, con sensores como AprilTag, camara de blobs de color y bateria. Plugin disponible en [mbyr0n/custom_crazyflie](https://github.com/mbyr0n/custom_crazyflie).

## Contenido del repositorio

```text
.
+-- controller/
|   +-- control_sos.lua
|   +-- control_qupa.lua
|   +-- control_crazyflie.lua
+-- experiments/
|   +-- self_organize_system.argos
|   +-- floor.png
|   +-- textura_piso.jpg
+-- self_organize_system.argos
+-- README.md
```

- `controller/control_sos.lua`: controlador principal para una prueba SoNS con QUPA, comunicacion `range_and_bearing`, asignacion de roles y seguimiento de una estructura tipo arbol.
- `controller/control_qupa.lua`: controlador simple para QUPA en el experimento heterogeneo.
- `controller/control_crazyflie.lua`: controlador de prueba para Crazyflie usando deteccion AprilTag.
- `self_organize_system.argos`: configuracion enfocada en seis robots QUPA con comunicacion `range_and_bearing`.
- `experiments/self_organize_system.argos`: configuracion heterogenea con seis QUPA y un Crazyflie.

## Experimentos

### QUPA + comunicacion local

El archivo `self_organize_system.argos` instancia seis robots QUPA y usa `range_and_bearing` para intercambiar mensajes locales. El controlador `control_sos.lua` asigna un robot como nodo raiz o "brain" y organiza el resto como hijos dentro de una topologia predefinida.

### QUPA + Crazyflie

El archivo `experiments/self_organize_system.argos` combina robots terrestres QUPA con un Crazyflie. Esta configuracion sirve como punto de partida para escenarios heterogeneos donde un robot aereo puede detectar tags y colaborar con robots terrestres.

## Ejecucion

Requisitos generales:

- ARGoS3 instalado.
- Plugin QUPA instalado desde [mbyr0n/qupa_v2](https://github.com/mbyr0n/qupa_v2).
- Plugin Crazyflie instalado desde [mbyr0n/custom_crazyflie](https://github.com/mbyr0n/custom_crazyflie), si se va a ejecutar el experimento heterogeneo.

Ejecutar el experimento principal:

```bash
argos3 -c self_organize_system.argos
```

Ejecutar el experimento heterogeneo:

```bash
argos3 -c experiments/self_organize_system.argos
```

## Referencias

- W. Zhu et al., **"Self-organizing Nervous Systems for Robot Swarms"**.
- QUPA ARGoS plugin: [https://github.com/mbyr0n/qupa_v2](https://github.com/mbyr0n/qupa_v2)
- Crazyflie ARGoS plugin: [https://github.com/mbyr0n/custom_crazyflie](https://github.com/mbyr0n/custom_crazyflie)

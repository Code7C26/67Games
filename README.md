# 67Games

> *Un juego de estrategia 2D y simulación táctica de propagación patógena desarrollado en Godot Engine.*

![Godot Engine](https://img.shields.io/badge/Godot-v4.x-478CBF?style=for-the-badge&logo=godotengine&logoColor=white)
![Status](https://img.shields.io/badge/Status-En_Desarrollo-orange?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

---

## Descripción General

**Outbreak Rivals** es un videojuego de estrategia e infectividad táctica en vista superior (*top-down 2D*). El jugador asume el control de una cepa patógena en evolución con el objetivo de propagarse y dominar el entorno antes de que los sistemas de control o cepas rivales neutralicen la infección.

A diferencia de los simuladores tradicionales, el juego combina **decisiones tácticas previas a la partida** (basadas en factores ambientales como temperatura, humedad e higiene del entorno) con un **sistema de comportamiento de multitudes en tiempo real**.

---

## Características Principales

* **Estrategia Adaptativa al Entorno:** Las condiciones del mapa (clima, densidad de población, niveles de desinfección) alteran directamente la tasa de transmisibilidad de tus síntomas.
* **Árbol de Mutaciones:** Gasta puntos de ADN para evolucionar atributos de *Transmisión*, *Síntomas* y *Resistencia*.
* **IA de Multitudes (NPCs):** Un motor de simulación en 2D donde los bots reaccionan con comportamientos de pánico, aislamiento o búsqueda de atención médica según la gravedad del brote.
* **Modo Táctico:** Analiza el informe demográfico e higiénico del escenario antes de empezar y arma el combo de enfermedades perfecto para ese mapa.
* **Desarrollado en Godot 4:** Aprovecha la arquitectura de nodos nativa en 2D y scripts optimizados en GDScript para un rendimiento fluido.

---

## Tecnologías Utilizadas

* **Motor de Videojuegos:** [Godot Engine 4.x](https://godotengine.org/)
* **Lenguaje Principal:** GDScript
* **Control de Versiones:** Git / GitHub
* **Diseño e Interfaz:** Pixel Art 2D

---

## Estructura del Repositorio

```text
├── assets/             # Sprites, texturas, fuentes y efectos de sonido
│   ├── sprites/        # Personajes, mapas e interfaz
│   └── audio/          # SFX y música de fondo
├── scenes/             # Escenas de Godot (.tscn)
│   ├── ui/             # Menús, paneles de mutación y HUD
│   ├── maps/           # Escenarios y niveles
│   └── entities/       # Jugador, bots (NPCs) y agentes
├── scripts/            # Código fuente en GDScript (.gd)
│   ├── ai/             # Algoritmos de movimiento y comportamiento de bots
│   ├── core/           # Lógica del juego, gestor de infecciones y variables
│   └── resources/      # Definición de mapas y tipos de mutaciones
├── resources/          # Archivos de datos personalizados (.tres)
└── README.md           # Documentación del proyecto

# La confianza ya viene: edad, cohortes y períodos en la confianza institucional del Chile de los últimos 20 años

Gonzalo Bustamante Rojas & Alonso Quintero Contreras

Ponencia aceptada en el **4to Congreso Latinoamericano de Ciencias Sociales y Gobierno de la Triada 2026** (PUC Chile / Universidad de los Andes Colombia / Tec de Monterrey), 1-2 de octubre de 2026, campus Ciudad de México.

## Qué hace este análisis

Un análisis edad-período-cohorte (APC) de la confianza institucional en Chile (Gobierno, Parlamento, Partidos, Fuerzas Armadas, Iglesia), usando el panel armonizado de la Encuesta Bicentenario PUCV (2006-2025). La pregunta central: ¿existe una ruptura generacional real en la confianza institucional asociada a la Generación del estallido (nacidos desde 1995)?

Se estimaron tres especificaciones de la variable dependiente en paralelo (binaria top-2-box, continua z-score, ordinal completa) y se puso a prueba la elección de cohortes generacionales contra tres esquemas alternativos (una taxonomía generacional importada tipo Silent/Boomer/X/Millennial/Z, la periodización histórico-local propia del proyecto, y un corte único de transición democrática). El resultado: la única ruptura generacional que se sostiene de forma robusta, en las tres especificaciones y frente a los tres esquemas alternativos, es la de la Generación del estallido — con la excepción de la Iglesia, que no muestra ruptura generacional en ninguna configuración.

## Estructura del repositorio

```
Análisis final/
├── dofile final confianza institucional.do   # Script principal (Stata), secciones 0-9
├── graficos_nuevos.do                         # Script chico y autocontenido para regenerar
│                                               # solo las secciones 8 y 9 (sin los ~45 modelos
│                                               # multinivel del script principal)
├── Principal/                                 # Tablas y gráficos centrales
│   ├── tabla_1c_ordinal.rtf                   # Especificación recomendada (meologit), 5 instituciones
│   ├── 1b_continua_{gob,ffaa,igl}.png         # Márgenes cohorte/período/edad — sin violación seria
│   │                                           # de normalidad (ver diagnóstico), gráfico continuo
│   ├── 1c_ordinal_{parl,part}.png             # Márgenes cohorte/período/edad — violación seria de
│   │                                           # normalidad (piso de la escala), gráfico ordinal
│   ├── tabla_4_wald_cohortes.csv              # Tests de Wald de las 3 encrucijadas de cohorte
│   ├── 4_brecha_estallido.png                 # Hallazgo: brecha pre/post estallido (z-score)
│   ├── 5_forest_encrucijadas.png              # Resumen visual de los tests de Wald: solo la
│   │                                           # frontera 1994/1995 sobrevive a las 3 encrucijadas
│   └── 6_tendencia_temporal.png               # Contexto descriptivo: % que confía 2006-2025
├── Auxiliar/                                   # Robustez y diagnóstico
│   ├── tabla_1a_binaria.rtf / tabla_1b_continua.rtf
│   ├── 1b_continua_{parl,part}.png / 1c_ordinal_{gob,ffaa,igl}.png  # Contraparte de cada gráfico
│   │                                           # principal, misma conclusión sustantiva
│   ├── tabla_2*_robustez_teorica.rtf           # Robustez con cohortes histórico-generacionales
│   ├── tabla_3_diagnostico_normalidad.csv      # Diagnóstico de residuos (skewness/kurtosis)
│   └── wald_chequeo_dummies_ano.csv            # Período como efectos fijos vs. aleatorios
├── Cohortes teóricas/                          # Comparación: márgenes con cohort_teorica (5
│   │                                           # bloques) en vez de cohort5 (14 quinquenios) —
│   │                                           # no reemplaza nada de Principal/Auxiliar
│   └── 1{b,c}_{continua,ordinal}_teo_*.png
└── Construcción del panel/
    └── build_panel_bicentenario_armonizado.do  # Script que arma el panel 2006-2025 a partir
                                                  # de las bases anuales de Bicentenario
```

## Datos

**Los microdatos de la Encuesta Bicentenario NO están incluidos en este repositorio.** No se encontró una licencia explícita que autorice su redistribución pública; los datos deben solicitarse directamente a la Encuesta Bicentenario (PUCV).

Para reproducir el análisis:
1. Obtener las bases anuales de Bicentenario (2006-2025) directamente de PUCV.
2. Correr `Construcción del panel/build_panel_bicentenario_armonizado.do` para generar el panel armonizado.
3. Editar los tres globals al inicio de `dofile final confianza institucional.do` (`$DATA`, `$PRINCIPAL`, `$AUXILIAR`) para que apunten a las rutas locales correspondientes.
4. Correr el do-file completo.

## Especificación metodológica

- **Modelo APC**: cohorte y edad como efectos fijos (edad con término cuadrático), período como intercepto aleatorio por año de encuesta — siguiendo a Bargsted & Maldonado (2018).
- **Tres especificaciones de DV**: binaria top-2-box (`melogit`), continua z-score por año (`mixed`), ordinal completa 1-5 (`meologit`). La especificación ordinal es la recomendada como principal para las tablas de resultados: usa toda la información de la escala (a diferencia de la binaria) sin asumir normalidad de la variable observada (a diferencia de la continua — ver diagnóstico de residuos en `Auxiliar/`). Para los **gráficos de márgenes**, la elección entre continua y ordinal se hace institución por institución según ese mismo diagnóstico: donde la violación de normalidad es leve (Gobierno, FF.AA., Iglesia) se muestra la continua, con intervalos más angostos y legibles sin ese problema; donde es seria (Parlamento, Partidos, por la alta concentración de respuestas en el piso de la escala) se muestra la ordinal, con intervalos más anchos pero que sí reflejan honestamente la incertidumbre.
- **Diseño muestral**: ponderador incorporado como `pweight` con errores estándar robustos (`vce(robust)`) en todos los modelos multinivel, ya que Stata no propaga correctamente el prefijo `svy:` a través de efectos aleatorios anidados.
- **Cohortes**: quinquenales (Bargsted & Maldonado 2018) como especificación principal; cohortes histórico-generacionales (inspiradas en Araujo & Martuccelli 2012, extendidas con la Generación del estallido siguiendo Mannheim 1928 y Krosnick & Alwin 1989) como robustez con etiquetas interpretables.

## Estado

Ponencia aceptada; artículo completo en preparación (fecha límite: 7 de noviembre de 2026).

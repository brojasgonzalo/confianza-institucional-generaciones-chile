# La confianza ya viene: edad, cohortes y períodos en la confianza institucional del Chile de los últimos 20 años

Gonzalo Bustamante Rojas & Alonso Quintero Contreras

<sub>Ponencia aceptada en el 4to Congreso Latinoamericano de Ciencias Sociales y Gobierno de la Triada 2026 (PUC Chile / Universidad de los Andes Colombia / Tec de Monterrey), 1-2 de octubre de 2026, campus Ciudad de México.</sub>

## Qué hace este análisis

Un análisis edad-período-cohorte (APC) de la confianza institucional en Chile (Gobierno, Parlamento, Partidos, Fuerzas Armadas, Iglesia), usando el panel armonizado de la Encuesta Bicentenario PUCV (2006-2025). La pregunta central:

*¿Existe una ruptura generacional real en la confianza institucional chilena, distinta del efecto de la edad o la coyuntura del momento (efecto de período), y si existe, dónde se ubica?*

Se estimaron tres especificaciones multinivel de la variable dependiente en paralelo (binaria top-2-box, continua z-score, ordinal completa) y se puso a prueba la elección de la frontera generacional contra tres esquemas de cohorte alternativos: una taxonomía generacional importada tipo Silent/Boomer/X/Millennial/Z (del Solar & Fernández, 2024), una periodización histórico-local propia del proyecto (Araujo & Martuccelli, 2012; Krosnick & Alwin, 1989; Didier, 2017), y un corte único de transición democrática (Balcells & Villamil, 2026) — 225 tests de Wald en total.

**Sobre el aparato teórico de generaciones:** todas las estimaciones parten de cohortes quinquenales como base. Sobre esta se pusieron a prueba tres esquemas candidatos de dónde debería estar el quiebre real ("encrucijadas", `Principal/tabla_4_wald_cohortes.csv`): **(1)** la taxonomía generacional importada tipo Silenciosa/Boomer/X/Millennial/Z, popular en reportes chilenos (del Solar & Fernández, 2024) pero que Didier (2017) critica por ser fronteras sin anclaje en la experiencia histórica local; **(2)** una periodización histórico-local propia del proyecto, inspirada en el argumento de Araujo & Martuccelli (2012) de que la subjetividad se forma en condiciones históricas concretas, extendida con la Generación del estallido siguiendo la lógica de "años impresionables" de Mannheim (1928) y Krosnick & Alwin (1989); y **(3)** un corte único de edad-en-la-transición-democrática estilo Balcells & Villamil (2026), prácticamente rechazado en las ~20 pruebas.

## Estructura del repositorio

```
Análisis final/
├── dofile final confianza institucional.do   # Script principal (Stata), secciones 0-11
├── graficos_nuevos.do                         # Autocontenido, cero estimación — tendencia temporal
├── fronteras_quinquenales.do                  # Autocontenido, ~5 modelos rápidos — forest plot quinquenal
├── brecha_probabilidad.do                     # Autocontenido, ~5 modelos rápidos — brecha en % + test
├── specification_curve.do                     # Autocontenido, cero estimación — curva de especificaciones
├── cohort_check_ventana2.do                   # Autocontenido, ~15 modelos rápidos — actualiza el csv de
│                                               # Wald con ventana ±2 años para importada/Balcells
├── Principal/                                 # Tablas y gráficos centrales
│   ├── tabla_1c_ordinal.rtf                   # Tabla de resultados — especificación ordinal, 5 instituciones
│   ├── tabla_4_wald_cohortes.csv              # Los 225 tests de Wald de las 3 encrucijadas
│   ├── 1b_continua_{gob,ffaa,igl}.png         # Márgenes cohorte/período/edad — sin violación seria de
│   │                                           # normalidad, gráfico continuo (más legible)
│   ├── 1c_ordinal_{parl,part}.png             # Márgenes cohorte/período/edad — violación seria de
│   │                                           # normalidad (piso de la escala), gráfico ordinal
│   ├── 4_brecha_estallido.png                 # Hallazgo confirmado, escala z-score (figura principal)
│   ├── 5_forest_encrucijadas.png / .csv       # Las 13 fronteras entre quinquenios consecutivos —
│   │                                           # dónde exactamente se concentra el quiebre
│   ├── 6_tendencia_temporal.png               # Contexto descriptivo: % que confía 2006-2025, sin ajustar
│   ├── 7_brecha_estallido_prob.png / _pvalues.csv  # Mismo hallazgo que la 4, en escala de
│   │                                           # probabilidad (% que confía) con test de significancia
│   └── 8_specification_curve.png              # Las 10 fronteras candidatas de las 3 encrucijadas juntas
│                                               # — curva de especificaciones (Simonsohn et al. 2020)
├── Auxiliar/                                   # Robustez y diagnóstico
│   ├── tabla_1a_binaria.rtf / tabla_1b_continua.rtf
│   ├── 1b_continua_{parl,part}.png / 1c_ordinal_{gob,ffaa,igl}.png  # Contraparte de cada gráfico
│   │                                           # principal, misma conclusión sustantiva
│   ├── tabla_2*_robustez_teorica.rtf           # Robustez con cohortes histórico-generacionales
│   ├── tabla_3_diagnostico_normalidad.csv      # Diagnóstico de residuos (skewness/kurtosis)
│   └── wald_chequeo_dummies_ano.csv            # Período como efectos fijos vs. aleatorios
├── Cohortes teóricas/                          # Comparación descartada: márgenes con cohort_teorica
│   │                                           # (5 bloques históricos) en vez de cohort5 (14
│   │                                           # quinquenios) — se probó y no mejora nada, en algunos
│   │                                           # casos diluye la señal más fuerte (ver metodología)
│   └── 1{b,c}_{continua,ordinal}_teo_*.png
└── Construcción del panel/
    └── build_panel_bicentenario_armonizado.do  # Script que arma el panel 2006-2025 a partir
                                                  # de las bases anuales de Bicentenario
```

## Estimaciones

**Estimación continua** (z-score de la escala 1-5, normalizada por año): es la que más potencia estadística da, pero asume que los residuos del modelo son normales. Se testeó ese supuesto (ver `Auxiliar/tabla_3_diagnostico_normalidad.csv`, histogramas y QQ-plots en `Auxiliar/3_normalidad_*.png`) y se encontró que se rompe en serio justo en Parlamento y Partidos. En FF.AA. la violación es prácticamente nula.

**Estimación binaria** (top-2-box): se dicotomizó la variable. Este tipo de modelo no impone normalidad, pero dicotomizar tiene un costo conocido: al colapsar 5 categorías a 2, se pierde información y potencia estadística — de hecho, la especificación binaria falla en detectar la frontera generacional justo en Parlamento y Partidos, las mismas dos instituciones donde ya se sabía que había sesgo de piso. La continua y la ordinal sí la detectan ahí sin problema.

**Estimación ordinal**: soluciona los problemas de las dos anteriores. Usa toda la información de la escala 1-5 (no pierde potencia como la binaria) y no asume normalidad de la variable observada — solo de una variable latente subyacente con puntos de corte libres, que sí se puede estimar sin ese supuesto. Por eso quedó como la especificación principal (`Principal/tabla_1c_ordinal.rtf`).

## Resultados

De todas las fronteras candidatas, solo una sobrevive de forma robusta a la identificación de la ruptura generacional: 1994/1995, la Generación del estallido. Robusta en las tres especificaciones para Gobierno y FF.AA.; robusta en continua y ordinal para Parlamento y Partidos; en Iglesia el patrón es mucho más débil y depende de la especificación.

La evidencia de esa convergencia, en cuatro ángulos distintos:

1. **`tabla_4_wald_cohortes.csv`** — los 225 tests de Wald crudos, las tres encrucijadas completas.
2. **`8_specification_curve.png`** — las 10 fronteras candidatas de las tres encrucijadas juntas en una sola figura (curva de especificaciones / *multiverse analysis*, Simonsohn, Simmons & Nelson 2020; Steegen et al. 2016): de un vistazo, cuál corte sobrevive y cuáles no.
3. **`5_forest_encrucijadas.png`** — dentro del esquema quinquenal, las 13 fronteras entre cohortes consecutivas: dónde exactamente, al detalle más fino posible con este panel, se concentra el quiebre.
4. **`4_brecha_estallido.png`** / **`7_brecha_estallido_prob.png`** — el contraste final ya simplificado a una sola variable binaria (pre/post 1995), en dos escalas (z-score y % que confía), con test de significancia impreso en el csv que acompaña a la segunda.

## Datos

Este análisis usa el panel armonizado de la Encuesta Bicentenario (PUCV), 2006-2025, 18 olas. Los microdatos **no** están incluidos en este repositorio — no se encontró una licencia explícita que autorice su redistribución pública; deben solicitarse directamente a la Encuesta Bicentenario (PUCV).


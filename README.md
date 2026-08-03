# La confianza ya viene: edad, cohortes y períodos en la confianza institucional del Chile de los últimos 20 años

Gonzalo Bustamante Rojas & Alonso Quintero Contreras

Ponencia aceptada en el **4to Congreso Latinoamericano de Ciencias Sociales y Gobierno de la Triada 2026** (PUC Chile / Universidad de los Andes Colombia / Tec de Monterrey), 1-2 de octubre de 2026, campus Ciudad de México.

## Qué hace este análisis

Un análisis edad-período-cohorte (APC) de la confianza institucional en Chile (Gobierno, Parlamento, Partidos, Fuerzas Armadas, Iglesia), usando el panel armonizado de la Encuesta Bicentenario PUCV (2006-2025). La pregunta central: ¿existe una ruptura generacional real en la confianza institucional asociada a la Generación del estallido (nacidos desde 1995), o lo que parece "generacional" es en realidad edad o coyuntura del momento (efecto de período)?

Se estimaron tres especificaciones de la variable dependiente en paralelo (binaria top-2-box, continua z-score, ordinal completa) y se puso a prueba la elección de la frontera generacional contra tres esquemas de cohorte alternativos (una taxonomía generacional importada tipo Silent/Boomer/X/Millennial/Z, la periodización histórico-local propia del proyecto, y un corte único de transición democrática estilo Balcells & Villamil 2026) — 225 tests de Wald en total. **El resultado:** de todas las fronteras candidatas, solo una sobrevive de forma robusta: 1994/1995, la Generación del estallido. Robusta en las tres especificaciones para Gobierno y FF.AA.; robusta en continua y ordinal (no en binaria — dicotomizar pierde potencia justo ahí) para Parlamento y Partidos; en Iglesia el patrón es mucho más débil y depende de la especificación — significativa solo en la comparación más potente (post-estallido contra todo el resto del panel), no en ninguna de las otras tres formas de testearla.

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

## Datos

**Los microdatos de la Encuesta Bicentenario NO están incluidos en este repositorio.** No se encontró una licencia explícita que autorice su redistribución pública; los datos deben solicitarse directamente a la Encuesta Bicentenario (PUCV).

Para reproducir el análisis:
1. Obtener las bases anuales de Bicentenario (2006-2025) directamente de PUCV.
2. Correr `Construcción del panel/build_panel_bicentenario_armonizado.do` para generar el panel armonizado.
3. Editar los globals al inicio de `dofile final confianza institucional.do` (`$DATA`, `$PRINCIPAL`, `$AUXILIAR`, `$TEORICA`) para que apunten a las rutas locales correspondientes.
4. Correr el do-file completo (tarda varias horas, sobre todo por los loops de `margins`/`marginsplot`) — o, para regenerar solo una figura puntual sin correr todo, usar el script chico correspondiente (`graficos_nuevos.do`, `fronteras_quinquenales.do`, `brecha_probabilidad.do`, `specification_curve.do`, `cohort_check_ventana2.do`).

## Especificación metodológica

- **Modelo APC**: cohorte y edad como efectos fijos (edad con término cuadrático), período como intercepto aleatorio por año de encuesta — siguiendo a Bargsted & Maldonado (2018).
- **Tres especificaciones de DV**: binaria top-2-box (`melogit`), continua z-score por año (`mixed`), ordinal completa 1-5 (`meologit`). La ordinal es la recomendada como principal para las tablas de resultados: usa toda la información de la escala sin asumir normalidad de la variable observada. El diagnóstico de residuos (`Auxiliar/tabla_3_diagnostico_normalidad.csv`) confirma que esa normalidad se rompe en serio en Parlamento y Partidos (mayor sesgo de piso) — y el test de Wald de la frontera 1994/1995 lo demuestra empíricamente: la binaria falla en detectar la ruptura ahí, mientras ordinal y continua sí la detectan.
- **Gráficos de márgenes**: la elección entre continua y ordinal se hace institución por institución según ese mismo diagnóstico — continua donde la violación es leve (Gobierno, FF.AA., Iglesia), ordinal donde es seria (Parlamento, Partidos).
- **Diseño muestral**: ponderador incorporado como `pweight` con errores estándar robustos (`vce(robust)`) en todos los modelos multinivel, ya que Stata no propaga correctamente el prefijo `svy:` a través de efectos aleatorios anidados.
- **Cohortes**: quinquenales (Bargsted & Maldonado 2018) como especificación principal; cohortes histórico-generacionales (inspiradas en Araujo & Martuccelli 2012, extendidas con la Generación del estallido siguiendo Mannheim 1928 y Krosnick & Alwin 1989) como robustez con etiquetas interpretables — se probó también como alternativa visual a los márgenes quinquenales y se descartó (ver `Cohortes teóricas/`).
- **Fronteras candidatas fuera de la grilla quinquenal** (taxonomía importada y corte único Balcells): se testean con una variable auxiliar (`cohort_check`) que usa resolución fina solo alrededor de cada corte candidato — ventana de ±2 años de nacimiento a cada lado (año individual, ±1, para el par Balcells por estar sus dos cortes a solo 2 años de distancia). Esto evita el problema de comparar generaciones completas: si la confianza sube o baja de forma gradual con cada cohorte de nacimiento sin ningún quiebre real, comparar promedios de grupos amplios da "significativo" en casi cualquier corte que se elija — comparar años adyacentes al borde específico sí puede distinguir un quiebre genuino de una tendencia suave.

## La evidencia de robustez, en cuatro ángulos distintos

1. **`tabla_4_wald_cohortes.csv`** — los 225 tests de Wald crudos, las tres encrucijadas completas.
2. **`8_specification_curve.png`** — las 10 fronteras candidatas de las tres encrucijadas juntas en una sola figura (curva de especificaciones / *multiverse analysis*, Simonsohn, Simmons & Nelson 2020; Steegen et al. 2016): de un vistazo, cuál corte sobrevive y cuáles no.
3. **`5_forest_encrucijadas.png`** — dentro del esquema quinquenal, las 13 fronteras entre cohortes consecutivas: dónde exactamente, al detalle más fino posible con este panel, se concentra el quiebre.
4. **`4_brecha_estallido.png`** / **`7_brecha_estallido_prob.png`** — el contraste final ya simplificado a una sola variable binaria (pre/post 1995), en dos escalas (z-score y % que confía), con test de significancia impreso en el csv que acompaña a la segunda.

Las cuatro miradas convergen en el mismo punto: la Generación del estallido es la única ruptura generacional real en Gobierno, Parlamento, Partidos y FF.AA. Iglesia es la excepción — ahí la señal es débil y depende de qué tan potente sea la comparación específica.

## Estado

Ponencia aceptada; artículo completo en preparación (fecha límite: 7 de noviembre de 2026).

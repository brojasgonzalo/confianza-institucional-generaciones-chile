# La confianza ya viene: edad, cohortes y períodos en la confianza institucional del Chile de los últimos 20 años

Gonzalo Bustamante Rojas & Alonso Quintero Contreras

<sub>Ponencia aceptada en el 4to Congreso Latinoamericano de Ciencias Sociales y Gobierno de la Triada 2026 (PUC Chile / Universidad de los Andes Colombia / Tec de Monterrey), 1-2 de octubre de 2026, campus Ciudad de México.</sub>

## Qué hace este análisis

Un análisis edad-período-cohorte (APC) de la confianza institucional en Chile (Gobierno, Parlamento, Partidos, Fuerzas Armadas, Iglesia), usando el panel armonizado de la Encuesta Bicentenario PUCV (2006-2025). La pregunta central:

*¿Existe una ruptura generacional real en la confianza institucional chilena, distinta del efecto de la edad o la coyuntura del momento (efecto de período), y si existe, dónde se ubica?*

Se estimaron tres especificaciones multinivel de la variable dependiente en paralelo (binaria top-2-box, continua z-score, ordinal completa), con edad, sexo, educación y nivel socioeconómico (NSE) como controles, y se puso a prueba la elección de la frontera generacional contra tres esquemas de cohorte alternativos: una taxonomía generacional importada tipo Silent/Boomer/X/Millennial/Z (del Solar & Fernández, 2024), una periodización histórico-local propia del proyecto (Araujo & Martuccelli, 2012; Krosnick & Alwin, 1989; Didier, 2017), y un corte único de transición democrática (Balcells & Villamil, 2026) — 225 tests de Wald en total.

**Sobre el aparato teórico de generaciones:** todas las estimaciones parten de cohortes quinquenales como base. Sobre esta se pusieron a prueba tres esquemas candidatos de dónde debería estar el quiebre real ("encrucijadas", `Principal_NSE/tabla_4_wald_cohortes.csv`): **(1)** la taxonomía generacional importada tipo Silenciosa/Boomer/X/Millennial/Z, popular en reportes chilenos (del Solar & Fernández, 2024) pero que Didier (2017) critica por ser fronteras sin anclaje en la experiencia histórica local; **(2)** una periodización histórico-local propia del proyecto, inspirada en el argumento de Araujo & Martuccelli (2012) de que la subjetividad se forma en condiciones históricas concretas, extendida con la Generación del estallido siguiendo la lógica de "años impresionables" de Mannheim (1928) y Krosnick & Alwin (1989); y **(3)** un corte único de edad-en-la-transición-democrática estilo Balcells & Villamil (2026), prácticamente rechazado en las ~20 pruebas.

## Dos momentos de testeo de cohortes

El diseño separa dos preguntas distintas, en ese orden:

**1. ¿Existe algún efecto de cohorte?** (`Principal_NSE/lr_bargsted_maldonado.csv`) — un test de Wald conjunto sobre los 13 coeficientes de `cohort5` contra la base (H₀: todos son cero a la vez), calculado sobre el mismo modelo completo de la Sección 2/6 del dofile principal. Es la réplica del chequeo global de Bargsted & Maldonado (2018) — ellos preguntan si el bloque de cohorte aporta algo, no dónde. Significativo (p<0.0001) en las 15 combinaciones de institución × especificación; es la condición necesaria para que valga la pena buscar una frontera puntual.

  Nota metodológica: Bargsted & Maldonado testean esto con razón de verosimilitud (LR). Se intentó replicar ese test exactamente (columnas `chi2`/`df`/`p` del mismo csv), pero bajo `vce(robust)` — necesario en este proyecto porque los modelos usan `pweight` para corregir por el diseño muestral, algo que ellos no hacen — `lrtest` reporta grados de libertad muy por debajo de los 13 esperados (hasta indefinidos en dos casos), aparentemente por cómo Stata computa `e(rank)` en `melogit`/`meologit` bajo errores robustos, no por dummies de cohorte omitidos (se descartó esa hipótesis en `Auxiliar_NSE/diagnostico_omitidas_cohort5.csv`, con dos chequeos distintos). El test de Wald conjunto no depende de `e(rank)` y da resultados estables (df=13 en 13/15 casos; Gobierno queda en df=12 en las tres especificaciones, por colinealidad entre dos de sus coeficientes de cohorte al testearlos juntos — no afecta la significancia, que sigue siendo p<0.0001).

**2. ¿Dónde está exactamente el quiebre?** (`Principal_NSE/tabla_4_wald_cohortes.csv`) — los 225 tests de Wald de frontera propios del proyecto (Sección 6 del dofile principal): comparaciones puntuales entre quinquenios contiguos o entre bloques de un mismo esquema teórico. Esta es la pieza metodológica que no está en Bargsted & Maldonado ni en la literatura APC revisada (ver más abajo) — es el aporte propio.

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
├── cobertura_variables.do                     # Autocontenido, cero estimación — cobertura de datos por ola
├── lr_bargsted_maldonado.do                   # Autocontenido, 30 modelos — test global de cohorte
│                                               # (LR de Bargsted & Maldonado + Wald conjunto, ver arriba)
├── diagnostico_omitidas_cohort5.do            # Autocontenido, 15 modelos — chequea si algún dummy de
│                                               # cohort5 se cae por colinealidad en el modelo completo
├── Principal_NSE/                             # Tablas y gráficos centrales (especificación con control
│   │                                           # de NSE — es la corrida vigente)
│   ├── tabla_1c_ordinal.rtf                   # Tabla de resultados — especificación ordinal, 5 instituciones
│   ├── tabla_4_wald_cohortes.csv              # Los 225 tests de Wald de frontera de las 3 encrucijadas
│   ├── lr_bargsted_maldonado.csv              # Test global de cohorte (momento 1, ver arriba)
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
├── Auxiliar_NSE/                               # Robustez y diagnóstico (con NSE)
│   ├── tabla_1a_binaria.rtf / tabla_1b_continua.rtf
│   ├── 1a_binaria_*.png / 1b_continua_{parl,part}.png / 1c_ordinal_{gob,ffaa,igl}.png  # Contraparte
│   │                                           # de cada gráfico principal, misma conclusión sustantiva
│   ├── tabla_2*_robustez_teorica.rtf           # Robustez con cohortes histórico-generacionales
│   ├── tabla_3_diagnostico_normalidad.csv      # Diagnóstico de residuos (skewness/kurtosis)
│   └── diagnostico_omitidas_cohort5.csv        # Chequeo de dummies de cohorte omitidos (ver arriba)
├── Cohortes teóricas_NSE/                      # Comparación descartada: márgenes con cohort_teorica
│   │                                           # (5 bloques históricos) en vez de cohort5 (14
│   │                                           # quinquenios) — se probó y no mejora nada, en algunos
│   │                                           # casos diluye la señal más fuerte (ver metodología)
│   └── 1{b,c}_{continua,ordinal}_teo_*.png
├── Principal/ Auxiliar/ Cohortes teóricas/     # Corrida anterior, sin control de NSE — se mantiene
│                                               # intacta como referencia, no es la vigente
└── Construcción del panel/
    └── build_panel_bicentenario_armonizado.do  # Script que arma el panel 2006-2025 a partir
                                                  # de las bases anuales de Bicentenario
```

## Estimaciones

**Estimación continua** (z-score de la escala 1-5, normalizada por año): es la que más potencia estadística da, pero asume que los residuos del modelo son normales. Se testeó ese supuesto (ver `Auxiliar_NSE/tabla_3_diagnostico_normalidad.csv`, histogramas y QQ-plots en `Auxiliar_NSE/3_normalidad_*.png`) y se encontró que se rompe en serio justo en Parlamento y Partidos. En FF.AA. la violación es prácticamente nula.

**Estimación binaria** (top-2-box): se dicotomizó la variable. Este tipo de modelo no impone normalidad, pero dicotomizar tiene un costo conocido: al colapsar 5 categorías a 2, se pierde información y potencia estadística — de hecho, la especificación binaria falla en detectar la frontera generacional justo en Parlamento y Partidos, las mismas dos instituciones donde ya se sabía que había sesgo de piso. La continua y la ordinal sí la detectan ahí sin problema.

**Estimación ordinal**: soluciona los problemas de las dos anteriores. Usa toda la información de la escala 1-5 (no pierde potencia como la binaria) y no asume normalidad de la variable observada — solo de una variable latente subyacente con puntos de corte libres, que sí se puede estimar sin ese supuesto. Por eso quedó como la especificación principal (`Principal_NSE/tabla_1c_ordinal.rtf`).

## Resultados

De todas las fronteras candidatas, solo una sobrevive de forma robusta a la identificación de la ruptura generacional: 1994/1995, la Generación del estallido. Robusta en las tres especificaciones para Gobierno y FF.AA.; robusta en continua y ordinal para Parlamento y Partidos; en Iglesia el patrón es mucho más débil y depende de la especificación. Esa frontera puntual solo tiene sentido buscarla porque, antes, el test de Wald conjunto confirma que existe *algún* efecto de cohorte en las 15 combinaciones de institución × especificación (ver "Dos momentos de testeo de cohortes" arriba).

La evidencia de esa convergencia, en cinco ángulos distintos:

1. **`lr_bargsted_maldonado.csv`** — el test global de cohorte (momento 1): ¿hay algo que buscar?
2. **`tabla_4_wald_cohortes.csv`** — los 225 tests de Wald de frontera, las tres encrucijadas completas (momento 2).
3. **`8_specification_curve.png`** — las 10 fronteras candidatas de las tres encrucijadas juntas en una sola figura (curva de especificaciones / *multiverse analysis*, Simonsohn, Simmons & Nelson 2020; Steegen et al. 2016): de un vistazo, cuál corte sobrevive y cuáles no.
4. **`5_forest_encrucijadas.png`** — dentro del esquema quinquenal, las 13 fronteras entre cohortes consecutivas: dónde exactamente, al detalle más fino posible con este panel, se concentra el quiebre.
5. **`4_brecha_estallido.png`** / **`7_brecha_estallido_prob.png`** — el contraste final ya simplificado a una sola variable binaria (pre/post 1995), en dos escalas (z-score y % que confía), con test de significancia impreso en el csv que acompaña a la segunda.

## Datos

Este análisis usa el panel armonizado de la Encuesta Bicentenario (PUCV), 2006-2025, 18 olas. Los microdatos **no** están incluidos en este repositorio — no se encontró una licencia explícita que autorice su redistribución pública; deben solicitarse directamente a la Encuesta Bicentenario (PUCV).

## Especificación metodológica

- **Modelo APC**: cohorte y edad como efectos fijos (edad con término cuadrático), período como intercepto aleatorio por año de encuesta — siguiendo a Bargsted & Maldonado (2018), quienes son también la fuente del esquema de cohortes quinquenales. Su propio chequeo de significancia global del bloque de cohorte (LR test) se replicó y se documenta en la sección "Dos momentos de testeo de cohortes" — no así sus tests de frontera puntual, que son un desarrollo propio de este proyecto.
- **Tres especificaciones de DV**: binaria top-2-box (`melogit`), continua z-score por año (`mixed`), ordinal completa 1-5 (`meologit`). La ordinal es la recomendada como principal para las tablas de resultados: usa toda la información de la escala sin asumir normalidad de la variable observada. El diagnóstico de residuos (`Auxiliar_NSE/tabla_3_diagnostico_normalidad.csv`) confirma que esa normalidad se rompe en serio en Parlamento y Partidos (mayor sesgo de piso) — y el test de Wald de la frontera 1994/1995 lo demuestra empíricamente: la binaria falla en detectar la ruptura ahí, mientras ordinal y continua sí la detectan.
- **Gráficos de márgenes**: la elección entre continua y ordinal se hace institución por institución según ese mismo diagnóstico — continua donde la violación es leve (Gobierno, FF.AA., Iglesia), ordinal donde es seria (Parlamento, Partidos).
- **Controles**: sexo, nivel educativo (`educ4`) y nivel socioeconómico armonizado (`nse4`) en todas las estimaciones.
- **Diseño muestral**: ponderador incorporado como `pweight` con errores estándar robustos (`vce(robust)`) en todos los modelos multinivel, ya que Stata no propaga correctamente el prefijo `svy:` a través de efectos aleatorios anidados. Esta decisión es la razón por la que el LR test de Bargsted & Maldonado no se pudo replicar de forma confiable (ver arriba): con `pweight`, Stata requiere varianza tipo robusta, y `vce(robust)` no es compatible con la teoría asintótica bajo la que se construye un LR test clásico. El test de Wald conjunto no tiene ese problema porque no depende de `e(rank)`.
- **Cohortes**: quinquenales (Bargsted & Maldonado 2018) como especificación principal; cohortes histórico-generacionales (inspiradas en Araujo & Martuccelli 2012, extendidas con la Generación del estallido siguiendo Mannheim 1928 y Krosnick & Alwin 1989) como robustez con etiquetas interpretables — se probó también como alternativa visual a los márgenes quinquenales y se descartó (ver `Cohortes teóricas_NSE/`).
- **Fronteras candidatas fuera de la grilla quinquenal** (taxonomía importada y corte único Balcells): se testean con una variable auxiliar (`cohort_check`) que usa resolución fina solo alrededor de cada corte candidato — ventana de ±2 años de nacimiento a cada lado (año individual, ±1, para el par Balcells por estar sus dos cortes a solo 2 años de distancia). Esto evita el problema de comparar generaciones completas: si la confianza sube o baja de forma gradual con cada cohorte de nacimiento sin ningún quiebre real, comparar promedios de grupos amplios da "significativo" en casi cualquier corte que se elija — comparar años adyacentes al borde específico sí puede distinguir un quiebre genuino de una tendencia suave.

## Antecedentes metodológicos revisados

Ningún paper revisado hace exactamente el test de frontera puntual de la Sección 6, pero varios abordan piezas del mismo problema (elegir/testear dónde poner los límites de una cohorte en vez de asumirlos):

- **Bargsted & Maldonado (2018)**, *JPLA* — fuente directa del modelo (edad/cohorte fijos, período aleatorio) y del esquema quinquenal; su test de significancia de cohorte es global (LR), no de frontera.
- **Frenk, Yang & Land (2013)**, *Social Forces* — HAPC con cohorte como efecto aleatorio; testean significancia del bloque vía F-test de componentes de varianza, tampoco fronteras puntuales.
- **Grasso (2014)**, *Electoral Studies* — testea la categorización de cohortes con GAM/GAMM (splines) en vez de tests de igualdad de coeficientes; mismo objetivo, herramienta distinta.
- **Rudolph, Costanza et al. (2021)**, *Work, Aging and Retirement* — crítica metodológica a las categorías generacionales impuestas a priori; respaldo conceptual para poner a prueba el esquema importado (encrucijada 1) en vez de asumirlo.

## Estado

Ponencia aceptada; artículo completo en preparación (fecha límite: 7 de noviembre de 2026).

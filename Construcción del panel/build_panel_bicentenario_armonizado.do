/*=============================================================================
  BUILD_PANEL_BICENTENARIO_ARMONIZADO.DO
  Encuesta Bicentenario 2006–2025 — Panel armonizado

  NOTAS CRÍTICAS:
  - 2020 EXCLUIDO: bicentenario_2020.dta = copia idéntica de 2022 (confirmado)
  - 2008, 2009, 2010, 2011, 2014: sin variable region (solo macrozona)
  - 2025: region en string (nom_region) → region = missing en panel
  - 2009: pond_x tiene 249 obs con Stata-missing (> 1e10) → se excluyen
  - 2024: ponderador = POND (mayúscula); estrato = encode(estrato_upm)
  - 2018: cp04=ecivil, cp05=sit_laboral (invertido vs. 2019+) — documentado
  - 2021: ingreso fragmentado en cp13_1–cp13_7 → missing en panel
  - 2014: afil_raw = r10 (trayectoria de creencia, NO denominación) → missing
  - 2012: creedios_raw = q94 (ítem actitudinal, NO creencia) → missing
  - 2011: creedios_raw no disponible; slab_raw (q199) etiquetada con label ecivil
  - 2019, 2021: confint (r10) = "sin ayuda de la religión" → framing diferente → missing
  - 2024: confint (s11) = actitudes hacia inmigrantes → missing
  - 2024: convivencia = i_1_f34 con framing diferente → missing
  - 2024: sit_lab3 parcial (cp07 código 5 agrupa cesante+inactivo)

  Creado: 2026-05
=============================================================================*/

version 15
set more off

* ─── RUTAS ──────────────────────────────────────────────────────────────────
global SRC `"C:\Users\gonza\Dropbox\Proyectos personales\01.- Desarrollo investigación\Quintero, Bustamante\Datos\Encuesta Bicentenario\Conjunto de datos"'
global OUT `"C:\Users\gonza\Dropbox\Proyectos personales\02.- DATOS\Bicentenario"'

* ─── TEMPFILES ──────────────────────────────────────────────────────────────
tempfile yr2006 yr2007 yr2008 yr2009 yr2010 yr2011 yr2012 yr2013 yr2014 ///
         yr2016 yr2017 yr2018 yr2019 yr2021 yr2022 yr2023 yr2024 yr2025

* ─── LISTA DE VARIABLES TARGET (keep idéntico en cada bloque) ───────────────
local KVARS year ponderador folio_mapa estrato                            ///
    edad sexo region macrozona ingreso gse                                ///
    educ_raw ecivil_raw slab_raw afil_raw creedios_raw misa_raw           ///
    homo_casar homo_adopt convivencia matrimonio aborto_vio aborto_gen    ///
    rol_genero confgob_raw configla_raw confffaa_raw confpart_raw confparl_raw confint pospolcont pospolcat ///
    n_hijos_vivos tiene_hijos


/*============================================================================
  BLOQUE POR AÑO
  Al final de cada bloque: ensure + keep + save
============================================================================*/

* ─────────────────────────────────────────────────────────────────────────────
* 2006
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2006.dta", clear
gen int year = 2006

capture rename pond_x ponderador
capture rename folio folio_mapa              // 2006: PSU en variable "folio"
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename zona macrozona
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .
capture rename p84 ingreso

capture rename p22a  educ_raw
capture rename p2    ecivil_raw
capture rename p73_2 slab_raw
capture rename p38a  afil_raw
capture rename p41a  creedios_raw
capture rename p39a  misa_raw

capture rename p13g  homo_casar
capture rename p13e  convivencia
capture rename p13a  matrimonio
capture rename p27b  rol_genero
capture rename p15d  aborto_vio
capture rename p14   aborto_gen
capture rename p48_3 confgob_raw
capture rename p48_1 configla_raw
capture rename p48_2 confffaa_raw
capture rename p48_9 confpart_raw
capture rename p48_7 confparl_raw
capture rename p37a  confint
gen float pospolcont = p44 if p44 >= 1 & p44 <= 10
gen byte  pospolcat  = .
gen byte  homo_adopt = .

capture rename p7 n_hijos_vivos              // 2006: "Cuantos hijos vivos tiene"
if _rc != 0 gen byte n_hijos_vivos = .
gen byte tiene_hijos = (n_hijos_vivos > 0) if !missing(n_hijos_vivos)

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2006'


* ─────────────────────────────────────────────────────────────────────────────
* 2007
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2007.dta", clear
gen int year = 2007

capture rename pond_x ponderador
capture rename folio folio_mapa              // 2007: PSU en variable "folio"
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename zona macrozona
capture confirm variable macrozona
if _rc != 0 gen byte macrozona = .
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .
gen byte ingreso = .

capture rename p92   educ_raw
capture rename p87   ecivil_raw
capture rename p88_1 slab_raw
capture rename p27_2 rol_genero
capture rename p23   aborto_gen  // 2007: "¿debería la mujer tener derecho a realizarse el aborto?"
capture rename p29   confint     // 2007: "¿se puede confiar en la mayoría de personas?" (vecindario)
gen float pospolcont = p44 if p44 >= 1 & p44 <= 10

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2007'


* ─────────────────────────────────────────────────────────────────────────────
* 2008
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2008.dta", clear
gen int year = 2008

capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename q260  edad
capture rename q258  sexo
gen byte region = .
capture rename zona_x macrozona
capture rename q188  ingreso
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename q159 educ_raw
capture rename q160 ecivil_raw
capture rename q178 slab_raw
capture rename q34  afil_raw
capture rename q47  creedios_raw
capture rename q38  misa_raw

capture rename q20  homo_casar    // 1=Acuerdo → INVERTIR en parte 4
capture rename q18  convivencia   // 1=Acuerdo → INVERTIR
capture rename q14  matrimonio    // 1=Acuerdo → INVERTIR
capture rename q11d aborto_vio
capture rename q10  aborto_gen
gen float pospolcont = q113 if q113 >= 1 & q113 <= 10
gen byte  pospolcat  = .

capture rename q167 n_hijos_vivos            // 2008: "Nº de hijos vivos que tiene"
if _rc != 0 gen byte n_hijos_vivos = .
gen byte tiene_hijos = (n_hijos_vivos > 0) if !missing(n_hijos_vivos)

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2008'


* ─────────────────────────────────────────────────────────────────────────────
* 2009
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2009.dta", clear
gen int year = 2009

replace pond_x = . if pond_x > 1e10 & !missing(pond_x)   // excluye Stata-missing
capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename q191  edad
capture rename q189  sexo
gen byte region = .
capture rename zona_x macrozona
capture rename q180  ingreso
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename q155 educ_raw
capture rename q158 ecivil_raw
capture rename q170 slab_raw
capture rename q66  afil_raw
capture rename q70  creedios_raw
capture rename q76  misa_raw

capture rename q53d aborto_vio
capture rename q52  aborto_gen
gen float pospolcont = q139 if q139 >= 1 & q139 <= 10
gen byte  pospolcat  = .

capture rename q1 n_hijos_vivos              // 2009: "Hijos vivos que tiene Ud."
if _rc != 0 gen byte n_hijos_vivos = .
gen byte tiene_hijos = (n_hijos_vivos > 0) if !missing(n_hijos_vivos)

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2009'


* ─────────────────────────────────────────────────────────────────────────────
* 2010
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2010.dta", clear
gen int year = 2010

capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

* 2010: la fuente tiene 'edad' como variable binaria recodificada (1=≤40, 2=>40)
* y 'edad_x' como edad continua real. capture rename q310 edad falla silenciosamente.
drop edad
capture rename edad_x edad   // edad continua real (idéntica a q310, ambas 18-92)
capture rename q309  sexo
gen byte region = .
capture rename zona_x macrozona
capture rename q300  ingreso
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename q273 educ_raw
capture rename q276 ecivil_raw
capture rename q290 slab_raw
capture rename q77  afil_raw
capture rename q97  creedios_raw
capture rename q81  misa_raw

capture rename q61  matrimonio    // 1=Acuerdo → INVERTIR en parte 4
capture rename q8d  aborto_vio
capture rename q7   aborto_gen
capture rename q151 confgob_raw   // 1=Mucha → INVERTIR en parte 4
capture rename q150 configla_raw  // 1=Mucha → INVERTIR
capture rename q152 confffaa_raw  // 1=Mucha → INVERTIR
capture rename q155 confpart_raw  // 1=Mucha → INVERTIR
capture rename q156 confparl_raw  // 1=Mucha → INVERTIR
gen float pospolcont = .
gen byte  pospolcat  = .

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2010'


* ─────────────────────────────────────────────────────────────────────────────
* 2011
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2011.dta", clear
gen int year = 2011

capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename q220  edad
capture rename q219  sexo
gen byte region = .
capture rename zona_x macrozona
capture rename q210  ingreso
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename q193       educ_raw
capture rename estadocivil ecivil_raw
capture rename q199        slab_raw    // etiquetada con label de ecivil — verificar en cuestionario
capture rename religion    afil_raw
gen byte creedios_raw = .      // no disponible en 2011
capture rename q75         misa_raw

capture rename q62  homo_casar  // 1=Acuerdo → INVERTIR
capture rename q61  convivencia // 1=Acuerdo → INVERTIR
capture rename q60  matrimonio  // 1=Acuerdo → INVERTIR
capture rename q64  rol_genero  // 1=Acuerdo → INVERTIR
capture rename q56d aborto_vio
capture rename q55  aborto_gen
capture rename q122 confgob_raw   // 1=Mucha → INVERTIR
capture rename q123 configla_raw  // 1=Mucha → INVERTIR
capture rename q121 confffaa_raw  // 1=Mucha → INVERTIR
capture rename q126 confpart_raw  // 1=Mucha → INVERTIR
capture rename q127 confparl_raw  // 1=Mucha → INVERTIR
gen float pospolcont = q180 if q180 >= 1 & q180 <= 10
gen byte  pospolcat  = .

capture rename nhijos n_hijos_vivos          // 2011: conteo en variable "nhijos"
if _rc != 0 gen byte n_hijos_vivos = .
gen byte tiene_hijos = (n_hijos_vivos > 0) if !missing(n_hijos_vivos)

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2011'


* ─────────────────────────────────────────────────────────────────────────────
* 2012
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2012.dta", clear
gen int year = 2012

capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename q237  edad
capture rename q236  sexo
* region disponible en 2012
capture rename zona_x macrozona
capture rename q227  ingreso
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename q209 educ_raw
capture rename q216 ecivil_raw
capture rename q217 slab_raw
capture rename q57  afil_raw
gen byte creedios_raw = .   // q94 = ítem actitudinal, NO creencia — excluido
capture rename q61  misa_raw

capture rename q154d aborto_vio
capture rename q153  aborto_gen
capture rename q132  confgob_raw   // 1=Mucha → INVERTIR
capture rename q133  configla_raw  // 1=Mucha → INVERTIR
capture rename q131  confffaa_raw  // 1=Mucha → INVERTIR
capture rename q136  confpart_raw  // 1=Mucha → INVERTIR
capture rename q137  confparl_raw  // 1=Mucha → INVERTIR
gen float pospolcont = q138 if q138 >= 1 & q138 <= 10
gen byte  pospolcat  = .

capture rename q215 n_hijos_vivos            // 2012: conteo hijos vivos
if _rc != 0 gen byte n_hijos_vivos = .
gen byte tiene_hijos = (n_hijos_vivos > 0) if !missing(n_hijos_vivos)

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2012'


* ─────────────────────────────────────────────────────────────────────────────
* 2013
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2013.dta", clear
gen int year = 2013

capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename q253  edad
capture rename q250  sexo
* region disponible en 2013
capture rename zona_x macrozona
capture rename q235  ingreso
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename q217 educ_raw
capture rename q224 ecivil_raw
capture rename q225 slab_raw
capture rename q75  afil_raw
capture rename q94  creedios_raw
capture rename q90  misa_raw

capture rename q70  homo_casar  // 1=Acuerdo → INVERTIR
capture rename q69  convivencia // 1=Acuerdo → INVERTIR
capture rename q68  matrimonio  // 1=Acuerdo → INVERTIR
capture rename q73d aborto_vio
capture rename q72  aborto_gen
gen byte confgob_raw  = .   // batería 2013 no incluye gobierno (q112=Igl.Cat, etc.)
capture rename q112 configla_raw    // 1=Mucha → INVERTIR
gen byte confffaa_raw = .           // 2013: sin FF.AA. en batería institucional
gen byte confpart_raw = .           // 2013: sin Partidos en batería institucional
capture rename q114 confparl_raw    // 1=Mucha → INVERTIR
gen float pospolcont = q137 if q137 >= 1 & q137 <= 10
gen byte  pospolcat  = .

capture rename q222 n_hijos_vivos            // 2013: conteo hijos vivos
if _rc != 0 gen byte n_hijos_vivos = .
gen byte tiene_hijos = (n_hijos_vivos > 0) if !missing(n_hijos_vivos)

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2013'


* ─────────────────────────────────────────────────────────────────────────────
* 2014
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2014.dta", clear
gen int year = 2014

capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

* edad, sexo → ya nombrados en 2014
gen byte region = .
capture rename area macrozona
capture rename cp_8 ingreso
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename cp_1 educ_raw
capture rename cp_3 ecivil_raw
gen byte slab_raw    = .    // sit_laboral no identificada en 2014
capture rename r10  afil_raw         // ADVERTENCIA: r10 = trayectoria de creencia, NO denominación religiosa
capture rename r9   creedios_raw
capture rename r6   misa_raw

capture rename f23 homo_casar   // 1=Acuerdo → INVERTIR
capture rename f26 homo_adopt   // 1=Acuerdo → INVERTIR
capture rename f24 convivencia  // 1=Acuerdo → INVERTIR
capture rename f25 matrimonio   // 1=Acuerdo → INVERTIR
capture rename f32 aborto_vio
capture rename f28 aborto_gen
gen byte confgob_raw  = .           // 2014: sin Gobierno en batería
capture rename c1  configla_raw // 1=Mucha → INVERTIR
capture rename c8  confffaa_raw // 1=Mucha → INVERTIR
capture rename c7  confpart_raw // 1=Mucha → INVERTIR
capture rename c3  confparl_raw // 1=Mucha → INVERTIR
gen float pospolcont = s26 if s26 >= 1 & s26 <= 10
gen byte  pospolcat  = .

gen byte n_hijos_vivos = .                   // 2014: sin conteo; solo binario
capture rename f1 tiene_hijos               // 2014: "¿Tiene usted hijos?" 1=Sí 2=No
if _rc != 0 gen byte tiene_hijos = .
else recode tiene_hijos (2=0)

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2014'


* ─────────────────────────────────────────────────────────────────────────────
* 2016
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2016.dta", clear
gen int year = 2016

capture rename pond_x ponderador
capture rename folio_x folio_mapa            // 2016: PSU en variable "folio_x"
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename edad_x    edad
capture rename sexo_x    sexo
capture rename region_x  region
capture rename zona2     macrozona
capture rename g11       ingreso
capture confirm variable gse_calc_x
if _rc == 0 {
    capture rename gse_calc_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_calc_x gse
        drop gse_old
    }
}
else {
    capture confirm variable gse_x
    if _rc == 0 {
        capture rename gse_x gse
        if _rc != 0 {
            rename gse gse_old
            rename gse_x gse
            drop gse_old
        }
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename cp01  educ_raw
capture rename cp02  ecivil_raw
capture rename cp03  slab_raw
capture rename f01_1 afil_raw
capture rename f04   creedios_raw
capture rename f02_1 misa_raw

* escalas OK (1=Desacuerdo), pero escala 1–6 (código 6=NS/NR → missing en parte 4)
capture rename e01_5 homo_casar
capture rename e01_4 homo_adopt
capture rename e01_1 convivencia
capture rename e01_2 matrimonio
capture rename e10_4 aborto_vio
capture rename e09   aborto_gen
capture rename a07_9 confgob_raw   // OK: 1=Nada, 5=Mucha
capture rename a07_1 configla_raw  // OK
capture rename a07_6 confffaa_raw  // OK: 1=Nada, 5=Mucha
capture rename a07_5 confpart_raw  // OK: 1=Nada, 5=Mucha
capture rename a07_2 confparl_raw  // OK: 1=Nada, 5=Mucha
capture rename e06_1 confint
gen float pospolcont = a06 if a06 >= 1 & a06 <= 10
gen byte  pospolcat  = .

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2016'


* ─────────────────────────────────────────────────────────────────────────────
* 2017
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2017.dta", clear
gen int year = 2017

capture rename pond_x ponderador
capture rename folio_x folio_mapa            // 2017: PSU en variable "folio_x"
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename edad_x    edad
capture rename sexo_x    sexo
capture rename region_x  region
capture rename zona2     macrozona
capture rename cp15      ingreso
capture confirm variable gse_calc_x
if _rc == 0 {
    capture rename gse_calc_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_calc_x gse
        drop gse_old
    }
}
else {
    capture confirm variable gse_x
    if _rc == 0 {
        capture rename gse_x gse
        if _rc != 0 {
            rename gse gse_old
            rename gse_x gse
            drop gse_old
        }
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename cp01     educ_raw
capture rename cp05     ecivil_raw
capture rename cp06     slab_raw
capture rename religion afil_raw
capture rename r04      creedios_raw
gen byte misa_raw = .          // asistencia pendiente confirmar en 2017

capture rename f01_5 homo_casar
capture rename f01_4 homo_adopt
capture rename f01_1 convivencia
capture rename f01_2 matrimonio
capture rename f08_4 aborto_vio
gen byte aborto_gen = .        // no disponible en 2017
capture rename f02_1 rol_genero
capture rename s13_7 confgob_raw
capture rename s13_1 configla_raw
capture rename s13_5 confffaa_raw
capture rename s13_4 confpart_raw
capture rename s13_2 confparl_raw
gen byte confint = .
gen float pospolcont = s11 if s11 >= 1 & s11 <= 10   // s11 en 2017 = posicion_pol
gen byte  pospolcat  = .

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2017'


* ─────────────────────────────────────────────────────────────────────────────
* 2018
* OJO: cp04=ecivil, cp05=sit_laboral (invertido vs 2019+)
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2018.dta", clear
gen int year = 2018

capture rename pond_x ponderador
capture rename folio_unico folio_mapa        // 2018: PSU en variable "folio_unico"
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename d08   edad
capture rename d07   sexo
capture rename cvar4 region
capture rename zona_x macrozona
capture rename cp15  ingreso
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename cp01  educ_raw
capture rename cp04  ecivil_raw   // en 2018 cp04=ecivil (distinto de 2019+ donde cp04=educ)
capture rename cp05  slab_raw     // en 2018 cp05=sit_laboral
capture rename cvar5 afil_raw
capture rename r04   creedios_raw
gen byte misa_raw = .      // pendiente confirmar en 2018

capture rename t_f01_5 homo_casar
capture rename t_f01_4 homo_adopt
capture rename t_f01_1 convivencia
capture rename t_f01_2 matrimonio
capture rename t_f03_4 aborto_vio
capture rename f02     aborto_gen   // sin prefijo t_ — verificar cuestionario 2018
capture rename t_f07_2 rol_genero
capture rename t_s10_7 confgob_raw
capture rename t_s10_1 configla_raw
capture rename t_s10_5 confffaa_raw
capture rename t_s10_4 confpart_raw
capture rename t_s10_2 confparl_raw
capture rename s09     confint
gen float pospolcont = s08 - 1 if s08 >= 2 & s08 <= 6   // s08 usa códigos 2–6
gen byte  pospolcat  = .

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2018'


* ─────────────────────────────────────────────────────────────────────────────
* 2019
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2019.dta", clear
gen int year = 2019

capture rename pond_x ponderador
capture rename folio_x folio_mapa            // 2019: PSU en variable "folio_x"
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename edad_x       edad
capture rename sexo_x       sexo
capture rename region_x     region
capture rename tipo_zona_02 macrozona
capture rename cp15         ingreso
capture confirm variable gse_calc_x
if _rc == 0 {
    capture rename gse_calc_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_calc_x gse
        drop gse_old
    }
}
else {
    capture confirm variable gse_x
    if _rc == 0 {
        capture rename gse_x gse
        if _rc != 0 {
            rename gse gse_old
            rename gse_x gse
            drop gse_old
        }
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename cp01  educ_raw
capture rename cp05  ecivil_raw
capture rename cp06  slab_raw
capture rename r01_1 afil_raw
capture rename r03   creedios_raw
capture rename r02_1 misa_raw

capture rename f01_5 homo_casar   // 1=Acuerdo → INVERTIR
capture rename f01_4 homo_adopt   // 1=Acuerdo → INVERTIR
capture rename f01_1 convivencia  // 1=Acuerdo → INVERTIR
capture rename f01_2 matrimonio   // 1=Acuerdo → INVERTIR
capture rename f03_4 aborto_vio
capture rename f02   aborto_gen
capture rename f04_1 rol_genero   // 1=Acuerdo → INVERTIR
capture rename s07_2 confgob_raw  // 1=Mucha → INVERTIR
capture rename r07_1 configla_raw // 1=Mucha → INVERTIR (batería religiosa 2019)
capture rename s07_1 confffaa_raw // 1=Mucha → INVERTIR
capture rename s07_3 confpart_raw // 1=Mucha → INVERTIR
capture rename s07_4 confparl_raw // 1=Mucha → INVERTIR
gen byte confint = .       // r10 = "sin ayuda de la religión" → framing incompatible
gen float pospolcont = s05 if s05 >= 1 & s05 <= 5
gen byte  pospolcat  = .

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2019'


* ─────────────────────────────────────────────────────────────────────────────
* 2021
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2021.dta", clear
gen int year = 2021

capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

capture rename edad_x   edad
capture rename sexo_x   sexo
capture rename region_x region
capture rename zona     macrozona
gen byte ingreso = .       // fragmentado en cp13_1–cp13_7
capture confirm variable gse_calc_x
if _rc == 0 {
    capture rename gse_calc_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_calc_x gse
        drop gse_old
    }
}
else {
    capture confirm variable gse_x
    if _rc == 0 {
        capture rename gse_x gse
        if _rc != 0 {
            rename gse gse_old
            rename gse_x gse
            drop gse_old
        }
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename cp01  educ_raw
capture rename cp05  ecivil_raw
capture rename cp06  slab_raw
capture rename r01_1 afil_raw
capture rename r03   creedios_raw
gen byte misa_raw = .      // pendiente confirmar en 2021

capture rename f01_5 homo_casar
capture rename f01_4 homo_adopt
capture rename f01_1 convivencia
capture rename f01_2 matrimonio
gen byte aborto_vio = .
capture rename f02   aborto_gen
capture rename f04_1 rol_genero
capture rename s07_2 confgob_raw
capture rename s07_7 configla_raw
capture rename s07_1 confffaa_raw
capture rename s07_3 confpart_raw
capture rename s07_4 confparl_raw
gen byte confint = .       // r10 en 2021 = "sin ayuda de religión" → framing incompatible
gen float pospolcont = .
gen byte  pospolcat  = .   // posicion_pol no disponible en 2021

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2021'


* ─────────────────────────────────────────────────────────────────────────────
* 2022
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2022.dta", clear
gen int year = 2022

capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

* edad, sexo, region → ya nombrados
capture rename zona macrozona
capture rename cp15  ingreso
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename i_1_cp01 educ_raw
capture rename cp05     ecivil_raw
capture rename cp06     slab_raw
gen byte afil_raw = .       // p701 n_valid=0 → sin datos útiles
capture rename p705     creedios_raw
capture rename i_1_p703 misa_raw

* escala 1–7 (6=NS, 7=NR → missing en parte 4); dirección OK
capture rename i_5_p501 homo_casar
capture rename i_4_p501 homo_adopt
capture rename i_1_p501 convivencia
capture rename i_2_p501 matrimonio
gen byte aborto_vio = .
capture rename p503     aborto_gen
capture rename i_1_p502 rol_genero
capture rename i_2_p104 confgob_raw
capture rename i_7_p104 configla_raw
capture rename i_1_p104 confffaa_raw
capture rename i_3_p104 confpart_raw
capture rename i_4_p104 confparl_raw
gen byte confint = .
capture rename pos_politica pospolcat
if _rc != 0 gen byte pospolcat = .
gen float pospolcont = .

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2022'


* ─────────────────────────────────────────────────────────────────────────────
* 2023
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2023.dta", clear
gen int year = 2023

capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 gen int estrato = .

* edad, sexo, region → ya nombrados
capture rename zona macrozona
capture rename cp15  ingreso
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename i_1_cp04_bis educ_raw
capture rename cp05         ecivil_raw
capture rename p57          slab_raw
capture rename i_1_r47      afil_raw
capture rename r50          creedios_raw
capture rename i_1_r48      misa_raw

capture rename i_5_f38 homo_casar
capture rename i_4_f38 homo_adopt
capture rename i_1_f38 convivencia
capture rename i_2_f38 matrimonio
gen byte aborto_vio = .
capture rename f39     aborto_gen
capture rename i_2_s4  confgob_raw
capture rename i_7_s4  configla_raw
capture rename i_1_s4  confffaa_raw
capture rename i_3_s4  confpart_raw
capture rename i_4_s4  confparl_raw
capture rename s11     confint        // OK en 2023 (formulación estándar)
capture rename pos_politica pospolcat
if _rc != 0 gen byte pospolcat = .
gen float pospolcont = .

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2023'


* ─────────────────────────────────────────────────────────────────────────────
* 2024
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2024.dta", clear
gen int year = 2024

capture rename POND ponderador         // 2024 usa POND (mayúscula)
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 {
    capture confirm variable estrato_upm
    if _rc == 0 encode estrato_upm, gen(estrato)
    else gen int estrato = .
}

* edad, sexo, region, zona → ya nombrados
capture rename zona macrozona
capture rename cp15  ingreso
capture confirm variable gse
if _rc != 0 {
    capture rename nse_3 gse
    if _rc != 0 gen byte gse = .
}
* 2024 usa nse_3 (3 cats), no gse_x

capture rename i_1_cp04_bis educ_raw
capture rename cp08         ecivil_raw
capture rename cp07         slab_raw   // código 5 agrupa cesante+inactivo → sit_lab3 parcial
capture rename r44_a        afil_raw
capture rename r47          creedios_raw
capture rename i_1_r45      misa_raw

capture rename i_5_f34 homo_casar
capture rename i_4_f34 homo_adopt
gen byte convivencia = .       // i_1_f34 tiene framing incompatible
capture rename i_2_f34 matrimonio
gen byte aborto_vio = .
capture rename f35     aborto_gen
capture rename i_2_s4  confgob_raw
capture rename i_7_s4  configla_raw
capture rename i_1_s4  confffaa_raw
capture rename i_3_s4  confpart_raw
capture rename i_4_s4  confparl_raw
gen byte confint = .           // s11 en 2024 = actitudes hacia inmigrantes, NO confianza interpersonal
capture rename pos_politica pospolcat
if _rc != 0 gen byte pospolcat = .
gen float pospolcont = cp03 if cp03 >= 1 & cp03 <= 5   // cp03 = continua 1–5

capture rename f37 n_hijos_vivos             // 2024: conteo hijos vivos
if _rc != 0 gen byte n_hijos_vivos = .
gen byte tiene_hijos = (n_hijos_vivos > 0) if !missing(n_hijos_vivos)

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2024'


* ─────────────────────────────────────────────────────────────────────────────
* 2025
* ─────────────────────────────────────────────────────────────────────────────
use "$SRC/bicentenario_2025.dta", clear
gen int year = 2025

capture rename pond_x ponderador
capture confirm variable folio_mapa
if _rc != 0 gen long folio_mapa = .
capture confirm variable estrato
if _rc != 0 {
    capture confirm variable estrato_upm
    if _rc == 0 encode estrato_upm, gen(estrato)
    else gen int estrato = .
}

capture rename edad_sel_fin edad
capture rename sexo_sel_fin sexo
gen byte region = .            // nom_region es string, sin código numérico disponible
capture rename zona macrozona
capture confirm variable ingreso_grupo
if _rc == 0 {
    capture rename ingreso_grupo ingreso
    if _rc != 0 {
        rename ingreso ingreso_old
        rename ingreso_grupo ingreso
        drop ingreso_old
    }
}
else {
    capture confirm variable ingreso
    if _rc != 0 {
        capture rename cp17 ingreso
        if _rc != 0 gen byte ingreso = .
    }
}
capture confirm variable gse_x
if _rc == 0 {
    capture rename gse_x gse
    if _rc != 0 {
        rename gse gse_old
        rename gse_x gse
        drop gse_old
    }
}
capture confirm variable gse
if _rc != 0 gen byte gse = .

capture rename p56   educ_raw
capture rename p58   ecivil_raw
capture rename p57   slab_raw
capture rename p43_1 afil_raw
capture rename p46   creedios_raw
capture rename p44_1 misa_raw

capture rename p29_5 homo_casar
capture rename p29_4 homo_adopt
capture rename p29_1 convivencia
capture rename p29_2 matrimonio
gen byte aborto_vio = .
capture rename p30   aborto_gen
capture rename p6_2  confgob_raw
capture rename p6_7  configla_raw
capture rename p6_1  confffaa_raw
capture rename p6_3  confpart_raw
capture rename p6_4  confparl_raw
capture rename p26   confint
capture rename pos_politica pospolcat
if _rc != 0 gen byte pospolcat = .
gen float pospolcont = .

capture rename p33 n_hijos_vivos             // 2025: conteo hijos (solo respondido si tiene_hijos=2)
if _rc != 0 gen byte n_hijos_vivos = .
* tiene_hijos: 1=No tiene hijos → 0, 2=Sí tiene hijos → 1
capture confirm variable tiene_hijos
if _rc != 0 gen byte tiene_hijos = .
else recode tiene_hijos (1=0) (2=1)

foreach v of local KVARS {
    capture confirm variable `v'
    if _rc != 0 gen byte `v' = .
}
foreach v in region macrozona estrato ingreso gse edad {
    capture confirm string variable `v'
    if _rc == 0 destring `v', replace force
}
keep `KVARS'
save `yr2025'


/*============================================================================
  APPEND
============================================================================*/

use `yr2006', clear
foreach yr in 2007 2008 2009 2010 2011 2012 2013 2014 ///
              2016 2017 2018 2019 2021 2022 2023 2024 2025 {
    append using `yr`yr''
}
sort year
count


/*============================================================================
  PARTE 3: RECODES CATEGÓRICOS
============================================================================*/

* ─── educ4 ──────────────────────────────────────────────────────────────────
gen byte educ4 = .
label define educ4lbl 1 "Básica o menos" 2 "Media incompleta" ///
                      3 "Media completa/técnica" 4 "Superior"

* 2006–2014: 10–12 categorías
replace educ4 = 1 if inrange(educ_raw,  1,  2) & inrange(year, 2006, 2014)
replace educ4 = 2 if inrange(educ_raw,  3,  4) & inrange(year, 2006, 2014)
replace educ4 = 3 if inrange(educ_raw,  5,  7) & inrange(year, 2006, 2014)
replace educ4 = 4 if inrange(educ_raw,  8, 12) & inrange(year, 2006, 2014)

* 2016–2024: 17–19 categorías (cp01 / i_1_cp04_bis con preescolar)
replace educ4 = 1 if inrange(educ_raw,  1,  6) & inrange(year, 2016, 2024)
replace educ4 = 2 if inrange(educ_raw,  7,  8) & inrange(year, 2016, 2024)
replace educ4 = 3 if inrange(educ_raw,  9, 13) & inrange(year, 2016, 2024)
replace educ4 = 4 if inrange(educ_raw, 14, 19) & inrange(year, 2016, 2024)

* 2025: p56, 10 categorías
replace educ4 = 1 if educ_raw == 1               & year == 2025
replace educ4 = 2 if inrange(educ_raw, 2, 3)     & year == 2025
replace educ4 = 3 if inrange(educ_raw, 4, 7)     & year == 2025
replace educ4 = 4 if inrange(educ_raw, 8, 10)    & year == 2025

label values educ4 educ4lbl
label var educ4 "Educación armonizada (4 categorías)"


* ─── ecivil5 ─────────────────────────────────────────────────────────────────
gen byte ecivil5 = .
label define ecivil5lbl 1 "Soltero/a sin pareja"    2 "Conviviente/pareja" ///
                        3 "Casado/a"                4 "Sep/Div/Anuladx"    ///
                        5 "Viudo/a"

* 2006–2014: 1=Solt.s/par 2=Solt.c/par 3=Casado 4=Vuelto a casar 5=Sep 6=Viudo
replace ecivil5 = 1 if ecivil_raw == 1              & inrange(year, 2006, 2014)
replace ecivil5 = 2 if ecivil_raw == 2              & inrange(year, 2006, 2014)
replace ecivil5 = 3 if inlist(ecivil_raw, 3, 4)     & inrange(year, 2006, 2014)
replace ecivil5 = 4 if ecivil_raw == 5              & inrange(year, 2006, 2014)
replace ecivil5 = 5 if ecivil_raw == 6              & inrange(year, 2006, 2014)
* código 7 → missing (verificar en datos: pocos casos)

* 2016–2024: 1=Cas 2=Conv.s/c 3=Conv.civil 4=Anu 5=Sep 6=Div 7=Viudo 8=¿Soltero?
* código 8 asumido = Soltero basado en n=534–650 — VERIFICAR con cuestionario
replace ecivil5 = 1 if ecivil_raw == 8              & inrange(year, 2016, 2024)
replace ecivil5 = 2 if inlist(ecivil_raw, 2, 3)     & inrange(year, 2016, 2024)
replace ecivil5 = 3 if ecivil_raw == 1              & inrange(year, 2016, 2024)
replace ecivil5 = 4 if inlist(ecivil_raw, 4, 5, 6)  & inrange(year, 2016, 2024)
replace ecivil5 = 5 if ecivil_raw == 7              & inrange(year, 2016, 2024)
* 9, 88, 99 → missing

* 2025: 1=Cas 2=Conv 3=Conv.civil 4=Anu/Sep 5=Viudo 6=Soltero; -99/-88=.
replace ecivil5 = 1 if ecivil_raw == 6              & year == 2025
replace ecivil5 = 2 if inlist(ecivil_raw, 2, 3)     & year == 2025
replace ecivil5 = 3 if ecivil_raw == 1              & year == 2025
replace ecivil5 = 4 if ecivil_raw == 4              & year == 2025
replace ecivil5 = 5 if ecivil_raw == 5              & year == 2025

label values ecivil5 ecivil5lbl
label var ecivil5 "Estado civil armonizado (5 categorías)"


* ─── sit_lab3 ────────────────────────────────────────────────────────────────
gen byte sit_lab3 = .
label define sitlab3lbl 1 "Ocupado" 2 "Desocupado" 3 "Inactivo"

* 2006–2013: 10–11 cats (1–5=ocupado; 6–7=cesante/buscando; 8–10=inactivo; 11=NS)
replace sit_lab3 = 1 if inrange(slab_raw,  1,  5) & inrange(year, 2006, 2013)
replace sit_lab3 = 2 if inrange(slab_raw,  6,  7) & inrange(year, 2006, 2013)
replace sit_lab3 = 3 if inrange(slab_raw,  8, 10) & inrange(year, 2006, 2013)
* 11 → missing

* 2016–2017: 1=Trab 2=Ces 3=Buscando 4=Inact 5=NS/NR
replace sit_lab3 = 1 if slab_raw == 1              & inrange(year, 2016, 2017)
replace sit_lab3 = 2 if inlist(slab_raw, 2, 3)     & inrange(year, 2016, 2017)
replace sit_lab3 = 3 if slab_raw == 4              & inrange(year, 2016, 2017)
* 5 → missing

* 2018: 1=Trab 2=Ces 3=Buscando 4=Inact 5=Jubilado 6=Otro 99=NS
replace sit_lab3 = 1 if slab_raw == 1              & year == 2018
replace sit_lab3 = 2 if inlist(slab_raw, 2, 3)     & year == 2018
replace sit_lab3 = 3 if inlist(slab_raw, 4, 5, 6)  & year == 2018

* 2019–2023: 1=Trab 2=Ces 3=Buscando 4=Inact 8/9=NS
replace sit_lab3 = 1 if slab_raw == 1              & inrange(year, 2019, 2023)
replace sit_lab3 = 2 if inlist(slab_raw, 2, 3)     & inrange(year, 2019, 2023)
replace sit_lab3 = 3 if slab_raw == 4              & inrange(year, 2019, 2023)

* 2024: cp07 1=Empleador 2=Asal.JC 3=Asal.JP 4=CuentaPropia 5=No trabaja(agrupa todo)
replace sit_lab3 = 1 if inrange(slab_raw, 1, 4)    & year == 2024
* slab_raw==5 en 2024 → sit_lab3=missing (no distingue cesante de inactivo)

* 2025: p57 1=Empl 2=Asal 3=CuentaPropia 4=Desemp 5=Estud 6=Jubilado 7=Otro
replace sit_lab3 = 1 if inrange(slab_raw, 1, 3)    & year == 2025
replace sit_lab3 = 2 if slab_raw == 4              & year == 2025
replace sit_lab3 = 3 if inrange(slab_raw, 5, 7)    & year == 2025

label values sit_lab3 sitlab3lbl
label var sit_lab3 "Situación laboral armonizada (3 categorías)"


* ─── afil4 ───────────────────────────────────────────────────────────────────
* NOTA: los códigos exactos para afil4 pueden variar entre ediciones del cuestionario.
* El esquema asumido es: 1=Católica 2=Evangélica/Pentecostal 3=Protestante/Otra 4=Ninguna/Ateo.
* Verificar con libros de códigos de cada año antes de análisis final.
gen byte afil4 = .
label define afil4lbl 1 "Católica" 2 "Evangélica/Protestante" ///
                      3 "Otra religión" 4 "Sin religión/Ateo/Agnóstico"

* Esquema multicat estándar: 1=Cat 2=Ev 3=Prot(otra evang) 4=Otra religión
*                            5=Ninguna/Ateo 6=Agnóstico 7+=NS/NR
local yr_multi 2006 2008 2009 2010 2012 2013 2016 2018 2019 2021 2023 2025
foreach y of local yr_multi {
    replace afil4 = 1 if afil_raw == 1              & year == `y'
    replace afil4 = 2 if inlist(afil_raw, 2, 3)     & year == `y'
    replace afil4 = 3 if inlist(afil_raw, 4, 5)     & year == `y'
    replace afil4 = 4 if inlist(afil_raw, 6, 7, 8)  & year == `y'
}

* 2011 (religion): 3 cats → 1=Cat 2=Otra 3=Ninguna
replace afil4 = 1 if afil_raw == 1 & year == 2011
replace afil4 = 3 if afil_raw == 2 & year == 2011
replace afil4 = 4 if afil_raw == 3 & year == 2011

* 2017 (religion): 4 cats → 1=Cat 2=Otra 3=Agn/ateo/ning 4=NS
replace afil4 = 1 if afil_raw == 1 & year == 2017
replace afil4 = 3 if afil_raw == 2 & year == 2017
replace afil4 = 4 if afil_raw == 3 & year == 2017
* 4=NS → missing

* 2024: 7 cats → 1=Cat 2=Ev 3=Prot 4=Otra 5=Ateo/agn 6=Ninguna 7=?
replace afil4 = 1 if afil_raw == 1              & year == 2024
replace afil4 = 2 if inlist(afil_raw, 2, 3)     & year == 2024
replace afil4 = 3 if afil_raw == 4              & year == 2024
replace afil4 = 4 if inlist(afil_raw, 5, 6)     & year == 2024
* afil_raw==7 en 2024 → missing; 2014 → missing (r10=trayectoria, no denominación)

label values afil4 afil4lbl
label var afil4 "Afiliación religiosa armonizada (4 categorías)"


/*============================================================================
  PARTE 4: CORRECCIÓN DE DIRECCIÓN Y LIMPIEZA NS/NR
  Convención target actitudes: 1=Muy en desacuerdo, 5=Muy de acuerdo
  Convención target confianza: 1=Nada, 5=Mucha
============================================================================*/

* ─── Limpiar escala extendida 2016 (1–6, código 6=NS/NR) ───────────────────
foreach v in homo_casar homo_adopt convivencia matrimonio {
    replace `v' = . if `v' == 6 & year == 2016
}
replace aborto_gen = . if aborto_gen == 4 & year == 2016

* ─── Limpiar escala extendida 2020/2022 (1–7, 6=NS 7=NR) ───────────────────
foreach v in homo_casar homo_adopt convivencia matrimonio rol_genero {
    replace `v' = . if inlist(`v', 6, 7) & inlist(year, 2020, 2022)
}

* ─── Limpiar NS/NR genéricos ─────────────────────────────────────────────────
foreach v in homo_casar homo_adopt convivencia matrimonio aborto_vio aborto_gen ///
             rol_genero confgob_raw configla_raw confffaa_raw confpart_raw confparl_raw {
    replace `v' = . if inlist(`v', 8, 9, 88, 99) & !missing(`v')
    replace `v' = . if `v' < 0 & !missing(`v')
}

replace aborto_gen = . if inlist(aborto_gen, 4, 5) & year == 2021  // 4=NS, 5=NR
replace aborto_gen = . if inlist(aborto_gen, 8, 9) & year == 2024  // 8=NS, 9=NR
replace aborto_vio = . if inlist(aborto_vio, 3, 8, 9, 99) & !missing(aborto_vio)

* ─── Invertir dirección (1=Acuerdo → 6 - raw para quedar 1=Desacuerdo) ──────

foreach yr in 2008 2011 2013 2014 2019 {
    replace homo_casar = 6 - homo_casar if year == `yr' & inrange(homo_casar, 1, 5)
}
foreach yr in 2014 2019 {
    replace homo_adopt = 6 - homo_adopt if year == `yr' & inrange(homo_adopt, 1, 5)
}
foreach yr in 2008 2011 2013 2014 2019 {
    replace convivencia = 6 - convivencia if year == `yr' & inrange(convivencia, 1, 5)
}
foreach yr in 2008 2010 2011 2013 2014 2019 {
    replace matrimonio = 6 - matrimonio if year == `yr' & inrange(matrimonio, 1, 5)
}
foreach yr in 2007 2011 2019 {
    replace rol_genero = 6 - rol_genero if year == `yr' & inrange(rol_genero, 1, 5)
}

* ─── Confianza: invertir (1=Mucha → 6 - raw → 1=Nada) ──────────────────────
foreach yr in 2010 2011 2012 2019 {
    replace confgob_raw = 6 - confgob_raw if year == `yr' & inrange(confgob_raw, 1, 5)
}
foreach yr in 2010 2011 2012 2013 2014 2019 {
    replace configla_raw = 6 - configla_raw if year == `yr' & inrange(configla_raw, 1, 5)
}
foreach yr in 2010 2011 2012 2014 2019 {
    replace confffaa_raw = 6 - confffaa_raw if year == `yr' & inrange(confffaa_raw, 1, 5)
}
foreach yr in 2010 2011 2012 2014 2019 {
    replace confpart_raw = 6 - confpart_raw if year == `yr' & inrange(confpart_raw, 1, 5)
}
foreach yr in 2010 2011 2012 2013 2014 2019 {
    replace confparl_raw = 6 - confparl_raw if year == `yr' & inrange(confparl_raw, 1, 5)
}

* ─── Renombrar a nombres finales ─────────────────────────────────────────────
capture rename confgob_raw  conf_gobierno
capture rename configla_raw conf_iglesia
capture rename confffaa_raw conf_ffaa
capture rename confpart_raw conf_partidos
capture rename confparl_raw conf_parlamento
capture rename creedios_raw creencia_dios
capture rename misa_raw     asist_misa

* ─── Creencia en Dios (1=Sí sin duda 2=A veces 3=No creo) ──────────────────
replace creencia_dios = . if inlist(creencia_dios, 8, 9, 88, 99) & !missing(creencia_dios)
replace creencia_dios = . if creencia_dios < 0 & !missing(creencia_dios)

* ─── Asistencia misa ─────────────────────────────────────────────────────────
replace asist_misa = . if asist_misa == 10 & inlist(year, 2006, 2016)
replace asist_misa = . if asist_misa == 6  & year == 2019
replace asist_misa = . if inlist(asist_misa, 6, 7) & inlist(year, 2020, 2022)
replace asist_misa = . if inlist(asist_misa, 8, 9, 88, 99) & !missing(asist_misa)
replace asist_misa = . if asist_misa < 0 & !missing(asist_misa)

* ─── Posición política ───────────────────────────────────────────────────────
replace pospolcont = . if pospolcont == 11                    // 11=NS en 2006
replace pospolcat  = . if pospolcat  == 4 & !missing(pospolcat) // 4=NS/NR

* Derivar pospolcat desde pospolcont para años pre-2022 (donde pos_politica no existe)
* Escala 1–10 (2006–2017): 1–4=Izq, 5–6=Centro, 7–10=Der
replace pospolcat = 1 if missing(pospolcat) & pospolcont >= 1  & pospolcont <= 4  ///
    & inlist(year, 2006,2007,2008,2009,2011,2012,2013,2014,2016,2017)
replace pospolcat = 2 if missing(pospolcat) & pospolcont >= 5  & pospolcont <= 6  ///
    & inlist(year, 2006,2007,2008,2009,2011,2012,2013,2014,2016,2017)
replace pospolcat = 3 if missing(pospolcat) & pospolcont >= 7  & pospolcont <= 10 ///
    & inlist(year, 2006,2007,2008,2009,2011,2012,2013,2014,2016,2017)
* Escala 1–5 (2018, 2019): 1=Izq, 2–3=Centro, 4–5=Der
replace pospolcat = 1 if missing(pospolcat) & pospolcont == 1 & inlist(year, 2018, 2019)
replace pospolcat = 2 if missing(pospolcat) & inlist(pospolcont, 2, 3) & inlist(year, 2018, 2019)
replace pospolcat = 3 if missing(pospolcat) & inlist(pospolcont, 4, 5) & inlist(year, 2018, 2019)

* ─── Tiene hijos ─────────────────────────────────────────────────────────────
replace tiene_hijos = . if !inlist(tiene_hijos, 0, 1)


/*============================================================================
  PARTE 5: ETIQUETAS DE VARIABLES Y VALORES
============================================================================*/

label var year          "Ola de encuesta"
label var ponderador    "Factor de expansión"
label var folio_mapa    "PSU (folio de mapa)"
label var estrato       "Estrato muestral"
label var edad          "Edad en años"
label var region        "Región (código; missing en 2008–2011, 2014, 2025)"
label var macrozona     "Macrozona (1=Norte 2=Centro 3=Sur 4=RM)"
label var ingreso       "Ingreso del hogar (escala ordinal)"
label var gse           "Nivel socioeconómico"
label var educ_raw      "Educación (raw — ver educ4)"
label var ecivil_raw    "Estado civil (raw — ver ecivil5)"
label var slab_raw      "Situación laboral (raw — ver sit_lab3)"
label var afil_raw      "Afiliación religiosa (raw — ver afil4)"
label var homo_casar    "Matrimonio igualitario (1=Muy en desac, 5=Muy de acuerdo)"
label var homo_adopt    "Adopción homoparental (1=Muy en desac, 5=Muy de acuerdo)"
label var convivencia   "Convivencia sin matrimonio (1=Muy en desac, 5=Muy de acuerdo)"
label var matrimonio    "El matrimonio es para toda la vida (1=Muy en desac, 5=Muy de acuerdo)"
label var aborto_vio    "Aborto en caso de violación (raw)"
label var aborto_gen    "Aborto (1=Cualquier circ. 2=Algunas 3=Ninguna)"
label var rol_genero    "Familia se descuida si mujer trabaja JC (1=Desac 5=Acuerdo)"
label var conf_gobierno  "Confianza en el Gobierno (1=Nada 5=Mucha)"
label var conf_iglesia   "Confianza en la Iglesia Católica (1=Nada 5=Mucha)"
label var conf_ffaa      "Confianza en las Fuerzas Armadas (1=Nada 5=Mucha)"
label var conf_partidos  "Confianza en los Partidos Políticos (1=Nada 5=Mucha)"
label var conf_parlamento "Confianza en el Parlamento (1=Nada 5=Mucha)"
label var confint        "Confianza interpersonal general"
label var pospolcont    "Posición política continua (1=Izq, 5 o 10=Der)"
label var pospolcat     "Posición política categórica (1=Iz 2=Cen 3=Der)"
label var creencia_dios "Creencia en Dios (1=Sí sin duda 2=A veces 3=No creo)"
label var asist_misa    "Asistencia a misa (1=Más 1x/semana 5=Nunca)"
label var educ4         "Educación armonizada (4 categorías)"
label var ecivil5       "Estado civil armonizado (5 categorías)"
label var sit_lab3      "Situación laboral armonizada (3 categorías)"
label var afil4         "Afiliación religiosa armonizada (4 categorías)"
label var n_hijos_vivos "Número de hijos vivos (2006,2008,2009,2011,2012,2013,2024,2025)"
label var tiene_hijos   "Tiene hijos (0=No 1=Sí) (2006,2008,2009,2011,2012,2013,2014,2024,2025)"

label define sexolbl 1 "Hombre" 2 "Mujer"
label values sexo sexolbl

label define macrozonaslbl 1 "Norte" 2 "Centro" 3 "Sur" 4 "RM"
label values macrozona macrozonaslbl

label define pospolcatlbl 1 "Izquierda" 2 "Centro" 3 "Derecha"
label values pospolcat pospolcatlbl

label values educ4    educ4lbl
label values ecivil5  ecivil5lbl
label values sit_lab3 sitlab3lbl
label values afil4    afil4lbl


/*============================================================================
  PARTE 6: SVYSET, ORDEN, COMPRESIÓN Y GUARDADO
============================================================================*/

* Diseño muestral: PSU=folio_mapa, estrato=estrato, ponderador=ponderador
* Nota: años sin región (2008–2011, 2014) tienen estratificación menos granular
* Nota: 2025 tiene 5 etapas vs 4 en otros años (aproximación válida para estimaciones)
svyset folio_mapa [pw=ponderador], strata(estrato) vce(linearized) singleunit(centered)

order year ponderador folio_mapa estrato                              ///
      edad sexo region macrozona                                      ///
      educ_raw educ4 ecivil_raw ecivil5 slab_raw sit_lab3 afil_raw afil4 ///
      ingreso gse                                                     ///
      creencia_dios asist_misa                                        ///
      homo_casar homo_adopt convivencia matrimonio                    ///
      aborto_vio aborto_gen rol_genero                                ///
      conf_gobierno conf_iglesia conf_ffaa conf_partidos conf_parlamento confint ///
      pospolcont pospolcat                                            ///
      n_hijos_vivos tiene_hijos

capture drop gse_x gse_calc_x estrato_upm ingreso_grupo

* Limpiar códigos NSR/no-aplica
recode confint (-99=.) (-88=.) (8=.) (9=.) (99=.)   // 2007:9=NSR 2018:99=NSR 2023:8/9 2025:-99/-88
recode n_hijos_vivos (99=.)                          // 99=no sabe/no responde

* NOTA: conf_gobierno y conf_iglesia en 2022 usan escala 1-7 vs 1-5 en otras olas
* (variable i_X_p104). No se normaliza aquí — considerar z-estandarizar por año en análisis.

compress
save "$OUT/bicentenario_panel_armonizado.dta", replace

di as result _n "=== PANEL ARMONIZADO GUARDADO ==="
di as result "Archivo: $OUT/bicentenario_panel_armonizado.dta"
di as result "Variables: `= wordcount("`e(varlist)'")'" _n

count
tab year

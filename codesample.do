clear all
set more off
cd "C:\Users\ariel\OneDrive - Escuela Superior Politécnica del Litoral\Research\PROYECTO_AYUDANTIAS_RENDIMIENTO\Nuevas bases 2012-2019"

*******************************************************************************
******************ACADEMIC PERFORMANCE DATA BASE *******************************
********************************************************************************

*********************New student academic history database**********************
forvalue i=2012(1)2019 {
import excel "DATOS_todos_`i'.xlsx", sheet("1S") firstrow clear
save data`i'-1S,replace
}
forvalue i=2012(1)2019 {
import excel "DATOS_todos_`i'.xlsx", sheet("2S") firstrow clear
save data`i'-2S,replace
}
use data2012-1S,clear
append using data2012-2S,force
forvalue s=1(1)2 {
	forvalue i=3(1)9 {
	append using data201`i'-`s'S,force  
	 }
  } 
 
*To generate student's name and save the database 
gen NOMBRE_ESTUDIANTE=APELLIDOS+" "+NOMBRES
save historia_academica_2012_2019,replace

***************************Original database**********************************
use "historia_academica_2007_2018_new",clear
keep if anio_materia<2012

ren (apellidos nombres anio_ingreso anio_materia termino_ingreso termino_materia promedio_materia materia ///
profesor numregistrados numcreditos cod_unidad_academica_est cod_materia_acad paralelo) ///
(APELLIDOS NOMBRES ANIO_INGRESO ANIO_MATERIA TERMINO_INGRESO TERMINO_MATERIA PROMEDIO_MATERIA MATERIA ///
PROFESOR NUMREGISTRADOS NUMCREDITOS COD_UNIDAD_ACADEMICA_EST COD_MATERIA_ACAD PARALELO)

*To generate student's name and save the database 
gen NOMBRE_ESTUDIANTE=APELLIDOS+" "+NOMBRES
destring PROMEDIO_MATERIA ,replace dpcomma

save historia_academica_2007_2011,replace

*joining databases

use historia_academica_2012_2019,clear
append using historia_academica_2007_2011
drop if NOMBRE_ESTUDIANTE==" "
save historia_academica_2007_2019,replace

***********************Cleaning data and generating variables*****************
tostring ANIO_INGRESO ANIO_MATERIA,replace

gen AÑO_INGRESO=ANIO_INGRESO+"-"+TERMINO_INGRESO
gen AÑO_TERMINO=ANIO_MATERIA+"-"+TERMINO_MATERIA
encode  AÑO_TERMINO, gen (termino_academico)

sort NOMBRE_ESTUDIANTE termino_academico

ren PROMEDIO_MATERIA promedio_materia
destring promedio_materia ,replace dpcomma
*Verify duplicates
duplicates tag NOMBRE_ESTUDIANTE MATERIA PROFESOR AÑO_TERMINO, gen(rep)
duplicates drop NOMBRE_ESTUDIANTE MATERIA PROFESOR AÑO_TERMINO, force
drop if NOMBRE_ESTUDIANTE==" "
// Generate variables

*academic performance
egen promedio_termino=mean(promedio_materia) ,by(NOMBRE_ESTUDIANTE AÑO_TERMINO)
*quantity of subjects
sort NOMBRE_ESTUDIANTE AÑO_TERMINO
quietly by NOMBRE_ESTUDIANTE AÑO_TERMINO :gen materias_tomadas=cond(_N==1,0,_n)
	replace materias_tomadas=1 if materias_tomadas==0
egen Cantidad_materias=max(materias_tomadas) ,by(NOMBRE_ESTUDIANTE AÑO_TERMINO)
*identify if in a semester the students are taking a subject for a second time or  for the third time
gen materias_Segunda=(VEZ_TOMADA==2) 
gen materias_tercera=(VEZ_TOMADA==3)
egen segunda_matricula=max(materias_Segunda),by(NOMBRE_ESTUDIANTE AÑO_TERMINO)
egen tercera_matricula=max(materias_tercera),by(NOMBRE_ESTUDIANTE AÑO_TERMINO)
*to take account the total number of subjects students take more than once
egen cantidad_segunda=sum(materias_Segunda),by(NOMBRE_ESTUDIANTE AÑO_TERMINO)
egen canitdad_tercera=sum(materias_tercera),by(NOMBRE_ESTUDIANTE AÑO_TERMINO)
*get the average class size per semester
egen tamaño_clasespromedio=mean(NUMREGISTRADOS),by(NOMBRE_ESTUDIANTE AÑO_TERMINO)
	replace tamaño_clasespromedio=round(tamaño_clasespromedio)
*number of fail subjects
gen matreprobada=(ESTADO_MAT_TOMADA=="RP"|ESTADO_MAT_TOMADA=="PF")
gen matpf=(ESTADO_MAT_TOMADA=="PF")
egen materiasrp=sum(matreprobada),by(NOMBRE_ESTUDIANTE AÑO_TERMINO)
egen materiaspf= sum(matpf),by(NOMBRE_ESTUDIANTE AÑO_TERMINO)
*one student observation per semester
duplicates drop NOMBRE_ESTUDIANTE AÑO_TERMINO,force
*faculty encode
encode COD_UNIDAD_ACADEMICA_EST,gen(Facultad)	
recode Facultad (1 =1 EDCOM ) (2 =1 EDCOM ) (3=3 FCNM) (4=4 FCSH) (13=4 FCSH) ///
(5=5 FCV) (6=6 FICT) (7=7 FIEC) (8=8 FIMCBOR) (9=8 FIMCBOR) (12=8 FIMCBOR) (10=10 FIMCP) ///
(11=10 FIMCP) (14=11 TECNOLOGIAS) (15=11 TECNOLOGIAS) (16=11 TECNOLOGIAS) (17=11 TECNOLOGIAS) ///
(18=11 TECNOLOGIAS) , gen (facultad)	
		
keep  NOMBRE_ESTUDIANTE AÑO_INGRESO AÑO_TERMINO CARRERA COD_UNIDAD_ACADEMICA_EST ///
promedio_termino tercera_matricula cantidad_segunda canitdad_tercera ///
Cantidad_materias materiasrp materiaspf NUMCREDITOS facultad ANIO_MATERIA ///
porcentaje_avance_carrera tamaño_clasespromedio

*save "BASE_RENDIMIENTO_ACADÉMICO_new.dta",re
save "BASE_PASANTIAS_new",replace

********************************************************************************
**************TO OBTAIN THE PROFESSOR DIFFICULTY VARIABLE**********
********************************************************************************	

*failure subject rate by professor
use historia_academica_2007_2019,clear
ren PROMEDIO_MATERIA promedio_materia
destring promedio_materia ,replace dpcomma
gen RP=(ESTADO_MAT_TOMADA=="RP")
tostring ANIO_INGRESO ANIO_MATERIA,replace
gen AÑO_INGRESO=ANIO_INGRESO+"-"+TERMINO_INGRESO
gen AÑO_TERMINO=ANIO_MATERIA+"-"+TERMINO_MATERIA
encode  AÑO_TERMINO, gen (termino_academico)
*verifing duplicates
duplicates tag NOMBRE_ESTUDIANTE MATERIA PROFESOR AÑO_TERMINO, gen(rep)
duplicates drop NOMBRE_ESTUDIANTE MATERIA PROFESOR AÑO_TERMINO, force
*removing spaces in a string variable 
replace PROFESOR= trim(PROFESOR)
*removing closed courses
generate ayuda = regexm( PROFESOR, "CERRADO" )
drop if ayuda==1
drop ayuda
drop if PROFESOR==""
*to identify the number of courses by professor
sort AÑO_TERMINO PROFESOR COD_MATERIA_ACAD  PARALELO
ren (COD_MATERIA_ACAD  PARALELO)  (cod_materia_acad paralelo)
gen cambio_de_curso=0
	replace cambio_de_curso = 1 if  (PROFESOR[_n] == PROFESOR[_n-1]) & ///
	( cod_materia_acad[_n] !=  cod_materia_acad[_n-1])
	replace  cambio_de_curso = 1  if  (PROFESOR[_n] != PROFESOR[_n-1])
	replace cambio_de_curso = 1 if  (PROFESOR[_n] == PROFESOR[_n-1]) & ///
	( paralelo[_n] !=  paralelo[_n-1]) 
egen Total_cursos = total(cambio_de_curso), by (PROFESOR AÑO_TERMINO)
gen cambio_materia=0
	replace cambio_materia = 1 if  (PROFESOR[_n] == PROFESOR[_n-1]) & ///
	( cod_materia_acad[_n] !=  cod_materia_acad[_n-1])
    replace cambio_materia = 1 if  (PROFESOR[_n] !=  PROFESOR[_n-1])
egen Total_materias = total(cambio_materia), by (PROFESOR AÑO_TERMINO)

*number of students by professor 
sort PROFESOR AÑO_TERMINO
quietly by PROFESOR AÑO_TERMINO :  gen estudiantes  = cond(_N==1,0,_n)
replace estudiantes=1 if estudiantes==0
egen Total_estudiantes = max(estudiantes), by (PROFESOR AÑO_TERMINO)
*number of failed students by professor 
bysort PROFESOR AÑO_TERMINO:gen Total_reprobados = sum(RP)
egen Total_RP = max(Total_reprobados), by (PROFESOR AÑO_TERMINO)

collapse (max) Total_cursos Total_materias Total_estudiantes Total_RP ,by( PROFESOR  AÑO_TERMINO )
gen Ratio_Estudiantes_Rp= Total_RP/Total_estudiantes
sort PROFESOR AÑO_TERMINO
quietly by PROFESOR :  gen Semestres_En_ESPOL  = cond(_N==1,0,_n)

*cumulative student failure rate by professor
bysort PROFESOR  :gen RP_ACUMULADO = sum(Total_RP)
bysort PROFESOR  :gen Total_Estudiantes_acumulado=sum(Total_estudiantes)
gen RATIO_RP_ACUMULADA=RP_ACUMULADO/Total_Estudiantes_acumulado
*cumulative student failure rate by professor ( cumulative past period)
gen RP_ACUMULADO_P_PASADO=RP_ACUMULADO-Total_RP
gen Total_Estudiantes_P_PASADO=Total_Estudiantes_acumulado-Total_estudiantes
gen RATIO_RP_ACUMULADA_P_PASADO=RP_ACUMULADO_P_PASADO/Total_Estudiantes_P_PASADO
*student failure rate by professor (past period)
gen RATIO_RP_PASTPERIOD=(Ratio_Estudiantes_Rp[_n-1]) if (PROFESOR==PROFESOR[_n-1])
	replace RATIO_RP_PASTPERIOD=0 if RATIO_RP_PASTPERIOD==.

save "TASAS_REPROBACION_PROFESORES_new.dta",replace

*calculating the average difficulty rate of the students' teachers in each semester
use historia_academica_2007_2019,clear
drop if NOMBRE_ESTUDIANTE==" "
tostring ANIO_INGRESO ANIO_MATERIA,replace
gen AÑO_INGRESO=ANIO_INGRESO+"-"+TERMINO_INGRESO
gen AÑO_TERMINO=ANIO_MATERIA+"-"+TERMINO_MATERIA
encode  AÑO_TERMINO, gen (termino_academico)

sort NOMBRE_ESTUDIANTE AÑO_TERMINO
ren ( COD_MATERIA_ACAD  PARALELO)  ( cod_materia_acad paralelo)
merge m:1 PROFESOR AÑO_TERMINO using "TASAS_REPROBACION_PROFESORES_new.dta"

keep if _merge==3 
sort NOMBRE_ESTUDIANTE AÑO_TERMINO 
replace RATIO_RP_ACUMULADA_P_PASADO=0 if RATIO_RP_ACUMULADA_P_PASADO==.
egen PROMEDIO_REPROBACION_PROFESORES=mean( RATIO_RP_ACUMULADA_P_PASADO) ,by( NOMBRE_ESTUDIANTE  AÑO_TERMINO )
egen PROMEDIO_REPROBACION_PROFPAST=mean(RATIO_RP_PASTPERIOD) ,by( NOMBRE_ESTUDIANTE  AÑO_TERMINO )
collapse (max) PROMEDIO_REPROBACION_PROFESORES PROMEDIO_REPROBACION_PROFPAST ,by(NOMBRE_ESTUDIANTE  AÑO_TERMINO )

save "ESTUDIANTE_REPROBACION_PROFES_new.dta",replace


********************************************************************************
********************INTERNSHIPS DATABASE*****************************************
********************************************************************************
import excel "practicas_empresariales.xlsx", sheet("Hoja1") firstrow clear

keep NUMERO_MATRICULA NOMBRE_ESTUDIANTE FECHADESDE FECHAHASTA NUMERO_HORAS REMUNERADA NOMBRE_ACTIVIDAD
ren NUMERO_MATRICULA COD_ESTUDIANTE
destring COD_ESTUDIANTE,replace
save pasantiasactualizadas,replace
*dropping duplicates 
duplicates drop NOMBRE_ESTUDIANTE FECHADESDE FECHAHASTA NOMBRE_ACTIVIDAD,force
*removing spaces in string variables
replace NOMBRE_ACTIVIDAD=trim(NOMBRE_ACTIVIDAD)
replace NOMBRE_ESTUDIANTE=trim(NOMBRE_ESTUDIANTE)
*removing teaching assistant internships  
gen identificadorayudantias=regexm(NOMBRE_ACTIVIDAD, "DOCENCIA")
drop if identificadorayudantias==1
*verifing duplicates
duplicates tag COD_ESTUDIANTE FECHADESDE FECHAHASTA NOMBRE_ACTIVIDAD,gen(h)
duplicates drop COD_ESTUDIANTE NOMBRE_ESTUDIANTE FECHADESDE FECHAHASTA NOMBRE_ACTIVIDAD,force

keep  COD_ESTUDIANTE NOMBRE_ESTUDIANTE  NUMERO_HORAS FECHADESDE FECHAHASTA NOMBRE_ACTIVIDAD 
save pasantiasstata,replace

*****************matching internship dates and academic period dates************
*doing 26 observations to each observation to 
expand 26
sort NOMBRE_ESTUDIANTE FECHADESDE FECHAHASTA NOMBRE_ACTIVIDAD
bysort NOMBRE_ESTUDIANTE FECHADESDE FECHAHASTA NOMBRE_ACTIVIDAD: gen ayuda=_n
gen AÑO_TERMINO="-"
replace AÑO_TERMINO="2007-1S" if ayuda==1
replace AÑO_TERMINO="2007-2S" if ayuda==2
replace AÑO_TERMINO="2008-1S" if ayuda==3
replace AÑO_TERMINO="2008-2S" if ayuda==4
replace AÑO_TERMINO="2009-1S" if ayuda==5
replace AÑO_TERMINO="2009-2S" if ayuda==6
replace AÑO_TERMINO="2010-1S" if ayuda==7
replace AÑO_TERMINO="2010-2S" if ayuda==8
replace AÑO_TERMINO="2011-1S" if ayuda==9
replace AÑO_TERMINO="2011-2S" if ayuda==10
replace AÑO_TERMINO="2012-1S" if ayuda==11
replace AÑO_TERMINO="2012-2S" if ayuda==12
replace AÑO_TERMINO="2013-1S" if ayuda==13
replace AÑO_TERMINO="2013-2S" if ayuda==14
replace AÑO_TERMINO="2014-1S" if ayuda==15
replace AÑO_TERMINO="2014-2S" if ayuda==16
replace AÑO_TERMINO="2015-1S" if ayuda==17
replace AÑO_TERMINO="2015-2S" if ayuda==18
replace AÑO_TERMINO="2016-1S" if ayuda==19
replace AÑO_TERMINO="2016-2S" if ayuda==20
replace AÑO_TERMINO="2017-1S" if ayuda==21
replace AÑO_TERMINO="2017-2S" if ayuda==22
replace AÑO_TERMINO="2018-1S" if ayuda==23
replace AÑO_TERMINO="2018-2S" if ayuda==24
replace AÑO_TERMINO="2019-1S" if ayuda==25
replace AÑO_TERMINO="2019-2S" if ayuda==26

*joining internship dates with academic period dates
merge m:1 AÑO_TERMINO using periodos
sort COD_ESTUDIANTE  FECHADESDE FECHAHASTA NOMBRE_ACTIVIDAD ayuda
keep if _merge==3
*generating a dummy variable that identify the treatment (when a student doing his or her internship for the academic period)
gen hizopasantia2= ((FECHAINICLASES>=FECHADESDE) & (FECHAFINCLASES<=FECHAHASTA))  | ///
( (FECHAINICLASES>=FECHADESDE) & (FECHAINICLASE<=FECHAHASTA) & (FECHAFINCLASE>FECHAHASTA)) ///
|( (FECHAFINCLASES<=FECHAHASTA) & (FECHAFINCLASE>=FECHADESDE) & (FECHAINICLASES<FECHADESDE) )

keep if hizopasantia2==1
duplicates drop COD_ESTUDIANTE AÑO_TERMINO,force
keep COD_ESTUDIANTE  NOMBRE_ESTUDIANTE AÑO_TERMINO hizopasantia2
ren COD_ESTUDIANTE cod_estudiante

save terminospasantias,replace

***************************Joining databases************************************
use "BASE_PASANTIAS_new",clear 
merge 1:1 NOMBRE_ESTUDIANTE  AÑO_TERMINO using "ESTUDIANTE_REPROBACION_PROFES_new.dta"
drop _merge
*generating  semester (time in university) by student
bysort NOMBRE_ESTUDIANTE:  gen semester  = cond(_N==1,0,_n)
replace semester=1 if semester==0
*encode academic period
encode AÑO_TERMINO,gen(termino_academico)
gen repetidor=(cantidad_segunda>0)
drop if NOMBRE_ESTUDIANTE==" "
*joining
merge 1:1 NOMBRE_ESTUDIANTE AÑO_TERMINO using terminospasantias
drop if _merge==2
drop cod_estudiante

*generating additonal variables
encode AÑO_INGRESO,gen(ingreso)
*failure percentage 
gen porcentajerp=(materiasrp/ Cantidad_materias)
*to know who has left for various periods of his university
gen permanencia= (termino_academico-termino_academico[_n-1]) if (NOMBRE_ESTUDIANTE==NOMBRE_ESTUDIANTE[_n-1])
replace permanencia=0 if permanencia==.
bysort NOMBRE_ESTUDIANTE: egen ausenciamaxima=max(permanencia)
*period academic and faculty dummies
tab facultad,gen(facul)
tab semester,gen(semesterdummy)

replace hizopasantia2=0 if hizopasantia2==.
ren hizopasantia2 hizo_pasantia 
encode NOMBRE_ESTUDIANTE,gen(cod_estudiante)
save baseestimaciones,replace
*******************************************************************************
******************************ESTIMATIONS**************************************
*******************************************************************************

**********************Fixed effect estimator- within estimator******************
use baseestimaciones,clear
keep if ingreso>=61

*To estimate with students who took their internships after 2015
bysort NOMBRE_ESTUDIANTE:gen primeravez=sum( hizo_pasantia)
gen ayuda=(primeravez==1 & termino_academico>=17) 
gen ayuda1=(primeravez==1 & termino_academico<17) 
bysort NOMBRE_ESTUDIANTE:egen id1=max(ayuda)
bysort NOMBRE_ESTUDIANTE:egen id12=max(ayuda1)
bysort NOMBRE_ESTUDIANTE:gen id1mejorado=(id1==1 & id12==0)
bysort NOMBRE_ESTUDIANTE:egen ayuda2=max(primeravez)
bysort NOMBRE_ESTUDIANTE:egen id2=max(ayuda2)
keep if (id1mejorado==1|id2==0)
*interaction variables
xi i.facultad*i.semester
xi i.facultad*i.termino_academico
*set data
set seed 123
sort cod_estudiante semester
xtset cod_estudiante semester

*POLS
asdoc reg promedio_termino hizo_pasantia  ,r cl(cod_estudiante) nest title( Resultado de regresiones. Rendimiento educativo) cnames(POLS) fs(10) add(  Controls, No, Students FE, No, Time FE,No) dec(3) save(tabletodos.doc) replace
*Efecto fijo de Facultad >1y controles
asdoc reg promedio_termino hizo_pasantia   sexo i.Prov_Nacimiento i.Colegio  i.estado_civil  i.facultad ,r cl(cod_estudiante) cnames(POLS) keep(hizo_pasantia _cons)  nest fs(10) add(  Controls, Yes, Students FE, No, Time FE,No) dec(3)   save(tabletodos.doc) append
*Efecto fijo de estudiante
asdoc xtreg promedio_termino hizo_pasantia  sexo i.Prov_Nacimiento i.Colegio  i.estado_civil  i.facultad  ,fe cl(cod_estudiante)  cnames(FE Model ) keep(hizo_pasantia _cons) title( Resultado de regresiones. Rendimiento educativo) nest fs(10) add( Controls, Yes, Students FE, Yes, Time FE,No) dec(3)   save(tabletodos.doc)  append
*Efecto fijo de semestre
asdoc xtreg promedio_termino hizo_pasantia  sexo i.Prov_Nacimiento i.Colegio  i.estado_civil  i.facultad   i.semester  ,fe cl(cod_estudiante)  cnames(FE(Sem) ) keep(hizo_pasantia _cons) title( Resultado de regresiones. Rendimiento educativo) nest fs(10) add( Controls, Yes, Students FE, Yes, Time FE,Yes) dec(3)   save(tabletodos.doc)   append
*Efecto fijo con interacciones de semestre por facultad
asdoc xtreg promedio_termino hizo_pasantia   sexo i.Prov_Nacimiento i.Colegio  i.estado_civil  facultad##semester  control ,fe cl(cod_estudiante)  cnames(FE interacciones) keep(hizo_pasantia _cons) title( Resultado de regresiones. Rendimiento educativo) nest fs(10) add( Controls, Yes, Students FE, Yes, Time FE,Yes) dec(3)   save(tabletodos.doc)   append
	
	
***********************Multiple DID estimator (SHARP DID)***********************
 *Results a= without controls
 	set seed 123
	did_multiplegt promedio_termino cod_estudiante semester hizo_pasantia,  placebo (3)  covariances dynamic(1) cluster(cod_estudiante) breps(50) save_results(results1_a)
	graph export "results1_a.pdf", replace
	graph export "results1_a.eps", replace

*Results b=faculty controls 
	set seed 123
	did_multiplegt promedio_termino cod_estudiante semester hizo_pasantia,  placebo (3) controls(_Ifacultad_3-_Ifacultad_11)  covariances dynamic(1) cluster(cod_estudiante) breps(50) save_results(results1_b)
	graph export "results1_b.pdf", replace
	graph export "results1_b.eps", replace

*Results c= linear trends by faculty 
	set seed 123
	did_multiplegt promedio_termino cod_estudiante semester hizo_pasantia,  placebo (4) controls(_Ifacultad_2-_Ifacultad_12 _IfacXsem_2_2-_IfacXsem_2_23   _IfacXsem_3_2-_IfacXsem_3_23 _IfacXsem_4_2-_IfacXsem_4_23  ///
	_IfacXsem_5_2-_IfacXsem_5_23  _IfacXsem_6_2-_IfacXsem_6_23  _IfacXsem_7_2-_IfacXsem_7_23  _IfacXsem_8_2-_IfacXsem_8_23  _IfacXsem_12_2-_IfacXsem_12_23)  covariances dynamic(2) cluster(cod_estudiante) breps(50) save_results(results1_c)
	graph export "results1_c.pdf", replace
	graph export "results1_c.eps", replace
 



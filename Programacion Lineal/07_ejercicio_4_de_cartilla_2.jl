### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ e0033f10-cfdb-11ed-35d4-078aa3187b81
using PlutoUI, JuMP, HiGHS, NamedArrays

# ╔═╡ 54102d49-06d7-4e10-9eab-2052eab1ed9b
md"
Vamos a recordar el problema 4 de la cartilla de ejercicios 2:

>En base al problema 3, hay que planificar la producción a dos meses. El mercado nos demanda, para el mes 1, 200 unidades de cada producto como mínimo, y para el segundo mes, 300 unidades de cada uno. La cantidad de HE1 y HE2 en cada centro se mantiene igual para el segundo mes (tomar los valores del problema 3). Se pueden almacenar productos en el mes 1 para cumplir con la demanda del mes 2. Indique el plan de producción óptimo, que permita maximizar el margen de contribución total y que satisfaga la demanda mínima (o acercándose a ella lo más cerca posible)."

# ╔═╡ 10c79139-472d-42f0-b4c6-6ed2d5c0f5e8
md"## Diferencias con el modelo del problema 3"

# ╔═╡ b09bea9a-44e7-4e81-b331-e920c883d983
md"En el modelo anterior consideramos solo el primer mes de producción, siendo que no estamos considerando existencias iniciales, esa parte del modelo seguirá teniendo la misma forma, el único cambio es que ahora tendremos más decisiones por tomar."

# ╔═╡ bca6bc36-ec31-4236-b863-44b6919c1d68
md"Previamente, teníamos 6 variables de decisión:
* Cuánto producir del producto A en el Centro 1
* Cuánto producir del producto A en el Centro 2
* Cuánto producir del producto B en el Centro 1
* Cuánto producir del producto B en el Centro 2
* Cuánto producir del producto C en el Centro 1
* Cuánto producir del producto C en el Centro 2"

# ╔═╡ 379504d9-62b9-4b54-ae05-38d32d7d4ebc
md"Estas 6 variables funcionarán ahora como las variables del primer mes y necesitaremos otras 6 para el mes 2."

# ╔═╡ ee45437f-5d5d-409e-bea6-dcf7fecc8085
md"## Modelo problema 4"

# ╔═╡ 0b992a9c-c4f7-4c38-892f-1947e95d0642
md"Las nuevas variables serán entonces:
 $X_{i,k,l} \in \mathbb{R}$ : representa la cantidad de producto $i \in I$ que se decide producir en el centro de producción $k \in K$ en el mes $l \in L$, con $I=\{A,B,C\}$, $K=\{C1,C2\}$ y $L=\{Mes1,Mes2\}$

Además, podemos definir al equipo $j \in J$, con $J=\{Eq1,Eq2\}$"

# ╔═╡ d78f3f81-4c47-4161-a841-68bfc58c26aa
md"### Función objetivo"

# ╔═╡ 32b8c1a0-1cd0-4bbf-9bcf-f25d0687ec82
md"La función objetivo no sufrirá grandes cambios, solo hay que sumar las variables del segundo mes a la sumatoria (en este caso las contribuciones son las mismas, pero indicamos el caso general en el que la contribución pueda ser otra al mes $l$).

$Max  Z = \sum_{i \in I} \sum_{k \in K} \sum_{l \in L} CMg_{i,k,l} \cdot X_{i,k,l}$

Es decir,

$Max  Z = 100 X_{A,C1,Mes1} + 150 X_{B,C1,Mes1} + 175 X_{C,C1,Mes1} + 90 X_{A,C2,Mes1} + 180 X_{B,C2,Mes1}$
$+ 155 X_{C,C2,Mes1} + 100 X_{A,C1,Mes2} + 150 X_{B,C1,Mes2} + 175 X_{C,C1,Mes2} + 90 X_{A,C2,Mes2}$ 
$+ 180 X_{B,C2,Mes2} + 155 X_{C,C2,Mes2}$"

# ╔═╡ e22aca1a-8a84-4983-9977-78ab056fc3bd
md"### Restricciones"

# ╔═╡ c771e0cb-ff02-4478-97b2-18f2fb062046
md"En este caso, seguimos teniendo los mismos dos tipos de restricciones"

# ╔═╡ fe0806ec-d5dc-4cda-a095-8b5fb7446264
md"#### Horas equipo"

# ╔═╡ 47be42fb-1680-4b5a-af0e-30de7953d796
md"Uno no puede retener las horas de un equipo en un mes y 'guardarlas' para el otro, por lo que en este caso, lo único que necesitamos es repetir las mismas restricciones que teníamos para el primer mes para los meses siguientes de manera independiente. Además, el estándar del equipo no debería cambiar por el paso del tiempo (a menos que empecemos a hablar de años y, aún así, depende del equipo)"

# ╔═╡ aff0eecf-08e7-4bd4-a7e7-eb1d097c3c1c
md"$\sum_{i \in I} Estándar_{i,j,k} \cdot X_{i,k,l} \leq DispHE_{j,k,l}, \forall j \in J, \forall k \in K, \forall l \in L$"

# ╔═╡ 44651a09-f4a6-47c3-b5ab-26865ca6edaf
md"Como tenemos dos centros, dos equipos y tres productos necesitamos cuatro ecuaciones (2 Centros x 2 Equipos) con tres sumandos cada una por cada mes (4 ecuaciones/mes x 2 meses). Necesitaremos 8 ecuaciones:

$Estándar_{A,Eq1,C1} \cdot X_{A,C1,Mes1} + Estándar_{B,Eq1,C1} \cdot X_{B,C1,Mes1} + Estándar_{C,Eq1,C1} \cdot X_{C,C1,Mes1}   \leq DispHE_{Eq1,C1,Mes1}$

$Estándar_{A,Eq2,C1} \cdot X_{A,C1,Mes1} + Estándar_{B,Eq2,C1} \cdot X_{B,C1,Mes1} + Estándar_{C,Eq2,C1} \cdot X_{C,C1,Mes1}   \leq DispHE_{Eq2,C1,Mes1}$

$Estándar_{A,Eq1,C2} \cdot X_{A,C2,Mes1} + Estándar_{B,Eq1,C2} \cdot X_{B,C2,Mes1} + Estándar_{C,Eq1,C2} \cdot X_{C,C2,Mes1}   \leq DispHE_{Eq1,C2,Mes1}$

$Estándar_{A,Eq2,C2} \cdot X_{A,C2,Mes1} + Estándar_{B,Eq2,C2} \cdot X_{B,C2,Mes1} + Estándar_{C,Eq2,C2} \cdot X_{C,C2,Mes1}   \leq DispHE_{Eq2,C2,Mes1}$

$Estándar_{A,Eq1,C1} \cdot X_{A,C1,Mes2} + Estándar_{B,Eq1,C1} \cdot X_{B,C1,Mes2} + Estándar_{C,Eq1,C1} \cdot X_{C,C1,Mes2}   \leq DispHE_{Eq1,C1,Mes2}$

$Estándar_{A,Eq2,C1} \cdot X_{A,C1,Mes2} + Estándar_{B,Eq2,C1} \cdot X_{B,C1,Mes2} + Estándar_{C,Eq2,C1} \cdot X_{C,C1,Mes2}   \leq DispHE_{Eq2,C1,Mes2}$

$Estándar_{A,Eq1,C2} \cdot X_{A,C2,Mes2} + Estándar_{B,Eq1,C2} \cdot X_{B,C2,Mes2} + Estándar_{C,Eq1,C2} \cdot X_{C,C2,Mes2}   \leq DispHE_{Eq1,C2,Mes2}$

$Estándar_{A,Eq2,C2} \cdot X_{A,C2,Mes2} + Estándar_{B,Eq2,C2} \cdot X_{B,C2,Mes2} + Estándar_{C,Eq2,C2} \cdot X_{C,C2,Mes2}   \leq DispHE_{Eq2,C2,Mes2}$
"

# ╔═╡ e9491fb6-1dea-4a55-bd9f-7de5a1110d16
md"Reemplazando con los datos del problema, tenemos:"

# ╔═╡ 0ee99627-43cf-4a8c-8782-ab79db7e0ba5
md"$10X_{A,C1,Mes1} + 20X_{B,C1,Mes1} + 25X_{C,C1,Mes1}   \leq 7000$

$5X_{A,C1,Mes1} + 7X_{B,C1,Mes1} + 15X_{C,C1,Mes1}   \leq 3000$

$8X_{A,C2,Mes1} + 17X_{B,C2,Mes1} + 23X_{C,C2,Mes1}   \leq 6500$

$6X_{A,C1,Mes1} + 6X_{B,C1,Mes1} + 16X_{C,C2,Mes1}   \leq 3500$

$10X_{A,C1,Mes2} + 20X_{B,C1,Mes2} + 25X_{C,C1,Mes2}   \leq 7000$

$5X_{A,C1,Mes2} + 7X_{B,C1,Mes2} + 15X_{C,C1,Mes2}   \leq 3000$

$8X_{A,C2,Mes2} + 17X_{B,C2,Mes2} + 23X_{C,C2,Mes2}   \leq 6500$

$6X_{A,C1,Mes2} + 6X_{B,C1,Mes2} + 16X_{C,C2,Mes2}   \leq 3500$"

# ╔═╡ 3d531676-b0e6-46bc-a37b-5975e7b4e9f8
md"#### Demanda mínima"

# ╔═╡ bc6a8497-ed19-4d26-b2fc-08f17acee250
md"La demanda mínima será un poco diferente. Al mercado no solo no le importa a dónde hacemos cada producto, sino que tampoco le importa si guardamos producto de un mes a otro (a menos que sea perecedero), por lo que deberemos sumar lo que decidimos producir en cada planta por producto y lo que nos sobró de demanda del mes anterior para cada demanda mínima mensual. Una forma de modelarlo es considerar que el primer mes la demanda solo se puede satisfacer con la producción del primer mes, pero a partir del segundo mes podemos cumplir lo establecido con la producción acumulada hasta ese mes y la demanda acumulada hasta ese mes."

# ╔═╡ 34e2a696-6f6a-4b72-b696-0aee363259d6
md"En otras palabras, le vamos a decir al modelo que para cada producto:
* La demanda mínima del primer mes se debe cumplir con la producción del primer mes.
* La demanda mínima del primer mes más la del segundo mes se debe cumplir con la suma de la producción del primer y el segundo mes.
* La demanda mínima del primer mes más la del segundo más... más la del mes $l$ se debe cumplir con la suma de la produccion de todos los meses hasta el mes $l$."

# ╔═╡ a0f774da-5d3f-4cb8-9a7b-7f8d3384aeeb
md"Por lo tanto, por cada producto habrá igual cantidad de ecuaciones que meses analizados:

$\sum_{k \in K} X_{i,k,Mes1}+\sum_{k \in K} X_{i,k,Mes2}+...+\sum_{k \in K} X_{i,k,l} \geq DemMin_{i,Mes1}+DemMin_{i,Mes2}+...+DemMin_{i,l}, \forall i \in I,\forall l \in L$

"

# ╔═╡ 6b3b0339-96b9-4f9e-89be-4471a9d02b01
md"Reemplazando con los datos del problema:"

# ╔═╡ db831192-0a5d-4113-9362-32ae458a9ee7
md"
$X_{A,C1,Mes1}+X_{A,C2,Mes1} \geq 200$
$X_{A,C1,Mes1}+X_{A,C2,Mes1}+X_{A,C1,Mes2}+X_{A,C2,Mes2} \geq 500$
$X_{B,C1,Mes1}+X_{B,C2,Mes1} \geq 200$
$X_{B,C1,Mes1}+X_{B,C2,Mes1}+X_{B,C1,Mes2}+X_{B,C2,Mes2} \geq 500$
$X_{C,C1,Mes1}+X_{C,C2,Mes1} \geq 200$
$X_{C,C1,Mes1}+X_{C,C2,Mes1}+X_{C,C1,Mes2}+X_{C,C2,Mes2} \geq 500$"

# ╔═╡ eb2041e2-997f-4221-8fbc-25c0a9a59570
md"### Modelo completo"

# ╔═╡ 216fb665-6d2e-4c23-a64c-76a757d75b95
md"$Max  Z = 100 X_{A,C1,Mes1} + 150 X_{B,C1,Mes1} + 175 X_{C,C1,Mes1} + 90 X_{A,C2,Mes1} + 180 X_{B,C2,Mes1}$
$+ 155 X_{C,C2,Mes1} + 100 X_{A,C1,Mes2} + 150 X_{B,C1,Mes2} + 175 X_{C,C1,Mes2} + 90 X_{A,C2,Mes2}$ 
$+ 180 X_{B,C2,Mes2} + 155 X_{C,C2,Mes2}$"

# ╔═╡ 3187f72a-fb91-4675-94f0-7534fa51c279
md"$10X_{A,C1,Mes1} + 20X_{B,C1,Mes1} + 25X_{C,C1,Mes1}   \leq 7000$

$5X_{A,C1,Mes1} + 7X_{B,C1,Mes1} + 15X_{C,C1,Mes1}   \leq 3000$

$8X_{A,C2,Mes1} + 17X_{B,C2,Mes1} + 23X_{C,C2,Mes1}   \leq 6500$

$6X_{A,C1,Mes1} + 6X_{B,C1,Mes1} + 16X_{C,C2,Mes1}   \leq 3500$

$10X_{A,C1,Mes2} + 20X_{B,C1,Mes2} + 25X_{C,C1,Mes2}   \leq 7000$

$5X_{A,C1,Mes2} + 7X_{B,C1,Mes2} + 15X_{C,C1,Mes2}   \leq 3000$

$8X_{A,C2,Mes2} + 17X_{B,C2,Mes2} + 23X_{C,C2,Mes2}   \leq 6500$

$6X_{A,C1,Mes2} + 6X_{B,C1,Mes2} + 16X_{C,C2,Mes2}   \leq 3500$

$X_{A,C1,Mes1}+X_{A,C2,Mes1} \geq 200$
$X_{A,C1,Mes1}+X_{A,C2,Mes1}+X_{A,C1,Mes2}+X_{A,C2,Mes2} \geq 500$
$X_{B,C1,Mes1}+X_{B,C2,Mes1} \geq 200$
$X_{B,C1,Mes1}+X_{B,C2,Mes1}+X_{B,C1,Mes2}+X_{B,C2,Mes2} \geq 500$
$X_{C,C1,Mes1}+X_{C,C2,Mes1} \geq 200$
$X_{C,C1,Mes1}+X_{C,C2,Mes1}+X_{C,C1,Mes2}+X_{C,C2,Mes2} \geq 500$
$X_{i,k,l} \in \mathbb{R}, \forall i \in I, \forall k \in K, \forall l \in L$"

# ╔═╡ f338e5c7-037f-437e-98a6-0c611ae2ddc3
begin
	# Creo una variable que contiene al modelo (Siempre empiezo así, solo cambiar nombre)
	ej4_2 = Model(HiGHS.Optimizer)

	# Datos (dependientes del problema)
	# Variables con los índices de los datos (luego los accederemos como i, j, etc.)
	productos_ej4_2 = ["A"; "B"; "C"] #=I=#
	equipos_ej4_2 = ["Eq1"; "Eq2"] #=J=#
	centros_ej4_2 =["C1"; "C2"] #=K=#
	meses_ej4_2=["Mes1"; "Mes2"] #=L=#
	# Los datos propiamente dichos anexados a sus índices
	contribucion_Mg_ej4_2 = NamedArray(cat([[100 90] 
										[150 180] 
										[175 155]],
									 	[[100 90] 
										[150 180] 
										[175 155]],dims=3), (productos_ej4_2,centros_ej4_2,meses_ej4_2)) 
	estandar_Hequipo_ej4_2 = NamedArray(cat(
					#=C1=#			     [[10 5]
										 [20 7]
										 [25 15]],
					#=C2=#				[[8 6]
										 [17 6]
										 [23 16]],dims=3), (productos_ej4_2,equipos_ej4_2,centros_ej4_2))
	Hequipo_disp_ej4_2 = NamedArray(cat([[7000 6500] 
									 [3000 3500]],
								 	 [[7000 6500] 
									 [3000 3500]],dims=3), (equipos_ej4_2,centros_ej4_2,meses_ej4_2))
	Demanda_min_ej4_2 = NamedArray([200; 300],meses_ej4_2)
	# Declaro las variables de decisión.
	Xej4_2 = @variable(ej4_2, x[productos_ej4_2,centros_ej4_2,meses_ej4_2] >= 0)

	# Creo la función objetivo.
	obje_j4_2 = @objective(ej4_2, 
		Max, 
		sum(
			[sum(
				[sum(
					[contribucion_Mg_ej4_2[i,k,l] * Xej4_2[i,k,l] 
						for i in productos_ej4_2]) 
					for k in centros_ej4_2]) 
				for l in meses_ej4_2]))

	# Cargo las restricciones.
	# Restricción de HE
	r1_ej4_2 = @constraint(ej4_2, 
		[j in equipos_ej4_2, k in centros_ej4_2, l in meses_ej4_2], 
		sum(
			[estandar_Hequipo_ej4_2[i,j,k] * Xej4_2[i,k,l] for i in productos_ej4_2]) <= Hequipo_disp_ej4_2[j, k,l])
	
	# Restricciones de demanda mínima
	@constraint(ej4_2,[i in productos_ej4_2, l_actual in 1:length(meses_ej4_2)],
		sum(
			[sum([Xej4_2[i,k,l] 
				for k in centros_ej4_2])
				for l in meses_ej4_2[1:l_actual]]) 
		>= sum([Demanda_min_ej4_2[l] for l in meses_ej4_2[1:l_actual]])
	)
	
	latex_formulation(ej4_2)
end

# ╔═╡ 75f76343-06a3-4ff2-9a79-281dc24c09ea
begin
	# Resuelvo el modelo (Siempre termino así, solo cambiar nombre del modelo)
	optimize!(ej4_2)
	@show solution_summary(ej4_2, verbose=true)
end

# ╔═╡ 20523ed2-f34d-4c0c-8f8c-897bedd8a7c1
md"El resultado da infactible... esto quiere decir que con la capacidad instalada en planta no es posible satisfacer a la demanda. Busquemos cuánto nos faltaría producir para poder abastecer al mercado según los mínimos propuestos. Para ello, agreguemos un nuevo tipo de variables que represente lo que nos falta para alcanzar la demanda de un determinado producto en un mes particular:

$F_{i,l} \geq 0$

Y modifiquemos ahora las restricciones de demanda, usando el siguiente esquema de balanceo de producción:

* Faltante = Demanda - Cantidad producida

O, su equivalente:

* Cantidad producida + Faltante = Demanda

En este esquema, las restricciones de demanda se modifican de la siguiente manera:

$\sum_{k \in K} X_{i,k,Mes1}+\sum_{k \in K} X_{i,k,Mes2}+...+\sum_{k \in K} X_{i,k,l} + F_{i,Mes1}+ F_{i,Mes2}+...+ F_{i,l} \geq DemMin_{i,Mes1}+DemMin_{i,Mes2}+...+DemMin_{i,l}, \forall i \in I,\forall l \in L$

Noten la inclusión de las variables de faltante.
"

# ╔═╡ 1c958d64-1276-495c-8fd4-83450f47b326
md"Por otro lado, tener faltantes no debería ser gratis. En este caso no tenemos un costo por faltante, pero en general es una buena práctica empeorar la función objetivo en estos casos. Agreguemos, entonces, términos de penalización. Si $M$ es un número muy grande, entonces:

$Max  Z = \sum_{i \in I} \sum_{k \in K} \sum_{l \in L} CMg_{i,k,l} \cdot X_{i,k,l} - \sum_{i \in I} \sum_{l \in L} M \cdot F_{i,l}$



"

# ╔═╡ 37168cdf-d7a2-4a08-bf9c-03d4878e01d1
md"Codifiquemos ahora nuestro problema:"

# ╔═╡ 9d82dd6e-815d-4155-b4e8-ca43e80df2fc
begin
	# Creo una variable que contiene al modelo (Siempre empiezo así, solo cambiar nombre)
	ej4_2_falt = Model(HiGHS.Optimizer)

	# Datos (dependientes del problema)
	# Variables con los índices de los datos (luego los accederemos como i, j, etc.)
	productos_ej4_2_falt = ["A"; "B"; "C"] #=I=#
	equipos_ej4_2_falt = ["Eq1"; "Eq2"] #=J=#
	centros_ej4_2_falt =["C1"; "C2"] #=K=#
	meses_ej4_2_falt=["Mes1"; "Mes2"] #=L=#
	M=10000000
	# Los datos propiamente dichos anexados a sus índices
	contribucion_Mg_ej4_2_falt = NamedArray(cat([[100 90] 
										[150 180] 
										[175 155]],
									 	[[100 90] 
										[150 180] 
										[175 155]],dims=3), (productos_ej4_2_falt,centros_ej4_2_falt,meses_ej4_2_falt)) 
	estandar_Hequipo_ej4_2_falt = NamedArray(cat(
					#=C1=#			     [[10 5]
										 [20 7]
										 [25 15]],
					#=C2=#				[[8 6]
										 [17 6]
										 [23 16]],dims=3), (productos_ej4_2_falt,equipos_ej4_2_falt,centros_ej4_2_falt))
	Hequipo_disp_ej4_2_falt = NamedArray(cat([[7000 6500] 
									 [3000 3500]],
								 	 [[7000 6500] 
									 [3000 3500]],dims=3), (equipos_ej4_2_falt,centros_ej4_2_falt,meses_ej4_2_falt))
	Demanda_min_ej4_2_falt = NamedArray([200; 300],meses_ej4_2_falt)
	# Declaro las variables de decisión.
	Xej4_2_falt = @variable(ej4_2_falt, X[productos_ej4_2_falt,centros_ej4_2_falt,meses_ej4_2_falt] >= 0)
	F = @variable(ej4_2_falt, F[productos_ej4_2_falt,meses_ej4_2_falt] >= 0)

	# Creo la función objetivo.
	obje_j4_2_falt = @objective(ej4_2_falt, Max, sum([sum([sum([contribucion_Mg_ej4_2_falt[i,k,l] * Xej4_2_falt[i,k,l] for k in centros_ej4_2_falt]) + -M*F[i,l] for i in productos_ej4_2_falt]) for l in meses_ej4_2_falt]))

	# Cargo las restricciones.
	# Restricción de HE
	r1_ej4_2_falt = @constraint(ej4_2_falt, [j in equipos_ej4_2_falt, k in centros_ej4_2_falt, l in meses_ej4_2_falt], sum([estandar_Hequipo_ej4_2_falt[i,j,k] * Xej4_2_falt[i,k,l] for i in productos_ej4_2_falt]) <= Hequipo_disp_ej4_2_falt[j, k,l])
	
	# Restricciones de demanda mínima
	@constraint(ej4_2_falt, [i in productos_ej4_2_falt, l_actual in 1:length(meses_ej4_2_falt)],
		sum(
			[sum([Xej4_2_falt[i,k,l] 
				for k in centros_ej4_2_falt])
				for l in meses_ej4_2_falt[1:l_actual]]) +
		sum([F[i,l] for l in meses_ej4_2_falt[1:l_actual]])
		>= sum([Demanda_min_ej4_2_falt[l] for l in meses_ej4_2_falt[1:l_actual]])
	)
	
	latex_formulation(ej4_2_falt)
end

# ╔═╡ fbafd965-6ee9-4991-9556-6f1d5a7a7a5d
begin
	# Resuelvo el modelo (Siempre termino así, solo cambiar nombre del modelo)
	optimize!(ej4_2_falt)
	@show solution_summary(ej4_2_falt, verbose=true)
end

# ╔═╡ 27eee087-957e-42ba-8d38-b8c68ed43c53
md"Sería mejor obtener un resumen mas suscinto:"

# ╔═╡ 85957cb0-4394-49ff-be57-81afe4ecc5e3
begin
	for i in productos_ej4_2_falt
		for k in centros_ej4_2_falt
			for l in meses_ej4_2_falt
				if value(X[i,k,l]) >= 0.00001
					println("Producir ", round(value(X[i,k,l])), " unidades de ", i, " en centro ", k, " en el mes ", l, ".")
				end
			end
		end
	end

	println("")
	for i in productos_ej4_2_falt
		for l in meses_ej4_2_falt
			if value(F[i,l]) >= 0.00001
				println("Hay un faltante de ", round(value(F[i,l])), " unidades del producto ", i, " en el mes ", l, ".")
			end
		end
	end

	
end

# ╔═╡ 2c5cd720-b070-4851-b3f0-0ea8b5b934ca


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
HiGHS = "~1.5.0"
JuMP = "~1.9.0"
NamedArrays = "~0.9.7"
PlutoUI = "~0.7.50"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "8761e7f7ea53fe3eaf9665b9f43293d63c5c8265"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "d9a9701b899b30332bbcb3e1679c41cce81fb0e8"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.2"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c6d890a52d2c4d55d326439580c3b8d0875a77d9"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.7"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "485193efd2176b88e6622a39a246f8c5b600e74e"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.6"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "2e62a725210ce3c3c2e1a3080190e7ca491f18d7"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.7.2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "9c209fb7536406834aa938fb149964b985de6c83"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "7a60c856b9fa189eb34f5f8a6f6b5529b7942957"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.6.1"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "a4ad7ef19d2cdc2eff57abbbe68032b1cd0bd8f8"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.13.0"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "00e252f4d706b3d55a8863432e742bf5717b498d"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.35"

[[deps.HiGHS]]
deps = ["HiGHS_jll", "MathOptInterface", "SnoopPrecompile", "SparseArrays"]
git-tree-sha1 = "c4e72223d3c5401cc3a7059e23c6717ba5a08482"
uuid = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
version = "1.5.0"

[[deps.HiGHS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "53aadc2a53ef3ecc4704549b4791dea67657a4bb"
uuid = "8fd58aa0-07eb-5a78-9b36-339c94fd15ea"
version = "1.5.1+0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "49510dfcb407e572524ba94aeae2fced1f3feb0f"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.8"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JuMP]]
deps = ["LinearAlgebra", "MathOptInterface", "MutableArithmetics", "OrderedCollections", "Printf", "SnoopPrecompile", "SparseArrays"]
git-tree-sha1 = "611b9f12f02c587d860c813743e6cec6264e94d8"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.9.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "0a1b7c2863e44523180fdb3146534e265a91870b"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.23"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SnoopPrecompile", "SparseArrays", "SpecialFunctions", "Test", "Unicode"]
git-tree-sha1 = "3ba708c18f4a5ee83f3a6fb67a2775147a1f59f5"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.13.2"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "3295d296288ab1a0a2528feb424b854418acff57"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.2.3"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "2b3bcadd0fc35debfd67972e1af45a3a761f2d4b"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.7"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "d78db6df34313deaca15c5c0b9ff562c704fe1ab"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.5.0"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "478ac6c952fddd4399e71d4779797c538d0ff2bf"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.8"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "5bb5129fdd62a2bbbe17c2756932259acf467386"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.50"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "ef28127915f4229c971eb43f3fc075dd3fe91880"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.2.0"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "b8d897fe7fa688e93aef573711cb207c08c9e11e"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.19"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "94f38103c984f89cf77c402f2a68dbd870f8165f"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.11"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "074f993b0ca030848b897beff716d93aca60f06a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╠═e0033f10-cfdb-11ed-35d4-078aa3187b81
# ╟─54102d49-06d7-4e10-9eab-2052eab1ed9b
# ╟─10c79139-472d-42f0-b4c6-6ed2d5c0f5e8
# ╟─b09bea9a-44e7-4e81-b331-e920c883d983
# ╟─bca6bc36-ec31-4236-b863-44b6919c1d68
# ╟─379504d9-62b9-4b54-ae05-38d32d7d4ebc
# ╟─ee45437f-5d5d-409e-bea6-dcf7fecc8085
# ╟─0b992a9c-c4f7-4c38-892f-1947e95d0642
# ╟─d78f3f81-4c47-4161-a841-68bfc58c26aa
# ╟─32b8c1a0-1cd0-4bbf-9bcf-f25d0687ec82
# ╟─e22aca1a-8a84-4983-9977-78ab056fc3bd
# ╟─c771e0cb-ff02-4478-97b2-18f2fb062046
# ╟─fe0806ec-d5dc-4cda-a095-8b5fb7446264
# ╟─47be42fb-1680-4b5a-af0e-30de7953d796
# ╟─aff0eecf-08e7-4bd4-a7e7-eb1d097c3c1c
# ╟─44651a09-f4a6-47c3-b5ab-26865ca6edaf
# ╟─e9491fb6-1dea-4a55-bd9f-7de5a1110d16
# ╟─0ee99627-43cf-4a8c-8782-ab79db7e0ba5
# ╟─3d531676-b0e6-46bc-a37b-5975e7b4e9f8
# ╟─bc6a8497-ed19-4d26-b2fc-08f17acee250
# ╟─34e2a696-6f6a-4b72-b696-0aee363259d6
# ╟─a0f774da-5d3f-4cb8-9a7b-7f8d3384aeeb
# ╟─6b3b0339-96b9-4f9e-89be-4471a9d02b01
# ╟─db831192-0a5d-4113-9362-32ae458a9ee7
# ╟─eb2041e2-997f-4221-8fbc-25c0a9a59570
# ╟─216fb665-6d2e-4c23-a64c-76a757d75b95
# ╟─3187f72a-fb91-4675-94f0-7534fa51c279
# ╠═f338e5c7-037f-437e-98a6-0c611ae2ddc3
# ╠═75f76343-06a3-4ff2-9a79-281dc24c09ea
# ╠═20523ed2-f34d-4c0c-8f8c-897bedd8a7c1
# ╟─1c958d64-1276-495c-8fd4-83450f47b326
# ╟─37168cdf-d7a2-4a08-bf9c-03d4878e01d1
# ╠═9d82dd6e-815d-4155-b4e8-ca43e80df2fc
# ╠═fbafd965-6ee9-4991-9556-6f1d5a7a7a5d
# ╟─27eee087-957e-42ba-8d38-b8c68ed43c53
# ╠═85957cb0-4394-49ff-be57-81afe4ecc5e3
# ╠═2c5cd720-b070-4851-b3f0-0ea8b5b934ca
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

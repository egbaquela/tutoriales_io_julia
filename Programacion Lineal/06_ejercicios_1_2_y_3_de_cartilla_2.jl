### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 3999d6b1-4cdb-451e-9570-c7a424d580db
using PlutoUI, JuMP, HiGHS, NamedArrays

# ╔═╡ d51580b1-983b-418e-8742-ab51c4ed9f4f
md"# Problemas de mix de producción"

# ╔═╡ 3332f97b-7e31-419b-874e-02b567b27d09
md"## 1 Centro, 1 Equipo, 3 productos"

# ╔═╡ af18994c-9e81-4661-a30c-1345785e06ec
md"
Vamos a recordar el problema 1 de la cartilla de ejercicios 2:

>Queremos definir cuantas unidades fabricar de cada uno de nuestros tres productos, A, B y C:
>
> El producto A tiene un margen de contribución de \$100/u, y requiere de 10HE/u. 
>
> El producto B tiene un margen de contribución de \$150/u, y requiere de 20HE/u. 
>
> El producto C tiene un margen de contribución de \$175/u y requiere de 25HE/u. 
>
>El mercado nos demanda, como mínimo, 100 unidades de cada uno de estos productos. 
>
>Por otro lado, disponemos de un total de 7000 HE. 
>
>¿Cuántas unidades debemos fabricar de cada producto para maximizar el margen de contribución total?


"

# ╔═╡ 6b5505e5-d0d8-42fe-9d61-37ca939faf04
md"### Modelo"

# ╔═╡ b305dc54-0904-4e99-8058-9dc50192a283
md"Para este problema utilizaremos tres variables del tipo:

 $X_{i} \in \mathbb{R}$ : representa la cantidad de producto $i \in I$ que se decide producir, con $I=\{A,B,C\}$"

# ╔═╡ ced9da4e-f193-4cce-907c-ebe35db22d0b
md"#### Función objetivo"

# ╔═╡ edb985e2-a5d1-4ee2-81c1-20bf679535f4
md"Se quiere conocer cuánto producir de cada producto para maximizar la ganancia, por lo que:

$Max  Z = \sum_{i \in I} CMg_{i} \cdot X_{i}$

Es decir,

$Max  Z = 100 X_{A} + 150 X_{B} + 175 X_{C}$"

# ╔═╡ d1675a0a-7303-4a3a-a0d8-60583cf7257b
md"#### Restricciones"

# ╔═╡ ae1ab578-093d-4db3-9e1f-df29353d908a
md"Se deben tener en cuenta dos tipos de restricciones en este problema: las relacionadas con las horas equipo y las relacionadas con la demanda que se desea satisfacer."

# ╔═╡ 3a75931e-1500-4275-9ad9-3b1b7c556c8b
md"##### Horas equipo"

# ╔═╡ 49203b1d-20a0-4269-9a50-622093637436
md"La manufactura de cada producto requiere de cierto tiempo en equipos definido por un estándar de producción que depende de cada producto en sí, del equipo y de los procedimientos con los que se cuente en la planta. Los estándares vinieron dados por unidad, por lo que la suma de cada estándar multiplicado por la cantidad producida de ese producto deberá ser menor o igual a la disponibilidad de horas del equipo:"

# ╔═╡ 109320b4-4ce2-4765-8c26-efba6c63a9d2
md"$\sum_{i \in I} Estándar_{i} \cdot X_{i} \leq DispHE$"

# ╔═╡ aa43f8e0-f4a3-448e-954b-c09440c8df6c
md"Como tenemos un centro, un equipo y tres productos solo necesitamos una ecuación con tres sumandos:"

# ╔═╡ e6fcdc89-ed6f-4c70-909f-6d346be0d07f
md"$Estándar_{A} \cdot X_{A} + Estándar_{B} \cdot X_{B} + Estándar_{C} \cdot X_{C}   \leq DispHE$"

# ╔═╡ f841f75c-3cea-4277-b110-a21c11351cee
md"Reemplazando con los datos del problema, tenemos:"

# ╔═╡ d38097c8-e2f5-4601-8f23-189178558310
md"$10X_{A} + 20X_{B} + 25X_{C}   \leq 7000$"

# ╔═╡ a4f2ad73-6017-4a9e-8290-0e7efa55c564
md"#### Demanda mínima"

# ╔═╡ 89f430fb-02d1-419a-9831-e1296022ee44
md"Como mínimo, queremos producir la demanda mínima en unidades de cada una de las variables, por lo que:"

# ╔═╡ a8168094-613b-4ac9-b0ac-d9402dc0e199
md"$X_{i} \geq DemMin_{i}, \forall i \in I$"

# ╔═╡ d6c2a00b-b5f5-407f-bed3-fe7cc9aac484
md"En este caso, que hay un centro y tres productos, tendremos tres ecuaciones con una variable en cada ecuación. Además la demanda mínima es igual para todos los productos y es 100."

# ╔═╡ 97d38c38-f150-4563-995c-f98ecc07ff03
md"$X_{A} \geq 100$"

# ╔═╡ a579b8d4-9f90-402d-bec2-19763e60ab9d
md"$X_{B} \geq 100$"

# ╔═╡ 82ac1506-945f-4791-9ce0-2e1a184a9150
md"$X_{C} \geq 100$"

# ╔═╡ 6bec153b-9cd5-4049-ad35-cd14cde05ea3
md"### Modelo completo"

# ╔═╡ f62d2bb9-6a3a-4289-a80b-cdff5d61de09
md"$Max  Z = 100 X_{A} + 150 X_{B} + 175 X_{C}$
$10X_{A} + 20X_{B} + 25X_{C}   \leq 7000$
$X_{A} \geq 100$
$X_{B} \geq 100$
$X_{C} \geq 100$
$X_{i} \in \mathbb{R}, \forall i \in I$"

# ╔═╡ eae6ead0-cb44-11ed-19f2-f92d550c035e
begin
	# Creo una variable que contiene al modelo (Siempre empiezo así, solo cambiar nombre)
	ej1_2 = Model(HiGHS.Optimizer)

	# Datos (dependientes del problema)
	# Variables con los índices de los datos (luego los accederemos como i, j, etc.)
	productos_ej1_2 = ["A"; "B"; "C"]
	# Los datos propiamente dichos anexados a sus índices
	contribucion_Mg_ej1_2 = NamedArray([100; 150; 175], productos_ej1_2) 
	estandar_Hequipo_ej1_2 = NamedArray([10; 20; 25], productos_ej1_2)
	Hequipo_disp = 7000
	Demanda_min = 100
	# Declaro las variables de decisión.
	X_ej1_2 = @variable(ej1_2, X[productos_ej1_2] >= 0)

	# Creo la función objetivo.
	obj_ej1_2 = @objective(ej1_2, Max, sum([contribucion_Mg_ej1_2[i] * X_ej1_2[i] for i in productos_ej1_2]))

	# Cargo las restricciones.
	# Restricción de HE
	r1_ej1_2 = @constraint(ej1_2, #=Esto significa sumatoria en i=# sum([estandar_Hequipo_ej1_2[i] * X_ej1_2[i] for i in productos_ej1_2]) <= Hequipo_disp)
	# Restricciones de demanda mínima
	r2_ej1_2 = @constraint(ej1_2, [i in productos_ej1_2], X_ej1_2[i] >= Demanda_min)
	
	latex_formulation(ej1_2)
end

# ╔═╡ 551d0314-4a85-4284-8424-58a18d13dfe2
begin
	# Resuelvo el modelo (Siempre termino así, solo cambiar nombre del modelo)
	optimize!(ej1_2)
	@show solution_summary(ej1_2, verbose=true)
end

# ╔═╡ 4dfbf627-3ed2-409a-974a-9d12255b0a4d
md"## 1 Centro, 2 Equipos, 3 productos"

# ╔═╡ f3d64a49-042e-4912-8f5a-984bc1951685
md"
Vamos a recordar el problema 2 de la cartilla de ejercicios 2:

>Queremos definir cuantas unidades fabricar de cada uno de nuestros tres productos, A, B y C:
>
> El producto A tiene un margen de contribución de \$100/u, y requiere de 10HE1/u y 5HE2/u. 
>
> El producto B tiene un margen de contribución de \$150/u, y requiere de 20HE1/u y 7HE2/u.  
>
> El producto C tiene un margen de contribución de \$175/u y requiere de 25H1E/u y 15HE2/u. 
>
>El mercado nos demanda, como mínimo, 100 unidades de cada uno de estos productos. 
>
>Por otro lado, disponemos de un total de 7000 HE1 y 3000HE2. 
>
>¿Cuántas unidades debemos fabricar de cada producto para maximizar el margen de contribución total?


"

# ╔═╡ c2daf356-656a-48ed-803c-2183f1457b5e
md"### Modelo"

# ╔═╡ d0806a29-7142-4a10-987c-872231e3fee3
md"El problema es una extensión del primero, solo que con dos equipos. Las restricciones de demanda mínima no dependían de la cantidad de equipos, por lo que no se modificarán, pero las de horas equipos sí."

# ╔═╡ 633fe791-aeb1-4030-8326-8183bc441472
md"Para este problema utilizaremos tres variables del tipo:

 $X_{i} \in \mathbb{R}$ : representa la cantidad de producto $i \in I$ que se decide producir, con $I=\{A,B,C\}$"

# ╔═╡ dc357040-dd13-4955-9262-2ce6e2d55354
md"Podemos además definir al equipo $j \in J$, con $J=\{Eq1,Eq2\}$"

# ╔═╡ f5f1097d-9926-45ee-859f-47bf29fa0f30
md"#### Función objetivo"

# ╔═╡ 1774f1be-0208-41c1-b227-26b668931825
md"Se quiere conocer cuánto producir de cada producto para maximizar la ganancia, por lo que:

$Max  Z = \sum_{i \in I} CMg_{i} \cdot X_{i}$

Es decir,

$Max  Z = 100 X_{A} + 150 X_{B} + 175 X_{C}$"

# ╔═╡ 37a0e259-1827-47d1-a214-fc032aeb3c9b
md"#### Restricciones"

# ╔═╡ 8526a528-9302-4324-a522-262d3b40e7cc
md"##### Horas Equipo"

# ╔═╡ 8a1d1c90-a859-46c8-8ebb-5a3277ebc0f7
md"La manufactura de cada producto requiere de cierto tiempo en equipos definido por un estándar de producción que depende de cada producto en sí, del equipo y de los procedimientos con los que se cuente en la planta. Los estándares vinieron dados por unidad, por lo que la suma de cada estándar multiplicado por la cantidad producida de ese producto deberá ser menor o igual a la disponibilidad de horas de cada equipo:"

# ╔═╡ b8a482f8-5ef7-45ef-b871-a037514dda33
md"$\sum_{i \in I} Estándar_{i,j} \cdot X_{i} \leq DispHE_{j}, \forall j \in J$"

# ╔═╡ 42505ab8-5644-41b6-9b47-f9aa60d9167b
md"Como tenemos un centro, dos equipos y tres productos necesitamos dos ecuaciones con tres sumandos cada una:"

# ╔═╡ 5a4c108a-9cb8-4b41-b4b1-435cbbeba263
md"$Estándar_{A,Eq1} \cdot X_{A} + Estándar_{B,Eq1} \cdot X_{B} + Estándar_{C,Eq1} \cdot X_{C}   \leq DispHE_{Eq1}$

$Estándar_{A,Eq2} \cdot X_{A} + Estándar_{B,Eq2} \cdot X_{B} + Estándar_{C,Eq2} \cdot X_{C}   \leq DispHE_{Eq2}$
"

# ╔═╡ 3b02c0cb-a685-4dc9-a9e6-a20f53f3fd58
md"Reemplazando con los datos del problema, tenemos:"

# ╔═╡ d157f9f3-101b-432b-abba-cf92fb210314
md"$10X_{A} + 20X_{B} + 25X_{C}   \leq 7000$

$5X_{A} + 7X_{B} + 15X_{C}   \leq 3000$"

# ╔═╡ e7abd575-5de9-416d-9123-c007f2966b78
md"##### Demanda mínima"

# ╔═╡ a7668d57-915e-42c1-aff4-8dad99d0b21b
md"Ver caso anterior."

# ╔═╡ 51422b8d-4246-4c72-b394-31c7702a100b
md"### Modelo Completo"

# ╔═╡ 90433426-001f-438e-8023-91e1e798e8d0
md"$Max  Z = 100 X_{A} + 150 X_{B} + 175 X_{C}$
$10X_{A} + 20X_{B} + 25X_{C}   \leq 7000$
$5X_{A} + 7X_{B} + 15X_{C}   \leq 3000$
$X_{A} \geq 100$
$X_{B} \geq 100$
$X_{C} \geq 100$
$X_{i} \in \mathbb{R}, \forall i \in I$"

# ╔═╡ 17791dda-32d5-4220-96ba-d35e0c38cadd
begin
	# Creo una variable que contiene al modelo (Siempre empiezo así, solo cambiar nombre)
	ej2_2 = Model(HiGHS.Optimizer)

	# Datos (dependientes del problema)
	# Variables con los índices de los datos (luego los accederemos como i, j, etc.)
	productos_ej2_2 = ["A"; "B"; "C"]
	equipos_ej2_2 = ["Eq1"; "Eq2"]
	# Los datos propiamente dichos anexados a sus índices
	contribucion_Mg_ej2_2 = NamedArray([100; 150; 175], productos_ej2_2) 
	estandar_Hequipo_ej2_2 = NamedArray([[10 5]
										 [20 7]
										 [25 15]], (productos_ej2_2,equipos_ej2_2))
	Hequipo_disp_ej2_2 = NamedArray([7000; 3000], equipos_ej2_2)
	Demanda_min_ej2_2 = 100
	# Declaro las variables de decisión.
	Xej2_2 = @variable(ej2_2, x_[productos_ej2_2] >= 0)

	# Creo la función objetivo.
	objej2_2 = @objective(ej2_2, Max, sum([contribucion_Mg_ej2_2[i] * Xej2_2[i] for i in productos_ej2_2]))

	# Cargo las restricciones.
	# Restricción de HE
	r1ej2_2 = @constraint(ej2_2, #=Esto significa para cada j=# [j in equipos_ej2_2], sum([estandar_Hequipo_ej2_2[i,j] * Xej2_2[i] for i in productos_ej2_2]) <= Hequipo_disp_ej2_2[j])
	
	# Restricciones de demanda mínima
	r2_ej2_2 = @constraint(ej2_2, [i in productos_ej2_2], Xej2_2[i] >= Demanda_min_ej2_2)
	
	latex_formulation(ej2_2)
end

# ╔═╡ 4691b57d-8451-4dad-bd27-1408869860f1
begin
	# Resuelvo el modelo (Siempre termino así, solo cambiar nombre del modelo)
	optimize!(ej2_2)
	@show solution_summary(ej2_2, verbose=true)
end

# ╔═╡ aa550e5a-f960-405f-8f94-cb6e014b5744
md"## 2 Centros, 2 Equipos, 3 productos"

# ╔═╡ cb8838f6-7ae9-4c77-94f8-3d21d8cf9512
md"
Vamos a recordar el problema 3 de la cartilla de ejercicios 2:

>En base al problema 2, resulta que podemos fabricar nuestros productos en dos centros diferentes. Los datos para cada producto fabricado en el segundo centro son:
>
> El producto A tiene un margen de contribución de \$90/u, y requiere de 8HE1/u y 6HE2/u.
>
> El producto B tiene un margen de contribución de \$180/u, y requiere de 17HE1/u y 6HE2/u.   
>
> El producto C tiene un margen de contribución de \$155/u y requiere de 23H1E/u y 16HE3/u. 
>
>(los del primer centro son los valores definidos en el problema 2).
>
>El mercado nos demanda, como mínimo, 200 unidades de cada uno de estos productos (sin importar en donde los fabriquemos). 
>
>Por otro lado, disponemos de un total de 7000 HE1 y 3000 HE2 en el centro 1, y 6500 HE1 y 3500 HE2 en el centro 2. 
>
>¿Cuántas unidades debemos fabricar de cada producto, en cada centro, para maximizar el margen de contribución total?


"

# ╔═╡ 332fa5e7-a75d-459f-aff1-3387993e8079
md"En este caso, tanto la capacidad de producir la demanda mínima como la cantidad y estándares de los equipos se vieron afectados, por lo que ambos tipos de restricciones sufrirán cambios"

# ╔═╡ 06e0adc8-a7a4-4b0b-a36b-5b47f296cebf
md"### Modelo"

# ╔═╡ dc8c4a35-cf0a-412e-a689-adcb7c584ce5
md"Para este problema utilizaremos seis variables del tipo:

 $X_{i,k} \in \mathbb{R}$ : representa la cantidad de producto $i \in I$ que se decide producir en el centro de producción $k \in K$, con $I=\{A,B,C\}$ y $K=\{C1,C2\}$

Podemos además definir al equipo $j \in J$, con $J=\{Eq1,Eq2\}$"

# ╔═╡ b27264f3-39e5-4571-b24f-1f72146703a3
md"#### Función objetivo"

# ╔═╡ 88872629-4d17-44ad-bf39-41ddf8fe0792
md"Se quiere conocer cuánto producir de cada producto para maximizar la ganancia, por lo que:

$Max  Z = \sum_{i \in I} \sum_{k \in K} CMg_{i,k} \cdot X_{i,k}$

Es decir,

$Max  Z = 100 X_{A,C1} + 150 X_{B,C1} + 175 X_{C,C1} + 90 X_{A,C2} + 180 X_{B,C2} + 155 X_{C,C2}$"

# ╔═╡ 9fefc71a-fe9c-4c61-b022-190720b7824a
md"#### Restricciones"

# ╔═╡ a4427bff-7a31-438d-a96a-fa75d1251f45
md"Seguimos teniendo los dos mismos tipos de restricciones"

# ╔═╡ f936e7cd-be12-47d9-bd6d-1818a77c9bee
md"##### Horas Equipo"

# ╔═╡ 52aa447b-d763-4acc-b3b4-09b188195f03
md"La manufactura de cada producto requiere de cierto tiempo en equipos definido por un estándar de producción que depende de cada producto en sí, del equipo y de los procedimientos con los que se cuente en la planta. Los estándares vinieron dados por unidad, por lo que la suma de cada estándar multiplicado por la cantidad producida de ese producto deberá ser menor o igual a la disponibilidad de horas de cada equipo."

# ╔═╡ 995cc921-1ac0-46d4-9efb-3e29229a1d31
md"Como tenemos 2 equipos en 2 plantas, en este caso hay 4 disponibilidades. La del Eq1 en C1, la del Eq2 en C1, la del Eq1 en C2 y la del Eq2 en C2:"

# ╔═╡ 5cb77851-d28b-4217-9eb2-2f09f008ad79
md"$\sum_{i \in I} Estándar_{i,j,k} \cdot X_{i,k} \leq DispHE_{j,k}, \forall j \in J, \forall k \in K$"

# ╔═╡ 06c3c368-4c6c-47f8-b8a1-6b3e20d913ad
md"Como tenemos dos centros, dos equipos y tres productos necesitamos cuatro ecuaciones (2 Centros x 2 Equipos) con tres sumandos cada una:"

# ╔═╡ 5ee89a38-7b5a-49af-9d17-18297c863bce
md"$Estándar_{A,Eq1,C1} \cdot X_{A,C1} + Estándar_{B,Eq1,C1} \cdot X_{B,C1} + Estándar_{C,Eq1,C1} \cdot X_{C,C1}   \leq DispHE_{Eq1,C1}$

$Estándar_{A,Eq2,C1} \cdot X_{A,C1} + Estándar_{B,Eq2,C1} \cdot X_{B,C1} + Estándar_{C,Eq2,C1} \cdot X_{C,C1}   \leq DispHE_{Eq2,C1}$

$Estándar_{A,Eq1,C2} \cdot X_{A,C2} + Estándar_{B,Eq1,C2} \cdot X_{B,C2} + Estándar_{C,Eq1,C2} \cdot X_{C,C2}   \leq DispHE_{Eq1,C2}$

$Estándar_{A,Eq2,C2} \cdot X_{A,C2} + Estándar_{B,Eq2,C2} \cdot X_{B,C2} + Estándar_{C,Eq2,C2} \cdot X_{C,C2}   \leq DispHE_{Eq2,C2}$
"

# ╔═╡ cd08b7ed-b87e-4f4a-b684-b64c21af718f
md"Reemplazando con los datos del problema, tenemos:"

# ╔═╡ 40c0efee-42ff-442d-9af7-6149e84931a9
md"$10X_{A,C1} + 20X_{B,C1} + 25X_{C,C1}   \leq 7000$

$5X_{A,C1} + 7X_{B,C1} + 15X_{C,C1}   \leq 3000$

$8X_{A,C2} + 17X_{B,C2} + 23X_{C,C2}   \leq 6500$

$6X_{A,C1} + 6X_{B,C1} + 16X_{C,C2}   \leq 3500$"

# ╔═╡ a16f09c2-fa21-4956-bcf5-ace81753558a
md"#### Demanda mínima"

# ╔═╡ c6c15b0d-a76a-4965-b464-4cd2a0f74d54
md"La demanda mínima será un poco diferente. Al mercado no le importa a donde hacemos cada producto, por lo que deberemos sumar lo que decidimos producir en cada planta por producto para cada demanda mínima."

# ╔═╡ 9194e63c-7b3c-45e0-9aeb-019d4f7e44fb
md"$\sum_{k \in K} X_{i,k} \geq DemMin_{i}, \forall i \in I$"

# ╔═╡ 5f47cf57-8bd6-46f4-babe-5ca7d0528081
md"En este caso, que hay dos centros y tres productos, tendremos tres ecuaciones con dos variables sumadas en cada ecuación. Además la demanda mínima es igual para todos los productos y es 200."

# ╔═╡ 36653a46-6f3e-4911-8fda-29817e764b02
md"$\sum_{k \in K} X_{i,k} \geq DemMin_{i}, \forall i \in I$"

# ╔═╡ 955d2934-88f1-4193-9f3a-d99b1ebaf7be
md"$X_{A,C1}+X_{A,C2} \geq 200$
$X_{B,C1}+X_{B,C2} \geq 200$
$X_{C,C1}+X_{C,C2} \geq 200$"

# ╔═╡ 0a622e96-3768-414e-b13e-aa1c5e2b07fd
md"### Modelo Completo"

# ╔═╡ 209f35cc-d0cc-4225-8495-ce796e633474
md"$Max  Z = 100 X_{A,C1} + 150 X_{B,C1} + 175 X_{C,C1} + 90 X_{A,C2} + 180 X_{B,C2} + 155 X_{C,C2}$
$10X_{A,C1} + 20X_{B,C1} + 25X_{C,C1}   \leq 7000$
$5X_{A,C1} + 7X_{B,C1} + 15X_{C,C1}   \leq 3000$
$8X_{A,C2} + 17X_{B,C2} + 23X_{C,C2}   \leq 6500$
$6X_{A,C1} + 6X_{B,C1} + 16X_{C,C2}   \leq 3500$
$X_{A,C1}+X_{A,C2} \geq 200$
$X_{B,C1}+X_{B,C2} \geq 200$
$X_{C,C1}+X_{C,C2} \geq 200$
$X_{i,k} \in \mathbb{R}, \forall i \in I, \forall k \in K$"

# ╔═╡ d7aafad4-430d-4230-b529-d5415fdaefd2
begin
	# Creo una variable que contiene al modelo (Siempre empiezo así, solo cambiar nombre)
	ej3_2 = Model(HiGHS.Optimizer)

	# Datos (dependientes del problema)
	# Variables con los índices de los datos (luego los accederemos como i, j, etc.)
	productos_ej3_2 = ["A"; "B"; "C"]
	equipos_ej3_2 = ["Eq1"; "Eq2"]
	centros_ej3_2 =["C1"; "C2"]
	# Los datos propiamente dichos anexados a sus índices
	contribucion_Mg_ej3_2 = NamedArray([[100 90] 
										[150 180] 
										[175 155]], (productos_ej3_2,centros_ej3_2)) 
	estandar_Hequipo_ej3_2 = NamedArray(cat(
					#=C1=#			     [[10 5]
										 [20 7]
										 [25 15]],
					#=C2=#				[[8 6]
										 [17 6]
										 [23 16]],dims=3), (productos_ej3_2,equipos_ej3_2,centros_ej3_2))
	Hequipo_disp_ej3_2 = NamedArray([[7000 6500] 
									 [3000 3500]], (equipos_ej3_2,centros_ej3_2))
	Demanda_min_ej3_2 = 200
	# Declaro las variables de decisión.
	Xej3_2 = @variable(ej3_2, x[productos_ej3_2,centros_ej3_2] >= 0)

	# Creo la función objetivo.
	objej3_2 = @objective(ej3_2, Max, sum([sum([contribucion_Mg_ej3_2[i,k] * Xej3_2[i,k] for i in productos_ej3_2]) for k in centros_ej3_2]))

	# Cargo las restricciones.
	# Restricción de HE
	r1ej3_2 = @constraint(ej3_2, #=Esto significa para cada j=# [j in equipos_ej3_2, k in centros_ej3_2], sum([estandar_Hequipo_ej3_2[i,j,k] * Xej3_2[i,k] for i in productos_ej3_2]) <= Hequipo_disp_ej3_2[j, k])
	
	# Restricciones de demanda mínima
	r2_ej3_2 = @constraint(ej3_2, [i in productos_ej3_2], sum([Xej3_2[i,k] for k in centros_ej3_2]) >= Demanda_min_ej3_2)
	
	latex_formulation(ej3_2)
end

# ╔═╡ 48141702-d73b-4414-8f7d-5c294ced6649
begin
	# Resuelvo el modelo (Siempre termino así, solo cambiar nombre del modelo)
	optimize!(ej3_2)
	@show solution_summary(ej3_2, verbose=true)
end

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
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

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
# ╠═3999d6b1-4cdb-451e-9570-c7a424d580db
# ╟─d51580b1-983b-418e-8742-ab51c4ed9f4f
# ╟─3332f97b-7e31-419b-874e-02b567b27d09
# ╟─af18994c-9e81-4661-a30c-1345785e06ec
# ╟─6b5505e5-d0d8-42fe-9d61-37ca939faf04
# ╟─b305dc54-0904-4e99-8058-9dc50192a283
# ╟─ced9da4e-f193-4cce-907c-ebe35db22d0b
# ╟─edb985e2-a5d1-4ee2-81c1-20bf679535f4
# ╟─d1675a0a-7303-4a3a-a0d8-60583cf7257b
# ╟─ae1ab578-093d-4db3-9e1f-df29353d908a
# ╟─3a75931e-1500-4275-9ad9-3b1b7c556c8b
# ╟─49203b1d-20a0-4269-9a50-622093637436
# ╟─109320b4-4ce2-4765-8c26-efba6c63a9d2
# ╟─aa43f8e0-f4a3-448e-954b-c09440c8df6c
# ╟─e6fcdc89-ed6f-4c70-909f-6d346be0d07f
# ╟─f841f75c-3cea-4277-b110-a21c11351cee
# ╟─d38097c8-e2f5-4601-8f23-189178558310
# ╟─a4f2ad73-6017-4a9e-8290-0e7efa55c564
# ╟─89f430fb-02d1-419a-9831-e1296022ee44
# ╟─a8168094-613b-4ac9-b0ac-d9402dc0e199
# ╟─d6c2a00b-b5f5-407f-bed3-fe7cc9aac484
# ╟─97d38c38-f150-4563-995c-f98ecc07ff03
# ╟─a579b8d4-9f90-402d-bec2-19763e60ab9d
# ╟─82ac1506-945f-4791-9ce0-2e1a184a9150
# ╟─6bec153b-9cd5-4049-ad35-cd14cde05ea3
# ╟─f62d2bb9-6a3a-4289-a80b-cdff5d61de09
# ╠═eae6ead0-cb44-11ed-19f2-f92d550c035e
# ╠═551d0314-4a85-4284-8424-58a18d13dfe2
# ╟─4dfbf627-3ed2-409a-974a-9d12255b0a4d
# ╟─f3d64a49-042e-4912-8f5a-984bc1951685
# ╟─c2daf356-656a-48ed-803c-2183f1457b5e
# ╟─d0806a29-7142-4a10-987c-872231e3fee3
# ╟─633fe791-aeb1-4030-8326-8183bc441472
# ╟─dc357040-dd13-4955-9262-2ce6e2d55354
# ╟─f5f1097d-9926-45ee-859f-47bf29fa0f30
# ╟─1774f1be-0208-41c1-b227-26b668931825
# ╟─37a0e259-1827-47d1-a214-fc032aeb3c9b
# ╟─8526a528-9302-4324-a522-262d3b40e7cc
# ╟─8a1d1c90-a859-46c8-8ebb-5a3277ebc0f7
# ╟─b8a482f8-5ef7-45ef-b871-a037514dda33
# ╟─42505ab8-5644-41b6-9b47-f9aa60d9167b
# ╟─5a4c108a-9cb8-4b41-b4b1-435cbbeba263
# ╟─3b02c0cb-a685-4dc9-a9e6-a20f53f3fd58
# ╟─d157f9f3-101b-432b-abba-cf92fb210314
# ╟─e7abd575-5de9-416d-9123-c007f2966b78
# ╟─a7668d57-915e-42c1-aff4-8dad99d0b21b
# ╟─51422b8d-4246-4c72-b394-31c7702a100b
# ╟─90433426-001f-438e-8023-91e1e798e8d0
# ╠═17791dda-32d5-4220-96ba-d35e0c38cadd
# ╠═4691b57d-8451-4dad-bd27-1408869860f1
# ╟─aa550e5a-f960-405f-8f94-cb6e014b5744
# ╟─cb8838f6-7ae9-4c77-94f8-3d21d8cf9512
# ╟─332fa5e7-a75d-459f-aff1-3387993e8079
# ╟─06e0adc8-a7a4-4b0b-a36b-5b47f296cebf
# ╟─dc8c4a35-cf0a-412e-a689-adcb7c584ce5
# ╟─b27264f3-39e5-4571-b24f-1f72146703a3
# ╟─88872629-4d17-44ad-bf39-41ddf8fe0792
# ╟─9fefc71a-fe9c-4c61-b022-190720b7824a
# ╟─a4427bff-7a31-438d-a96a-fa75d1251f45
# ╟─f936e7cd-be12-47d9-bd6d-1818a77c9bee
# ╟─52aa447b-d763-4acc-b3b4-09b188195f03
# ╟─995cc921-1ac0-46d4-9efb-3e29229a1d31
# ╟─5cb77851-d28b-4217-9eb2-2f09f008ad79
# ╟─06c3c368-4c6c-47f8-b8a1-6b3e20d913ad
# ╟─5ee89a38-7b5a-49af-9d17-18297c863bce
# ╟─cd08b7ed-b87e-4f4a-b684-b64c21af718f
# ╟─40c0efee-42ff-442d-9af7-6149e84931a9
# ╟─a16f09c2-fa21-4956-bcf5-ace81753558a
# ╟─c6c15b0d-a76a-4965-b464-4cd2a0f74d54
# ╟─9194e63c-7b3c-45e0-9aeb-019d4f7e44fb
# ╟─5f47cf57-8bd6-46f4-babe-5ca7d0528081
# ╟─36653a46-6f3e-4911-8fda-29817e764b02
# ╟─955d2934-88f1-4193-9f3a-d99b1ebaf7be
# ╟─0a622e96-3768-414e-b13e-aa1c5e2b07fd
# ╟─209f35cc-d0cc-4225-8495-ce796e633474
# ╠═d7aafad4-430d-4230-b529-d5415fdaefd2
# ╠═48141702-d73b-4414-8f7d-5c294ced6649
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

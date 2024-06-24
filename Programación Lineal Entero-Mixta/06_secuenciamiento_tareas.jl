### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ f6b07961-6a93-4ed0-8dfb-26d6e477acb1
begin
	using PlutoUI, JuMP, HiGHS, NamedArrays, DataFrames, Gadfly
	TableOfContents(title="Contenido")
end 

# ╔═╡ 2773ada4-2d1a-11ed-0928-635c9c9cf446
md"# Problemas de secuenciamiento de tareas"

# ╔═╡ 352b57ea-d6a3-4ee1-aed7-96761aebcec9
md"## Secuenciamiento de tareas"

# ╔═╡ 45e25c69-c4fe-4b75-97e0-30133d4a6068
md"Nos referimos a un problema de secuenciamiento, cuando el foco de la decisión es el orden en que se deben realizar ciertas tareas. Así, por ejemplo, para tres tareas A, B, C existen $3!$ combinaciones; es decir, tenemos seis posibles secuencias (A-B-C, A-C-B, B-A-C, B-C-A, C-A-B y C-B-A). Decidir cuál secuencia es la mejor dependerá de la naturaleza del problema, pero, en general, existe alguna relación con el tiempo total de la secuencia. Otra característica es que las tareas no se pueden hacer en paralelo, sino que sí o sí deben hacerse en secuencia (no es posible hacer las tareas en paralelo)."

# ╔═╡ 0a9988f8-33d6-48f4-99f0-aaceb5a2bbe5
md"Para continuar la explicación con un caso, utilizaremos el problema 32 de la cartilla."

# ╔═╡ b84a8d36-6494-494f-bf15-a71132483fbc
md"
> Pastelería SA utiliza un solo horno para hacer tres tortas por día (el resto del día lo utiliza con otros fines). El horno debe estar a determinada temperatura antes de poner cada torta y se debe mantener a esa temperatura durante toda la cocción. Enfriar o calentar el horno 5 ºC lleva 1 minuto. Tanto el tiempo en horno como la temperatura a la que debe estar el horno (en ºC) de cada producto aparecen en la siguiente tabla. "

# ╔═╡ e5fce636-ba6e-42c5-bc5b-920c993addb8
md"|  			Producto 		 	|  			Tiempo en horno (minutos) 		 	|  			Temperatura a la que debe estar el horno (º C) 		 	|
|-----------	|----------------------------------	|-----------------------	|
|  			Selva negra 		       	|  			5 		       	|  			200 		       	|
|  			Lemon Pie 		       	|  			20 		       	|  			350 		       	|
|  			Cheesecake 		       	|  			15 		       	|  			400 		       	|"

# ╔═╡ 56c619fc-a0f7-4e60-a79d-6e3f46c319ea
md"
> El objetivo de la empresa es determinar la secuencia (orden en que deben ponerse en el horno) de productos que maximice el tiempo que le queda al horno para usarlo con otros fines."

# ╔═╡ 9a9428c1-70c9-41f3-b7d6-f6c103025c6c
md"En este caso, queremos saber en qué orden cocinaremos las tortas para minimizar el tiempo total de tener las tres terminadas."

# ╔═╡ 266880d7-e07e-4a9b-b5e2-7fbcb41af18d
md"### Modelado"

# ╔═╡ 9d039aa2-e1be-4576-b7ae-539468b414bd
md"
Si utilizamos las variables de decisión:

* _ $x_{i} \in \mathbb{Z}, con \ x_{i} \geq 0$ que representen la fecha de inicio del producto $i \in \{1, 2, 3\}$.
* _ $y_{i,j} \in \mathbb{B}, \forall i < j$  que cuando valgan $1$ representen que el producto $i$ se hace antes que el $j \in \{1, 2, 3\}$ y cuando valgan $0$ representen que el producto $j$ se hace antes que el $i$.
"

# ╔═╡ e5cef8ef-dd5e-4ca9-81f7-30c27def778b
md"
Además, tenemos datos; llamémosle:

* _	$THorno_{i}$ a la temperatura a la que debe estar el horno para el producto $i$.
* _ $tHorno_{i}$ al tiempo que el producto $i$ debe permanecer dentro del horno.
* _ $varHorno = 5$ a los grados que enfría o calienta el horno por minuto.

Y, también, necesitaremos una variable de decisión auxiliar:
* _ $w \in \mathbb{Z}, con \ w \geq 0$, variable auxiliar que será igual a la mayor de todas las $x_{i}+tHorno_{i}$.
"

# ╔═╡ 4986cc5a-74c0-417d-bb7a-12b2015ba9c6
md"#### Cálculos auxiliares"

# ╔═╡ f0f70394-ea18-4035-9b12-18c3fc0f9a49
md"Con esto, podemos calcular el dato:"

# ╔═╡ 394efbb1-cd1b-4afd-959c-1be90b976dcc
md"
$tVar_{i,j} = \left\lvert \frac{THorno_{i}-THorno_{j}}{varHorno} \right\rvert$
"

# ╔═╡ 980a4a5a-3291-4118-a4cb-6a47331f8fc5
md"que representa el tiempo que tarda el horno en calentarse o enfriarse desde la temperatura que necesita el producto $i$ hasta la que necesita el producto $j$."

# ╔═╡ e351013b-15ad-452c-bea9-37674a104151
md"Finalmente, se puede calcular:"

# ╔═╡ abbe84b0-5fdd-447a-922f-651c73c52a8b
md"
$duracion_{i,j} = tHorno_{i}+tVar_{i,j}$
"

# ╔═╡ cac89777-a9ad-437c-b7a4-358441196443
md"que simboliza el tiempo que se tarda desde el inicio del producto $i$ hasta que el horno está a la temperatura necesaria para que inicie $j$, según la siguiente tabla de tiempos (las filas corresponden al producto que se pone antes y las columnas al producto subsiguiente en la secuencia):

"

# ╔═╡ d8d790a5-146f-4b66-8874-6cf1a00b1831
md"
|  			 		 	|  			Selva negra 		 	|  			Lemon Pie 		 	|  			Cheesecake 		 	|
|-----------	|----------------------------------	|-----------------------	|-----------------------	|
|  			**Selva negra** 		       	|  			0 		       	|  			35 		       	|  			45 		       	|
|  			**Lemon Pie** 		       	|  			50 		       	|  			0 		       	|  			30 		       	|
|  			**Cheesecake** 		       	|  			55 		       	|  			25 		       	|  			0 		       	|
"

# ╔═╡ b7bec7ea-4f30-4d29-a19c-445e500f511c
md"La tabla se lee:
Si pongo Selva negra a cocinar en el minuto $m$, deberé esperar $m+35$ minutos para poner Lemon Pie y $m+45$ minutos para poner Cheesecake."

# ╔═╡ 6f86a91d-846a-4bb4-abf2-9fce800c4a94
md"#### Función objetivo"

# ╔═╡ 31e5229a-466e-4685-991b-98d3e015667a
md"Para como hicimos nuestras variables. Lo más sencillo es usar a $w$ como la variable a minimizar, puesto que representa al tiempo del fin de la última tarea (el mayor inicio más duración)."

# ╔═╡ ec896c06-3d25-4cff-a3ba-d32023d8c9dc
md"
$Min \ Z = w$
"

# ╔═╡ c4a59158-4e1b-46b1-ba5a-d19ff574419f
md"#### Restricciones de vínculo entre w y las x"

# ╔═╡ f682c01a-061c-4a42-91bb-d49ff0ea2133
md"Definimos a la variable w como la mayor de las $x_{i}+tHorno_{i}$, por lo que debemos mostrarlo en las restricciones:"

# ╔═╡ efa74ed7-5fa2-4971-ac62-5a3fe3ad2ea1
md"$w \geq x_{i}+tHorno_{i}, \forall i \in I$"

# ╔═╡ af65d4f7-611e-434e-b1b7-3d178cc39d41
md"#### Restricciones de no solapamiento"

# ╔═╡ e090771f-ec0b-41ac-8124-10f2944716bf
md"El tipo de restricciones más frecuente para este tipo de problemas es la de no solapamiento. Estas restricciones se utilizan para que el modelo sepa que las tareas no se pueden hacer en paralelo. Básicamente, lo que hacen es que si la tarea $i$ se hace antes que la $j$ (esto lo indica $y_{i,j}$ cuando vale $1$), obligan a que el inicio de la tarea $j$ sea luego del fin de la $i$."

# ╔═╡ eab0dada-6102-4eae-9edf-604a94954356
md"
$M(1-y_{i,j})+x_{j} \geq x_{i}+duracion_{i,j}, \forall i \in I,j \in J, \ con \ i<j$
"

# ╔═╡ 73b39859-329e-4a93-9f72-2f66157f76e4
md">Nota: Cabe destacar que si la tarea $i$ no se hace antes de la $j$, como $y_{i,j}$ es $0$, la M grande que utilizamos hace que esta restricción no tenga ningún efecto (el número grande M siempre hace que se cumpla el signo de mayor en la inecuación)."

# ╔═╡ 93f857f0-f801-4bc1-9dc5-3f414f437c3b
md"Por el contrario, si la tarea $i$ no se hace antes que la $j$ (esto lo indica $y_{i,j}$ cuando vale $0$), es porque la $j$ se hace antes que la $i$, entonces se debe agregar ese escenario:"

# ╔═╡ 4ee5f54c-67a5-4f32-8e76-efeb58a6f670
md"
$My_{i,j}+x_{i} \geq x_{j}+duracion_{j,i}, \forall i \in I,j \in J, \ con \ i<j$
"

# ╔═╡ ccc07fa6-7f42-4041-bfc3-a2bd51a9aa63
md"
> Nota: Como en el caso anterior, tenemos que si la tarea $j$ no se hace antes de la $i$, como $y_{i,j}$ vale $1$, la M grande que utilizamos hace que esta restricción no tenga ningún efecto (el número grande M siempre hace que se cumpla el signo de mayor en la inecuación).
"

# ╔═╡ 70b0f876-ac36-489e-bf12-7fc8e87936f9
md"### Modelado completo"

# ╔═╡ 21ca493f-b567-40fd-977a-be9f7d09318a
md"
$Min \ Z = w$
"

# ╔═╡ 316365f7-8809-40fe-93a5-e80f940dd3dd
md"Sujeto a:"

# ╔═╡ bad54d03-68a6-4db2-944b-970dcfb3f4e6
md"
$M(1-y_{i,j})+x_{j} \geq x_{i}+duracion_{i,j}, \forall i \in I,j \in J, \ con \ i<j$
$My_{i,j}+x_{i} \geq x_{j}+duracion_{j,i}, \forall i \in I,j \in J, \ con \ i<j$
$w \geq x_{i}+tHorno_{i}, \forall i \in I$
$x_{i} \geq 0, \forall i \in I$
$y_{i,j} \in \{0,1\}, \forall i \in I, \forall j \in J, \ con \ i<j$
"

# ╔═╡ 59fccf56-d2c4-4ac8-a9ca-e14fb6b04bb5
md"### Resolución"

# ╔═╡ 363eacb9-0397-46fc-b055-25a58d6ab2e2
begin
	model_seq_pas_v1 = Model(HiGHS.Optimizer) #
	
	# Dimensiones
	tareas_seq_pas_v1 = ["SN", "LP", "CC"]
	cant_tareas_seq_pas_v1 = length(tareas_seq_pas_v1)
	
	#Datos
	M_seq_pas_v1=1000
	TvarPM_seq_pas_v1=5
	tHorno_seq_pas_v1 = NamedArray([5, 20, 15], tareas_seq_pas_v1) 
	THorno_seq_pas_v1 = NamedArray([200, 350, 400], tareas_seq_pas_v1) 
	#= El bloque de código que sigue es equivalente a definir este vector:
	
	tiempos_de_proceso_seq_pas_v1 = NamedArray([[0 35 45]
									 [50 0 30 ]
									 [55 25 0]], (tareas_seq_pas_v1,tareas_seq_pas_v1))
	
	Hace las cuentas que hicimos para llegar a las duraciones en la sección cálculos auxiliares
	=#
	tiempos_de_proceso_seq_pas_v1 = NamedArray([[0 0 0]
								 [0 0 0 ]
								 [0 0 0]], (tareas_seq_pas_v1,tareas_seq_pas_v1))
	for i in 1:cant_tareas_seq_pas_v1
		for j in (i+1):cant_tareas_seq_pas_v1
			tiempos_de_proceso_seq_pas_v1[tareas_seq_pas_v1[i],tareas_seq_pas_v1[j]]=tHorno_seq_pas_v1[i]+abs((THorno_seq_pas_v1[tareas_seq_pas_v1[i]]-THorno_seq_pas_v1[tareas_seq_pas_v1[j]])/TvarPM_seq_pas_v1)
			
			tiempos_de_proceso_seq_pas_v1[tareas_seq_pas_v1[j],tareas_seq_pas_v1[i]]=tHorno_seq_pas_v1[j]+abs((THorno_seq_pas_v1[tareas_seq_pas_v1[i]]-THorno_seq_pas_v1[tareas_seq_pas_v1[j]])/TvarPM_seq_pas_v1)
		end
	end
 
	
	# Declaro las variables de decisión.
	x_seq_pas_v1 = @variable(model_seq_pas_v1, x_seq_pas_v1[1:cant_tareas_seq_pas_v1] >= 0)
	y_seq_pas_v1 = @variable(model_seq_pas_v1, y_seq_pas_v1[i=1:cant_tareas_seq_pas_v1,j=(1+i):cant_tareas_seq_pas_v1], Bin)
	w_seq_pas_v1 = @variable(model_seq_pas_v1, w_seq_pas_v1 >= 0)
	
	# Creo la función objetivo. 
	obj_seq_pas_v1 = @objective(model_seq_pas_v1, Min, w_seq_pas_v1)

	# Cargo las restricciones de no solapamiento.
	r1_seq_pas_v1 = @constraint(model_seq_pas_v1, [i in 1:cant_tareas_seq_pas_v1, j in (1+i):cant_tareas_seq_pas_v1], M_seq_pas_v1*y_seq_pas_v1[i,j] + x_seq_pas_v1[i] >= x_seq_pas_v1[j] + tiempos_de_proceso_seq_pas_v1[tareas_seq_pas_v1[j],tareas_seq_pas_v1[i]])
	r2_seq_pas_v1 = @constraint(model_seq_pas_v1, [i in 1:cant_tareas_seq_pas_v1, j in (1+i):cant_tareas_seq_pas_v1], M_seq_pas_v1*(1-y_seq_pas_v1[i,j]) + x_seq_pas_v1[j] >= x_seq_pas_v1[i] + tiempos_de_proceso_seq_pas_v1[tareas_seq_pas_v1[i],tareas_seq_pas_v1[j]])

	# Cargo vinculo entre W y X
	r3_seq_pas_v1 = @constraint(model_seq_pas_v1, [i in 1:cant_tareas_seq_pas_v1], w_seq_pas_v1 >= x_seq_pas_v1[i] + tHorno_seq_pas_v1[tareas_seq_pas_v1[i]])
		
	latex_formulation(model_seq_pas_v1)
end

# ╔═╡ acb96eb5-350e-4ba1-95be-92a1661b631a
begin
	optimize!(model_seq_pas_v1)
	@show solution_summary(model_seq_pas_v1, verbose=true)
end

# ╔═╡ 11c5e0b0-5123-4567-9ec3-ed3f20d11e8a
model_seq_pas_v1

# ╔═╡ c9680511-0a39-428e-abe7-a9ee71283c99
md"### Vista gráfica del resultado"

# ╔═╡ 469aba47-46d5-4f06-afd5-ca97f06699ce
begin
	D1 = DataFrame(y = Int[1, 2, 3],
	    ylab=tareas_seq_pas_v1,
	    x = value.(model_seq_pas_v1[:x_seq_pas_v1]),
	    xend = value.(model_seq_pas_v1[:x_seq_pas_v1])+tHorno_seq_pas_v1,
	    id = ["a","b","c"]
	)
	ylabdict = Dict(i=>D1[!,:ylab][i] for i in 1:3)
	
	coord = Coord.cartesian(ymin=0.4, ymax=4.6)
	p = plot(D1, coord,
	    layer(x=:x, xend=:xend, y=:y, yend=:y, color=:id, Geom.segment, Theme(line_width=10mm)), 
	    Scale.y_continuous(labels=i->get(ylabdict,i,"")),
	    Guide.xlabel("Tiempo en minutos"), Guide.ylabel(""),
	    Theme(key_position=:none) 
	)
end

# ╔═╡ 58f3b012-50b6-4980-8c13-103a459d3530
md"## Secuenciamiento de tareas con condiciones iniciales"

# ╔═╡ 575eb7cc-65a9-43e4-9542-99d52d6420ad
md"Muchas veces, nos encontraremos con problemas que, tendrán requisitos de inicio distintos para la primera tarea de la secuencia como tareas de limpieza, mantenimiento, cambios de matriz, etcétera; en función de la naturaleza del problema. Si consideramos el ejercicio 33 de la cartilla, podemos observar que es igual que el problema anterior, solo que ahora la primera tarea necesita un tiempo de espera al inicio. Hay distintas formas de modelarlo, por ejemplo, usando variables que identifiquen cuál es la primera tarea y con eso formar más restricciones. En este caso, no sería necesario (ni deseable) complejizar tanto porque el tiempo de espera funciona como una cota inferior de las $x_{i}$, ya que, por como está planteada la situación, es imposible que una tarea que no se asigne primera entre al horno antes."

# ╔═╡ 6685b640-5594-46c1-8ae2-3da63c84e40c
md"Según los datos del problema, la cota será entonces:"

# ╔═╡ 462a156e-346d-4fda-8541-901528221ff8
md"$cotaInf_{i} = \left\lvert \frac{THorno_{i}-80}{varHorno} \right\rvert$"

# ╔═╡ ebb010a4-0371-4b1d-b099-2b37b4b1af43
md"En otras palabras, solo necesitamos agregar la restricción:"

# ╔═╡ ef7f853a-b65a-4cbf-8fd3-6a42864ffee1
md"$x_{i} \geq cotaInf_{i}$"

# ╔═╡ 4feb0d74-323a-4947-9c71-7a8c3e43512c
md"### Modelo completo"

# ╔═╡ 8bdce93a-6e93-419a-9bf8-96d3cb7a3f33
md"
$Min \ Z = w$
"

# ╔═╡ edad701c-1053-4fca-bd57-4e7678705991
md"Sujeto a:"

# ╔═╡ 17f89e05-d9a9-4e6a-9004-58291edb9091
md"
$M(1-y_{i,j})+x_{j} \geq x_{i}+duracion_{i,j}, \forall i \in I,j \in J, \ con \ i<j$
$My_{i,j}+x_{i} \geq x_{j}+duracion_{j,i}, \forall i \in I,j \in J, \ con \ i<j$
$w \geq x_{i}+tHorno_{i}, \forall i \in I$
$x_{i} \geq cotaInf_{i}$
$x_{i} \geq 0, \forall i \in I$
$y_{i,j} \in \{0,1\}, \forall i \in I, \forall j \in J, \ con \ i<j$
"

# ╔═╡ 24bf6ad9-acb5-46dd-96fa-62de72a60e2a
md"### Resolución"

# ╔═╡ ce734804-5042-4f7d-bd9e-0e0c5927f409
begin
	model_seq_pas_v2 = Model(HiGHS.Optimizer) #
	
	# Dimensiones
	tareas_seq_pas_v2 = ["SN", "LP", "CC"]
	cant_tareas_seq_pas_v2 = length(tareas_seq_pas_v2)
	
	#Datos
	M_seq_pas_v2=1000
	TvarPM_seq_pas_v2=5
	
	tHorno_seq_pas_v2 = NamedArray([5, 20, 15], tareas_seq_pas_v2) 
	THorno_seq_pas_v2 = NamedArray([200, 350, 400], tareas_seq_pas_v2) 

	cotaInf_seq_pas_v2 = abs.(THorno_seq_pas_v2 .- 80)./5 
	#= El bloque de código que sigue es equivalente a definir este vector:
	
	tiempos_de_proceso_seq_pas_v1 = NamedArray([[0 35 45]
									 [50 0 30 ]
									 [55 25 0]], (tareas_seq_pas_v1,tareas_seq_pas_v1))
	
	Hace las cuentas que hicimos para llegar a las duraciones en la sección cálculos auxiliares
	=#
	tiempos_de_proceso_seq_pas_v2 = NamedArray([[0 0 0]
								 [0 0 0 ]
								 [0 0 0]], (tareas_seq_pas_v2,tareas_seq_pas_v2))
	for i in 1:cant_tareas_seq_pas_v2
		for j in (i+1):cant_tareas_seq_pas_v2
			tiempos_de_proceso_seq_pas_v2[tareas_seq_pas_v2[i],tareas_seq_pas_v2[j]]=tHorno_seq_pas_v2[i]+abs((THorno_seq_pas_v2[tareas_seq_pas_v2[i]]-THorno_seq_pas_v2[tareas_seq_pas_v2[j]])/TvarPM_seq_pas_v2)
			
			tiempos_de_proceso_seq_pas_v2[tareas_seq_pas_v2[j],tareas_seq_pas_v2[i]]=tHorno_seq_pas_v2[j]+abs((THorno_seq_pas_v2[tareas_seq_pas_v2[i]]-THorno_seq_pas_v2[tareas_seq_pas_v2[j]])/TvarPM_seq_pas_v2)
		end
	end
 
	
	# Declaro las variables de decisión.
	x_seq_pas_v2 = @variable(model_seq_pas_v2, x_seq_pas_v2[1:cant_tareas_seq_pas_v2] >= 0)
	y_seq_pas_v2 = @variable(model_seq_pas_v2, y_seq_pas_v2[i=1:cant_tareas_seq_pas_v2,j=(1+i):cant_tareas_seq_pas_v2], Bin)
	w_seq_pas_v2 = @variable(model_seq_pas_v2, w_seq_pas_v2 >= 0)
	
	# Creo la función objetivo. 
	obj_seq_pas_v2 = @objective(model_seq_pas_v2, Min, w_seq_pas_v2)

	# Cargo las restricciones de no solapamiento.
	r1_seq_pas_v2 = @constraint(model_seq_pas_v2, [i in 1:cant_tareas_seq_pas_v2, j in (1+i):cant_tareas_seq_pas_v2], M_seq_pas_v2*y_seq_pas_v2[i,j] + x_seq_pas_v2[i] >= x_seq_pas_v2[j] + tiempos_de_proceso_seq_pas_v2[tareas_seq_pas_v2[j],tareas_seq_pas_v2[i]])
	r2_seq_pas_v2 = @constraint(model_seq_pas_v2, [i in 1:cant_tareas_seq_pas_v2, j in (1+i):cant_tareas_seq_pas_v2], M_seq_pas_v2*(1-y_seq_pas_v2[i,j]) + x_seq_pas_v2[j] >= x_seq_pas_v2[i] + tiempos_de_proceso_seq_pas_v2[tareas_seq_pas_v2[i],tareas_seq_pas_v2[j]])

	# Cargo vinculo entre W y X
	r3_seq_pas_v2 = @constraint(model_seq_pas_v2, [i in 1:cant_tareas_seq_pas_v2], w_seq_pas_v2 >= x_seq_pas_v2[i] + tHorno_seq_pas_v2[tareas_seq_pas_v2[i]])

	# Cargo condición inicial
	r4_seq_pas_v2 = @constraint(model_seq_pas_v2, [i in 1:cant_tareas_seq_pas_v2], x_seq_pas_v2[i] >=  cotaInf_seq_pas_v2[tareas_seq_pas_v2[i]])
	
	latex_formulation(model_seq_pas_v2)
	
end

# ╔═╡ 1e38449b-ce67-4735-b657-77be779ed9f6
begin
	optimize!(model_seq_pas_v2)
	@show solution_summary(model_seq_pas_v2, verbose=true)
end

# ╔═╡ 6952d3c6-6025-4d85-9c30-2f6b765ddbeb
md"### Vista gráfica del resultado"

# ╔═╡ b4ed2864-3787-4385-92e7-d3fbee57793e
begin
	D2 = DataFrame(y = Int[1, 2, 3],
	    ylab=tareas_seq_pas_v2,
	    x = value.(model_seq_pas_v2[:x_seq_pas_v2]),
	    xend = value.(model_seq_pas_v2[:x_seq_pas_v2])+tHorno_seq_pas_v2,
	    id = ["a","b","c"]
	)
	ylabdict2 = Dict(i=>D2[!,:ylab][i] for i in 1:3)
	
	coord2 = Coord.cartesian(ymin=0.4, ymax=4.6)
	p2 = plot(D2, coord2,
	    layer(x=:x, xend=:xend, y=:y, yend=:y, color=:id, Geom.segment, Theme(line_width=10mm)), 
	    Scale.y_continuous(labels=i->get(ylabdict2,i,"")),
	    Guide.xlabel("Tiempo en minutos"), Guide.ylabel(""),
	    Theme(key_position=:none) 
	)
end

# ╔═╡ 763d5891-af27-43f6-a609-5bde19d8faf4
md"## Secuenciamiento de tareas con condiciones finales"

# ╔═╡ c053d1d7-81cf-45bb-828d-70e7382367b7
md"En ciertas aplicaciones, necesitamos que se consideren consecuencias de la secuencia elegida. Por ejemplo, si es la secuencia en la que despachamos productos fuera de la compañía hacia un almacén, puede que debamos considerar el tiempo que requiere el camión para volver a planta. El problema 34 plantea una situación similar, dejar a una máquina en un determinado estado al dejar de usarla."

# ╔═╡ 210e0dfa-7156-4151-a03f-d6eccde69750
md"Entonces, en nuestro modelo, podríamos cambiar la variable $w$, para que nos indique que el objetivo ahora incluye además el tiempo que se requiere para cumplir con el requisito."

# ╔═╡ f33b6c83-8b07-4f46-b32d-79e10b60d868
md"$tCondFinal_{i} = \left\lvert \frac{THorno_{i}-50}{varHorno} \right\rvert$"

# ╔═╡ 66a6ff12-135f-4381-8d16-bdca556df987
md"### Modelo completo"

# ╔═╡ 3ba0cfa7-67a6-407a-b010-8333f1e2b896
md"
$Min \ Z = w$
"

# ╔═╡ 1b46024b-ae78-4b01-a0e2-8651531254ba
md"Sujeto a:"

# ╔═╡ 4c4edd5b-891f-457d-8504-ba294a36be6d
md"
$M(1-y_{i,j})+x_{j} \geq x_{i}+duracion_{i,j}, \forall i \in I,j \in J, \ con \ i<j$
$My_{i,j}+x_{i} \geq x_{j}+duracion_{j,i}, \forall i \in I,j \in J, \ con \ i<j$
$w \geq x_{i}+tHorno_{i}+tCondFinal_{i}, \forall i \in I$
$x_{i} \geq 0, \forall i \in I$
$y_{i,j} \in \{0,1\}, \forall i \in I, \forall j \in J, \ con \ i<j$
"

# ╔═╡ 99c92994-6827-419a-a031-6e1973bece66
md"### Resolución"

# ╔═╡ fcc8f3ec-9762-45d8-a747-320e91ed7f9d
begin
	model_seq_pas_v3 = Model(HiGHS.Optimizer) #
	
	# Dimensiones
	tareas_seq_pas_v3 = ["SN", "LP", "CC"]
	cant_tareas_seq_pas_v3 = length(tareas_seq_pas_v3)
	
	#Datos
	M_seq_pas_v3=1000
	TvarPM_seq_pas_v3=5
	
	tHorno_seq_pas_v3 = NamedArray([5, 20, 15], tareas_seq_pas_v3) 
	THorno_seq_pas_v3 = NamedArray([200, 350, 400], tareas_seq_pas_v3) 

	cotaInf_seq_pas_v3 = abs.(THorno_seq_pas_v3 .- 80)./5 
	tcondFinal_seq_pas_v3 = abs.(THorno_seq_pas_v3 .- 50)./5 
	#= El bloque de código que sigue es equivalente a definir este vector:
	
	tiempos_de_proceso_seq_pas_v1 = NamedArray([[0 35 45]
									 [50 0 30 ]
									 [55 25 0]], (tareas_seq_pas_v1,tareas_seq_pas_v1))
	
	Hace las cuentas que hicimos para llegar a las duraciones en la sección cálculos auxiliares
	=#
	tiempos_de_proceso_seq_pas_v3 = NamedArray([[0 0 0]
								 [0 0 0 ]
								 [0 0 0]], (tareas_seq_pas_v3,tareas_seq_pas_v3))
	for i in 1:cant_tareas_seq_pas_v3
		for j in (i+1):cant_tareas_seq_pas_v3
			tiempos_de_proceso_seq_pas_v3[tareas_seq_pas_v3[i],tareas_seq_pas_v3[j]]=tHorno_seq_pas_v3[i]+abs((THorno_seq_pas_v3[tareas_seq_pas_v3[i]]-THorno_seq_pas_v3[tareas_seq_pas_v3[j]])/TvarPM_seq_pas_v3)
			
			tiempos_de_proceso_seq_pas_v3[tareas_seq_pas_v3[j],tareas_seq_pas_v3[i]]=tHorno_seq_pas_v3[j]+abs((THorno_seq_pas_v3[tareas_seq_pas_v3[i]]-THorno_seq_pas_v3[tareas_seq_pas_v3[j]])/TvarPM_seq_pas_v3)
		end
	end
 
	
	# Declaro las variables de decisión.
	x_seq_pas_v3 = @variable(model_seq_pas_v3, x_seq_pas_v3[1:cant_tareas_seq_pas_v3] >= 0)
	y_seq_pas_v3 = @variable(model_seq_pas_v3, y_seq_pas_v3[i=1:cant_tareas_seq_pas_v3,j=(1+i):cant_tareas_seq_pas_v3], Bin)
	w_seq_pas_v3 = @variable(model_seq_pas_v3, w_seq_pas_v3 >= 0)
	
	# Creo la función objetivo. 
	obj_seq_pas_v3 = @objective(model_seq_pas_v3, Min, w_seq_pas_v3)

	# Cargo las restricciones de no solapamiento.
	r1_seq_pas_v3 = @constraint(model_seq_pas_v3, [i in 1:cant_tareas_seq_pas_v3, j in (1+i):cant_tareas_seq_pas_v3], M_seq_pas_v3*y_seq_pas_v3[i,j] + x_seq_pas_v3[i] >= x_seq_pas_v3[j] + tiempos_de_proceso_seq_pas_v3[tareas_seq_pas_v3[j],tareas_seq_pas_v3[i]])
	r2_seq_pas_v3 = @constraint(model_seq_pas_v3, [i in 1:cant_tareas_seq_pas_v3, j in (1+i):cant_tareas_seq_pas_v3], M_seq_pas_v3*(1-y_seq_pas_v3[i,j]) + x_seq_pas_v3[j] >= x_seq_pas_v3[i] + tiempos_de_proceso_seq_pas_v3[tareas_seq_pas_v3[i],tareas_seq_pas_v3[j]])

	# Cargo vinculo entre W y X
	r3_seq_pas_v3 = @constraint(model_seq_pas_v3, [i in 1:cant_tareas_seq_pas_v3], w_seq_pas_v3 >= x_seq_pas_v3[i] + tHorno_seq_pas_v3[tareas_seq_pas_v3[i]]+tcondFinal_seq_pas_v3[tareas_seq_pas_v3[i]])

	# Cargo condición inicial
	r4_seq_pas_v3 = @constraint(model_seq_pas_v3, [i in 1:cant_tareas_seq_pas_v3], x_seq_pas_v3[i] >=  cotaInf_seq_pas_v3[tareas_seq_pas_v3[i]])
	
	latex_formulation(model_seq_pas_v3)
end

# ╔═╡ 3948ec58-287a-4a1f-9d72-81285a338b9f
begin
	optimize!(model_seq_pas_v3)
	@show solution_summary(model_seq_pas_v3, verbose=true)
end

# ╔═╡ 3f4f5c55-6d49-44f3-892e-748c8dc305ca
md"### Vista gráfica del resultado"

# ╔═╡ c713db47-2b96-4fe0-9c56-6c860edb2221
begin
	D3 = DataFrame(y = Int[1, 2, 3],
	    ylab=tareas_seq_pas_v3,
	    x = value.(model_seq_pas_v3[:x_seq_pas_v3]),
	    xend = value.(model_seq_pas_v3[:x_seq_pas_v3])+tHorno_seq_pas_v3,
	    id = ["a","b","c"]
	)
	ylabdict3 = Dict(i=>D3[!,:ylab][i] for i in 1:3)
	
	coord3 = Coord.cartesian(ymin=0.4, ymax=4.6)
	p3 = plot(D3, coord3,
	    layer(x=:x, xend=:xend, y=:y, yend=:y, color=:id, Geom.segment, Theme(line_width=10mm)), 
	    Scale.y_continuous(labels=i->get(ylabdict3,i,"")),
	    Guide.xlabel("Tiempo en minutos"), Guide.ylabel(""),
	    Theme(key_position=:none) 
	)
end

# ╔═╡ abf8d36b-788e-4915-bf1a-97f04175876f
md"## Secuenciamiento de tareas con penalización"

# ╔═╡ a8c705d1-6f8f-40aa-b22f-97a8781810cb
md"Los problemas de secuenciamiento de tareas son muy comunes en la planificación de manufactura, entre otros. Veamos como ejemplo el problema 13:

> Jobco utiliza una sola máquina para procesar tres trabajos. Tanto el tiempo de procesamiento como la fecha límite (en días) de cada trabajo aparecen en la siguiente tabla. Las fechas límite se miden a partir de cero, el tiempo de inicio supuesto del primer trabajo.

|  			Trabajo 		 	|  			Tiempo de procesamiento (días) 		 	|  			Fecha límite (días) 		 	|  			Penalización por retraso (\$/día) 		 	|
|-----------	|----------------------------------	|-----------------------	|-------------------------------------	|
|  			1 		       	|  			5 		                              	|  			25 		                  	|  			19 		                                	|
|  			2 		       	|  			20 		                             	|  			22 		                  	|  			22 		                                	|
|  			3 		       	|  			15 		                             	|  			35 		                  	|  			34 		                                	|

> El objetivo del problema es determinar la secuencia de los trabajos que minimice la penalización por retraso en el procesamiento de los tres trabajos.


"

# ╔═╡ 593933e0-49f1-49eb-94f1-7c9999e35465
md"### Modelado de la secuencia"

# ╔═╡ 6954e630-1a65-433f-a250-d735e4d6e4ca
md"Los problemas de secuenciamiento son un poco mas complejos en su modelado, ya que, en general, la estructura de variables a utilizar no es tan intuitiva ni se extrae directamente de la descripción textual del problema. Incluso, tiene dos partes diferenciadas: la parte relativa a realizar los trabajos en forma secuencial, no solapada, y la parte relativa a las demoras.

Modelemos primero la secuenciación de trabajos. Comencemos definiendo dos tipos de variables:

* _ $x_{j} \in \mathbb{R}, con \ x_{j} \geq 0$ = fecha de inicio (en días) para el trabajo $j$.
* _ $y_{i,j} \in \mathbb{B}, \forall i < j$ = variable binaria que vale $1$ si el trabajo $i$ se realiza antes que el $j$, y $0$ en el caso contrario.

Como los trabajos $i$ y $j$ no se pueden solapar, tenemos dos posibles alternativas: 

* La fecha de inicio del trabajo $i$ es posterior a la finalización del trabajo $j$, esto es: $x_{i} \geq x_{j} + duracion_{j}$
* La fecha de inicio del trabajo $j$ es posterior a la finalización del trabajo $i$, esto es: $x_{j} \geq x_{i} + duracion_{i}$

Es evidente que solo uno de los dos escenarios anteriores puede suceder. Esto, lo podemos modelar haciendo uso de la técnica de la $M$:

$My_{i,j} + x_{i} \geq x_{j} + duracion_{j}$

$M(1 - y_{i,j}) + x_{j} \geq x_{i} + duracion_{i}$

Necesitamos las dos restricciones simultaneamente, ya que, cuando $y_{i,j}=0$:


$0 + x_{i} \geq x_{j} + duracion_{j}$

$M + x_{j} \geq x_{i} + duracion_{i}$

la primer restricción fuerza a $i$ a comenzar luego (aunque no, necesariemente, a continuación) de la finalización de $j$, mientras que permite a $j$ tomar cualquier momento de inicio respecto de $i$ (ya que $M$ es un tiene un valor muy grande). Por el contrario, si  $y_{i,j}=1$:

$M + x_{i} \geq x_{j} + duracion_{j}$

$0 + x_{j} \geq x_{i} + duracion_{i}$

la situación se invierte, y es $j$ quien está obligada a comenzar luego de la finalización de $i$.

Notemos también cuantas $y_{i,j}$ necesitamos: $y_{1,2}$, $y_{1,3}$ y $y_{2,3}$. Y, por ende, solo tres pares de restricciones.

"

# ╔═╡ bfc7d52e-b778-4df7-b57c-8b4aeda745af
md"### Modelado de la demora"

# ╔═╡ b035d381-43ab-46d0-88fd-58d9031d755c
md"Para modelar los días de demora, podemos apelar el uso de variables auxiliares. Si $x_{i} + duracion_{i}$ es la fecha de finalización, y $deadline_{i}$ la fecha máxima en la cual podemos terminar sin sufrir penalización, podemos crear dos variables auxiliares:

* _ $s_{i}^{+} \in \mathbb{R}, con \ x_{j} \geq 0$: variable que indica cuantos días terminamos después de $deadline_{i}$.
* _ $s_{i}^{-} \in \mathbb{R}, con \ x_{j} \geq 0$: variable que indica cuantos días terminamos antes de $deadline_{i}$.

Con estas variables, podemos armar una restricción como sigue:

$x_{i} + duracion_{i} - s_{i}^{+} + s_{i}^{-} = deadline_{i}$

en la cual, dado que $s_{i}^{+}$ y $s_{i}^{-}$ son no negativas, una de las dos valdrá $0$, y la otra indicara los días de demora/adelanto (o, pueden ser las dos iguales a cero, indicando que se termina exactamente en la fecha esperada).

"

# ╔═╡ 25eb1e43-3626-4972-8341-9f8087d66e62
md"### Modelado completo"

# ╔═╡ 0f9f48c7-6fc1-4b49-9905-150cd9421346
md"

$Min \ Z=\sum_{i}penalizacion_{i} \cdot s_{i}^{+}$

Sujeto a:

$My_{i,j} + x_{i} \geq x_{j} + duracion_{j}, \forall i, \forall j, \ con \ i<j$

$M(1 - y_{i,j}) + x_{j} \geq x_{i} + duracion_{i}, \forall i, \forall j, \ con \ i<j$

$x_{i} + duracion_{i} - s_{i}^{+} + s_{i}^{-} = deadline_{i}, \forall i$

$x_{i} \geq 0, \forall i$

$s_{i}^{+} \geq 0, \forall i$

$s_{i}^{-} \geq 0, \forall i$

$y_{i,j} \in \{0,1\}, \forall i, \forall j, \ con \ i<j$



En forma extensa:

$Min \ Z=19s_{1}^{+} + 12s_{2}^{+} + 34s_{3}^{+}$

Sujeto a:

$x_{1} - x_{2} + My_{1,2} \geq 20$

$-x_{1} + x_{2} - My_{1,2} \geq 5-M$

$x_{1} - x_{3} + My_{1,3} \geq 15$

$-x_{1} + x_{3} - My_{1,3} \geq 5-M$

$x_{2} - x_{3} + My_{2,3} \geq 15$

$-x_{2} + x_{3} - My_{2,3} \geq 20-M$

$x_{1} - s_{1}^{+} + s_{1}^{-} \geq 25-5$

$x_{2} - s_{2}^{+} + s_{2}^{-} \geq 22-20$

$x_{3} - s_{3}^{+} + s_{3}^{-} \geq 35-15$

$x_{1}, x_{2}, x_{3} \geq 0$

$s_{1}^{+}, s_{2}^{+}, s_{3}^{+} \geq 0$

$s_{1}^{-}, s_{2}^{-}, s_{3}^{-} \geq 0$

$y_{1,2}, y_{1,3}, y_{2,3} \in \{0,1\}$

"

# ╔═╡ e92e1e71-b547-4aea-b2a9-eb19814bcaf3
md"### Resolución"

# ╔═╡ 580eaef4-bdd8-43e5-821c-3dc5c47451fa
begin
	model_seq_v1 = Model(HiGHS.Optimizer) #
	
	# Dimensiones
	tareas = ["Tarea 1", "Tarea 2", "Tarea 3"]
	cant_tareas = length(tareas)
	
	#Datos
	M=1000
	tiempos_de_proceso = NamedArray([5;20;15], tareas) 
	fecha_entrega_esperada = NamedArray([25;25;35], tareas) 
	penalizacion_retraso = NamedArray([19;22;34], tareas) 

	
	# Declaro las variables de decisión.
	x_seq_v1 = @variable(model_seq_v1, x_seq_v1[1:cant_tareas] >= 0)
	y_seq_v1 = @variable(model_seq_v1, y_seq_v1[i=1:cant_tareas,j=(1+i):cant_tareas], Bin)
	s_mas_seq_v1 = @variable(model_seq_v1, s_mas_seq_v1[1:cant_tareas] >= 0)
	s_menos_seq_v1 = @variable(model_seq_v1, s_menos_seq_v1[1:cant_tareas] >= 0)
	

	# Creo la función objetivo. 
	obj_seq_v1 = @objective(model_seq_v1, Min,
		sum([penalizacion_retraso[tareas[i]]*s_mas_seq_v1[i] for i in 1:cant_tareas]))

	# Cargo las restricciones de no solapamiento.
	r1_seq_v1 = @constraint(model_seq_v1, [i in 1:cant_tareas, j in (1+i):cant_tareas], M*y_seq_v1[i,j] + x_seq_v1[i] >= x_seq_v1[j] + tiempos_de_proceso[tareas[j]])
	r2_seq_v1 = @constraint(model_seq_v1, [i in 1:cant_tareas, j in (1+i):cant_tareas], M*(1-y_seq_v1[i,j]) + x_seq_v1[j] >= x_seq_v1[i] + tiempos_de_proceso[tareas[i]])


	# Cargo las restricciones de no balance de tiempo.
	r3_seq_v1 = @constraint(model_seq_v1, [i in 1:cant_tareas], x_seq_v1[i] + tiempos_de_proceso[tareas[i]] - s_mas_seq_v1[i] + s_menos_seq_v1[i] == fecha_entrega_esperada[tareas[i]])
	
	latex_formulation(model_seq_v1)
end

# ╔═╡ 850480c9-7332-4501-baca-d479155f0606
begin
	optimize!(model_seq_v1)
	
	@show termination_status(model_seq_v1)
end

# ╔═╡ 9cd041d2-9cdd-462b-a8a1-15c37198930d
begin
	@show solution_summary(model_seq_v1, verbose=true)
end

# ╔═╡ ab2ac035-0147-4dd1-ba21-c18ab03f5cb3
md"### Vista gráfica del resultado"

# ╔═╡ 4c30ddd8-a88d-48b4-886f-f520a4d0c0af
begin
	D4 = DataFrame(y = Int[1, 2, 3],
	    ylab=tareas,
	    x = value.(model_seq_v1[:x_seq_v1]),
	    xend = value.(model_seq_v1[:x_seq_v1])+tiempos_de_proceso,
	    id = ["a","b","c"]
	)
	ylabdict4 = Dict(i=>D4[!,:ylab][i] for i in 1:3)
	
	coord4 = Coord.cartesian(ymin=0.4, ymax=4.6)
	p4 = plot(D4, coord4,
	    layer(x=:x, xend=:xend, y=:y, yend=:y, color=:id, Geom.segment, Theme(line_width=10mm)), 
	    Scale.y_continuous(labels=i->get(ylabdict4,i,"")),
	    Guide.xlabel("Tiempo en días"), Guide.ylabel(""),
	    Theme(key_position=:none) 
	)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Gadfly = "c91e804a-d5a3-530f-b6f0-dfbca275c004"
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
DataFrames = "~1.3.4"
Gadfly = "~1.3.4"
HiGHS = "~1.1.4"
JuMP = "~1.3.0"
NamedArrays = "~0.9.6"
PlutoUI = "~0.7.40"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "a6f589a1268ce8499e9fdb63f7246abcdf4f0b0a"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "69f7020bd72f069c219b5e8c236c1fa90d2cb409"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.2.1"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "195c5505521008abea5aee4f96930717958eac6f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "4c10eee4af024676200bc7752e536f858c6b8f93"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.1"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.CategoricalArrays]]
deps = ["DataAPI", "Future", "Missings", "Printf", "Requires", "Statistics", "Unicode"]
git-tree-sha1 = "5f5a975d996026a8dd877c35fe26a7b8179c02ba"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.6"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "8a494fe0c4ae21047f28eb48ac968f0b8a6fcaa7"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.4"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "2e62a725210ce3c3c2e1a3080190e7ca491f18d7"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.7.2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

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
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "78bee250c6826e1cf805a88b7f1e86025275d208"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.46.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.Compose]]
deps = ["Base64", "Colors", "DataStructures", "Dates", "IterTools", "JSON", "LinearAlgebra", "Measures", "Printf", "Random", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "d853e57661ba3a57abcdaa201f4c9917a93487a2"
uuid = "a81c6b42-2e10-5240-aca2-a61377ecd94b"
version = "0.9.4"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[deps.CoupledFields]]
deps = ["LinearAlgebra", "Statistics", "StatsBase"]
git-tree-sha1 = "6c9671364c68c1158ac2524ac881536195b7e7bc"
uuid = "7ad07ef1-bdf2-5661-9d2b-286fd4296dac"
version = "0.2.0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "daa21eb85147f72e41f6352a57fccea377e310a9"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.4"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "992a23afdb109d0d2f8802a30cf5ae4b1fe7ea68"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.11.1"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "8579b5cdae93e55c0cff50fbb0c2d1220efd5beb"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.70"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "90630efff0894f8142308e334473eba54c433549"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.5.0"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "87519eb762f85534445f5cda35be12e32759ee14"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.4"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "187198a4ed8ccd7b5d99c41b69c679269ea2b2d4"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.32"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Gadfly]]
deps = ["Base64", "CategoricalArrays", "Colors", "Compose", "Contour", "CoupledFields", "DataAPI", "DataStructures", "Dates", "Distributions", "DocStringExtensions", "Hexagons", "IndirectArrays", "IterTools", "JSON", "Juno", "KernelDensity", "LinearAlgebra", "Loess", "Measures", "Printf", "REPL", "Random", "Requires", "Showoff", "Statistics"]
git-tree-sha1 = "13b402ae74c0558a83c02daa2f3314ddb2d515d3"
uuid = "c91e804a-d5a3-530f-b6f0-dfbca275c004"
version = "1.3.4"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.Hexagons]]
deps = ["Test"]
git-tree-sha1 = "de4a6f9e7c4710ced6838ca906f81905f7385fd6"
uuid = "a1b4810d-1bce-5fbd-ac56-80944d57a21f"
version = "0.2.0"

[[deps.HiGHS]]
deps = ["HiGHS_jll", "MathOptInterface", "SparseArrays"]
git-tree-sha1 = "dc1802d0710a6e685d4279d0d3e6ae5fe35203fe"
uuid = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
version = "1.1.4"

[[deps.HiGHS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b0bf110765a077880aab84876f9f0b8de0407561"
uuid = "8fd58aa0-07eb-5a78-9b36-339c94fd15ea"
version = "1.2.2+0"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions", "Test"]
git-tree-sha1 = "709d864e3ed6e3545230601f94e11ebc65994641"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.11"

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

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "64f138f9453a018c8f3562e7bae54edc059af249"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.4"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "b3364212fb5d870f724876ffcd34dd8ec6d98918"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.7"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

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
deps = ["LinearAlgebra", "MathOptInterface", "MutableArithmetics", "OrderedCollections", "Printf", "SparseArrays"]
git-tree-sha1 = "906e2325c22ba8aaed432677d0a8d5cf24c9ea9e"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.3.0"

[[deps.Juno]]
deps = ["Base64", "Logging", "Media", "Profile"]
git-tree-sha1 = "07cb43290a840908a771552911a6274bc6c072c7"
uuid = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
version = "0.8.4"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "9816b296736292a80b9a3200eb7fbb57aaa3917a"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.5"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

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

[[deps.Loess]]
deps = ["Distances", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "46efcea75c890e5d820e670516dc156689851722"
uuid = "4345ca2d-374a-55d4-8d30-97f9976e7612"
version = "0.5.4"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "94d9c52ca447e23eac0c0f074effbcd38830deb5"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.18"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "41d162ae9c868218b1f3fe78cba878aa348c2d26"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.1.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SparseArrays", "SpecialFunctions", "Test", "Unicode"]
git-tree-sha1 = "3256d773b0b807e478194c3e3451b8c5e27caf55"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.8.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[deps.Media]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "75a54abd10709c01f1b86b84ec225d26e840ed58"
uuid = "e89f7d12-3494-54d1-8411-f7d8b9ae1f27"
version = "0.5.0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "4e675d6e9ec02061800d6cfb695812becbd03cdf"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.0.4"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "a7c3d1da1189a1c2fe843a3bfa04d18d20eb3211"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.1"

[[deps.NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "2fd5787125d1a93fbe30961bd841707b8a80d75b"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.6"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "1ea784113a6aa054c5ebd95945fa5e52c2f378e7"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.7"

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

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "cf494dca75a69712a72b80bc48f59dcf3dea63ec"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.16"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "3d5bf43e3e8b412656404ed9466f1dcbf7c50269"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.4.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "a602d7b0babfca89005da04d89223b867b55319f"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.40"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "3c009334f45dfd546a16a57960a821a1a023d241"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.5.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "dc84268fe0e3335a62e315a3a7cf2afa7178a734"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.3"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "d75bda01f8c31ebb72df80a46c88b25d1c79c56d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.7"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "dfec37b90740e3b9aa5dc2613892a3fc155c3b42"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.6"

[[deps.StaticArraysCore]]
git-tree-sha1 = "ec2bd695e905a3c755b33026954b119ea17f2d22"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.3.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f9af7f195fb13589dd2e2d57fdb401717d2eb1f6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.5.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "5783b877201a82fc0014cbf381e7e6eb130473a4"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.0.1"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "8a75929dcd3c38611db2f8d08546decb514fcadf"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.9"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

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
# ╟─2773ada4-2d1a-11ed-0928-635c9c9cf446
# ╠═f6b07961-6a93-4ed0-8dfb-26d6e477acb1
# ╟─352b57ea-d6a3-4ee1-aed7-96761aebcec9
# ╟─45e25c69-c4fe-4b75-97e0-30133d4a6068
# ╟─0a9988f8-33d6-48f4-99f0-aaceb5a2bbe5
# ╟─b84a8d36-6494-494f-bf15-a71132483fbc
# ╟─e5fce636-ba6e-42c5-bc5b-920c993addb8
# ╟─56c619fc-a0f7-4e60-a79d-6e3f46c319ea
# ╟─9a9428c1-70c9-41f3-b7d6-f6c103025c6c
# ╟─266880d7-e07e-4a9b-b5e2-7fbcb41af18d
# ╟─9d039aa2-e1be-4576-b7ae-539468b414bd
# ╟─e5cef8ef-dd5e-4ca9-81f7-30c27def778b
# ╟─4986cc5a-74c0-417d-bb7a-12b2015ba9c6
# ╟─f0f70394-ea18-4035-9b12-18c3fc0f9a49
# ╟─394efbb1-cd1b-4afd-959c-1be90b976dcc
# ╟─980a4a5a-3291-4118-a4cb-6a47331f8fc5
# ╟─e351013b-15ad-452c-bea9-37674a104151
# ╟─abbe84b0-5fdd-447a-922f-651c73c52a8b
# ╟─cac89777-a9ad-437c-b7a4-358441196443
# ╟─d8d790a5-146f-4b66-8874-6cf1a00b1831
# ╟─b7bec7ea-4f30-4d29-a19c-445e500f511c
# ╟─6f86a91d-846a-4bb4-abf2-9fce800c4a94
# ╟─31e5229a-466e-4685-991b-98d3e015667a
# ╟─ec896c06-3d25-4cff-a3ba-d32023d8c9dc
# ╟─c4a59158-4e1b-46b1-ba5a-d19ff574419f
# ╟─f682c01a-061c-4a42-91bb-d49ff0ea2133
# ╟─efa74ed7-5fa2-4971-ac62-5a3fe3ad2ea1
# ╟─af65d4f7-611e-434e-b1b7-3d178cc39d41
# ╟─e090771f-ec0b-41ac-8124-10f2944716bf
# ╟─eab0dada-6102-4eae-9edf-604a94954356
# ╟─73b39859-329e-4a93-9f72-2f66157f76e4
# ╟─93f857f0-f801-4bc1-9dc5-3f414f437c3b
# ╟─4ee5f54c-67a5-4f32-8e76-efeb58a6f670
# ╟─ccc07fa6-7f42-4041-bfc3-a2bd51a9aa63
# ╟─70b0f876-ac36-489e-bf12-7fc8e87936f9
# ╟─21ca493f-b567-40fd-977a-be9f7d09318a
# ╟─316365f7-8809-40fe-93a5-e80f940dd3dd
# ╟─bad54d03-68a6-4db2-944b-970dcfb3f4e6
# ╟─59fccf56-d2c4-4ac8-a9ca-e14fb6b04bb5
# ╠═363eacb9-0397-46fc-b055-25a58d6ab2e2
# ╠═acb96eb5-350e-4ba1-95be-92a1661b631a
# ╠═11c5e0b0-5123-4567-9ec3-ed3f20d11e8a
# ╟─c9680511-0a39-428e-abe7-a9ee71283c99
# ╟─469aba47-46d5-4f06-afd5-ca97f06699ce
# ╟─58f3b012-50b6-4980-8c13-103a459d3530
# ╟─575eb7cc-65a9-43e4-9542-99d52d6420ad
# ╟─6685b640-5594-46c1-8ae2-3da63c84e40c
# ╟─462a156e-346d-4fda-8541-901528221ff8
# ╟─ebb010a4-0371-4b1d-b099-2b37b4b1af43
# ╟─ef7f853a-b65a-4cbf-8fd3-6a42864ffee1
# ╟─4feb0d74-323a-4947-9c71-7a8c3e43512c
# ╟─8bdce93a-6e93-419a-9bf8-96d3cb7a3f33
# ╟─edad701c-1053-4fca-bd57-4e7678705991
# ╟─17f89e05-d9a9-4e6a-9004-58291edb9091
# ╟─24bf6ad9-acb5-46dd-96fa-62de72a60e2a
# ╠═ce734804-5042-4f7d-bd9e-0e0c5927f409
# ╠═1e38449b-ce67-4735-b657-77be779ed9f6
# ╟─6952d3c6-6025-4d85-9c30-2f6b765ddbeb
# ╟─b4ed2864-3787-4385-92e7-d3fbee57793e
# ╟─763d5891-af27-43f6-a609-5bde19d8faf4
# ╟─c053d1d7-81cf-45bb-828d-70e7382367b7
# ╟─210e0dfa-7156-4151-a03f-d6eccde69750
# ╟─f33b6c83-8b07-4f46-b32d-79e10b60d868
# ╟─66a6ff12-135f-4381-8d16-bdca556df987
# ╟─3ba0cfa7-67a6-407a-b010-8333f1e2b896
# ╟─1b46024b-ae78-4b01-a0e2-8651531254ba
# ╟─4c4edd5b-891f-457d-8504-ba294a36be6d
# ╟─99c92994-6827-419a-a031-6e1973bece66
# ╠═fcc8f3ec-9762-45d8-a747-320e91ed7f9d
# ╠═3948ec58-287a-4a1f-9d72-81285a338b9f
# ╟─3f4f5c55-6d49-44f3-892e-748c8dc305ca
# ╟─c713db47-2b96-4fe0-9c56-6c860edb2221
# ╟─abf8d36b-788e-4915-bf1a-97f04175876f
# ╟─a8c705d1-6f8f-40aa-b22f-97a8781810cb
# ╟─593933e0-49f1-49eb-94f1-7c9999e35465
# ╟─6954e630-1a65-433f-a250-d735e4d6e4ca
# ╟─bfc7d52e-b778-4df7-b57c-8b4aeda745af
# ╟─b035d381-43ab-46d0-88fd-58d9031d755c
# ╟─25eb1e43-3626-4972-8341-9f8087d66e62
# ╟─0f9f48c7-6fc1-4b49-9905-150cd9421346
# ╟─e92e1e71-b547-4aea-b2a9-eb19814bcaf3
# ╠═580eaef4-bdd8-43e5-821c-3dc5c47451fa
# ╠═850480c9-7332-4501-baca-d479155f0606
# ╠═9cd041d2-9cdd-462b-a8a1-15c37198930d
# ╟─ab2ac035-0147-4dd1-ba21-c18ab03f5cb3
# ╠═4c30ddd8-a88d-48b4-886f-f520a4d0c0af
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ d0cf72e5-937d-4766-8057-30b351db6d15
# Cargo los paquetes a usar en el notebook y genero la tabla de contenidos
begin
	using Colors, ImageShow, FileIO, ImageIO
	using PlutoUI, JuMP, HiGHS, NamedArrays
	TableOfContents(title="Contenido")
end 

# ╔═╡ 66a4d642-1708-11ed-17fa-8bbdcb323664
md"# Algunas otras variedades de problemas de mochila"

# ╔═╡ dc3c5b19-b0f9-4aa7-89c4-8bbe1af5a074
md"## Bin Packing"

# ╔═╡ 97c98e87-220f-43e6-806d-1a5e46dbbee7
md"El problema del _bin-packing_ es una variación del problema de la mochila en el cual, en vez de tener una sola mochila, tenemos muchas. ¿Cual es la diferencia entonces con el problema de la multi-mochila? Bueno, a diferencia este último, en el problema del _bin-packing_ queremos guardar **todos** los items usando la menor cantidad de mochilas posibles. O sea, el foco pasa de estar puesto en maximizar el beneficio que me generan los items hacia minimizar la cantidad de contenedores necesarios. Veamos el problema 31 de la cartilla 1 de la unidad 4."

# ╔═╡ 4dacf844-94b6-4161-8dc2-c0494af93d56
md"
> Supongamos que tenemos 4 mochilas cuyas capacidades máximas son de 15 kg y 25 l, y deseamos guardar en ella estos objetos:

> * Objeto 1, de 1 kg y 1 l.
> * Objeto 2, de 2 kg y 5 l.
> * Objeto 3, de 4 kg y 4 l.
> * Objeto 4, de 6 kg y 2 l.
> * Objeto 5, de 8 kg y 3 l.
> * Objeto 6, de 12 kg y 6 l.
> * Objeto 7, de 14 kg y 8 l.

> ¿Cual es la cantidad mínima de mochilas que necesito para guardarlos a todos?

"

# ╔═╡ 5993d380-fffa-4717-8bd0-90594474efe2
md"### Formulación"

# ╔═╡ 61d0e082-943d-4b1e-94a6-3954473b6a3f
md"
Para formular el problema, necesitamos dos tipos de variables:

* _ $x_{i,j} \in \{0,1\}$: variable binaria que indica si guardamos el ítem $i$ en la mochila $j$. 
* _ $y_{j} \in \{0,1\}$: variable binaria que indica si usamos o no la mochila $j$. 


Con este esquema de variables, podemos armar una función objetivo que minimize la suma de todas las $y_{j}$, esto es, que minimize la cantidad de mochilas:

$Min \ Z=\sum_{j \in J}y_{j}$

Por otro lado, necesitamos forzar a que todos los items estén en, al menos, una mochila:

$\sum_{j \in J}x_{i,j} = 1, \forall i \in I$

Y necesitamos vincular las variables $x_{i,j}$ y $y_{j}$, es decir, declarar que solo se pueden guardar cosas en una mochila si esta mochila se decide usar. Para ello, usando $M$ (es decir, un número muy grande):

$\sum_{i \in I}x_{i,j} \leq M \cdot y_{j}, \forall j \in J$

La formulación completa queda como:

$Min \ Z=\sum_{j \in J}y_{j}$

Sujeto a:

$\sum_{i \in I}peso_{i} \cdot x_{i,j} \leq capacidadKgMochila_{j}, \forall j \in J$

$\sum_{i \in I}volumen_{i} \cdot x_{i,j} \leq capacidadLitrosMochila_{j}, \forall j \in J$

$\sum_{j \in J}x_{i,j} = 1, \forall i \in I$

$\sum_{i \in I}x_{i,j} \leq M \cdot y_{j}, \forall j \in J$

$x_{i,j} \in \{0,1\}$

$y_{j} \in \{0,1\}$

"

# ╔═╡ 44461150-e4bd-42fd-ba1d-8d97577ab7c7
md"A efectos de claridad, lo vamos a modelar de esta forma. Pero, si se fijan, la restricción de vinculación de $x_{i,j}$ con $y_{j}$ se podría haber definido en las restricciones de capacidad:

$Min \ Z=\sum_{j \in J}y_{j}$

Sujeto a:

$\sum_{i \in I}peso_{i} \cdot x_{i,j} \leq capacidadKgMochila_{j} \cdot y_{j}, \forall j \in J$

$\sum_{i \in I}volumen_{i} \cdot x_{i,j} \leq capacidadLitrosMochila_{j} \cdot y_{j}, \forall j \in J$

$\sum_{j \in J}x_{i,j} = 1, \forall i \in I$

$x_{i,j} \in \{0,1\}$

$y_{j} \in \{0,1\}$

"

# ╔═╡ 3a009865-8072-4548-b9ee-1ddb66b5bd68
md"### Resolución"

# ╔═╡ 14ffef1b-017a-40c2-9386-40d0e1e707f9
begin
	model_bin_packing = Model(HiGHS.Optimizer) #

	# Dimensiones
	objetos_bp = ["obj1", "obj2", "obj3", "obj4", "obj5", "obj6", "obj7"]
	mochilas_bp = ["mochila1", "mochila2", "mochila3", "mochila4", "mochila5"]
	tipos_capacidades_bp = ["peso", "volumen"]
	M_bp = length(objetos_bp)
	
	#Datos
	pesos_bp = NamedArray([[1 2 4 6 8 12 14]
			                [1 5 4 2 3 6  8]], (tipos_capacidades_bp, objetos_bp)) 
	capacidad_mochila_bp = NamedArray([[15 15 15 15 15]
			                            [25 25 25 25 25]], 
		                               (tipos_capacidades_bp, mochilas_bp))
	
	# Declaro las variables de decisión.
	x_bp = @variable(model_bin_packing, x_bp[objetos_bp, mochilas_bp], Bin)
	y_bp = @variable(model_bin_packing, y_bp[mochilas_bp], Bin)

	# Creo la función objetivo. 
	obj_bp = @objective(model_bin_packing, Min,
		sum([y_bp[j] for j in mochilas_bp]))

	# Cargo las restricciones de capacidad máxima.
	r1_bp = @constraint(model_bin_packing, [j in mochilas_bp, c in tipos_capacidades_bp], sum([pesos_bp[c,i] * x_bp[i,j] for i in objetos_bp]) <= capacidad_mochila_bp[c,j])

	# Cargo las restricciones de un objeto en una sola mochila.
	r2_bp = @constraint(model_bin_packing, [i in objetos_bp], sum([x_bp[i,j] for j in mochilas_bp]) == 1)
	
	# Vinculamos X e Y.
	r3_bp = @constraint(model_bin_packing, [j in mochilas_bp], sum([x_bp[i,j] for i in objetos_bp]) <= M_bp * y_bp[j])
	
	latex_formulation(model_bin_packing)
end

# ╔═╡ c43b95ea-807f-472a-a283-84399354af97
begin
	optimize!(model_bin_packing)
	
	@show solution_summary(model_bin_packing, verbose=true)
end

# ╔═╡ c926ff69-04f8-4850-9485-ab0eb3c02f60
md"## Mochilas con costos fijos"

# ╔═╡ 0714215e-cb0d-49ee-af3e-fed5ce8773a2
md"El problema de mochilas con costos fijos es muy similar al anterior. Veamos el problema 30 de la cartilla 1 de la unidad:

> Supongamos que tenemos 2 mochilas cuyas capacidades máximas son de 12 kg y 20 l y 8 kg y 15 l, respectivamente. Deseamos guardar en ella estos objetos:

> * Objeto 1, de 1 kg y 1 l, que aporta un beneficio de 2.
> * Objeto 2, de 2 kg y 5 l, que aporta un beneficio de 3.
> * Objeto 3, de 4 kg y 4 l, que aporta un beneficio de 4.
> * Objeto 4, de 6 kg y 2 l, que aporta un beneficio de 7.
> * Objeto 5, de 8 kg y 3 l, que aporta un beneficio de 6.
> * Objeto 6, de 12 kg y 6 l, que aporta un beneficio de 8.
> * Objeto 7, de 14 kg y 8 l, que aporta un beneficio de 9.

> Para usar cada mochila, tenemos que pagar un costo fijo de alquiler. El mismo es de 20 por la mochila de mayor capacidad y 5 por la de menor capacidad, independientemente de cuantos artículos guardemos en cada una de ellas.

> Queremos maximizar el beneficio total. ¿Cual es la asignación óptima?

El problema es bastante similar a los problemas en los que veníamos trabajando. La diferencia radica en que el beneficio ya no depende solamente de los objetos que carguemos en la mochila, sinó de la decisión de usar cada mochila o no. Si usamos la mochila 1, el beneficio disminuye en 20, si usamos la mochila 2, en 5, y si usamos las dos, en 25.

"

# ╔═╡ 0f241b39-5a52-4f3b-861f-ffd8586f5ae7
md"### Formulación"

# ╔═╡ 163d5054-2d8f-4fcd-acb1-5ded7475e3e4
md"Modelar este problema requiere adaptar el modelado que usamos para el problema del _bin-packing_. Ya no es obligatorio cargar todos los bienes, por lo cual la restricción:

$\sum_{j \in J}x_{i,j} = 1, \forall i \in I$

se transforma en:

$\sum_{j \in J}x_{i,j} \leq 1, \forall i \in I$

Por otro lado, la función objetivo vuelve a ser una función de maximización de beneficios, salvo que aquí el beneficio depende tanto de las $x_{i,j}$ como de las $y_{j}$:

$Max \ Z=\sum_{i \in I}\sum_{j \in J}beneficio_{i} \cdot x_{i,j} - \sum_{j \in J}costoFijo_{j} \cdot y_{j}$

La formulación completa queda como:

$Max \ Z=\sum_{i \in I}\sum_{j \in J}beneficio_{i} \cdot x_{i,j} - \sum_{j \in J}costoFijo_{j} \cdot y_{j}$

Sujeto a:

$\sum_{i \in I}peso_{i} \cdot x_{i,j} \leq capacidadKgMochila_{j}, \forall j \in J$

$\sum_{i \in I}volumen_{i} \cdot x_{i,j} \leq capacidadLitrosMochila_{j}, \forall j \in J$

$\sum_{j \in J}x_{i,j} \leq 1, \forall i \in I$

$\sum_{i \in I}x_{i,j} \leq M \cdot y_{j}, \forall j \in J$

$x_{i,j} \in \{0,1\}$

$y_{j} \in \{0,1\}$

"

# ╔═╡ 18e2dcbd-0849-4170-b525-8eb156eb4db3
md"### Resolución"

# ╔═╡ 6fff1e0d-8ec0-444e-aa4a-d6fe027b43b9
begin
	model_mochila_costo_fijo = Model(HiGHS.Optimizer) #

	# Dimensiones
	objetos_mcf = ["obj1", "obj2", "obj3", "obj4", "obj5", "obj6", "obj7"]
	mochilas_mcf = ["mochila1", "mochila2"]
	tipos_capacidades_mcf = ["peso", "volumen"]
	M_mcf = length(objetos_mcf)
	
	#Datos
	beneficios_mcf = NamedArray([2; 3; 4; 7; 6; 8; 9], objetos_mcf) 
	costos_fijos_mcf = NamedArray([20; 5], mochilas_mcf) 
	pesos_mcf = NamedArray([[1 2 4 6 8 12 14]
			                [1 5 4 2 3 6  8]], (tipos_capacidades_mcf, objetos_mcf)) 
	capacidad_mochila_mcf = NamedArray([[15 8]
			                            [20 15]], 
		                               (tipos_capacidades_mcf, mochilas_mcf))
	
	# Declaro las variables de decisión.
	x_mcf = @variable(model_mochila_costo_fijo, x_mcf[objetos_mcf, mochilas_mcf], Bin)
	y_mcf = @variable(model_mochila_costo_fijo, y_mcf[mochilas_mcf], Bin)

	# Creo la función objetivo. 
	obj_mcf = @objective(model_mochila_costo_fijo, Max,
		sum([beneficios_mcf[i] * x_mcf[i,j] for i in objetos_mcf for j in mochilas_mcf]) - sum([costos_fijos_mcf[j] * y_mcf[j] for j in mochilas_mcf]))

	# Cargo las restricciones de capacidad máxima.
	r1_mcf = @constraint(model_mochila_costo_fijo, [j in mochilas_mcf, c in tipos_capacidades_mcf], sum([pesos_mcf[c,i] * x_mcf[i,j] for i in objetos_mcf]) <= capacidad_mochila_mcf[c,j])

	# Cargo las restricciones de un objeto en una sola mochila.
	r2_mcf = @constraint(model_mochila_costo_fijo, [i in objetos_mcf], sum([x_mcf[i,j] for j in mochilas_mcf]) <= 1)
	
	# Vinculamos X e Y.
	r3_mcf = @constraint(model_mochila_costo_fijo, [j in mochilas_mcf], sum([x_mcf[i,j] for i in objetos_mcf]) <= M_mcf * y_mcf[j])
	
	latex_formulation(model_mochila_costo_fijo)
end

# ╔═╡ 9f5a43cc-550c-4e3b-9f1b-53e6776cbef3
begin
	optimize!(model_mochila_costo_fijo)
	
	@show solution_summary(model_mochila_costo_fijo, verbose=true)
end

# ╔═╡ 8acf3a98-e88a-42f6-8e9c-74a32ebbbdba
md"## Maximización de las cantidades a guardar consumiendo toda la capacidad"

# ╔═╡ ac918e4e-c3b6-4de7-88ef-b10a7cd41b0d
load("np_complete_in_restaurant.png")

# ╔═╡ 5078f2e5-d82e-4e49-85f1-0e7353952c82
md"Fuente: [https://xkcd.com/287/](https://xkcd.com/287/)"

# ╔═╡ 54460234-0df4-4786-ae22-d3c52f672e3e
md"Queremos seleccionar la mayor cantidad posible de _appetizers_ asegurándonos de gastar exactamente \$15,05. Conceptualmente, es un variedad de problema de mochila, en el cual la mochila es el presupuesto disponible, la capacidad se debe consumir al 100%, y el beneficio de cada elemento es _1_." 

# ╔═╡ 88955653-7eb9-42d7-8c0a-6b647187c29f
md"### Resolución"

# ╔═╡ 459fe527-588f-4868-a222-4604c38f8003
begin
	model_xkcd = Model(HiGHS.Optimizer) #

	# Dimensiones
	objetos_xkcd = ["Mixed Fruit", "French Fries", "Side Salad", "Hot Wings", "Mozzarella Sticks", "Sampler Plate"]
	dinero_disponible_xkcd = 15.05
	
	#Datos
	costos_xkcd = NamedArray([2.15;2.75;3.35;3.55;4.20;5.80], (objetos_xkcd)) 
	
	# Declaro las variables de decisión.
	x_xkcd = @variable(model_xkcd, x_xkcd[objetos_xkcd], Bin)


	# Creo la función objetivo. 
	obj_xkcd = @objective(model_xkcd, Max,
		sum([x_xkcd[i] for i in objetos_xkcd]))

	# Cargo la restricción de capacidad.
	r1_xkcd = @constraint(model_xkcd, sum([costos_xkcd[i] * x_xkcd[i] for i in objetos_xkcd]) == dinero_disponible_xkcd)

	
	latex_formulation(model_xkcd)
end

# ╔═╡ caebb6d5-2866-42bd-a703-7262f7c3a1c1
begin
	optimize!(model_xkcd)
	
	@show solution_summary(model_xkcd, verbose=true)
	
end

# ╔═╡ f469aa4f-962e-434e-94a0-f42cb238ef38
md"Mmmmm, un error. Pero es raro, venimos haciendo lo mismo que siempre, ¿no? Hagamos un check al resultado de la optimización."

# ╔═╡ 9ef209ad-592f-4802-9954-e6e0dfae7203
@show termination_status(model_xkcd)

# ╔═╡ 466d910e-a1a7-4262-bd2d-aca37d6d7865
md"Ajá, es infactible el modelo. Entonces, cuando quiere calcular el resumen, no tiene valores para las varibles. La infactibilidad vienen dada porque la restricción es muy estricta. ¿Que pasa si la relajamos a gastar el dinero disponible o menos?"

# ╔═╡ 4457fd86-a6fd-43dd-9af8-12c8c50c068e
begin
	model_xkcd2 = Model(HiGHS.Optimizer) #

	# Dimensiones
	objetos_xkcd2 = ["Mixed Fruit", "French Fries", "Side Salad", "Hot Wings", "Mozzarella Sticks", "Sampler Plate"]
	dinero_disponible_xkcd2 = 15.05
	
	#Datos
	costos_xkcd2 = NamedArray([2.15;2.75;3.35;3.55;4.20;5.80], (objetos_xkcd2)) 
	
	# Declaro las variables de decisión.
	x_xkcd2 = @variable(model_xkcd2, x_xkcd2[objetos_xkcd2], Bin)


	# Creo la función objetivo. 
	obj_xkcd2 = @objective(model_xkcd2, Max,
		sum([x_xkcd2[i] for i in objetos_xkcd2]))

	# Cargo la restricción de capacidad.
	r1_xkcd2 = @constraint(model_xkcd2, sum([costos_xkcd2[i] * x_xkcd2[i] for i in objetos_xkcd2]) <= dinero_disponible_xkcd2)

	
	latex_formulation(model_xkcd2)
end

# ╔═╡ bae4e507-724c-481f-ac4f-ee3329b4e61b
begin
	optimize!(model_xkcd2)
	
	@show solution_summary(model_xkcd2, verbose=true)
end

# ╔═╡ 2ffd5369-8967-4926-808a-423ccbe1fa14
md"Ahora es factible, ¿pero cuanta plata gastamos?"

# ╔═╡ 05325a53-7de1-4a9c-ba4f-a44af7b96233
@show value(r1_xkcd2) #A value le puedo pasar variables, restricciones o funciones objetivo. En este caso, paso a variable que almacena la restricción del gasto y me devuelve el lado izquierdo (luego de pasar todas las variables a la izquierda).

# ╔═╡ e507735f-e443-40e6-92ee-291ccfcb4472
md"Entonces, lo máximo que podemos comprar son 4 _appetizers_, gastando \$11,80."

# ╔═╡ Cell order:
# ╟─66a4d642-1708-11ed-17fa-8bbdcb323664
# ╠═d0cf72e5-937d-4766-8057-30b351db6d15
# ╠═dc3c5b19-b0f9-4aa7-89c4-8bbe1af5a074
# ╟─97c98e87-220f-43e6-806d-1a5e46dbbee7
# ╟─4dacf844-94b6-4161-8dc2-c0494af93d56
# ╟─5993d380-fffa-4717-8bd0-90594474efe2
# ╟─61d0e082-943d-4b1e-94a6-3954473b6a3f
# ╟─44461150-e4bd-42fd-ba1d-8d97577ab7c7
# ╟─3a009865-8072-4548-b9ee-1ddb66b5bd68
# ╠═14ffef1b-017a-40c2-9386-40d0e1e707f9
# ╠═c43b95ea-807f-472a-a283-84399354af97
# ╟─c926ff69-04f8-4850-9485-ab0eb3c02f60
# ╟─0714215e-cb0d-49ee-af3e-fed5ce8773a2
# ╟─0f241b39-5a52-4f3b-861f-ffd8586f5ae7
# ╟─163d5054-2d8f-4fcd-acb1-5ded7475e3e4
# ╟─18e2dcbd-0849-4170-b525-8eb156eb4db3
# ╠═6fff1e0d-8ec0-444e-aa4a-d6fe027b43b9
# ╠═9f5a43cc-550c-4e3b-9f1b-53e6776cbef3
# ╟─8acf3a98-e88a-42f6-8e9c-74a32ebbbdba
# ╟─ac918e4e-c3b6-4de7-88ef-b10a7cd41b0d
# ╟─5078f2e5-d82e-4e49-85f1-0e7353952c82
# ╟─54460234-0df4-4786-ae22-d3c52f672e3e
# ╟─88955653-7eb9-42d7-8c0a-6b647187c29f
# ╠═459fe527-588f-4868-a222-4604c38f8003
# ╠═caebb6d5-2866-42bd-a703-7262f7c3a1c1
# ╟─f469aa4f-962e-434e-94a0-f42cb238ef38
# ╠═9ef209ad-592f-4802-9954-e6e0dfae7203
# ╟─466d910e-a1a7-4262-bd2d-aca37d6d7865
# ╠═4457fd86-a6fd-43dd-9af8-12c8c50c068e
# ╠═bae4e507-724c-481f-ac4f-ee3329b4e61b
# ╟─2ffd5369-8967-4926-808a-423ccbe1fa14
# ╠═05325a53-7de1-4a9c-ba4f-a44af7b96233
# ╟─e507735f-e443-40e6-92ee-291ccfcb4472

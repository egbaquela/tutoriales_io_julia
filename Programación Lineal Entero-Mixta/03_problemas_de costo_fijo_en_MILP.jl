### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ b5e9f4be-4b20-4193-a6ac-f76ee9966b40
# Cargo los paquetes a usar en el notebook y genero la tabla de contenidos
begin
	using PlutoUI, JuMP, HiGHS, NamedArrays
	TableOfContents(title="Contenido")
end 

# ╔═╡ c4f7c3e7-9963-45de-b29e-d4dad33c5cda
md"# Problemas de costo fijo en MILP"

# ╔═╡ e6eeb994-a377-4d02-ab91-39f921eaac4a
md"## Planificación de la producción"

# ╔═╡ cdf6e13b-5c99-47eb-8f78-e65df94d987a
md"### Problema con múltiples tipos de capacidades"

# ╔═╡ 3a2fde91-76bd-4ecc-b9bb-e5a873160806
md"El problema 1 de la cartilla 1 es un problema de planificación de la producción donde el producto no se puede fraccionar (variables enteras). Sin embargo, esta no es la única diferencia con lo que veníamos viendo, puesto que tenemos costos fijos por decidir hacer 1 o más de cada producto."

# ╔═╡ 6890eecf-f2d5-48b0-9bc9-b3bd1af6e44d
md"
| Producto | Horas MO | C1 | C2 | Precio | Costo |
|:-:|:-:|:-:|:-:|:-:|:-:|
| **P1** | 3 | 5 | 1 | 12 | 6 |
| **P2** | 2 | 3,5 | 2 | 8 | 4 |
| **P3** | 6 | 4,5 | 5 | 18 | 7 |
| **P4** | 4 | 3 | 3 | 15 | 9 |
"

# ╔═╡ 800e53d8-4d7b-4f92-93b7-8ada35cae84a
md"Los costos fijos son de $200, $150, $100 y $125, para P1, P2, P3 y P4, respectivamente. Además, se dispone de 180 horas, 200 unidades de C1 y 170 unidades de C2."

# ╔═╡ 603154d4-b8e8-40d9-9ae5-a1d8321a37bc
md"### Formulación"

# ╔═╡ 22e6886f-aa89-4baa-9dce-2a999f475239
md"
Para formular el problema, necesitamos dos tipos de variables:

* _ $x_{i} \in \mathbb Z$ : variable entera que indica cuánto producimos del producto $i$. 
* _ $y_{i} \in \{0,1\}$ : variable binaria que indica si producimos o no el producto $i$ (otra forma de pensarla es si alquilamos o no el equipo para producir el producto $i$). 


Con este esquema de variables, podemos armar una función objetivo que maximice la contribución marginal total (contribución marginal unitaria del producto por cantidad producida de cada producto) menos el costo fijo por el alquiler del equipo si hago un producto que lo requiera:

$Max \ Z=\sum_{i \in I}x_{i} \cdot cMg_{i}-y_{i} \cdot cf_{i}$

Además, se deben cumplir las restricciones de capacidad para las HH, C1 y C2:

$\sum_{i \in I}StdHH_{i} \cdot x_{i} \leq HH_{max}$

$\sum_{i \in I}StdC1_{i} \cdot x_{i} \leq C1_{max}$

$\sum_{i \in I}StdC2_{i} \cdot x_{i} \leq C2_{max}$

Y necesitamos vincular las variables $x_{i}$ y $y_{i}$, es decir, declarar que solo se pueden producir los productos si se alquila el equipo correspondiente. Para ello, una opción es darle un tope individual a cada variable según sus estándares:

$StdHH_{i} \cdot x_{i} \leq HH_{max} \cdot y_{i}, \forall i \in I$

$StdC1_{i} \cdot x_{i} \leq C1_{max} \cdot y_{i}, \forall i \in I$

$StdC2_{i} \cdot x_{i} \leq C2_{max} \cdot y_{i}, \forall i \in I$

Nota: Otra opción sería utilizar un número $M$ muy grande y no haría falta hacer un tipo de restricción por cada tipo de capacidad.

Finalmente, se debe asegurar la no negatividad de las variables $x_{i}$, ya que pertenecen al conjunto de los enteros:

$x_{i} \geq 0, \forall i \in I$

La formulación completa queda como:

$Max \ Z=\sum_{i \in I}x_{i} \cdot cMg_{i}-y_{i} \cdot cf_{i}$

Sujeto a:

$\sum_{i \in I}StdHH_{i} \cdot x_{i} \leq HH_{max}$

$\sum_{i \in I}StdC1_{i} \cdot x_{i} \leq C1_{max}$

$\sum_{i \in I}StdC2_{i} \cdot x_{i} \leq C2_{max}$

$StdHH_{i} \cdot x_{i} \leq HH_{max} \cdot y_{i}, \forall i \in I$

$StdC1_{i} \cdot x_{i} \leq C1_{max} \cdot y_{i}, \forall i \in I$

$StdC2_{i} \cdot x_{i} \leq C2_{max} \cdot y_{i}, \forall i \in I$

$x_{i} \geq 0, \forall i \in I$


$x_{i} \in \mathbb Z$ 

$y_{i} \in \{0,1 \}$ 

"

# ╔═╡ 9a7c3d61-2b49-4a29-a22b-69064bee5265
md"### Resolución"

# ╔═╡ 3d895d32-5c01-491d-b4a0-c848f2f446a9
md"#### Opción 1"

# ╔═╡ 173fab15-2812-4637-9fd0-5277ddcef3a3
md"#### Opción 2"

# ╔═╡ 3e5ce343-4d42-4bbb-b2b3-60b9b3147881
begin
	model_01 = Model(HiGHS.Optimizer) #

	# Dimensiones
	productos_01 = []
	num_prod_01 = 4
	for i in 1:num_prod_01
		push!(productos_01, string("P",i)) 
	end
	recursos_01 = ["HH", "C1", "C2"]
	
	# Datos
	precios_01 = NamedArray([12, 8, 18, 15], productos_01)
	costos_01 = NamedArray([6, 4, 7, 9], productos_01)
	cMg_01 = precios_01-costos_01
	
	estandar_01 = NamedArray([[3 2 6 4]
							[5 3.5 4.5 3]
							[1 2 5 3]], (recursos_01,productos_01))
	
	capMax_01 = NamedArray([180, 200, 170], recursos_01)

	cf_01 = NamedArray([200, 150, 100, 125], productos_01)

	# Declaro las variables de decisión.
	x_01 = @variable(model_01, x_01[productos_01], Int)
	y_01 = @variable(model_01, y_01[productos_01], Bin)
	
	#Función objetivo
	obj_01 = @objective(model_01, Max,
		sum([cMg_01[j]*x_01[j] for j in productos_01])-sum([cf_01[j]*y_01[j] for j in productos_01]))

	# Restriccion de capacidad por no usar un producto.
	r_01 = @constraint(model_01, [j in productos_01, i in recursos_01], estandar_01[i,j]*x_01[j] <= capMax_01[i] * y_01[j])
	
	# Restriccion de capacidad por recurso
	r2_01  = @constraint(model_01, [i in recursos_01], sum([estandar_01[i,j]*x_01[j] for j in productos_01])<= capMax_01[i])
	
	
	# No negatividad
	r3_01  = @constraint(model_01, [j in productos_01], x_01[j]>= 0)
	
	latex_formulation(model_01)
end

# ╔═╡ 0bdb8c87-4f6c-401f-a633-470f77810ac5
begin
	model_01_01 = Model(HiGHS.Optimizer) #

	# Dimensiones
	productos_01_01 = []
	num_prod_01_01 = 4
	for i in 1:num_prod_01_01
		push!(productos_01_01, string("P",i)) 
	end
	recursos_01_01 = ["HH", "C1", "C2"]
	
	# Datos
	precios_01_01 = NamedArray([12, 8, 18, 15], productos_01_01)
	costos_01_01 = NamedArray([6, 4, 7, 9], productos_01_01)
	cMg_01_01 = precios_01_01-costos_01_01
	
	estandar_01_01 = NamedArray([[3 2 6 4]
							[5 3.5 4.5 3]
							[1 2 5 3]], (recursos_01_01,productos_01_01))
	
	capMax_01_01 = NamedArray([180, 200, 170], recursos_01_01)

	cf_01_01 = NamedArray([200, 150, 100, 125], productos_01_01)

	# Declaro las variables de decisión.
	x_01_01 = @variable(model_01_01, x_01_01[productos_01_01], Int)
	y_01_01 = @variable(model_01_01, y_01_01[productos_01_01], Bin)
	
	#Función objetivo
	obj_01_01 = @objective(model_01_01, Max,
		sum([cMg_01_01[i]*x_01_01[i] for i in productos_01_01])-sum([cf_01_01[i]*y_01_01[i] for i in productos_01_01]))

	# Restriccion de capacidad por no usar un producto.
	# Esto genera para todo i:
	# 3*x_01_01[i]<=180*y_01_01[i]
	# 2*x_01_01[i]<=180*y_01_01[i]
	# 6*x_01_01[i]<=180*y_01_01[i]
	# 4*x_01_01[i]<=180*y_01_01[i]
	rHH_01_01 = @constraint(model_01_01, [i in productos_01], estandar_01_01["HH",i]*x_01_01[i] <= capMax_01_01["HH"] * y_01_01[i])

	# Esto genera para todo i:
	# 5*x_01_01[i]<=200*y_01_01[i]
	# 3.5*x_01_01[i]<=200*y_01_01[i]
	# 4.5*x_01_01[i]<=200*y_01_01[i]
	# 3*x_01_01[i]<=200*y_01_01[i]
	rC1_01_01 = @constraint(model_01_01, [i in productos_01], estandar_01_01["C1",i]*x_01_01[i] <= capMax_01_01["C1"] * y_01_01[i])

	# Esto genera para todo i:
	# 1*x_01_01[i]<=170*y_01_01[i]
	# 2*x_01_01[i]<=170*y_01_01[i]
	# 5*x_01_01[i]<=170*y_01_01[i]
	# 3*x_01_01[i]<=170*y_01_01[i]
	rC2_01_01 = @constraint(model_01_01, [i in productos_01], estandar_01_01["C2",i]*x_01_01[i] <= capMax_01_01["C2"] * y_01_01[i])
	
	# Restriccion de capacidad por recurso
	r2_01_01  = @constraint(model_01_01, [i in recursos_01_01], sum([estandar_01_01[i,j]*x_01_01[j] for j in productos_01_01])<= capMax_01_01[i])
	
	# No negatividad
	r3_01_01  = @constraint(model_01_01, [j in productos_01_01], x_01_01[j]>= 0)
	
	latex_formulation(model_01_01)
end

# ╔═╡ 2341525f-8ebd-44d3-ad1e-143779fdb5e5
begin
	optimize!(model_01_01)
	
	@show solution_summary(model_01_01, verbose=true)
end

# ╔═╡ a51ca19f-edf2-4774-b620-5711189e34bc
begin
	optimize!(model_01)
	
	@show solution_summary(model_01, verbose=true)
end

# ╔═╡ c7d90d15-c601-4e8e-9cb9-a060a54b22e5
md"### Planificación de la producción con múltiples plantas"

# ╔═╡ ce65ce29-7c01-47e0-aa52-85c2e7afdc1d
md"El problema 2 de la cartilla 1 es un problema muy similar al problema 1; la diferencia radica en que tenemos más de una planta."

# ╔═╡ 6902ff90-bac2-4ec3-87c1-b4d297588f01
md"
|  | P1 | P2 | P3 | P4 | P5 |
|:-:|:-:|:-:|:-:|:-:|:-:|
| **Hs/unidad en planta 1** | 3 | 3,5 | 5 | 2,5 | 2 |
| **Hs/unidad en planta 2** | 2,8 | 4 | 4,5 | 3 | 2,2 |
| **Costo/unidad en planta 1** | 3 | 2,5 | 4,8 | 2,7 | 2,1 |
| **Costo/unidad en planta 2** | 2,6 | 2,2 | 4,9 | 2,3 | 3 |
| **Costo lanzamiento** | 600 | 500 | 700 | 400 | 500 |
| **Precio de venta** | 6,7 | 7,2 | 8,8 | 6 | 4,7 |
"

# ╔═╡ 9ec516f5-4f5f-4307-85e3-e4d051596497
md"La capacidad disponible en la planta 1 es de 2700 horas y, en la planta 2, de 3000 horas."

# ╔═╡ 10d3cfa9-23c8-4471-8698-730ba9b76939
md"### Formulación"

# ╔═╡ dbf6471b-1398-4808-94a2-81ee74a5ab13
md"
Para formular el problema, necesitamos dos tipos de variables:

* _ $x_{i,j} \in \mathbb Z$ : variable entera que indica cuánto producimos del producto $i$ en la planta $j$. 
* _ $y_{i,j} \in \{0,1\}$ : variable binaria que indica si producimos o no el producto $i$ en la planta $j$ (otra forma de pensarla es si lanzamos o no el producto $i$ en la planta $j$). 


Con este esquema de variables, podemos armar una función objetivo que maximice la contribución marginal total (contribución marginal unitaria del producto $i$ en la planta $j$ por cantidad producida de cada producto en la planta correspondiente) menos el costo fijo por lanzar el producto en la planta si hago al menos un producto en la planta:

$Max \ Z= \sum_{j \in J} \sum_{i \in I}x_{i,j} \cdot cMg_{i,j}-y_{i,j} \cdot cf_{i}$

Además, se deben cumplir las restricciones de capacidad disponible:

$\sum_{i \in I}StdHH_{i,j} \cdot x_{i,j} \leq HHociosas_{j}, \forall j \in J$

Y necesitamos vincular las variables $x_{i,j}$ y $y_{i,j}$, es decir, declarar que solo se pueden producir los productos si se lanzan en la planta. Para ello, una opción es utilizar un número $M$ muy grande de esta forma:

$x_{i,j} \leq M \cdot y_{i,j}, \forall i \in I, \forall j \in J$

Finalmente, se debe asegurar la no negatividad de las variables $x_{i,j}$, ya que pertenecen al conjunto de los enteros:

$x_{i,j} \geq 0, \forall i \in I, j \in J$

La formulación completa queda como:

$Max \ Z=\sum_{i \in I}x_{i,j} \cdot cMg_{i,j}-y_{i,j} \cdot cf_{i}$

Sujeto a:

$\sum_{i \in I}StdHH_{i,j} \cdot x_{i,j} \leq HHociosas_{j}, \forall j \in J$

$x_{i,j} \leq M \cdot y_{i,j}, \forall i \in I, \forall j \in J$

$x_{i,j} \geq 0, \forall i \in I, j \in J$

$x_{i,j} \in \mathbb Z$ 

$y_{i,j} \in \{0,1 \}$ 

"

# ╔═╡ 487bb70b-e237-4daa-bb90-84f8ab3ec9fc
md"### Resolución"

# ╔═╡ 24e53519-12ba-438c-b050-87eaf59f0976
begin
	model_02 = Model(HiGHS.Optimizer) #

	# Dimensiones
	productos_02 = []
	num_prod_02 = 5
	for i in 1:num_prod_02
		push!(productos_02, string("P",i)) 
	end
	num_plantas_02 = 2
	
	plantas_02 = []
	for i in 1:num_plantas_02
		push!(plantas_02, string("Planta",i)) 
	end
	
	# Datos
	precios_02 = NamedArray([[6.7 7.2 8.8 6 4.7]
							 [6.7 7.2 8.8 6 4.7]], (plantas_02,productos_02))
	costos_02 = NamedArray([[3 2.5 4.8 2.7 2.1]
							[2.6 2.2 4.9 2.3 3]], (plantas_02,productos_02))
	cMg_02 = precios_02-costos_02
	
	estandar_02 = NamedArray([[3 3.5 5 2.5 2]
							  [2.8 4 4.5 3 2.2]], (plantas_02,productos_02))
	
	capMax_02 = NamedArray([2700, 3000], plantas_02)

	cf_02 = NamedArray([600, 500, 700, 400, 500], productos_02)

	M = 200000
	# Declaro las variables de decisión.
	x_02 = @variable(model_02, x_02[productos_02,plantas_02], Int)
	y_02 = @variable(model_02, y_02[productos_02,plantas_02], Bin)
	
	#Función objetivo
	obj_02 = @objective(model_02, Max,
		sum([cMg_02[j,i]*x_02[i,j] for i in productos_02 for j in plantas_02])-sum([cf_02[i]*y_02[i,j] for i in productos_02 for j in plantas_02]) )
	
	# Restriccion de capacidad.
	r_02 = @constraint(model_02, [j in plantas_02], sum([estandar_02[j,i]*x_02[i,j] for i in productos_02]) <= capMax_02[j])
	
	# Vinculo entre x e y
	r2_02  = @constraint(model_02, [i in productos_02, j in plantas_02], x_02[i,j]<= M*y_02[i,j])

	# No negatividad
	r3_02  = @constraint(model_02, [i in productos_02, j in plantas_02], x_02[i,j]>= 0)
	latex_formulation(model_02)
end

# ╔═╡ 74baaf6a-39b3-4f56-b8be-f0608f48b451
begin
	optimize!(model_02)
	
	@show solution_summary(model_02, verbose=true)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
HiGHS = "~1.1.4"
JuMP = "~1.1.1"
NamedArrays = "~0.9.6"
PlutoUI = "~0.7.39"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.3"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

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

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "80ca332f6dcb2508adba68f22f551adb2d00a624"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.3"

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
git-tree-sha1 = "924cdca592bc16f14d2f7006754a621735280b74"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.1.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

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
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "28d605d9a0ac17118fe2c5e9ce0fbb76c3ceb120"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.11.0"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "5158c2b41018c5f7eb1470d558127ac274eca0c9"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.1"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "425e126d13023600ebdecd4cf037f96e396187dd"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.31"

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
deps = ["Calculus", "DataStructures", "ForwardDiff", "LinearAlgebra", "MathOptInterface", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SparseArrays", "SpecialFunctions"]
git-tree-sha1 = "534adddf607222b34a0a9bba812248a487ab22b7"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.1.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "361c2b088575b07946508f135ac556751240091c"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.17"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

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
git-tree-sha1 = "e652a21eb0b38849ad84843a50dcbab93313e537"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.6.1"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

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

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

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
deps = ["Dates"]
git-tree-sha1 = "0044b23da09b5608b4ecacb4e5e6c6332f833a7e"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8d1f54886b9037091edf146b517989fc4a09efec"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.39"

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

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

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
git-tree-sha1 = "23368a3313d12a2326ad0035f0db0c0966f438ef"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "66fe9eb253f910fe8cf161953880cfdaef01cdf0"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.0.1"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─c4f7c3e7-9963-45de-b29e-d4dad33c5cda
# ╠═b5e9f4be-4b20-4193-a6ac-f76ee9966b40
# ╟─e6eeb994-a377-4d02-ab91-39f921eaac4a
# ╟─cdf6e13b-5c99-47eb-8f78-e65df94d987a
# ╟─3a2fde91-76bd-4ecc-b9bb-e5a873160806
# ╟─6890eecf-f2d5-48b0-9bc9-b3bd1af6e44d
# ╟─800e53d8-4d7b-4f92-93b7-8ada35cae84a
# ╟─603154d4-b8e8-40d9-9ae5-a1d8321a37bc
# ╟─22e6886f-aa89-4baa-9dce-2a999f475239
# ╟─9a7c3d61-2b49-4a29-a22b-69064bee5265
# ╟─3d895d32-5c01-491d-b4a0-c848f2f446a9
# ╠═0bdb8c87-4f6c-401f-a633-470f77810ac5
# ╠═2341525f-8ebd-44d3-ad1e-143779fdb5e5
# ╟─173fab15-2812-4637-9fd0-5277ddcef3a3
# ╠═3e5ce343-4d42-4bbb-b2b3-60b9b3147881
# ╠═a51ca19f-edf2-4774-b620-5711189e34bc
# ╟─c7d90d15-c601-4e8e-9cb9-a060a54b22e5
# ╟─ce65ce29-7c01-47e0-aa52-85c2e7afdc1d
# ╟─6902ff90-bac2-4ec3-87c1-b4d297588f01
# ╟─9ec516f5-4f5f-4307-85e3-e4d051596497
# ╟─10d3cfa9-23c8-4471-8698-730ba9b76939
# ╟─dbf6471b-1398-4808-94a2-81ee74a5ab13
# ╟─487bb70b-e237-4daa-bb90-84f8ab3ec9fc
# ╠═24e53519-12ba-438c-b050-87eaf59f0976
# ╠═74baaf6a-39b3-4f56-b8be-f0608f48b451
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

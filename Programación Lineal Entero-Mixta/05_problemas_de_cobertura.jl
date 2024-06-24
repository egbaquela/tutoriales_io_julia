### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ 99e322b0-fa3a-45d7-a0c3-93df2a8e1329
begin
	using PlutoUI, JuMP, HiGHS, NamedArrays
	TableOfContents(title="Contenido")
end 

# ╔═╡ fcbf455e-2a2a-11ed-3cd3-db52dcd9a8f6
md"# Problemas de cobertura"

# ╔═╡ c466d642-6b96-4a5f-8c00-f48f15583467
md"## Problemas de cobertura"

# ╔═╡ 26b1d484-8f14-48f4-9412-e7eefff5e9e0
md"Para entender que es un problema de cobertura, empecemos tratando de resolver el problema 12 de la cartilla de Programación Lineal Entera-Mixta.

> El condado de Washington incluye seis poblaciones que necesitan el servicio de ambulancias de emergencia. Debido a la proximidad de algunas poblaciones, una sola estación puede atender a más de una comunidad. La estipulación es que la estación debe estar como máximo a 15 minutos de tiempo de manejo de la población que atiende. La siguiente tabla muestra los tiempos de manejo en minutos entre las seis poblaciones.

| Origen 	| Destino   	|           	|           	|           	|           	|           	|
|--------	|-----------	|-----------	|-----------	|-----------	|-----------	|-----------	|
|        	| 1         	| 2         	| 3         	| 4         	| 5         	| 6         	|
| 1      	|     0     	|     23    	|     14    	|     18    	|     10    	|     32    	|
| 2      	|     23    	|     0     	|     24    	|     13    	|     22    	|     11    	|
| 3      	|     14    	|     24    	|     0     	|     60    	|     19    	|     20    	|
| 4      	|     18    	|     13    	|     60    	|     0     	|     55    	|     17    	|
| 5      	|     10    	|     22    	|     19    	|     55    	|     0     	|     12    	|
| 6      	|     32    	|     11    	|     20    	|     17    	|     12    	|     0     	|

> Determine la mínima cantidad de ambulancias necesarias, en que poblaciones poner las estaciones y a que poblaciones atienden cada una.

"

# ╔═╡ 8398457c-372c-45f1-93c6-a18025402abd
md"### Modelado"

# ╔═╡ fe81d5ce-1995-4bbc-a100-6db2a2811f93
md"Bueno, tenemos nuestro problema, ¿pero como lo modelamos?

Si bien diferente a los problemas que veníamos modelando en notebooks anteriores, tampoco es tan distinto, tiene un aire familiar. Y es que, si lo pensamos, en cierta forma es parecido a un problema de asignación. Tengo 6 posibles localizaciones donde situar las estaciones de guardia de las ambulancias, y 6 posibles destinos donde deben brindar servicio. Pero tiene algunas diferencias, siendo la principal que desde un mismo origen, podemos brindar servcio a varios destinos.

Pensemos un poco el problema. ¿Que decisión quiero tomar?, ¿como mido si una decisión particular es mejor que otra?

...

...

...

...

...

...

Ya fue suficiente tiempo para pensarlo, ¿no?. En ese sentido, el problema es bastante claro, me pide determinar donde localizar las estaciones, y si, eso es lo que tengo que hacer, localizar estaciones. Entonces, dado un conjunto de orígenes $I=\{1,2,3,4,5,6\}$, puedo definir una variable binaria $x_{i}$ tal que $x_{i}=1$ implique que decidimos colocar una estación en el origen $i$. 

Ok, ¿y cual es la función objetivo?. En ese sentido, el problema también es claro, queremos minimizar la cantidad de estaciones, así que:

$Min \ Z=\sum_{i \in I}x_{i}$

Ahora bien, tenemos que asegurarnos que, para todos los destino, llegue al menos una ambulancia. Fijémosnos que lo importante es que llegue _al menos una_, es decir, no habría problema si llegaran dos o tres. Por otro lado, tienen que llegar en 15 o menos minutos. O sea, solo pueden llegar aquellas que tarden 15 minutos o menos, por ejemplo:

* Desde una estación puesta en $i=1$, se puede atender a los destinos 1, 3 y 5, pero no al resto.

Esto lo podemos modelar con las siguientes restricciones:

$\sum_{i \in I}f(i,j)x_{i} \geq 1, \ \forall j \in J$

Donde $J$ es el conjunto de destinos, y $f(i,j)$ es una función que vale $0$ si el tiempo de viaje desde $i$ a $j$ es mayor a $15$ minutos, y $1$ en el caso contrario. Como tenemos 6 destinos, el problema completo quedaría expresado como:

$Min \ Z=x_{1}+x_{2}+x_{3}+x_{4}+x_{5}+x_{6}$

Sujeto a:

$x_{1} + x_{3} + x_{5} \geq 1$

$x_{2} + x_{4} + x_{6} \geq 1$

$x_{1} + x_{3} \geq 1$

$x_{2} + x_{4} \geq 1$

$x_{1} + x_{5} + x_{6} \geq 1$

$x_{2} + x_{5} + x_{6} \geq 1$

$x_{1}, x_{2},x_{3}, x_{4}, x_{5}, x_{6}  \in \{0,1\}$

La primera restricción me dice que el servicio respecto del primer destino solo puede ser cubierto por las estaciones ubicadas en los orígenes $1$, $3$ y $5$, por lo cual al menos una de las tres estaciones deben ser usadas. 

Observen que la función $f(i,j)$ es equivalente a decir que revisamos la tabla de tiempos de viaje y descartamos aquellas entradas en las cuales el valor es mayor a 15.
"

# ╔═╡ 24ec258d-d722-413f-8720-de2d2824c2c8
md"### Resolución"

# ╔═╡ 036c7d9e-27c1-4d1d-b871-0d23524fa7e2
begin
	model_cob_v1 = Model(HiGHS.Optimizer) #
	
	# Función f(i,j). Devuelve 1 si la distancia entre i y j es igual o menor a 15.
	# En caso contrario, devuelve 0.
	function f(matriz, i,j)
		if matriz[i,j] <=15
			return 1
		else
			return 0
		end
	end

	# Dimensiones
	origenes_cob_v1 = ["origen 1", "origen 2", "origen 3", "origen 4", "origen 5", "origen 6"]
	destinos_cob_v1 = ["destino 1", "destino 2", "destino 3", "destino 4", "destino 5", "destino 6"]
	
	#Datos
	tiempos_de_viaje_cob_v1 = NamedArray([
			[ 0	23	14	18	10	32]
	        [23	0	24	13	22	11]
	        [14	24	0	60	19	20]
	        [18	13	60	0	55	17]
	        [10	22	19	55	0	12]
	        [32	11	20	17	12	0 ]], (origenes_cob_v1, destinos_cob_v1)) 

	
	# Declaro las variables de decisión.
	x_cob_v1 = @variable(model_cob_v1, x_cob_v1[origenes_cob_v1], Bin)


	# Creo la función objetivo. 
	obj_cob_v1 = @objective(model_cob_v1, Min,
		sum([x_cob_v1[i] for i in origenes_cob_v1]))

	# Cargo las restricciones.
	r1_cob_v1 = @constraint(model_cob_v1, [j in destinos_cob_v1], sum([f(tiempos_de_viaje_cob_v1, i, j) * x_cob_v1[i] for i in origenes_cob_v1]) >= 1)


	latex_formulation(model_cob_v1)
end

# ╔═╡ 3e06161d-045d-4c91-9b6d-b097956cac16
begin
	optimize!(model_cob_v1)
	
	@show termination_status(model_cob_v1)
end

# ╔═╡ b6c7e629-ce0b-40fb-a6a2-97fdfdcbbae7
begin
	@show solution_summary(model_cob_v1, verbose=true)
end

# ╔═╡ d5128163-28bf-4110-aa76-b7792ce1db50
md"Como vemos, con instalar estaciones en los orígenes $1$ y $2$ podemos dar servicio a todos los destinos."

# ╔═╡ 5426cfed-1a25-4921-97da-2fa8536b7059
md"### Resolución alternativa"

# ╔═╡ 51ecab21-a937-4e53-8183-2b85e25b2b00
md"Cuando codificamos el modelo, definimos explícitamente la función $f(i,j)$. Pero podemos hacer el procedimiento equivalente de no tener en cuenta las asignaciones con tiempos mayor a $15$ minutos:"

# ╔═╡ 57c5907b-38f1-4586-bf0a-b90fcae51574
begin
	model_cob_v2 = Model(HiGHS.Optimizer) #
	
	# Dimensiones
	origenes_cob_v2 = ["origen 1", "origen 2", "origen 3", "origen 4", "origen 5", "origen 6"]
	destinos_cob_v2 = ["destino 1", "destino 2", "destino 3", "destino 4", "destino 5", "destino 6"]
	
	#Datos
	tiempos_de_viaje_cob_v2 = NamedArray([
			[ 0	23	14	18	10	32]
	        [23	0	24	13	22	11]
	        [14	24	0	60	19	20]
	        [18	13	60	0	55	17]
	        [10	22	19	55	0	12]
	        [32	11	20	17	12	0 ]], (origenes_cob_v2, destinos_cob_v2)) 

	
	# Declaro las variables de decisión.
	x_cob_v2 = @variable(model_cob_v2, x_cob_v2[origenes_cob_v2], Bin)


	# Creo la función objetivo. 
	obj_cob_v2 = @objective(model_cob_v2, Min,
		sum([x_cob_v2[i] for i in origenes_cob_v2]))

	# Cargo las restricciones. En vez de usar la función f(i,j) decido en la propia restricción si agregar o no la variable.
	r1_cob_v2 = @constraint(model_cob_v2, [j in destinos_cob_v2], sum([x_cob_v2[i] for i in origenes_cob_v2 if tiempos_de_viaje_cob_v2[i,j]<=15]) >= 1)


	latex_formulation(model_cob_v2)
end

# ╔═╡ 69b8beb0-3b35-437e-b3e6-54d3f9612d1b
begin
	optimize!(model_cob_v2)
	
	@show termination_status(model_cob_v2)
end

# ╔═╡ f3c7acf5-c329-4434-98e9-f7b7aa1eb1f4
begin
	@show solution_summary(model_cob_v2, verbose=true)
end

# ╔═╡ 0e2a6e34-41e0-456d-b632-03d132234e30
md"Si bien el código es diferente, es modelo es exactamente el mismo."

# ╔═╡ e4573a44-99f2-4d43-b519-e55a83a10ac7
md"### Actividades para hacer"

# ╔═╡ abda40db-f9b0-442b-aae3-7d7728c545ce
md"Para que sirva de repaso, traten de resolver las siguientes variantes:

1. No se puede instalar ninguna estación en el origen 1.
2. A cada destino deben llegar, como mínimo, ambulancias de dos orígenes diferentes.

Sabiendo resolver esto, animensé al problema 11 (ayuda: es de cobertura).
"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
HiGHS = "~1.1.4"
JuMP = "~1.3.0"
NamedArrays = "~0.9.6"
PlutoUI = "~0.7.40"
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
git-tree-sha1 = "5856d3031cdb1f3b2b6340dfdc66b6d9a149a374"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.2.0"

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
git-tree-sha1 = "992a23afdb109d0d2f8802a30cf5ae4b1fe7ea68"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.11.1"

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
git-tree-sha1 = "187198a4ed8ccd7b5d99c41b69c679269ea2b2d4"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.32"

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
deps = ["LinearAlgebra", "MathOptInterface", "MutableArithmetics", "OrderedCollections", "Printf", "SparseArrays"]
git-tree-sha1 = "906e2325c22ba8aaed432677d0a8d5cf24c9ea9e"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.3.0"

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
git-tree-sha1 = "94d9c52ca447e23eac0c0f074effbcd38830deb5"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.18"

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
git-tree-sha1 = "3256d773b0b807e478194c3e3451b8c5e27caf55"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.8.0"

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
git-tree-sha1 = "3d5bf43e3e8b412656404ed9466f1dcbf7c50269"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.4.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "a602d7b0babfca89005da04d89223b867b55319f"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.40"

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
# ╟─fcbf455e-2a2a-11ed-3cd3-db52dcd9a8f6
# ╠═99e322b0-fa3a-45d7-a0c3-93df2a8e1329
# ╟─c466d642-6b96-4a5f-8c00-f48f15583467
# ╟─26b1d484-8f14-48f4-9412-e7eefff5e9e0
# ╟─8398457c-372c-45f1-93c6-a18025402abd
# ╟─fe81d5ce-1995-4bbc-a100-6db2a2811f93
# ╟─24ec258d-d722-413f-8720-de2d2824c2c8
# ╠═036c7d9e-27c1-4d1d-b871-0d23524fa7e2
# ╠═3e06161d-045d-4c91-9b6d-b097956cac16
# ╠═b6c7e629-ce0b-40fb-a6a2-97fdfdcbbae7
# ╟─d5128163-28bf-4110-aa76-b7792ce1db50
# ╟─5426cfed-1a25-4921-97da-2fa8536b7059
# ╟─51ecab21-a937-4e53-8183-2b85e25b2b00
# ╠═57c5907b-38f1-4586-bf0a-b90fcae51574
# ╠═69b8beb0-3b35-437e-b3e6-54d3f9612d1b
# ╠═f3c7acf5-c329-4434-98e9-f7b7aa1eb1f4
# ╟─0e2a6e34-41e0-456d-b632-03d132234e30
# ╟─e4573a44-99f2-4d43-b519-e55a83a10ac7
# ╟─abda40db-f9b0-442b-aae3-7d7728c545ce
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

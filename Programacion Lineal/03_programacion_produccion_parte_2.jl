### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 9df2a720-d8c0-40f3-ad9d-ac0fa5ad7fb3
# Cargo los paquetes a usar en el notebook y genero la tabla de contenidos
begin
	using PlutoUI, JuMP, HiGHS, NamedArrays
	TableOfContents(title="Contenido")
end 

# ╔═╡ 7b640dc2-da2b-11ec-1b20-559d8a2ba88c
md"# Programando la producción - Parte 2"

# ╔═╡ 54253c66-5846-4add-abb6-84bfd5f23aff
md"## Planificación de las cantidades a producir"

# ╔═╡ 25562ef9-e3fb-4209-945a-c213e941c778
md"
Vamos a recordar el problema 3 de la cartilla de ejercicios:

>La empresa Cactus S.A. se encarga de la fabricación de pantalones y remeras para bebés. Ambos productos son cortados, cosidos y empaquetados en bolsas de polietileno para su posterior distribución en el mercado. Se sabe que para el próximo mes se dispondrán de 20.000 minutos en la sección Cortado, 36.000 minutos en la sección Costura y 6.000 minutos en la sección Empaque.
>
>Se sabe además que los requerimientos unitarios de tiempo para los pantalones son de 0.1 min/u para la sección de Corte, 0.3 min/u en la sección Costura y 0.1 min/u en la sección Empaque, mientras que para las remeras dichos tiempos son de 0.2 min/u, 0.1 min/u y 0.5 min/u respectivamente.
> 
>La contribución marginal de cada pantalón es de 1.8 por unidad y la de remeras es de 1.2 por unidad. Definir un programa de producción que maximice la contribución marginal.

"

# ╔═╡ 5d56312e-6260-45b5-beaa-f4984325cd8e
md"### Objetivos y variable de decisión"

# ╔═╡ 6424b976-5ddc-4e44-9bf6-460ef81d5917
md"
Este problema es relativamente sencillo de modelar. Si bien ya no tenemos todo el sistema de producción consolidado (como e el notebook anterior), sinó una línea de producción, la línea es única, por lo cual nuestras variables de decisión pueden enfocarse solamente a la cantidad a producir de cada producto. Si $P=\{pantalon, remera\}$ es el conjunto formado por los dos productos:

$x_{i} \in \mathbb{R}, \ con \ i \in P$

La función objetivo es también sencilla, solo hay que calcular la contribución total. Si $cm_{i}$ es la contribución marginal del producto $i$:

$Max \ Z=\sum_{i \in P}cm_{i}x_{i}$

Lo cual es equivalente a:

$Max \ Z=1.8x_{pantalon} + 1.2x_{remera}$
"

# ╔═╡ 2e6e8efd-babe-4a12-815d-c4068a56df80
md"### Restricciones"

# ╔═╡ 5d923510-9c42-4223-926b-ce95fd0a4c69
md"
Las restricciones de este problema están asociadas a la capacidad de producción de cada sección. Dado que tenemos tres secciones, tenemos tres restricciones. Si $S=\{Cortado, Costura, Empaque\}$ es el conjunto de las tres secciones, podemos expresarlas como, y $std_{i,j}$ es la cantidad qe minutos consumidos en el equipo $j$ para producir una unidad del producto $i$:

$\sum_{i \in P}std_{i,j}x_{i} \leq HorasMaximas_{j}, \forall j \in S$

Lo cual es equivalente a:

$\sum_{i \in P}std_{i,Cortado}x_{i} \leq HorasMaximas_{Cortado}$

$\sum_{i \in P}std_{i,Costura}x_{i} \leq HorasMaximas_{Costura}$

$\sum_{i \in P}std_{i,Empaque}x_{i} \leq HorasMaximas_{Empaque}$

Lo cual es también equivalente a:

$0.1x_{pantalon} + 0.2x_{remera} \leq 20000$

$0.3x_{pantalon} + 0.1x_{remera} \leq 36000$

$0.1x_{pantalon} + 0.5x_{remera} \leq 6000$

Además de estas, tenemos obviamente las restricciones de no negatividad.
"

# ╔═╡ 9405e536-e1fb-4b27-a3d3-7e954e7e6e17
md"### Problema completo"

# ╔═╡ ea7d35ed-ba03-4562-a14b-f9190d40c8fc
md"
El problema completo, en forma compacta, es el siguiente:

$Max \ Z=\sum_{i \in P}cm_{i}x_{i}$

Sujeto a:

$\sum_{i \in P}std_{i,j}x_{i} \leq HorasMaximas_{j}, \forall j \in S$

$x_{i}\geq 0, \forall i \in P$

Y, en forma extensa:

$Max \ Z=1.8x_{pantalon} + 1.2x_{remera}$

Sujeto a:

$0.1x_{pantalon} + 0.2x_{remera} \leq 20000$

$0.3x_{pantalon} + 0.1x_{remera} \leq 36000$

$0.1x_{pantalon} + 0.5x_{remera} \leq 6000$

$x_{pantalon} \geq 0$

$x_{remera} \geq 0$
"

# ╔═╡ 46669e76-5262-4ab8-8030-86e4ebebe84d
md"### Resolución"

# ╔═╡ 73fceaef-12ab-4ece-834e-147eb18fd374
begin
	model_produccion_base = Model(HiGHS.Optimizer)

	productos = ["pantalón"; "remera"]
	procesos = ["Cortado"; "Costura"; "Empaque"]
	horas_maximas = NamedArray([20000; 30000; 5000], procesos) #Creo un vector con nombres. O sea, 20000 es el valor de la componente Cortado, no de la componente 1.
	precios_de_venta = NamedArray([1.8; 1.2], productos)
	hs_por_unidad_producto = NamedArray([[0.1 0.2]
		                                 [0.3 0.1]
	                                     [0.1 0.5]], (procesos, productos))
	
	# Declaro las variables de decisión. Fijensé que, en vez de subindices numéricos, puedo utilizar el vector de nombres de productos.
	x_mpb = @variable(model_produccion_base, x_mpb[productos] >= 0)

	# Creo la función objetivo. Noten que, como las variables están definidas en base a índices no numéricos, tengo que calcular el sumaproducto explicitamente, no puedo utilizar el producto matricial.
	obj_mpb = @objective(model_produccion_base, Max,
		sum([precios_de_venta[i] * x_mpb[i] for i in productos]))

	# Cargo las restricciones de capacidad máxima. El bloque '[j in procesos]' indica que hay tantas restricciones como procesos
	r1_mpb = @constraint(model_produccion_base, [j in procesos], sum([hs_por_unidad_producto[j, i] * x_mpb[i] for i in productos]) <= horas_maximas[j])

	Text(model_produccion_base)
end

# ╔═╡ 28417a00-945e-4da9-99a8-26248560df9d
begin
	optimize!(model_produccion_base)
	
	@show solution_summary(model_produccion_base, verbose=true)
end

# ╔═╡ fe65b961-d27e-47fe-9880-d3a5abfea629
md"## Planificación de las cantidades a producir con demanda mínima"

# ╔═╡ 5d71d635-e8e3-4060-8866-98cb9b7f27dc
md"
Supongamos ahora que queremos fabricar como mínimo 5000 unidades de pantalones y 6000 de remeras. Es decir, la descripción del problema sería la siguiente:

>La empresa Cactus S.A. se encarga de la fabricación de pantalones y remeras para bebés. Ambos productos son cortados, cosidos y empaquetados en bolsas de polietileno para su posterior distribución en el mercado. Se sabe que para el próximo mes se dispondrán de 20.000 minutos en la sección Cortado, 36.000 minutos en la sección Costura y 6.000 minutos en la sección Empaque.
>
>Se sabe además que los requerimientos unitarios de tiempo para los pantalones son de 0.1 min/u para la sección de Corte, 0.3 min/u en la sección Costura y 0.1 min/u en la sección Empaque, mientras que para las remeras dichos tiempos son de 0.2 min/u, 0.1 min/u y 0.5 min/u respectivamente.
> 
>La contribución marginal de cada pantalón es de 1.8 por unidad y la de remeras es de 1.2 por unidad. Se desean fabricar, como mínimo, 5.000 unidades de pantalones y 6.000 de remeras. Definir un programa de producción que maximice la contribución marginal.
"

# ╔═╡ a2b39afa-8532-44de-9d5a-07611fe3b28e
md"### Problema completo"

# ╔═╡ 778f30ce-1017-4b22-b6e5-2fb849f473c9
md"
El problema completo, en forma compacta, es el siguiente:

$Max \ Z=\sum_{i \in P}cm_{i}x_{i}$

Sujeto a:

$\sum_{i \in P}std_{i,j}x_{i} \leq HorasMaximas_{j}, \forall j \in S$

$x_{i} \geq DemandaMinima_{i}, \forall i \in P$

$x_{i}\geq 0, \forall i \in P$

Y, en forma extensa:

$Max \ Z=1.8x_{pantalon} + 1.2x_{remera}$

Sujeto a:

$0.1x_{pantalon} + 0.2x_{remera} \leq 20000$

$0.3x_{pantalon} + 0.1x_{remera} \leq 36000$

$0.1x_{pantalon} + 0.5x_{remera} \leq 6000$

$x_{pantalon} \geq 5000$

$x_{remera} \geq 6000$

$x_{pantalon} \geq 0$

$x_{remera} \geq 0$

Notemos que el único cambio ha sido el añadido de dos restricciones. Y que, además, las restricciones de no negatividad se volvieron redundantes.
"

# ╔═╡ 97bde0da-57c2-4448-a360-3f5443a2196e
md"### Resolución"

# ╔═╡ a0006220-d967-41ab-b917-c2d4a581269c
begin
	model_produccion_base_2 = Model(HiGHS.Optimizer)

	productos_2 = ["pantalón"; "remera"]
	procesos_2 = ["Cortado"; "Costura"; "Empaque"]
	horas_maximas_2 = NamedArray([20000; 30000; 5000], procesos_2) #Creo un vector con nombres. O sea, 20000 es el valor de la componente Cortado, no de la componente 1.
	precios_de_venta_2 = NamedArray([1.8; 1.2], productos_2)
	hs_por_unidad_producto_2 = NamedArray([[0.1 0.2]
		                                   [0.3 0.1]
	                                       [0.1 0.5]], (procesos_2, productos_2))
	demanda_minima_2 = NamedArray([5000; 6000], productos_2)
	
	# Declaro las variables de decisión. Fijensé que, en vez de subindices numéricos, puedo utilizar el vector de nombres de productos.
	x_mpb_2 = @variable(model_produccion_base_2, x_mpb_2[productos_2] >= 0)

	# Creo la función objetivo. Noten que, como las variables están definidas en base a índices no numéricos, tengo que calcular el sumaproducto explicitamente, no puedo utilizar el producto matricial.
	obj_mpb_2 = @objective(model_produccion_base_2, Max,
		sum([precios_de_venta_2[i] * x_mpb_2[i] for i in productos_2]))

	# Cargo las restricciones de capacidad máxima. El bloque '[j in procesos]' indica que hay tantas restricciones como procesos
	r1_mpb_2 = @constraint(model_produccion_base_2, [j in procesos_2], sum([hs_por_unidad_producto_2[j, i] * x_mpb_2[i] for i in productos_2]) <= horas_maximas_2[j])

	# Cargo las restricciones de demanda minima.
	r2_mpb_2 = @constraint(model_produccion_base_2, [i in productos_2], x_mpb_2[i] >= demanda_minima_2[i])

	Text(model_produccion_base_2)
end

# ╔═╡ c6d56864-4d9b-4991-a8e7-a3dfb93fc642
begin
	optimize!(model_produccion_base_2)
	
	@show solution_summary(model_produccion_base_2, verbose=true)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
HiGHS = "~1.1.3"
JuMP = "~1.0.0"
NamedArrays = "~0.9.6"
PlutoUI = "~0.7.39"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "4c10eee4af024676200bc7752e536f858c6b8f93"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.1"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "9950387274246d08af38f6eef8cb5480862a435f"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.14.0"

[[ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "1e315e3f4b0b7ce40feded39c73049692126cf53"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.3"

[[CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "2e62a725210ce3c3c2e1a3080190e7ca491f18d7"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.7.2"

[[CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "a985dc37e357a3b22b260a5def99f3530fb415d3"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.2"

[[Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "b153278a25dd42c65abbf4e62344f9d22e59191b"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.43.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "cc1a8e22627f33c789ab60b36a9132ac050bbf75"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.12"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "28d605d9a0ac17118fe2c5e9ce0fbb76c3ceb120"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.11.0"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "2f18915445b248731ec5db4e4a17e451020bf21e"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.30"

[[HiGHS]]
deps = ["HiGHS_jll", "MathOptInterface", "SparseArrays"]
git-tree-sha1 = "bb6b049c06370af5319d86d977429a01dd09e6d6"
uuid = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
version = "1.1.3"

[[HiGHS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b0bf110765a077880aab84876f9f0b8de0407561"
uuid = "8fd58aa0-07eb-5a78-9b36-339c94fd15ea"
version = "1.2.2+0"

[[Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "336cc738f03e069ef2cac55a104eb823455dca75"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.4"

[[InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[JuMP]]
deps = ["Calculus", "DataStructures", "ForwardDiff", "LinearAlgebra", "MathOptInterface", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SparseArrays", "SpecialFunctions"]
git-tree-sha1 = "936e7ebf6c84f0c0202b83bb22461f4ebc5c9969"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.0.0"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "09e4b894ce6a976c354a69041a04748180d43637"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.15"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "JSON", "LinearAlgebra", "MutableArithmetics", "OrderedCollections", "Printf", "SparseArrays", "Test", "Unicode"]
git-tree-sha1 = "23c99cadd752cc0b70d4c74c969a679948b1bb6a"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.2.0"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "4050cd02756970414dab13b55d55ae1826b19008"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.0.2"

[[NaNMath]]
git-tree-sha1 = "737a5957f387b17e74d4ad2f440eb330b39a62c5"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.0"

[[NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "2fd5787125d1a93fbe30961bd841707b8a80d75b"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.6"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "1285416549ccfcdf0c50d4997a94331e88d68413"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.1"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8d1f54886b9037091edf146b517989fc4a09efec"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.39"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "bc40f042cfcc56230f781d92db71f0e21496dffd"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.5"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "cd56bf18ed715e8b09f06ef8c6b781e6cdc49911"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.4.4"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─7b640dc2-da2b-11ec-1b20-559d8a2ba88c
# ╠═9df2a720-d8c0-40f3-ad9d-ac0fa5ad7fb3
# ╟─54253c66-5846-4add-abb6-84bfd5f23aff
# ╟─25562ef9-e3fb-4209-945a-c213e941c778
# ╟─5d56312e-6260-45b5-beaa-f4984325cd8e
# ╟─6424b976-5ddc-4e44-9bf6-460ef81d5917
# ╟─2e6e8efd-babe-4a12-815d-c4068a56df80
# ╟─5d923510-9c42-4223-926b-ce95fd0a4c69
# ╟─9405e536-e1fb-4b27-a3d3-7e954e7e6e17
# ╟─ea7d35ed-ba03-4562-a14b-f9190d40c8fc
# ╟─46669e76-5262-4ab8-8030-86e4ebebe84d
# ╠═73fceaef-12ab-4ece-834e-147eb18fd374
# ╠═28417a00-945e-4da9-99a8-26248560df9d
# ╟─fe65b961-d27e-47fe-9880-d3a5abfea629
# ╟─5d71d635-e8e3-4060-8866-98cb9b7f27dc
# ╟─a2b39afa-8532-44de-9d5a-07611fe3b28e
# ╟─778f30ce-1017-4b22-b6e5-2fb849f473c9
# ╟─97bde0da-57c2-4448-a360-3f5443a2196e
# ╠═a0006220-d967-41ab-b917-c2d4a581269c
# ╠═c6d56864-4d9b-4991-a8e7-a3dfb93fc642
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

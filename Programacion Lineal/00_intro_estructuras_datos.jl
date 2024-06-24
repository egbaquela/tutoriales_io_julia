### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ a7b819a6-3168-4138-917d-9f024fa8e187
begin
	using PlutoUI
	TableOfContents(title="Contenido")
end 

# ╔═╡ 367f3d1a-3546-4021-9994-82268196a1e4
using NamedArrays

# ╔═╡ ff734c42-d787-11ed-000f-7fe0eb95fa1c
md"# Introducción a las estructuras de datos para Programación Lineal"

# ╔═╡ 0d6bd842-e447-4fe8-a66a-e227b0fcd46b
md"## NamedArrays"

# ╔═╡ 5c5db570-6725-4d22-9d15-3f5a234e03e0
md"### ¿Que son los NamedArrays?"

# ╔═╡ 0aede690-c987-40bf-bd2c-f7c1c1031224
md"Un NamedArray es una estructura de datos que, por un lado, generaliza los vectores y matrices y, por otro, nos permite asociar nombres a cada una de sus componentes. Esto último, que no parece importante, es lo que nos proporciona su potencia en el modelado de problema de programación lineal: nos permite llamar a los elementos de vectores y matrices usando terminología coloquial."

# ╔═╡ 18b44e56-475b-4248-abbc-d9e91066be8b
md"Para poder usar un NamedArray, primero hay que cargar en memoria el paquete en el cual están definidos. Para ello hacemos:"

# ╔═╡ 7431d586-8b40-418e-a100-4b05286fd2b8
md"### Vectores"

# ╔═╡ 49c39222-080a-4b4f-b81e-f7677b764ab1
md"Listo, tenemos la funcionalidad de los NamedArray disponibles en memoria. Veamos como usarlos. Para empezar, puedo crear vectores:" 

# ╔═╡ a42043f0-8313-4294-a33b-4381ab24bc5a
begin
	vector_nombres_de_las_componentes = ["Costo del peaje"; "Costo del flete"; "Costo de la mano de obra"]
	vector_valores_de_las_componentes = [10;20;30]
	vector_named_array_1 = NamedArray(vector_valores_de_las_componentes, vector_nombres_de_las_componentes)
end

# ╔═╡ e63aa9d9-7698-4092-ae9d-4f9032c1af5a
md"Creamos tres cosas en el bloque anterior. Dos vectores, uno con texto y otro con números, y un NamedArray que los vincula. Si mis datos no son muchos, yo podría hacer todas las operaciones que quisiera con el vector de valores:"

# ╔═╡ bb47a52e-fc42-4217-9b55-2fa352f97ae8
# Visualizarlo (noten que el vector que creamos es un vector columna):
vector_valores_de_las_componentes

# ╔═╡ 55e5a1ff-9c1a-4757-af01-33da59e1294d
# Transponerlo (para crear un vector fila):
vector_valores_de_las_componentes'

# ╔═╡ f8f1e605-f588-445a-99e0-aa49881d97c8
# Consulto el valor de la segunda componente:
vector_valores_de_las_componentes[2]

# ╔═╡ dfcb8562-ff11-4fe7-8afb-d9318685f3c0
# Sumo los valores de todas las componentes:
sum(vector_valores_de_las_componentes)

# ╔═╡ f613aecf-e24e-4ca9-b872-3116d828056d
# Calculo el producto escalar de un vector con otro (creado on-the-fly, en este caso):
vector_valores_de_las_componentes' * [1;2;3]

# ╔═╡ 28897e3a-687e-4068-b3f8-cb912c20edac
# Concatenar vectores:
[vector_valores_de_las_componentes; [1;2;3]]

# ╔═╡ e074986b-20ac-476e-9ef7-ed93116c758f
md"El problema de esto es que me tengo que acordar que representaba cada una de las componentes. Fácil con 3 componentes, no tan fácil con 30 componentes. Usando un NamedArray, es mas fácil acordarse:"

# ╔═╡ 75206e98-76ae-4b14-a4c1-9964c2441494
# Si queremos obtener el valor del costo del flete, es mas fácil acordarse de "Costo del flete" que memorizar que la componente 2 apuntaba al costo del flete:
vector_named_array_1["Costo del flete"]

# ╔═╡ a467f78f-cf34-4f86-a8f4-ed238e93e848
# También podría consultar por el número de componente:
vector_named_array_1[vector_nombres_de_las_componentes[2]]

# ╔═╡ b7246997-d359-40dc-9fda-cf224ede0ccc
# Podría querer buscar todos los costos distintos del "Costo del flete":
vector_named_array_1[Not("Costo del flete")]

# ╔═╡ 3285bd13-8edf-4aff-876d-e3c38e235dc2
# Puedo transponer:
vector_named_array_1'

# ╔═╡ f98fcf79-3a20-4e49-8b61-a342f085b4f3
# No puedo hacer el producto escalar como antes, me tira error:
vector_named_array_1' * [1;2;3]

# ╔═╡ 6a129b9f-f4d1-4116-9509-3d603c591e6e
# Pero puedo hacerlo multiplicando componente por componente y sumando:
sum(vector_named_array_1 .* [1;2;3])

# ╔═╡ d6444c6b-bd86-4f3f-9f87-13cc8bc72ae0
# Pero, si tengo dos vectores con componentes con el mismo nombre, puedo hacer:
begin
	# Creo el segundo NamedArray
	vector_named_array_2 = NamedArray([1;2;3], vector_nombres_de_las_componentes)

	# Calculo el producto escalar, en una forma parecida a la notación usada en programación lineal
	sum([vector_named_array_1[i] * vector_named_array_2[i] for i in vector_nombres_de_las_componentes])

end

# ╔═╡ 8229ed38-6a9c-4f04-bcda-8093254740c4
md"Lo anterior fue un poco mas complicado, veámoslo por partes. Si quiero multiplicar los valores asociados a 'Costo del flete':"

# ╔═╡ bd3bb9d4-4bad-43b8-9290-e54d75fed414
vector_named_array_1["Costo del flete"] * vector_named_array_2["Costo del flete"]

# ╔═╡ d787fab9-6ee3-4bd7-acb5-b9c87ce63b91
md"Para no repetir 'Costo del flete', podría haber hecho:"

# ╔═╡ db36b9fa-813e-4d92-b654-46f5a48d2ef8
begin
	nombre = "Costo del flete"
	vector_named_array_1[nombre] * vector_named_array_2[nombre]
end

# ╔═╡ 613dbdd4-3d14-4891-bae2-f7611330313a
md"Si multiplico para todos los nombre:"

# ╔═╡ ab3ac5c0-384a-4604-b6c7-19502f8824de
begin
	[vector_named_array_1[nombre] * vector_named_array_2[nombre] for nombre in vector_nombres_de_las_componentes]
end

# ╔═╡ 03ee4312-fdc9-4989-aec2-94c0b51cd9a9
md"Sumando el resultado anterior, llego al producto escalar:"

# ╔═╡ b4362527-93db-4bc9-9bef-becd19b7cf91
begin
	sum([vector_named_array_1[nombre] * vector_named_array_2[nombre] for nombre in vector_nombres_de_las_componentes])
end

# ╔═╡ 598319c1-f4d4-4b33-a5de-9bd2af33e8b0
md"Puedo hacer comparaciones también"

# ╔═╡ d3fe0366-7897-4238-8882-e55ede5c8704
# Hago una comparación con un elemento del vector
vector_named_array_1["Costo del flete"] >= 30

# ╔═╡ 9fe8a1f7-e421-4e80-bc79-6020f5b1fb4c
# Hago una comparación con cada elemento del vector
vector_named_array_1 .>= 30

# ╔═╡ 47918780-8dd3-45a2-abeb-c7c2f7638856
# O comparar elementos de dos vectores del mismo tamaño
vector_named_array_1 .>= [30; 4; 10]

# ╔═╡ 417ac629-b663-40fd-a8aa-fc4e10bb7821
md"### Matrices"

# ╔═╡ 599f0d55-579c-4d8b-8c66-dbc2a3f1d9ea
md"Una matriz se crea en forma muy similar a un vector:"

# ╔═╡ f7736f1d-7e8f-4d43-985c-4fb91468be64
matriz1 = [[1;2;3] [4;5;6]] # Concateno vectores columna, fila a fila

# ╔═╡ 2f168bb7-261b-4363-ba8e-b488679c884b
md"O, formateandoló un poco mas parecido a una matriz:"

# ╔═╡ 340ffd79-3090-48a7-b5ce-913fa047881b
matriz2 = [[1 4] 
           [2 5]
           [3 6]] # Concateno vectores fila, columna a columna

# ╔═╡ 784a993d-f452-428e-be1e-13bf8b60d4c1
md"Las matrices se pueden transponer:"

# ╔═╡ 708fe9d6-698d-4e2b-9f7d-50cb7b56dc8e
matriz1'

# ╔═╡ cbdc2968-10d6-4254-b9e9-e0088dc4de7a
md"Puedo multiplicar matrices:"

# ╔═╡ 0b94e231-995f-4893-a0d2-232550e80ac4
matriz1 * matriz1' # Recordemos que la cantidad de columnas de la primera tiene que ser igual a la cantidad de filas de la segunda

# ╔═╡ b10470ec-b7a4-40af-86d5-d00a757cc1c8
md"También puedo multiplicar matrices por vectores columna:"

# ╔═╡ 1452ea14-a3f5-4fd8-b3f8-c83917370591
begin
	vector = [1;10]
	matriz1 * vector
end

# ╔═╡ a29d7c29-ac7a-41fb-af51-a65b3e845f3f
md"Los NamedArray nos permiten crear matrices también:"

# ╔═╡ 87bf6bbc-c758-46f6-8098-8fc77202801c
begin
	vector_nombre_de_las_filas = ["Peaje"; "Flete"; "Mano de obra"]
	vector_nombre_de_las_columnas = ["Cantidad"; "Costo"]	

	elementos_de_la_matriz = [[1;2;3] [4;5;6]] #Concateno vectores columna
	matriz_named_array_1 = NamedArray(elementos_de_la_matriz, (vector_nombre_de_las_filas, vector_nombre_de_las_columnas))

end

# ╔═╡ e9d9634f-5db6-4874-93d9-c944ef3a59d3
md"Puedo usar los dos modos vistos de crear matrices:"

# ╔═╡ ff6ca0f0-b5bb-48e0-9a0d-17c8f8e93aa5
begin
	elementos_de_la_matriz_2 = [[1 4] 
                                [2 5]
                                [3 6]] # Concateno vectores fila
	matriz_named_array_2 = NamedArray(elementos_de_la_matriz_2, (vector_nombre_de_las_filas, vector_nombre_de_las_columnas))

end

# ╔═╡ 481995dc-44dd-48ea-b42b-fd29a626ef1e
md"Con esto, puedo hacer:"

# ╔═╡ 1013b40f-1278-4b5d-908e-8390a3bc6de8
# Traigo un elemento
matriz_named_array_1["Peaje","Costo"]

# ╔═╡ d86fe9de-ec57-4d28-980b-5a247e3d7103
# Traigo una columna
matriz_named_array_1[:,"Costo"]

# ╔═╡ ee7b909e-13dc-439b-9a65-eefabaf49796
# Traigo una fila
matriz_named_array_1["Peaje",:]

# ╔═╡ 16228012-9a61-413f-bf3f-8ec911b7e9c5
# Traigo una submatriz arbitraria:
matriz_named_array_1[["Peaje"; "Mano de obra"],"Costo"]

# ╔═╡ 06b60846-7383-41c0-abb0-278fa742a809
matriz_named_array_1 * [1;10]

# ╔═╡ 669a4a64-6b61-403e-b19f-287bb5617832
md"La forma de uso es muy similar a la de los vectores, salvo que ahora indexamos por dos dimensiones"

# ╔═╡ 005b6567-ff4a-40a5-9157-c03ea89e5f6e
md"### Arreglos con mas dimensiones"

# ╔═╡ cd2abb92-af4b-4b68-9616-c906f9dbcb9e
md"En muchos problemas de programación lineal, nos quedamos cortos con dos dimensiones. Por suerte, NamedArray nos permite trabajar con cualquier número de ellas:"

# ╔═╡ 9bca8217-c1cc-4b03-8233-7c0c2ec3db03
begin
	vector_objetos = ["Peaje"; "Flete"; "Mano de obra"]
	vector_metricas = ["Cantidad"; "Costo"]	
	vector_meses = ["Mes 1"; "Mes 2"]

	elementos =cat(
					#=Mes 1=#			     [[1 4]
										      [2 55]
										      [3 6]], 
					#=Mes 2=#				[[1 4.1]
										     [2 6.3]
										     [5 7.0]], dims=3) 
	multidimensional_named_array_1 = NamedArray(elementos, (vector_objetos, vector_metricas, vector_meses))

end

# ╔═╡ cb414182-df2f-4a77-aa86-5984e4dc48cc
md"¿Pueden intepretar que está haciendo 'cat'?"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
NamedArrays = "~0.9.8"
PlutoUI = "~0.7.50"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "1a1c0854078fbd22fd94cc987fda97caf7d758e4"

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

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

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

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

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

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "b84e17976a40cb2bfe3ae7edb3673a8c630d4f95"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.8"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

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

[[deps.Tricks]]
git-tree-sha1 = "aadb748be58b492045b4f56166b5188aa63ce549"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.7"

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
# ╟─ff734c42-d787-11ed-000f-7fe0eb95fa1c
# ╠═a7b819a6-3168-4138-917d-9f024fa8e187
# ╟─0d6bd842-e447-4fe8-a66a-e227b0fcd46b
# ╟─5c5db570-6725-4d22-9d15-3f5a234e03e0
# ╟─0aede690-c987-40bf-bd2c-f7c1c1031224
# ╟─18b44e56-475b-4248-abbc-d9e91066be8b
# ╠═367f3d1a-3546-4021-9994-82268196a1e4
# ╟─7431d586-8b40-418e-a100-4b05286fd2b8
# ╟─49c39222-080a-4b4f-b81e-f7677b764ab1
# ╠═a42043f0-8313-4294-a33b-4381ab24bc5a
# ╟─e63aa9d9-7698-4092-ae9d-4f9032c1af5a
# ╠═bb47a52e-fc42-4217-9b55-2fa352f97ae8
# ╠═55e5a1ff-9c1a-4757-af01-33da59e1294d
# ╠═f8f1e605-f588-445a-99e0-aa49881d97c8
# ╠═dfcb8562-ff11-4fe7-8afb-d9318685f3c0
# ╠═f613aecf-e24e-4ca9-b872-3116d828056d
# ╠═28897e3a-687e-4068-b3f8-cb912c20edac
# ╟─e074986b-20ac-476e-9ef7-ed93116c758f
# ╠═75206e98-76ae-4b14-a4c1-9964c2441494
# ╠═a467f78f-cf34-4f86-a8f4-ed238e93e848
# ╠═b7246997-d359-40dc-9fda-cf224ede0ccc
# ╠═3285bd13-8edf-4aff-876d-e3c38e235dc2
# ╠═f98fcf79-3a20-4e49-8b61-a342f085b4f3
# ╠═6a129b9f-f4d1-4116-9509-3d603c591e6e
# ╠═d6444c6b-bd86-4f3f-9f87-13cc8bc72ae0
# ╟─8229ed38-6a9c-4f04-bcda-8093254740c4
# ╠═bd3bb9d4-4bad-43b8-9290-e54d75fed414
# ╟─d787fab9-6ee3-4bd7-acb5-b9c87ce63b91
# ╠═db36b9fa-813e-4d92-b654-46f5a48d2ef8
# ╟─613dbdd4-3d14-4891-bae2-f7611330313a
# ╠═ab3ac5c0-384a-4604-b6c7-19502f8824de
# ╟─03ee4312-fdc9-4989-aec2-94c0b51cd9a9
# ╠═b4362527-93db-4bc9-9bef-becd19b7cf91
# ╟─598319c1-f4d4-4b33-a5de-9bd2af33e8b0
# ╠═d3fe0366-7897-4238-8882-e55ede5c8704
# ╠═9fe8a1f7-e421-4e80-bc79-6020f5b1fb4c
# ╠═47918780-8dd3-45a2-abeb-c7c2f7638856
# ╟─417ac629-b663-40fd-a8aa-fc4e10bb7821
# ╟─599f0d55-579c-4d8b-8c66-dbc2a3f1d9ea
# ╠═f7736f1d-7e8f-4d43-985c-4fb91468be64
# ╠═2f168bb7-261b-4363-ba8e-b488679c884b
# ╠═340ffd79-3090-48a7-b5ce-913fa047881b
# ╟─784a993d-f452-428e-be1e-13bf8b60d4c1
# ╠═708fe9d6-698d-4e2b-9f7d-50cb7b56dc8e
# ╟─cbdc2968-10d6-4254-b9e9-e0088dc4de7a
# ╠═0b94e231-995f-4893-a0d2-232550e80ac4
# ╟─b10470ec-b7a4-40af-86d5-d00a757cc1c8
# ╠═1452ea14-a3f5-4fd8-b3f8-c83917370591
# ╟─a29d7c29-ac7a-41fb-af51-a65b3e845f3f
# ╠═87bf6bbc-c758-46f6-8098-8fc77202801c
# ╟─e9d9634f-5db6-4874-93d9-c944ef3a59d3
# ╠═ff6ca0f0-b5bb-48e0-9a0d-17c8f8e93aa5
# ╟─481995dc-44dd-48ea-b42b-fd29a626ef1e
# ╠═1013b40f-1278-4b5d-908e-8390a3bc6de8
# ╠═d86fe9de-ec57-4d28-980b-5a247e3d7103
# ╠═ee7b909e-13dc-439b-9a65-eefabaf49796
# ╠═16228012-9a61-413f-bf3f-8ec911b7e9c5
# ╠═06b60846-7383-41c0-abb0-278fa742a809
# ╟─669a4a64-6b61-403e-b19f-287bb5617832
# ╟─005b6567-ff4a-40a5-9157-c03ea89e5f6e
# ╟─cd2abb92-af4b-4b68-9616-c906f9dbcb9e
# ╠═9bca8217-c1cc-4b03-8233-7c0c2ec3db03
# ╟─cb414182-df2f-4a77-aa86-5984e4dc48cc
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

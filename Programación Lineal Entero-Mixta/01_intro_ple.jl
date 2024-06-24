### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 643d54ee-e08e-4de5-8733-d18704781523
# Cargo los paquetes a usar en el notebook y genero la tabla de contenidos
begin
	using PlutoUI, JuMP, HiGHS, NamedArrays
	TableOfContents(title="Contenido")
end 

# ╔═╡ 2d4017c0-da97-11ec-0bb9-2dbf19cdd9b5
md"# Introducción a la Programación Lineal Entero-Mixta"

# ╔═╡ 1daee18c-7dc8-44fd-9e38-3a282fdb7497
md"## Problema de la mochila (knapsack problem)"

# ╔═╡ 133f42e1-fe24-4ab4-addc-2db93d9fb951
md"
El problema de la mochila es uno de los problemas básicos de programación lineal entero-mixta con variables binarias. Resolvamos el problema 24 de la cartilla 1 de la unidad de _Programación Lineal Entero-Mixta_.

> Supongamos que tenemos una mochila en la cual la capacidad máxima es de 15 kg, y deseamos guardar en ella estos objetos:

> * Objeto 1, de 1 kg, que aporta un beneficio de 2.
> * Objeto 2, de 2 kg, que aporta un beneficio de 3.
> * Objeto 3, de 4 kg, que aporta un beneficio de 4.
> * Objeto 4, de 6 kg, que aporta un beneficio de 7.
> * Objeto 5, de 8 kg, que aporta un beneficio de 6.
> * Objeto 6, de 12 kg, que aporta un beneficio de 8.
> * Objeto 7, de 14 kg, que aporta un beneficio de 9.

> Obviamente, no podemos guardar todos los objetos en la mochila, el peso total es mayor a la capacidad de la misma. Entonces, ¿como puedo seleccionar un subconjunto de objetos para guardarlos en la mochila, sin superar su capacidad, pero maximizando el beneficio?
"

# ╔═╡ 78c3e84d-3a12-4e67-b8c3-c02fac10c0a8
md"### Objetivos y variables de decisión"

# ╔═╡ 8a86499c-4cda-4299-af95-1bdce26a303c
md"
Lo primero que tenemos que darnos cuenta es que, a diferencia de los problemas de _Programación Lineal (continua)_, la decisión a tomar no pasa por definir _cuanto de algo_, sinó definir _si hacemos algo o no_. Es decir, pasamos de una decisión del tipo _cuanto_ a una decisión del tipo _si-no_. Mientras que en la primera tendríamos infinitos posibles valores, en la segunda solo tenemos dos posibles valores.

Cuando queres resolver un problema relativo al _cuanto_, lo podemos modelar con variables pertenecientes al dominio de los reales (o a los enteros, llegado el caso). Pero, cuando queremos resolver cuestiones del tipo _si-no_, tenemos que utilizar variables en el dominio binario, es decir, que solo puedan tomar valores $0$ o $1$ (o, lo que es lo mismo, el dominio es el conjunto {0,1}, el cual es el subconjunto de los enteros mayores o iguales a $0$ y menores o iguales a $1$). Podemos usar la convención que $0=no$ y $1=si$.

Dado lo anterior, podemos plantaer el problema como un conjunto de decisiones relativas a si el objeto $i$ va a ser incluido en la mochila o no. En otras palabras, podemos definir un conjunto de variables $x_{i} \in \{0,1\}$, donde $x_{i}=1$ significa que incluimos el objeto $i$ en la mochila y $x_{i}=0$ significa que no. En esos términos, la función objetivo queda como:

$Max \ Z=\sum_{i \in I}beneficio_{i} \cdot x_{i}$

Donde $I$ es el conjunto de nuestros siete objetos.
"

# ╔═╡ 9f4f2144-32e0-4194-a942-3c6b36383757
md"### Restricciones"

# ╔═╡ fa283a0d-5e94-4424-98b7-1ad14b1a846d
md"
Las restricciones aquí se refieren a que no podemos superar la capacidad de la mochila:

$\sum_{i \in I}peso_{i} \cdot x_{i} \leq capacidadMochila$

"

# ╔═╡ 07af090c-f8e4-470e-9326-accbd0523dbf
md"### Problema completo"

# ╔═╡ e97b5cf5-0135-4b79-a35d-0afec0513c7d
md"
El problema completo, en forma compacta, es el siguiente:

$Max \ Z=\sum_{i \in I}beneficio_{i} \cdot x_{i}$

Sujeto a:

$\sum_{i \in I}peso_{i} \cdot x_{i} \leq capacidadMochila$

$x_{i} \in \{0,1\}, \forall i \in I$

Y, en forma extensa:

$Max \ Z=2x_{1} + 3x_{2} + 4x_{3} + 7x_{4} + 6x_{5}  + 8x_{6}  + 9x_{7}$

Sujeto a:

$1x_{1} + 2x_{2} + 4x_{3} + 6x_{4} + 8x_{5}  + 12x_{6}  + 14x_{7} \leq 15$

$x_{1}, x_{2}, x_{3}, x_{4}, x_{5}, x_{6}, x_{7} \in \{0,1\}$


"

# ╔═╡ 318b9749-a03a-4a0b-a4ec-273ac7f3d0be
md"### Resolución"

# ╔═╡ 9529b709-4d54-4ea3-9abc-bc9a46a84a09
begin
	model_mochila = Model(HiGHS.Optimizer) #

	# Dimensiones
	objetos_mm = ["obj1", "obj2", "obj3", "obj4", "obj5", "obj6", "obj7"]
	
	# Datos
	beneficios_mm = NamedArray([2; 3; 4; 7; 6; 8; 9], objetos_mm) 
	pesos_mm = NamedArray([1; 2; 4; 6; 8; 12; 14], objetos_mm) 
	capacidad_mochila = 15
	
	# Declaro las variables de decisión.
	x_mm = @variable(model_mochila, x_mm[objetos_mm], Bin)

	# Creo la función objetivo. 
	obj_mm = @objective(model_mochila, Max,
		sum([beneficios_mm[i] * x_mm[i] for i in objetos_mm]))

	# Cargo la restricción de capacidad máxima.
	r1_mm = @constraint(model_mochila, sum([pesos_mm[i] * x_mm[i] for i in objetos_mm]) <= capacidad_mochila)

	latex_formulation(model_mochila)
end

# ╔═╡ c419b556-e7cd-43a2-811e-153d2cc85a2c
begin
	optimize!(model_mochila)
	
	@show solution_summary(model_mochila, verbose=true)
end

# ╔═╡ 42278aa8-cf77-4526-b206-8815717d0bf0
md"## Problema de la multi-mochila"

# ╔═╡ 082aa155-8f7b-49b6-a163-847dee7a2df5
md"¿Que pasa si tengo una segunda mochila, con capacidad de 10 kg?, es decir, si no solamente tengo que decidir que guardar sino también en cual de las dos mochilas. Este problema, con dos o mas mochilas, se conoce como el problema de las mochilas múltiples, o multi-mochila."

# ╔═╡ d6967ef7-fd66-4148-9e24-e4227961897f
md"### Objetivos y variables de decisión"

# ╔═╡ 65a32339-88f1-49e0-81a3-02efeaac28a3
md"En este caso, el problema se puede reformular pensando que tengo que decidir si colocar el objeto $i$ en la mochila $j$. Por eso, mis variables de decisión serían $x_{i,j} \in \{0,1\}$. El objetivo, permanece mas o menos parecido:

$Max \ Z=\sum_{i \in I}\sum_{j \in J}beneficio_{i} \cdot x_{i,j}$

Donde $J$ es el conjunto de mochilas. Notemos que, en este caso, el beneficio es el mismo para un objeto $i$, sin importar en que mochila se guarde.
"

# ╔═╡ 3ee77cbd-1d2d-4e9e-95ae-ccc2878b8c34
md"### Restricciones"

# ╔═╡ 4932f2a8-885e-4809-880c-88d578a2bb14
md"Las restricciones cambian un poco mas. Por un lado, tenemos la restricción de capacidad, pero ahora por cada mochila. Importante notar que en la restricción de capacidad asociada a cada mochila, solo consideramos las variables que impliquen la decisión de colocar el objeto en esa mochila:

$\sum_{i \in I}peso_{i} \cdot x_{i,j} \leq capacidadMochila_{j}, \forall j \in J$

Por otro lado, si ponemos el objeto $i$ en una mochila, no podemos ponerlo en el resto de las mochilas disponibles. Dado que nuestras variables son binarias, podemos modelar esto como:

$\sum_{j \in J}x_{i,j} \leq 1, \forall i \in I$

Es decir, tenemos una restricción por cada objeto $i$, que dice que todas las variables binarias que apunten a ese objeto (es decir, mismo objeto, diferentes mochilas) pueden sumar, cuando mucho, $1$. Como son binarias, solo pueden tomar valor $0$ o $1$, por lo tanto, estamos diciendo que hay dos posibles alternativas para cada objeto $i$:

* Todas las variables valen $0$, lo que implica que el objeto no se guarda en ninguna mochila.
* Una variable vale $1$ y el resto $0$, lo que implica que el objeto $i$ y se guarda en la mochila cuya $x_{i,j}=1$.
"

# ╔═╡ 260d3f87-b56a-4185-9fef-893bf856a64d
md"### Problema completo"

# ╔═╡ 5c0ea276-77ba-43b0-9d1c-68badbf3889e
md"

$Max \ Z=\sum_{i \in I}\sum_{j \in J}beneficio_{i} \cdot x_{i,j}$

Sujeto a:

$\sum_{i \in I}peso_{i} \cdot x_{i,j} \leq capacidadMochila_{j}, \forall j \in J$

$\sum_{j \in J}x_{i,j} \leq 1, \forall i \in I$

$x_{i,j} \in \{0,1\}$
"

# ╔═╡ f0f1fca5-ac06-4957-8fb0-82939cd26bdc
md"### Resolución"

# ╔═╡ 97f624c2-43bb-4f01-9243-535763bd55a2
begin
	model_multi_mochila = Model(HiGHS.Optimizer) #

	# Dimensiones
	objetos_mmm = ["obj1", "obj2", "obj3", "obj4", "obj5", "obj6", "obj7"]
	mochilas_mmm = ["mochila1", "mochila2"]
	
	# Datos
	beneficios_mmm = NamedArray([2; 3; 4; 7; 6; 8; 9], objetos_mmm) 
	pesos_mmm = NamedArray([1; 2; 4; 6; 8; 12; 14], objetos_mmm) 
	capacidad_mochila_mmm = NamedArray([15;10], mochilas_mmm) 
	
	# Declaro las variables de decisión.
	x_mmm = @variable(model_multi_mochila, x_mmm[objetos_mmm, mochilas_mmm], Bin)

	# Creo la función objetivo. 
	obj_mmm = @objective(model_multi_mochila, Max,
		sum([beneficios_mmm[i] * x_mmm[i,j] for i in objetos_mmm for j in mochilas_mmm]))

	# Cargo las restricciones de capacidad máxima.
	r1_mmm = @constraint(model_multi_mochila, [j in mochilas_mmm], sum([pesos_mmm[i] * x_mmm[i,j] for i in objetos_mmm]) <= capacidad_mochila_mmm[j])

	# Cargo las restricciones de un objeto en una sola mochila.
	r2_mmm = @constraint(model_multi_mochila, [i in objetos_mmm], sum([x_mmm[i,j] for j in mochilas_mmm]) <= 1)
	
	latex_formulation(model_multi_mochila)
end

# ╔═╡ 21ade227-3a18-4796-bfec-fbde568097a0
begin
	optimize!(model_multi_mochila)
	
	@show solution_summary(model_multi_mochila, verbose=true)
end

# ╔═╡ 25f03233-8522-4393-9f34-3e940b41de42
md"## Problema de la multi-mochila con multi-capacidades"

# ╔═╡ 633362e2-ebc7-40f0-bafe-29b60a604a54
md"¿Que pasa si ahora no solo hay que atender a no pasarse del peso máximo que soporta cada mochila, sinó también del volumen máximo que se puede guardar?. Suponiendo que la primera mochila tiene una capacidad de 20 litros y la segunda de 15 litros, y estos consumos de volúmenes por parte de cada objeto:

* Objeto 1, de 1 kg y 1 l, que aporta un beneficio de 2.
* Objeto 2, de 2 kg y 5 l, que aporta un beneficio de 3.
* Objeto 3, de 4 kg y 4 l, que aporta un beneficio de 4.
* Objeto 4, de 6 kg y 2 l, que aporta un beneficio de 7.
* Objeto 5, de 8 kg y 3 l, que aporta un beneficio de 6.
* Objeto 6, de 12 kg y 6 l, que aporta un beneficio de 8.
* Objeto 7, de 14 kg y 8 l, que aporta un beneficio de 9.

El único cambio al modelo es que, por cada mochila, hay que chequear dos capacidades diferentes. Es decir, en vez de tener la siguiente restriccion:

$\sum_{i \in I}peso_{i} \cdot x_{i,j} \leq capacidadMochila_{j}, \forall j \in J$

Vamos a tener los dos siguientes grupos de restricciones:

$\sum_{i \in I}peso_{i} \cdot x_{i,j} \leq capacidadEnKgMochila_{j}, \forall j \in J$
$\sum_{i \in I}peso_{i} \cdot x_{i,j} \leq capacidadEnLitrosMochila_{j}, \forall j \in J$

"

# ╔═╡ 7e093a54-aca7-4936-ade7-6276c1b17154
md"### Resolución"

# ╔═╡ a17f940e-4af9-4e50-9094-28e974907e0f
begin
	model_mochila_capacidades = Model(HiGHS.Optimizer) #

	# Dimensiones
	objetos_mmc = ["obj1", "obj2", "obj3", "obj4", "obj5", "obj6", "obj7"]
	mochilas_mmc = ["mochila1", "mochila2"]
	tipos_capacidades_mmc = ["peso", "volumen"]
	
	#Datos
	beneficios_mmc = NamedArray([2; 3; 4; 7; 6; 8; 9], objetos_mmc) 
	pesos_mmc = NamedArray([[1 2 4 6 8 12 14]
			                [1 5 4 2 3 6  8]], (tipos_capacidades_mmc, objetos_mmc)) 
	capacidad_mochila_mmc = NamedArray([[15 10]
			                            [20 15]], 
		                               (tipos_capacidades_mmc, mochilas_mmc))
	
	# Declaro las variables de decisión.
	x_mmc = @variable(model_mochila_capacidades, x_mmc[objetos_mmc, mochilas_mmc], Bin)

	# Creo la función objetivo. 
	obj_mmc = @objective(model_mochila_capacidades, Max,
		sum([beneficios_mmc[i] * x_mmc[i,j] for i in objetos_mmc for j in mochilas_mmc]))

	# Cargo las restricciones de capacidad máxima.
	r1_mmc = @constraint(model_mochila_capacidades, [j in mochilas_mmc, c in tipos_capacidades_mmc], sum([pesos_mmc[c,i] * x_mmc[i,j] for i in objetos_mmc]) <= capacidad_mochila_mmc[c,j])

	# Cargo las restricciones de un objeto en una sola mochila.
	r2_mmc = @constraint(model_mochila_capacidades, [i in objetos_mmc], sum([x_mmc[i,j] for j in mochilas_mmc]) <= 1)
	
	latex_formulation(model_mochila_capacidades)
end

# ╔═╡ e3f0ee89-520b-44a8-a207-465d8b554fa9
begin
	optimize!(model_mochila_capacidades)
	
	@show solution_summary(model_mochila_capacidades, verbose=true)
end

# ╔═╡ c1b0b169-ee90-4794-a75f-53064e3d8d4e
md"## Problema de la multi-mochila con multi-capacidades y restricciones lógicas"

# ╔═╡ dc368218-b9d4-4229-ba95-ce2750a8a38c
md"Supongamos ahora que, en el problema anterior, tenemos las siguientes restricciones lógicas:

1. El objeto 1 y el 2 no pueden ir juntos en la misma mochila.
2. Si guardo el objeto 2 en alguna mochila, no puede guardar el 3 en ninguna, y viceversa.
3. Si guardo el objeto 4 en alguna mochila, es obligatorio guardar el 5 (en la misma mochila o en otra). Sin embargo, si guardo el objeto 5, no es obligatorio guardar el 4.
4. Es obligatorio llevar el objeto 1 en alguna mochila.

Dado que nuestras variables son binarias, podemos hacer uso del hecho que solamente pueden tomar los valores $0$ y $1$ para modelar en forma _lineal_ estas restricciones:

1.
    Esta restricción la modelamos al nivel de mochila (es decir, una restricción por mochila). Dado que los dos objetos no pueden ir juntos, sabemos que las posibles asignaciones, para una mochila $j$, son:
    * No guardamos ninguno de los dos objetos en la mochila: $x_{1,j}=0$ y $x_{2,j}=0$
    * Guardamos el objeto 1 en la mochila: $x_{1,j}=1$ y $x_{2,j}=0$
    * Guardamos el objeto 2 en la mochila: $x_{1,j}=0$ y $x_{2,j}=1$

    Por otro lado, guardar los dos objetos es inválido (es decir, que $x_{1,j}=1$ y $x_{2,j}=1$ no está permitido). Estas relaciones se pueden formular mediante la siguiente inecuación: 
    
    $x_{1,j} + x_{2,j} \leq 1, \forall j \in J$

    Dado la característica binaria de las variables, vemos que la inecuación anterior se cumple para los tres primeros casos, pero resulta violada en caso de asignar los dos objetos a la misma mochila.

2.
    Dada la naturaleza binaria de las variables, esta restricción podría reexpresarse como: _las Xs que apuntan al objeto 2 y al 3 no pueden valer $1$ simultaneamente_. Es decir:
    
    $\sum_{j \in J}x{2,j} + \sum_{j \in J}x{3,j} \leq 1$

    En otras palabras: _de todas las variables que apunten a los objetos 2 y 3, solo una puede asumir el valor 1_. 

3. 
    Esta restricción la podemos modelar como:
    
    $\sum_{j \in J}x{5,j} \geq  \sum_{j \in J}x{4,j}$

    Notemos que si alguna de las variables que apuntan al objeto 4 toma el valor $1$, es obligatorio que alguna de las que apunten al objeto 5 tome el valor $1$. Pero, si todas las que apuntan al objeto 4 toman el valor $0$, todavía es posible que alguna de las que apunta al objeto 5 tome valor $1$.

4. 
    La obligatoriedad de poner el objeto 1 en alguna mochila es equivalente a decir que, si o si, algunas de las variables que apunten al objeto 1 debe valer $1$:
    
     $\sum_{j \in J}x{1,j} = 1$

"

# ╔═╡ b8443049-a490-4b59-abf3-8d2843854cca
md"### Resolución"

# ╔═╡ 24524270-29e5-471c-a5f1-8ce0d55a8c25
begin
	model_mochila_logicas = Model(HiGHS.Optimizer) #

	# Dimensiones
	objetos_mml = ["obj1", "obj2", "obj3", "obj4", "obj5", "obj6", "obj7"]
	mochilas_mml = ["mochila1", "mochila2"]
	tipos_capacidades_mml = ["peso", "volumen"]
	
	#Datos
	beneficios_mml = NamedArray([2; 3; 4; 7; 6; 8; 9], objetos_mml) 
	pesos_mml = NamedArray([[1 2 4 6 8 12 14]
			                [1 5 4 2 3 6  8]], (tipos_capacidades_mml, objetos_mml)) 
	capacidad_mochila_mml = NamedArray([[15 10]
			                            [20 15]], 
		                               (tipos_capacidades_mml, mochilas_mml))
	
	# Declaro las variables de decisión.
	x_mml = @variable(model_mochila_logicas, x_mml[objetos_mml, mochilas_mml], Bin)

	# Creo la función objetivo. 
	obj_mml = @objective(model_mochila_logicas, Max,
		sum([beneficios_mml[i] * x_mml[i,j] for i in objetos_mml for j in mochilas_mml]))

	# Cargo las restricciones de capacidad máxima.
	r1_mml = @constraint(model_mochila_logicas, [j in mochilas_mml, c in tipos_capacidades_mml], sum([pesos_mml[c,i] * x_mml[i,j] for i in objetos_mml]) <= capacidad_mochila_mml[c,j])

	# Cargo las restricciones de un objeto en una sola mochila.
	r2_mml = @constraint(model_mochila_logicas, [i in objetos_mml], sum([x_mml[i,j] for j in mochilas_mml]) <= 1)
	
	#Restricción lógica 1
	r3_mml = @constraint(model_mochila_logicas, [j in mochilas_mml], x_mml["obj1",j] + x_mml["obj2",j]  <= 1)
	
	#Restricción lógica 2
	r4_mml = @constraint(model_mochila_logicas, sum([x_mml["obj2",j] for j in mochilas_mml]) + sum([x_mml["obj3",j] for j in mochilas_mml])  <= 1)
	
	#Restricción lógica 3
	r5_mml = @constraint(model_mochila_logicas, sum([x_mml["obj5",j] for j in mochilas_mml]) >=  sum([x_mml["obj4",j] for j in mochilas_mml]))
	
	#Restricción lógica 4
	r6_mml = @constraint(model_mochila_logicas, sum([x_mml["obj1",j] for j in mochilas_mml]) == 1)
	
	latex_formulation(model_mochila_logicas)
end

# ╔═╡ 15291ed6-d2d1-4b2e-a901-dc73a608e0df
begin
	optimize!(model_mochila_logicas)
	
	@show solution_summary(model_mochila_logicas, verbose=true)
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

julia_version = "1.7.2"
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
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "2f18915445b248731ec5db4e4a17e451020bf21e"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.30"

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
# ╟─2d4017c0-da97-11ec-0bb9-2dbf19cdd9b5
# ╠═643d54ee-e08e-4de5-8733-d18704781523
# ╟─1daee18c-7dc8-44fd-9e38-3a282fdb7497
# ╠═133f42e1-fe24-4ab4-addc-2db93d9fb951
# ╟─78c3e84d-3a12-4e67-b8c3-c02fac10c0a8
# ╟─8a86499c-4cda-4299-af95-1bdce26a303c
# ╟─9f4f2144-32e0-4194-a942-3c6b36383757
# ╟─fa283a0d-5e94-4424-98b7-1ad14b1a846d
# ╟─07af090c-f8e4-470e-9326-accbd0523dbf
# ╠═e97b5cf5-0135-4b79-a35d-0afec0513c7d
# ╟─318b9749-a03a-4a0b-a4ec-273ac7f3d0be
# ╠═9529b709-4d54-4ea3-9abc-bc9a46a84a09
# ╠═c419b556-e7cd-43a2-811e-153d2cc85a2c
# ╟─42278aa8-cf77-4526-b206-8815717d0bf0
# ╟─082aa155-8f7b-49b6-a163-847dee7a2df5
# ╟─d6967ef7-fd66-4148-9e24-e4227961897f
# ╟─65a32339-88f1-49e0-81a3-02efeaac28a3
# ╟─3ee77cbd-1d2d-4e9e-95ae-ccc2878b8c34
# ╟─4932f2a8-885e-4809-880c-88d578a2bb14
# ╟─260d3f87-b56a-4185-9fef-893bf856a64d
# ╟─5c0ea276-77ba-43b0-9d1c-68badbf3889e
# ╟─f0f1fca5-ac06-4957-8fb0-82939cd26bdc
# ╠═97f624c2-43bb-4f01-9243-535763bd55a2
# ╠═21ade227-3a18-4796-bfec-fbde568097a0
# ╟─25f03233-8522-4393-9f34-3e940b41de42
# ╟─633362e2-ebc7-40f0-bafe-29b60a604a54
# ╟─7e093a54-aca7-4936-ade7-6276c1b17154
# ╠═a17f940e-4af9-4e50-9094-28e974907e0f
# ╠═e3f0ee89-520b-44a8-a207-465d8b554fa9
# ╠═c1b0b169-ee90-4794-a75f-53064e3d8d4e
# ╟─dc368218-b9d4-4229-ba95-ce2750a8a38c
# ╟─b8443049-a490-4b59-abf3-8d2843854cca
# ╠═24524270-29e5-471c-a5f1-8ce0d55a8c25
# ╠═15291ed6-d2d1-4b2e-a901-dc73a608e0df
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

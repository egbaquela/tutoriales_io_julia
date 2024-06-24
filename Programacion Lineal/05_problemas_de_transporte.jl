### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ d82cf546-8a7b-482c-9870-c1b9f84a0c24
# Cargo los paquetes a usar en el notebook y genero la tabla de contenidos
begin
	using Colors, ImageShow, FileIO, ImageIO
	using PlutoUI, JuMP, HiGHS, NamedArrays, Graphs, GraphPlot
	TableOfContents(title="Contenido")
end 

# ╔═╡ e7327140-dbab-11ec-072c-cf2db526be21
md"# Problemas de transporte y transbordo"

# ╔═╡ fbd92258-af0e-4271-912c-e6c37c881a05
md"## Problemas de transporte"

# ╔═╡ 59a4315e-3d22-4751-9cb2-2969840447a5
md"En un problema de transporte, tenemos un volumen de productos que deben ser transportados desde un conjunto de _orígenes_ a un conjunto de _destinos_ al menor costo posible. Cada $origen_{i}$ tiene asociado una cierta cantidad de producto que se debe transportar (denominada _suministro_), y cada $destino_{j}$ una cierta cantidad de producto que se debe recibir (denominada _demanda_). A su vez, cada par $(origen_{i}, destino_{j})$ lleva asociado un costo $c_{i,j}$, el cual representa el costo de transportar una unidad de producto desde $i$ a $j$. Se asume que el costo unitario es constante (si $c_{i,j}$ es el costo de transportar una unidad, $10c_{i,j}$ es el costo de transportar 10 unidades)."

# ╔═╡ 1faeb4ab-c4c0-4645-8bac-c3b390a749b8
md"### Estructura general del problema"

# ╔═╡ deadec4b-2074-4864-84a3-5cc425b24c7f
md"Una forma sencilla de entender la estructura de un problema puntual de transporte es a través de un grafo:"

# ╔═╡ 299c1ebb-7158-40a6-90bf-3f4876f971b6
begin
	#g = SimpleDiGraph();
	#add_vertex!(g);
	#add_vertex!(g);
	#add_vertex!(g);
	#add_vertex!(g);
	#add_vertex!(g);
	
	#add_edge!(g, 1, 4);
	#add_edge!(g, 2, 4);
	#add_edge!(g, 3, 4);
	#add_edge!(g, 1, 5);
	#add_edge!(g, 2, 5);
	#add_edge!(g, 3, 5);
	
	#nodelabel = ["v1"; "v2"; "v3"; "v4"; "v5"];
	#edgelabel = ["v1"; "v2"; "v3"; "v4"; "v5"; "v5"];
	#gplot(g, nodelabel=nodelabel, edgelabel=edgelabel);
	
	graph_image = load("grafo_transporte.png")
end

# ╔═╡ ce8d4ea4-bf02-4cf6-9bda-042e0b350c8d
md"Donde los nodos en gris son los _orígenes_ , los nodos naranja son los _destinos_ y los arcos indican los transportes disponibles y el correspondiente costo. El _suministro_ del _origen A_ es de 10 unidades, el del _origen B_ es de 2 unidades y el del _origen C_ es de 3 unidades. Por otra parte, los dos _destinos_ tienen una _demanda_ individual de 7 y 8 unidades respectivamente. Transportar una unidad desde _B_ hacia _D_ cuesta 30 unidades monetarias. En un problema de transporte puro, la suma de todos los _suministros_ es igual a la suma de todas las _demandas_ y desde cualquier _origen_ se puede llegar a cualquier _destino_ . No es necesario que la cantidad de _orígenes_ sean iguales a la de _destinos_ .  

Una posible solución factible sería:
* Transportar 7 unidades desde A hasta D, a un costo de 70 unidades monetarias
* Transportar 3 unidades desde A hasta E, a un costo de 60 unidades monetarias
* Transportar 2 unidades desde B hasta E, a un costo de 80 unidades monetarias
* Transportar 3 unidades desde C hasta E, a un costo de 180 unidades monetarias

La solución luciría como (sin indicar costos en arcos):"

# ╔═╡ 42af2bd1-bb99-4729-bd0f-e4c3907cdaf7
load("grafo_transporte_factible.png")

# ╔═╡ d4504b56-5a83-4b08-ac9e-3dc4ede42481
md"### Variables de decisión"

# ╔═╡ e4d02ee6-4ede-4641-84cf-59cdbfff17d2
md"Las variables aquí representan la cantidad transportada desde el origen $i$ al destino $j$. Las variables deben tomar valores enteros, pero, por la estructura de los problemas de transporte (puros) usar variables continuas genera soluciones óptimas enteras. Entonces, nuestras variables de decisión son:

$x_{i,j} \in \mathbb{R}, \ con \ i \in I \ y \ j \in J$

Donde $I$ es el conjunto de _orígenes_ y $J$ el conjunto de _destinos_ ."

# ╔═╡ 65713e01-290f-46e1-99ad-06692aae4cca
md"### Función objetivo"

# ╔═╡ ae3cc54b-d93a-4eb3-8847-41a571eacfce
md"
La función objetivo del problema es sencilla. Queremos minimizar el costo total de transporte. Si cada producto enviado desde el origen $i$ al destino $j$ tiene un costo de $c_{i,j}$, podemos expresar el objetivo de nuestro problema como:

$Min \ Z=\sum_{i \in I}\sum_{j \in J} c_{i,j}x_{i,j}$

Dado que la cantidad de variables y coeficientes de costos involucrados es igual a $||I||\cdot||J||$, una forma cómoda de presentar los costos es a través de una matriz:


$\left(\begin{array}{cccc} 
c_{1,1} & c_{1,2} & ... & c_{1,J}\\
c_{2,1} & c_{2,2} & ... & c_{2,J}\\
...     & ...     & ... & ...    \\
c_{I,1} & c_{I,2} & ... & c_{I,J}\\
\end{array}\right)$


Donde las filas son los _orígenes_ y las columnas los _destinos_.
"

# ╔═╡ d8f5edd1-9277-41fc-a2cb-9110d03527bd
md"### Restricciones"

# ╔═╡ 9061df2a-e6ad-4538-89a8-42bfacf98461
md"
Si pensamos acerca del problema de transporte, vemos que tenemos dos tipos de restricciones:

* Cada uno de los orígenes debe entregar la totalidad de su suministro.
* Cada uno de los destinos debe recibir la totalidad de su demanda

Por ejemplo, para el origen $i=1$, el primer tipo de restricción puede escribirse como:

$x_{1,1} + x_{1,2} + ... + x_{1,||J||}=suministro_{1}$

Los mismo se repite para todos los orígenes. Es decir, por cada origen tenemos una restricción en la cual se suman todas las variables que apunten a dicho origen y se iguala la suma al suministro de dicho origen. En forma compacta:

$\sum_{j \in J}x_{i,j}=suministro_{i}, \forall i \in I$

En forma análoga, para el destino $j=1$, el segundo tipo de restricción puede escribirse como:

$x_{1,1} + x_{2,1} + ... + x_{||I||,1}=demanda_{1}$

En forma compacta:

$\sum_{i \in I}x_{i,j}=demanda_{j}, \forall j \in J$

Y además, como siempre, tenemos las restricciones de no negatividad.

Es interesante explorar como queda la matriz de los coeficientes de las restricciones. Si ordenamos las variables de la forma:
$\left(\begin{array}{c}
x_{1,1} & x_{1,2} & ... & x_{1,||J||} & x_{2,1} & x_{2,2} & ... & x_{2,||J||} & ...  & ...  & ... & ... & x_{I,1} & x_{||I||,2} & ... & x_{||I||,||J||}
\end{array}\right)$

Las primeras $||I||$ filas de la matriz quedan como:

$\left(\begin{array}{cccccccccccccccc} 
1 & 1 & ... & 1 & 0 & 0 & ... & 0 & ...  & ...  & ... & ... & 0 & 0 & ... & 0 \\
0 & 0& ... & 0 & 1 & 1 & ... & 1 & ...  & ...  & ... & ... & 0 & 0 & ... & 0 \\
... & ... & ... & ... & ...  & ... & ... & ... & ...    & ... & ... & ... & ...  & ... & ... & ...   \\
0 & 0 & ... & 0 & 0 & 0 & ... & 0 & ...  & ...  & ... & ... & 1 & 1 & ... & 1 \\
\end{array}\right)$ 

Mientras que las siguientes ||J|| filas:

$\left(\begin{array}{cccccccccccccccc} 
1 & 0 & ... & 0 & 1 & 0 & ... & 0 & ...  & ...  & ... & ... & 1 & 0 & ... & 0 \\
0 & 1 & ... & 0 & 0 & 1 & ... & 0 & ...  & ...  & ... & ... & 0 & 1 & ... & 0 \\
... & ... & ... & ... & ...  & ... & ... & ... & ...    & ... & ... & ... & ...  & ... & ... & ...   \\
0 & 0 & ... & 1 & 0 & 0 & ... & 1 & ...  & ...  & ... & ... & 0 & 0 & ... & 1 \\
\end{array}\right)$ 

Entonces, la matriz completa:

$\left(\begin{array}{cccccccccccccccc} 
1 & 1 & ... & 1 & 0 & 0 & ... & 0 & ...  & ...  & ... & ... & 0 & 0 & ... & 0 \\
0 & 0& ... & 0 & 1 & 1 & ... & 1 & ...  & ...  & ... & ... & 0 & 0 & ... & 0 \\
... & ... & ... & ... & ...  & ... & ... & ... & ...    & ... & ... & ... & ...  & ... & ... & ...   \\
0 & 0 & ... & 0 & 0 & 0 & ... & 0 & ...  & ...  & ... & ... & 1 & 1 & ... & 1 \\
1 & 0 & ... & 0 & 1 & 0 & ... & 0 & ...  & ...  & ... & ... & 1 & 0 & ... & 0 \\
0 & 1 & ... & 0 & 0 & 1 & ... & 0 & ...  & ...  & ... & ... & 0 & 1 & ... & 0 \\
... & ... & ... & ... & ...  & ... & ... & ... & ...    & ... & ... & ... & ...  & ... & ... & ...   \\
0 & 0 & ... & 1 & 0 & 0 & ... & 1 & ...  & ...  & ... & ... & 0 & 0 & ... & 1 \\
\end{array}\right)$ 

"

# ╔═╡ 2ef44066-6950-4d53-8331-78ac9774af9e
md"### Problema completo"

# ╔═╡ dd89da86-ca0d-4ddd-b330-cb637b7e50d7
md"
La forma compacta del problema de asignación es:

$Min \ Z=\sum_{i \in I}\sum_{j \in J} c_{i,j}x_{i,j}$

Sujeto a:

$\sum_{j \in J}x_{i,j}=suministro_{i}, \forall i \in I$

$\sum_{i \in I}x_{i,j}=demanda_{j}, \forall j \in J$

$x_{i,j}\geq 0, \forall i \in I, \forall j\in J$ 
"

# ╔═╡ d4ee5419-e24e-4931-8089-936ab7d99e51
md"### Un ejemplo"

# ╔═╡ 781821d9-fe0c-4bae-8e2d-c156ef4dc4da
md"
>La P&T Company produce arvejas que distribuye por todo el país. Tiene 3 enlatadoras: en Rafaela (Santa Fe), en Marcos Juarez (Córdoba) y en Santa Rosa (La Pampa). Las arvejas enlatadas se envían a 4 centros de distribución, emplazados en La Plata (Buenos Aires), Viedma (Rio Negro), San Miguel (Tucumán) y Colón (Entre Rios). Se ha estimado la producción de cada planta para el próximo periodo, así como la demanda que deberán afrontar cada centro de distribución. En la siguiente tabla se proporciona dicha información (en unidades de camiones llenos) así como los costos de transportes
>

$\begin{array}{lccccc}
	\hline
	\ & \text{La Plata} & \text{Viedma} & \text{San Miguel}& \text{Colón} &\text{Producción}\\
	\text{Rafaela} & 464 & 513 & 654 & 867 & 75\\
	\text{Marcos Juarez} & 352 & 416 & 690 & 791 & 125\\
	\text{Santa Rosa} & 995 & 682 & 388 & 685 & 100\\
	\text{Demanda} & 80 & 65 & 70 & 85 & \ \\
	\hline
\end{array}$

>Determine la solución óptima.
>
>_Problema adaptado del ejemplo prototípico 8.1 del libro __Investigación de Operaciones 9na Edición__ de Hillier y Lieberman_

"

# ╔═╡ 32b12826-46f9-4b15-8351-c9e174d2ac19
md"#### Formulación"

# ╔═╡ e3ae1ca5-e6d1-4d10-8477-8eabbad8e1c7
md"
Lo primero que tenemos que controlar en un problema de transporte es que la demanda total y el suministro total estén balanceados. En este problema, tanto la demanda como el suministro total suman 300 unidades. Siendo $I=\{rafaela,marcosJuarez,santaRosa\}$ el conjunto de orígenes y $J=\{laPlata,viedma,sanMiguel,colon\}$ el conjunto de destinos, el problema se puede formular como:

$Min \ Z = 464x_{1,1} + 513x_{1, 2} + 654x_{1, 3} + 867x_{1, 4} 
       + 352x_{2,1} + 416x_{2, 2} + 690x_{2, 3} + 791x_{2, 4}
       + 995x_{3,1} + 682x_{3, 2} + 388x_{3, 3} + 685x_{3, 4}$
     
Sujeto a:

$x_{1,1} + x_{1,2} + x_{1,3} + x_{1,4}=75$

$x_{2,1} + x_{2,2} + x_{2,3} + x_{2,4}=125$

$x_{3,1} + x_{3,2} + x_{3,3} + x_{3,4}=100$

$x_{1,1} + x_{2,1} + x_{3,1}=80$

$x_{1,2} + x_{2,2} + x_{3,2}=65$

$x_{1,3} + x_{2,3} + x_{3,3}=70$

$x_{1,4} + x_{2,4} + x_{3,4}=85$

$x_{i,j}\geq 0, \forall i \in I, \forall j \in J$
"

# ╔═╡ 91a59125-025d-4421-a4a2-37a43e86614d
md"#### Resolución"

# ╔═╡ 19619817-7d9d-49a8-b491-00b20d1430ce
begin
	model_01 = Model(HiGHS.Optimizer) #

	# Dimensiones
	origenes_01 = ["rafaela", "marcosJuarez", "santaRosa"]
	destinos_01 = ["laPlata", "viedma", "sanMiguel", "colon"]
	
	# Datos
	costos_01 = NamedArray([[464 513 654 867]
							[352 416 690 791]
							[995 682 388 685]],(origenes_01, destinos_01))
	
	
	oferta_01 = NamedArray([75, 125, 100], origenes_01)
	
	demanda_01 = NamedArray([80, 65, 70, 85], destinos_01)

	# Declaro las variables de decisión.
	x_01 = @variable(model_01, x_01[origenes_01,destinos_01] >= 0)
	
	#Función objetivo
	obj_01 = @objective(model_01, Min,
		sum([sum([costos_01[i,j]*x_01[i,j] for i in origenes_01]) for j in destinos_01]))

	# Restriccion de capacidad en oferta.
	r_01 = @constraint(model_01, [i in origenes_01], sum([x_01[i,j] for j in destinos_01])  <= oferta_01[i])
	
	# Restriccion de capacidad en demanda.
	r2_01  = @constraint(model_01, [j in destinos_01], sum([x_01[i,j] for i in origenes_01])  >= demanda_01[j])
	
	latex_formulation(model_01)
end

# ╔═╡ 56982a31-2133-419c-86b5-b70f1ac49e2f
begin
	optimize!(model_01)
	
	solution_summary(model_01, verbose=true)
end

# ╔═╡ 88a62444-a4d1-4c8e-9054-12765964ac46
md"## Problemas de transbordo"

# ╔═╡ c1ebef1e-1ebd-4b0c-b8ee-479fb15a08b6
md"Los problemas de transbordo son un supertipo de los problemas de transporte (es decir, se puede considerar al problema de transporte como un caso particular del de transbordo) en el cual, a fin de transportar los productos desde los _orígenes_ a los _destinos_ , es necesario consolidar y/o desconsolidar la carga en nodos intermedios de _transbordo_ . Por ejemplo, si tenemos un conjunto de fábricas por un lado y un conjunto de puntos de venta por otro, la distribución no suele ser directa, sino que los productos son enviados desde las fábricas a centros de distribución y, desde ahí, a los puntos de venta.  "

# ╔═╡ e24d4099-2390-459f-87dc-87a19af7bdc4
md"### Estructura general del problema"

# ╔═╡ 418d141d-3f34-4649-bf26-51bc1a58e5ab
md"Una forma sencilla de entender la estructura de un problema de transbordo es mediante un grafo:"

# ╔═╡ 8a661a59-83aa-46c3-aa40-c3b7fa642eaa
load("grafo_transbordo.png")

# ╔═╡ 6cf9997f-14d6-40ba-9c35-40ba4d01c3db
md"Donde los nodos grises son _orígenes_ , los _naranjas_ son _transbordos_ y los blancos son _destinos_ . El número en los nodos indica el _suministro_ (para los _orígenes_ ), la _demanda_ (para los _destinos_ ) y la _capacidad_ (para los transobordos). El número sobre cada arco (o flecha) indica el costo de transportar una unidad de producto. Un ejemplo de asignación factible sería: 

>El _origen A_ podría enviar al centro de _transbordo D_ 7 unidades a un costo total de 70 (no puede enviar mas por las limitaciones de capacidad de _D_ ) y _D_ puede repartir 5 unidades a _F_, 1 unidad a _I_ y 1 unidad a _H_ . _H_ requeriría que que _E_ lo aprovisione con las otras 3 unidades faltantes que necesita, y _A_ necesitaría que _E_ reciba el resto de su suministro. _B_ y _C_ deberían enviar a _E_, y _G_ debería ser aprovisionado solamente por _E_.
> El costo total sería de de 1670 unidades monetarias:
> * 7 unidades desde A hasta D, a 70 unidades monetarias
> * 3 unidades desde A hasta E, a 60 unidades monetarias 
> * 2 unidades desde B hasta E, a 240 unidades monetarias
> * 3 unidades desde C hasta E, a 420 unidades monetarias
> * 5 unidades desde D hasta F, a 150 unidades monetarias
> * 1 unidad desde D hasta H, a 50 unidades monetarias
> * 1 unidad desde D hasta I, a 60 unidades monetarias
> * 5 unidades desde E hasta G, a 350 unidades monetarias
> * 3 unidades desde E hasta H, a 270 unidades monetarias
>
> Esta solución, si bien no es óptima, es factible, y luciría de esta forma (sin indicar costos en los arcos):"

# ╔═╡ ee4b4818-e343-40cd-b084-d39fbed712b7
load("grafo_transbordo_factible.png")

# ╔═╡ 0bb817a4-3552-4b9a-83f2-ff257fa82fc0
md"### Variables de decisión"

# ╔═╡ eb6a89fa-f341-4c69-98ff-35cd142e8f4f
md"
Notemos que este problema se puede interpretar como dos problemas de transporte encadenados: transportar desde los _orígenes_ a los _transbordos_ (usando la _capacidad_ a modo de _demanda_ ), y luego desde los _transbordos_ a los _destinos_ (usando la _capacidad_ a modo de _suministro_ ). Entonces, podemos definir un tipo de variable para cada _subproblema_ de transporte:

$x_{i,j} \in \mathbb{R}, \ con \ i \in I \ y \ j \in J$
$y_{j,k} \in \mathbb{R}, \ con \ j \in J \ y \ k \in K$

Donde $I$ es el conjunto de _orígenes_ , $J$ el conjunto de _transbordos_ y $K$ el conjunto de _destinos_ . Tanto $x_{i,j}$ como $y_{j,k}$ representan cantidades a transportar.
"

# ╔═╡ 8961e674-4cbd-4142-8ecd-915f5518296a
md"### Función objetivo"

# ╔═╡ 7190dc83-d751-4276-9184-570deae6f5f3
md"La función objetivo del problema es sencilla. Queremos minimizar el costo total de transporte. Si cada producto enviado desde el origen $i$ al transbordo $j$ tiene un costo de $c_{i,j}$, y cada producto enviado desde el transbordo $j$ al destino $k$ tiene costo $c_{j,k}$ podemos expresar el objetivo de nuestro problema como:

$Min \ Z=\sum_{i \in I}\sum_{j \in J} c_{i,j}x_{i,j} + \sum_{j \in J}\sum_{k \in K} c_{j,k}y_{j,k}$"

# ╔═╡ 4b6ce9e5-6c15-4ed3-9861-609496a6f2f4
md"### Restricciones"

# ╔═╡ c80bf4c3-27a1-4a03-a3ee-48243ba0e78b
md"
Si pensamos acerca del problema de transbordo, vemos que tenemos tres tipos de restricciones:

* Cada uno de los orígenes debe entregar su suministro a un nodo de transbordo.
* Cada uno de los destinos debe recibir las cantidades demandadas desde los nodos de transbordo.
* La cantidad entregada en un nodo de transbordo debe ser igual a la recibida.

Por ejemplo, para el origen $i=1$, la primera restricción puede escribirse como:

$x_{1,1} + x_{1,2} + ... + x_{1,||J||}=suministro_{1}$

Los mismo se repite para todos los orígenes. Es decir, por cada origen tenemos una restricción en la cual se suman todas las variables que apunten a dicho origen y se iguala la suma a $1$. En forma compacta:

$\sum_{j \in J}x_{i,j}=suministro_{i}, \forall i \in I$

En forma análoga, para el destino $k=1$, la segunda restricción puede escribirse como:

$y_{1,1} + y_{2,1} + ... + y_{||J||,1}=demanda_{1}$

En forma compacta:

$\sum_{j \in J}y_{j,k}=demanda_{k}, \forall k \in K$

Por último, para el nodo de transbordo $j=1$:

$x_{1,1} + x_{2,1} + ... + x_{||I||,1} = y_{1,1} + y_{1,2} + ... + y_{1,||K||}$

En forma compacta:

$\sum_{i \in I}x_{i,j}=\sum_{k \in K}y_{j,k}, \forall j \in J$

Si los nodos de transbordo tuvieran capacidad asociada (por ejemplo, cuando pueden transbordar en el periodo de tiempo analizado), es cuestión de agregar una restricción adicional por nodo de transbordo acotando las entradas máximas (o las salidas máximas) a dicho valor. Para el nodo $j=1$:

$x_{1,1} + x_{2,1} + ... + x_{||I||,1} = capacidad_{j}$

En forma compacta:

$\sum_{i \in I}x_{i,j}=capacidad_{j}, \forall j \in J$


Y además, como siempre, tenemos las restricciones de no negatividad.

"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
GraphPlot = "a2cc645c-3eea-5389-862e-a155d0052231"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
ImageIO = "82e4d734-157c-48bb-816b-45c225c6df19"
ImageShow = "4e3cecfd-b093-5904-9786-8bbb286a6a31"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Colors = "~0.12.10"
FileIO = "~1.16.0"
GraphPlot = "~0.5.2"
Graphs = "~1.8.0"
HiGHS = "~1.5.1"
ImageIO = "~0.6.6"
ImageShow = "~0.3.7"
JuMP = "~1.10.0"
NamedArrays = "~0.9.8"
PlutoUI = "~0.7.50"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "f57801fd0192a2756d6fb3f3270aefaef055cd0e"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "16b6dbc4cf7caee4e1e75c49485ec67b667098a0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.3.1"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "cc37d689f599e8df4f464b2fa3870ff7db7492ef"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.6.1"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "1dd4d9f5beebac0c03446918741b1a03dc5e5788"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.6"

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

[[deps.CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

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

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random", "SnoopPrecompile"]
git-tree-sha1 = "aa3edc8f8dea6cbfa176ee12f7c2fc82f0608ed3"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.20.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "600cc5508d66b78aae350f7accdb58763ac18589"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.10"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

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

[[deps.Compose]]
deps = ["Base64", "Colors", "DataStructures", "Dates", "IterTools", "JSON", "LinearAlgebra", "Measures", "Printf", "Random", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "bf6570a34c850f99407b494757f5d7ad233a7257"
uuid = "a81c6b42-2e10-5240-aca2-a61377ecd94b"
version = "0.9.5"

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

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "7be5f99f7d15578798f338f5433b6c432ea8037b"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.0"

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

[[deps.GraphPlot]]
deps = ["ArnoldiMethod", "ColorTypes", "Colors", "Compose", "DelimitedFiles", "Graphs", "LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "5cd479730a0cb01f880eff119e9803c13f214cab"
uuid = "a2cc645c-3eea-5389-862e-a155d0052231"
version = "0.5.2"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "d61890399bc535850c4bf08e4e0d3a7ad0f21cbd"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.2"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "1cf1d7dcb4bc32d7b4a5add4232db3750c27ecb4"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.8.0"

[[deps.HiGHS]]
deps = ["HiGHS_jll", "MathOptInterface", "SnoopPrecompile", "SparseArrays"]
git-tree-sha1 = "08535862ef6d42a01ffcaaf6507cfb8a0fe329a6"
uuid = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
version = "1.5.1"

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

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "c54b581a83008dc7f292e205f4c409ab5caa0f04"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.10"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "b51bb8cae22c66d0f6357e3bcb6363145ef20835"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.5"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "acf614720ef026d38400b3817614c45882d75500"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.4"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "342f789fd041a55166764c351da1710db97ce0e0"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.6"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "36cbaebed194b292590cba2593da27b34763804a"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.8"

[[deps.ImageShow]]
deps = ["Base64", "ColorSchemes", "FileIO", "ImageBase", "ImageCore", "OffsetArrays", "StackViews"]
git-tree-sha1 = "ce28c68c900eed3cdbfa418be66ed053e54d4f56"
uuid = "4e3cecfd-b093-5904-9786-8bbb286a6a31"
version = "0.3.7"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3d09a9f60edf77f8a4d99f9e015e8fbf9989605d"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.7+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "5cd07aab533df5170988219191dfad0519391428"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.3"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IntervalSets]]
deps = ["Dates", "Random", "Statistics"]
git-tree-sha1 = "16c0cc91853084cb5f58a78bd209513900206ce6"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.4"

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

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "106b6aa272f294ba47e96bd3acbabdc0407b5c60"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.2"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6f2675ef130a300a112286de91973805fcc5ffbc"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.91+0"

[[deps.JuMP]]
deps = ["LinearAlgebra", "MathOptInterface", "MutableArithmetics", "OrderedCollections", "Printf", "SnoopPrecompile", "SparseArrays"]
git-tree-sha1 = "4ec0e68fecbbe1b78db2ddf1ac573963ed5adebc"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.10.0"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

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

[[deps.MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SnoopPrecompile", "SparseArrays", "SpecialFunctions", "Test", "Unicode"]
git-tree-sha1 = "58a367388e1b068104fa421cb34f0e6ee6316a26"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.14.1"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

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
git-tree-sha1 = "b84e17976a40cb2bfe3ae7edb3673a8c630d4f95"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.8"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "5ae7ca23e13855b3aba94550f26146c01d259267"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "82d7c9e310fe55aa54996e6f7f94674e2a38fcb4"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.9"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "a4ca623df1ae99d09bc9868b008262d0c0ac1e4f"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.4+0"

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
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "f809158b27eba0c18c269cf2a2be6ed751d3e81d"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.3.17"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "478ac6c952fddd4399e71d4779797c538d0ff2bf"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.8"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f6cf8e7944e50901594838951729a1861e668cb8"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.2"

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

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "d7a7aef8f8f2d537104f170139553b14dfe39fe9"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.2"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

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

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "8fb59825be681d451c246a795117f317ecbcaa28"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.2"

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

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "63e84b7fdf5021026d0f17f76af7c57772313d99"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.21"

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

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "8621f5c499a8aa4aa970b1ae381aae0ef1576966"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.6.4"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "0b829474fed270a4b0ab07117dce9b9a2fa7581a"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.12"

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

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "libpng_jll"]
git-tree-sha1 = "d4f63314c8aa1e48cd22aa0c17ed76cd1ae48c3c"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.3+0"

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
# ╟─e7327140-dbab-11ec-072c-cf2db526be21
# ╠═d82cf546-8a7b-482c-9870-c1b9f84a0c24
# ╟─fbd92258-af0e-4271-912c-e6c37c881a05
# ╟─59a4315e-3d22-4751-9cb2-2969840447a5
# ╟─1faeb4ab-c4c0-4645-8bac-c3b390a749b8
# ╟─deadec4b-2074-4864-84a3-5cc425b24c7f
# ╟─299c1ebb-7158-40a6-90bf-3f4876f971b6
# ╟─ce8d4ea4-bf02-4cf6-9bda-042e0b350c8d
# ╟─42af2bd1-bb99-4729-bd0f-e4c3907cdaf7
# ╟─d4504b56-5a83-4b08-ac9e-3dc4ede42481
# ╟─e4d02ee6-4ede-4641-84cf-59cdbfff17d2
# ╟─65713e01-290f-46e1-99ad-06692aae4cca
# ╟─ae3cc54b-d93a-4eb3-8847-41a571eacfce
# ╟─d8f5edd1-9277-41fc-a2cb-9110d03527bd
# ╟─9061df2a-e6ad-4538-89a8-42bfacf98461
# ╟─2ef44066-6950-4d53-8331-78ac9774af9e
# ╟─dd89da86-ca0d-4ddd-b330-cb637b7e50d7
# ╟─d4ee5419-e24e-4931-8089-936ab7d99e51
# ╟─781821d9-fe0c-4bae-8e2d-c156ef4dc4da
# ╟─32b12826-46f9-4b15-8351-c9e174d2ac19
# ╟─e3ae1ca5-e6d1-4d10-8477-8eabbad8e1c7
# ╟─91a59125-025d-4421-a4a2-37a43e86614d
# ╠═19619817-7d9d-49a8-b491-00b20d1430ce
# ╠═56982a31-2133-419c-86b5-b70f1ac49e2f
# ╟─88a62444-a4d1-4c8e-9054-12765964ac46
# ╟─c1ebef1e-1ebd-4b0c-b8ee-479fb15a08b6
# ╟─e24d4099-2390-459f-87dc-87a19af7bdc4
# ╟─418d141d-3f34-4649-bf26-51bc1a58e5ab
# ╟─8a661a59-83aa-46c3-aa40-c3b7fa642eaa
# ╟─6cf9997f-14d6-40ba-9c35-40ba4d01c3db
# ╟─ee4b4818-e343-40cd-b084-d39fbed712b7
# ╟─0bb817a4-3552-4b9a-83f2-ff257fa82fc0
# ╟─eb6a89fa-f341-4c69-98ff-35cd142e8f4f
# ╟─8961e674-4cbd-4142-8ecd-915f5518296a
# ╟─7190dc83-d751-4276-9184-570deae6f5f3
# ╟─4b6ce9e5-6c15-4ed3-9861-609496a6f2f4
# ╟─c80bf4c3-27a1-4a03-a3ee-48243ba0e78b
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

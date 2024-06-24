### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 643d54ee-e08e-4de5-8733-d18704781523
# Cargo los paquetes a usar en el notebook y genero la tabla de contenidos
begin
	using PlutoUI, JuMP, HiGHS, NamedArrays
	TableOfContents(title="Contenido")
end 

# ╔═╡ 2d4017c0-da97-11ec-0bb9-2dbf19cdd9b5
md"# Mas problemas de Programación Lineal"

# ╔═╡ 1daee18c-7dc8-44fd-9e38-3a282fdb7497
md"## Armado de lotes de productos"

# ╔═╡ 133f42e1-fe24-4ab4-addc-2db93d9fb951
md"
> _Babies & Co_ es un local de ropa para chicos que está liquidando productos por el fin de temporada. Tiene que liquidar 300 bodies, 200 pantalones y 100 remeras, todos para bebé. Está pensando en armar combos, de los cuales, los mas _vendibles_ serían los siguientes:
>
> * Combo 1: 1 body, 1 remera y 1 pantalón. 
> * Combo 2: 1 remera y 1 pantalon.
> * Combo 3: 2 remeras y 1 pantalon.
> * Combo 4: 2 bodies y 1 pantalon.
>
> La contribución marginal de cada combo es, respectivamente, 35, 15, 25 y 45. Definir cuantos combos de cada tipo se deberían ofrecer para maximizar la contribución total.
"

# ╔═╡ 78c3e84d-3a12-4e67-b8c3-c02fac10c0a8
md"### Objetivos y variables de decisión"

# ╔═╡ 8a86499c-4cda-4299-af95-1bdce26a303c
md"
Las variables de decisión en este problema son la cantidad de combos de cada tipo a ofrecer. Si $P=\{combo1, combo2, combo3, combo4\}$, ponemos definir a nuestras variables de decisión como:

$x_{i} \in \mathbb{R}, \ con \ i \in P$

Y, si la contribución marginal de cada combo se denomina como $cm_{i}$, la función objetivo queda como:

$Max \ Z=\sum_{i \in P}cm_{i}x_{i}$
"

# ╔═╡ 9f4f2144-32e0-4194-a942-3c6b36383757
md"### Restricciones"

# ╔═╡ fa283a0d-5e94-4424-98b7-1ad14b1a846d
md"
Las restricciones aquí se refieren a que, al armar los combos, no puedo usar mas cantidades de remeras, bodies y pantalones de las disponibles. Entonces, si $S=\{body, remera, pantalon\}$ es el conjunto de prendas con las cuales pueden armarse combos, y $std_{i,j}$ es la cantidad de prendas $j$ en el combo $i$, nuestras tres restricciones quedan como:

$\sum_{i \in P}std_{i,j}x_{i} \leq CantidadDisponible_{j}, \forall j \in S$

Además, tenemos las restricciones de no negatividad.
"

# ╔═╡ 07af090c-f8e4-470e-9326-accbd0523dbf
md"### Problema completo"

# ╔═╡ e97b5cf5-0135-4b79-a35d-0afec0513c7d
md"
El problema completo, en forma compacta, es el siguiente:

$Max \ Z=\sum_{i \in P}cm_{i}x_{i}$

Sujeto a:

$\sum_{i \in P}std_{i,j}x_{i} \leq CantidadDisponible_{j}, \forall j \in S$

$x_{i}\geq 0, \forall i \in P$

Y, en forma extensa:

$Max \ Z=35x_{combo1} + 15x_{combo2} + 25x_{combo3} + 45x_{combo4}$

Sujeto a:

$x_{combo1} + 0x_{combo2} + 0x_{combo3} + 2x_{combo4} \leq 300$

$x_{combo1} + x_{combo2} + 2x_{combo3} + 0x_{combo4} \leq 100$

$x_{combo1} + x_{combo2} + x_{combo3} + x_{combo4} \leq 200$

$x_{combo1} \geq 0$

$x_{combo2} \geq 0$

$x_{combo3} \geq 0$

$x_{combo4} \geq 0$
"

# ╔═╡ 318b9749-a03a-4a0b-a4ec-273ac7f3d0be
md"### Resolución"

# ╔═╡ 9529b709-4d54-4ea3-9abc-bc9a46a84a09
begin
	model_lotes = Model(HiGHS.Optimizer) #

	# Datos
	combos_ml = ["Combo 1"; "Combo 2"; "Combo 3"; "Combo 4"]
	productos_ml = ["body"; "remera"; "pantalón"]
	cant_max_productos_ml = NamedArray([300; 100; 200], productos_ml) 
	contribucion_ml = NamedArray([35; 15; 25; 45], combos_ml)
	composicion_combos_ml = NamedArray([[1 0 0 2]
		                                [1 1 2 0]
	                                    [1 1 1 1]], (productos_ml, combos_ml))
	
	# Declaro las variables de decisión.
	x_ml = @variable(model_lotes, x_ml[combos_ml] >= 0)

	# Creo la función objetivo. Noten que, como las variables están definidas en base a índices no numéricos, tengo que calcular el sumaproducto explícitamente, no puedo utilizar el producto matricial.
	obj_ml = @objective(model_lotes, Max,
		sum([contribucion_ml[i] * x_ml[i] for i in combos_ml]))

	# Cargo las restricciones de capacidad máxima. El bloque '[j in productos]' indica que hay tantas restricciones como productos
	r1_ml = @constraint(model_lotes, [j in productos_ml], sum([composicion_combos_ml[j, i] * x_ml[i] for i in combos_ml]) <= cant_max_productos_ml[j])

	Text(model_lotes)
end

# ╔═╡ c419b556-e7cd-43a2-811e-153d2cc85a2c
begin
	optimize!(model_lotes)
	
	@show solution_summary(model_lotes, verbose=true)
end

# ╔═╡ 531a4cd4-3da9-4d5a-9e9a-ec5d259035ab
md"## Problema de mezcla"

# ╔═╡ 72ff5417-db9c-4deb-a8e5-c87e1995cb8a
md"
Un problema de mezcla es un tipo de problema en el cual se deben combinar componentes, o materia prima, para lograr un producto final que cumpla con ciertas especificaciones de calidad al menor costo posible. Por ejemplo:

> En una granja de cerdos se data una dieta balanceada para criarlos de manera equilibrada. 
> Para una buena alimentación, se requiere consumir al menos 100 gramos del nutriente A,
> 150 del nutriente B y 50 del nutriente C.
>
> En el mercado hay tres tipos de alimentos. El alimento 1 proporciona 50 gramos de nutriente A
> y 50 de nutriente B por cada kilogramo. El alimento 2 proporciona 80 gramos de nutriente A y
> 30 gramos de nutriente C por cada kilogramo. Y el alimento 3 proporciona 10 gramos de nutriente A,
> 20 gramos de nutriente B y 30 gramos de nutriente C por cada kilogramo.
>
> El alimento 1 cuesta 10, el alimento 2 cuesta 8, y el alimento 3 cuesta 4. ¿Que cantidades de cada 
> de alimento se deben comprar para minimizar el costo?
"

# ╔═╡ f4d3ad25-1bd6-4c81-b51b-d0df4c9dc268
md"### Objetivos y variables de decisión"

# ╔═╡ d2004884-9f06-4d31-9592-007b890b4030
md"
Las variables de decisión en este problema son la cantidad de cada tipo de alimento a comprar. Si $P=\{alimento1, alimento2, alimento3\}$, ponemos definir a nuestras variables de decisión como:

$x_{i} \in \mathbb{R}, \ con \ $i \in P$

Donde $x_{i}$ es la cantidad de kilogramos del alimento $i$.

Si el costo de cada alimento se denomina como $c_{i}$, la función objetivo queda como:

$Min \ Z=\sum_{i \in P}c_{i}x_{i}$
"

# ╔═╡ 2f5fb158-50fb-4267-ac3d-10bda44135c0
md"### Restricciones"

# ╔═╡ 7f3f61ce-dc25-454c-adca-e8a822e6ff41
md"
Las restricciones aquí se refieren a que, al mezclar los tres alimentos, se deben superar las necesidades mínimas de nutrientes. Entonces, si $S=\{nutrienteA, nutrienteB, nutrienteC\}$ es el conjunto de nutrientes, y $std_{i,j}$ es la cantidad de gramos de nutriente $j$ que aporta cada kilogramo de alimento $i$, nuestras tres restricciones (una por cada nutriente) quedan como:

$\sum_{i \in P}std_{i,j}x_{i} \geq CantidadMinima_{j}, \forall j \in S$

Además, tenemos las restricciones de no negatividad.
"

# ╔═╡ 2286e7c3-e3a2-43b6-99fc-03e14d5d4e03
md"### Problema completo"

# ╔═╡ 704ee15d-2fdd-476f-8071-fcbe6f0bcc56
md"
El problema completo, en forma compacta, es el siguiente:

$Min \ Z=\sum_{i \in P}c_{i}x_{i}$

Sujeto a:

$\sum_{i \in P}std_{i,j}x_{i} \geq CantidadMinima_{j}, \forall j \in S$

$x_{i}\geq 0, \forall i \in P$

Y, en forma extensa:

$Min \ Z=10x_{alimento1} + 8x_{alimento2} + 4x_{alimento3}$

Sujeto a:

$50x_{alimento1} + 80x_{alimento2} + 10x_{alimento3} \geq 100$

$50x_{alimento1} + 0x_{alimento2} + 20x_{alimento3} \geq 150$

$0x_{alimento1} + 30x_{alimento2} + 30x_{alimento3} \geq 50$

$x_{alimento1} \geq 0$

$x_{alimento2} \geq 0$

$x_{alimento3} \geq 0$
"

# ╔═╡ 24df0a9e-7acc-4c0e-a70e-2292a75383ce
md"### Resolución"

# ╔═╡ a5567a1e-848d-4402-af3e-e2815513e723
begin
	model_mezcla = Model(HiGHS.Optimizer)

	# Datos
	alimentos_mm = ["Alimento 1"; "Alimento 2"; "Alimento 3"]
	nutrientes_mm = ["Nutriente A"; "Nutriente B"; "Nutriente C"]
	cant_min_nutrientes_mm = NamedArray([100; 150; 50], nutrientes_mm) 
	costo_mm = NamedArray([10; 8; 4], alimentos_mm)
	aporte_de_nutrientes_mm = NamedArray([[50 80 10]
		                                 [50 0 20]
	                                     [0 30 30]], (nutrientes_mm, alimentos_mm))
	
	# Declaro las variables de decisión.
	x_mm = @variable(model_mezcla, x_mm[alimentos_mm] >= 0)

	# Creo la función objetivo. Noten que, como las variables están definidas en base a índices no numéricos, tengo que calcular el sumaproducto explícitamente, no puedo utilizar el producto matricial.
	obj_mm = @objective(model_mezcla, Min,
		sum([costo_mm[i] * x_mm[i] for i in alimentos_mm]))

	# Cargo las restricciones de capacidad máxima. El bloque '[j in nutrientes_mm]' indica que hay tantas restricciones como nutrientes
	r1_mm = @constraint(model_mezcla, [j in nutrientes_mm], sum([aporte_de_nutrientes_mm[j, i] * x_mm[i] for i in alimentos_mm]) >= cant_min_nutrientes_mm[j])

	Text(model_mezcla)
end

# ╔═╡ d968e11b-7035-4851-b138-c0d2c093869c
begin
	optimize!(model_mezcla)
	
	@show solution_summary(model_mezcla, verbose=true)
end

# ╔═╡ 4461ce74-9a0f-4bf5-96ae-c88e165e9704
md"## Problema de multimezcla"

# ╔═╡ 1d7324e1-0b28-46c1-b51a-e6c564a7d0a6
md"
Un problema de multimezcla es básicamente un problema de mezcla en el cual se deben fabricar mas de un producto. Por ejemplo, el problema 2 de la cartilla de ejercicios:

> Una refinería de petróleo produce dos tipos de nafta sin plomo: super y premium, los cuales vende a su cadena de estaciones de servicio a 12 y 14 por barril, respectivamente. Ambos tipos se preparan del inventario de petróleo nacional refinado y de petróleo importado refinado que tiene la refinería y deben cumplir las especificaciones que se presentan en la siguiente tabla:
>

$\begin{array}{lcccc}
	\hline
	\text{Producto} & \text{Presión máx. vapor} & \text{Octanaje mín}& \text{Demanda máxima} &\text{Entregas mínimas}\\
	\hline
	\text{Super} & 23 & 88 & 100000 & 50000\\
	\text{Premium} & 24 & 93 & 20000 & 5000\\
	\hline
\end{array}$

> Las características de los inventarios de petróleo refinado son las siguientes:

$\begin{array}{lcccc}
	\hline
	\text{Petroleo} & \text{Presión vapor media} & \text{Octanaje medio}& \text{Stock} &\text{Costo unitario}\\
	\hline
	\text{Nacional} & 25 & 87 & 45000 & 8\\
	\text{Importado} & 15 & 98 & 60000 & 15\\
	\hline
\end{array}$

> Definir un programa de producción que permita maximizar la ganancia. Determinar cuál es la utilización de cada estación de trabajo, y cual actúa a modo de cuello de botella.
"

# ╔═╡ 70a72379-ee2a-48d3-9e67-627168a8bdf0
md"### Objetivos y variables de decisión"

# ╔═╡ 8ca5a37a-02ad-4726-99e0-5dfe7adf3dde
md"
Las variables de decisión en este problema no son ni la cantidad de cada tipo de petroleo a utilizar, ni la cantidad de nafta a producir. Las variables son un combinación de estas dos dimensiones. Si $P=\{nacional, importado\}$ y $N=\{super, premium\}$, ponemos definir a nuestras variables de decisión como:

$x_{i,j} \in \mathbb{R}, \ con \ i \in N \ y \ j \in P$

Donde $x_{i,j}$ es la cantidad barriles de nafta del tipo $i$ fabricados con petroleo del tipo $j$.

Si el costo de cada tipo de petroleo se denomina como $c_{j}$ y el precio de venta de cada nafta como $pv_{i}$, la función objetivo queda como:

$Max \ Z=\sum_{i \in N}\sum_{j \in P}(pv_{i}-c_{j})x_{i,j}$

Expandiendolo un poco:

$Max \ Z=(pv_{super}-c_{nacional})x_{super,nacional} 
+ (pv_{super}-c_{importado})x_{super,importado} 
+ (pv_{premium}-c_{nacional})x_{premiun,nacional} 
+ (pv_{premium}-c_{importado})x_{premiun,importado}$
"

# ╔═╡ 9872cb49-c360-48df-a725-f9c8a7ceba60
md"### Restricciones"

# ╔═╡ 8dcb4543-411d-40ab-b073-7620eec8fdb6
md"
En este problema, tenemos varios tipos de restricciones. Por un lado, las cantidades a fabricar de cada producto deben están acotadas por las entregas mínimas requeridas y la demanda máxima. Para el caso de las entregas mínimas:

$\sum_{j \in P}x_{i,j} \geq EntregaMinima_{i}, \forall i \in N$

Por ejemplo, en el caso de la nafta super ($i=super$) la restrición queda como:

$x_{super, nacional} + x_{super, importado} \geq EntregaMinima_{super}$

Similar estructura tienen las restricciones asociadas a la demanda máxima:

$\sum_{j \in P}x_{i,j} \leq DemandaMaxima_{i}, \forall i \in N$

Para el caso de las cantidades de barriles de petroleo disponibles, la estructura es similar, pero en vez de tener una restricción por cada tipo de producto, tenemos una por cada tipo de materia prima. Y la sumatoria se hace sobre todos los productos:

$\sum_{i \in N}x_{i,j} \leq BarrilesEnStock_{j}, \forall j \in P$

Lo cual, para el caso del petroleo naciona ($j=nacional$) se convierte en:

$x_{super, nacional} + x_{premium, nacional} \leq BarrilesEnStock_{nacional}$

Luego nos quedan las restricciones que hacen a la calidad del producto. La regla genérica que hay que usar para calcular el valor final de una propiedad intensiva en una mezcla de componentes es la siguiente:


$valorFinal = \frac{\sum_{t} aporteDelComponente_{t} \cdot cantidadDelComponente_{t}}{\sum_{t}cantidadDelComponente_{t}}$

Es decir, es un promedio ponderado. Para el caso de la presión máxima de vapor, siendo $pa_{j}$ la presión de vapor aportada por el petroleo del tipo $j$:

$\frac{\sum_{j \in P} pa_{j}x_{i,j}}{\sum_{j \in P}x_{i,j}} \leq PresionMaxima_{i}, \forall i \in N$

Para el octanaje, siendo $oa_{j}$ el octanaje aportado por el petroleo del tipo $j$:

$\frac{\sum_{j \in P} oa_{j}x_{i,j}}{\sum_{j \in P}x_{i,j}} \geq OctanajeMaximo_{i}, \forall i \in N$

Estos dos últimos tipo de restricciones no son lineales, pero se pueden linealizar pasando el denominador multiplicando y reagrupando en el lado izquierdo:

$\sum_{j \in P} pa_{j}x_{i,j} - PresionMaxima_{i}\sum_{j \in P}x_{i,j} \leq 0, \forall i \in N$

$\sum_{j \in P} oa_{j}x_{i,j} - OctanajeMinimo_{i}\sum_{j \in P}x_{i,j} \geq 0, \forall i \in N$

Las cuales, reordenando, se convierten en:

$\sum_{j \in P} (pa_{j} - PresionMaxima_{i})x_{i,j} \leq 0, \forall i \in N$

$\sum_{j \in P} (oa_{j}- OctanajeMinimo_{i})x_{i,j} \geq 0, \forall i \in N$

Además, tenemos las restricciones de no negatividad.
"

# ╔═╡ 4279eeb2-e28f-4530-8b86-b7c0422931ac
md"### Problema completo"

# ╔═╡ a0436ccc-d43e-43f0-b653-18fc76a85789
md"
El problema completo, en forma compacta, es el siguiente:

$Max \ Z=\sum_{i \in N}\sum_{j \in P}(pv_{i}-c_{j})x_{i,j}$

Sujeto a:

$\sum_{j \in P}x_{i,j} \geq EntregaMinima_{i}, \forall i \in N$

$\sum_{j \in P}x_{i,j} \leq DemandaMaxima_{i}, \forall i \in N$

$\sum_{i \in N}x_{i,j} \leq BarrilesEnStock_{j}, \forall j \in P$

$\sum_{j \in P} (pa_{j} - PresionMaxima_{i})x_{i,j} \leq 0, \forall i \in N$

$\sum_{j \in P} (oa_{j}- OctanajeMinimo_{i})x_{i,j} \geq 0, \forall i \in N$

$x_{i,j}\geq 0, \forall i \in N, \forall j \in P$

Y, en forma extensa:

$Max \ Z=(12-8)x_{super,nacional} 
+ (12-15)x_{super,importado} 
+ (14-8)x_{premium,nacional} 
+ (14-15)x_{premium,importado}$

Sujeto a:

$x_{super, nacional} + x_{super, importado} \geq 50000$

$x_{premium, nacional} + x_{premium, importado} \geq 5000$

$x_{super, nacional} + x_{super, importado} \leq 100000$

$x_{premium, nacional} + x_{premium, importado} \leq 20000$

$x_{super, nacional} + x_{premium, nacional} \leq 45000$

$x_{super, importado} + x_{premium, importado} \leq 60000$

$(25 - 23)x_{super,nacional} + (15 - 23)x_{super,importado} \leq 0$

$(25 - 24)x_{premium,nacional} + (15 - 24)x_{premium,importado} \leq 0$

$(87 - 88)x_{super,nacional} + (98 - 88)x_{super,importado} \geq 0$

$(87 - 93)x_{premium,nacional} + (98 - 93)x_{premium,importado} \geq 0$

$x_{super,nacional} \geq 0$

$x_{super,importado} \geq 0$

$x_{premium,nacional} \geq 0$

$x_{premium,importado} \geq 0$
"

# ╔═╡ 29b1bd2a-3c35-4f17-980f-723ac6e139fb
md"### Resolución"

# ╔═╡ 403f9a9f-b245-4c93-9a3d-8839857a3075
begin
	model_naftas = Model(HiGHS.Optimizer)

	# Datos
	productos_mn = ["Nafta Super"; "Nafta Premium"]
	materias_primas_mn = ["Petroleo Nacional"; "Petroleo Importado"]
	
	demanda_maxima_mn = NamedArray([100000; 20000], productos_mn)
	demanda_minima_mn = NamedArray([50000; 5000], productos_mn)
	presion_vapor_maxima_mn = NamedArray([23; 24], productos_mn)
	octanaje_minimo_mn = NamedArray([88; 93], productos_mn)
	precio_venta_unitario_mn = NamedArray([12; 14], productos_mn)
	
	presion_vapor_media_mn = NamedArray([25; 15], materias_primas_mn)
	octanaje_medio_mn = NamedArray([87; 98], materias_primas_mn)
	stock_mn = NamedArray([45000; 60000], materias_primas_mn)
	costo_unitario_mn = NamedArray([8; 15], materias_primas_mn)
	
	# Declaro las variables de decisión.
	x_mn = @variable(model_naftas, x_mn[productos_mn, materias_primas_mn] >= 0) # Variables con dos subindices: producto y materia prima

	# Creo la función objetivo. Noten que, como las variables están definidas en base a índices no numéricos, tengo que calcular el sumaproducto explícitamente. Además, noten el doble 'for' para representar la doble sumatoria.
	obj_mn = @objective(model_naftas, Max,
		sum([(precio_venta_unitario_mn[i] - costo_unitario_mn[j]) * x_mn[i,j] for i in productos_mn for j in materias_primas_mn]))

	# Cargo las restricciones relativas a la cantidad a producir: 
	rdemanda_maxima_mn = @constraint(model_naftas, [i in productos_mn],  sum(x_mn[i,j] for j in materias_primas_mn) <= demanda_maxima_mn[i])
	
	rdemanda_minima_mn = @constraint(model_naftas, [i in productos_mn],  sum(x_mn[i,j] for j in materias_primas_mn) >= demanda_minima_mn[i])
	
	# Cargo las restricciones relativas a la cantidad de materia prima a consumir: 
	rconsumo_maximo_mn = @constraint(model_naftas, [j in materias_primas_mn],  sum(x_mn[i,j] for i in productos_mn) <= stock_mn[j])

	# Cargo las restricciones relativas a la presión de vapor máxima: 
	rpresion_vapor_max_mn = @constraint(model_naftas, [i in productos_mn],  sum(presion_vapor_media_mn[j] * x_mn[i,j] for j in materias_primas_mn) <= presion_vapor_maxima_mn[i] * sum(x_mn[i,j] for j in materias_primas_mn))

	# Cargo las restricciones relativas al octanaje mínimo: 
	roctanaje_min_mn = @constraint(model_naftas, [i in productos_mn],  sum(octanaje_medio_mn[j] * x_mn[i,j] for j in materias_primas_mn) >= octanaje_minimo_mn[i] * sum(x_mn[i,j] for j in materias_primas_mn))
	
	Text(model_naftas)
end

# ╔═╡ d523f4d1-99ad-40c8-80b5-e299201e9e8d
begin
	optimize!(model_naftas)
	
	@show solution_summary(model_naftas, verbose=true)
end

# ╔═╡ cad78b36-7808-4810-9863-8238ab977b3d
md"## Armado de cartera de inversión"

# ╔═╡ e6153c92-4c96-4286-b7d1-9365432f59df
md"
> Un inversionista dispone de 200.000 pesos para invertir en fondos de inversión. Dispone de 4 fondos:
>
> * Fondo 1: bajo riesgo, 2% de interes anual
> * Fondo 2: riesgo medio, 4% de interes anual
> * Fondo 3: riesgo alto, 8% de interes anual
> * Fondo 4: riesgo muy alto, 12% de interes anual
>
> Como es bastante conservador, quiere que al menos la mitad de sus inversiones vayan al Fondo 1, y que no mas de 20.000 pesos vayan al Fondo 4. Además, quiere que la cantidad invertida en el Fondo 3 sea la mitad o menos que la del Fondo 2. 
> Definir la cartera de inversión óptimo.
"

# ╔═╡ 66be6b57-5713-4b63-a364-444c1d2c8acf
md"### Problema completo"

# ╔═╡ e2115829-2835-4226-bca8-45a5104b5139
md"
A la luz de los problemas anteriores, la formulación de este problema es bastante sencilla. Siendo $X_{i} \in \mathbb{R}$ con $i=1..4$ la cantidad de dinero invertida en cada fondo, el problema se puede expresar como: 

$Max \ Z=\sum_{i=1}^{4}rendimiento_{i}x_{i}$

Sujeto a:

$\sum_{i=1}^{4}x_{i} \leq dineroTotalDisponible$

$x_{1} \geq 0.5\cdot dineroTotalDisponible$

$x_{4} \leq cantidadMaximaEnF4$

$-0.5x_{2} + x_{3} \leq 0$

$x_{i} \geq 0, \forall i=1..4$
"

# ╔═╡ 8b7a969d-5a58-440b-aed9-ae057552003a
md"### Resolución"

# ╔═╡ a55447f4-5b52-4aaa-af56-0f0cb9e751f4
begin
	model_porfolio = Model(HiGHS.Optimizer)

	# Datos
	fondos_mp = ["Fondo 1"; "Fondo 2"; "Fondo 3"; "Fondo 4"]
	dinero_disp_mp = 200000
	cant_maxima_titulo_4_mp = 20000
	porcentaje_fondo_1_mp = 0.5
	rendimiento_mp = NamedArray([0.02; 0.04; 0.08; 0.12], fondos_mp)
	
	# Declaro las variables de decisión.
	x_mp = @variable(model_porfolio, x_mp[fondos_mp] >= 0)

	# Creo la función objetivo. Noten que, como las variables están definidas en base a índices no numéricos, tengo que calcular el sumaproducto explícitamente, no puedo utilizar el producto matricial.
	obj_mp = @objective(model_porfolio, Max,
		sum([rendimiento_mp[i] * x_mp[i] for i in fondos_mp]))

	# Cargo las restricciones. 
	r1_mp = @constraint(model_porfolio, sum(x_mp) <= dinero_disp_mp)
	r2_mp = @constraint(model_porfolio, x_mp["Fondo 1"] >= dinero_disp_mp)
	r3_mp = @constraint(model_porfolio, x_mp["Fondo 4"] <= cant_maxima_titulo_4_mp)
	r4_mp = @constraint(model_porfolio, x_mp["Fondo 3"] <= 0.5*x_mp["Fondo 2"])

	Text(model_porfolio)
end

# ╔═╡ cf43e65f-3d2b-4500-a6d1-dab5f3a3046c
begin
	optimize!(model_porfolio)
	
	@show solution_summary(model_porfolio, verbose=true)
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
git-tree-sha1 = "9489214b993cd42d17f44c36e359bf6a7c919abf"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.0"

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
# ╟─2d4017c0-da97-11ec-0bb9-2dbf19cdd9b5
# ╠═643d54ee-e08e-4de5-8733-d18704781523
# ╟─1daee18c-7dc8-44fd-9e38-3a282fdb7497
# ╟─133f42e1-fe24-4ab4-addc-2db93d9fb951
# ╟─78c3e84d-3a12-4e67-b8c3-c02fac10c0a8
# ╟─8a86499c-4cda-4299-af95-1bdce26a303c
# ╟─9f4f2144-32e0-4194-a942-3c6b36383757
# ╟─fa283a0d-5e94-4424-98b7-1ad14b1a846d
# ╟─07af090c-f8e4-470e-9326-accbd0523dbf
# ╟─e97b5cf5-0135-4b79-a35d-0afec0513c7d
# ╟─318b9749-a03a-4a0b-a4ec-273ac7f3d0be
# ╠═9529b709-4d54-4ea3-9abc-bc9a46a84a09
# ╠═c419b556-e7cd-43a2-811e-153d2cc85a2c
# ╟─531a4cd4-3da9-4d5a-9e9a-ec5d259035ab
# ╟─72ff5417-db9c-4deb-a8e5-c87e1995cb8a
# ╟─f4d3ad25-1bd6-4c81-b51b-d0df4c9dc268
# ╟─d2004884-9f06-4d31-9592-007b890b4030
# ╟─2f5fb158-50fb-4267-ac3d-10bda44135c0
# ╟─7f3f61ce-dc25-454c-adca-e8a822e6ff41
# ╟─2286e7c3-e3a2-43b6-99fc-03e14d5d4e03
# ╟─704ee15d-2fdd-476f-8071-fcbe6f0bcc56
# ╟─24df0a9e-7acc-4c0e-a70e-2292a75383ce
# ╠═a5567a1e-848d-4402-af3e-e2815513e723
# ╠═d968e11b-7035-4851-b138-c0d2c093869c
# ╟─4461ce74-9a0f-4bf5-96ae-c88e165e9704
# ╟─1d7324e1-0b28-46c1-b51a-e6c564a7d0a6
# ╟─70a72379-ee2a-48d3-9e67-627168a8bdf0
# ╟─8ca5a37a-02ad-4726-99e0-5dfe7adf3dde
# ╟─9872cb49-c360-48df-a725-f9c8a7ceba60
# ╟─8dcb4543-411d-40ab-b073-7620eec8fdb6
# ╟─4279eeb2-e28f-4530-8b86-b7c0422931ac
# ╟─a0436ccc-d43e-43f0-b653-18fc76a85789
# ╟─29b1bd2a-3c35-4f17-980f-723ac6e139fb
# ╠═403f9a9f-b245-4c93-9a3d-8839857a3075
# ╠═d523f4d1-99ad-40c8-80b5-e299201e9e8d
# ╟─cad78b36-7808-4810-9863-8238ab977b3d
# ╟─e6153c92-4c96-4286-b7d1-9365432f59df
# ╟─66be6b57-5713-4b63-a364-444c1d2c8acf
# ╟─e2115829-2835-4226-bca8-45a5104b5139
# ╟─8b7a969d-5a58-440b-aed9-ae057552003a
# ╠═a55447f4-5b52-4aaa-af56-0f0cb9e751f4
# ╠═cf43e65f-3d2b-4500-a6d1-dab5f3a3046c
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

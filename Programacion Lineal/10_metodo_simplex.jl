### A Pluto.jl notebook ###
# v0.19.30

using Markdown
using InteractiveUtils

# ╔═╡ ee761890-e134-11ee-1d8b-499ec171889b
begin
	using PlutoUI, JuMP, HiGHS, NamedArrays, DataFrames, Gadfly,CDDLib,Polyhedra,Plots,LaTeXStrings
	TableOfContents(title="Contenido")
end 

# ╔═╡ 6015bf28-1a1f-467e-80ff-16167ac4f51e
md"# El método Simplex"

# ╔═╡ aae0e4f4-712e-47b6-ac01-665afa3279d5
md"## Partimos de un problema de Programación Lineal Continua"

# ╔═╡ 0f0298a4-784b-4fd9-87de-9f554a63c448
md"La fábrica de Hilados y Tejidos «Salazar» requiere fabricar dos tejidos de calidad diferente Estándar y Premium; se dispone de 500 Kg de hilo a, 300 Kg de hilo b y 108 Kg de hilo c. Para obtener un metro de Estándar diariamente se necesitan 125 gr de a, 150 gr de b y 72 gr de c; para producir un metro de Premium por día se necesitan 200 gr de a, 100 gr de b y 27 gr de c. El Estándar se vende a $4000 el metro y el Premium se vende a $5000 el metro. Si se debe obtener el máximo beneficio, ¿Cuántos metros de Estándar y Premium se deben fabricar?"

# ╔═╡ 5bb53ec6-2083-4633-acb8-e97983208205
md"### Modelo"

# ╔═╡ 39d355cf-c432-452d-8b2a-c981dcbbe612
md"Llamemos $X_{E}$ a la cantidad de metros de tejido estándar y $X_{P}$ a la cantidad de metros de tejido Premium."

# ╔═╡ 739db78f-23d8-4e1b-809b-e25ccb3d13fc
md"Debemos entonces: "

# ╔═╡ 5666b163-fdaf-4197-a804-6f25a8ebf0da
md"$Max \ Z = 4 X_{E} + 5 X_{P}$"

# ╔═╡ 1234aa29-8cda-4c2d-91cc-70f17b98516a
md"Cabe aclarar que, para utilizar números sencillos, $Z$ está expresada en miles de unidades monetarias."

# ╔═╡ 0d4b4066-9592-4d5f-b5e6-1992017617da
md"Esta función objetivo estará sujeta a la disponibilidad de hilo a, b y c, respectivamente:"

# ╔═╡ 755c3412-86a8-4d12-90a8-a7aaa0457cd8
md"$r_{1}) \ 0,125X_{E}+0,2X_{P} \leq 500$"

# ╔═╡ 98e2fe7c-bc3a-45ae-91a5-54a6bd3f1223
md"$r_{2}) \ 0,15X_{E}+0,1X_{P} \leq 300$"

# ╔═╡ 30aa2c58-e932-449b-9ce1-93ae839838ef
md"$r_{3}) \ 0,072X_{E}+0,027X_{P} \leq 108$"

# ╔═╡ 480aceb3-3f1f-443e-976c-eee27c11a29f
md"Notesé que las unidades deben mantener coherencia. O bien utilizamos el consumo de hilos en kilogramos (como se hizo en este ejemplo) o la disponibilidad en gramos."

# ╔═╡ de35023b-f8a8-4d06-9169-1516894bb159
md"Además, debemos agregar las restricciones de no negatividad"

# ╔═╡ ba65f7c6-79a8-4cec-81bc-b5f319d5544f
begin
	md"$X_{E} \geq 0$
$X_{P} \geq 0$"
end

# ╔═╡ d8665123-57f0-44ee-8d53-a6510cab95ae
md"### Recordemos"

# ╔═╡ 489894ee-e3d7-4b44-8be7-333fa5fe85f0
md"Recordemos un poco algo de terminología de programación lineal.

* **Solución**: Cualquier combinación de posibles valores que adoptan las variables de decisión. Por ejemplo, en este caso tenemos dos variables de decisión $X_{E}$ y $X_{P}$, una solución podría ser:
$(X_{E},X_{P})=(50,600)$

* **Solución infactible**: Es una solución que no cumple con al menos una restricción, ya sea técnica o de no negatividad. Por ejemplo, en este problema la solución $(X_{E},X_{P})=(1800,0)$ es infactible, puesto que la restricción $r_{3}$ no se satisface:
$0,072 \cdot 1800+0,027 \cdot 0 = 129,6 \nleq 108$

* **Solución factible**: Es una solución que cumple con todas las restricciones del problema, técnicas y de no negatividad. Por ejemplo, para este caso $(X_{E},X_{P})=(200,200)$ es una solución factible, puesto que se cumplen $r_{1}$, $r_{2}$, $r_{3}$ y ambas variables son no negativas.


* **Solución óptima**: Es una solución factible cuyo Z, en un problema de maximización, no es menor que ningún otro de una solución factible y, en un problema de minimización, no es mayor que ningún otro de una solución factible. Cabe destacar que la solución óptima es la mejor para las condiciones impuestas y la función objetivo elegida, pero no quiere decir que sea única, de hecho, pueden ser infinitas (todas con el mismo Z).
"

# ╔═╡ bae093dc-c62d-4b87-ae3a-8a7764a2d683
md"### Resolución por método Simplex"

# ╔═╡ 7807ca1f-2d07-4584-872b-c3a17c4e51cb
md"#### Introducción"

# ╔═╡ 7e452eb1-4824-4668-a8a4-91e3260599f4
begin
	f(X)=(500-0.125X)/0.2
	g(X)=(300-0.15X)/0.1
	h(X)=(108-0.072X)/0.027
	X_f_values = 0:0.1:4000
	X_g_values = 0:0.1:2000
	X_h_values = 0:0.1:1500
	f_values = f.(X_f_values)
	g_values = g.(X_g_values)
	h_values = h.(X_h_values)
	md"El método Simplex es algebraico, por lo que se lo puede utilizar sin importar la cantidad de variables y restricciones. Sin embargo, tiene conceptos que surgen de lo geométrico, por lo que es útil graficar la región factible para entenderlo y recordando que el óptimo se encontrará en sus vértices."

end

# ╔═╡ b1c5476d-65c9-4046-a68a-b20feb90a067
md"Antes de continuar, se debe aclarar que todos los vértices de la región factible los producen la intersección de al menos dos fronteras de restricción (contando las de no negatividad). Sin embargo, no todas las intersecciones de fronteras de restricción son soluciones factibles (en el gráfico se ve que la intersección de la frontera de la restricción $r_{1}$ y la de la restricción $r_{3}$ no lo son, por ejemplo), a estas soluciones se las llama solución no factible en el vértice y evitaremos considerarlas en Simplex gracias a como funciona su algoritmo."

# ╔═╡ 62ca060d-4d2b-421c-9b08-a31370095b61
md"Otra cuestión a tener en cuenta en todo problema de programación lineal con inecuaciones es que se puede transformar el problema a uno con igualdades agregando variables. Las variables que utilizamos en el caso en que las inecuaciones son de menor o igual se llaman variables de holgura."

# ╔═╡ 1ad013cb-a69e-4d0d-8705-0c9b3c892a4f
md"Dicho esto, podemos empezar a plantear el simplex a partir del problema original y su versión aumentada con las variables de holgura $S_{1}$,$S_{2}$ y $S_{3}$."

# ╔═╡ 31bce864-0e59-4ff7-b4c1-28fd17fb3e30
md"""
|  			Problema original 		 	|  			Forma aumentada 		 	| Observaciones		 	| 
|-----------	|----------------------------------	|-----------	|
|  			$Max \ Z = 4 X_{E} + 5 X_{P}$ 		       	|  			$Max \ Z = 4 X_{E} + 5 X_{P}$ 		       	| 		Sin cambios       	|  	
|  			$0,125X_{E}+0,2X_{P} \leq 500$ 		       	|  			$0,125X_{E}+0,2X_{P}+S_{1} = 500$ 		       	| 	En $r_{1}$ se agrega $S_{1}$	       	|  		
|  			$0,15X_{E}+0,1X_{P} \leq 300$ 		       	|  			$0,15X_{E}+0,1X_{P}+S_{2} = 300$ 	 		       	| 	En $r_{2}$ se agrega $S_{2}$	       	|
|  			$0,072X_{E}+0,027X_{P} \leq 108$ 		       	|  			$0,072X_{E}+0,027X_{P}+S_{3} = 108$	 		       	| 	En $r_{3}$ se agrega $S_{3}$	       	|
|  			$X_{E} \geq 0$ 		       	|  			$X_{E} \geq 0$	 		       	| 	       	|
|  			$X_{P} \geq 0$ 		       	|  			$X_{P} \geq 0$	 		       	| 	       	|
|  					       	|  			$S_{1} \geq 0$	 		       	| 	       	|
|  					       	|  			$S_{2} \geq 0$	 		       	| 	       	|
|  					       	|  			$S_{3} \geq 0$	 		       	| 	       	|
"""

# ╔═╡ 9124c4a8-ac6f-424a-a996-e9e11de4ac24
md"Se debe notar que, al pasar de inecuaciones a ecuaciones, las holguras representan el sobrante en las unidades en que estén las restricciones para alcanzar el limitante de la restricción en una solución dada."

# ╔═╡ f30f1e8f-1e06-4656-9144-b95c954ce8e5
md"Por ejemplo, en la solución del problema original

$(X_{E},X_{P})=(100,100)$"

# ╔═╡ dc5e9e29-db08-4ddb-a327-713c9ee883e7
md"""
|  			Problema original 		 	|  			Forma aumentada 		 	| Observaciones		 	| 
|-----------	|----------------------------------	|-----------	|
|  			$Max \ Z = 400 + 500$ 		       	|  			$Max \ Z = 400 + 500$ 		       	| 		Sin cambios       	|  	
|  			$12,5+20 \leq 500$ 		       	|  			$12,5+20+S_{1} = 500$ 		       	| 	$S_{1}$ es entonces	467,5       	|  		
|  			$15+10 \leq 300$ 		       	|  			$15+10+S_{2} = 300$ 	 		       	| 	$S_{2}$	es entonces 275       	|
|  			$7,2+2,7 \leq 108$ 		       	|  			$7,2+2,7+S_{3} = 108$	 		       	| 	$S_{3}$	es entonces 98,1	       	|
|  			$X_{E} \geq 0$ 		       	|  			$X_{E} \geq 0$	 		       	| 	       	|
|  			$X_{P} \geq 0$ 		       	|  			$X_{P} \geq 0$	 		       	| 	       	|
|  					       	|  			$S_{1} \geq 0$	 		       	| 	       	|
|  					       	|  			$S_{2} \geq 0$	 		       	| 	       	|
|  					       	|  			$S_{3} \geq 0$	 		       	| 	       	|
"""

# ╔═╡ ace7dda9-2571-45f7-ae07-c0ada0c7f724
md"En otras palabras, la misma solución en la forma aumentada es

$(X_{E},X_{P},S_{1},S_{2},S_{3})=(100,100,467.5,275,98.1)$"

# ╔═╡ c39a25c0-573f-4cdd-8938-ce26cff31994
md"Cabe destacar que en este problema basta con fijar cuánto valen dos variables para obtener las otras tres, ya que tenemos tres ecuaciones y cinco incógnitas (al definir dos, se tiene un sistema de 3x3)."

# ╔═╡ 020ba471-4335-4766-ae1e-f25b24ba0139
md"Podemos ver que tanto la solución en el problema original como en la forma aumentada cumplen todas las restricciones, por lo que son soluciones factibles. Sin embargo, como dijimos anteriormente, la solución óptima estará en un vértice, por lo que al menos dos de las cinco variables que tenemos en la forma aumentada deberán valer cero."

# ╔═╡ 5d391250-f228-4fde-8f7b-1f3fc50b7c6e
md"Volviendo al gráfico, chequeamos que con las coordenadas de las soluciones factibles en el vértice de la forma original y reemplazando en la forma aumentada para obtener $S_{1}$, $S_{2}$ y $S_{3}$, se pueden obtener las soluciones en el vértice de la forma aumentada llamados: **soluciones básicas factibles**"

# ╔═╡ dbfe97b3-2178-48dd-bde0-a2a3ef4103d5
md"

$P_{1}=(0,0,500,300,108)$
$P_{2}=(1500,0,312.5,75,0)$
$P_{3}=(0,2500,0,50,40.5)$
$P_{4}=(2700/3.15,5400/3.15,50,0,0)$
$P_{5}=(100/0.175,375/0.175,0,0,9)$
"

# ╔═╡ dcd11660-81b1-423b-996c-e5ef7033e125
md"Estas soluciones junto con en el resto de los vértices que no son factibles en la forma aumentada se llaman **soluciones básicas**."

# ╔═╡ 425a0746-f15a-4d12-82da-feaf4c65261d
md"""
!!! info "Actividad para el alumno"
	Mostrar que $P_{1}$,$P_{2}$,$P_{3}$,$P_{4}$ y $P_{5}$ son factibles en la forma aumentada y que $P_{6}$,$P_{7}$,$P_{8}$,$P_{9}$ y $P_{10}$ no lo son.
"""

# ╔═╡ d406586d-990e-482f-a1a9-fe41460ec405
md"Note que en toda solución básica (ya sea factible como no) de este problema obtuvo al menos dos variables iguales a cero. Esto se puede obtener como:

Cantidad de variables - Cantidad de restricciones = Mínimo de cantidad de variables iguales a cero"

# ╔═╡ 155f950f-4fd5-433c-9e24-a5655e876e3c
md"Estas variables que **deben ser cero** para estar en una solución básica se llaman variables no básicas, el resto se llaman variables básicas."

# ╔═╡ cb447c92-1d8f-4d09-95cd-3e73356649ff
md"Todo lo dicho anteriormente se puede generalizar cuando todas las restricciones técnicas son de menor o igual como:

* Tendré igual cantidad de variables de holgura que de restricciones técnicas.
* Cada variable se designa ya sea como variable básica o como variable no básica.
* El número de variables básicas es igual al número de restricciones técnicas (ahora ecuaciones). Por lo tanto, el número de variables no básicas es igual al número total de variables menos el número de restricciones técnicas.
* Las variables no básicas se igualan a cero.
* Los valores de las variables básicas se obtienen como la solución simultánea del sistema de ecuaciones (restricciones funcionales en la forma aumentada).
* Si las variables básicas satisfacen las restricciones de no negatividad, la solución básica es una solución básica factible."

# ╔═╡ 1b37d591-df61-4ba7-9512-d1f5e1683a08
md"#### El método Simplex: un método iterativo"

# ╔═╡ 56447d3a-db83-4fa1-baa0-c4ba0e08868b
md"El método Simplex es un **método iterativo**. Esto quiere decir que a partir de una matriz se siguen una serie de pasos previamente definidos y al final de estos pasos obtendremos la solución u obtendremos otra matriz para volver a empezar."

# ╔═╡ 65a0d44f-7bd4-47bf-8228-c46a5d77b418
md"En cada iteración del método Simplex, nos paramos en una solución básica factible y revisamos si existe una solución básica factible en un vértice adyacente que sea mejor. Si encontramos una mejor, nos movemos a ese vértice y, si no, es que estamos parados en el óptimo. Si nos movimos de vértice, volvemos a ver los adyacentes a ese vértice y repetimos el proceso."

# ╔═╡ ede98414-dbd7-4833-a86f-c14e1c1efb65
md"Antes de iniciar el método, debemos formarnos la matriz con la que vamos a trabajar. De ser posible, nos vamos a parar en el vértice $(0,0)$ del problema original, para evitar tener que encontrar un vértice que puede ser laborioso con muchas variables. De no ser posible el uso del origen de coordenadas, no quedará más remedio que buscar una solución básica factible."

# ╔═╡ 558532e7-cfc8-4f0a-ab22-fd7a05099f5e
md"Organicemos entonces los datos en una matriz y paremonós en (0,0), además vamos a reescribir por conveniencia a Z como:

$Z-4X_{E}-5X_{P}=0$"

# ╔═╡ 2882da3f-4880-4ec0-b649-de4842bea709
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | -4 | -5 | 0 | 0 | 0 | - |- |- |
| $r_{1}$ | $S_{1}$ | 0,125 | 0,2 | 1 | 0 | 0 |500 |- |- |
| $r_{2}$ | $S_{2}$ | 0,15 | 0,1 | 0 | 1 | 0 |300 |- |- |
| $r_{3}$ | $S_{3}$ | 0,072 | 0,027 | 0 | 0 | 1 |108 |- |- |
"

# ╔═╡ dbd7cd77-2980-4788-a585-9fe7033680f5
md"La primera fila de la matriz corresponde al valor de Z y de la segunda en adelante una para cada restricción. Cada una de las restricciones posee una variable básica con coeficiente distinto de cero y la solución básica factible (0,0,500,300,108) en la que estamos parados posee dos variables no básicas (de valor cero). En la matriz, solo se ven los coeficientes, **no los valores de las variables**. Además, se incluyen las columnas Lado Derecho con el término independiente de la restricción, Sale y Entra que utilizaremos luego."

# ╔═╡ 3af304f6-acc4-4aa9-b085-31ad8152a285
md"Cabe destacar que los coeficientes de las variables de holgura en este primer momento forman una matriz identidad.

Mientras haya coeficientes en la fila de z que sean negativos, el simplex continuará y no se habrá arribado a una solución óptima."

# ╔═╡ bfa2cb84-96f7-4662-ac77-c9a30eb60904
md"##### Iteración 1"

# ╔═╡ 93ce7e4c-7381-4c0a-9751-7c25e9ba6361
md"1. ¿Cómo son las variables?"

# ╔═╡ 37f31ad7-797f-4315-86d2-c30841d96857
md"
| Variables no básicas | Variables básicas |
|------ |----- |
| $X_{E}$ | $S_{1}$ | 
| $X_{P}$ | $S_{2}$ | 
|  | $S_{3}$ | 
"

# ╔═╡ 6af3d3bf-5cab-46f2-8bbc-d1162c3fc61d
md"2. ¿Hay coeficientes en Z negativos?"

# ╔═╡ 6082b10f-40a6-4046-8d85-cb0b2247d204
md"Sí, debo continuar. Hay un vértice mejor que en el que estoy, me moveré a uno adyacente."

# ╔═╡ 3f7bb3f7-7e34-402b-8945-f5a05bfc59d1
md"3. ¿Cuál es la variable que mayor beneficio aporta?" 

# ╔═╡ 65869168-0806-4f47-8c71-817967856d73
md"La de coeficiente más negativo, $X_{P}$. Es una variable no básica, podemos hacerla 'entrar' como variable básica para movernos de vértice. Es decir, nos moveremos verticalmente a otro vértice (la dirección de $X_{P}$ como la dibujamos)."

# ╔═╡ df283948-8e54-4316-88d0-024b767b7c96
md"4. Si $X_{P}$ ya no será no básica, necesito que una básica se vuelva no básica. ¿Cuál?"

# ╔═╡ a4e9f1d6-7d90-4e63-a7cc-f81aec8718a6
md"Trato de aumentar $X_{P}$ lo más que pueda, sabiendo que $X_{E}$ seguirá siendo no básica (cero). Y recordando que todas las variables deben ser no negativas.

$0,125X_{E}+0,2X_{P}+S_{1} = 500 \implies S_{1}=500-0,2X_{P} \geq 0$
$0,15X_{E}+0,1X_{P}+S_{2} = 300 \implies S_{2}=300-0,1X_{P} \geq 0$ 
$0,072X_{E}+0,027X_{P}+S_{3} = 108 \implies S_{3}=108-0,027X_{P} \geq 0$
"

# ╔═╡ 8e0ced4d-f291-4d47-ae95-69066ad740a5
md"En otras palabras, se debe dar al mismo tiempo que:"

# ╔═╡ a5413ae4-30fa-4aad-854a-ed814b19ccdc
md"
$500/0,2 = 2500 \geq X_{P}$
$300/0,1 = 3000 \geq X_{P}$
$500/0,2 = 4000 \geq X_{P}$"

# ╔═╡ 98b22d80-7ef1-4d73-a1ea-213e39a06aa4
md"Por lo que, como mucho, $X_{P}$ será 2500 al entrar como variable básica en $r_{1}$. Y, por ende, $S_{1}$ saldrá como variable básica en $r_{1}$ y será no básica en la próxima iteración. Es decir, nos estamos moviendo desde $P_{1}$ al vértice $P_{3}$"

# ╔═╡ 54f76348-e2b9-4855-ab9a-ec1146ea5037
md"Como se ve gráficamente, la restricción $r_{1}$ es con la que choca primero. Esto coincide con lo que vimos algebraicamente, donde $r_{1}$ era la que limitaba el crecimiento de $X_{P}$."

# ╔═╡ 1e584917-c355-4a9b-8b0c-46c367c5e2a7
md"Notar que los otros límites posibles eran 4000 y 3000, que corresponden a soluciones en vértices no factibles en la misma dirección ($P_{9}$ y $P_{10}$), lo mismo si alguno hubiese dado negativo: **no debe usarse**, sino que usamos el mínimo no negativo.
"

# ╔═╡ df278d9d-78ab-4f43-be4f-621348b81fb1
md"5. Entonces, ¿Cómo queda la matriz?"

# ╔═╡ 151cadde-6f05-4928-a176-2c95c584621c
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | -4 | -5 | 0 | 0 | 0 | - |- |- |
| $r_{1}$ | $S_{1}$ | 0,125 | 0,2 | 1 | 0 | 0 |500 |$S_{1}$ | $X_{P}$ |
| $r_{2}$ | $S_{2}$ | 0,15 | 0,1 | 0 | 1 | 0 |300 |- |- |
| $r_{3}$ | $S_{3}$ | 0,072 | 0,027 | 0 | 0 | 1 |108 |- |- |
"

# ╔═╡ 5cd10f38-a94d-47b0-8c6a-6a3a64a1e216
md"Para hacer entrar a $X_{P}$ solo lo que podemos hacer son dos operaciones:
* Multiplicar una fila por un número.
* Sumar una fila con otra multiplicada por un número.

Nuestro objetivo es que, para la columna $X_{P}$, en la fila de la restricción que cambia de variable básica el coeficiente sea 1 y, en el resto, cero."

# ╔═╡ 8c82055a-9ce7-4ff0-8e13-b05bb4992441
md"En esta parte, el método funciona como el método de eliminación de Gauss-Jordan que se estudió en Álgebra."

# ╔═╡ f3469695-5ca6-4571-b737-cf1b1a5e8e35
md"Empecemos haciéndola uno, dividiéndola por 0,2."

# ╔═╡ c1c25ebe-69c9-4a59-a4ed-5d529ea2643f
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | -4 | -5 | 0 | 0 | 0 | - |- |- |
| $r_{1}$ | $X_{P}$ | 0,625 | 1 | 5 | 0 | 0 |2500 |$S_{1}$ | $X_{P}$ |
| $r_{2}$ | $S_{2}$ | 0,15 | 0,1 | 0 | 1 | 0 |300 |- |- |
| $r_{3}$ | $S_{3}$ | 0,072 | 0,027 | 0 | 0 | 1 |108 |- |- |
"

# ╔═╡ d06a9fd9-7aac-475d-af74-bbf7747ba02d
md"Podemos multiplicar la fila de $r_{1}$ por cinco y sumarla a la fila de Z para eliminar el -5"

# ╔═╡ ece8f181-3e22-44b5-a907-1f55e5b3daf9
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | -0,875 | 0 | 25 | 0 | 0 | - |- |- |
| $r_{1}$ | $X_{P}$ | 0,625 | 1 | 5 | 0 | 0 |2500 |$S_{1}$ | $X_{P}$ |
| $r_{2}$ | $S_{2}$ | 0,15 | 0,1 | 0 | 1 | 0 |300 |- |- |
| $r_{3}$ | $S_{3}$ | 0,072 | 0,027 | 0 | 0 | 1 |108 |- |- |
"

# ╔═╡ e3bf2afa-9ae6-446e-9c08-edcba0e6e854
md"Podemos multiplicar la fila de $r_{1}$ por -0,1 y sumarla a la fila de $r_{2}$ para eliminar el 0,1 (incluído el lado derecho en estos casos que es posible)"

# ╔═╡ 7f62d868-f794-4f1a-bcf4-d1670420cfd4
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | -0,875 | 0 | 25 | 0 | 0 | - |- |- |
| $r_{1}$ | $X_{P}$ | 0,625 | 1 | 5 | 0 | 0 |2500 |$S_{1}$ | $X_{P}$ |
| $r_{2}$ | $S_{2}$ | 0,0875 | 0 | -0,5 | 1 | 0 |50 |- |- |
| $r_{3}$ | $S_{3}$ | 0,072 | 0,027 | 0 | 0 | 1 |108 |- |- |
"

# ╔═╡ 668f6b8d-390e-4551-86a8-8615fa65d11d
md"Podemos multiplicar la fila de $r_{1}$ por -0,027 y sumarla a la fila de $r_{3}$ para eliminar el 0,027 (incluído el lado derecho en estos casos que es posible)."

# ╔═╡ b6c177c1-ff81-4ecb-8f17-ad88c01ddeb0
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | -0,875 | 0 | 25 | 0 | 0 | - |- |- |
| $r_{1}$ | $X_{P}$ | 0,625 | 1 | 5 | 0 | 0 |2500 |$S_{1}$ | $X_{P}$ |
| $r_{2}$ | $S_{2}$ | 0,0875 | 0 | -0,5 | 1 | 0 |50 |- |- |
| $r_{3}$ | $S_{3}$ | 0,055125 | 0 | -0,135 | 0 | 1 |40,5 |- |- |
"

# ╔═╡ 175bfa4c-4407-4952-91ac-4db7a06992ea
md"¡Lo hemos logrado! Ahora entró $X_{P}$ como variable básica y salió $S_{1}$ que ahora es cero, por ser no básica. Cabe destacar que, como se construye esta matriz, el valor de los lados derechos resulta ser el valor de las variables básicas. En otras palabras, nos movimos al vértice $(0,2500,0,50,40.5)$ que es una solución básica factible. Además, como adelantamos, es el vértice que habíamos llamado $P_{3}$. Es decir, si algún valor de la columna Lado Derecho nos diera negativo algo hemos hecho mal."

# ╔═╡ b3362547-f7ed-4ea9-a913-00d5d107f9e4
md"##### Iteración 2"

# ╔═╡ f27b57d0-8790-4e62-9fba-be4891973ddc
md"1. ¿Cómo son las variables?"

# ╔═╡ 0c2a7256-2aa5-4e5b-912e-f3b78ad82441
md"
| Variables no básicas | Variables básicas |
|------ |----- |
| $X_{E}$ | $X_{P}$ | 
| $S_{1}$ | $S_{2}$ | 
|  | $S_{3}$ | 
"

# ╔═╡ 974b07ab-bc4b-486a-b7c8-6ab4c5030e52
md"2. ¿Hay coeficientes en Z negativos?"

# ╔═╡ cc408f23-dcbd-4061-9c52-2ab6b4d800d5
md"Sí, debo continuar. Hay un vértice mejor que en el que estoy, me moveré a uno adyacente."

# ╔═╡ 79774398-47fc-45f6-80ca-02ad00f75a66
md"3. ¿Cuál es la variable que mayor beneficio aporta?" 

# ╔═╡ a65cc031-7955-405e-b521-9b48d87f822f
md"La de coeficiente más negativo, $X_{E}$. Es una variable no básica, podemos hacerla 'entrar' como variable básica para movernos de vértice. Es decir, nos moveremos horizontalmente a otro vértice (la dirección de $X_{E}$ como la dibujamos)."

# ╔═╡ fd5df6a6-147f-4ef7-9640-6f18c1b63694
md"4. Si $X_{E}$ ya no será no básica, necesito que una básica se vuelva no básica. ¿Cuál?"

# ╔═╡ e2c2f59f-9c6d-4016-afd5-e3e5243d7210
md"Trato de aumentar $X_{E}$ lo más que pueda, sabiendo que $S_{1}$ seguirá siendo no básica (cero). Y recordando que todas las variables deben ser no negativas.

$0,625X_{E}+X_{P}+5S_{1} = 2500 \implies X_{P}=2500-0,625X_{E} \geq 0$
$0,0875X_{E}-0,5S_{1}+S_{2} = 50 \implies S_{2}=50-0,0875X_{E} \geq 0$ 
$0,055125X_{E}-0,135S_{1}+S_{3} = 40,5 \implies S_{3}=40,5-0,055125X_{E} \geq 0$
"

# ╔═╡ da83406c-93ca-4085-922b-21690ee1f9d4
md"En otras palabras, se debe dar al mismo tiempo que:"

# ╔═╡ 2d1564bf-a2af-4296-a283-8fec2eb51065
md"
$2500/0,625 = 4000 \geq X_{E}$
$50/0,0875=100/0,175 \approx 571,43 \geq X_{E}$ 
$40,5/0,055125 \approx 734,69 \geq X_{E}$
"

# ╔═╡ f9861e2c-8034-4336-add0-224fdebfbe3e
md"Por lo que, como mucho, $X_{E}$ será 100/0,175 al entrar como variable básica en $r_{2}$. Y, por ende, $S_{2}$ saldrá como variable básica en $r_{2}$ y será no básica en la próxima iteración. Es decir, nos estamos moviendo desde $P_{3}$ al vértice $P_{5}$"

# ╔═╡ 25548d31-9404-4d41-924f-700e7eca8cfe
md"Como se ve gráficamente, la restricción $r_{2}$ es con la que choca primero. Esto coincide con lo que vimos algebraicamente, donde $r_{2}$ era la que limitaba el crecimiento de $X_{E}$."

# ╔═╡ d88af1d8-9dab-4801-bd99-0d1fa05060de
md"Notar que los otros límites posibles eran 40,5/0,055125 y 4000, que corresponden a soluciones en vértices no factibles en la misma dirección ($P_{6}$ y $P_{8}$), lo mismo si alguno hubiese dado negativo: **no debe usarse**, sino que usamos el mínimo no negativo.
"

# ╔═╡ a4918bce-6246-471e-84a2-e93f4442bd7b
md"5. Entonces, ¿Cómo queda la matriz?"

# ╔═╡ 98a643fd-c241-4f74-a461-f3f68d4c13d1
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | -0,875 | 0 | 25 | 0 | 0 | - |- |- |
| $r_{1}$ | $X_{P}$ | 0,625 | 1 | 5 | 0 | 0 |2500 |- | - |
| $r_{2}$ | $S_{2}$ | 0,0875 | 0 | -0,5 | 1 | 0 |50 | $S_{2}$ | $X_{E}$ |
| $r_{3}$ | $S_{3}$ | 0,055125 | 0 | -0,135 | 0 | 1 |40,5 |- |- |
"

# ╔═╡ 846dde5a-2310-4c2f-b294-f5ff4558f60f
md"Empecemos haciendo el coeficiente de $X_{E}$ uno, dividiéndolo por 0,0875."

# ╔═╡ 8318702f-0884-478b-9b9f-500b1372d88e
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | -0,875 | 0 | 25 | 0 | 0 | - |- |- |
| $r_{1}$ | $X_{P}$ | 0,625 | 1 | 5 | 0 | 0 |2500 |- | - |
| $r_{2}$ | $X_{E}$ | 1 | 0 | -50/8,75 | 100/8,75 | 0 |100/0,175 | $S_{2}$ | $X_{E}$ |
| $r_{3}$ | $S_{3}$ | 0,055125 | 0 | -0,135 | 0 | 1 |40,5 |- |- |
"

# ╔═╡ 55b1dfc0-3015-4aaf-bb4c-d8b5ab6ea2b9
md"Podemos multiplicar la fila de $r_{2}$ por 0,875 y sumarla a la fila de Z para eliminar el -0,875"

# ╔═╡ 716abe6f-a2d1-4151-bae9-c7adb5bc919f
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | 0 | 0 | 20 | 10 | 0 | - |- |- |
| $r_{1}$ | $X_{P}$ | 0,625 | 1 | 5 | 0 | 0 |2500 |- | - |
| $r_{2}$ | $X_{E}$ | 1 | 0 | -50/8,75 | 100/8,75 | 0 |100/0,175 | $S_{2}$ | $X_{E}$ |
| $r_{3}$ | $S_{3}$ | 0,055125 | 0 | -0,135 | 0 | 1 |40,5 |- |- |
"

# ╔═╡ 31e65d55-88ed-49da-b29f-78f8af6ff63b
 md"Podemos multiplicar la fila de $r_{2}$ por -0,625 y sumarla a la fila de $r_{1}$ para eliminar el 0,625 (incluído el lado derecho en estos casos que es posible)."

# ╔═╡ 366b7e63-0a04-464d-878b-f26c11146f51
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | 0 | 0 | 20 | 10 | 0 | - |- |- |
| $r_{1}$ | $X_{P}$ | 0 | 1 | 75/8,75 | -62,5/8,75 | 0 |375/0,175 |- | - |
| $r_{2}$ | $X_{E}$ | 1 | 0 | -50/8,75 | 100/8,75 | 0 |100/0,175 | $S_{2}$ | $X_{E}$ |
| $r_{3}$ | $S_{3}$ | 0,055125 | 0 | -0,135 | 0 | 1 |40,5 |- |- |
"

# ╔═╡ 907f978f-52fd-486c-9bd6-e936eaca9be6
 md"Podemos multiplicar la fila de $r_{2}$ por -0,055125 y sumarla a la fila de $r_{3}$ para eliminar el 0,055125 (incluído el lado derecho en estos casos que es posible)."

# ╔═╡ cc4fa574-b4eb-4e8f-a4eb-2ad18a8bec5d
md"
| Observación | Variable básica | $X_{E}$| $X_{P}$| $S_{1}$| $S_{2}$| $S_{3}$|  Lado Derecho | Sale | Entra
|------ |-----	|--------	|--------- |--------- |--------- |--------- |------ |---- |--- |
| Z | - | 0 | 0 | 20 | 10 | 0 | - |- |- |
| $r_{1}$ | $X_{P}$ | 0 | 1 | 75/8,75 | -62,5/8,75 | 0 |375/0,175 |- | - |
| $r_{2}$ | $X_{E}$ | 1 | 0 | -50/8,75 | 100/8,75 | 0 |100/0,175 | $S_{2}$ | $X_{E}$ |
| $r_{3}$ | $S_{3}$ | 0 | 0 | 0,18 | -0,63 | 1 |9 |- |- |
"

# ╔═╡ e0b1bac4-cae6-4f3f-a72e-54e7721fe00b
md"¡Lo hemos logrado! Ahora entró $X_{E}$ como variable básica y salió $S_{2}$ que ahora es cero, por ser no básica. Cabe destacar que, como se construye esta matriz, el valor de los lados derechos resulta ser el valor de las variables básicas. En otras palabras, nos movimos al vértice $(100/0.175,375/0.175,0,0,9)$ que es una solución básica factible. Además, como adelantamos, es el vértice que habíamos llamado $P_{5}$. Es decir, si algún valor de la columna Lado Derecho nos diera negativo algo hemos hecho mal."

# ╔═╡ 8cb629e4-f7aa-40fe-bc7d-b9a26b2a3485
md"##### Iteración 3"

# ╔═╡ a5db9f67-1ef6-475b-aef0-1c84df07a520
md"1. ¿Cómo son las variables?"

# ╔═╡ b36bd47d-bbf5-46ee-a646-845938069f6c
md"
| Variables no básicas | Variables básicas |
|------ |----- |
| $S_{1}$ | $X_{E}$ | 
| $S_{2}$ | $X_{P}$ | 
|  | $S_{3}$ | 
"

# ╔═╡ 48f6cdd0-ffa3-42ae-88be-f0b29f09eb75
md"2. ¿Hay coeficientes en Z negativos?"

# ╔═╡ a156043d-d49c-4200-aacf-aa6f4067000d
md"No, ¡hemos llegado al óptimo! La solución básica factible 

$(100/0.175,375/0.175,0,0,9) \approx (571.43,2142.86,0,0,9)$

es la óptima."

# ╔═╡ 433c5e70-8dc7-471a-baf1-2761295d2757
md"Cabe destacar que la restricción $r_{3}$ tiene la holgura $S_{3}=9$, como se ve gráficamente."

# ╔═╡ dc9bdedd-b6e1-45e8-985f-7b4e62a46a06
md"Podemos obtener el Z óptimo usando el valor obtenido de $X_{E}$ y $X_{P}$ en la función objetivo original."

# ╔═╡ 91f1c58a-97b8-4df4-9e41-e52241cefd41
md"$Max \ Z=4X_{E}+5X_{P}= 4 \cdot 571,43+5 \cdot 2142,86=13000$"

# ╔═╡ 9dcb8c27-5245-45af-8b62-2411162f14f8
md"Como medimos Z en miles de unidades monetarias, el máximo ingreso por ventas será de 13 millones de unidades monetarias."

# ╔═╡ a27b0cb5-6c6a-431f-8e24-8201c53a7cec
md"### Veamos si nuestra solución es correcta"

# ╔═╡ 1bc0d602-37e3-4102-b749-b99d42cfb9e3
begin
	#=Empieza Modelado=#
	m = Model(HiGHS.Optimizer)
	hilos = ["a", "b","c"]
	productos = ["E","P"]
	consumo = NamedArray([[0.125 0.15 0.072]
					      [0.2 0.1 0.027]], (productos,hilos))
	disp =NamedArray([500;300;108], hilos)
	ben = NamedArray([4;5], productos)
	
	_X = @variable(m, X[productos] >= 0)
	
	obj = @objective(m, Max, sum([ben[i]*_X[i] for i in productos]))
	
	r = @constraint(m, [j in hilos],sum([consumo[i,j]*_X[i] for i in productos]) <= disp[j])
	
	#Termina Modelado	
	#Me guardo la region factible
	poly = polyhedron(m, CDDLib.Library(:exact))
	#Resuelvo el problema
	optimize!(m)
	#Escribo el modelo arriba de la celda de Pluto
	latex_formulation(m)
end

# ╔═╡ ef8e2976-9d6a-4dc3-b4d1-b5179d2137b1
begin
	Plots.plot(X_f_values,f_values, fillrange = -8, fillalpha = 0.2, label = L"$r_{1}$: Disponibilidad de hilo a",color= "red")
	Plots.plot!(X_g_values,g_values, fillrange = -8, fillalpha = 0.2, label=L"$r_{2}$: Disponibilidad de hilo b", color= "green")
	Plots.plot!(X_h_values,h_values, fillrange = -8, fillalpha = 0.2, label=L"$r_{3}$: Disponibilidad de hilo c", color= "blue")
	Plots.plot!(poly,label="Region factible",color="yellow",linecolor="yellow")
	color1="black"
	color2="red"
	Plots.plot!([0],[0], marker=:circle, markersize=5, label=L"$P_{1}$: solución factible en el vértice", color=color1)
	Plots.annotate!(100,200,text(L"$P_{1}$",color=color1))
	Plots.plot!([1500],[0], marker=:circle, markersize=5, label=L"$P_{2}$: solución factible en el vértice", color=color1)
	Plots.annotate!(1600,200,text(L"$P_{2}$",color=color1))
	Plots.plot!([0],[2500], marker=:circle, markersize=5, label=L"$P_{3}$: solución factible en el vértice", color=color1)
	Plots.annotate!(100,2700,text(L"$P_{3}$",color=color1))
	Plots.plot!([2700/3.15],[(300-0.15*2700/3.15)/0.1], marker=:circle, markersize=5, label=L"$P_{4}$: solución factible en el vértice", color=color1)
	Plots.annotate!(2700/3.15+100,(300-0.15*2700/3.15)/0.1+200,text(L"$P_{4}$",color=color1))
	Plots.plot!([100/0.175],[(300-0.15*100/0.175)/0.1], marker=:circle, markersize=5, label=L"$P_{5}$: solución factible en el vértice", color=color1)
	Plots.annotate!(100/0.175,(300-0.15*100/0.175)/0.1+200,text(L"$P_{5}$",color=color1))
	Plots.plot!([300/(0.072*0.2/0.027-0.125)],[(500-0.125*300/(0.072*0.2/0.027-0.125))/0.2], marker=:circle, markersize=5, label=L"$P_{6}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(300/(0.072*0.2/0.027-0.125)+100,(500-0.125*300/(0.072*0.2/0.027-0.125))/0.2+200,text(L"$P_{6}$",color=color2))
	Plots.plot!([2000],[0], marker=:circle, markersize=5, label=L"$P_{7}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(2000+100,200,text(L"$P_{7}$",color=color2))
	Plots.plot!([4000],[0], marker=:circle, markersize=5, label=L"$P_{8}$: solución no factible en el vértice", color=color2)	
	Plots.annotate!(4000+100,200,text(L"$P_{8}$",color=color2))
	Plots.plot!([0],[4000], marker=:circle, markersize=5, label=L"$P_{9}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(100,4200,text(L"$P_{9}$",color=color2))
	Plots.plot!([0],[3000], marker=:circle, markersize=5, label=L"$P_{10}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(100,3200,text(L"$P_{10}$",color=color2))
	Plots.plot!(xlab=L"$X_{E}$")
	Plots.plot!(ylab=L"$X_{P}$")	
	Plots.plot!(legend=true)
	Plots.plot!(ylim=[-100,4500])
	Plots.plot!(xlim=[-100,4500])
	Plots.plot!(framestyle=:origin)
end

# ╔═╡ 8b896760-c2c1-4e59-a586-c964c7b16afb
begin
	Plots.plot(X_f_values,f_values, fillrange = -8, fillalpha = 0.2, label = L"$r_{1}$: Disponibilidad de hilo a",color= "red")
	Plots.plot!(X_g_values,g_values, fillrange = -8, fillalpha = 0.2, label=L"$r_{2}$: Disponibilidad de hilo b", color= "green")
	Plots.plot!(X_h_values,h_values, fillrange = -8, fillalpha = 0.2, label=L"$r_{3}$: Disponibilidad de hilo c", color= "blue")
	Plots.plot!(poly,label="Region factible",color="yellow",linecolor="yellow")
	local color1="black"
	local color2="red"
	local color3="violet"
	Plots.plot!([0],[0], marker=:circle, markersize=5, label=L"$P_{1}$: solución factible en el vértice", color="lime")
	Plots.annotate!(100,200,text(L"$P_{1}$",color=color1))
	Plots.plot!([1500],[0], marker=:circle, markersize=5, label=L"$P_{2}$: solución factible en el vértice", color=color1)
	Plots.annotate!(1600,200,text(L"$P_{2}$",color=color1))
	Plots.plot!([0],[2500], marker=:circle, markersize=5, label=L"$P_{3}$: solución factible en el vértice", color="cyan")
	Plots.annotate!(100,2700,text(L"$P_{3}$",color=color1))
	Plots.plot!([0,0],[100,2400],arrow=true,color=color3, linewidth=4,label="Iteración 1")
	Plots.plot!([2700/3.15],[(300-0.15*2700/3.15)/0.1], marker=:circle, markersize=5, label=L"$P_{4}$: solución factible en el vértice", color=color1)
	Plots.annotate!(2700/3.15+100,(300-0.15*2700/3.15)/0.1+200,text(L"$P_{4}$",color=color1))
	Plots.plot!([100/0.175],[(300-0.15*100/0.175)/0.1], marker=:circle, markersize=5, label=L"$P_{5}$: solución factible en el vértice", color=color1)
	Plots.annotate!(100/0.175,(300-0.15*100/0.175)/0.1+200,text(L"$P_{5}$",color=color1))
	Plots.plot!([300/(0.072*0.2/0.027-0.125)],[(500-0.125*300/(0.072*0.2/0.027-0.125))/0.2], marker=:circle, markersize=5, label=L"$P_{6}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(300/(0.072*0.2/0.027-0.125)+100,(500-0.125*300/(0.072*0.2/0.027-0.125))/0.2+200,text(L"$P_{6}$",color=color2))
	Plots.plot!([2000],[0], marker=:circle, markersize=5, label=L"$P_{7}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(2000+100,200,text(L"$P_{7}$",color=color2))
	Plots.plot!([4000],[0], marker=:circle, markersize=5, label=L"$P_{8}$: solución no factible en el vértice", color=color2)	
	Plots.annotate!(4000+100,200,text(L"$P_{8}$",color=color2))
	Plots.plot!([0],[4000], marker=:circle, markersize=5, label=L"$P_{9}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(100,4200,text(L"$P_{9}$",color=color2))
	Plots.plot!([0],[3000], marker=:circle, markersize=5, label=L"$P_{10}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(100,3200,text(L"$P_{10}$",color=color2))
	Plots.plot!(xlab=L"$X_{E}$")
	Plots.plot!(ylab=L"$X_{P}$")	
	Plots.plot!(legend=true)
	Plots.plot!(ylim=[-100,4500])
	Plots.plot!(xlim=[-100,4500])
	Plots.plot!(framestyle=:origin)
end

# ╔═╡ b724ebfe-a873-4f45-9fd6-4ac9162f6dfd
begin
	Plots.plot(X_f_values,f_values, fillrange = -8, fillalpha = 0.2, label = L"$r_{1}$: Disponibilidad de hilo a",color= "red")
	Plots.plot!(X_g_values,g_values, fillrange = -8, fillalpha = 0.2, label=L"$r_{2}$: Disponibilidad de hilo b", color= "green")
	Plots.plot!(X_h_values,h_values, fillrange = -8, fillalpha = 0.2, label=L"$r_{3}$: Disponibilidad de hilo c", color= "blue")
	Plots.plot!(poly,label="Region factible",color="yellow",linecolor="yellow")
	local color1="black"
	local color2="red"
	local color3="violet"
	Plots.plot!([0],[0], marker=:circle, markersize=5, label=L"$P_{1}$: solución factible en el vértice", color="lime")
	Plots.annotate!(100,200,text(L"$P_{1}$",color=color1))
	Plots.plot!([1500],[0], marker=:circle, markersize=5, label=L"$P_{2}$: solución factible en el vértice", color=color1)
	Plots.annotate!(1600,200,text(L"$P_{2}$",color=color1))
	Plots.plot!([0],[2500], marker=:circle, markersize=5, label=L"$P_{3}$: solución factible en el vértice", color=color1)
	Plots.annotate!(100,2700,text(L"$P_{3}$",color=color1))
	Plots.plot!([0,0],[100,2900],arrow=true,color="red", linewidth=4,label="Movimiento no posible")
	Plots.plot!([0,0],[100,3900],arrow=true,color="red", linewidth=4,label="Movimiento no posible")
	Plots.plot!([2700/3.15],[(300-0.15*2700/3.15)/0.1], marker=:circle, markersize=5, label=L"$P_{4}$: solución factible en el vértice", color=color1)
	Plots.annotate!(2700/3.15+100,(300-0.15*2700/3.15)/0.1+200,text(L"$P_{4}$",color=color1))
	Plots.plot!([100/0.175],[(300-0.15*100/0.175)/0.1], marker=:circle, markersize=5, label=L"$P_{5}$: solución factible en el vértice", color=color1)
	Plots.annotate!(100/0.175,(300-0.15*100/0.175)/0.1+200,text(L"$P_{5}$",color=color1))
	Plots.plot!([300/(0.072*0.2/0.027-0.125)],[(500-0.125*300/(0.072*0.2/0.027-0.125))/0.2], marker=:circle, markersize=5, label=L"$P_{6}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(300/(0.072*0.2/0.027-0.125)+100,(500-0.125*300/(0.072*0.2/0.027-0.125))/0.2+200,text(L"$P_{6}$",color=color2))
	Plots.plot!([2000],[0], marker=:circle, markersize=5, label=L"$P_{7}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(2000+100,200,text(L"$P_{7}$",color=color2))
	Plots.plot!([4000],[0], marker=:circle, markersize=5, label=L"$P_{8}$: solución no factible en el vértice", color=color2)	
	Plots.annotate!(4000+100,200,text(L"$P_{8}$",color=color2))
	Plots.plot!([0],[4000], marker=:circle, markersize=5, label=L"$P_{9}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(100,4200,text(L"$P_{9}$",color=color2))
	Plots.plot!([0],[3000], marker=:circle, markersize=5, label=L"$P_{10}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(100,3200,text(L"$P_{10}$",color=color2))
	Plots.plot!(xlab=L"$X_{E}$")
	Plots.plot!(ylab=L"$X_{P}$")	
	Plots.plot!(legend=true)
	Plots.plot!(ylim=[-100,4500])
	Plots.plot!(xlim=[-100,4500])
	Plots.plot!(framestyle=:origin)
end

# ╔═╡ e885cb9e-f7a3-4c35-b07b-ea9cdd19cbfd
begin
	Plots.plot(X_f_values,f_values, fillrange = -8, fillalpha = 0.2, label = L"$r_{1}$: Disponibilidad de hilo a",color= "red")
	Plots.plot!(X_g_values,g_values, fillrange = -8, fillalpha = 0.2, label=L"$r_{2}$: Disponibilidad de hilo b", color= "green")
	Plots.plot!(X_h_values,h_values, fillrange = -8, fillalpha = 0.2, label=L"$r_{3}$: Disponibilidad de hilo c", color= "blue")
	Plots.plot!(poly,label="Region factible",color="yellow",linecolor="yellow")
	local color1="black"
	local color2="red"
	local color3="violet"
	Plots.plot!([0],[0], marker=:circle, markersize=5, label=L"$P_{1}$: solución factible en el vértice", color=color1)
	Plots.annotate!(100,200,text(L"$P_{1}$",color=color1))
	Plots.plot!([1500],[0], marker=:circle, markersize=5, label=L"$P_{2}$: solución factible en el vértice", color=color1)
	Plots.annotate!(1600,200,text(L"$P_{2}$",color=color1))
	Plots.plot!([0],[2500], marker=:circle, markersize=5, label=L"$P_{3}$: solución factible en el vértice", color="lime")
	Plots.annotate!(100,2700,text(L"$P_{3}$",color=color1))
	Plots.plot!([50,-50+100/0.175],[-50+2500,50+(300-0.15*100/0.175)/0.1],arrow=true,color=color3, linewidth=4,label="Iteración 2")
	Plots.plot!([2700/3.15],[(300-0.15*2700/3.15)/0.1], marker=:circle, markersize=5, label=L"$P_{4}$: solución factible en el vértice", color=color1)
	Plots.annotate!(2700/3.15+100,(300-0.15*2700/3.15)/0.1+200,text(L"$P_{4}$",color=color1))
	Plots.plot!([100/0.175],[(300-0.15*100/0.175)/0.1], marker=:circle, markersize=5, label=L"$P_{5}$: solución factible en el vértice", color="cyan")
	Plots.annotate!(100/0.175,(300-0.15*100/0.175)/0.1+200,text(L"$P_{5}$",color=color1))
	Plots.plot!([300/(0.072*0.2/0.027-0.125)],[(500-0.125*300/(0.072*0.2/0.027-0.125))/0.2], marker=:circle, markersize=5, label=L"$P_{6}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(300/(0.072*0.2/0.027-0.125)+100,(500-0.125*300/(0.072*0.2/0.027-0.125))/0.2+200,text(L"$P_{6}$",color=color2))
	Plots.plot!([2000],[0], marker=:circle, markersize=5, label=L"$P_{7}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(2000+100,200,text(L"$P_{7}$",color=color2))
	Plots.plot!([4000],[0], marker=:circle, markersize=5, label=L"$P_{8}$: solución no factible en el vértice", color=color2)	
	Plots.annotate!(4000+100,200,text(L"$P_{8}$",color=color2))
	Plots.plot!([0],[4000], marker=:circle, markersize=5, label=L"$P_{9}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(100,4200,text(L"$P_{9}$",color=color2))
	Plots.plot!([0],[3000], marker=:circle, markersize=5, label=L"$P_{10}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(100,3200,text(L"$P_{10}$",color=color2))
	Plots.plot!(xlab=L"$X_{E}$")
	Plots.plot!(ylab=L"$X_{P}$")	
	Plots.plot!(legend=true)
	Plots.plot!(ylim=[-100,4500])
	Plots.plot!(xlim=[-100,4500])
	Plots.plot!(framestyle=:origin)
end

# ╔═╡ 936cf177-e51a-420a-bb9d-6bf98b8ad8f4
begin
	Plots.plot(X_f_values,f_values, fillrange = -8, fillalpha = 0.2, label = L"$r_{1}$: Disponibilidad de hilo a",color= "red")
	Plots.plot!(X_g_values,g_values, fillrange = -8, fillalpha = 0.2, label=L"$r_{2}$: Disponibilidad de hilo b", color= "green")
	Plots.plot!(X_h_values,h_values, fillrange = -8, fillalpha = 0.2, label=L"$r_{3}$: Disponibilidad de hilo c", color= "blue")
	Plots.plot!(poly,label="Region factible",color="yellow",linecolor="yellow")
	local color1="black"
	local color2="red"
	local color3="violet"
	Plots.plot!([0],[0], marker=:circle, markersize=5, label=L"$P_{1}$: solución factible en el vértice", color=color1)
	Plots.annotate!(100,200,text(L"$P_{1}$",color=color1))
	Plots.plot!([1500],[0], marker=:circle, markersize=5, label=L"$P_{2}$: solución factible en el vértice", color=color1)
	Plots.annotate!(1600,200,text(L"$P_{2}$",color=color1))
	Plots.plot!([0],[2500], marker=:circle, markersize=5, label=L"$P_{3}$: solución factible en el vértice", color="lime")
	Plots.annotate!(100,2700,text(L"$P_{3}$",color=color1))
	Plots.plot!([2700/3.15],[(300-0.15*2700/3.15)/0.1], marker=:circle, markersize=5, label=L"$P_{4}$: solución factible en el vértice", color=color1)
	Plots.annotate!(2700/3.15+100,(300-0.15*2700/3.15)/0.1+200,text(L"$P_{4}$",color=color1))
	Plots.plot!([100/0.175],[(300-0.15*100/0.175)/0.1], marker=:circle, markersize=5, label=L"$P_{5}$: solución factible en el vértice", color=color1)
	Plots.annotate!(100/0.175,(300-0.15*100/0.175)/0.1+200,text(L"$P_{5}$",color=color1))
	Plots.plot!([300/(0.072*0.2/0.027-0.125)],[(500-0.125*300/(0.072*0.2/0.027-0.125))/0.2], marker=:circle, markersize=5, label=L"$P_{6}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(300/(0.072*0.2/0.027-0.125)+100,(500-0.125*300/(0.072*0.2/0.027-0.125))/0.2+200,text(L"$P_{6}$",color=color2))
	Plots.plot!([2000],[0], marker=:circle, markersize=5, label=L"$P_{7}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(2000+100,200,text(L"$P_{7}$",color=color2))
	Plots.plot!([4000],[0], marker=:circle, markersize=5, label=L"$P_{8}$: solución no factible en el vértice", color=color2)	
	Plots.annotate!(4000+100,200,text(L"$P_{8}$",color=color2))
	Plots.plot!([0],[4000], marker=:circle, markersize=5, label=L"$P_{9}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(100,4200,text(L"$P_{9}$",color=color2))
	Plots.plot!([0],[3000], marker=:circle, markersize=5, label=L"$P_{10}$: solución no factible en el vértice", color=color2)
	Plots.annotate!(100,3200,text(L"$P_{10}$",color=color2))
	
	Plots.plot!([50,-50+4000],[2450,0],arrow=true,color="red", linewidth=3,label="Movimiento no posible")
	
	Plots.plot!([50,-50+40.5/0.055125],[2450,2090],arrow=true,color="red", linewidth=4,label="Movimiento no posible")
	Plots.plot!(xlab=L"$X_{E}$")
	Plots.plot!(ylab=L"$X_{P}$")	
	Plots.plot!(legend=true)
	Plots.plot!(ylim=[-100,4500])
	Plots.plot!(xlim=[-100,4500])
	Plots.plot!(framestyle=:origin)
end

# ╔═╡ e7e7184e-7cac-489f-a2a7-96da19557fe6
solution_summary(m,verbose=true)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CDDLib = "3391f64e-dcde-5f30-b752-e11513730f60"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Gadfly = "c91e804a-d5a3-530f-b6f0-dfbca275c004"
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Polyhedra = "67491407-f73d-577b-9b50-8179a7c68029"

[compat]
CDDLib = "~0.9.2"
DataFrames = "~1.6.1"
Gadfly = "~1.4.0"
HiGHS = "~1.7.5"
JuMP = "~1.18.1"
LaTeXStrings = "~1.3.1"
NamedArrays = "~0.10.0"
Plots = "~1.39.0"
PlutoUI = "~0.7.54"
Polyhedra = "~0.7.6"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.3"
manifest_format = "2.0"
project_hash = "0268137238ce8588c0365db9c9a8d881fee02b8e"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "Test"]

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "c278dfab760520b8bb7e9511b968bf4ba38b7acc"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.3"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "f8c724a2066b2d37d0234fe4022ec67987022d00"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.0.0"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "01b8ccb13d68535d73d2b0c23e39bd23155fb712"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.1.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "f1f03a9fa24271160ed7e73051fba3c1a759b53f"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.4.0"

[[deps.BitFlags]]
git-tree-sha1 = "2dc09997850d68179b69dafb58ae806167a32b1b"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.8"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CDDLib]]
deps = ["LinearAlgebra", "MathOptInterface", "Polyhedra", "SparseArrays", "cddlib_jll"]
git-tree-sha1 = "568af9e3cdfe1983820c89a96c4ffd0b197d0327"
uuid = "3391f64e-dcde-5f30-b752-e11513730f60"
version = "0.9.2"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.CategoricalArrays]]
deps = ["DataAPI", "Future", "Missings", "Printf", "Requires", "Statistics", "Unicode"]
git-tree-sha1 = "1568b28f91293458345dabba6a5ea3f183250a61"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.8"

    [deps.CategoricalArrays.extensions]
    CategoricalArraysJSONExt = "JSON"
    CategoricalArraysRecipesBaseExt = "RecipesBase"
    CategoricalArraysSentinelArraysExt = "SentinelArrays"
    CategoricalArraysStructTypesExt = "StructTypes"

    [deps.CategoricalArrays.weakdeps]
    JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    SentinelArrays = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
    StructTypes = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "2118cb2765f8197b08e5958cdd17c165427425ee"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.19.0"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "c0ae2a86b162fb5d7acc65269b469ff5b8a73594"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.8.1"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "cd67fc487743b2f0fd4380d4cbd3a24660d0eec8"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.3"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "67c1f244b991cad9b0aa4b7540fb758c2488b129"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.24.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

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
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "ed2ebb1ff7550226ddb584ba8352facf8d9ffb22"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.11.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.Compose]]
deps = ["Base64", "Colors", "DataStructures", "Dates", "IterTools", "JSON", "LinearAlgebra", "Measures", "Printf", "Random", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "bf6570a34c850f99407b494757f5d7ad233a7257"
uuid = "a81c6b42-2e10-5240-aca2-a61377ecd94b"
version = "0.9.5"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "8cfa272e8bdedfa88b6aefbbca7c19f1befac519"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.3.0"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

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
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "04c738083f29f86e62c8afc341f0967d8717bdb8"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.6.1"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "ac67408d9ddf207de5cfa9a97e114352430f01ed"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.16"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "66c4c81f259586e8f002eacebc177e1fb06363b0"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.11"
weakdeps = ["ChainRulesCore", "SparseArrays"]

    [deps.Distances.extensions]
    DistancesChainRulesCoreExt = "ChainRulesCore"
    DistancesSparseArraysExt = "SparseArrays"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "7c302d7a5fec5214eb8a5a4c466dcf7a51fcf169"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.107"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8e9441ee83492030ace98f9789a654a6d0b1f643"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "dcb08a0d93ec0b1cdc4af184b26b591e9695423a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.10"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "4558ab818dcceaab612d1bb8c19cee87eda2b83c"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.5.0+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "466d45dc38e15794ec7d5d63ec03d776a9aff36e"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.4+1"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "ec22cbbcd01cba8f41eecd7d44aac1f23ee985e3"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.7.2"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random"]
git-tree-sha1 = "5b93957f6dcd33fc343044af3d48c215be2562f1"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.9.3"
weakdeps = ["PDMats", "SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "cf0fe81336da9fb90944683b8c41984b08793dad"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.36"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d8db6a5a2fe1381c1ea4ef2cab7c69c2de7f9ea0"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.1+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "ff38ba61beff76b8f4acad8ab0c97ef73bb670cb"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.9+0"

[[deps.GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"
version = "6.2.1+2"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Preferences", "Printf", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "UUIDs", "p7zip_jll"]
git-tree-sha1 = "27442171f28c952804dede8ff72828a96f2bfc1f"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.72.10"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "025d171a2847f616becc0f84c8dc62fe18f0f6dd"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.72.10+0"

[[deps.Gadfly]]
deps = ["Base64", "CategoricalArrays", "Colors", "Compose", "Contour", "CoupledFields", "DataAPI", "DataStructures", "Dates", "Distributions", "DocStringExtensions", "Hexagons", "IndirectArrays", "IterTools", "JSON", "Juno", "KernelDensity", "LinearAlgebra", "Loess", "Measures", "Printf", "REPL", "Random", "Requires", "Showoff", "Statistics"]
git-tree-sha1 = "d546e18920e28505e9856e1dfc36cff066907c71"
uuid = "c91e804a-d5a3-530f-b6f0-dfbca275c004"
version = "1.4.0"

[[deps.GenericLinearAlgebra]]
deps = ["LinearAlgebra", "Printf", "Random", "libblastrampoline_jll"]
git-tree-sha1 = "02be7066f936af6b04669f7c370a31af9036c440"
uuid = "14197337-ba66-59df-a3e3-ca00e7dcff7a"
version = "0.3.11"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "82853ebc70db4f5a3084853738c68fd497b22c7c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.3.10"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "e94c92c7bf4819685eb80186d51c43e71d4afa17"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.76.5+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "abbbb9ec3afd783a7cbd82ef01dcd088ea051398"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.1"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.Hexagons]]
deps = ["Test"]
git-tree-sha1 = "de4a6f9e7c4710ced6838ca906f81905f7385fd6"
uuid = "a1b4810d-1bce-5fbd-ac56-80944d57a21f"
version = "0.2.0"

[[deps.HiGHS]]
deps = ["HiGHS_jll", "MathOptInterface", "PrecompileTools", "SparseArrays"]
git-tree-sha1 = "fce13308f09771b160232903cad57be39a8a0ebb"
uuid = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
version = "1.7.5"

[[deps.HiGHS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "10bf0ecdf70f643bfc1948a6af0a98be3950a3fc"
uuid = "8fd58aa0-07eb-5a78-9b36-339c94fd15ea"
version = "1.6.0+0"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "f218fe3736ddf977e0e772bc9a586b2383da2685"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.23"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "d75853a0bdbfb1ac815478bacd89cd27b550ace6"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.3"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "5fdf2fe6724d8caabf43b557b84ce53f3b7e2f6b"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2024.0.2+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "88a101217d7cb38a7b481ccd50d21876e1d1b0e0"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.15.1"
weakdeps = ["Unitful"]

    [deps.Interpolations.extensions]
    InterpolationsUnitfulExt = "Unitful"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IterTools]]
git-tree-sha1 = "42d5f897009e7ff2cf88db414a389e5ed1bdd023"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.10.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "a53ebe394b71470c7f97c2e7e170d51df21b17af"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.7"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "60b1194df0a3298f460063de985eae7b01bc011a"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.1+0"

[[deps.JuMP]]
deps = ["LinearAlgebra", "MacroTools", "MathOptInterface", "MutableArithmetics", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays"]
git-tree-sha1 = "adef1dfbafeab635664fb3249b58be8d290ed49d"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.18.1"

    [deps.JuMP.extensions]
    JuMPDimensionalDataExt = "DimensionalData"

    [deps.JuMP.weakdeps]
    DimensionalData = "0703355e-b756-11e9-17c0-8b28908087d0"

[[deps.Juno]]
deps = ["Base64", "Logging", "Media", "Profile"]
git-tree-sha1 = "07cb43290a840908a771552911a6274bc6c072c7"
uuid = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
version = "0.8.4"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "fee018a29b60733876eb557804b5b109dd3dd8a7"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.8"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d986ce2d884d49126836ea94ed5bfb0f12679713"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "15.0.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "f428ae552340899a935973270b8d98e5a31c49fe"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.1"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

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

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "2da088d113af58221c52828a80378e16be7d037a"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.5.1+1"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Loess]]
deps = ["Distances", "LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "a113a8be4c6d0c64e217b472fb6e61c760eb4022"
uuid = "4345ca2d-374a-55d4-8d30-97f9976e7612"
version = "0.6.3"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "7d6dd4e9212aebaeed356de34ccf262a3cd415aa"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.26"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "c1dd6d7978c12545b4179fb6153b9250c96b0075"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.3"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "72dc3cf284559eb8f53aa593fe62cb33f83ed0c0"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2024.0.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "b211c553c199c111d998ecdaf7623d1b89b69f93"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.12"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays", "SpecialFunctions", "Test", "Unicode"]
git-tree-sha1 = "e2ae8cf5ac6daf5a3959f7f6ded9c2028b61d09d"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.25.1"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.Media]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "75a54abd10709c01f1b86b84ec225d26e840ed58"
uuid = "e89f7d12-3494-54d1-8411-f7d8b9ae1f27"
version = "0.5.0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "806eea990fb41f9b36f1253e5697aa645bf6a9f8"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.4.0"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "6d42eca6c3a27dc79172d6d947ead136d88751bb"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.10.0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OffsetArrays]]
git-tree-sha1 = "6a731f2b5c03157418a20c12195eb4b74c8f8621"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.13.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "51901a49222b09e3743c65b8847687ae5fc78eb2"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "cc6e1927ac521b659af340e0ca45828a3ffc748f"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.12+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "949347156c25054de2db3b166c52ac4728cbad65"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.31"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "64779bc4c9784fee475689a1752ef4d5747c5e87"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.42.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "1f03a2d339f42dca4a4da149c7e15e9b896ad899"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.1.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "862942baf5663da528f66d24996eb6da85218e76"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.0"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Preferences", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "ccee59c6e48e6f2edf8a5b64dc817b6729f99eb5"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.39.0"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "bd7c69c7f7173097e7b5e1be07cee2b8b7447f51"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.54"

[[deps.Polyhedra]]
deps = ["GenericLinearAlgebra", "GeometryBasics", "JuMP", "LinearAlgebra", "MutableArithmetics", "RecipesBase", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "e7b1e266cc9f3cb046d6c8d2c3aefc418a53428d"
uuid = "67491407-f73d-577b-9b50-8179a7c68029"
version = "0.7.6"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "88b895d13d53b5577fd53379d913b9ab9ac82660"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "37b7bb7aabf9a085e0044307e1717436117f2b3b"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.5.3+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "9ebcd48c498668c7fa0e97a9cae873fbee7bfee1"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.9.1"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "1342a47bf3260ee108163042310d26f2be5ec90b"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.5"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "f65dcb5fa46aee0cf9ed6274ccbd597adc49aa7b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.1"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6ed52fdd3382cf21947b15e8870ac0ddbff736da"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.4.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "0e7508ff27ba32f26cd459474ca2ede1bc10991f"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.1"

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

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e2cfc4012a19088254b3950b85c3c1d8882d864d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.3.1"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "4e17a790909b17f7bf1496e3aec138cf01b60b3b"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.0"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "36b3d696ce6366023a0ea192b4cd442268995a0d"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.2"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "f625d686d5a88bcd2b15cd81f18f98186fdc0c9a"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.3.0"

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

    [deps.StatsFuns.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a04cabe79c5f01f4d723cc6704070ada0b9d46d5"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.4"

[[deps.StructArrays]]
deps = ["DataAPI", "Tables"]
git-tree-sha1 = "ad1f5fd155426dcc879ec6ede9f74eb3a2d582df"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.4.2"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "cb76cf677714c095e535e3501ac7954732aeea2d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.11.1"

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

[[deps.TranscodingStreams]]
git-tree-sha1 = "1fbeaaca45801b4ba17c251dd8603ef24801dd84"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.10.2"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "3c793be6df9dd77a0cf49d80984ef9ff996948fa"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.19.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "e2d817cc500e960fdbafcf988ac8436ba3208bfd"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.3"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "7558e29847e99bc3f04d6569e82d0f5c54460703"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+1"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "93f43ab61b16ddfb2fd3bb13b3ce241cafb0e6c9"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.31.0+0"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c1a7aa6219628fcd757dede0ca95e245c5cd9511"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "1.0.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "801cbe47eae69adc50f36c3caec4758d2650741b"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.12.2+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "522b8414d40c4cbbab8dee346ac3a09f9768f25d"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.4.5+0"

[[deps.Xorg_libICE_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "e5becd4411063bdcac16be8b66fc2f9f6f1e8fe5"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.0.10+1"

[[deps.Xorg_libSM_jll]]
deps = ["Libdl", "Pkg", "Xorg_libICE_jll"]
git-tree-sha1 = "4a9d9e4c180e1e8119b5ffc224a7b59d3a7f7e18"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.3+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "b4bfde5d5b652e22b9c790ad00af08b6d042b97d"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.15.0+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "730eeca102434283c50ccf7d1ecdadf521a765a4"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.2+0"

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "04341cb870f29dcd5e39055f895c39d016e18ccd"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.4+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "330f955bc41bb8f5270a369c473fc4a5a4e4d3cb"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.6+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "691634e5453ad362044e2ad653e79f3ee3bb98c3"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.39.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "49ce682769cd5de6c72dcf1b94ed7790cd08974c"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.5+0"

[[deps.cddlib_jll]]
deps = ["Artifacts", "GMP_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c25e5fe14395ea7b1d702f4eb90c52bdf50e3450"
uuid = "f07e07eb-5685-515a-97c8-3014f6152feb"
version = "0.94.13+0"

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "gperf_jll"]
git-tree-sha1 = "431b678a28ebb559d224c0b6b6d01afce87c51ba"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.9+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a68c9655fbe6dfcab3d972808f1aafec151ce3f8"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.43.0+0"

[[deps.gperf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3516a5630f741c9eecb3720b1ec9d8edc3ecc033"
uuid = "1a1c6b14-54f6-533d-8383-74cd7377aa70"
version = "3.1.1+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "141fe65dc3efabb0b1d5ba74e91f6ad26f84cc22"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "ad50e5b90f222cfe78aa3d5183a20a12de1322ce"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.18.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "93284c28274d9e75218a416c65ec49d0e0fcdf3d"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.40+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "814e154bdb7be91d78b6802843f76b6ece642f11"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.6+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9c304562909ab2bab0262639bd4f444d7bc2be37"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+1"
"""

# ╔═╡ Cell order:
# ╠═ee761890-e134-11ee-1d8b-499ec171889b
# ╟─6015bf28-1a1f-467e-80ff-16167ac4f51e
# ╟─aae0e4f4-712e-47b6-ac01-665afa3279d5
# ╟─0f0298a4-784b-4fd9-87de-9f554a63c448
# ╟─5bb53ec6-2083-4633-acb8-e97983208205
# ╟─39d355cf-c432-452d-8b2a-c981dcbbe612
# ╟─739db78f-23d8-4e1b-809b-e25ccb3d13fc
# ╟─5666b163-fdaf-4197-a804-6f25a8ebf0da
# ╟─1234aa29-8cda-4c2d-91cc-70f17b98516a
# ╟─0d4b4066-9592-4d5f-b5e6-1992017617da
# ╟─755c3412-86a8-4d12-90a8-a7aaa0457cd8
# ╟─98e2fe7c-bc3a-45ae-91a5-54a6bd3f1223
# ╟─30aa2c58-e932-449b-9ce1-93ae839838ef
# ╟─480aceb3-3f1f-443e-976c-eee27c11a29f
# ╟─de35023b-f8a8-4d06-9169-1516894bb159
# ╟─ba65f7c6-79a8-4cec-81bc-b5f319d5544f
# ╟─d8665123-57f0-44ee-8d53-a6510cab95ae
# ╟─489894ee-e3d7-4b44-8be7-333fa5fe85f0
# ╟─bae093dc-c62d-4b87-ae3a-8a7764a2d683
# ╟─7807ca1f-2d07-4584-872b-c3a17c4e51cb
# ╟─7e452eb1-4824-4668-a8a4-91e3260599f4
# ╟─ef8e2976-9d6a-4dc3-b4d1-b5179d2137b1
# ╟─b1c5476d-65c9-4046-a68a-b20feb90a067
# ╟─62ca060d-4d2b-421c-9b08-a31370095b61
# ╟─1ad013cb-a69e-4d0d-8705-0c9b3c892a4f
# ╟─31bce864-0e59-4ff7-b4c1-28fd17fb3e30
# ╟─9124c4a8-ac6f-424a-a996-e9e11de4ac24
# ╟─f30f1e8f-1e06-4656-9144-b95c954ce8e5
# ╟─dc5e9e29-db08-4ddb-a327-713c9ee883e7
# ╟─ace7dda9-2571-45f7-ae07-c0ada0c7f724
# ╟─c39a25c0-573f-4cdd-8938-ce26cff31994
# ╟─020ba471-4335-4766-ae1e-f25b24ba0139
# ╟─5d391250-f228-4fde-8f7b-1f3fc50b7c6e
# ╟─dbfe97b3-2178-48dd-bde0-a2a3ef4103d5
# ╟─dcd11660-81b1-423b-996c-e5ef7033e125
# ╟─425a0746-f15a-4d12-82da-feaf4c65261d
# ╟─d406586d-990e-482f-a1a9-fe41460ec405
# ╟─155f950f-4fd5-433c-9e24-a5655e876e3c
# ╟─cb447c92-1d8f-4d09-95cd-3e73356649ff
# ╟─1b37d591-df61-4ba7-9512-d1f5e1683a08
# ╟─56447d3a-db83-4fa1-baa0-c4ba0e08868b
# ╟─65a0d44f-7bd4-47bf-8228-c46a5d77b418
# ╟─ede98414-dbd7-4833-a86f-c14e1c1efb65
# ╟─558532e7-cfc8-4f0a-ab22-fd7a05099f5e
# ╟─2882da3f-4880-4ec0-b649-de4842bea709
# ╟─dbd7cd77-2980-4788-a585-9fe7033680f5
# ╟─3af304f6-acc4-4aa9-b085-31ad8152a285
# ╟─bfa2cb84-96f7-4662-ac77-c9a30eb60904
# ╟─93ce7e4c-7381-4c0a-9751-7c25e9ba6361
# ╟─37f31ad7-797f-4315-86d2-c30841d96857
# ╟─6af3d3bf-5cab-46f2-8bbc-d1162c3fc61d
# ╟─6082b10f-40a6-4046-8d85-cb0b2247d204
# ╟─3f7bb3f7-7e34-402b-8945-f5a05bfc59d1
# ╟─65869168-0806-4f47-8c71-817967856d73
# ╟─df283948-8e54-4316-88d0-024b767b7c96
# ╟─a4e9f1d6-7d90-4e63-a7cc-f81aec8718a6
# ╟─8e0ced4d-f291-4d47-ae95-69066ad740a5
# ╟─a5413ae4-30fa-4aad-854a-ed814b19ccdc
# ╟─98b22d80-7ef1-4d73-a1ea-213e39a06aa4
# ╟─8b896760-c2c1-4e59-a586-c964c7b16afb
# ╟─54f76348-e2b9-4855-ab9a-ec1146ea5037
# ╟─1e584917-c355-4a9b-8b0c-46c367c5e2a7
# ╟─b724ebfe-a873-4f45-9fd6-4ac9162f6dfd
# ╟─df278d9d-78ab-4f43-be4f-621348b81fb1
# ╟─151cadde-6f05-4928-a176-2c95c584621c
# ╟─5cd10f38-a94d-47b0-8c6a-6a3a64a1e216
# ╟─8c82055a-9ce7-4ff0-8e13-b05bb4992441
# ╟─f3469695-5ca6-4571-b737-cf1b1a5e8e35
# ╟─c1c25ebe-69c9-4a59-a4ed-5d529ea2643f
# ╟─d06a9fd9-7aac-475d-af74-bbf7747ba02d
# ╟─ece8f181-3e22-44b5-a907-1f55e5b3daf9
# ╟─e3bf2afa-9ae6-446e-9c08-edcba0e6e854
# ╟─7f62d868-f794-4f1a-bcf4-d1670420cfd4
# ╟─668f6b8d-390e-4551-86a8-8615fa65d11d
# ╟─b6c177c1-ff81-4ecb-8f17-ad88c01ddeb0
# ╟─175bfa4c-4407-4952-91ac-4db7a06992ea
# ╟─b3362547-f7ed-4ea9-a913-00d5d107f9e4
# ╟─f27b57d0-8790-4e62-9fba-be4891973ddc
# ╟─0c2a7256-2aa5-4e5b-912e-f3b78ad82441
# ╟─974b07ab-bc4b-486a-b7c8-6ab4c5030e52
# ╟─cc408f23-dcbd-4061-9c52-2ab6b4d800d5
# ╟─79774398-47fc-45f6-80ca-02ad00f75a66
# ╟─a65cc031-7955-405e-b521-9b48d87f822f
# ╟─fd5df6a6-147f-4ef7-9640-6f18c1b63694
# ╟─e2c2f59f-9c6d-4016-afd5-e3e5243d7210
# ╟─da83406c-93ca-4085-922b-21690ee1f9d4
# ╟─2d1564bf-a2af-4296-a283-8fec2eb51065
# ╟─f9861e2c-8034-4336-add0-224fdebfbe3e
# ╟─e885cb9e-f7a3-4c35-b07b-ea9cdd19cbfd
# ╟─25548d31-9404-4d41-924f-700e7eca8cfe
# ╟─d88af1d8-9dab-4801-bd99-0d1fa05060de
# ╟─936cf177-e51a-420a-bb9d-6bf98b8ad8f4
# ╟─a4918bce-6246-471e-84a2-e93f4442bd7b
# ╟─98a643fd-c241-4f74-a461-f3f68d4c13d1
# ╟─846dde5a-2310-4c2f-b294-f5ff4558f60f
# ╟─8318702f-0884-478b-9b9f-500b1372d88e
# ╟─55b1dfc0-3015-4aaf-bb4c-d8b5ab6ea2b9
# ╟─716abe6f-a2d1-4151-bae9-c7adb5bc919f
# ╟─31e65d55-88ed-49da-b29f-78f8af6ff63b
# ╟─366b7e63-0a04-464d-878b-f26c11146f51
# ╟─907f978f-52fd-486c-9bd6-e936eaca9be6
# ╟─cc4fa574-b4eb-4e8f-a4eb-2ad18a8bec5d
# ╟─e0b1bac4-cae6-4f3f-a72e-54e7721fe00b
# ╟─8cb629e4-f7aa-40fe-bc7d-b9a26b2a3485
# ╟─a5db9f67-1ef6-475b-aef0-1c84df07a520
# ╟─b36bd47d-bbf5-46ee-a646-845938069f6c
# ╟─48f6cdd0-ffa3-42ae-88be-f0b29f09eb75
# ╟─a156043d-d49c-4200-aacf-aa6f4067000d
# ╟─433c5e70-8dc7-471a-baf1-2761295d2757
# ╟─dc9bdedd-b6e1-45e8-985f-7b4e62a46a06
# ╟─91f1c58a-97b8-4df4-9e41-e52241cefd41
# ╟─9dcb8c27-5245-45af-8b62-2411162f14f8
# ╟─a27b0cb5-6c6a-431f-8e24-8201c53a7cec
# ╠═1bc0d602-37e3-4102-b749-b99d42cfb9e3
# ╠═e7e7184e-7cac-489f-a2a7-96da19557fe6
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

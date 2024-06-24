### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 17d6f40d-c53a-4f5c-93ba-0de5c3bc2454
using PlutoUI

# ╔═╡ feb2c68a-193f-4a8e-b0c2-e317c205c9d9
using(JuMP); 

# ╔═╡ c1937ebc-4fdd-4420-a221-a72a4b082815
using(HiGHS); 

# ╔═╡ e5a1158e-c71f-11ec-1f06-2ba1aaa846b1
md"# Introducción a Julia para modelado y resolución de problemas de programación lineal"

# ╔═╡ dcb11e23-90e9-45fd-938a-d009af1cf528
TableOfContents(title="Contenido")

# ╔═╡ 00fb8cef-0a92-44e2-8078-22d05f0000c3
md"En este notebook vamos a realizar una introducción al uso de Julia, en general, y a la biblioteca JuMP, en particular, para modelar problemas de programación lineal."

# ╔═╡ d330b64b-2d70-44c0-b7b8-e872a6182efa
md"## Una pequeña disgresión acerca de software de optimización"

# ╔═╡ d05c9518-c61e-4e0f-98d4-1957818b8494
md"En el mercado de software de optimización existen basicamente dos tipos de software: optimizadores (o solucionadores, en ingles _solvers_) y modeladores. Los primeros (los _solvers_) son los que resuelven los problemas de optimización en si. Implementan un montón de algoritmos de optimización, heurísticas de aproximación y técnicas de aprendizaje automático para encontrar las soluciones óptimas a los problemas que reciben como input. Hay _solvers_ generales (para cualquier tipo de problema, como [LocalSolver](https://www.localsolver.com/)) y específicos, como por ejemplo, aquellos que solo problemas de programación lineal. Dentro de este rubro hay software comerciales, como [CPLEX](https://www.ibm.com/analytics/cplex-optimizer) o [Gurobi](https://www.gurobi.com/) y otros open-source, como [lpSolve](http://web.mit.edu/lpsolve/doc/), [SCIP](https://scip.zib.de/), [HiGHS](https://www.maths.ed.ac.uk/hall/HiGHS/), las herramientas del proyecto [COIN-OR](https://www.coin-or.org/) o las de [Google OR-Tools](https://developers.google.com/optimization). Si necesitamos mucha, mucha performance, las aplicaciones comerciales salen ganando (obviamente tienen su precio, el cual es bastante elevado). Por último, para problemas específicos, existen _solvers_ dedicados, como [Concorde](http://www.math.uwaterloo.ca/tsp/concorde.html)."

# ╔═╡ b5c7cc5f-51f6-4214-a2f7-8627f06dc2c9
md"Lo anterior aplica a la resolución del problema en si, pero el modelado suele ser una tarea larga y tediosa. Para ello, existen bibliotecas que permiten hacer uso de los _solvers_ desde lenguajes de programación, como [HiGHS](https://www.maths.ed.ac.uk/hall/HiGHS/) y aplicaciones de _modelado_, que permiten escribir el problema usando algo cercano a la notación matemática (como [AMPL](https://ampl.com/) y [GAMS](https://www.gams.com/)). Estos software de modelado ahorran mucho trabajo en el día a día de la resolución de problemas de optimización."

# ╔═╡ 548a519c-e41e-482e-ad6f-171572a89015
md"Por último, existen softwares híbridos, como [Lingo/Lindo](https://www.lindo.com/index.php/products/lingo-and-optimization-modeling), que implementan modelado y resolución. LocalSolver también entra en esta categoría, si consideramos el lenguaje de modelado que tiene asociado."

# ╔═╡ 8ca42767-b720-4bef-b548-75cedb47671d
md"## Modelando problemas con Julia"

# ╔═╡ 6bf7649f-7a8d-48df-a35d-48a8ed687ed3
md"Para resolver problemas de Programación Lineal con Julia, es necesario recurrir a algún paquetes (o biblioteca) que nos permita trasladar el formalismo de la PL en forma fácil y, a su vez, conectarnos a un solver. En este curso, vamos a utilizar la bilioteca de modelado [JuMP](https://jump.dev/) y el solver [HiGHS](https://www.maths.ed.ac.uk/hall/HiGHS/).

[JuMP](https://jump.dev/) es una biblioteca de modelado que permite escribir modelos de PL en Julia de forma muy similar a la escritura matemática estandar. En ese sentido, sabiendo como escribir las ecuaciones en papel y lápiz, es poco lo que se necesita aprender de Julia para resolver problemas de PL.

[HiGHS](https://www.maths.ed.ac.uk/hall/HiGHS/) es un solver Open-Source desarrollado por un equipo de investigadores de la Universidad de Edimburgo. Dentro del grupo de los solvers no comerciales es, junto con SCIP, uno de los solvers mas potentes para resolver problemas de PL y PL Entera-Mixta. Si bien inferior en velocidad respecto de solvers como CPLEX y Gurobi, es adecuado para una gran cantidad de aplicaciones en la industria."

# ╔═╡ 25947bcb-e2a4-474d-854d-76995701036d
md"## Resolviendo un problema con Julia, JuMP y HiGHS"

# ╔═╡ a55ef807-7428-40f3-9006-605f6e44cc34
md"Vamos a focalizarnos en el problema 1 de la cartilla de ejercicios. Para no abrir otro archivo, aquí esta transcripto:

> Winco vende cuatro tipos de productos. Para satisfacer las demandas de los clientes, hay que producir exactamente $950$ unidades en total y por lo menos $400$ unidades del producto 4.
>
> En la tabla a continuación se dan los recursos requeridos para producir una unidad de cada producto y los precios de venta de cada uno. 

$\begin{array}{lcccc}
	\hline
	\text{Concepto} & \text{Producto 1} & \text{Producto 2}& \text{Producto 3} &\text{Producto 4}\\
	\hline
	\text{Materia Prima} & 2 & 3 & 4 & 7\\
	\text{Horas de trabajo} & 3 & 4 & 5 & 6\\
	\text{Precio de venta} & 4 & 6 & 7 & 8\\
	\hline
\end{array}$

> En la actualidad, se dispone de $4600$ unidades de materia prima y $5000$ horas de trabajo. 
>
> El objetivo de Winco es maximizar sus ingresos por las ventas. "

# ╔═╡ 559a7a85-d115-4040-aac3-a2d5e7a828fd
md"El modelo de programación lineal asociado al problema anterior es:

$\begin{equation}
Min Z = 4x_{1} + 6x_{2} + 7x_{3} + 8x_{4} 
\end{equation}$

Sujeto a:

$\begin{equation}
x_{1} + x_{2} + x_{3} + x_{4} = 950
\end{equation}$

$\begin{equation}
x_{4} \geq 400
\end{equation}$

$\begin{equation}
2x_{1} + 3x_{2} + 4x_{3} + 7x_{4} \leq 4600
\end{equation}$

$\begin{equation}
3x_{1} + 4x_{2} + 5x_{3} + 6x_{4} \leq 5000
\end{equation}$

$\begin{equation}
x_{i} \geq 0,  \forall i \in \{1,2,3,4\}
\end{equation}$"

# ╔═╡ 32134397-1dd6-4237-8d41-6383df68bb2e
md"Asumiendo que tenemos JuMP y HiGHS instalados (y, si no, revisen el instructivo):"

# ╔═╡ 7a2983db-2091-4709-866d-0f59566a7129
md"Con las dos sentencias anteriores, le decimos a Julia que queremos cargar en memoria las bibliotecas JuMP y HiGHS. 

Ahora, es necesario crear un modelo."

# ╔═╡ c69f358e-d92c-44ff-bf24-90b14620e80e
model = Model(HiGHS.Optimizer)

# ╔═╡ c19baf24-c56a-4f89-aaaa-9d5a82516325
md"El modelo anterior está vacío. Es una estructura genérica para almacenar el formalismo de un problema de programación lineal. Entonces, ahora, hay que llenar ese modelo vacío. Para ello, primero creamos las variables de decisión:"

# ╔═╡ d003da06-f38e-44ee-a488-7b76d8cefb8e
x = @variable(model, x[1:4] >= 0)

# ╔═╡ 3b005c8f-d41d-4be4-8037-86d3378f1fb2
md"Creadas nuestras cuatro variables del tipo $X_{i}$, todas no-negativas, vamos a crear la función objetivo. Para ello, primero creamos el vector de los coeficientes de las variables:"

# ╔═╡ baf9f785-51a0-4c91-ac8b-578f4f1df002
c = [4;6;7;8]

# ╔═╡ 7d2c0c6c-8521-4379-a92e-ea8925303882
md"Y luego, le decimos a JuMP que nuestra función objetivo es el producto escalar entre el vector $c$ y el vector $x$. Para ello, recordando que el producto escalar entre dos vectores columnas es igual al producto matricial del primer transpuesto por el segundo, y sabiendo que el operador _'_ nos permite calcular la matriz transpuesta conjugada (o matriz adjunta, la cual es igual a la transpuesta si no hay parte imaginaria):"

# ╔═╡ afe6e4b6-b8e5-4b2c-ac69-d38cd0e4c076
obj = @objective(model, Max, c' * x)

# ╔═╡ 493671e2-ede2-48c5-8f4c-7fc5684086a0
md"Para agregar restricciones, JuMP nos permite definir el vector de coeficientes de las variables de la restricción, y expresar el producto escalar con el vector de $X$. Para indicar el sentido de la restricción, tenemos el signo de igualdad _==_, el signo de mayor o igual _>=_ y el de menor o igual _<=_. Entonces, la operatoria se vuelve muy similar a la declaración de la función objetivo:"

# ╔═╡ 930d00cb-fa2e-42ad-8851-025c34dcbf49
a1 = [1;1;1;1]

# ╔═╡ 8203844b-044c-4a3c-92d0-779f9b5f86db
r1 = @constraint(model, a1' * x == 950)

# ╔═╡ caa37dd3-102d-4d52-ade7-1d2856ddacd6
md"También podemos referenciar una única variable al momento de escribir las restricciones:"

# ╔═╡ 3e626874-2e36-45c4-aff6-2856e489be24
r2= @constraint(model, x[4] >= 400)

# ╔═╡ ef8f067f-8419-4896-9c2d-568219652756
md"¿Y que pasa si tenemos muchas restricciones con el mismo signo? Bueno, podemos escribirlas una por una, como en las restricciones anteriores, o bien podemos definir la matriz de coeficientes (una fila por restricción, una columna por variable) y el vector columna del lado derecho. Noten que, en este caso, no es necesario transponer nada, pero si hay que decirle que aplique las comparaciones fila por fila, mediante los operadores _.==_, _.>=_ y _.<=_ (noten el punto adelante del signo):"

# ╔═╡ cf6a89e1-be05-4864-bac3-2edb31db8a0c
a3and4 = [
	2 3 4 7
	3 4 5 6]

# ╔═╡ 2adbfff0-233e-4977-9303-6f8a45de5ded
b3and4 = [4600; 5000]

# ╔═╡ f4c69968-d9ad-4b58-b77e-1a86813d9217
r3and4 = @constraint(model, a3and4 * x .<= b3and4)

# ╔═╡ d6bad884-7b9f-4c60-ab19-ef4966540edd
md"Con la función _Text_ podemos visualizar el modelo:"

# ╔═╡ 44facdfb-84b1-4b6b-b413-bc9929413f15
Text(model)

# ╔═╡ 45b8f9de-7508-46df-aa8e-06cba0c7f046
md"Listo, ya tenemos el modelo cargado. Ahora, hay que resolver el problema. Para ello, llamamos a la función _optimize!_, pasando como parámetro nuestro modelo. JuMP se encarga de llamar al solver elegido (HiGHS en nuestro caso) y guardar los resultados:"

# ╔═╡ 14dcbef0-f779-4f1a-8e8c-0c1d53dce972
optimize!(model)

# ╔═╡ a5c452bd-a86f-460b-abb9-ac2903dcf330
md"Una vez resuelto, podemos ver si se llegó a alguna solución:"

# ╔═╡ a58d5cb5-ee53-4849-8f2b-d4043bfefd39
@show termination_status(model)

# ╔═╡ 48994b80-e5ec-4d19-acae-2e9c5108aa2f
md"En el caso de arribar a una solución óptima, podemos ver el valor de la función objetivo:"

# ╔═╡ 190f8a85-2567-4ac2-b687-ee6ddf47dc98
@show objective_value(model)

# ╔═╡ bab6e3d9-7016-4b0e-8b29-f94eff4e6b7b
md"Y el de las variables de decisión:"

# ╔═╡ 1f188080-ba38-4508-bb96-55cee778ae9c
@show value.(x)

# ╔═╡ d56b0f08-715c-4ea4-a968-c65718a5c69b
md"Podemos ver también el valor asociado a una variable de decisión en particular, en vez de todas las variables. Por ejemplo, para ver el valor de $X_2$, podemos usar __value__ (noten que se usa __value__ para una única variable, no __value.__ como en el caso de un vector de variables):"

# ╔═╡ 6c89436a-5b2e-4b5b-adb6-aead7ac3d273
@show value(x[2])

# ╔═╡ 141d28a0-7f47-4f2c-bbeb-49d6a2ab59ab
md"De cualquier maneda, __value.__ funciona igual para una única variable:" 

# ╔═╡ 6ab4884c-ad06-40b3-8946-6a09a221aa46
@show value.(x[2])

# ╔═╡ 2a6fd161-33a2-4c34-a7e6-5df12314863b
md"Pero ojo, __value__ no funciona para un vector:"

# ╔═╡ a52d6dc7-3922-4fea-a5b0-7d8b416da7f0
@show value(x)

# ╔═╡ 5c61b448-b85b-4e81-8430-ab092d276f14
md"Una mejor forma (siempre que sean pocas variables) es ver el resumen de los resultados:"

# ╔═╡ 969253bc-40af-4238-873e-9ae45b80acfc
@show solution_summary(model, verbose=true)

# ╔═╡ 4c4461c0-c2af-46de-916e-f41383df68c9
md"Con __value.__ también podemos ver el valor de los lados izquierdos de las restricciones:"

# ╔═╡ fa5b8a3d-97c9-467a-875b-9c295f761240
@show value.(r1)

# ╔═╡ cbd3edb2-3a91-4b55-ad9e-22ed21739025
@show value.(r2)

# ╔═╡ d6fc2ea9-e104-42b6-8bed-82bb330b90b5
@show value.(r3and4)

# ╔═╡ 662b5043-cbf8-48a9-81e6-428908538c3c
md"Se pueden calcular las holguras (en este caso, de las restricciones 3 y 4):"

# ╔═╡ a5e6ac72-e6df-469b-b577-907068bdd967
b3and4 - value.(r3and4)

# ╔═╡ 305d170f-30fe-417e-b4b5-cc139c0649e5
md"Y obtener los precios sombras:"

# ╔═╡ b8c7e4d3-3447-4e52-9efc-5213434690f7
@show shadow_price(r1)

# ╔═╡ c29a8073-ca5f-41dd-b7f6-242d4fe01d13
@show shadow_price(r2)

# ╔═╡ 85f66db0-49b5-4352-8c2b-f567f70d47d9
@show shadow_price(r3and4[1])

# ╔═╡ 82cc6ec6-60e4-4118-900b-eb7981d39e68
@show shadow_price(r3and4[2])

# ╔═╡ be014ce7-3734-43f2-bf9a-bf7b9074dd85
md"## Otra forma de modelarlo en Julia"

# ╔═╡ 45bed4c9-5966-4911-8afd-de8460aca986
md"La formulación anterior está basada en productos escalares. También podemos implementar la formulación equivalente en terminos de sumatorias. Creemos otra versión del modelo (vamos a agregarle la terminación _v2_, para diferenciarlo del anterior):"

# ╔═╡ 264045f0-d6d7-49ba-8589-aee3b8d3e2d7
model_v2 = Model(HiGHS.Optimizer)

# ╔═╡ 7d30f426-01a5-4ece-a7b0-dd92161e25b9
x_v2 = @variable(model_v2, x_v2[1:4] >= 0)

# ╔═╡ 88b88e3f-6ae4-457e-96c2-6a3a947e81fc
c_v2 = [4;6;7;8]

# ╔═╡ 3e03b764-efd7-4e7f-8255-437274543041
md"Usando sumatorias, la función objetivo se puede crear como:"

# ╔═╡ 25670547-f4b3-43c6-bb5b-6561084ba195
obj_v2 = @objective(model_v2, Max, 
	sum([c_v2[i] * x_v2[i] for i in 1:4]))

# ╔═╡ 79216929-23a9-401f-8c66-28f5935a47a4
md"Si, quedó un poco mas largo, pero es mas explícito lo que estamos haciendo. Lo mismo puedo hacer para las restricciones:"

# ╔═╡ 0e6d7bea-3512-46bd-b9e8-174ec9a51dda
a1_v2 = [1;1;1;1]

# ╔═╡ 19b5b744-d68b-4b4f-8f8f-0c602d3d7179
r1_v2 = @constraint(model_v2, 
	sum([a1_v2[i] * x_v2[i] for i in 1:4]) == 950)

# ╔═╡ e0f88363-3fdc-4602-b86f-7db3219ad2aa
r2_v2= @constraint(model_v2, x_v2[4] >= 400)

# ╔═╡ 763850f7-6f14-46b9-9127-f26c44df5d1c
md"Si estoy definiendo restricciones como sumatorias, también puedo definir múltiples restricciones en la misma sentencia:"

# ╔═╡ d7e28c32-21ec-4749-abea-7125b2e36be7
a3and4_v2 = [
	2 3 4 7
	3 4 5 6]

# ╔═╡ e06c213f-4409-49ee-bbd5-6c4d0f20541c
b3and4_v2 = [4600; 5000]

# ╔═╡ 67e2e076-90d9-4c21-bfe4-ffd4e662cb0a
r3and4_v2 = @constraint(model_v2, 
	[j in 1:2], #Genero dos restricciones
	sum([a3and4_v2[j,i] * x_v2[i] for i in 1:4 ]) <= b3and4_v2[j])

# ╔═╡ 89efbade-79b9-484d-9673-bf9c25059544
md"Si visualizo el modelo y lo resuelvo, puedo ver que tanto el modelo como sus resultados son los mismos modelándolo de las dos formas:"

# ╔═╡ f28c4350-148b-4abc-a4bb-b7dedc723aed
Text(model_v2)

# ╔═╡ a1436e57-e23c-44ae-8861-3b670268ed49
optimize!(model_v2)

# ╔═╡ 2a499a57-d036-4e1f-8ae2-ceef6c819ec0
@show solution_summary(model_v2, verbose=true)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
HiGHS = "~1.1.3"
JuMP = "~1.0.0"
PlutoUI = "~0.7.38"
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
git-tree-sha1 = "bf98fa45a0a4cee295de98d4c1462be26345b9a1"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.2"

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
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

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
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

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
git-tree-sha1 = "34e6147e7686a101c245f12dba43b743c7afda96"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.27"

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
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

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
git-tree-sha1 = "91b5dcf362c5add98049e6c29ee756910b03051d"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.3"

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
git-tree-sha1 = "44a7b7bb7dd1afe12bac119df6a7e540fa2c96bc"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.13"

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
git-tree-sha1 = "ba8c0f8732a24facba709388c74ba99dcbfdda1e"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.0.0"

[[NaNMath]]
git-tree-sha1 = "737a5957f387b17e74d4ad2f440eb330b39a62c5"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.0"

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
git-tree-sha1 = "670e559e5c8e191ded66fa9ea89c97f10376bb4c"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.38"

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
git-tree-sha1 = "5ba658aeecaaf96923dce0da9e703bd1fe7666f9"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.4"

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
# ╟─e5a1158e-c71f-11ec-1f06-2ba1aaa846b1
# ╠═17d6f40d-c53a-4f5c-93ba-0de5c3bc2454
# ╠═dcb11e23-90e9-45fd-938a-d009af1cf528
# ╟─00fb8cef-0a92-44e2-8078-22d05f0000c3
# ╟─d330b64b-2d70-44c0-b7b8-e872a6182efa
# ╟─d05c9518-c61e-4e0f-98d4-1957818b8494
# ╟─b5c7cc5f-51f6-4214-a2f7-8627f06dc2c9
# ╟─548a519c-e41e-482e-ad6f-171572a89015
# ╟─8ca42767-b720-4bef-b548-75cedb47671d
# ╟─6bf7649f-7a8d-48df-a35d-48a8ed687ed3
# ╟─25947bcb-e2a4-474d-854d-76995701036d
# ╟─a55ef807-7428-40f3-9006-605f6e44cc34
# ╟─559a7a85-d115-4040-aac3-a2d5e7a828fd
# ╟─32134397-1dd6-4237-8d41-6383df68bb2e
# ╠═feb2c68a-193f-4a8e-b0c2-e317c205c9d9
# ╠═c1937ebc-4fdd-4420-a221-a72a4b082815
# ╟─7a2983db-2091-4709-866d-0f59566a7129
# ╠═c69f358e-d92c-44ff-bf24-90b14620e80e
# ╟─c19baf24-c56a-4f89-aaaa-9d5a82516325
# ╠═d003da06-f38e-44ee-a488-7b76d8cefb8e
# ╟─3b005c8f-d41d-4be4-8037-86d3378f1fb2
# ╠═baf9f785-51a0-4c91-ac8b-578f4f1df002
# ╟─7d2c0c6c-8521-4379-a92e-ea8925303882
# ╠═afe6e4b6-b8e5-4b2c-ac69-d38cd0e4c076
# ╟─493671e2-ede2-48c5-8f4c-7fc5684086a0
# ╠═930d00cb-fa2e-42ad-8851-025c34dcbf49
# ╠═8203844b-044c-4a3c-92d0-779f9b5f86db
# ╟─caa37dd3-102d-4d52-ade7-1d2856ddacd6
# ╠═3e626874-2e36-45c4-aff6-2856e489be24
# ╟─ef8f067f-8419-4896-9c2d-568219652756
# ╠═cf6a89e1-be05-4864-bac3-2edb31db8a0c
# ╠═2adbfff0-233e-4977-9303-6f8a45de5ded
# ╠═f4c69968-d9ad-4b58-b77e-1a86813d9217
# ╟─d6bad884-7b9f-4c60-ab19-ef4966540edd
# ╠═44facdfb-84b1-4b6b-b413-bc9929413f15
# ╟─45b8f9de-7508-46df-aa8e-06cba0c7f046
# ╠═14dcbef0-f779-4f1a-8e8c-0c1d53dce972
# ╟─a5c452bd-a86f-460b-abb9-ac2903dcf330
# ╠═a58d5cb5-ee53-4849-8f2b-d4043bfefd39
# ╟─48994b80-e5ec-4d19-acae-2e9c5108aa2f
# ╠═190f8a85-2567-4ac2-b687-ee6ddf47dc98
# ╟─bab6e3d9-7016-4b0e-8b29-f94eff4e6b7b
# ╠═1f188080-ba38-4508-bb96-55cee778ae9c
# ╟─d56b0f08-715c-4ea4-a968-c65718a5c69b
# ╠═6c89436a-5b2e-4b5b-adb6-aead7ac3d273
# ╟─141d28a0-7f47-4f2c-bbeb-49d6a2ab59ab
# ╠═6ab4884c-ad06-40b3-8946-6a09a221aa46
# ╟─2a6fd161-33a2-4c34-a7e6-5df12314863b
# ╠═a52d6dc7-3922-4fea-a5b0-7d8b416da7f0
# ╟─5c61b448-b85b-4e81-8430-ab092d276f14
# ╠═969253bc-40af-4238-873e-9ae45b80acfc
# ╟─4c4461c0-c2af-46de-916e-f41383df68c9
# ╠═fa5b8a3d-97c9-467a-875b-9c295f761240
# ╠═cbd3edb2-3a91-4b55-ad9e-22ed21739025
# ╠═d6fc2ea9-e104-42b6-8bed-82bb330b90b5
# ╟─662b5043-cbf8-48a9-81e6-428908538c3c
# ╠═a5e6ac72-e6df-469b-b577-907068bdd967
# ╟─305d170f-30fe-417e-b4b5-cc139c0649e5
# ╠═b8c7e4d3-3447-4e52-9efc-5213434690f7
# ╠═c29a8073-ca5f-41dd-b7f6-242d4fe01d13
# ╠═85f66db0-49b5-4352-8c2b-f567f70d47d9
# ╠═82cc6ec6-60e4-4118-900b-eb7981d39e68
# ╟─be014ce7-3734-43f2-bf9a-bf7b9074dd85
# ╟─45bed4c9-5966-4911-8afd-de8460aca986
# ╠═264045f0-d6d7-49ba-8589-aee3b8d3e2d7
# ╠═7d30f426-01a5-4ece-a7b0-dd92161e25b9
# ╠═88b88e3f-6ae4-457e-96c2-6a3a947e81fc
# ╟─3e03b764-efd7-4e7f-8255-437274543041
# ╠═25670547-f4b3-43c6-bb5b-6561084ba195
# ╟─79216929-23a9-401f-8c66-28f5935a47a4
# ╠═0e6d7bea-3512-46bd-b9e8-174ec9a51dda
# ╠═19b5b744-d68b-4b4f-8f8f-0c602d3d7179
# ╠═e0f88363-3fdc-4602-b86f-7db3219ad2aa
# ╟─763850f7-6f14-46b9-9127-f26c44df5d1c
# ╠═d7e28c32-21ec-4749-abea-7125b2e36be7
# ╠═e06c213f-4409-49ee-bbd5-6c4d0f20541c
# ╠═67e2e076-90d9-4c21-bfe4-ffd4e662cb0a
# ╟─89efbade-79b9-484d-9673-bf9c25059544
# ╠═f28c4350-148b-4abc-a4bb-b7dedc723aed
# ╠═a1436e57-e23c-44ae-8861-3b670268ed49
# ╠═2a499a57-d036-4e1f-8ae2-ceef6c819ec0
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ df1df4dd-01e3-4da7-8e2b-ea6c96220ee5
using PlutoUI

# ╔═╡ d99488c7-7003-4bc3-ba9b-87c8b05592cb
using JuMP, HiGHS

# ╔═╡ 62598918-ca1a-11ec-20be-c97e53b0cbff
md"# Programando la producción"

# ╔═╡ fd28ca11-d824-49c2-9ac8-17d6635308e0
TableOfContents(title="Contenido")

# ╔═╡ a540f085-c5c9-40d8-8f87-f6dad7eaf1b6
md"## Planificación de las cantidades a producir"

# ╔═╡ 86b7ee8e-fbbe-4470-bf02-4086a96a1435
md"Vamos a recordar el problema 1 de la cartilla de ejercicios 1:

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
> El objetivo de Winco es maximizar sus ingresos por las ventas. 

Si bien ya lo resolvimos en un notebook anterior, vamos a modelarlo en este."

# ╔═╡ ac7e19b6-fc1c-4d6b-83d4-70f82b45283a
md"### Objetivos y variable de decisión"

# ╔═╡ 383e95da-9aa6-4fda-bf1e-e1069e0a1ea4
md"La detección de las variables de decisión y el objetivo del problema, suelen ir de la mano en muchos poblemas. Si leemos el enunciado del problema, dice explicitamente que Winco quiere maximizar sus ganancias, así que el objetivo debería ser ese. Y por otro lado, la única decisión que puede tomar Winco es acerca de cuanto producir de cada artículo. No puede elegir cambiar la cantidad de materia prima disponible, ni las horas de trabajo disponible, ni los estándares de trabajo (ya sea de horas o de materia prima) ni los precios de venta. 

Como solo se puede decidir acerca de la cantidad a producir de cada artículo, definamos estas magnitudes como variables de decisión:

$x_{i} \in \mathbb{R}, \ con \ i \in \{1,2,3,4\}$

Es decir, tenemos 4 variables de decisión reales, $x_{1}$, $x_{2}$, $x_{3}$ y $x_{4}$ (genericamente, $x_{i}$). Notemos que la notación $x_{i}$ me permitiría reutilizar la formulación con cualquier número de producto. En dicho caso, $i$ es una referencia al producto apuntado. 

Cualquier conjunto de valores de nuestras variables de decisión define a una solución potencial. Como, por ejemplo, $x_{1}=0$, $x_{2}=10$, $x_{3}=306.7632$ y $x_{4}=-3$. En forma mas compacta, $\vec{x}=(0, 10, 306.7632, -3)$. Que esta solución sea válida o no (factible, en términos de problemas de programación lineal) es otro cantar. 

¿Como podemos expresar el ingreso por ventas que obtendriamos para una solución potencial determinada? Bueno, en este problema, el ingreso por ventas se determina multiplicando el precio unitario de venta por la cantidad producida de un determinado artículo (se supone que la demanda absorbe la producción). O sea, para calcular el ingreso asociado al producto 1, tenemos que multiplicar $4$ por la cantidad producida, es decir, $x_{i}$. Repitiendo el mismo cálculo para cada producto y sumando los resultados, obtenemos nuestro ingreso por ventas, el cual es el objetivo a maximizar. Si denominamos $p_{i}$ al precio del artículo $i$:

Max $Z=\sum_{i=1}^{4}p_{i}x_{i}$

O, en forma extensa:

Max $Z=p_{1}*x_{1} + p_{2}*x_{2} + p_{3}*x_{3} + p_{4}*x_{4}$

O, expresando los valores de $p_{i}$:

Max $Z=4x_{1} + 6x_{2} + 7x_{3} + 8x_{4}$

Las tres formas de escribir la función $Z$ son equivalente para este problema. Pero la primera es mucho mas compacta. Y, las dos primeras, son reutilizables en un problema del mismo tipo pero con diferentes valores de precio unitario de venta. "

# ╔═╡ d00dbdaf-6034-4770-a423-3f846fd5999c
md"### Restricciones"

# ╔═╡ 53de617e-643e-4a99-9df8-782548a43360
md"En la sección anterior dijimos que cualquier conjunto de valores para nuestras $x_{i}$ es una solución potencial, pero no todas las soluciones potenciales son factibles. En este problema, debo cumplir con la cantidad de $950$ unidades fabricadas en total, un mínimo de $400$ unidades del producto 4, no gastar mas materia prima de la disponible, ni mas horas de trabajo de las disponibles. Todo ello se expresa mediente las ecuaciones e inecuaciones que componen el conjunto de restricciones del problema.

La primer restricción me dice que que tengo que fabricar en total $950$ unidades. Es decir, la cantidad de productos $1$, $2$, $3$ y $4$ sumadas debe dar $950$. En forma de ecuación, si llamamos a la demanda total $DT$:

$\sum_{i=1}^{4}x_{i}=DT$

O, en forma extensa:

$x_{1} + x_{2} + x_{3} + x_{4} = 950$

Por otro lado, debo fabricar como mínimo $400$ unidades del artículo $4$. Si llamamos a esta cantidad $DMin_{4}$:

$x_{4} \geq DMin_{4}$

O en forma extensa (o explícita):

$x_{4} \geq 400$

Por otro lado, no tengo que consumir mas materia prima que la disponible. Si llamo $m_{i}$ a la cantidad de materia prima que necesita una unidad del producto $i$, y $MP$ a la cantidad de materia prima total:

$\sum_{i=1}^{4}m_{i}x_{i} \leq MP$

O, en forma mas extensa:

$2x_{1} + 3x_{2} + 4x_{3} + 7x_{4} \leq 4600$

Por el lado de las horas disponibles, la formulación es similar al caso de la materia prima. Si llamamos $h_{i}$ a la cantidad de horas de trabajo que necesita una unidad del producto $i$ y $HT$ a la cantidad de horas de trabajo totales:

$\sum_{i=1}^{4}h_{i}x_{i} \leq HT$

O, en forma mas extensa:

$3x_{1} + 4x_{2} + 5x_{3} + 6x_{4} \leq 5000$

Por último, ninguna variable de decisión puede tomar valores negativos:

$x_{i}\geq 0$

O en forma extensa:

$x_{1}\geq 0$
$x_{2}\geq 0$
$x_{3}\geq 0$
$x_{4}\geq 0$
"

# ╔═╡ 90fd45c8-822f-4757-8c14-0c4b6d7733dc
md"### Problema completo"

# ╔═╡ 9518e425-e804-4e94-9974-8519f23886f1
md"El problema completo en forma compacta (en realidad, podría ser mas compacto todavía) es:

$Max \ Z=\sum_{i=1}^{4}p_{i}x_{i}$

Sujeto a:

$\sum_{i=1}^{4}x_{i}=DT$

$x_{4} \geq DMin_{4}$

$\sum_{i=1}^{4}m_{i}x_{i} \leq MP$

$\sum_{i=1}^{4}h_{i}x_{i} \leq HT$

$x_{i}\geq 0$

En forma extensa (o explícita):

$Max \ Z=4x_{1} + 6x_{2} + 7x_{3} + 8x_{4}$

Sujeto a:

$x_{1} + x_{2} + x_{3} + x_{4} = 950$

$x_{4} \geq 400$

$2x_{1} + 3x_{2} + 4x_{3} + 7x_{4} \leq 4600$

$3x_{1} + 4x_{2} + 5x_{3} + 6x_{4} \leq 5000$

$x_{1}\geq 0$
$x_{2}\geq 0$
$x_{3}\geq 0$
$x_{4}\geq 0$

La forma compacta nos permite establecer una familia de problemas, mientras que la forma extensa nos permite especificar un problema puntual. Fijémosnos que, cualesquiera sean los valores que tomen $DT$, $Dmin_{4}$, $p_{i}$, $h_{i}$ y $m_{i}$, la forma compacta es todavía válida.
"

# ╔═╡ 6016878a-6800-42a3-a96e-ca153e1f5304
md"### Resolución"

# ╔═╡ 21d06573-3380-4552-bc3e-eff4b6aead29
md"A continuación, el código Julia para resolver el problema."

# ╔═╡ 89088218-0d57-4fa9-804a-4809a6d7fde6
model = Model(HiGHS.Optimizer)

# ╔═╡ c25dbd8e-f24c-4f5c-845d-f4c3187b1059
x = @variable(model, x[1:4] >= 0)

# ╔═╡ aaec3799-14af-4bcd-a61a-9a8c28bc73c8
c = [4;6;7;8]

# ╔═╡ 087af842-ca86-4cd5-87a6-cf40cf0f846c
obj = @objective(model, Max, c' * x)

# ╔═╡ 0a18987c-1a11-4074-80c1-d4e3ee2cef85
a1 = [1;1;1;1]

# ╔═╡ fc29bbff-c8a3-498a-b352-6a055713ddb8
r1 = @constraint(model, a1' * x == 950)

# ╔═╡ 39e46ce1-d9cf-4761-98a1-520b0bfd5dc4
r2= @constraint(model, x[4] >= 400)

# ╔═╡ 22e35d51-59e8-4b9c-9a36-3ff12f692922
a3and4 = [
	2 3 4 7
	3 4 5 6]

# ╔═╡ 85b3259a-654a-4ee7-bf72-77d4687dbd7c
b3and4 = [4600; 5000]

# ╔═╡ 31cf1712-fc8e-463e-b525-809c6a926f55
r3and4 = @constraint(model, a3and4 * x .<= b3and4)

# ╔═╡ 3d796053-7b79-40ab-9641-71fa62a7b1be
Text(model)

# ╔═╡ 93af8cae-2ed5-4201-8e7e-acab21ac0e2b
optimize!(model)

# ╔═╡ 77e3981e-c4a3-45fe-b457-cf8bf2353c46
@show termination_status(model)

# ╔═╡ 7bfd1b68-074e-4446-b6f3-b6ea5dcbc2a6
@show objective_value(model)

# ╔═╡ 689d73e4-ad42-48cd-8e16-a45d06817a84
@show value.(x)

# ╔═╡ 400ef579-27e6-4912-93ae-8aefe90ed0fa
@show solution_summary(model, verbose=true)

# ╔═╡ 423d3e0d-4937-4276-bf2e-492ba609e38f
md"## Planificación de las cantidades a producir con recursos variables (MP)"

# ╔═╡ d8fb5b82-bfa7-4759-9afd-9b31131edac3
md"Supongamos ahora que en el problema anterior, exista la posibilidad de adquirir mas materia prima (que, como vimos en los resultados anteriores, la cantidad de materia prima es un cuello de botella). La formulación del nuevo problema podría ser:

> Winco vende cuatro tipos de productos. Para satisfacer las demandas de los clientes, hay que producir exactamente $950$ unidades en total y por lo menos $400$ unidades del producto 4.
En la tabla a continuación se dan los recursos requeridos para producir una unidad de cada producto y los precios de venta de cada uno. 

$\begin{array}{lcccc}
	\hline
	\text{Concepto} & \text{Producto 1} & \text{Producto 2}& \text{Producto 3} &\text{Producto 4}\\
	\hline
	\text{Materia Prima} & 2 & 3 & 4 & 7\\
	\text{Horas de trabajo} & 3 & 4 & 5 & 6\\
	\text{Precio de venta} & 4 & 6 & 7 & 8\\
	\hline
\end{array}$


> En la actualidad, se dispone de $4600$ unidades de materia prima y $5000$ horas de trabajo. Se pueden adquirir mas unidades de materia prima a un costo de $0.50$ por unidad de materia prima. Se pueden comprar, como máximo, $100$ unidades extras de materia prima.
> El objetivo de Winco es maximizar sus ingresos por las ventas. 


"

# ╔═╡ 8dcac0cc-5840-4a29-bbc1-bc15c7c9b384
md"### Objetivos y variable de decisión"

# ╔═╡ 49a04fe7-43cb-432f-a092-34fb778f0e06
md"En este nuevo problema, nuestras variables de decisión siguen siendo las cantidades a producir:

$x_{i} \in \mathbb{R}, \ con \ i \in \{1,2,3,4\}$

Pero, resulta que ahora también podemos decidir si compramos materia prima extra y cuanta cantidad. Para modelar esto, podríamos pensar en una nueva variable $w \in \mathbb{R}$, que represente la cantidad de materia prima extra a comprar (en caso de valer $0$, significa que no compro nada).

Ahora bien, resulta que esta cantidad extra de materia prima conlleva un costo extra (noten que para los niveles de stock actuales de materia prima y horas no estamos asumiendo ningún costo por ahora, suponemos que están disponibles y ya son un costo hundido). Este costo extra afecta a los ingresos que obtenemos, por lo cual la función objetivo se debe reformular a:

$Max \ Z=\sum_{i=1}^{4}p_{i}x_{i} - cmp\cdot w$

O, en forma extensa:

$Max \ Z=p_{1}*x_{1} + p_{2}*x_{2} + p_{3}*x_{3} + p_{4}*x_{4} - cmp\cdot w$

O, expresando los valores de $p_{i}$:

$Max \ Z=4x_{1} + 6x_{2} + 7x_{3} + 8x_{4} - 0.5w$

Donde $cmp$ es el costo de una unidad de materia prima extra.

"

# ╔═╡ 7d0f0a1a-3b55-413d-97fe-a3c06fe099ec
md"### Restricciones"

# ╔═╡ 7cdbd21a-22a9-49ec-9bc1-2380eca5c530
md"Las restricciones 1, 2 y 4 se mantienen sin cambios, pero la restricción de materia prima debe ser modificada, ya que ahora la cantidad de MP es variable. Es decir, la materia prima disponible es ahora igual a $MP + w$. Sabiendo esto, y recordando que las variables de decisión van en el lado izquierdo, la restriccion de materia prima se puede reescribir como:

$\sum_{i=1}^{4}m_{i}x_{i} - w \leq MP$

O, en forma mas extensa:

$2x_{1} + 3x_{2} + 4x_{3} + 7x_{4} - w \leq 4600$


La cantidad de materia prima extra que puedo comprar no es ilimitada, así que debo restringir su valor máximo (al cual llamamos $MaxMpExtra$):

$w \leq MaxMpExtra$

O en forma explícita:

$w \leq 100$


Por último, $w$ no puede tomar valores negativos:

$w \geq 0$

"

# ╔═╡ f79caecb-3592-46d4-9fd8-298f0c47dea1
md"### Problema completo"

# ╔═╡ 6cbb2669-7dd0-4b76-97c8-af99a186e3cf
md"El problema completo en forma compacta es:

$Max \ Z=\sum_{i=1}^{4}p_{i}x_{i} - cmp\cdot w$

Sujeto a:

$\sum_{i=1}^{4}x_{i}=DT$

$x_{4} \geq DMin_{4}$

$\sum_{i=1}^{4}m_{i}x_{i} - w\leq MP$

$\sum_{i=1}^{4}h_{i}x_{i} \leq HT$

$w \leq MaxMpExtra$

$x_{i}\geq 0$

$w \geq 0$


En forma extensa (o explícita):

$Max \ Z=4x_{1} + 6x_{2} + 7x_{3} + 8x_{4} - 0.5w$

Sujeto a:

$x_{1} + x_{2} + x_{3} + x_{4} = 950$

$x_{4} \geq 400$

$2x_{1} + 3x_{2} + 4x_{3} + 7x_{4} - w\leq 4600$

$3x_{1} + 4x_{2} + 5x_{3} + 6x_{4} \leq 5000$

$w \leq 100$

$x_{1}\geq 0, x_{2}\geq 0, x_{3}\geq 0, x_{4}\geq 0$

$w \geq 0$

"

# ╔═╡ 70c89896-81b5-4850-a1fd-95f142a1fea7
md"### Resolución"

# ╔═╡ 02bd199a-6c8d-4696-baf6-b05698d04f38
md"A continuación la resolución. Fijémosnos que los cambios son mínimos."

# ╔═╡ b0acb185-c4f1-40af-9d52-9e60a27e46bd
model2 = Model(HiGHS.Optimizer)

# ╔═╡ 7a968fee-09e8-4df1-b397-b5c7030eacf7
x_m2 = @variable(model2, x_m2[1:4] >= 0)

# ╔═╡ 2db24516-830c-4f76-871f-e51e87f91638
w_m2 = @variable(model2, w_m2 >= 0)

# ╔═╡ 978d146c-6f02-4d39-b8e2-1e15db103b5d
c_m2 = [4;6;7;8;-0.5]

# ╔═╡ 79aa5ddd-19a0-412b-b121-85af900ecf87
md"Observen como, al crear la función objetivo, se concatenaron las variables en un único vector. __[x_m2;w_m2]__ es el vector cuyas primeras cuatro componentes apuntan a nuestras variables _x_, y la quinta a la variable _w_, es decir __[x_m2[1];x_m2[2];x_m2[3];x_m2[4];w_m2]__."

# ╔═╡ 1480da0e-f605-47f1-86b2-ca15d93021f7
obj_m2 = @objective(model2, Max, c_m2' * [x_m2;w_m2]) #Acá se concatenaron las variables en un único vector ([x_m2;w_m2] es ahora el vector de nuestras 5 variables de decisión).

# ╔═╡ 46b4b097-793b-45fc-b0c5-f06ebf714501
a1_m2 = [1;1;1;1]

# ╔═╡ c390945b-940f-4f78-9ae7-251b0850c2f0
r1_m2 = @constraint(model2, a1_m2' * x_m2 == 950)

# ╔═╡ d0458826-ef24-420d-92e5-edd514f5fa68
r2_m2= @constraint(model2, x_m2[4] >= 400)

# ╔═╡ 572aeb67-46a6-4656-87b9-56132647f032
a3and4_m2 = [
	2 3 4 7 -1
	3 4 5 6 0]

# ╔═╡ 31850a4a-a5e5-4e4e-9df6-bef03ccec7d1
b3and4_m2 = [4600; 5000]

# ╔═╡ a77dd882-450a-4f4a-ab57-8ebf2358d2c3
r3and4_m2 = @constraint(model2, a3and4_m2 * [x_m2;w_m2] .<= b3and4_m2)

# ╔═╡ 57002765-f027-490c-81f5-be1d19b5a795
r5_m2= @constraint(model2, w_m2 <= 100)

# ╔═╡ cd0d82be-55b6-4c30-8934-12227b3ec4aa
Text(model2)

# ╔═╡ dbd13bd3-6967-401c-8b90-128267f097b8
md"Puedo consolidar la sección de resultados en una sola celda, con _'begin-end'_:"

# ╔═╡ e4e86464-547c-4bca-995c-71c231a6f14a
begin
	optimize!(model2)

	@show solution_summary(model2, verbose=true)
end

# ╔═╡ 2b224a52-307b-4a62-9be6-27fcfa75ee7c
md"## Planificación de las cantidades a producir con recursos variables (horas totales) "

# ╔═╡ de6c89cc-3d96-488e-a4e3-f10b3765ea65
md"Supongamos ahora que en el problema anterior, existe la posibilidad de realizar horas extras. La formulación del nuevo problema podría ser:"

# ╔═╡ 43944518-74f7-437f-9f16-1afedddc0034
md"> Winco vende cuatro tipos de productos. Para satisfacer las demandas de los clientes, hay que producir exactamente $950$ unidades en total y por lo menos $400$ unidades del producto 4.
En la tabla a continuación se dan los recursos requeridos para producir una unidad de cada producto y los precios de venta de cada uno. 

$\begin{array}{lcccc}
	\hline
	\text{Concepto} & \text{Producto 1} & \text{Producto 2}& \text{Producto 3} &\text{Producto 4}\\
	\hline
	\text{Materia Prima} & 2 & 3 & 4 & 7\\
	\text{Horas de trabajo} & 3 & 4 & 5 & 6\\
	\text{Precio de venta} & 4 & 6 & 7 & 8\\
	\hline
\end{array}$

> En la actualidad, se dispone de $4600$ unidades de materia prima y $5000$ horas de trabajo. Se pueden adquirir mas unidades de materia prima a un costo de $0.50$ por unidad de materia prima. Se pueden comprar, como máximo, $100$ unidades extras de materia prima. 

> Por otro lado, existe la posibilidad de realizar horas extras. Se puede realizar un máximo de 500 horas extras al 50% y un máximo de 200 al 100%. Las primeras tienen un costo de $0.20$ por hora, y las segundas un costo de $0.50$.

> El objetivo de Winco es maximizar sus ingresos por las ventas.
"

# ╔═╡ 003e6d35-9a7b-46e8-9409-02d99a0eb787
md"### Objetivos y variable de decisión"

# ╔═╡ f8d917de-fb64-4471-a701-933ea18bea69
md"En este nuevo problema, nuestras variables de decisión siguen siendo las cantidades a producir:

$x_{i} \in \mathbb{R}, \ con \ i \in \{1,2,3,4\}$

Pero, resulta que ahora también podemos decidir si compramos materia prima extra y cuanta cantidad. Para modelar esto, podríamos pensar en una nueva variable $w \in \mathbb{R}$, que represente la cantidad de materia prima extra a comprar (en caso de valer $0$, significa que no compro nada). Por otro lado, también podemos hacer horas extras, por lo que podemos pensar en las variables $u_{50} \in \mathbb{R}$ y $u_{100} \in \mathbb{R}$ para modelar la cantidad de horas extras al 50% y 100% respectivamente.

Tanto la materia prima adicional como las horas extras tienen costo. Este costo extra afecta a los ingresos que obtenemos, por lo cual la función objetivo se debe reformular a:

$Max \ Z=\sum_{i=1}^{4}p_{i}x_{i} - cmp\cdot w - ch50\cdot u_{50} - ch100\cdot u_{100}$ 

O, en forma extensa:

$Max \ Z=p_{1}*x_{1} + p_{2}*x_{2} + p_{3}*x_{3} + p_{4}*x_{4} - cmp\cdot w - ch50\cdot u_{50} - ch100\cdot u_{100}$

O, expresando los valores de los coeficientes:

$Max \ Z=4x_{1} + 6x_{2} + 7x_{3} + 8x_{4} - 0.5w - 0.2u_{50} - 0.5u_{100}$

Donde $cmp$ es el costo de una unidad de materia prima extra, $ch50$ el costo de las horas extras al $50\%$ y $ch100$ el costo de las horas extras al $100\%$.
"

# ╔═╡ ade5c017-9780-46a1-9755-262c56e53b68
md"### Restricciones"

# ╔═╡ 409e831b-032c-4447-9a3c-9afe379ccdba
md"Las restricciones 1, 2 y 3 se mantienen sin cambios respecto del [ejercicio anterior](#Seccion02), pero la restricción de horas hombres debe ser modificada para tomar en cuenta el incremento de horas de trabajo totales debido a la posibilidad de realizar horas extras:

$\sum_{i=1}^{4}h_{i}x_{i} - u_{50} - u_{100}\leq HT$

O, en forma mas extensa:

$3x_{1} + 4x_{2} + 5x_{3} + 6x_{4} - u_{50} - u_{100}\leq 5000$

Además, necesitamos dos restricciones para limitar la cantidad máxima de horas hombres, así como forzar a que las dos nuevas variables sean no negativas:

$u_{50} \leq MaxHE50$
$u_{100} \leq MaxHE100$

$u_{50} \geq 0$
$u_{100} \geq 0$
"

# ╔═╡ b060bad4-ce64-40df-bf95-4599b51ef9f7
md"### Problema completo"

# ╔═╡ dc743fa4-c1d9-47d5-8035-da1b6fd6f6a7
md"El problema completo en forma compacta es:

$Max \ Z=\sum_{i=1}^{4}p_{i}x_{i} - cmp\cdot w - ch50\cdot u_{50} - ch100\cdot u_{100}$

Sujeto a:

$\sum_{i=1}^{4}x_{i}=DT$

$x_{4} \geq DMin_{4}$

$\sum_{i=1}^{4}m_{i}x_{i} - w\leq MP$

$\sum_{i=1}^{4}h_{i}x_{i} - u_{50} - u_{100}\leq HT$

$w \leq MaxMpExtra$

$u_{50} \leq MaxHE50$

$u_{100} \leq MaxHE100$

$x_{i}\geq 0$

$w \geq 0$

$u_{50} \geq 0$

$u_{100} \geq 0$"

# ╔═╡ 8af7c24c-de0c-4985-9028-36f83b7c5414
md"En forma extensa (o explícita):

$Max \ Z=4x_{1} + 6x_{2} + 7x_{3} + 8x_{4} - 0.5w - 0.2u_{50} - 0.5u_{100}$

Sujeto a:

$x_{1} + x_{2} + x_{3} + x_{4} = 950$

$x_{4} \geq 400$

$2x_{1} + 3x_{2} + 4x_{3} + 7x_{4} - w\leq 4600$

$3x_{1} + 4x_{2} + 5x_{3} + 6x_{4} \leq 5000$

$3x_{1} + 4x_{2} + 5x_{3} + 6x_{4} - u_{50} - u_{100} \leq 5000$

$w \leq 100$

$u_{50} \leq 500$

$u_{100} \leq 200$

$x_{1}\geq 0, x_{2}\geq 0, x_{3}\geq 0, x_{4}\geq 0$

$w \geq 0$

$u_{50} \geq 0$

$u_{100} \geq 0$"

# ╔═╡ 66b15ff3-6fe4-48b5-aeae-b071be3c923c
md"### Resolución"

# ╔═╡ f57792c2-1447-43a8-918a-db28572e1730
md"Escribir un montón de celdas es un lío. Usemos los bloques _'begin-end'_ para agrupar celdas:"

# ╔═╡ 41f5d2e9-44cd-4f50-8ce1-d512fe7a4a8e
begin
	model3 = Model(HiGHS.Optimizer)

	# Variables de decisión
	x_m3 = @variable(model3, x_m3[1:4] >= 0)
	w_m3 = @variable(model3, w_m3 >= 0)
	u_m3 = @variable(model3, u_m3[1:2] >= 0)

	# Coeficientes de la función objetivo
	precio_venta_m3 = [4;6;7;8]
	costo_mp_m3 = -0.5
	costo_hh_extras_m3 = [-0.2;-0.5]

	# Función objetivo
	obj_m3 = @objective(model3, Max,
		[precio_venta_m3;costo_mp_m3;costo_hh_extras_m3]' * [x_m3;w_m3;u_m3])

	# A la restricción 1 la puedo escribir mas fácil, ya que el lado izquierdo es la suma de las Xs
	r1_m3 = @constraint(model3, sum(x_m3) == 950)

	# La restricción 2 queda igual
	r2_m3= @constraint(model3, x_m3[4] >= 400)

	# Para las restricciones 3 y 4, en vez de definir a priori la matriz de coeficientes, podemos definir cada sub-matriz y gestionar cada restricción por separado. Observen como no es necesario agrupar todas las variable en el lado izquierdo, JuMP lo hace automáticamente:
	consumo_mp_m3 = [2;3;4;7] 
	r3_m3 = @constraint(model3, consumo_mp_m3' * x_m3 <= 4600 + w_m3) 

	consumo_hs_m3 = [3;4;5;6]
	r4_m3 = @constraint(model3, consumo_hs_m3' * x_m3 <= 5000 + sum(u_m3))
	
	# La restricción 5 queda igual
	r5_m3= @constraint(model3, w_m3 <= 100)

	# Agregamos las restricciones 6 y 7
	maximas_he_m3 = [500;200]
	r6y7_m3= @constraint(model3, u_m3 .<= maximas_he_m3)
	
	Text(model3)

end

# ╔═╡ 6f53f1fb-ea87-4c91-9a4a-0edca3bb658d
begin

	optimize!(model3)
	
	@show solution_summary(model3, verbose=true)
end

# ╔═╡ dd84d139-2b1a-4705-a958-fe3edd4e8544
md"## Planificación de las cantidades a producir con recursos variables y tolerancia en la demanda"

# ╔═╡ 1ad27015-eb95-427f-bd04-5e5549e9a061
md"Supongamos ahora que en el problema anterior, existe la posibilidad de entregar menos unidades del producto 4, pero a costa de una penalización. La formulación del nuevo problema podría ser:

> Winco vende cuatro tipos de productos. Para satisfacer las demandas de los clientes, hay que producir exactamente $950$ unidades en total y por lo menos $400$ unidades del producto 4. Existe una tolerancia de hasta $20$ unidades faltantes en las cantidades del producto 4, pero con una penalización de $0.2$ por unidad de producto 4 no entregada.

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

> En la actualidad, se dispone de $4600$ unidades de materia prima y $5000$ horas de trabajo. Se pueden adquirir mas unidades de materia prima a un costo de $0.50$ por unidad de materia prima. Se pueden comprar, como máximo, $100$ unidades extras de materia prima. 

> Por otro lado, existe la posibilidad de realizar horas extras. Se puede realizar un máximo de 500 horas extras al 50% y un máximo de 200 al 100%. Las primeras tienen un costo de $0.20$ por hora, y las segundas un costo de $0.50$.

> El objetivo de Winco es maximizar sus ingresos por las ventas.


"

# ╔═╡ 2af7ab35-51f3-4228-9fbd-8861cb611c68
md"### Objetivos y variable de decisión"

# ╔═╡ 961bbe51-5c0a-493a-b75e-4218c668651a
md"En este nuevo problema, nuestras variables de decisión siguen siendo las cantidades a producir, la cantidad de materia prima adicional y las horas extras:

$x_{i} \in \mathbb{R}, \ con \ i \in \{1,2,3,4\}$

$w \in \mathbb{R}$

$u_{j} \in \mathbb{R}, \ con \ j \in \{50, 100\}$

Pero ahora necesitamos una nueva variable $t$ que indique cuantas unidades de producto 4 tenemos de faltantes (es decir, cuanta demanda del producto 4 vamos a decidir dejar de satisfacer).

La función objetivo queda entonces como:

$Max \ Z=\sum_{i=1}^{4}p_{i}x_{i} - cmp\cdot w - ch50\cdot u_{50} - ch100\cdot u_{100} - penalizacion\cdot t$ 

O, en forma extensa:

$Max \ Z=p_{1}*x_{1} + p_{2}*x_{2} + p_{3}*x_{3} + p_{4}*x_{4} - cmp\cdot w - ch50\cdot u_{50} - ch100\cdot u_{100} - penalizacion\cdot t$

O, expresando los valores de los coeficientes:

$Max \ Z=4x_{1} + 6x_{2} + 7x_{3} + 8x_{4} - 0.5w - 0.2u_{50} - 0.5u_{100} - 0.2t$

Donde $cmp$ es el costo de una unidad de materia prima extra, $ch50$ el costo de las horas extras al $50\%$ y $ch100$ el costo de las horas extras al $100\%$.

"

# ╔═╡ 7ae4b30d-d439-4cf4-9f88-7fbcb9b914d9
md"### Restricciones"

# ╔═╡ 624990c4-763a-497b-8863-9efee8497ca5
md"Respecto del problema anterior, solo se modifica la restricción de la cantidad mínima de producto 4, a su vez que se agregan las restricciones de las cotas a los faltantes del producto 4:

$x_{4} + t \geq DMin_{4}$

$t \leq MaxFaltante$

$t \geq 0$

Noten que la ecuación $x_{4} + t \geq DMin_{4}$ se puede escribir como $x_{4} \geq DMin_{4} - t$, la cual indica que lo que decido fabricar del producto 4 tiene que ser igual o mayor a mi demanda mínima menos la cantidad de demanda que decido no satisfacer.

"

# ╔═╡ f380f772-448e-4928-a096-11e813064f2f
md"### Problema completo"

# ╔═╡ 7b9b70ee-2861-4cff-8527-a46cbad82c69
md"El problema completo en forma compacta es:

$Max \ Z=\sum_{i=1}^{4}p_{i}x_{i} - cmp\cdot w - ch50\cdot u_{50} - ch100\cdot u_{100} - penalizacion\cdot t$

Sujeto a:

$\sum_{i=1}^{4}x_{i}=DT$

$x_{4} + t \geq DMin_{4}$

$\sum_{i=1}^{4}m_{i}x_{i} - w\leq MP$

$\sum_{i=1}^{4}h_{i}x_{i} - u_{50} - u_{100}\leq HT$

$w \leq MaxMpExtra$

$u_{50} \leq MaxHE50$

$u_{100} \leq MaxHE100$

$x_{4} + t \geq DMin_{4}$

$t \leq MaxFaltante$

$x_{i}\geq 0$

$w \geq 0$

$u_{50} \geq 0$

$u_{100} \geq 0$

$t \geq 0$"

# ╔═╡ 46f5c604-ca82-4bda-9430-73c6a5bb7383
md"En forma extensa (o explícita):

$Max \ Z=4x_{1} + 6x_{2} + 7x_{3} + 8x_{4} - 0.5w - 0.2u_{50} - 0.5u_{100} - 0.2t$

Sujeto a:

$x_{1} + x_{2} + x_{3} + x_{4} = 950$

$x_{4} + t \geq 400$

$2x_{1} + 3x_{2} + 4x_{3} + 7x_{4} - w\leq 4600$

$3x_{1} + 4x_{2} + 5x_{3} + 6x_{4} \leq 5000$

$3x_{1} + 4x_{2} + 5x_{3} + 6x_{4} - u_{50} - u_{100} \leq 5000$

$w \leq 100$

$u_{50} \leq 500$

$u_{100} \leq 200$

$t \leq 20$

$x_{1}\geq 0, x_{2}\geq 0, x_{3}\geq 0, x_{4}\geq 0$

$w \geq 0$

$u_{50} \geq 0$

$u_{100} \geq 0$

$t \geq 0$"

# ╔═╡ fecbba66-d97f-4dc8-9525-f2294833978b
md"### Resolución"

# ╔═╡ 77cdab72-5d1d-45ff-95bc-d48632f4ce65
begin
	model4 = Model(HiGHS.Optimizer)

	# Variables de decisión. Mismo enfoque, pero reformulado un poco. Porque, si tenemos restricciones que acoten a una única variable, podemos escribir esos límites en la declaración de la variables:
	maxima_mp_m4 = 100
	maximas_he_m4 = [500;200]
	maximo_faltante_producto_4_m4 = 20
	x_m4 = @variable(model4, x_m4[1:4] >= 0)
	w_m4 = @variable(model4, 0 <= w_m4 <= maxima_mp_m4)
	u_m4 = @variable(model4, 0 <= u_m4[h=1:2] <= maximas_he_m4[h])
	t_m4 = @variable(model4, 0 <= t_m4 <= maximo_faltante_producto_4_m4)

	# Coeficientes de la función objetivo
	precio_venta_m4 = [4;6;7;8]
	costo_mp_m4 = -0.5
	costo_hh_extras_m4 = [-0.2;-0.5]
	penalizacion_faltante_4_m4 = -0.2

	# Función objetivo
	obj_m4 = @objective(model4, Max,
		[precio_venta_m4;costo_mp_m4;costo_hh_extras_m4;penalizacion_faltante_4_m4]' * [x_m4;w_m4;u_m4;t_m4])

	# A la restricción 1 la puedo escribir mas fácil, ya que el lado izquierdo es la suma de las Xs
	r1_m4 = @constraint(model4, sum(x_m4) == 950)

	# A la restricción 2 le agregamos el faltante permitido
	r2_m4= @constraint(model4, x_m4[4] >= 400 - t_m4)

	# Para las restricciones 3 y 4, en vez de definir a priori la matriz de coeficientes, podemos definir cada sub-matriz y gestionar cada restricción por separado. Observen como no es necesario agrupar todas las variable en el lado izquierdo, JuMP lo hace automáticamente:
	consumo_mp_m4 = [2;3;4;7] 
	r3_m4 = @constraint(model4, consumo_mp_m4' * x_m4 <= 4600 + w_m4) 

	consumo_hs_m4 = [3;4;5;6]
	r4_m4 = @constraint(model4, consumo_hs_m4' * x_m4 <= 5000 + sum(u_m4))
	
	Text(model4)

end

# ╔═╡ 5fa02f42-d1c3-4fe3-9766-467f8845915c
begin

	optimize!(model4)
	
	@show solution_summary(model4, verbose=true)
end

# ╔═╡ 27ee67d2-92ea-455c-985a-64ae25ff6996
md"### Resolución modelando con sumatorias"

# ╔═╡ c07e416c-6a2e-4e2f-8a9c-87c9bf59ffcc
md"Hasta ahora, todos los modelos se realizaron mediante productos escalares de vectores. Veamos como modelar este último caso usando sumatorias:"

# ╔═╡ c759fdc8-ccb5-4d11-9774-ccd4c7adc5a0
begin
	model4_v2 = Model(HiGHS.Optimizer)

	# Variables de decisión. Mismo enfoque, pero reformulado un poco. Porque, si tenemos restricciones que acoten a una única variable, podemos escribir esos límites en la declaración de la variables:
	maxima_mp_m4v2 = 100
	maximas_he_m4v2 = [500;200]
	maximo_faltante_producto_4_m4v2 = 20
	x_m4v2 = @variable(model4_v2, x_m4v2[1:4] >= 0)
	w_m4v2 = @variable(model4_v2, 0 <= w_m4v2 <= maxima_mp_m4v2)
	u_m4v2 = @variable(model4_v2, 0 <= u_m4v2[h=1:2] <= maximas_he_m4v2[h])
	t_m4v2 = @variable(model4_v2, 0 <= t_m4v2 <= maximo_faltante_producto_4_m4v2)

	# Coeficientes de la función objetivo
	precio_venta_m4v2 = [4;6;7;8]
	costo_mp_m4v2 = -0.5
	costo_hh_extras_m4v2 = [-0.2;-0.5]
	penalizacion_faltante_4_m4v2 = -0.2

	# Función objetivo
	obj_m4v2 = @objective(model4_v2, Max,
		[precio_venta_m4v2;costo_mp_m4v2;costo_hh_extras_m4v2;penalizacion_faltante_4_m4v2]' * [x_m4v2;w_m4v2;u_m4v2;t_m4v2])

	obj_m4v2 = @objective(model4_v2, Max,
		sum([precio_venta_m4v2[i] * x_m4v2[i] for i in 1:4]) + 
	    costo_mp_m4v2 * w_m4v2 + # hay una única variable, no necesito sumatoria
	    sum([costo_hh_extras_m4v2[h] * u_m4v2[h] for h in 1:2]) + 
	    penalizacion_faltante_4_m4v2 * t_m4v2) # hay una única variable, no necesito sumatoria

	# A la restricción 1 la puedo escribir explicitando la iteración en la suma
	r1_m4v2 = @constraint(model4_v2, sum([x_m4v2[i] for i in 1:4]) == 950)

	# A la restricción 2 le agregamos el faltante permitido
	r2_m4v2= @constraint(model4_v2, x_m4v2[4] >= 400 - t_m4v2)

	# Restriccion 3, con la variable de materia prima en el lado derecho, por claridad.
	consumo_mp_m4v2 = [2;3;4;7] 
	r3_m4v2 = @constraint(model4_v2, sum([consumo_mp_m4v2[i] * x_m4v2[i] for i in 1:4]) <= 4600 + w_m4v2) 

	# Restricción 4
	consumo_hs_m4v2 = [3;4;5;6]
	r4_m4v2 = @constraint(model4_v2, sum([consumo_hs_m4v2[i] * x_m4v2[i] for i in 1:4]) <= 5000 + sum([u_m4v2[h] for h in 1:2]))
	
	Text(model4_v2)

end

# ╔═╡ 654bd4aa-05f1-4db1-a104-beb1142c62ce
begin

	optimize!(model4_v2)
	
	@show solution_summary(model4_v2, verbose=true)
end

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
# ╟─62598918-ca1a-11ec-20be-c97e53b0cbff
# ╠═df1df4dd-01e3-4da7-8e2b-ea6c96220ee5
# ╠═fd28ca11-d824-49c2-9ac8-17d6635308e0
# ╟─a540f085-c5c9-40d8-8f87-f6dad7eaf1b6
# ╟─86b7ee8e-fbbe-4470-bf02-4086a96a1435
# ╟─ac7e19b6-fc1c-4d6b-83d4-70f82b45283a
# ╟─383e95da-9aa6-4fda-bf1e-e1069e0a1ea4
# ╟─d00dbdaf-6034-4770-a423-3f846fd5999c
# ╟─53de617e-643e-4a99-9df8-782548a43360
# ╟─90fd45c8-822f-4757-8c14-0c4b6d7733dc
# ╟─9518e425-e804-4e94-9974-8519f23886f1
# ╟─6016878a-6800-42a3-a96e-ca153e1f5304
# ╟─21d06573-3380-4552-bc3e-eff4b6aead29
# ╠═d99488c7-7003-4bc3-ba9b-87c8b05592cb
# ╠═89088218-0d57-4fa9-804a-4809a6d7fde6
# ╠═c25dbd8e-f24c-4f5c-845d-f4c3187b1059
# ╠═aaec3799-14af-4bcd-a61a-9a8c28bc73c8
# ╠═087af842-ca86-4cd5-87a6-cf40cf0f846c
# ╠═0a18987c-1a11-4074-80c1-d4e3ee2cef85
# ╠═fc29bbff-c8a3-498a-b352-6a055713ddb8
# ╠═39e46ce1-d9cf-4761-98a1-520b0bfd5dc4
# ╠═22e35d51-59e8-4b9c-9a36-3ff12f692922
# ╠═85b3259a-654a-4ee7-bf72-77d4687dbd7c
# ╠═31cf1712-fc8e-463e-b525-809c6a926f55
# ╠═3d796053-7b79-40ab-9641-71fa62a7b1be
# ╠═93af8cae-2ed5-4201-8e7e-acab21ac0e2b
# ╠═77e3981e-c4a3-45fe-b457-cf8bf2353c46
# ╠═7bfd1b68-074e-4446-b6f3-b6ea5dcbc2a6
# ╠═689d73e4-ad42-48cd-8e16-a45d06817a84
# ╠═400ef579-27e6-4912-93ae-8aefe90ed0fa
# ╟─423d3e0d-4937-4276-bf2e-492ba609e38f
# ╟─d8fb5b82-bfa7-4759-9afd-9b31131edac3
# ╟─8dcac0cc-5840-4a29-bbc1-bc15c7c9b384
# ╟─49a04fe7-43cb-432f-a092-34fb778f0e06
# ╟─7d0f0a1a-3b55-413d-97fe-a3c06fe099ec
# ╟─7cdbd21a-22a9-49ec-9bc1-2380eca5c530
# ╟─f79caecb-3592-46d4-9fd8-298f0c47dea1
# ╟─6cbb2669-7dd0-4b76-97c8-af99a186e3cf
# ╟─70c89896-81b5-4850-a1fd-95f142a1fea7
# ╟─02bd199a-6c8d-4696-baf6-b05698d04f38
# ╠═b0acb185-c4f1-40af-9d52-9e60a27e46bd
# ╠═7a968fee-09e8-4df1-b397-b5c7030eacf7
# ╠═2db24516-830c-4f76-871f-e51e87f91638
# ╠═978d146c-6f02-4d39-b8e2-1e15db103b5d
# ╟─79aa5ddd-19a0-412b-b121-85af900ecf87
# ╠═1480da0e-f605-47f1-86b2-ca15d93021f7
# ╠═46b4b097-793b-45fc-b0c5-f06ebf714501
# ╠═c390945b-940f-4f78-9ae7-251b0850c2f0
# ╠═d0458826-ef24-420d-92e5-edd514f5fa68
# ╠═572aeb67-46a6-4656-87b9-56132647f032
# ╠═31850a4a-a5e5-4e4e-9df6-bef03ccec7d1
# ╠═a77dd882-450a-4f4a-ab57-8ebf2358d2c3
# ╠═57002765-f027-490c-81f5-be1d19b5a795
# ╠═cd0d82be-55b6-4c30-8934-12227b3ec4aa
# ╟─dbd13bd3-6967-401c-8b90-128267f097b8
# ╠═e4e86464-547c-4bca-995c-71c231a6f14a
# ╟─2b224a52-307b-4a62-9be6-27fcfa75ee7c
# ╟─de6c89cc-3d96-488e-a4e3-f10b3765ea65
# ╟─43944518-74f7-437f-9f16-1afedddc0034
# ╟─003e6d35-9a7b-46e8-9409-02d99a0eb787
# ╟─f8d917de-fb64-4471-a701-933ea18bea69
# ╟─ade5c017-9780-46a1-9755-262c56e53b68
# ╟─409e831b-032c-4447-9a3c-9afe379ccdba
# ╟─b060bad4-ce64-40df-bf95-4599b51ef9f7
# ╟─dc743fa4-c1d9-47d5-8035-da1b6fd6f6a7
# ╟─8af7c24c-de0c-4985-9028-36f83b7c5414
# ╟─66b15ff3-6fe4-48b5-aeae-b071be3c923c
# ╟─f57792c2-1447-43a8-918a-db28572e1730
# ╠═41f5d2e9-44cd-4f50-8ce1-d512fe7a4a8e
# ╠═6f53f1fb-ea87-4c91-9a4a-0edca3bb658d
# ╟─dd84d139-2b1a-4705-a958-fe3edd4e8544
# ╟─1ad27015-eb95-427f-bd04-5e5549e9a061
# ╟─2af7ab35-51f3-4228-9fbd-8861cb611c68
# ╟─961bbe51-5c0a-493a-b75e-4218c668651a
# ╟─7ae4b30d-d439-4cf4-9f88-7fbcb9b914d9
# ╟─624990c4-763a-497b-8863-9efee8497ca5
# ╟─f380f772-448e-4928-a096-11e813064f2f
# ╟─7b9b70ee-2861-4cff-8527-a46cbad82c69
# ╟─46f5c604-ca82-4bda-9430-73c6a5bb7383
# ╟─fecbba66-d97f-4dc8-9525-f2294833978b
# ╠═77cdab72-5d1d-45ff-95bc-d48632f4ce65
# ╠═5fa02f42-d1c3-4fe3-9766-467f8845915c
# ╟─27ee67d2-92ea-455c-985a-64ae25ff6996
# ╟─c07e416c-6a2e-4e2f-8a9c-87c9bf59ffcc
# ╠═c759fdc8-ccb5-4d11-9774-ccd4c7adc5a0
# ╠═654bd4aa-05f1-4db1-a104-beb1142c62ce
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

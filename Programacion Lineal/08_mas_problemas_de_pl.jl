### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 51c9cf36-a5dd-4759-95d4-a34c60683b9e
# Cargo los paquetes a usar en el notebook y genero la tabla de contenidos
begin
	using Colors, ImageShow, FileIO, ImageIO # Necesario para incrustar gráficos
	using PlutoUI, JuMP, HiGHS, NamedArrays
	TableOfContents(title="Contenido")
end 

# ╔═╡ e4e0c9ba-d92e-11ed-215c-cd0ccb4823ba
md"# Mas problemas de programación lineal"

# ╔═╡ 08e8c20b-bcb1-4db6-aafe-83e66268b469
md"## Problema de mezcla con relación entre cantidades de componentes"

# ╔═╡ 1d81ae8d-2146-49de-9191-4b00484eac4e
md"Recordemos el problema 15 de la cartilla de programación linea:

> Una empresa láctea necesita incrementar la cantidad de hierro en la leche entera, a fin de cumplir con la legislación vigente. Para ello, puede adicionarle dos suplementos diferentes, el componente A y el B. Debido a que los mismos agregan hierro pero diluyen la cantidad de los otros nutrientes, no se puede agregar mas de 0,05 litros de suplemento por cada un litro de leche. El suplemento A agrega 10 mg de hierro por cada litro de suplemento, mientras que el B agrega 30 mg por cada litro de suplemento.  El suplemento B tiene la particularidad de cambiarle el color a la leche, lo cual es un efecto no deseado (la leche de color gris no es muy comercial). Una forma de anular este efecto es combinarlo con el suplemento A, en una proporción 2:1 o mejor (es decir, usar, como mínimo, el doble de suplemento A respecto del suplemento B).
> 
> Se necesitan agregar, como mínimo, 0,65 mg de hierro por litro de producto final (leche mas suplementos).
> 
> ¿Es posible cumplir con el requerimiento legal?
> 
> Si los costos de los suplementos son \$1/litro para el A, y \$2,50/litro para el B, ¿cual es el mix óptimo?, ¿hasta cuanto puede subir el costo de cada suplemento sin afectar la decisión óptima?


"

# ╔═╡ 6f915b9f-50ea-4faf-8958-2e3d20003d81
md"### Resolución"

# ╔═╡ 63f628ef-ca6d-448e-9857-1293bcd64c57
begin
	model_mezcla = Model(HiGHS.Optimizer)

	# Datos
	suplementos_mm = ["A"; "B"]

	cantidad_maxima_suplementos_mm = 0.05
	aporte_hierro_mm = NamedArray([10;30], (suplementos_mm))
	cantidad_minima_hierro_mm = 0.65
	costo_suplementos_mm = NamedArray([1;2.5], (suplementos_mm))
	
	# Declaro las variables de decisión.
	x_mm = @variable(model_mezcla, x_mm[suplementos_mm] >= 0)

	# Creo la función objetivo.
	obj_mm = @objective(model_mezcla, Min,
		sum([costo_suplementos_mm[i] * x_mm[i] for i in suplementos_mm]))

	# Cargo la restricción de cantidad máxima de suplemento
	r1_mm = @constraint(model_mezcla, sum([x_mm[i] for i in suplementos_mm]) <= cantidad_maxima_suplementos_mm)

	# Cargo la restricción de aporte mínimo de hierro
	r2_mm = @constraint(model_mezcla, sum([aporte_hierro_mm[i]*x_mm[i] for i in suplementos_mm]) >= cantidad_minima_hierro_mm)

	# Cargo la restricción que garantiza que la cantidad de A sea el doble o mas que la cantidad de B
	r3_mm = @constraint(model_mezcla, x_mm["A"] >= 2*x_mm["B"])

	Text(model_mezcla)
end

# ╔═╡ d6f49962-0f6a-4f09-aa1c-dbc7a3fe5960
optimize!(model_mezcla)

# ╔═╡ c7242bb5-5632-4bf6-a31b-d115fd764b4c
solution_summary(model_mezcla, verbose=true)

# ╔═╡ cd6c4915-7962-47f0-b671-dc5a3ff42ca2
md"Se pudo encontrar una solución óptima, por lo tanto el problema es factible y se puede cumplir con el requerimiento. La solución óptima consiste en agregar a la leche 0,026 litros de suplemento A y 0,013 litros del B a cada litro de leche, con un costo total por litro de leche de \$0,0585."

# ╔═╡ 750d2cb0-8151-4ac4-a224-3b5cc92e3d24
md"¿Hasta cuanto puede subir el costo de cada suplemento? Pidámosle a JuMP el análisis de sensibilidad:"

# ╔═╡ 48cd5b06-5ce2-4910-9088-f8ce4db5f8d9
analisis_sensibilidad = lp_sensitivity_report(model_mezcla)

# ╔═╡ 0894db6d-60fe-4f88-a06f-b8476ead3537
analisis_sensibilidad[x_mm["A"]]

# ╔═╡ b607128a-a1e6-418f-9f3f-7649d90aa6e8
md"El componente A puede disminuir sus costos en \$0.17 o incrementarlos a cualquier valor sin modificar la solución óptima."

# ╔═╡ 503f7fb6-176e-47e8-abd2-625178dd153e
analisis_sensibilidad[x_mm["B"]]

# ╔═╡ 2bc4d2a4-c3f2-4db5-a00e-c32c858f4bac
md"El componente B puede disminuir sus costos en \$4.5 o incrementarlos en \$0,5 sin modificar la solución óptima."

# ╔═╡ fb0a3881-0cf5-4cb8-97ea-31111bf513a0
md"## Problema de mezcla con restricciones de porcentajes"

# ╔═╡ 2760b117-7a2e-4861-978e-1c8a5c496695
md"Vemos ahora el problema 20 de la cartilla:

> La pyme de Elaborados Cárnicos ChaciVac S.A. requiere de tus habilidades como  Ingeniero Industrial (el único en toda la planta)  para realizar las formulaciones y determinar cantidades óptimas a producir de salchichas de Viena para este período. 
>
>La planta fabrica salchichas en tres calidades, unas Económicas, otras Familiares, y por último la línea Premium, con precios de venta y demandas máximas y mínimas diferentes, detalladas en la siguiente tabla:
>
$\begin{array}{lccc}
	\hline
	\text{Salchichas} & \text{Económicas} & \text{Familiares}& \text{Premiun}\\
	\hline
	\text{Precio Venta (pesos/kg)} & 52.00 & 61.00 & 80.50\\
	\text{Demanda mínima (kg)} & 8500 & 5000 & 2570\\
	\text{Demanda máxima (kg)} & 10000 & 7500 & 3000\\
	\hline
\end{array}$
>
>A su vez, para la fabricación se utilizan 4 materias primas: carne de cerdo, grasa de cerdo, carne vacuna y almidón de papa. Estas materias primas se mezclan en diferentes proporciones por cada uno de los productos, pudiéndose utilizar cualquier combinación, mientras que la especificación lo permita.
>
>Desde el departamento de producción te han proporcionado, de cada uno de estos posibles ingredientes, las cantidades máximas y mínimas a utilizar de acuerdo a las especificaciones tanto legales como propias de calidad para cada una de las salchichas. Estas especificaciones deben respetarse a rajatabla, ya que los dos hermanos dueños de la empresa están tratando de forjar una imagen diferenciada de ChaciVac S.A. con respecto a la competencia. Las especificaciones de contenidos por cada una de las calidades se especifican a continuación:
>
$\begin{array}{lccc}
	\hline
	\text{Salchichas} & \text{Económicas} & \text{Familiares}& \text{Premiun}\\
	\hline
	\text{Contenido de Carne Mínimo} & 64\% & 70\% & 75\%\\
	\text{Contenido de Grasa Máximo} & 32\% & 25\% & 20\%\\
	\text{Almidón Máximo} & 15\% & 13\% & 9\%\\
	\hline
\end{array}$
> (La referencia a Carne o Grasa es independiente de la procedencia de la misma (vacuna o porcina)
>
>De estas materias primas además, se poseen datos de disponibilidad, de costo por kilogramo y de contenido graso y cárnico indicados en la tabla posterior:
>
$\begin{array}{lcccc}
	\hline
	\text{} & \text{Carne porcina} & \text{Grasa porcina} & \text{Carne vacuna}& \text{Almidón de papa}\\
	\hline
	\text{Costo (pesos/kg)} & 34.90 & 11.00 & 54.30 & 21.20\\
	\text{Disponibilidad (kg)} & 8400 & 1200 & 9050 & 1500\\
	\text{Contenido de carne} & 68\% & 5\% & 80\% & 0\%\\
    \text{Contenido de grasa} & 32\% & 95\% & 20\% & 0\%\\
    \text{Contenido de almidón} & 0\% & 0\% & 0\% & 100\%\\
	\hline
\end{array}$
>
>Con esta información deberías ser capaz de determinar:
>    1. Cantidad a producir de cada una de las calidades.
>    2. Proporción de materia prima en cada una de las mismas.
>    3. ¿Debería esforzarme para conseguir mayor cantidad de materia prima? ¿Cuál(es) y por qué?
"

# ╔═╡ 2d8c62ca-ec25-4474-807e-568fa556a5ce
md"### Resolución"

# ╔═╡ c21698c6-a6b8-4ee9-93e6-4e34196f830b
begin
	model_salchichas = Model(HiGHS.Optimizer)

	# Datos
	materias_primas_ms = ["Carne porcina"; "Grasa porcina"; "Carne vacuna"; "Almidón de papa"]
	productos_ms =["Salchica Económica"; "Salchicha Familiar"; "Salchicha Premiun"]
	componentes_ms = ["Carne"; "Grasa"; "Almidón"]
	
	precios_productos_ms = NamedArray([52;61;80.5], (productos_ms))
	demanda_minima_ms = NamedArray([8500;5000;2570], (productos_ms))
	demanda_maxima_ms = NamedArray([10000;7500;3000], (productos_ms))	
	
	costos_materias_primas_ms = NamedArray([34.90;11;54.30;21.20], (materias_primas_ms))
	disponibilidad_materias_primas_ms = NamedArray([8400;1200;9050;1500], (materias_primas_ms))

	contenido_minimo_carne_ms = NamedArray([0.64; 0.70; 0.75], (productos_ms))
	contenido_maximo_grasa_ms = NamedArray([0.32; 0.25; 0.20], (productos_ms))
    contenido_maximo_almidon_ms = NamedArray([0.15; 0.13; 0.09], (productos_ms))

	aporte_componentes_ms = NamedArray([[0.68 0.05 0.80 0.00]
										[0.32 0.95 0.20 0.00]
	                                    [0.00 0.00 0.00 1.00]], (componentes_ms, materias_primas_ms))
	
	# Declaro las variables de decisión.
	x_ms = @variable(model_salchichas, x_ms[materias_primas_ms, productos_ms] >= 0)

	# Creo la función objetivo.
	obj_ms = @objective(model_salchichas, Max,
		sum([(precios_productos_ms[j]-costos_materias_primas_ms[i]) * x_ms[i,j] for i in materias_primas_ms for j in productos_ms]))

	# Cargo las restricciones de demanda mínima
	r1_ms = @constraint(model_salchichas, [j in productos_ms], sum([x_ms[i,j] for i in materias_primas_ms]) >= demanda_minima_ms[j])

	# Cargo las restricciones de demanda máxima
	r2_ms = @constraint(model_salchichas, [j in productos_ms], sum([x_ms[i,j] for i in materias_primas_ms]) <= demanda_maxima_ms[j])

	# Cargo las restricciones de disponibilidad máxima de materi prima
	r3_ms = @constraint(model_salchichas, [i in materias_primas_ms], sum([x_ms[i,j] for j in productos_ms]) <= disponibilidad_materias_primas_ms[i])

	# Cargo las restricciones de aporte mínimo de carne
	r4_ms = @constraint(model_salchichas, [j in productos_ms], sum([aporte_componentes_ms["Carne", i]*x_ms[i,j] for i in materias_primas_ms]) >= contenido_minimo_carne_ms[j] * sum([x_ms[i,j] for i in materias_primas_ms]))

	# Cargo las restricciones de aporte maximo de grasa
	r5_ms = @constraint(model_salchichas, [j in productos_ms], sum([aporte_componentes_ms["Grasa", i]*x_ms[i,j] for i in materias_primas_ms]) <= contenido_maximo_grasa_ms[j] * sum([x_ms[i,j] for i in materias_primas_ms]))

	# Cargo las restricciones de aporte maximo de grasa
	r6_ms = @constraint(model_salchichas, [j in productos_ms], sum([aporte_componentes_ms["Almidón", i]*x_ms[i,j] for i in materias_primas_ms]) <= contenido_maximo_almidon_ms[j] * sum([x_ms[i,j] for i in materias_primas_ms]))
	Text(model_salchichas)
	
end

# ╔═╡ 3de79c8a-58f6-473a-9e9e-2a2a6e3b56cd
optimize!(model_salchichas)

# ╔═╡ 79090133-2a86-4462-b96d-2d8351c9fac1
solution_summary(model_salchichas, verbose=true)

# ╔═╡ 3047c4ef-7cad-4c09-a20e-73857c105311
md"## Problema de trasporte"

# ╔═╡ f2adaa53-febe-47ea-ba67-9579882caa14
md"El problema 12 de la cartilla dice:

>Una compañía considera la apertura de 4 centros de almacenaje para poder abastecer al país en cuatro ciudades: Buenos Aires, Córdoba, Rosario y Rio Negro. Cada centro tiene una capacidad máxima de despachos semanales, definida por el tamaño de sus almacenes (Buenos Aires, 130 unidades semanales, Córdoba y Rosario 90 unidades y Rio Negro 60 unidades, todo expresado en capacidad semanal). 
>
>El país está dividido en 3 regiones, cada una de las cuales tiene una demanda diferencial. La región 1 requiere de 80 unidades semanales, la 2 de 70 unidades semanales y la 3 de 40 unidades semanales. Obviamente, los costos de transporte unitarios a cada región varían de centro a centro:
>
$\begin{array}{lccc}
	\hline
	\text{Desde/Hacia} & \text{Región 1} & \text{Región 2}& \text{Región 2}\\
	\hline
	\text{Buenos Aires} & 0,2 & 0,4 & 0,5\\
	\text{Rosario}      & 0,5 & 0,1 & 0,3\\
	\text{Córdoba}      & 0,3 & 0,3 & 0,2\\
	\text{Rio Negro}    & 0,2 & 0,5 & 0,4\\
	\hline
\end{array}$
>
>Se desea satisfacer la demanda semanal, minimizando el costo total de operación. Defina la planificación óptima de despachos desde cada centro a cada región.

"

# ╔═╡ 2fb9efbc-1c9d-44a4-8f3c-b969e476fd9f
md"### Resolución"

# ╔═╡ 51ff4c28-f878-4cd3-a6fd-9e13d3c2e6f3
begin
	model_transporte = Model(HiGHS.Optimizer)

	# Datos
	origenes_mt = ["Buenos Aires"; "Rosario"; "Córdoba"; "Rio Negro"]
	destinos_mt = ["Región 1"; "Región 2"; "Región 3"]

	oferta_mt = NamedArray([130;90;90;60], (origenes_mt))
	demanda_mt = NamedArray([80;70;40], (destinos_mt))

	costos_de_transporte_mt = NamedArray([[0.2 0.4 0.5]
										  [0.5 0.1 0.3]
										  [0.3 0.3 0.2]
										  [0.2 0.5 0.4]], (origenes_mt, destinos_mt))

	# Declaro las variables de decisión.
	x_mt = @variable(model_transporte, x_mt[origenes_mt, destinos_mt] >= 0)

	# Creo la función objetivo.
	obj_mt = @objective(model_transporte, Min,
		sum([costos_de_transporte_mt[i,j] * x_mt[i,j] for i in origenes_mt for j in destinos_mt]))

	# Cargo las restricciones de oferta
	r1_mt = @constraint(model_transporte, [i in origenes_mt], sum([x_mt[i,j] for j in destinos_mt]) <= oferta_mt[i])

	# Cargo las restricciones de demanda
	r2_mt = @constraint(model_transporte, [j in destinos_mt], sum([x_mt[i,j] for i in origenes_mt]) >= demanda_mt[j])

	Text(model_transporte)
end

# ╔═╡ 44edca61-4ea2-405d-a994-72bedff7750e
optimize!(model_transporte)

# ╔═╡ d2c72134-ba60-4fb9-a8bf-6aa648ad57d2
solution_summary(model_transporte, verbose=true)

# ╔═╡ faa6642c-9477-44e2-b1ca-6d5f78734c2a
md"## Problema de transbordo"

# ╔═╡ 3fce4180-255e-4b67-933c-9030da672d77
md"Dada la siguiente red logística, planificar los transportes óptimos para satisfacer la demanda:"

# ╔═╡ 280022de-ef66-43af-bfd8-a1f7f79340c1
load("grafo_problema_25.png")

# ╔═╡ 628afe93-ad68-4ebd-a6d9-f0f21381e74e
md"### Resolución"

# ╔═╡ 91e8e5e1-e97f-4a82-8c93-7c4609847aa8
md"Para resolverlo, vamos a construir a una matriz auxiliar (la matriz de adyacencias) que indique las conexiones del grafo. Para cada par de nodos, el elemento asociado en la matriz vale $1$ si se puede ir desde ese origen a ese destino, y $0$ en caso contrario. Vamos a utilizar la función _zeros_ y luego editar los valores manualmente. Lo mismo vamos a realizar para la matriz de costos, usando la función _ones_. También, para mantenerlo sencillo, vamos a crear tantas variables como pares de nodos se puedan formar, usando la matriz de adyacencias para armar las ecuaciones de balance de flujo."

# ╔═╡ d82026b3-4ff4-467a-8285-36cf9dfd53fc
begin
	model_transbordo = Model(HiGHS.Optimizer)

	# Datos

	# Defino todos los nodos como orígenes y destinos
	nodos_mt2 = ["A";"B";"C";"D";"E";"F";"G";"H";"I";"J";"K";"L";"M"]
	cant_origenes_mt2 = length(nodos_mt2)
	cant_destinos_mt2 = length(nodos_mt2)

	oferta_mt2 = NamedArray([2000;800;700;0;0;0;0;0;0;0;0;0;0], (nodos_mt2))
	demanda_mt2 = NamedArray([0;0;0;0;0;0;0;600;200;700;800;600;600], (nodos_mt2))

	M_mt2 = 10000000
	
	# Matriz de adyacencias (conexiones en el grafo) rellena de zeros y de costo rellenas con M
	adyacencias_mt2 = NamedArray(
		zeros(cant_origenes_mt2, cant_destinos_mt2), 
		(nodos_mt2, nodos_mt2))
	
	costos_de_transporte_mt2 = NamedArray(
		M_mt2 * ones(cant_origenes_mt2, cant_destinos_mt2), 
		(nodos_mt2, nodos_mt2))

	# Cargo los valores
	adyacencias_mt2["A", "D"] = 1
	adyacencias_mt2["B", "E"] = 1
	adyacencias_mt2["C", "D"] = 1
	adyacencias_mt2["C", "E"] = 1
	adyacencias_mt2["D", "E"] = 1
	adyacencias_mt2["D", "F"] = 1
	adyacencias_mt2["D", "G"] = 1
	adyacencias_mt2["E", "G"] = 1
	adyacencias_mt2["E", "K"] = 1
	adyacencias_mt2["F", "H"] = 1
	adyacencias_mt2["F", "I"] = 1
	adyacencias_mt2["G", "I"] = 1
	adyacencias_mt2["G", "J"] = 1
	adyacencias_mt2["I", "J"] = 1
	adyacencias_mt2["J", "K"] = 1
	adyacencias_mt2["K", "L"] = 1
	adyacencias_mt2["K", "M"] = 1

	costos_de_transporte_mt2["A", "D"] = 1
	costos_de_transporte_mt2["B", "E"] = 3
	costos_de_transporte_mt2["C", "D"] = 3
	costos_de_transporte_mt2["C", "E"] = 5
	costos_de_transporte_mt2["D", "E"] = 6
	costos_de_transporte_mt2["D", "F"] = 5
	costos_de_transporte_mt2["D", "G"] = 11
	costos_de_transporte_mt2["E", "G"] = 7
	costos_de_transporte_mt2["E", "K"] = 25
	costos_de_transporte_mt2["F", "H"] = 5
	costos_de_transporte_mt2["F", "I"] = 5
	costos_de_transporte_mt2["G", "I"] = 7
	costos_de_transporte_mt2["G", "J"] = 9
	costos_de_transporte_mt2["I", "J"] = 1
	costos_de_transporte_mt2["J", "K"] = 8
	costos_de_transporte_mt2["K", "L"] = 9
	costos_de_transporte_mt2["K", "M"] = 8
	
	# Declaro las variables de decisión.
	x_mt2 = @variable(model_transbordo, x_mt2[nodos_mt2, nodos_mt2] >= 0)

	# Creo la función objetivo.
	obj_mt2 = @objective(model_transbordo, Min,
		sum([costos_de_transporte_mt2[i,j] * x_mt2[i,j] for i in nodos_mt2 for j in nodos_mt2]))

	# Vamos a definir las restricciones de balance de flujo en forma genérica, mediante el esquema "entrada - salida = demanda - oferta"
	r1_mt2 = @constraint(model_transbordo, [i in nodos_mt2], sum([adyacencias_mt2[j,i] * x_mt2[j,i] for j in nodos_mt2]) - sum([adyacencias_mt2[i,j] * x_mt2[i,j] for j in nodos_mt2]) == demanda_mt2[i]-oferta_mt2[i])
	

	Text(model_transbordo)
end

# ╔═╡ 0d11fb40-0131-4ab4-8674-4410f31a5e73
optimize!(model_transbordo)

# ╔═╡ 77342dcd-f16a-4a8d-9409-cc18fbcedd9c
solution_summary(model_transbordo, verbose=true)

# ╔═╡ 2fcb650b-1ab8-4bce-9340-0a03a7441e51
# Hay muchas variables con 0, mostremos la solución real.
begin
	for i in nodos_mt2
		for j in nodos_mt2
			if value(x_mt2[i,j])>= 0.00000001
				println("Desde " , i, " hasta ", j, ":", value(x_mt2[i,j]))
			end
		end
	end
end

# ╔═╡ a8639418-a8f1-471f-bbd3-27e4a6c56e44
md"## Problema de mezcla con igualdad de proporciones"

# ╔═╡ 388e818a-82ae-4a57-9387-5cbc339454cc
md"Este problema está extraido del Hillier-Lierberman 9na Edición, pag 41."

# ╔═╡ 889defb7-4f0f-4e94-9426-8a094e089e3e
begin
	modelo_cultivos = Model(HiGHS.Optimizer)
	
	cultivos_mc= ["Remolacha"; "Algodon"; "Sorgo"]
	centros_mc= ["Centro 1";"Centro 2";"Centro 3"]

	rentabilidad_mc=NamedArray([1000;750;250], (cultivos_mc))
	acres_maximos_mc=NamedArray([400;600;300],(centros_mc))
	irrigacion_maxima_mc=NamedArray([600;800;375],(centros_mc))
	irrigacion_necesaria_mc=NamedArray([3;2;1], (cultivos_mc))

	maximo_total_cultivo_mc=NamedArray([600;500;325], (cultivos_mc))

	x_mc = @variable(modelo_cultivos, x_mc[cultivos_mc,centros_mc] >= 0)

	obj_mc = @objective(modelo_cultivos, Max,sum([x_mc[i,j]*rentabilidad_mc[i] for i in cultivos_mc for j in centros_mc]))

	rest_acre_max_mc=@constraint(modelo_cultivos,[j in centros_mc],sum([x_mc[i,j] for i in cultivos_mc]) <= acres_maximos_mc[j])

	rest_irri_max_mc=@constraint(modelo_cultivos,[j in centros_mc],sum([x_mc[i,j]*irrigacion_necesaria_mc[i] for i in cultivos_mc]) <= irrigacion_maxima_mc[j])	

	rest_prod_max_mc=@constraint(modelo_cultivos,[i in cultivos_mc],sum([x_mc[i,j] for j in centros_mc]) <= maximo_total_cultivo_mc[i])	

	# Con esta restriccion, me aseguro que el porcentaje de área sembrada en el centro 1 sea igual a la del centro 2.
	rest_frac_centro_1_centro_2_mc = @constraint(modelo_cultivos, sum([x_mc[i,"Centro 1"] for i in cultivos_mc])/acres_maximos_mc["Centro 1"] == sum([x_mc[i,"Centro 2"] for i in cultivos_mc])/acres_maximos_mc["Centro 2"])

	# Con esta restriccion, me aseguro que el porcentaje de área sembrada en el centro 1 sea igual a la del centro 3.
	rest_frac_centro_1_centro_3_mc = @constraint(modelo_cultivos, sum([x_mc[i,"Centro 1"] for i in cultivos_mc])/acres_maximos_mc["Centro 1"] == sum([x_mc[i,"Centro 3"] for i in cultivos_mc])/acres_maximos_mc["Centro 3"])	

	
	latex_formulation(modelo_cultivos)
end

# ╔═╡ cfda8a97-e7ea-44b1-ba4f-20833de5525a
optimize!(modelo_cultivos)

# ╔═╡ bf4ad643-1e48-4a7b-ab47-f7231f508e49
solution_summary(modelo_cultivos, verbose=true)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
ImageIO = "82e4d734-157c-48bb-816b-45c225c6df19"
ImageShow = "4e3cecfd-b093-5904-9786-8bbb286a6a31"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Colors = "~0.12.10"
FileIO = "~1.16.0"
HiGHS = "~1.5.0"
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
project_hash = "c2f728eac7ff466d0f87d311d4837c541615a9fb"

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

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "d61890399bc535850c4bf08e4e0d3a7ad0f21cbd"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.2"

[[deps.HiGHS]]
deps = ["HiGHS_jll", "MathOptInterface", "SnoopPrecompile", "SparseArrays"]
git-tree-sha1 = "c4e72223d3c5401cc3a7059e23c6717ba5a08482"
uuid = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
version = "1.5.0"

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
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

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
git-tree-sha1 = "b8d897fe7fa688e93aef573711cb207c08c9e11e"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.19"

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
# ╟─e4e0c9ba-d92e-11ed-215c-cd0ccb4823ba
# ╠═51c9cf36-a5dd-4759-95d4-a34c60683b9e
# ╠═08e8c20b-bcb1-4db6-aafe-83e66268b469
# ╟─1d81ae8d-2146-49de-9191-4b00484eac4e
# ╟─6f915b9f-50ea-4faf-8958-2e3d20003d81
# ╠═63f628ef-ca6d-448e-9857-1293bcd64c57
# ╠═d6f49962-0f6a-4f09-aa1c-dbc7a3fe5960
# ╠═c7242bb5-5632-4bf6-a31b-d115fd764b4c
# ╟─cd6c4915-7962-47f0-b671-dc5a3ff42ca2
# ╟─750d2cb0-8151-4ac4-a224-3b5cc92e3d24
# ╠═48cd5b06-5ce2-4910-9088-f8ce4db5f8d9
# ╠═0894db6d-60fe-4f88-a06f-b8476ead3537
# ╟─b607128a-a1e6-418f-9f3f-7649d90aa6e8
# ╠═503f7fb6-176e-47e8-abd2-625178dd153e
# ╟─2bc4d2a4-c3f2-4db5-a00e-c32c858f4bac
# ╟─fb0a3881-0cf5-4cb8-97ea-31111bf513a0
# ╟─2760b117-7a2e-4861-978e-1c8a5c496695
# ╟─2d8c62ca-ec25-4474-807e-568fa556a5ce
# ╠═c21698c6-a6b8-4ee9-93e6-4e34196f830b
# ╠═3de79c8a-58f6-473a-9e9e-2a2a6e3b56cd
# ╠═79090133-2a86-4462-b96d-2d8351c9fac1
# ╟─3047c4ef-7cad-4c09-a20e-73857c105311
# ╟─f2adaa53-febe-47ea-ba67-9579882caa14
# ╟─2fb9efbc-1c9d-44a4-8f3c-b969e476fd9f
# ╠═51ff4c28-f878-4cd3-a6fd-9e13d3c2e6f3
# ╠═44edca61-4ea2-405d-a994-72bedff7750e
# ╠═d2c72134-ba60-4fb9-a8bf-6aa648ad57d2
# ╟─faa6642c-9477-44e2-b1ca-6d5f78734c2a
# ╟─3fce4180-255e-4b67-933c-9030da672d77
# ╟─280022de-ef66-43af-bfd8-a1f7f79340c1
# ╟─628afe93-ad68-4ebd-a6d9-f0f21381e74e
# ╟─91e8e5e1-e97f-4a82-8c93-7c4609847aa8
# ╠═d82026b3-4ff4-467a-8285-36cf9dfd53fc
# ╠═0d11fb40-0131-4ab4-8674-4410f31a5e73
# ╠═77342dcd-f16a-4a8d-9409-cc18fbcedd9c
# ╠═2fcb650b-1ab8-4bce-9340-0a03a7441e51
# ╟─a8639418-a8f1-471f-bbd3-27e4a6c56e44
# ╟─388e818a-82ae-4a57-9387-5cbc339454cc
# ╠═889defb7-4f0f-4e94-9426-8a094e089e3e
# ╠═cfda8a97-e7ea-44b1-ba4f-20833de5525a
# ╠═bf4ad643-1e48-4a7b-ab47-f7231f508e49
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 77a95eed-7715-4c08-a5b4-d8001751f400
using PlutoUI, JuMP, HiGHS, NamedArrays,CDDLib,Polyhedra,Plots,NamedArrays,LaTeXStrings

# ╔═╡ 2f172bf7-51ac-442b-b3a7-fc569c81fa37
md"# Resolviendo el problema de los Rasti en Julia"

# ╔═╡ d71b9eeb-0195-443f-bb4f-096235241df2
md"Primero llamamos a los paquetes que vamos a usar, algunos son para modelar el problema, otros, para resolverlo y algunos son para hacer gráficos"

# ╔═╡ bfca7eec-382c-404b-aa35-15709490b95d
TableOfContents(title="Contenido") #

# ╔═╡ d8b88ea7-b196-44d8-918c-adff1e757663
md"Modelamos ahora el problema:"

# ╔═╡ cfe7e480-d249-11ed-2e84-e5c9576a1ad1
begin
	#=Empieza Modelado=#
	m = Model(HiGHS.Optimizer)
	piezas = ["Chicas", "Largas"]
	productos = ["Mesas","Sillas"]
	consumo = NamedArray([[2 2]
					      [2 1]], (productos,piezas))
	disp =NamedArray([8;6], piezas)
	ben = NamedArray([16;10], productos)
	
	_X = @variable(m, x[productos] >= 0)
	
	obj = @objective(m, Max, sum([ben[i]*_X[i] for i in productos]))
	
	r = @constraint(m, [j in piezas],sum([consumo[i,j]*_X[i] for i in productos]) <= disp[j])
	
	#Termina Modelado	
	#Me guardo la region factible
	poly = polyhedron(m, CDDLib.Library(:exact))

	#Escribo el modelo arriba de la celda de Pluto
	latex_formulation(m)
end

# ╔═╡ 48b804a1-b579-448e-ba7e-b9859ce7b493
	#Resuelvo el problema
	optimize!(m)

# ╔═╡ 89d983c4-8675-438d-be75-bee63ab1711c
begin
		#Las restricciones en forma de función para ayudarme a graficar luego.
		f(X)=6-2X
		g(X)=4-X
		md""
end

# ╔═╡ c5e325ee-6ad4-4f20-81fb-944824f19a8e
md"Obtenemos la región factible como la intersección de todas las restricciones a las que está sujeto el problema. Recordemos que las variables son no negativas, por lo que la región factible es mayor o igual a cero en todas sus dimensiones."

# ╔═╡ a8f34fd5-2ad8-40e8-8590-9c4417e9e955
begin
	anima = @animate for i ∈ 1:40
		plot(f, fillrange = -8, fillalpha = 0.35, label = L"$r_{1}$: Disponibilidad de piezas chicas",color= "red")
		if(i>12)
			plot!(g, fillrange = -8, fillalpha = 0.35, label=L"$r_{2}$: Disponibilidad de piezas grandes", color= "green")
		end
		if(i>24)
			plot!(poly,label="Region factible",color="yellow",linecolor="yellow")
		end
		plot!(xlab=L"$x_{Mesas}$")
		plot!(ylab=L"$x_{Sillas}$")
		plot!(legend=true)
		plot!(ylim=[-1.5,8])
		plot!(xlim=[-1.5,6])
		plot!(framestyle=:origin)
	end
	gif(anima, fps=5)
end

# ╔═╡ cc978854-061f-406d-8901-e4c1665d9bb1
md"## Curvas isobeneficio"

# ╔═╡ 3ec2098b-641e-4af2-bdda-1b8e8d2e882c
md"Una vez resuelto el problema se puede devolver el óptimo de las variables con la función value:"

# ╔═╡ f0e96327-128f-4380-b2ba-660bab7b665b
value(_X["Mesas"])

# ╔═╡ da38cb3e-57d8-49ee-9206-a75dd825cd07
value(_X["Sillas"])

# ╔═╡ 2028259a-c945-40b4-882d-77a6fddec777
md"Pero... un método gráfico sería tomar la función objetivo y darle valores a $Z$ y graficarlos. Cada una de las rectas para un valor de $Z$ dado se llama recta isobeneficio (porque se tiene el mismo beneficio en cada uno de los puntos en una misma recta). Al ser funciones lineales, todas las rectas isobeneficio son paralelas (misma pendiente y distinto término independiente)."

# ╔═╡ 62171755-06ca-44e4-9e37-e3174cde8cca
md"En consecuencia, podemos calcular una recta isobeneficio y 'arrastrarla' por la región factible. El último punto que toque en la región factible, será el óptimo (o los óptimos)."

# ╔═╡ 43cdd928-27f0-4645-8b42-43fbc989885a
begin
	isoBen=10
	hm=[]
	anim = @animate for i ∈ 1:80
		isoBen=i
		plot(poly,label="Region factible",color="yellow",linecolor="yellow")
		isoBenY(X)=isoBen/10-X*16/10
		plot!(f,label=L"$r_{1}$: Disponibilidad de piezas chicas", color= "red")
		plot!(g,label=L"$r_{2}$: Disponibilidad de piezas grandes", color= "green")
		scatter!((value(_X["Mesas"]),value(_X["Sillas"])),color="red",label="Óptimo")
		plot!(xlab=L"$x_{Mesas}$")
		plot!(ylab=L"$x_{Sillas}$")
		plot!(ylim=[-1.5,8])
		plot!(xlim=[-1.5,6])
		plot!(framestyle=:origin)
		plot!(isoBenY,label=L"Recta \ Isobeneficio \ = %$isoBen", color= "violet")
		for j in 1:length(hm)
			auxi=intersect(HyperPlane([1.,10/16.],j/16),poly)
			plot!(auxi, label="",linecolor=RGB((150+10*j)/800.,0,0))
		end
		plot!(legend=true)
		if(i>=value(obj))
			annotate!(2.7,2.4,text("Z(2,2) = 52"))
			aux(X)=value(obj)/10-X*16/10
			auxVal=value(obj)
			plot!(aux,label=L"Max \ isobeneficio \ en \ región \ factible \ = %$auxVal", color= "blue")	
		else
			push!(hm,isoBenY)
		end
	end
	gif(anim, fps=5)
end

# ╔═╡ 859698ef-5517-485a-b11f-67c544feda9e
md"## Análisis de sensibilidad"

# ╔═╡ 966519a0-933d-46e2-97cc-112ced0522ed
md"Una vez resuelto el problema se puede devolver un reporte de la solución con la función $lp\_sensitivity\_report$:"

# ╔═╡ 5489d50d-94c8-4381-881e-5f2fe3ad740b
report=lp_sensitivity_report(m)

# ╔═╡ 0cdd2169-8a07-45ec-b933-0767ff182a1f
md"Podemos ver que el reporte nos brinda información sobre las variables, a las que podemos acceder con sus nombres. Esta información es cuánto puede variar el coeficiente de la función objetivo sin que cambie el óptimo:"

# ╔═╡ 0c94bae9-dc78-42b0-8865-c063c0049a2a
report[_X["Mesas"]][1]

# ╔═╡ 341e07a4-1643-404d-ab18-7e6607e5708a
report[_X["Mesas"]][2]

# ╔═╡ 9bedeaa9-7080-4fbd-8a83-e4d303201356
report[_X["Sillas"]][1]

# ╔═╡ 17afc935-a4fa-4863-9c4c-f9f704dc2c72
report[_X["Sillas"]][2]

# ╔═╡ ddb7e3f0-97a8-418c-94ca-9ae59a596188
md"Es decir, el beneficio de las sillas puede caer 2 y el óptimo no cambiaría. Por otro lado, el beneficio de las sillas podría subir 6 y el óptimo no cambiaría. Lo mismo para las mesas, cuyo beneficio puede caer hasta 6 o aumentar hasta 4 y el óptimo no cambia.
Recordemos que estos valores son en función del beneficio original, es decir, para sillas los valores críticos serían 8 y 16 (10-2 y 10+6); mientras que para las mesas serían 10 y 20 (16-6 y 16+4)."

# ╔═╡ a9e0d60a-fec6-42c8-b4a6-3beebf2aece1
md"Además podemos obtener los precios sombra de cada restricción con la función $shadow\_price$. Recordemos que el precio sombra es el valor máximo que estaría dispuesto a pagar por aumentar en uno el lado derecho de la restricción."

# ╔═╡ 5c1e1193-fdb0-4cd5-b06c-3213ef56a9c5
[shadow_price(r[i]) for i in eachindex(r)]

# ╔═╡ ed416e04-fa97-4d9f-892d-12ab2b103905
md"### Varación en el beneficio"

# ╔═╡ eb201cdf-14cb-4284-be6e-be194f49f44e
md"#### Varía beneficio de sillas"

# ╔═╡ 36c03510-91b1-4e73-8745-ee2f0b9d5986
md"Podemos graficar cómo se verían diferentes beneficios de las sillas y ver cuándo cambiaría el óptimo. Si la recta choca en otros puntos, es porque la solución óptima habrá cambiado. Sabiendo que el sistema nos provee de lo máximo que puede caer o subir el precio de las sillas, podemos ver que gráficamente coinciden los valores con lo que habíamos obtenido."

# ╔═╡ 0193b204-8ae7-4e28-8e12-4a25c8daba59
begin
	benSillas=10
	minSillas=ben["Sillas"]+report[_X["Sillas"]][1]
	maxSillas=ben["Sillas"]+report[_X["Sillas"]][2]
	benMinSillas(X) = (value(_X["Mesas"])*16+value(_X["Sillas"])*minSillas)/minSillas-X*16/minSillas
	benMaxSillas(X) = (value(_X["Mesas"])*16+value(_X["Sillas"])*maxSillas)/maxSillas-X*16/maxSillas
	anim2 = @animate for i ∈ 1:30
		benSillas=i
		benOpt=value(_X["Mesas"])*16+value(_X["Sillas"])*benSillas
		plot(poly,label="Region factible",color="yellow",linecolor="yellow")
		benOrig(X)=52/10-X*16/10
		benY(X)=benOpt/benSillas-X*16/benSillas
		plot!(f,label=L"$r_{1}$: Disponibilidad de piezas chicas", color= "red")
		plot!(g,label=L"$r_{2}$: Disponibilidad de piezas grandes", color= "green")
		plot!(benOrig,label=L"Recta beneficio a beneficio original", color= "blue",ls=:dash)
		scatter!((value(_X["Mesas"]),value(_X["Sillas"])),color="red",label="Óptimo")
		annotate!(2.7,2.4,text(L"Z(2,2) = %$benOpt"))
		plot!(xlab=L"$x_{Mesas}$")
		plot!(ylab=L"$x_{Sillas}$")
		plot!(legend=true)
		plot!(ylim=[-1.5,8])
		plot!(xlim=[-1.5,6])
		plot!(framestyle=:origin)
		plot!(benY,label=L"Recta \ sensibilidad \ ben \ silla \ %$benSillas", color= "violet")
		if(i>=minSillas)
			plot!(benMinSillas,label="Min de sillas para mantener óptimo = $minSillas", color= "blue")		
		end
		if(i>=maxSillas)
			plot!(benMaxSillas,label="Max de sillas para mantener óptimo = $maxSillas", color= "blue")	
		end
	end
	gif(anim2, fps=5)
end

# ╔═╡ 964512b5-799a-4089-850d-8b2b02bd3a22
md"Se puede apreciar fácilmente que los beneficios límite se dan cuando las rectas isobeneficio son paralelas a una restricción."

# ╔═╡ a4a00d5a-e8c0-4fad-846a-97352e7e98cb
md"#### Varía beneficio de mesas"

# ╔═╡ 9a51feb6-ccf0-4426-9b9c-2c1b7f120e6c
md"Podemos hacer lo mismo con el beneficio de las mesas"

# ╔═╡ 1db35ba4-bfde-4832-ad36-921fa3df01c1
begin
	benMesas=16
	minMesas=ben["Mesas"]+report[_X["Mesas"]][1]
	maxMesas=ben["Mesas"]+report[_X["Mesas"]][2]
	benMinMesas(X) = (value(_X["Mesas"])*minMesas+value(_X["Sillas"])*10)/10-X*minMesas/10
	benMaxMesas(X) = (value(_X["Mesas"])*maxMesas+value(_X["Sillas"])*10)/10-X*maxMesas/10
	anim3 = @animate for i ∈ 1:30
		benMesas=i
		benOpt=value(_X["Mesas"])*benMesas+value(_X["Sillas"])*10
		plot(poly,label="Region factible",color="yellow",linecolor="yellow")
		benOrig(X)=52/10-X*16/10
		benY(X)=benOpt/10-X*benMesas/10
		plot!(f,label=L"$r_{1}$: Disponibilidad de piezas chicas", color= "red")
		plot!(g,label=L"$r_{2}$: Disponibilidad de piezas grandes", color= "green")
		plot!(benOrig,label=L"Recta beneficio a beneficio original", color= "blue",ls=:dash)
		scatter!((value(_X["Mesas"]),value(_X["Sillas"])),color="red",label="Óptimo")
		plot!(xlab=L"$x_{Mesas}$")
		plot!(ylab=L"$x_{Sillas}$")
		plot!(legend=true)
		plot!(ylim=[-1.5,8])
		plot!(xlim=[-1.5,6])
		plot!(framestyle=:origin)
		plot!(benY,label=L"Recta \ sensibilidad \ ben \ silla \ = %$benMesas", color= "violet")
		if(i>=minMesas)
			plot!(benMinMesas,label="Min de mesas para mantener óptimo = $minMesas", color= "blue")		
		end
		if(i>=maxMesas)
			plot!(benMaxMesas,label="Max de mesas para mantener óptimo = $maxMesas", color= "blue")		
		end
	end
	gif(anim3, fps=5)
end

# ╔═╡ 7148e063-484c-4ca6-8140-2e0d6a4f7de3
md"### Compra de una unidad del lado derecho de una restricción"

# ╔═╡ dc0b11c0-f88a-4e7a-9532-130726653a07
md"Como ya mencionamos, si pudiera comprar una unidad del lado derecho de una restricción, lo haría como mucho al precio sombra. Es porque el precio sombra es la mejora que tendría en mi $Z$ si aumentara en uno esa restricción. Hagamos dos modelos iguales al anterior con una unidad más en las restricciones solo a modo ilustrativo."

# ╔═╡ e089dcef-f97e-4ebe-aef9-740410b23b7a
md"#### Pieza chica"

# ╔═╡ faad2dc4-cd41-4683-b94c-43794e65eb55
begin
	#=Empieza Modelado=#
	m2 = Model(HiGHS.Optimizer)
	piezas2 = ["Chicas", "Largas"]
	productos2 = ["Mesas","Sillas"]
	consumo2 = NamedArray([[2 2]
					      [2 1]], (productos2,piezas2))
	disp2 =NamedArray([9;6], piezas2)
	ben2 = NamedArray([16;10], productos2)
	
	_X2 = @variable(m2, _x[productos2] >= 0)
	
	obj2 = @objective(m2, Max, sum([ben2[i]*_X2[i] for i in productos2]))
	
	r2 = @constraint(m2, [j in piezas2],sum([consumo2[i,j]*_X2[i] for i in productos2]) <= disp2[j])
	
	#Termina Modelado	
	#Me guardo la region factible
	poly2 = polyhedron(m2, CDDLib.Library(:exact))
	#Resuelvo el problema
	optimize!(m2)
	#Escribo el modelo arriba de la celda de Pluto
	latex_formulation(m2)
end

# ╔═╡ 287eb310-9f05-4a0e-a3a2-9a76c426ff0d
begin
	plot(poly2,label="Region factible",color="yellow",linecolor="yellow")
	plot!(xlab=L"$x_{Mesas}$")
	plot!(ylab=L"$x_{Sillas}$")
	plot!(legend=true)
	plot!(ylim=[-1.5,8])
	plot!(xlim=[-1.5,6])
	plot!(framestyle=:origin)
end

# ╔═╡ 902fdc09-389e-4dbf-82f0-2dc0cb359532
value(_X2["Mesas"])

# ╔═╡ ef443fa7-9abd-4682-8feb-3616360a3106
value(_X2["Sillas"])

# ╔═╡ c7737ed0-e6b9-4832-b944-01f3cfe69214
md"El valor óptimo de la función objetivo antes era:"

# ╔═╡ 553ca677-0fb2-438b-bc27-c33151a6d78d
objective_value(m)

# ╔═╡ 9fee820b-7b77-4a4e-bc95-c03e870f134e
md"Y recordemos el precio sombra de la restricción que aumentamos una unidad era:"

# ╔═╡ 06e5da4c-044c-4784-85bb-c17129e317a1
[shadow_price(r[i]) for i in eachindex(r)][1]

# ╔═╡ c5ff2712-55c2-4050-b11c-012c57aeda03
md"Y con el aumento de uno en la restricción el valor óptimo de la función objetivo aumentó a..."

# ╔═╡ f27b738f-e766-4221-9501-337a37693906
objective_value(m2)

# ╔═╡ 3847c6cb-2445-47ff-af3d-6a7de175c417
md"¡Aumentó en dos! Exactamente lo que habíamos dicho... si pudieramos comprar una pieza chica más la compraríamos a 2 o menos."

# ╔═╡ 44bea03b-5e31-4283-89d3-91fbbc422d0d
md"#### Pieza grande"

# ╔═╡ ae891e73-40bc-4b12-87dc-3b1cf26bb15a
begin
	#=Empieza Modelado=#
	m3 = Model(HiGHS.Optimizer)
	piezas3 = ["Chicas", "Largas"]
	productos3 = ["Mesas","Sillas"]
	consumo3 = NamedArray([[2 2]
					      [2 1]], (productos3,piezas3))
	disp3 =NamedArray([8;7], piezas3)
	ben3 = NamedArray([16;10], productos3)
	
	_X3 = @variable(m3, __x[productos3] >= 0)
	
	obj3 = @objective(m3, Max, sum([ben3[i]*_X3[i] for i in productos3]))
	
	r3 = @constraint(m3, [j in piezas3],sum([consumo3[i,j]*_X3[i] for i in productos3]) <= disp3[j])
	
	#Termina Modelado	
	#Me guardo la region factible
	poly3 = polyhedron(m3, CDDLib.Library(:exact))
	#Resuelvo el problema
	optimize!(m3)
	#Escribo el modelo arriba de la celda de Pluto
	latex_formulation(m3)
end

# ╔═╡ 5a4f54f8-932b-42b5-987d-faab35b451bd
begin
	plot(poly3,label="Region factible",color="yellow",linecolor="yellow")
	plot!(xlab=L"$x_{Mesas}$")
	plot!(ylab=L"$x_{Sillas}$")
	plot!(legend=true)
	plot!(ylim=[-1.5,8])
	plot!(xlim=[-1.5,6])
	plot!(framestyle=:origin)
end

# ╔═╡ 9f1a560f-890c-471e-8989-1c7f4f486591
value(_X3["Mesas"])

# ╔═╡ 0a765442-94b2-4115-b731-d8b075d7f836
value(_X3["Sillas"])

# ╔═╡ a41dee03-6bed-4959-b9dc-9a2cfbad07dc
md"El valor óptimo de la función objetivo antes era:"

# ╔═╡ 84d892dd-22a0-42c2-9f85-be570831d8f0
objective_value(m)

# ╔═╡ b3b260bc-aee4-4010-b454-f3adda172046
md"Y recordemos el precio sombra de la restricción que aumentamos una unidad era:"

# ╔═╡ 19325fcf-78dd-4092-8323-811aeb2b1551
[shadow_price(r[i]) for i in eachindex(r)][2]

# ╔═╡ bf66a94b-a557-4b7c-a31f-7d4b845ec49d
md"Y con el aumento de uno en la restricción el valor óptimo de la función objetivo aumentó a..."

# ╔═╡ 12ba34b7-2dfc-4fb3-8e17-51690db3c9b3
objective_value(m3)

# ╔═╡ 77f107a4-d866-4aa7-a709-a6d40eee5f43
md"¡Aumentó en seis! Exactamente lo que habíamos dicho... si pudieramos comprar una pieza larga más la compraríamos a 6 o menos."

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CDDLib = "3391f64e-dcde-5f30-b752-e11513730f60"
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Polyhedra = "67491407-f73d-577b-9b50-8179a7c68029"

[compat]
CDDLib = "~0.9.1"
HiGHS = "~1.5.0"
JuMP = "~1.10.0"
LaTeXStrings = "~1.3.0"
NamedArrays = "~0.9.7"
Plots = "~1.38.8"
PlutoUI = "~0.7.50"
Polyhedra = "~0.7.6"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "42798fef0e2613080997771768a5898089fd13c1"

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

[[deps.CDDLib]]
deps = ["LinearAlgebra", "MathOptInterface", "Polyhedra", "SparseArrays", "cddlib_jll"]
git-tree-sha1 = "97e38cde2e7392911245480c10d5997db438cd21"
uuid = "3391f64e-dcde-5f30-b752-e11513730f60"
version = "0.9.1"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

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

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

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

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[deps.Extents]]
git-tree-sha1 = "5e1e4c53fa39afe63a7d356e30452249365fba99"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.1"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

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
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "00e252f4d706b3d55a8863432e742bf5717b498d"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.35"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "d972031d28c8c8d9d7b41a536ad7bb0c2579caca"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.8+0"

[[deps.GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"
version = "6.2.1+2"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "1cd7f0af1aa58abc02ea1d872953a97359cb87fa"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.4"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Preferences", "Printf", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "UUIDs", "p7zip_jll"]
git-tree-sha1 = "4423d87dc2d3201f3f1768a29e807ddc8cc867ef"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.71.8"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "3657eb348d44575cc5560c80d7e55b812ff6ffe1"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.71.8+0"

[[deps.GenericLinearAlgebra]]
deps = ["LinearAlgebra", "Printf", "Random", "libblastrampoline_jll"]
git-tree-sha1 = "e8ec3260d28f3493a29cceeea572b629e87c6701"
uuid = "14197337-ba66-59df-a3e3-ca00e7dcff7a"
version = "0.3.9"

[[deps.GeoInterface]]
deps = ["Extents"]
git-tree-sha1 = "0eb6de0b312688f852f347171aba888658e29f20"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.3.0"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "GeoInterface", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "303202358e38d2b01ba46844b92e48a3c238fd9e"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.6"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "d3b3624125c1474292d0d8ed0f65554ac37ddb23"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.74.0+2"

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
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

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

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

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

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "f377670cda23b6b7c1c0b3893e37451c5c1a2185"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.5"

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

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "2422f47b34d4b127720a18f86fa7b1aa2e141f29"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.18"

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
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c7cb1f5d892775ba13767a87c7ada0b980ea0a71"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+2"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

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

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SnoopPrecompile", "SparseArrays", "SpecialFunctions", "Test", "Unicode"]
git-tree-sha1 = "3ba708c18f4a5ee83f3a6fb67a2775147a1f59f5"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.13.2"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "03a9b9718f5682ecb107ac9f7308991db4ce395b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.7"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

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
git-tree-sha1 = "2b3bcadd0fc35debfd67972e1af45a3a761f2d4b"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.7"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9ff31d101d987eb9d66bd8b176ac7c277beccd09"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.20+0"

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
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.40.0+0"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "478ac6c952fddd4399e71d4779797c538d0ff2bf"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.8"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "1f03a2d339f42dca4a4da149c7e15e9b896ad899"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.1.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "SnoopPrecompile", "Statistics"]
git-tree-sha1 = "c95373e73290cf50a8a22c3375e4625ded5c5280"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.4"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "Preferences", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SnoopPrecompile", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "f49a45a239e13333b8b936120fe6d793fe58a972"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.38.8"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "5bb5129fdd62a2bbbe17c2756932259acf467386"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.50"

[[deps.Polyhedra]]
deps = ["GenericLinearAlgebra", "GeometryBasics", "JuMP", "LinearAlgebra", "MutableArithmetics", "RecipesBase", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "e7b1e266cc9f3cb046d6c8d2c3aefc418a53428d"
uuid = "67491407-f73d-577b-9b50-8179a7c68029"
version = "0.7.6"

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

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "0c03844e2231e12fda4d0086fd7cbe4098ee8dc5"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+2"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
deps = ["SnoopPrecompile"]
git-tree-sha1 = "261dddd3b862bd2c940cf6ca4d1c8fe593e457c8"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.3"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase", "SnoopPrecompile"]
git-tree-sha1 = "e974477be88cb5e3040009f3767611bc6357846f"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.11"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "90bc7a7c96410424509e4263e277e43250c05691"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.0"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "30449ee12237627992a99d5e30ae63e4d78cd24a"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "ef28127915f4229c971eb43f3fc075dd3fe91880"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.2.0"

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

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "45a7769a04a3cf80da1c1c7c60caf932e6f4c9f7"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.6.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "GPUArraysCore", "StaticArraysCore", "Tables"]
git-tree-sha1 = "521a0e828e98bb69042fec1809c1b5a680eb7389"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.15"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

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
deps = ["Random", "Test"]
git-tree-sha1 = "94f38103c984f89cf77c402f2a68dbd870f8165f"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.11"

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

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "ed8d92d9774b077c53e1da50fd81a36af3744c1c"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "93c41695bc1c08c46c5899f4fe06d6ead504bb73"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.10.3+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

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
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

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
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c6edfe154ad7b313c01aceca188c05c835c67360"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.4+0"

[[deps.cddlib_jll]]
deps = ["Artifacts", "GMP_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c25e5fe14395ea7b1d702f4eb90c52bdf50e3450"
uuid = "f07e07eb-5685-515a-97c8-3014f6152feb"
version = "0.94.13+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "868e669ccb12ba16eaf50cb2957ee2ff61261c56"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.29.0+0"

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
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

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
git-tree-sha1 = "9ebfc140cc56e8c2156a15ceac2f0302e327ac0a"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+0"
"""

# ╔═╡ Cell order:
# ╟─2f172bf7-51ac-442b-b3a7-fc569c81fa37
# ╟─d71b9eeb-0195-443f-bb4f-096235241df2
# ╠═77a95eed-7715-4c08-a5b4-d8001751f400
# ╠═bfca7eec-382c-404b-aa35-15709490b95d
# ╟─d8b88ea7-b196-44d8-918c-adff1e757663
# ╠═cfe7e480-d249-11ed-2e84-e5c9576a1ad1
# ╠═48b804a1-b579-448e-ba7e-b9859ce7b493
# ╠═89d983c4-8675-438d-be75-bee63ab1711c
# ╟─c5e325ee-6ad4-4f20-81fb-944824f19a8e
# ╟─a8f34fd5-2ad8-40e8-8590-9c4417e9e955
# ╟─cc978854-061f-406d-8901-e4c1665d9bb1
# ╟─3ec2098b-641e-4af2-bdda-1b8e8d2e882c
# ╠═f0e96327-128f-4380-b2ba-660bab7b665b
# ╠═da38cb3e-57d8-49ee-9206-a75dd825cd07
# ╟─2028259a-c945-40b4-882d-77a6fddec777
# ╟─62171755-06ca-44e4-9e37-e3174cde8cca
# ╟─43cdd928-27f0-4645-8b42-43fbc989885a
# ╟─859698ef-5517-485a-b11f-67c544feda9e
# ╟─966519a0-933d-46e2-97cc-112ced0522ed
# ╠═5489d50d-94c8-4381-881e-5f2fe3ad740b
# ╟─0cdd2169-8a07-45ec-b933-0767ff182a1f
# ╠═0c94bae9-dc78-42b0-8865-c063c0049a2a
# ╠═341e07a4-1643-404d-ab18-7e6607e5708a
# ╠═9bedeaa9-7080-4fbd-8a83-e4d303201356
# ╠═17afc935-a4fa-4863-9c4c-f9f704dc2c72
# ╟─ddb7e3f0-97a8-418c-94ca-9ae59a596188
# ╟─a9e0d60a-fec6-42c8-b4a6-3beebf2aece1
# ╠═5c1e1193-fdb0-4cd5-b06c-3213ef56a9c5
# ╟─ed416e04-fa97-4d9f-892d-12ab2b103905
# ╟─eb201cdf-14cb-4284-be6e-be194f49f44e
# ╟─36c03510-91b1-4e73-8745-ee2f0b9d5986
# ╟─0193b204-8ae7-4e28-8e12-4a25c8daba59
# ╟─964512b5-799a-4089-850d-8b2b02bd3a22
# ╟─a4a00d5a-e8c0-4fad-846a-97352e7e98cb
# ╟─9a51feb6-ccf0-4426-9b9c-2c1b7f120e6c
# ╟─1db35ba4-bfde-4832-ad36-921fa3df01c1
# ╟─7148e063-484c-4ca6-8140-2e0d6a4f7de3
# ╟─dc0b11c0-f88a-4e7a-9532-130726653a07
# ╟─e089dcef-f97e-4ebe-aef9-740410b23b7a
# ╠═faad2dc4-cd41-4683-b94c-43794e65eb55
# ╟─287eb310-9f05-4a0e-a3a2-9a76c426ff0d
# ╠═902fdc09-389e-4dbf-82f0-2dc0cb359532
# ╠═ef443fa7-9abd-4682-8feb-3616360a3106
# ╟─c7737ed0-e6b9-4832-b944-01f3cfe69214
# ╠═553ca677-0fb2-438b-bc27-c33151a6d78d
# ╟─9fee820b-7b77-4a4e-bc95-c03e870f134e
# ╠═06e5da4c-044c-4784-85bb-c17129e317a1
# ╟─c5ff2712-55c2-4050-b11c-012c57aeda03
# ╠═f27b738f-e766-4221-9501-337a37693906
# ╟─3847c6cb-2445-47ff-af3d-6a7de175c417
# ╟─44bea03b-5e31-4283-89d3-91fbbc422d0d
# ╠═ae891e73-40bc-4b12-87dc-3b1cf26bb15a
# ╟─5a4f54f8-932b-42b5-987d-faab35b451bd
# ╠═9f1a560f-890c-471e-8989-1c7f4f486591
# ╠═0a765442-94b2-4115-b731-d8b075d7f836
# ╟─a41dee03-6bed-4959-b9dc-9a2cfbad07dc
# ╠═84d892dd-22a0-42c2-9f85-be570831d8f0
# ╟─b3b260bc-aee4-4010-b454-f3adda172046
# ╠═19325fcf-78dd-4092-8323-811aeb2b1551
# ╟─bf66a94b-a557-4b7c-a31f-7d4b845ec49d
# ╠═12ba34b7-2dfc-4fb3-8e17-51690db3c9b3
# ╟─77f107a4-d866-4aa7-a709-a6d40eee5f43
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

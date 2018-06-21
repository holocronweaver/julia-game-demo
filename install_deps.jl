#! /usr/bin/env julia
deps = [
    "DataStructures",
    "GLFW",
    "ModernGL",
    "Quaternions",
]

Pkg.update()
for dep in deps
    Pkg.add(dep)
end

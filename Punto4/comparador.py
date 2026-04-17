import time
import random

from cyk import ejecutar_cyk
from ll1 import ll1_parse
from graficas import *
# Gramática CNF
def cargar_gramatica_cyk(ruta):
    variaciones_terminales = {}
    variaciones_no_terminales = {}
    simbolo_inicial = None

    with open(ruta, 'r') as f:
        lineas = [line.strip() for line in f if line.strip()]

    for i, linea in enumerate(lineas):
        izquierda, derecha = linea.split("->")
        izquierda = izquierda.strip()
        derecha = derecha.strip().split()

        if i == 0:
            simbolo_inicial = izquierda

        # Terminal
        if len(derecha) == 1 and derecha[0].islower():
            terminal = derecha[0]
            if terminal not in variaciones_terminales:
                variaciones_terminales[terminal] = []
            variaciones_terminales[terminal].append(izquierda)

        # No terminal
        elif len(derecha) == 2:
            clave = (derecha[0], derecha[1])
            if clave not in variaciones_no_terminales:
                variaciones_no_terminales[clave] = []
            variaciones_no_terminales[clave].append(izquierda)

    return {
        'variaciones_terminales': variaciones_terminales,
        'variaciones_no_terminales': variaciones_no_terminales,
        'simbolo_inicial': simbolo_inicial
    }

def benchmark(n_max=200, paso=20):
    longitudes = []
    tiempos_cyk = []
    tiempos_ll1 = []

    # Cargar la gramática CNF desde el archivo
    import os
    ruta = os.path.join(os.path.dirname(__file__), "gramatica_cyk.txt")
    gramatica_cnf = cargar_gramatica_cyk(ruta)

    print(" Iniciando comparación CYK vs LL(1)")

    for n in range(10, n_max + 1, paso):
        cadena = [random.choice(['a', 'b']) for _ in range(n)]

        # CYK
        inicio = time.perf_counter()
        ejecutar_cyk(cadena, gramatica_cnf)
        t_cyk = time.perf_counter() - inicio

        # LL1
        inicio = time.perf_counter()
        ll1_parse(cadena.copy())
        t_ll1 = time.perf_counter() - inicio

        longitudes.append(n)
        tiempos_cyk.append(t_cyk)
        tiempos_ll1.append(t_ll1)

        print(f"N={n:03d} | CYK: {t_cyk:.5f}s | LL1: {t_ll1:.5f}s")

    graficar(longitudes, tiempos_cyk, tiempos_ll1)
    graficar_log(longitudes, tiempos_cyk, tiempos_ll1)
    graficar_ratio(longitudes, tiempos_cyk, tiempos_ll1)

if __name__ == "__main__":
    benchmark()
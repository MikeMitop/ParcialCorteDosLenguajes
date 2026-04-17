# GRAMÁTICA
gramatica = {
    "S": [["A", "a", "A", "b"], ["B", "b", "B", "a"]],
    "A": [["ε"]],
    "B": [["ε"]]
}

simbolo_inicial = "S"

# PRIMERO (FIRST)
PRIMERO = {}

def calcular_primero(simbolo):
    if simbolo not in gramatica:
        return {simbolo}

    if simbolo in PRIMERO:
        return PRIMERO[simbolo]

    primero = set()

    for produccion in gramatica[simbolo]:
        if produccion == ["ε"]:
            primero.add("ε")
        else:
            for sym in produccion:
                primero_sym = calcular_primero(sym)
                primero.update(primero_sym - {"ε"})
                if "ε" not in primero_sym:
                    break
            else:
                primero.add("ε")

    PRIMERO[simbolo] = primero
    return primero


# SIGUIENTE (FOLLOW)
SIGUIENTE = {nt: set() for nt in gramatica}
SIGUIENTE[simbolo_inicial].add("$")

def calcular_siguiente():
    cambio = True
    while cambio:
        cambio = False
        for cabeza, producciones in gramatica.items():
            for produccion in producciones:
                for i, simbolo in enumerate(produccion):
                    if simbolo in gramatica:
                        resto = produccion[i+1:]
                        if resto:
                            primero_resto = set()
                            for sym in resto:
                                primero_sym = calcular_primero(sym)
                                primero_resto.update(primero_sym - {"ε"})
                                if "ε" not in primero_sym:
                                    break
                            else:
                                primero_resto.add("ε")

                            antes = len(SIGUIENTE[simbolo])
                            SIGUIENTE[simbolo].update(primero_resto - {"ε"})

                            if "ε" in primero_resto:
                                SIGUIENTE[simbolo].update(SIGUIENTE[cabeza])

                            if len(SIGUIENTE[simbolo]) > antes:
                                cambio = True
                        else:
                            antes = len(SIGUIENTE[simbolo])
                            SIGUIENTE[simbolo].update(SIGUIENTE[cabeza])
                            if len(SIGUIENTE[simbolo]) > antes:
                                cambio = True


# PREDICCIÓN
def calcular_prediccion():
    prediccion = {}

    for cabeza, producciones in gramatica.items():
        prediccion[cabeza] = []

        for produccion in producciones:
            pred = set()

            if produccion == ["ε"]:
                pred.update(SIGUIENTE[cabeza])
            else:
                for sym in produccion:
                    primero_sym = calcular_primero(sym)
                    pred.update(primero_sym - {"ε"})
                    if "ε" not in primero_sym:
                        break
                else:
                    pred.update(SIGUIENTE[cabeza])

            prediccion[cabeza].append((produccion, pred))

    return prediccion


# VERIFICAR LL(1)
def es_LL1(prediccion):
    for cabeza, producciones in prediccion.items():
        conjuntos = [p[1] for p in producciones]
        for i in range(len(conjuntos)):
            for j in range(i + 1, len(conjuntos)):
                if conjuntos[i].intersection(conjuntos[j]):
                    return False
    return True


# MAIN
# Calcular PRIMERO
for nt in gramatica:
    calcular_primero(nt)

# Calcular SIGUIENTE
calcular_siguiente()

# Calcular PREDICCIÓN
prediccion = calcular_prediccion()

# MOSTRAR RESULTADOS
print("PRIMERO:")
for nt in PRIMERO:
    print(f"{nt}: {PRIMERO[nt]}")

print("\nSIGUIENTE:")
for nt in SIGUIENTE:
    print(f"{nt}: {SIGUIENTE[nt]}")

print("\nPREDICCIÓN:")
for cabeza, producciones in prediccion.items():
    for prod, pred in producciones:
        print(f"{cabeza} → {' '.join(prod)} : {pred}")

print("\n¿Es LL(1)?", es_LL1(prediccion))
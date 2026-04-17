def ejecutar_cyk(cadena, gramatica):
    n = len(cadena)
    if n == 0:
        return False

    tabla = [[set() for _ in range(n)] for _ in range(n)]
    term = gramatica['variaciones_terminales']
    non_term = gramatica['variaciones_no_terminales']

    # Inicialización
    for i in range(n):
        if cadena[i] in term:
            for nt in term[cadena[i]]:
                tabla[i][i].add(nt)

    # CYK
    for l in range(2, n + 1):
        for i in range(n - l + 1):
            j = i + l - 1
            for k in range(i, j):
                for b in tabla[i][k]:
                    for c in tabla[k+1][j]:
                        if (b, c) in non_term:
                            for A in non_term[(b, c)]:
                                tabla[i][j].add(A)

    return gramatica['simbolo_inicial'] in tabla[0][n-1]
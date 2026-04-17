import matplotlib.pyplot as plt

def graficar(longitudes, tiempos_cyk, tiempos_ll1):
    plt.figure()

    plt.plot(longitudes, tiempos_cyk, label="CYK (O(n³))")
    plt.plot(longitudes, tiempos_ll1, label="LL(1) (O(n))")

    plt.xlabel("Número de tokens")
    plt.ylabel("Tiempo (s)")
    plt.title("Comparación CYK vs LL(1)")
    plt.legend()
    plt.grid()

    plt.show()


def graficar_log(longitudes, tiempos_cyk, tiempos_ll1):
    plt.figure()

    plt.plot(longitudes, tiempos_cyk, label="CYK (O(n³))")
    plt.plot(longitudes, tiempos_ll1, label="LL(1) (O(n))")

    plt.yscale("log")

    plt.xlabel("Número de tokens")
    plt.ylabel("Tiempo (escala log)")
    plt.title("Comparación CYK vs LL(1) - Escala Logarítmica")
    plt.legend()
    plt.grid()

    plt.show()




def graficar_ratio(longitudes, tiempos_cyk, tiempos_ll1):
    ratio = []

    for cyk, ll1 in zip(tiempos_cyk, tiempos_ll1):
        if ll1 == 0:
            ratio.append(0)
        else:
            ratio.append(cyk / ll1)

    plt.figure()

    plt.plot(longitudes, ratio, marker='o')

    plt.xlabel("Número de tokens")
    plt.ylabel("CYK / LL(1)")
    plt.title("Relación de Rendimiento (CYK vs LL(1))")
    plt.grid()

    plt.show()
def ll1_parse(cadena):
    stack = ["$", "S"]
    i = 0
    cadena.append("$")

    while stack:
        top = stack.pop()

        if top == cadena[i]:
            i += 1

        elif top == "S":
            if cadena[i] == 'a':
                stack.extend(["B", "A"][::-1])
            elif cadena[i] == 'b':
                stack.extend(["A", "B"][::-1])
            else:
                return False

        elif top in ['A', 'B', 'C']:
            continue

        else:
            return False

    return True
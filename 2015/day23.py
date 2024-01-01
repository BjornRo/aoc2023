with open("in/d23.txt") as f:
    instructions = [x.strip().split(maxsplit=1) for x in f]


def assembly(part2=False):
    ins_len, pc, registers = len(instructions), 0, {"a": 1 if part2 else 0, "b": 0}
    while pc < ins_len:
        ins, arg = instructions[pc]
        match ins:
            case "hlf":
                registers[arg] //= 2
            case "tpl":
                registers[arg] *= 3
            case "inc":
                registers[arg] += 1
            case "jmp":
                pc += int(arg) - 1
            case "jie":
                reg, jmp = arg.split(", ")
                if registers[reg] % 2 == 0:
                    pc += int(jmp) - 1
            case "jio":
                reg, jmp = arg.split(", ")
                if registers[reg] == 1:
                    pc += int(jmp) - 1
        pc += 1
    return registers["b"]


print("Part 1:", assembly())
print("Part 2:", assembly(True))

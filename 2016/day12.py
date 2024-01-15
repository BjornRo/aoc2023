def assembly(a: int):
    ins_len, pc, registers = len(instructions), 0, {k: 0 for k in "abcd"}
    registers["c"] = a
    while pc < ins_len:
        match instructions[pc]:
            case "cpy", val, reg:
                registers[reg] = int(val) if val.isdigit() else registers[val]
            case "inc", reg:
                registers[reg] += 1
            case "dec", reg:
                registers[reg] -= 1
            case "jnz", reg, val:
                if (reg.isdigit() and int(reg) != 0) or registers[reg] != 0:
                    pc += int(val) - 1
        pc += 1
    return registers["a"]


with open("in/d12.txt") as f:
    instructions = [x.strip().split() for x in f]
print("Part 1:", assembly(0))
print("Part 2:", assembly(1))

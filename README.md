# MIPS-Multi-Cycle-Processor

A 32-bit multi-cycle MIPS processor implemented using Verilog.

Instructions are read from a file named "memfile.dat". One test file is included.

## Supported Instructions:
`
  add
  sub
  and
  or
  slt
  lw
  sw
  beq
  addi
  j
`

### Sample Test File (memfile.dat) in MIPS Assembly
```
main: 
    addi $2, $0, 5 
    addi $3, $0, 12
    addi $7, $3, −9
    or $4, $7, $2
    and $5, $3, $4
    add $5, $5, $4
    beq $5, $7, end
    slt $4, $3, $4
    beq $4, $0, around
    addi $5, $0, 0
around: 
    slt $4, $7, $2
    add $7, $4, $5
    sub $7, $7, $2
    sw $7, 68($3)
    lw $2, 80($0)
    j end
    addi $2, $0, 1
end: 
    sw $2, 84($0)
```

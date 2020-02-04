#lang pollen

Almost everything you'll need is in the ◊armv8-arm[1 null]{ARMv8 Architecture Reference Manual} and ◊cortex[1 null]{Cortex-72A Processor Technical Reference Manual}. I highly recommend downloading a copy of each PDF. Some of their contents are reproduced below.

◊section[1 null]{Terminology}

These are the search terms you're looking for.

◊table{
	◊tr{
		◊th{Term}
		◊th{Definition}
	}
	◊tr{
		◊td{cortex-72a}
		◊td{the processor used by the Raspberry Pi 4}
	}
	◊tr{
		◊td{broadcom bcm2711}
		◊td{same as above, for our purposes (???)}
	}
	◊tr{
		◊td{instruction encoding}
		◊td{the encoding for translating assembly into machine code}
	}
}

◊section[1 null]{Peripherals}

Many peripherals (external io stuff) are accessible through special memory addresses. The Raspberry Pi 4's peripherals document has not yet been released, so for now we'll use the RPi 3's ◊armv8-arm[1 null]{BCM2835 ARM Peripherals Manual}.

◊section[2 null]{UART}

◊section[3 null]{External Documentation}

◊armv8-arm[175 "110,-110,807"]{BCM2835 ARM Peripherals, Page 175}

◊link["http://infocenter.arm.com/help/topic/com.arm.doc.ddi0183g/DDI0183G_uart_pl011_r1p5_trm.pdf#page=47&zoom=auto,-29,502"]{PrimeCell UART Technical Reference Manual}

◊arm-periph[177 "110,-110,280"]{Register addresses}, with offset ◊mono{0xFE201000} on raspi4

◊section[3 null]{Setup Procedure}

On QEMU, UART data can be sent/received by simply writing ASCII-encoded text to/from ◊mono{0xFE201000}, but on real hardware, you'll need to do some setup first.

For the following setup steps, use the BCM2836 Peripheral Manual's ◊arm-periph[90 "110,-110,652"]{GPIO address section}, replacing ◊mono{0x7E20} with ◊mono{0xFE20} for raspi4.  Also see the manual's ◊arm-periph[177 "110,-110,280"]{UART address section}.

◊ol{
	◊li{
		disable UART using the ◊arm-periph[185 "110,-110,325"]{UART control register}
	}
	◊li{
		disable GPIO pin pull up/down
	}
	◊li{
		delay for 150 cycles (create a loop with a countdown)
	}
	◊li{
		disable GPIO pin pull up/down clock 0
	}
	◊li{
		delay for 150 cycles
	}
	◊li{
		disable GPIO pin pull up/down clock 0 (yeah, again; idk why)
	}
	◊li{
		clear all pending interrupts using the ◊arm-periph[192 "110,-70,735"]{UART interrupt clear register} (write zero to the bits representing each interrupt you want to clear)
	}
	◊li{
		set baud rate to 115200 given a 3 Mhz clock (follow the PrimeCell UART Manual's ◊link["http://infocenter.arm.com/help/topic/com.arm.doc.ddi0183g/DDI0183G_uart_pl011_r1p5_trm.pdf#page=56&zoom=auto,-29,199"]{baud rate calculation example})
		◊ul{
			◊li{
write the baud rate divisor integer (◊mono{BDR_I}) to the ◊arm-periph[183 "110,-70,479"]{UART integer baud rate divisor register}
			}
			◊li{
				write the calculated fractional part (◊mono{m}) to the ◊arm-periph[183 "110,-110,255"]{UART fractional baud rate divisor register}
			}
		}
	}
	◊li{
		enable FIFO and 8-bit data transmission using the ◊arm-periph[184 "110,-70,645"]{UART line control register}
	}
	◊li{
		mask all interrupts using the [TODO...]
	}
}

◊section[3 null]{Writing}

◊section[3 null]{Reading}

◊section[1 null]{Machine Code Overview}

◊section[2 ◊armv8-arm[223 "auto,-4,576"]{pg 223}]{Encoding}

Very few people venture below assembly to machine code, so most machine code is described in terms of the equivalent assembly.

For example, let's say we wanted to execute ◊code{r7 <- r2 + 16}.

Once we find the ◊code{add} instruction in the ARMv8 Manual (◊armv8-arm[531 "auto,-4,730"]{pg 521}) or via the documentation below, we see that the encoding for 64-bit ◊code{add} is as follows: 

◊pre{
sf 0 0 1 0 0 0 1 shift2 imm12 Rn Rd
}

Note the numbers after some variable names; they indicate how many bits wide their encodings are.

In our case, to do ◊code{r7 <- r2 + 16}, we calculate the following:
◊codeblock{
sf = 1
shift = 00
imm = 000000010000
Rn = r2 = 00010
Rd = r7 = 00111
}

Therefore, our fully encoded instruction is: (whitespace added for clarity)
◊codeblock{
1 0 0 1 0 0 0 1 00 000000010000 00010 00111
}

◊section[2 ◊cortex[75 "auto,-12,749"]{pg 75}]{Registers}

These are the fastest place to store data. Most machine code instructions involve registers and moving data to/from/between them.

◊table{
	◊tr{
		◊th{
			Register
		}
		◊th{Description}
	}
	◊tr{
		◊td{
			◊cortex[90 "auto,-12,258"]{◊code{MPIDR_EL1}}
		}
		◊td{
			This read-only identification register, among other things, provides a core identification number (◊armv8-arm[2620 "110,-33,627"]{how to access})
		}
	}
	◊tr{
		◊td{
			◊code{r0} to ◊code{r15}
		}
		◊td{
			General-purpose registers. Because we're writing our own assembly language, feel free to use these however you want
		}
	}
}


◊section[2 "\"immediate\" values"]{Constants}

The aarch64 instruction encoding is 32 bits wide, so we cannot store large constants into registers in a single command. Instead, we use multiple commands to store the constant, such as ◊mono{mov} with a bit shift followed by one or more ◊mono{add} instructions.


◊section[1 null]{Machine Code Operations}

◊section[2 null]{Register Movement}

This instruction family copies into a register either a constant or the value of another register.

◊section[3 null]{From Constant}

◊section[3 null]{From Register}

◊section[3 ◊armv8-arm[802 null]{pg 802}]{From System Register}

See the register summaries above for the parameters needed to access a specific system register.

◊section[2 ◊armv8-arm[226 null]{pg 226}]{Logical Operations}

I won't explain all of these here, but know that ◊mono{xor} is also known as ◊mono{eor}.

◊section[3 null]{And}

◊section[3 null]{Or}

◊section[3 null]{Xor}

◊section[2 null]{Arithmetic Operations}

◊section[3 null]{Add}

◊section[3 null]{Sub}

◊section[2 null]{Memory Operations}

◊link["https://people.cs.clemson.edu/~rlowe/cs2310/notes/ln_arm_load_store.pdf"]{Rose Lowe cs2310 Slideshow}


◊section[3 ◊armv8-arm[901 "auto,-4,387"]{pg 901}]{Store, Pre-Index}

Reads the address `Rn + imm` from memory and stores it into `Rt`.

```
Rt <- *(Rn + imm)
```

◊section[3 ◊armv8-arm[901 "auto,-4,655"]{pg 901}]{Store, Post-Index}



Reads the address `Rn` from memory stores it into `Rt`, then updates `Rn` to `Rn + imm`.

```
Rt <- *Rn
 Rn <- Rn + imm
```
# OV7670-with-FPGA-and-Demosaicing
This project is intended to exercise concepts relating to embedded digital image processing with FPGAs. 
In particular, to become familiar with interfacing with the OV7670 using I2C, demosaicing bayer pattern, and with VGA output.
was also to develop a concrete understanding of pipeling and parallelism. All diagrams are taken from the reading sources.

## Suggested Reading 
The basic areas that need to be covered are
- OV7670 datasheet (https://web.mit.edu/6.111/www/f2016/tools/OV7670_2006.pdf)
- Serial Camera Control Bus (SCCB) (https://people.ece.cornell.edu/land/courses/ece4760/FinalProjects/f2021/jfw225_aei23_dsb298/jfw225_aei23_dsb298/SCCBSpec_AN.pdf)
- I2C protocol
* SCCB is compatible with I2C
- VGA
- DSPs

### from "Design for Embedded Image Processing on FPGAs" by Donald G. Bailey (2nd edition)
chapters:
-  1. Image Processing
-  2. FPGAs (skim)
  > in particular, 2.1.2, DSP blocks
- 3. Design Process
- 4. Design Constraints
- 5. Computational Techniques (skim)
- 9. Local Filters
  > in particular, 9.7.3 Bayer Pattern Demosaicing

## Notes about OV7670
Naming differences, default to OV7670 datasheet naming 
SCL  <-> SIO_C
SDA  <-> SIO_D
HS   <-> HREF
VS   <-> VREF
MCLK <-> XCLK

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/4ac5698e-d715-47d3-96b5-2fc17806dd0b)

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/8b75e934-baf7-4f6b-873a-75348a83a904)

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/167f923c-efac-49e7-bbf0-8b207896f98c)

- Since we are dealing with a two wire setup, we can ignore SCCB_E ("Where SCCB_E is not present on the Camera Chip sensor, this signal is by default enabled and held high")
![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/92f1db44-960b-4891-a891-02fa9ddd623f)

- SIO_D must be held at 1 for a defined period to avoid unknown bus state propagation. Minimum value of t_rpc is 15 ns, t_psc is
  also 15 ns. This happens before transmission, and after transmission.

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/69c84b7d-8a66-4966-9519-9c58f90043e5)

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/bdb92781-57f9-4069-b529-72a159547480)

### Transmission cycles
1. 3-phase write transmission cycle
2. 2-phase write transmission cycle
3. 2-phase read transmission cycle

- the IP-address are bits 7 to 1, bit 0 is R/W'
- Sub-address identifies the register location of the specified child device
- interestingly enough, normally the ninth bit is used to acknowledge a transmission, but in this case it is either a Don't-Care or NA
- also there's an implicit notion of 'asserting' a phase. To be clear, all transmissions are inititated by the parent device however, say
  a 2-phase write cycle specificing a read is done, we know that the child device will inititate a 2-phase read cycle

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/aa4025bb-9d12-4df8-bf60-7b6352f703d2)

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/a3e8dd56-68c8-42aa-8291-25d5cedb57bc)

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/0a97d801-4cb3-4431-8cc6-cbfdb723716a)
- the parent must drive the NA bit at logical 1

- "The parent muskt mask the input of SIO_D during the period of the Don't-Care bit and force the input to 0 to avoid propagating
  and unknown bus state", meaning, we have to disable OE then mask the input
- note that SIO0_OE_M and SIO0_OE_S are active *low*
  ![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/ec0e3ff9-a2a1-42ad-8f53-7e25dedd5b50)

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/67552460-9081-4abf-94fc-7a3cf1059405)

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/98e5c77b-b7a2-4713-b8e1-e834068c9990)

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/d80e8d2d-3bc6-4307-8479-8623e7d33fd5)

### Pmod-Setup
![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/e5c4ec1c-e176-4f77-b860-046d3c57eaa7)

Mappings:  
JB1 - SCL    JB7  - SDA     (** Don't forget SCL and SDA resistors! see short-circuit protections below)  
JB2 - VS     JB8  - HS  
JB3 - PCLK   JB9  - MCLK  
JB4 - D7     JB10 - D6  

JC1 - D5     JC7  - D4  
JC2 - D3     JC8  - D2  
JC3 - D1     JC9  - D0  
JC4 - RST    JC10 - PWDN  


### VGA Setup (with artix-7 fpga on basys 3 board)
![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/8a3e00df-627d-44c2-8323-e18105eac120)

### Understanding VGA Timing (and Output Format)
The timing diagrams are fairly straightforward, refer to the Basys 3 reference documents and the OV7670 datasheets.
What I found confusing is how does the display itself know what resolution to expect?
- If we have a smaller resolution then the display will there be blank lines?
- Without knowledge of resolution, how does the display know to correctly sample data?
- The only constants are horizontal/vertical sync and the refresh rate of the monitor, but the pixel clock is not passed...
The GPIO test code provided by diligent is a good way to understanding how to interact with VGA displays:
https://digilent.com/reference/programmable-logic/basys-3/demos/gpio

After much reading out, two things are understood:
1. The resolution is *inferred* by the monitor depending on how many hsyncs there are between vsyncs (okay, makes sense)
2. The Generalized Timing Formula Standard by VESA, answers all questions about timing (see https://glenwing.github.io/docs/VESA-GTF-1.1.pdf)

VESA controls these standards, in fact, they copy right them and sell them. Don't bother visiting their website, finding information is suprisingly difficult and obscure and will lead to requesting information (which you don't know is what you actually need until they approve, if they do anyway).

The ov7670 signals generated by the Video Timing Generator (should) conforms to these timing standards. Meaning, we just have to pass it along to the VGA pins.
The last issue is output format. Looking at the device control register list, we can learn how to 
enable RGB444. This is the most convenient format, because the VGA port uses 4 bits to control each channel
(see just above VGA setup picture).

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/45965a71-3d24-420f-99d5-b78abeea752c)

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/4c544ea1-ae19-4c15-af63-3e3e1851341f)

By default RGB444 is *disabled* and can only be enabled effectively if COM15[4] is also set to high. Also
note the word format of RGB444. (see https://embeddedprogrammer.blogspot.com/2012/07/hacking-ov7670-camera-module-sccb-cheat.html to understand pixel formats).

To summarize, in order to get the output directly from the camera without any processing we need:
1. Supply XCLK by dividing our main clock (100MHz -> 25MHz, nice number since dividing by 4)
2. Wire up the i2c bus (with resistors too, very important), so that we can set the output format on the
control device registers
3. Have a small module that passes along from every two bytes from the camera, the pixel data to the VGA port (see the RGB444 word format)

Right now we don't have to worry about debayering since the ov7670 has its own DSP which takes care of this kind of stuff. However, there is a way to disable the formats so we get raw data that we then need to process. That will be the next step.

Turns out, the above is wrong. The ov7670 timing generator is not meant to be directly connected to the VGA output. This is
because the frame rate of the camera and the refresh rate of the monitor aren't the same. It might be possible if the frame 
rate and the refresh rate are the same, but I think the timings will still be off.

What is really needed is a buffer in between that can accept a frame of data from the camera and seperate circuitry which
can output the data from the buffer with its own VGA circuitry the produces the vsync and hsync signals properly. A FIFO
buffer would be ideal, since we are crossing clock domains.

1. Set up a DPORT RAM (inferrence should work but its better to use instantiation, see Vivado Design Suite 7 Series FPGA guide, UG953)
2. Use the RGB 444 module to send the data to the buffer at the correct address
3. Continuously read off of the video buffer and send it via a VGA control circuit which generates the appropriate vsync and hsync signals.

Checkout https://www.intel.com/content/www/us/en/docs/programmable/683562/21-3/read-during-write-operation-at-the-same.html,
to see what happens during a simultaneous read/write to the same address in memory.

### 4 7-seg displays
- same as a one 7-seg display, but the cathodes are multiplexed
- ![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/25665acf-fba6-425f-8521-230926c063b3)
- see timing diagram
![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/8a92e2b0-89eb-4043-bf47-5b00ad05ecf3)

### Setup and Short-circuit protections
![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/ecb6e25e-f8c2-4d43-8c2d-a99ed023e0bb)
![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/68b2e85f-1504-4c47-8db6-bf54b2de4afa)








  














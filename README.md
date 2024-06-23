# OV7670-with-FPGA-and-Demosaicing
This project is intended to exercise concepts relating to embedded digital image processing with FPGAs. 
In particular, to become familiar with interfacing with the OV7670 using I2C, demosaicing bayer pattern, and with VGA output.
was also to develop a concrete understanding of pipeling and parallelism.

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

- Since we are dealing with a two wire setup, we can ignore SCCB_E.
![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/92f1db44-960b-4891-a891-02fa9ddd623f)

- SIO_D must be held at 1 for a defined period to avoid unknown bus state propagation. Minimum value of t_rpc is 15 ns, t_psc is
  also 15 ns. This happens before transmission, and after transmission.

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/69c84b7d-8a66-4966-9519-9c58f90043e5)

![image](https://github.com/Marc103/OV7670-with-FPGA-and-Demosaicing/assets/78170299/bdb92781-57f9-4069-b529-72a159547480)











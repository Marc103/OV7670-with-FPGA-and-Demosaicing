/*
 * Small FSM, deserializes (every two bytes) to produce 
 * rgb 565.
 * also produces the appropriate address to write to video memory.
 * RGB 565 expected in format xR GB
 * see Figure 13, RGB 565 Output Timing Diagram, in the ov7670 datasheet
 */
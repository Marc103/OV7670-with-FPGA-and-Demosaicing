/*
Constants to name states
SA - subaddress 
WD - write data
RD - read data
*/

// Refer to figure 3.5 - 3.7 in the read me
typedef enum bit [2:0] {IDLE, PHASE_1, PHASE_2_SA, PHASE_2_RD, PHASE_3_WD} phase_states_t;

typedef enum bit [3:0] {IDLE, START, DATA, RW_, X, STOP} transmission_states_t;

{.$DEFINE SIMULATE_SPI}                 // Skips over hardware loops in the SPI Code

{.$DEFINE DCCTIMER_DISABLE}             // Does not enable the DCC 56us Timer

{.$DEFINE UART_ENABLE}                  // Adds/Removes all UART Code from the build

{.$DEFINE PINCHANGE_INTERRUPT_ENABLE}   // Enables the Pin Change Interrupt

{.$DEFINE SPI_ENABLE}                   // Enables the SPI Module

{$DEFINE XPRESSNET_UART_ENABLE}         // Enables the RS232 Module for the Xpressnet 65kBaud

{$DEFINE ENABLE_TRAPS}                 // Enables the Trap Interrupts on the MCU, uses the dsPICxx_Traps.mpas file
{.$DEFINE ENABLE_TOGGLE_PIN_ON_TRAP}    // Enables the Trap Interrupts on the MCU, uses the dsPICxx_Traps.mpas file
{.$DEFINE ENABLE_LOOP_FOREVER_ON_TRAP}  // Enables the Trap Interrupts on the MCU, uses the dsPICxx_Traps.mpas file

{$FIX_NESTED_INTERRUPT_SILICON_BUG}    // Add code to fix a silicon bug in nested Interrupts

{.$DEFINE SUPPORT_AT_LEAST_ONE_CONSUMED_EVENT}
{$DEFINE SUPPORT_AT_LEAST_ONE_PRODUCED_EVENT}
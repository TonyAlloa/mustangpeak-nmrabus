
{.$DEFINE SIMULATE_SPI}                 // Skips over hardware loops in the SPI Code

{.$DEFINE DCCTIMER_DISABLE}             // Does not enable the DCC 56us Timer

{.$DEFINE UART_ENABLE}                  // Adds/Removes all UART Code from the build

{.$DEFINE PINCHANGE_INTERRUPT_ENABLE}   // Enables the Pin Change Interrupt

{.$DEFINE SPI_ENABLE}                   // Enables the SPI Module

{$DEFINE SUPPORT_AT_LEAST_ONE_CONSUMED_EVENT}
{$DEFINE SUPPORT_AT_LEAST_ONE_PRODUCED_EVENT}

{.$DEFINE SUPPORT_AT_LEAST_ONE_VNODE_CONSUMED_EVENT}
{.$DEFINE SUPPORT_AT_LEAST_ONE_VNODE_PRODUCED_EVENT}

{.$DEFINE SUPPORT_VIRTUAL_NODES}

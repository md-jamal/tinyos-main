

#include <lib6lowpan/ip.h>

module TestNDC {
  uses {
    interface Boot;
    interface SplitControl;
    interface Leds;
    }
} implementation {
  
  event void Boot.booted() {
    call SplitControl.start();

  }

  event void SplitControl.startDone(error_t e) {
    call Leds.led0On();
  }

  event void SplitControl.stopDone(error_t e) {}

  
}

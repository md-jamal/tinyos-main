

/**
 * Copyright (c) 2007 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */


#include "printf.h"
module TestShtC {
  uses {
    interface Boot;
    interface Timer<TMilli> as Timer;
    interface Read<uint16_t> as Temperature;
    interface Read<uint16_t> as Humidity;
  }
}
implementation {
uint16_t temperature;
  event void Boot.booted() {	
	call Timer.startPeriodic(5*1024);

  }
 
  event void Timer.fired(){
		     	call Temperature.read();
  }

  event void Temperature.readDone(error_t err, uint16_t data){

		temperature = -39 + (0.0098)*data;
		printf("Temperature is %d C\n",temperature);
		printfflush();
		call Humidity.read();
	}
event void Humidity.readDone(error_t err, uint16_t data){

    uint16_t temp = (-0.0000028 * data *data) + (0.0405 * data) - 4;
    uint16_t humidity = (temperature  - 25) * (0.01 + 0.00008 * data) +temp;
    printf("Humidity is %d %%\n",humidity);  
    printfflush();

}
}


#define NEW_PRINTF_SEMANTICS
#include "printf.h"
module TestC{
	uses interface Boot;
	uses interface DHT11;
	uses interface Timer<TMilli> as Timer;
	uses interface Leds;
}

implementation{

	event void Boot.booted(){
		
		call Timer.startPeriodic(1024*5);

	}

	event void Timer.fired(){
		call DHT11.read(TRUE,TRUE);
	}

	event void DHT11.readHumidityDone(uint8_t error,uint8_t dec,uint8_t integ){
		if(error==SUCCESS){
			//call Leds.led0Toggle();				
			printf("Humidity:%d.%d %%\n",integ,dec);printfflush();
		}else{
			printf("Error Code:%d\n",error);printfflush();
		}

	}


	event void DHT11.readTempDone(error_t error,uint8_t dec,uint8_t integ){
		if(error==SUCCESS){

			printf("Temp:%d.%d C\n",integ,dec);printfflush();
		}else{
			printf("Error Code:%d\n",error);printfflush();
		}
					
	}



}


/**
	Steps Followed for generating Kpa
	
	Step1: Read the temperature from the DHT11
	Step2: Read the frequency from the Gypsum board and convert into the resistance
	Step3: Convert the temperature from Celsius to Farenheit
	Step4: Apply temperature compensation to the resistance
	Step5: Convert the temperature compensated resistance into kpa  


 
 */

#include "printf.h"
module TestC @safe()
{
  uses interface Boot;
  uses interface StdControl as FreqControl;
  uses interface Timer<TMilli> as Timer;
  uses interface Gypsum;
  uses interface DHT11;
 }
implementation
{

  uint8_t temperature;
  float farenheit;

  float celsius2Farenheit(int celsius){
	return (celsius*9/5)+32;
  }


  uint16_t resistToKpa(uint16_t resistance){
	if(resistance > 550 && resistance <= 1000)
		return (resistance - 550)/550;
	else if(resistance > 1000 && resistance <= 1100)
		return (9 + (resistance - 1000)/100);
	else if(resistance > 1100 && resistance <= 2000)
		return (10 + (resistance - 1100)/180);	
	else if(resistance  > 2000 && resistance <= 6000)
		return ( 10 + (resistance - 2000)/200);
	else if(resistance > 6000 && resistance <= 9200)
		return ( 10 + (resistance - 6000)/160);
	else if(resistance > 9200 && resistance <= 12200)	
		return ( 10 + (resistance - 9200)/150);
	else if(resistance > 12200 && resistance <= 15575)
		return (10 + (resistance - 12200)/135);
	else if(resistance >15575 && resistance <= 28078)
		return (10 + (resistance - 15575)/125);
	else
		return 0;
  }

  event void Boot.booted() {	
	call Timer.startOneShot(5*1024);
  }
 
  event void Timer.fired(){
	call DHT11.read(TRUE,FALSE);
  }



    event void Gypsum.readDone( error_t result, uint16_t freq,uint16_t resist){

		uint16_t temper_compens_res;
		uint16_t kpa;
		printf("Freq:%u Hz\n",freq);
		printf("Resistance:%u Ohms\n",resist);
		
		//convert temperature to farenheit
		farenheit = celsius2Farenheit(temperature);
		printf("Temperature:%dF\n",(int)farenheit);

		//perform temperature compensation on the resistance
		temper_compens_res = resist *(1+0.01*(farenheit - 75));
		//printf("Temperature compensated Resist:%u ohms\n",temper_compens_res);

		//perform resistance to kpa conversion
		kpa = resistToKpa(temper_compens_res);
		printf("soil moisture:%d kpa\n",kpa);

		printfflush();
		call FreqControl.stop();	//disabling the interrupt 
		call Timer.startOneShot(5*1024);//next reading

   }


   event void DHT11.readHumidityDone(uint8_t error,uint8_t dec,uint8_t integ){
	

	}


	event void DHT11.readTempDone(error_t error,uint8_t dec,uint8_t integ){
			if(error==SUCCESS){
				temperature = integ;
				//printf("Temperature is %d.%dC\n",integ,dec);printfflush();
				call FreqControl.start();	//enabling the interrupt
				call Gypsum.setSamples(4);
				call Gypsum.readFreq();
			}else{
				printf("Error is %d\n",error);printfflush();
				call Timer.startOneShot(5*1024);//retry the operation
			}

	}





}


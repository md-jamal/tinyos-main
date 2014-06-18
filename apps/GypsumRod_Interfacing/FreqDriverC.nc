
#include "printf.h"
#define MEASURE_PERIOD 250	//because we can process only upto 4k interrupts per sec and our max freq is 13k
module FreqDriverC{

	provides interface StdControl as FrequencyControl;
	provides interface Gypsum;
	uses interface GpioInterrupt as Interrupt;
	uses interface Timer<TMilli> as MeasureTimer;

}


implementation{


	uint32_t count=0;
	int8_t num_Samples,sample_Count=1;
	uint32_t total=0;
        
	uint32_t ohms_array[28]={ 0,1,24,
				32,48,64,96,128,
				192,256,512,768,
				1024,1536,2048,3072,4096,
				6144,8192,12288,16384,
				32768,49152,65536,98304,131072,
				196608,10000000     
                                 };

        uint32_t freq_array[28]={  10000,9980,12708,
				   8750,8520,8375,8100,7135,
				   6250,6120,5560,3570,
				   2900,2200,1786,1190,1020,
				   769,537,487,347,
				   194,154,127,94,81,	
				   77,39
				};

	uint32_t getResistance(uint32_t freq){

		uint8_t i;

		for(i=0;i<38;i++){
			if(freq_array[i]<freq)
				break;
		}


		return ohms_array[i-1];

	}	

  
	command error_t FrequencyControl.start(){
		call Interrupt.enableRisingEdge();
		return SUCCESS;
        }


	command error_t FrequencyControl.stop(){

		return SUCCESS;

        }

	 command error_t Gypsum.readFreq(){
		atomic {
			count=0;
			num_Samples = sample_Count;
			total =0;
			}
		call MeasureTimer.startOneShot(MEASURE_PERIOD);	
		return SUCCESS;

	}

	command error_t Gypsum.setSamples(uint8_t samples){
		if(samples>0)
			sample_Count =  samples;
		return SUCCESS;
        }

	event void MeasureTimer.fired(){
		
		atomic{
			num_Samples--;
			//printf("Num Samples:%d\n",num_Samples);
			total += count;
			count=0;
			if(num_Samples==0){
				//printf("Total Count::%ld\n",total/sample_Count);

				signal Gypsum.readDone(SUCCESS,(total*4)/sample_Count,getResistance((total*4)/sample_Count));
			}else{
				
				call MeasureTimer.startOneShot(MEASURE_PERIOD);
			}
			printfflush();
		      }		

		
	}
	
	async event void Interrupt.fired()
	{
		atomic count++;
		
   	}



}

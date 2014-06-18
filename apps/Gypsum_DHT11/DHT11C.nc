	#include "printf.h"
#if defined DEBUG_PRINTF
	#define NEW_PRINTF_SEMANTICS

	#define pr_debug_log(X) 	printf(X)
	#define pr_debug_error(X)	printf(X)
#endif

#define HUMIDITY_MASK 0x01
#define TEMPERATURE_MASK 0x02


module DHT11C @safe()
{
	provides interface DHT11;  
	uses{
		 interface GeneralIO as DataPin;
		 interface GpioInterrupt as DataInterrupt;
      		 interface Timer<TMilli> as DHT11Timer;
		 interface Timer<TMilli> as MeasureTimer;
		 interface Alarm<TMicro,uint16_t>;
		 interface Leds;
	    }
}
implementation
{

	#define SET_BIT(x,n)  x |= 1<<n
        #define CLR_BIT(x,n)  x ^= 1<<n 
	/*
		Various states for the DHT Timer
	*/
	uint8_t temperature_dec,temperature_int,humid_dec,humid_int,checksum;
	enum{
		INIT_STATE,
		START_SIGNAL,
		DELAY_STATE,
		RESPONSE_STATE,
		DHT_FALL_EDGE,
		DHT_RISE_EDGE,
		DHT_READ_STATE,
		DHT_START_BIT,
		DHT_DATA_BIT,

	};

	/*
		Various Errors in DHT Timer
	*/

        enum {
		NO_ERROR,
		CHECKSUM_FAILED = 1,	//some error in the received data
		LONG_INTERRUPT = 2,	//logical voltage of the interrupt is more than 150us
		MISSING_BITS = 3,	//Total 40 bits of data is not received
		NO_RESPONSE  = 4,	//No response received from DHT11
		FALL_RISE    = 5,	//Either falling or rising edge is not recv within 80us
        };

    
	enum {
		MEASURE_HUMIDITY=0x01,
		MEASURE_TEMPERATURE=0x02,		
         };


	uint8_t DHTState = INIT_STATE ; 

	uint8_t readState;

	char measurement[5];

	uint16_t start_time,end_time;

	uint8_t bit_count=0;
	/*
		MCU sends the start signal to the DHT11
	*/
	void sendStartSignal()
	{
		
		
	atomic{
		/*	
		Data Pin has to be set from high to low for 18ms and then 			pull it up 
		*/
		
		DHTState = START_SIGNAL;
		call DataPin.clr();
		call DHT11Timer.startOneShot(18);
		}
		
	}

	
	void sendResult(uint8_t Error_Code){
		#if defined PRINTF_DEBUG
			pr_debug_error("Error_Code is %d",Error_Code);
		#endif	

		call DataInterrupt.disable();				
								
		if((readState & TEMPERATURE_MASK) == MEASURE_TEMPERATURE){
				
	signal 	DHT11.readTempDone(Error_Code,temperature_dec,temperature_int);
		}
		if((readState & HUMIDITY_MASK) == MEASURE_HUMIDITY){
			
			signal DHT11.readHumidityDone(Error_Code,humid_dec,humid_int);	
		}
		DHTState = INIT_STATE;	//available for next read
		bit_count = 0;
		memset(&measurement,0,sizeof(measurement));
		temperature_dec=temperature_int=humid_dec=humid_int=checksum=0;

	}
	

	


	/*
		MCU initiates the read Operation
	*/
	command error_t DHT11.read(bool temperature,bool humidity){
	
		#if defined DEBUG_PRINTF
			pr_debug_log("Read  Called\n");
		#endif
		atomic{			
			if(DHTState != INIT_STATE){
				return EBUSY;
			}	
	
			if(temperature)
				readState |= MEASURE_TEMPERATURE;
			if(humidity)
				readState |= MEASURE_HUMIDITY;
		}
		
		
		call DataPin.makeOutput();
		call DataPin.set();
		sendStartSignal();
		

		return SUCCESS;
		
	}


	//useful for signalling to the user
	event void MeasureTimer.fired(){
	atomic{			
		if(bit_count!=40){
			sendResult(MISSING_BITS);
		}else{		
			humid_int            = measurement[0];
			humid_dec            = measurement[1];
			temperature_int      = measurement[2];
			temperature_dec      = measurement[3];
			checksum	     = measurement[4];			
		}	
			
		if(humid_int+humid_dec+temperature_int+temperature_dec != checksum){
		
			printf("Rcvd Chksm:%d,orig Chksm:%d\n",checksum,humid_int+humid_dec+temperature_int+temperature_dec);
			printfflush();
			sendResult(CHECKSUM_FAILED);
		}
		else{
			sendResult(SUCCESS);
		}
	}
	}	


	async event void Alarm.fired(){
		if(DHTState == RESPONSE_STATE){ //it means DHT has not send the response
			sendResult(NO_RESPONSE);
		}else if(DHTState == DHT_DATA_BIT){
			sendResult(LONG_INTERRUPT);
		}else if(DHTState == DHT_FALL_EDGE || DHTState == DHT_RISE_EDGE){
			sendResult(FALL_RISE);
		}
	}

	event void DHT11Timer.fired(){
		#if defined PRINTF_DEBUG
			pr_debug_log("dht11 timer fired");
		#endif
		
		atomic{

			
			if(DHTState == START_SIGNAL){
				#if defined PRINTF_DEBUG
					pr_debug_log("Low for 18 ms");
					printfflush();	
				#endif
				/*
					Now MCU has to wait 20-40 us for DHT response
				*/
				call DataPin.set();
				call DataPin.makeInput();
				call DataInterrupt.enableFallingEdge();	//as DHT11 pulls the line low	
				DHTState= RESPONSE_STATE;
				
				call Alarm.start(40);
			}
			
		}


	}

	async event void DataInterrupt.fired()
	{
		#if defined PRINTF_DEBUG
			pr_debug_log("Interrupt fired");
		#endif

		if(DHTState == RESPONSE_STATE){	//dht11 pulls the line down for 80us
			//TODO: check whether the line is actually low for 80 us
			call Alarm.stop();
			DHTState = DHT_FALL_EDGE;
			call Alarm.start(80);	//line should be low for 80us
			call DataInterrupt.disable();
			call DataInterrupt.enableRisingEdge();//as DHT11 pulls the line high after 80 us

		}else if(DHTState == DHT_FALL_EDGE){	//dht11 pulls the line up for 80 us
			call Alarm.stop();
			call Alarm.start(80);	//line should be high for 80us
			DHTState = DHT_RISE_EDGE;
			//it keeps high for 80 us
			call DataInterrupt.disable();
			call DataInterrupt.enableFallingEdge();

		}else if(DHTState == DHT_RISE_EDGE ){//dht received the start bit


			DHTState = DHT_START_BIT;
			call DataInterrupt.disable();
			call DataInterrupt.enableRisingEdge();
			call MeasureTimer.startOneShot(4); //one communication is about 4ms			
		}else if(DHTState == DHT_START_BIT){

			call Alarm.start(150);	//it should not be high for  more than 150us
			start_time = call Alarm.getNow();
			DHTState = DHT_DATA_BIT;			
			call DataInterrupt.disable();
			call DataInterrupt.enableFallingEdge();
		}else if(DHTState == DHT_DATA_BIT){
			end_time = call Alarm.getNow();
			call Alarm.stop();

			if(end_time-start_time>30){//it is logical one
				SET_BIT(measurement[bit_count/8],(7-(bit_count%8)));
			}
			bit_count++;
			DHTState = DHT_START_BIT;

			call DataInterrupt.disable();
			call DataInterrupt.enableRisingEdge();
					
		}
		
	}

		
   	



}


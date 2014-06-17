


interface DHT11{
	
	/*
		MCU initiates the read Operation
	*/
	command error_t read(bool temperature,bool humidity);

	

	/*
		Signals the temperature value to the user
		dec     -> decimal part
		integ   -> integer part
	*/

	event void readTempDone(error_t error,uint8_t dec,uint8_t integ);



	/*
		Signals the Humidity value to the user
		dec     -> decimal part
		integ   -> integer part

	*/


	event void readHumidityDone(error_t error,uint8_t dec,uint8_t integ);



}

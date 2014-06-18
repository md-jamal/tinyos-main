


interface Gypsum{

	/*
		Initiates the read operation
	*/

          command error_t readFreq();

	
         command error_t setSamples(uint8_t Samples);


	/*
		Signals the completion of the event
	*/

          event void readDone( error_t result, uint16_t freq, uint16_t resist );


	

}

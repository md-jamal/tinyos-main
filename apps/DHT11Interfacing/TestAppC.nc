

configuration TestAppC{



}


implementation{

	components TestC,DHT11AppC,MainC;

	TestC.Boot -> MainC;
	TestC.DHT11 -> DHT11AppC;
	
	#ifdef DEBUG_PRINTF
		components PrintfC,SerialStartC;
	#endif

	components new TimerMilliC() as Timer;
	TestC.Timer -> Timer;

	components LedsC;
	TestC.Leds -> LedsC;
	
	components PrintfC,SerialStartC;
	
}


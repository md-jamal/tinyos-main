


configuration FreqDriverAppC{

	provides interface StdControl;
	provides interface Gypsum;

}


implementation{

	components FreqDriverC;
	StdControl = FreqDriverC;
	Gypsum = FreqDriverC;

	components new TimerMilliC() as Timer;
  	FreqDriverC.MeasureTimer -> Timer;

  	components HplMsp430InterruptC as InterruptC;
   	components new Msp430InterruptC() as Int0;
   	Int0 -> InterruptC.Port20;
   	FreqDriverC.Interrupt -> Int0;



}

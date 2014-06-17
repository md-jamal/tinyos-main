
configuration DHT11AppC{

	provides interface DHT11;

}
implementation {
  components  DHT11C;
  DHT11 = DHT11C;

  components HplMsp430InterruptC as InterruptC;
  components new Msp430InterruptC() as DataInterrupt;
  DataInterrupt	 -> InterruptC.Port27;
  DHT11C.DataInterrupt -> DataInterrupt;


  components HplMsp430GeneralIOC as HplGeneralIO;
  components new Msp430GpioC() as DataPin;
  DataPin -> HplGeneralIO.Port27;
  DHT11C.DataPin -> DataPin;

  components new TimerMilliC() as DHT11Timer,new TimerMilliC() as MeasureTimer;
  DHT11C.DHT11Timer -> DHT11Timer;
  DHT11C.MeasureTimer -> MeasureTimer;

  components new AlarmMicro16C() as AlarmC;
  DHT11C.Alarm -> AlarmC;

  components LedsC;
  DHT11C.Leds -> LedsC;

}


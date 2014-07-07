/** Test the link-local communication in the blip stack
 */
configuration TestNDAppC {

} implementation {
  components MainC, LedsC;
  components TestNDC;
  components NDC;

  TestNDC.Boot -> MainC;
  TestNDC.SplitControl -> NDC;
  TestNDC.Leds -> LedsC;


}

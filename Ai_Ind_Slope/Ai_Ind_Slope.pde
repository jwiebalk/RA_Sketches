#include <ReefAngel_Features.h>
#include <ReefAngel_Globals.h>
#include <ReefAngel_Wifi.h>
#include <Wire.h>
#include <OneWire.h>
#include <Time.h>
#include <DS1307RTC.h>
#include <ReefAngel_EEPROM.h>
#include <ReefAngel_NokiaLCD.h>
#include <ReefAngel_ATO.h>
#include <ReefAngel_Joystick.h>
#include <ReefAngel_LED.h>
#include <ReefAngel_TempSensor.h>
#include <ReefAngel_Relay.h>
#include <ReefAngel_PWM.h>
#include <ReefAngel_Timer.h>
#include <ReefAngel_Memory.h>
//#include <ReefAngel_Salinity.h>
#include <ReefAngel_AI.h>
#include <ReefAngel.h>

#define Port8   8
#define Heater  7
#define Port6   6
#define Port5   5
#define FugePH  4
#define PH      3
#define SOL     2
#define FugeLT  1

#define T1LOW   720

#define T1HIGH  850

#define T2LOW   500

#define T2HIGH  850

#define T3LOW   650

#define T3HIGH  1000

// Labels for the web banner
#include <avr/pgmspace.h>
prog_char id_label[] PROGMEM = "wolfador";
prog_char probe1_label[] PROGMEM = "Water";
prog_char probe2_label[] PROGMEM = "Room";
prog_char probe3_label[] PROGMEM = "Ai%20Nano";
prog_char relay1_label[] PROGMEM = "Fuge%20Light";
prog_char relay2_label[] PROGMEM = "Ai%20Sol%20Nano";
prog_char relay3_label[] PROGMEM = "PowerHead";
prog_char relay4_label[] PROGMEM = "Fuge%20Pump";
prog_char relay5_label[] PROGMEM = "NA";
prog_char relay6_label[] PROGMEM = "NA";
prog_char relay7_label[] PROGMEM = "Heater";
prog_char relay8_label[] PROGMEM = "NA";


PROGMEM const char *webbanner_items[] = {
id_label, probe1_label, probe2_label, probe3_label, relay1_label, relay2_label,
relay3_label, relay4_label, relay5_label, relay6_label, relay7_label, relay8_label};

void WifiSendAlert(byte id, boolean IsAlert)
{
static byte alert_status;
if (IsAlert)
{
if ((alert_status & 1<<(id-1))==0)
{
alert_status|=1<<(id-1);
Serial.print("GET /status/alert.asp?e=4122988294@txt.att.net&id=");
Serial.println(alert_status,DEC);
Serial.println("\n\n");
}}
else
{
if (id==0)
{
alert_status=0;
delay(900);
}
else
{
alert_status&=~(1<<(id-1));
}}}
void setup()
{
    ReefAngel.Init();

    ReefAngel.LoadWebBanner(pgm_read_word(&(webbanner_items[0])), SIZE(webbanner_items));
    ReefAngel.Timer[4].SetInterval(180);
    ReefAngel.Timer[4].Start();

    ReefAngel.FeedingModePorts = B00001100;
    ReefAngel.WaterChangePorts = B01001100;
    //ReefAngel.OverheatShutoffPorts = B10110000;
   // ReefAngel.LightsOnPorts = B00000010;
  
  //WifiAuthentication("wolfador:gixxer");   

    ReefAngel.Relay.On(FugePH);
    ReefAngel.Relay.On(PH);
    ReefAngel.Relay.On(SOL);
    
    ReefAngel.AI.SetPort(highATOPin);
}

void loop()
{
    ReefAngel.ShowInterface();

    // Specific functions
    ReefAngel.StandardLights(FugeLT,23,0,10,0); 
    ReefAngel.StandardHeater(Heater);
    
    // Web Banner stuff
if(ReefAngel.Timer[4].IsTriggered())
{
ReefAngel.Timer[4].Start();
ReefAngel.WebBanner();
}

//This will send an alert if T1 is below 77 and reset if above 78
if (ReefAngel.Params.Temp1<770 && ReefAngel.Params.Temp1>0) WifiSendAlert(3,true);
if (ReefAngel.Params.Temp1>780 && ReefAngel.Params.Temp1<1850) WifiSendAlert(3,false);
//This will send an alert if T1 is above 83 and reset if below 80
if (ReefAngel.Params.Temp1>820 && ReefAngel.Params.Temp1>1850) WifiSendAlert(4,true);
if (ReefAngel.Params.Temp1<800 && ReefAngel.Params.Temp1>0) WifiSendAlert(4,false);
//PWMSlope(byte startHour, byte startMinute, byte endHour, byte endMinute, byte startPWM, byte endPWM, byte Duration, byte oldValue)

if (hour()>=5 && hour()<9)
    {
  ReefAngel.AI.SetChannel(White,0);
  //ReefAngel.AI.SetChannel(Blue,4);
 // ReefAngel.AI.SetChannel(RoyalBlue,4);
 
  ReefAngel.AI.SetChannel(Blue,PWMSlope(5,0,9,0,2,4,240,2));
  ReefAngel.AI.SetChannel(RoyalBlue,PWMSlope(5,0,9,0,2,4,240,2));
  
    }
    else if (hour()>=9 && hour()<11)
    {
  
  ReefAngel.AI.SetChannel(White,PWMSlope(9,0,11,0,0,4,240,0));
  ReefAngel.AI.SetChannel(Blue,PWMSlope(9,0,11,0,4,8,240,4));
  ReefAngel.AI.SetChannel(RoyalBlue,PWMSlope(9,0,11,0,4,8,240,4));
    }
   else if (hour()>=11 && hour()<13)
    {
  ReefAngel.AI.SetChannel(White,PWMSlope(11,0,13,0,4,15,240,4));
  ReefAngel.AI.SetChannel(Blue,PWMSlope(11,0,13,0,8,20,240,8));
  ReefAngel.AI.SetChannel(RoyalBlue,PWMSlope(11,0,13,0,8,20,240,8));
    }
   else if (hour()>=13 && hour()<17)
    {
  ReefAngel.AI.SetChannel(White,PWMSlope(13,0,17,0,15,30,240,15));
  ReefAngel.AI.SetChannel(Blue,PWMSlope(13,0,17,0,20,35,240,20));
  ReefAngel.AI.SetChannel(RoyalBlue,PWMSlope(13,0,17,0,20,35,240,20));
    }
   else if (hour()>=17 && hour()<20)
    {
  ReefAngel.AI.SetChannel(White,PWMSlope(17,0,20,0,30,5,240,30));
  ReefAngel.AI.SetChannel(Blue,PWMSlope(17,0,20,0,35,32,240,35));
  ReefAngel.AI.SetChannel(RoyalBlue,PWMSlope(17,0,20,0,35,32,240,35));
    }
   else if (hour()>=20 && hour()<22)
    {
  ReefAngel.AI.SetChannel(White,PWMSlope(20,0,22,0,5,3,240,5));
  ReefAngel.AI.SetChannel(Blue,PWMSlope(20,0,22,0,32,7,240,32));
  ReefAngel.AI.SetChannel(RoyalBlue,PWMSlope(20,0,22,0,32,7,240,32));
    }
   else if (hour()>=22 && hour()<5)
    {
  ReefAngel.AI.SetChannel(White,PWMSlope(22,0,5,0,3,0,240,3));
  ReefAngel.AI.SetChannel(Blue,PWMSlope(22,0,5,0,7,2,240,7));
  ReefAngel.AI.SetChannel(RoyalBlue,PWMSlope(22,0,5,0,7,2,240,7));
    }

  //ReefAngel.AI.SetChannel(White,PWMSlope(9,0,22,0,0,30,240,0));
  //ReefAngel.AI.SetChannel(Blue,PWMSlope(9,0,22,0,0,35,240,2));
  //ReefAngel.AI.SetChannel(RoyalBlue,PWMSlope(9,0,22,0,0,35,240,2));
}


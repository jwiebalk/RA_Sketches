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

byte WhiteValue=0;
byte BlueValue=0;
byte RoyalBlueValue=0;

boolean ForceCloud=false;


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
  
 // Create menu entries
 prog_char menu1_label[] PROGMEM = "Feeding";
 prog_char menu2_label[] PROGMEM = "Water Change";
 prog_char menu3_label[] PROGMEM = "Thunder Storm";
 
 PROGMEM const char *menu_items[] = {
   menu1_label, menu2_label, menu3_label};
 
 void MenuEntry1()
 {
   ReefAngel.FeedingModeStart();
 }
  void MenuEntry2()
 {
   ReefAngel.WaterChangeModeStart();
 }
  void MenuEntry3()
 {
   pingSerial();
   ReefAngel.LCD.DrawDate(6, 90);
  ReefAngel.LCD.DrawText(DefaultFGColor, DefaultBGColor, 20, 40, "ThunderStorm");
  ForceCloud=true;
  //ReefAngel.DisplayedMenu=RETURN_MAIN_MODE;
 }

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

void DrawCustomMain()
{
  // the graph is drawn/updated when we exit the main menu &
  // when the parameters are saved
  //ReefAngel.LCD.DrawDate(6, 115);
  pingSerial();
  ReefAngel.LCD.DrawMonitor(15, 66, ReefAngel.Params);
  ReefAngel.LCD.DrawText(DPColor, DefaultBGColor, 67, 78 ,"W:");
  ReefAngel.LCD.DrawSingleMonitor(ReefAngel.AI.GetChannel(0), DPColor, 79, 78, 1);
  ReefAngel.LCD.DrawText(APColor , DefaultBGColor, 67, 90 ,"B:");
  ReefAngel.LCD.DrawSingleMonitor(ReefAngel.AI.GetChannel(1), APColor, 79, 90, 1);
  ReefAngel.LCD.DrawText(APColor , DefaultBGColor, 94, 90 ,"RB:");
  ReefAngel.LCD.DrawSingleMonitor(ReefAngel.AI.GetChannel(2), APColor, 113, 90, 1);

  pingSerial();
  byte TempRelay = ReefAngel.Relay.RelayData;
  TempRelay &= ReefAngel.Relay.RelayMaskOff;
  TempRelay |= ReefAngel.Relay.RelayMaskOn;
  ReefAngel.LCD.DrawOutletBox(12, 100, TempRelay);
}
void DrawCustomGraph()
{
  ReefAngel.LCD.DrawText(DefaultFGColor, DefaultBGColor, 20, 2, "Wolfador's 10G");
  ReefAngel.LCD.DrawGraph(5,10);
}
//*********************************************************************************************************************************
// Random Cloud/Thunderstorm effects function
void CheckCloud()
{

  // ------------------------------------------------------------
  // Change the values below to customize your cloud/storm effect

  // Frequency in days based on the day of the month - number 2 means every 2 days, for example (day 2,4,6 etc)
  // For testing purposes, you can use 1 and cause the cloud to occur everyday
#define Clouds_Every_X_Days 2 

  // Percentage chance of a cloud happening today
  // For testing purposes, you can use 100 and cause the cloud to have 100% chance of happening
#define Cloud_Chance_per_Day 45

  // Minimum number of minutes for cloud duration.  Don't use max duration of less than 6
#define Min_Cloud_Duration 7

  // Maximum number of minutes for the cloud duration. Don't use max duration of more than 255
#define Max_Cloud_Duration 13

  // Minimum number of clouds that can happen per day
#define Min_Clouds_per_Day 3

  // Maximum number of clouds that can happen per day
#define Max_Clouds_per_Day 5

  // Only start the cloud effect after this setting
  // In this example, start could after 11:30am
#define Start_Cloud_After NumMins(11,30)

  // Always end the cloud effect before this setting
  // In this example, end could before 8:00pm
#define End_Cloud_Before NumMins(18,30)

  // Percentage chance of a lightning happen for every cloud
  // For testing purposes, you can use 100 and cause the lightning to have 100% chance of happening
#define Lightning_Change_per_Cloud 30

  // Note: Make sure to choose correct values that will work within your PWMSLope settings.
  // For example, in our case, we could have a max of 5 clouds per day and they could last for 50 minutes.
  // Which could mean 250 minutes of clouds. We need to make sure the PWMSlope can accomodate 250 minutes of effects or unforseen results could happen.
    // Also, make sure that you can fit double those minutes between Start_Cloud_After and End_Cloud_Before.
  // In our example, we have 510 minutes between Start_Cloud_After and End_Cloud_Before, so double the 250 minutes (or 500 minutes) can fit in that 510 minutes window.
    // It's a tight fit, but it did.

    //#define printdebug // Uncomment this for debug print on Serial Monitor window
//#define forcecloudcalculation // Uncomment this to force the cloud calculation to happen in the boot process. 


    // Change the values above to customize your cloud/storm effect
  // ------------------------------------------------------------
  // Do not change anything below here

  static byte cloudchance=255;
  static byte cloudduration=0;
  static int cloudstart=0;
  static byte numclouds=0;
  static byte lightningchance=0;
  static byte cloudindex=0;
  static byte lightningstatus=0;
  static int LastNumMins=0;
  // Every day at midnight, we check for chance of cloud happening today
  if (hour()==0 && minute()==0 && second()==0) cloudchance=255;

#ifdef forcecloudcalculation
  if (cloudchance==255)
#else
    if (hour()==0 && minute()==0 && second()==1 && cloudchance==255) 
#endif
    {
      //Pick a random number between 0 and 99
      cloudchance=random(100); 
      // if picked number is greater than Cloud_Chance_per_Day, we will not have clouds today
      if (cloudchance>Cloud_Chance_per_Day) cloudchance=0;
      // Check if today is day for clouds. 
      if ((day()%Clouds_Every_X_Days)!=0) cloudchance=0; 
      // If we have cloud today
      if (cloudchance)
      {
        // pick a random number for number of clouds between Min_Clouds_per_Day and Max_Clouds_per_Day
        numclouds=random(Min_Clouds_per_Day,Max_Clouds_per_Day);
        // pick the time that the first cloud will start
        // the range is calculated between Start_Cloud_After and the even distribuition of clouds on this day. 
        cloudstart=random(Start_Cloud_After,Start_Cloud_After+((End_Cloud_Before-Start_Cloud_After)/(numclouds*2)));
        // pick a random number for the cloud duration of first cloud.
        cloudduration=random(Min_Cloud_Duration,Max_Cloud_Duration);
        //Pick a random number between 0 and 99
        lightningchance=random(100);
        // if picked number is greater than Lightning_Change_per_Cloud, we will not have lightning today
        if (lightningchance>Lightning_Change_per_Cloud) lightningchance=0;
      }
    }
  // Now that we have all the parameters for the cloud, let's create the effect
  if (ForceCloud)
{
  ForceCloud=false;
  cloudchance=1;
  cloudduration=10;
  lightningchance=1;
  cloudstart=NumMins(hour(),minute())+1;
}
  if (cloudchance)
  {
    //is it time for cloud yet?
    if (NumMins(hour(),minute())>=cloudstart && NumMins(hour(),minute())<(cloudstart+cloudduration))
    {
      WhiteValue=ReversePWMSlope(cloudstart,cloudstart+cloudduration,WhiteValue,0,180);
      if (lightningchance && (NumMins(hour(),minute())==(cloudstart+(cloudduration/2))) && second()<5) 
      {
        if (random(100)<20) lightningstatus=1; 
        else lightningstatus=0;
        if (lightningstatus)
        {
          WhiteValue=50; 
          BlueValue=50;
          RoyalBlueValue=50;
        }
        else 
        {
          WhiteValue=0; 
          BlueValue=0;
          RoyalBlueValue=0;
        }
        delay(1);
      }
    }
    if (NumMins(hour(),minute())>(cloudstart+cloudduration))
    {
      cloudindex++;
      if (cloudindex < numclouds)
      {
        cloudstart=random(Start_Cloud_After+(((End_Cloud_Before-Start_Cloud_After)/(numclouds*2))*cloudindex*2),(Start_Cloud_After+(((End_Cloud_Before-Start_Cloud_After)/(numclouds*2))*cloudindex*2))+((End_Cloud_Before-Start_Cloud_After)/(numclouds*2)));
        // pick a random number for the cloud duration of first cloud.
        cloudduration=random(Min_Cloud_Duration,Max_Cloud_Duration);
        //Pick a random number between 0 and 99
        lightningchance=random(100);
        // if picked number is greater than Lightning_Change_per_Cloud, we will not have lightning today
        if (lightningchance>Lightning_Change_per_Cloud) lightningchance=0;
      }
    }
  }

  if (LastNumMins!=NumMins(hour(),minute()))
  {
    LastNumMins=NumMins(hour(),minute());
    ReefAngel.LCD.Clear(255,0,120,132,132);
    ReefAngel.LCD.DrawText(0,255,5,120,"C");
    ReefAngel.LCD.DrawText(0,255,11,120,"00:00");
    ReefAngel.LCD.DrawText(0,255,45,120,"L");
    ReefAngel.LCD.DrawText(0,255,51,120,"00:00");
    if (cloudchance && (NumMins(hour(),minute())<cloudstart))
    {
      int x=0;
      if ((cloudstart/60)>=10) x=11; 
      else x=17;
      ReefAngel.LCD.DrawText(0,255,x,120,(cloudstart/60));
      if ((cloudstart%60)>=10) x=29; 
      else x=35;
      ReefAngel.LCD.DrawText(0,255,x,120,(cloudstart%60));
    }
    ReefAngel.LCD.DrawText(0,255,90,120,cloudduration);
    if (lightningchance) 
    {
      int x=0;
      if (((cloudstart+(cloudduration/2))/60)>=10) x=51; 
      else x=57;
      ReefAngel.LCD.DrawText(0,255,x,120,((cloudstart+(cloudduration/2))/60));
      if (((cloudstart+(cloudduration/2))%60)>=10) x=69; 
      else x=75;
      ReefAngel.LCD.DrawText(0,255,x,120,((cloudstart+(cloudduration/2))%60));
    }
  }   
}

byte ReversePWMSlope(long cstart,long cend,byte PWMStart,byte PWMEnd, byte clength)
{
  long n=elapsedSecsToday(now());
  cstart*=60;
  cend*=60;
  if (n<cstart) return PWMStart;
  if (n>=cstart && n<=(cstart+clength)) return map(n,cstart,cstart+clength,PWMStart,PWMEnd);
  if (n>(cstart+clength) && n<(cend-clength)) return PWMEnd;
  if (n>=(cend-clength) && n<=cend) return map(n,cend-clength,cend,PWMEnd,PWMStart);
  if (n>cend) return PWMStart;
}

void setup()
{
  ReefAngel.Init();
  ReefAngel.InitMenu(pgm_read_word(&(menu_items[0])),SIZE(menu_items));
  
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
  
  ReefAngel.OverheatTempProbe = &ReefAngel.Params.Temp3;
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
  
  if (hour()>=22 || hour()<9)
  {
    ReefAngel.AI.SetChannel(White,0);
    ReefAngel.AI.SetChannel(Blue,MoonPhase()*0.06);
    ReefAngel.AI.SetChannel(RoyalBlue,MoonPhase()*0.06);
  }
  else
  {
    WhiteValue=PWMSlope(9,0,21,0,3,30,200,3);
    BlueValue=PWMSlope(9,0,21,0,8,35,240,8);
    RoyalBlueValue=PWMSlope(9,0,21,0,8,35,240,8);
    CheckCloud();
    ReefAngel.AI.SetChannel(White,WhiteValue);
    ReefAngel.AI.SetChannel(Blue,BlueValue);
    ReefAngel.AI.SetChannel(RoyalBlue,RoyalBlueValue);

    //ReefAngel.AI.SetChannel(White,PWMSlope(9,0,21,0,3,30,200,3));
    //ReefAngel.AI.SetChannel(Blue,PWMSlope(9,0,21,0,8,35,240,8));
    //ReefAngel.AI.SetChannel(RoyalBlue,PWMSlope(9,0,21,0,8,35,240,8));
  }

}



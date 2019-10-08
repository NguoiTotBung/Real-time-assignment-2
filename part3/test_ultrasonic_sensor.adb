------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                        Copyright (C) 2011, AdaCore                       --
--                                                                          --
-- This is free software; you can  redistribute it  and/or modify it under  --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. This is distributed in the hope that it will be useful, but WITH-  --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
------------------------------------------------------------------------------

--  Low-level test for an ultrasonic sensor attached to port 1

with System;
with NXT.AVR;
with NXT.Last_Chance;
with Ada.Real_Time;                 use Ada.Real_Time;
with NXT.Display;                   use NXT.Display;
with Interfaces;                    use Interfaces;
with NXT.Ultrasonic_Sensors;        use NXT.Ultrasonic_Sensors;
with NXT.Ultrasonic_Sensors.Ctors;  use NXT.Ultrasonic_Sensors.Ctors;
with Test_Utils;                    use Test_Utils;

procedure Test_Ultrasonic_Sensor is
   use NXT;

   Sonar : Ultrasonic_Sensor := Make (Sensor_1);

   procedure Print (Mode : Operating_Mode) is
   begin
      case Mode is
         when Off        => Put_Line ("Off");
         when Ping       => Put_Line ("Ping mode");
         when Continuous => Put_Line ("Continuous mode");
         when Capture    => Put_Line ("Capture mode");
         when Reset      => Put_Line ("Reset mode");
         when Error      => Put_Line ("Error!");
      end case;
   end Print;

begin
   Sonar.Reset;  -- reset the hardware; now mode is Off

   declare
      Reply : String (1 .. 8);
      Success : Boolean;
   begin
      Sonar.Get_Product_Id (Reply, Success);
      if Success then
         Put_Line (Reply);
      else
         Put_Line ("No id");
      end if;
      Sonar.Get_Sensor_Type (Reply, Success);
      if Success then
         Put_Line (Reply);
      else
         Put_Line ("No type");
      end if;
      Sonar.Get_Version (Reply, Success);
      if Success then
         Put_Line (Reply);
      else
         Put_Line ("No version");
      end if;
   end;

   Await_Button_Press;

   Sonar.Set_Mode (Ping);  -- necessary for getting multiple distances back

   declare
      Actual_Mode : Operating_Mode;
   begin
      Sonar.Query_Current_Mode (Actual_Mode);
      Print (Actual_Mode);
   end;

   declare
      Units : Units_String;
      Success : Boolean;
   begin
      Sonar.Get_Units (Units, Success);
      if Success then
         Put ("units: "); Put_Line (Units);
      else
         Put_Line ("units failed");
      end if;
   end;

   declare
      Interval : Unsigned_8;
      Success  : Boolean;
   begin
      Sonar.Get_Continuous_Interval (Interval, Success);
      if Success then
         Put ("interval: "); Put_Hex (Interval);  New_Line;
      else
         Put_Line ("intrvl failed");
      end if;
   end;

   declare
      Success  : Boolean;
      Interval : Unsigned_8;
   begin
      Sonar.Set_Continuous_Interval (2, Success);
      if Success then
         Put_Line ("set interval 2");
      else
         Put_Line ("set failed");
      end if;
      Sonar.Get_Continuous_Interval (Interval, Success);
      if Success then
         Put ("intrvl (2): "); Put_Hex (Interval);  New_Line;
         --  NB: if it does not display 2, we have a problem!
      else
         Put_Line ("get failed");
      end if;
   end;

   Await_Button_Press;

   declare
      Success      : Boolean;
      Factory_Info : Data;
   begin
      Put_Line ("Factory data:");
      Sonar.Get_Factory_Data (Factory_Info, Success);
      if Success then
         for K in Factory_Info'Range loop
            Put_Hex (Factory_Info (K)); New_Line;
         end loop;
      else
         Put_Line ("get failed");
      end if;
   end;

   Await_Button_Press;

   declare
      Detected     : Distances (1 .. 8); -- or a subset
      Num_Detected : Natural;
      Index        : Natural;
   begin
      loop
         Sonar.Ping;
         Sonar.Get_Distances (Detected, Num_Detected);
         if Num_Detected = 0 then
            Put_Line ("None");
         else
            Index := Detected'First;
            for K in 1 .. Num_Detected loop
               Put_Noupdate (K); Put (": ");
               Put_Noupdate (Integer (Detected (Index)));
               New_Line;
               Index := Index + 1;
            end loop;
         end if;

         exit when NXT.AVR.Button /= No_Button;

         delay until Clock + Milliseconds (500);
      end loop;
   end;

   Put_Line ("Powering off");
   loop
      NXT.AVR.Power_Down;
      delay until Clock + Seconds (1);
   end loop;
end Test_Ultrasonic_Sensor;

with NXT.AVR; use NXT.AVR;
with NXT.Display; use NXT.Display;
with NXT.Light_Sensors; use NXT.Light_Sensors;
with NXT.Light_Sensors.Ctors; use NXT.Light_Sensors.Ctors;
with System;
with Ada.Real_Time; use Ada.Real_Time;

package body Tasks is

	procedure Background is
	begin
		loop
			null;
		end loop;
	end Background;

	task HelloworldTask is
		pragma Priority(System.Priority'Last);
		pragma Storage_Size(4096);
	end HelloworldTask;

	task body HelloworldTask is
		Next_Time : Time := clock;
		Period_Display : Time_Span := Milliseconds(1000);

		light_sen : Light_Sensor := make(Sensor_3, True);
		light_val : integer := 0;
	begin
		---- display hello world
		put("Hello World!");
		newline;
	
		loop
			if NXT.AVR.Button = Power_Button then
				Power_Down;
			end if;
			
			--- read light value and display
			light_val := Light_Value(light_sen);
			put_noupdate("Light value: ");
			put_noupdate(light_val);
			newline;
			screen_update;

			Next_Time := Next_Time + Period_Display;
			delay until Next_Time;
		end loop;
	end HelloworldTask;
end Tasks;

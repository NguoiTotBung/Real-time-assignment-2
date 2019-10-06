with NXT; use NXT;
with NXT.AVR; use NXT.AVR;
with NXT.motor_controls; use NXT.motor_controls;
with NXT.touch_sensors; use NXT.touch_sensors;
with NXT.Display; use NXT.display;
with NXT.Light_Sensors; use NXT.Light_Sensors;
with NXT.Light_Sensors.Ctors; use NXT.Light_Sensors.Ctors;
with System;
with Ada.Real_time; use Ada.Real_time;

package body Part_2 is
    procedure background is
    begin
        loop
            null;
        end loop;
    end background;

    protected body Event is
        entry Wait(event_id: out integer) when Signalled is
        begin
            event_id := current_event_id;
            Signalled := False;
        end Wait;

        procedure Signal(event_id: in integer) is
        begin
            current_event_id := event_id;
            signalled := True;
        end Signal;
    end Event;

    --------------------------------------------------------------------------------------------
    -------- task that listening for touch event and light sensor value and issuing event ------
    task body EventdispatcherTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(100);

        touch_sen            : Touch_Sensor(Sensor_1);
        is_pressed           : Boolean := False;
        old_is_pressed       : Boolean := False;
        light_event_sent     : Boolean := False;

        light_sen : Light_sensor := make(Sensor_3, true);
        light_val : integer := 0;
    begin
        loop
            if (NXT.AVR.Button = Power_Button) then 
                Power_down;
            end if;

            
            --- check if the car is on the edge of the table first
            --- then check the touch sensor
            light_val := Light_value(light_sen);
            if (not light_event_sent and light_val < 25) then
                put("at the edge of table");
                newline;
                Event.signal(TouchOffEvent);
                light_event_sent := true;
            elsif (light_val >= 25) then
                is_pressed := Pressed(touch_sen);
                light_event_sent := False;
                if (is_pressed /= old_is_pressed and is_pressed) then
                    put("touch on");
                    newline;
                    Event.signal(TouchOnEvent);
                    old_is_pressed := is_pressed;
                elsif (is_pressed /= old_is_pressed and not is_pressed) then
                    put("touch off");
                    newline;
                    Event.signal(TouchOffEvent);
                    old_is_pressed := is_pressed;
                end if;
            end if;

            Next_time := Next_time + Delay_interval;
            delay until Next_time;
        end loop;
    end EventdispatcherTask;

    task body MotorcontrolTask is
        Next_time      : Time := clock;
        Delay_interval : Time_Span := Milliseconds(50);

        Right_wheel : Motor_id := Motor_a;
        Left_wheel  : Motor_id := Motor_b;

        touch_event : integer := 0;
        is_running  : Boolean := false;
    begin
        --- stop the car when initializing
        Control_motor(Right_wheel, 0, brake);
        Control_motor(Left_wheel, 0, brake);

        loop
            Event.wait(touch_event);
            if (is_running and touch_event = TouchOffEvent) then
                put("stop");
                newline;
                Control_motor(Right_wheel, 0, brake);
                Control_motor(Left_wheel, 0, brake);
				
                is_running := false;
            elsif (not is_running and touch_event = TouchOnEvent) then
                put("run");
                newline;
                Control_motor(Right_wheel, 50, Forward);
                Control_motor(Left_wheel, 50, Forward);

                is_running := true;
            end if;

            Next_time := Next_time + Delay_interval;
            delay until Next_time;
        end loop;
    end MotorcontrolTask;
end Part_2;

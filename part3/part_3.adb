with NXT; use NXT;
with NXT.AVR; use NXT.AVR;
with NXT.motor_controls; use NXT.motor_controls;
with NXT.touch_sensors; use NXT.touch_sensors;
with NXT.Display; use NXT.display;
with System;
with Ada.Real_time; use Ada.Real_time;

package body part_3 is
    procedure background is
    begin
        loop
            null;
        end loop;
    end background;

    protected body driving_command is
        entry change_driving_command (update_priority: integer; speed: integer; driving_duration: integer) when update_priority >= inner_update_priority is
        begin
            inner_update_priority := update_priority;
            inner_speed := speed;
            inner_driving_duration := driving_duration;
        end change_driving_command;

        procedure read_current_command(update_priority: out integer; speed: out integer; driving_duration: out integer) is
        begin
            update_priority := inner_update_priority;
            speed := inner_speed;
            driving_duration := inner_driving_duration;
        end read_current_command;
    end driving_command;

    -------------------------------------------------------------------------
    ------- task that watch for button press event --------------------------
    ------- issuing new command as long as the button is pressed ------------
    task body ButtonpressTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(10);

        touch_sen            : Touch_Sensor(Sensor_1);
        is_pressed           : Boolean := False;
    begin
        if (NXT.AVR.Button = Power_Button) then
            Power_down;
        end if;

        is_pressed := Pressed(touch_sen);
        if (is_pressed = true) then
            driving_command.change_driving_command(PRIO_BUTTON, 50, 1000);
        end if;

        Next_time := Next_time + Delay_interval;
        delay until Next_time;
    end ButtonpressTask;

    ----------------------------------------------------------------------------
    ---------- a task that control motor ---------------------------------------
    ---------- save the time the last command come, + duration and compare -----
    ---------- with the current time -------------------------------------------
    task body MotorcontrolTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(50);

        update_priority : integer;
        speed          : integer;
        driving_duration : integer;

        new_command_time : Time := clock;

        Right_wheel : Motor_id := Motor_a;
        Left_wheel  : Motor_id := Motor_b;
    begin
        driving_command.read_current_command(update_priority, speed, driving_duration);

        if (update_priority > PRIO_IDLE and new_command_time + Milliseconds(driving_duration) > clock) then
            Control_motor(Right_wheel, speed, Backward);
            Control_motor(Left_wheel, speed, Backward);
        else
            driving_command.change_driving_command(PRIO_IDLE, 0, 0);
            Control_motor(Right_wheel, 0, brake);
            Control_motor(Left_wheel, 0, brake);
        end if;

        Next_time := Next_time + Delay_interval;
        delay until Next_time;
    end MotorcontrolTask;

    ----------------------------------------------------------------------------
    -------- display command description every time a new command is issued ----
    task body DisplayTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(100);

        update_priority : integer := PRIO_IDLE;
        speed          : integer := 0;
        driving_duration : integer := 0;

        old_update_priority : integer := PRIO_IDLE;
        old_speed          : integer := 0;
        old_driving_duration : integer := 0;
    begin
        driving_command.read_current_command(update_priority, speed, driving_duration);

        if (update_priority /= old_update_priority or speed /= speed or driving_duration /= old_driving_duration) then
            Clear_Screen_Noupdate;
            put_noupdate("command: "):
            Newline_Noupdate;
            put_noupdate("- priority: ");
            if (update_priority = PRIO_IDLE) then
                put_noupdate("PRIO_IDLE");
            elsif (update_priority = PRIO_BUTTON) then
                Put_Noupdate("PRIO_BUTTON");
            end if;
            Newline_Noupdate;
            Put_Noupdate("- speed: " & integer'Image(speed));
            Newline_Noupdate;
            Put_Noupdate("- duration: " & integer'Image(driving_duration));
            Screen_Update;
        end if;

        Next_time := Next_time + Delay_interval;
        delay until Next_time;
    end DisplayTask;
end part_3;

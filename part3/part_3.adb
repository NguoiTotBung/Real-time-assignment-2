with NXT; use NXT;
with NXT.AVR; use NXT.AVR;
with NXT.motor_controls; use NXT.motor_controls;
with NXT.touch_sensors; use NXT.touch_sensors;
with NXT.Display; use NXT.display;
with NXT.Ultrasonic_Sensors; use NXT.Ultrasonic_Sensors;
with NXT.Ultrasonic_Sensors.Ctors; use NXT.Ultrasonic_Sensors.Ctors;
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
        procedure change_driving_command(update_priority: integer; speed: integer; driving_duration: integer) is
        begin
            if (update_priority >= inner_update_priority) then
                inner_update_priority := update_priority;
                inner_speed := speed;
                inner_driving_duration := driving_duration;
                executed := false;
            end if;
        end change_driving_command;

        procedure read_current_command(update_priority: out integer; speed: out integer; driving_duration: out integer; execute: out Boolean) is
        begin
            update_priority := inner_update_priority;
            speed := inner_speed;
            driving_duration := inner_driving_duration;
            execute := executed;
        end read_current_command;

        procedure change_execution_state(execute : Boolean) is
        begin
            executed := execute;
        end change_execution_state;
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
        put_noupdate("Task button: pressed = ");
        if (is_pressed) then
            put_noupdate("true");
        else
            Put_Noupdate("False");
        end if;
        newline;
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
        speed           : integer;
        driving_duration : integer;
        executed         : Boolean := false;

        new_command_time : Time := clock;

        Right_wheel : Motor_id := Motor_a;
        Left_wheel  : Motor_id := Motor_b;
    begin
        driving_command.read_current_command(update_priority, speed, driving_duration, executed);

        if (not executed) then
            new_command_time := clock;
            put("execute command");
            if (new_command_time + Milliseconds(driving_duration) > clock) then
                Control_motor(Right_wheel, NXT.Pwm_Value(speed), Backward);
                Control_motor(Left_wheel, NXT.Pwm_Value(speed), Backward);
            else
                driving_command.change_driving_command(PRIO_IDLE, 0, 0);
                Control_motor(Right_wheel, 0, brake);
                Control_motor(Left_wheel, 0, brake);
            end if;
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

        command_count : integer := 0;
    begin
        driving_command.read_current_command(update_priority, speed, driving_duration);

        if (update_priority /= old_update_priority or speed /= speed or driving_duration /= old_driving_duration) then
            Clear_Screen_Noupdate;
            put_noupdate("command: ");
            put_noupdate(command_count);
            Newline_Noupdate;
            put_noupdate("- priority: ");
            if (update_priority = PRIO_IDLE) then
                put_noupdate("PRIO_IDLE");
            elsif (update_priority = PRIO_BUTTON) then
                Put_Noupdate("PRIO_BUTTON");
            end if;
            Newline_Noupdate;
            Put_Noupdate("- speed: ");
            Put_Noupdate(speed);
            Newline_Noupdate;
            Put_Noupdate("- duration: ");
            Put_Noupdate(driving_duration);
            Screen_Update;

            command_count := command_count + 1;
        end if;

        Next_time := Next_time + Delay_interval;
        delay until Next_time;
    end DisplayTask;

    ----------------------------------------------------------------------------
    ------- a task that measure distance ---------------------------------------
--      task body DistanceTask is
--          Next_time      : Time := clock;
--          Delay_interval : Time_span := Milliseconds(100);
--
--          distance_sensor : Ultrasonic_Sensor := Make(Sensor_1);
--          distance : Natural := 0;
--      begin
--          Get_Distance(distance_sensor, distance);
--
--
--
--          Next_time := Next_time + Delay_interval;
--          delay until Next_time;
--      end DistanceTask;
end part_3;

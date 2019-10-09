with NXT; use NXT;
with NXT.AVR; use NXT.AVR;

with NXT.motor_controls; use NXT.motor_controls;

with NXT.touch_sensors; use NXT.touch_sensors;

with NXT.Display; use NXT.display;

with NXT.Ultrasonic_Sensors; use NXT.Ultrasonic_Sensors;
with NXT.Ultrasonic_Sensors.Ctors; use NXT.Ultrasonic_Sensors.Ctors;

with NXT.Light_Sensors; use NXT.Light_Sensors;
with NXT.Light_Sensors.Ctors; use NXT.Light_Sensors.Ctors;

with System;
with Ada.Real_time; use Ada.Real_time;

package body part_4 is
    procedure background is
    begin
        loop
            null;
        end loop;
    end background;

    protected body car_state is
        entry is_running when is_running_yet is
        begin
            null;
        end is_running;

        procedure next_state is
        begin
            if (Current_State = cali_black) then
                Current_State := cali_gray;
            elsif (Current_State = cali_gray) then
                Current_State := cali_white;
            elsif (Current_State = cali_white) then
                Current_State := ready;
            elsif (Current_State = ready) then
                Current_State := follow;
                is_running_yet := true;
            elsif (Current_State = follow) then
                Current_State := run_alone;
                is_running_yet := true;
            end if;
        end next_state;

        function get_state return states is
        begin
            return Current_State;
        end get_state;
    end car_state;

    protected body driving_command is
        procedure change_driving_command(update_priority: integer; speed: integer; driving_duration: integer; direction: Motion_Modes; force : boolean := false) is
        begin
            ---- need force in order to change back to PRIO_IDLE
            if (force or update_priority >= inner_update_priority) then
                inner_update_priority := update_priority;
                inner_speed := speed;
                inner_driving_duration := driving_duration;
                inner_direction := direction;
                version := version + 1;
            end if;
        end change_driving_command;

        procedure read_current_command(update_priority: out integer; speed: out integer; driving_duration: out integer; direction: out Motion_Modes; version_out: out integer) is
        begin
            update_priority := inner_update_priority;
            speed := inner_speed;
            driving_duration := inner_driving_duration;
            direction := inner_direction;
            version_out := version;
        end read_current_command;
    end driving_command;

    -------------------------------------------------------------------------
    ------- task that watch for button press event --------------------------
    ------- issuing 1 command for a key down event only ------------
    task body ButtonpressTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(10);

        touch_sen            : Touch_Sensor(Sensor_2);
        is_pressed           : Boolean := False;
        old_is_pressed       : Boolean := True;

        state : states;
    begin
        loop
            if (NXT.AVR.Button = Power_Button) then
                Power_down;
            end if;

            is_pressed := Pressed(touch_sen);

            if (is_pressed /= old_is_pressed and is_pressed) then
                state := car_state.get_state;

                if (state /= run_alone) then
                    car_state.next_state;
                end if;
            end if;

            old_is_pressed := is_pressed;

            Next_time := Next_time + Delay_interval;
            delay until Next_time;
        end loop;
    end ButtonpressTask;

    ----------------------------------------------------------------------------
    ---------- a task that control motor ---------------------------------------
    ---------- save the time the last command come, + duration and compare -----
    ---------- with the current time -------------------------------------------
    task body MotorcontrolTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(50);

        state : states;

        update_priority : integer;
        speed           : integer;
        driving_duration : integer;
        direction        : Motion_Modes;
        version         : integer := 0;
        old_version      : integer := 0;

        new_command_time : Time := clock;
        deadline_passed : Boolean := False;

        Right_wheel : Motor_id := Motor_a;
        Left_wheel  : Motor_id := Motor_b;
    begin
        loop
            state := car_state.get_state;

            if (state = follow or state = run_alone) then
                driving_command.read_current_command(update_priority, speed, driving_duration, direction, version);

                if (version > old_version) then
                    new_command_time := clock;
                    old_version := version;
                end if;

                if (version = old_version) then
                    deadline_passed := new_command_time + Milliseconds(driving_duration) <= clock;
                    if (not deadline_passed) then
                        Control_motor(Right_wheel, NXT.Pwm_Value(speed + 10), direction);
                        Control_motor(Left_wheel, NXT.Pwm_Value(speed), direction);
                    elsif (deadline_passed and update_priority /= PRIO_IDLE) then
                        driving_command.change_driving_command(PRIO_IDLE, 0, 0, Brake, true);
                        Control_motor(Right_wheel, 0, brake);
                        Control_motor(Left_wheel, 0, brake);
                    end if;
                end if;
            end if;

            Next_time := Next_time + Delay_interval;
            delay until Next_time;
        end loop;
    end MotorcontrolTask;

    ----------------------------------------------------------------------------
    -------- display command description every time a new command is issued ----
--      task body DisplayTask is
--          Next_time      : Time := clock;
--          Delay_interval : Time_span := Milliseconds(100);
--
--          update_priority : integer := PRIO_IDLE;
--          speed          : integer := 0;
--          driving_duration : integer := 0;
--          direction        : Motion_Modes;
--          version          : integer := 0;
--          old_version      : integer := -1;
--
--          old_update_priority : integer := PRIO_IDLE;
--          old_speed          : integer := 0;
--          old_driving_duration : integer := 0;
--      begin
--          loop
--              driving_command.read_current_command(update_priority, speed, driving_duration, direction, version);
--
--              if (version > old_version) then
--                  old_version := version;
--                  Clear_Screen_Noupdate;
--                  put_noupdate("command: ");
--                  put_noupdate(version);
--                  Newline_Noupdate;
--                  put_noupdate("- priority: ");
--                  if (update_priority = PRIO_IDLE) then
--                      put_noupdate("PRIO_IDLE");
--                  elsif (update_priority = PRIO_DIST) then
--                      put_noupdate("PRIO_DIST");
--                  elsif (update_priority = PRIO_BUTTON) then
--                      Put_Noupdate("PRIO_BUTTON");
--                  end if;
--                  Newline_Noupdate;
--                  Put_Noupdate("- speed: ");
--                  Put_Noupdate(speed);
--                  Newline_Noupdate;
--                  Put_Noupdate("- duration: ");
--                  Put_Noupdate(driving_duration);
--                  Newline_Noupdate;
--                  Put_noupdate("- direction: ");
--                  if (direction = Backward) then
--                      Put_noupdate("Backward");
--                  elsif (direction = Forward) then
--                      Put_Noupdate("Forward");
--                  elsif (direction = Brake) then
--                      put_noupdate("Brake");
--                  end if;
--                  newline;
--              end if;
--
--              Next_time := Next_time + Delay_interval;
--              delay until Next_time;
--          end loop;
--      end DisplayTask;

    ----------------------------------------------------------------------------
    ------- a task that measure distance ---------------------------------------
    task body DistanceTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(200);

        distance_sensor : Ultrasonic_Sensor := Make(Sensor_1);
        distance        : Natural := 0;
        base_distance   : Natural := 35;
        diff            : integer := 0;
        coefficient     : float := 1.5;
        speed           : integer;
        direction       : Motion_Modes;
    begin
        distance_sensor.Reset;
        loop
            distance_sensor.ping;
            distance_sensor.Get_Distance(distance);

            --- use 35 as baseline, compute the difference, then multiply with the coefficient to
            --- get the speed
            --- 1 unit buffer -> will stop when the distance is from 34 to 36
            diff := distance - base_distance;
            if (diff > 1) then
                direction := Forward;
                speed := integer(float(diff) * coefficient);
            elsif (diff < -1) then
                direction := Backward;
                speed := integer(float(diff) * coefficient * (-2.0)); --- double the coefficient for backward motion
            else
                direction := Brake;
                speed := 0;
            end if;

            if (speed > integer(PWM_Value'Last) / 2) then
                speed := integer(PWM_Value'Last) / 2;
            end if;

            driving_command.change_driving_command(PRIO_DIST, speed, 500, direction);

            Next_time := Next_time + Delay_interval;
            delay until Next_time;
        end loop;
    end DistanceTask;

    task body LightSensorTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(100);

        state          : states;

        light_sen      : Light_sensor := make(Sensor_3, true);
        black          : integer := 0;
        gray           : integer := 0;
        white          : integer := 0;
    begin
        loop
            state := car_state.get_state;

            if (state = cali_black) then
                black := Light_value(light_sen);
            elsif (state = cali_gray) then
                gray := Light_value(light_sen);
            elsif (state = cali_white) then
                white := Light_value(light_sen);
            elsif (state = follow or state = run_alone) then

            end if;

            Next_time := Next_time + Delay_interval;
            delay until Next_time;
        end loop;
    end LightSensorTask;
end part_4;

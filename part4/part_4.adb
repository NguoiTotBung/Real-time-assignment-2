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

    --- store state of the car -----------------
    protected body car_state is
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
            elsif (Current_State = follow) then
                Current_State := run_alone;
            end if;
        end next_state;

        function get_state return states is
        begin
            return Current_State;
        end get_state;

        function get_state_string(state: states) return String is
        begin
            if (state = cali_black) then
                return "cali_black";
            elsif (state = cali_gray) then
                return "cali_gray";
            elsif (state = cali_white) then
                return "cali_white";
            elsif (state = ready) then
                return "ready";
            elsif (state = follow) then
                return "follow";
            elsif (state = run_alone) then
                return "run_alone";
            else
                return "";
            end if;
        end get_state_string;
    end car_state;

    protected body driving_command is
        procedure change_speed(speed: integer) is
        begin
            inner_speed := speed;
        end change_speed;

        procedure change_turn_ratio(turn_ratio: float) is
        begin
            inner_turn_ratio := turn_ratio;
        end change_turn_ratio;

        procedure read_current_command(speed: out integer; turn_ratio: out float) is
        begin
            speed := inner_speed;
            turn_ratio := inner_turn_ratio;
        end read_current_command;
    end driving_command;

    -------------------------------------------------------------------------
    ------- task that watch for button press event --------------------------
    ------- advance to the next state when the button is pressed ------------
    task body ButtonpressTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(10);

        touch_sen            : Touch_Sensor(Sensor_2);
        is_pressed           : Boolean := False;
        old_is_pressed       : Boolean := True;

        state : states;
    begin
        put_noupdate("state: ");
        put_noupdate(car_state.get_state_string(car_state.get_state));
        newline;
        loop
            if (NXT.AVR.Button = Power_Button) then
                Power_down;
            end if;

            is_pressed := Pressed(touch_sen);

            if (is_pressed /= old_is_pressed and is_pressed) then
                state := car_state.get_state;

                if (state /= run_alone) then
                    car_state.next_state;

                    state := car_state.get_state;
                    put_noupdate("state: ");
                    put_noupdate(car_state.get_state_string(state));
                    newline;
                end if;
            end if;

            old_is_pressed := is_pressed;

            Next_time := Next_time + Delay_interval;
            delay until Next_time;
        end loop;
    end ButtonpressTask;

    ----------------------------------------------------------------------------
    ---------- a task that control motor ---------------------------------------
    task body MotorcontrolTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(100);

        state          : states;

        speed           : integer;
        turn_ratio      : float;

        Right_wheel : Motor_id := Motor_a;
        Left_wheel  : Motor_id := Motor_b;
    begin
        loop
            state := car_state.get_state;
            if (state = follow or state = run_alone) then
                driving_command.read_current_command(speed, turn_ratio);
                --- + 3 for right wheel because 2 motors are not totally identical
                --- the formula is: speed = original_speed - (original_speed * turn_ratio / 1.2)
                --- the turn_ratio has the value from -1 to 1 and indicating how much the car is off the track
                --- refer to command in task LightSensorTask for how turn_ratio is computed
                --- white on the right, black on the left
                --- turn_ratio > 0 = turn left, < 0 = turn right
                if (turn_ratio > 0.0) then
                    Control_motor(Right_wheel, NXT.Pwm_Value(speed + 3), Forward);
                    Control_motor(Left_wheel, NXT.Pwm_Value(speed - integer(float(speed) * turn_ratio / 1.2)), Forward);
                elsif (turn_ratio < 0.0) then
                    Control_motor(Right_wheel, NXT.Pwm_Value(speed + 3 + integer(float(speed + 3) * turn_ratio / 1.2)), Forward);
                    Control_motor(Left_wheel, NXT.Pwm_Value(speed), Forward);
                else
                    Control_motor(Right_wheel, NXT.Pwm_Value(speed + 3), Forward);
                    Control_motor(Left_wheel, NXT.Pwm_Value(speed), Forward);
                end if;
            end if;

            Next_time := Next_time + Delay_interval;
            delay until Next_time;
        end loop;
    end MotorcontrolTask;

    ----------------------------------------------------------------------------
    ------- a task that measure distance ---------------------------------------
    task body DistanceTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(100);

        distance_sensor : Ultrasonic_Sensor := Make(Sensor_1);
        distance        : Natural := 0;
        base_distance   : Natural := 25;
        diff            : integer := 0;
        coefficient     : float := 1.5;
        speed           : integer;

        state           : states;
    begin
        distance_sensor.Reset;
        loop
            state := car_state.get_state;

            if (state = follow) then
                distance_sensor.ping;
                distance_sensor.Get_Distance(distance);

                --- use 25 as baseline, compute the difference, then multiply with the coefficient to
                --- get the speed
                diff := distance - base_distance;
                if (diff > 0) then
                    speed := integer(float(diff) * coefficient);
                else
                    speed := 0;
                end if;

                if (speed > 40) then
                    speed := 40;
                end if;

                driving_command.change_speed(speed);
            elsif (state = run_alone) then
                driving_command.change_speed(40);
            end if;

            Next_time := Next_time + Delay_interval;
            delay until Next_time;
        end loop;
    end DistanceTask;

    ----------------------------------------------------------------------------------
    ----- A task that calibrate light value at the first 3 state --------------------
    ----- then at the last 2 states, it will measure light value on the -----------
    ----- track and compute turn_ratio -------------------------------------------
    task body LightSensorTask is
        Next_time      : Time := clock;
        Delay_interval : Time_span := Milliseconds(100);

        state          : states;

        light_sen      : Light_sensor := make(Sensor_3, true);
        black          : integer := 0;
        gray           : integer := 0;
        white          : integer := 0;
        current        : integer := 0;

        turn_ratio     : float := 0.0;

        printed        : Boolean := false;
    begin
        loop
            state := car_state.get_state;

            if (state = cali_black) then
                black := Light_value(light_sen);
            elsif (state = cali_gray) then
                gray := Light_value(light_sen);
            elsif (state = cali_white) then
                white := Light_value(light_sen);
            elsif (state = ready and not printed) then
                Clear_Screen_Noupdate;
                put_noupdate("calibration value: ");
                newline_noupdate;
                put_noupdate("- black: ");
                put_noupdate(black);
                newline_noupdate;
                put_noupdate("- gray: ");
                put_noupdate(gray);
                newline_noupdate;
                put_noupdate("- white: ");
                put_noupdate(white);
                newline;
                printed := true;
            elsif (state = follow or state = run_alone) then
                current := Light_value(light_sen);
                --- get the light value and bound it in the range (black, white)
                if (current < black) then current := black; end if;
                if (current > white) then current := white; end if;

                --- turn_ratio > 0 = turn left, < 0 = turn right
                --- formular: (current - gray)/(white - gray) for current > gray
                ---           (current - gray)/(gray - black) for current < gray
                --- the turn_ratio is the fraction of how much the light value is far from gray compare to black and white
                if (current > gray) then
                    turn_ratio := float(current - gray)/float(white - gray);
                else
                    turn_ratio := float(current - gray)/float(gray - black);
                end if;

                driving_command.change_turn_ratio(turn_ratio);
            end if;

            Next_time := Next_time + Delay_interval;
            delay until Next_time;
        end loop;
    end LightSensorTask;
end part_4;

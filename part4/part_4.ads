with System;
with NXT.motor_controls; use NXT.motor_controls;

package part_4 is
    type states is (cali_black, cali_gray, cali_white, ready, follow, run_alone);
    --- store state of the car -----------------
    protected car_state is
        procedure next_state; ---- advance to next state, the order is the same as declaration above
        function get_state return states;
        function get_state_string(state : states) return String;
    private
        pragma Priority(System.Priority'Last);

        current_state : states := cali_black;
    end car_state;

    protected driving_command is
        procedure change_speed(speed: integer);
        procedure change_turn_ratio(turn_ratio: float);
        procedure read_current_command(speed: out integer; turn_ratio: out float);
    private
        pragma Priority(System.Priority'Last);

        inner_speed           : integer := 0;
        inner_turn_ratio      : float := 0.0;
    end driving_command;

    task ButtonpressTask is
        pragma Priority(System.Priority'Last - 3);
        pragma Storage_Size(2048);
    end ButtonpressTask;

    task MotorcontrolTask is
        pragma Priority(System.Priority'Last - 1);
        pragma Storage_Size(2048);
    end MotorcontrolTask;

    task DistanceTask is
        pragma Priority(System.Priority'Last - 2);
        pragma Storage_Size(2048);
    end DistanceTask;

    task LightSensorTask is
        pragma Priority(System.Priority'Last - 2);
        pragma Storage_Size(2048);
    end LightSensorTask;

--      task DisplayTask is
--          pragma Priority(System.Priority'Last - 5);
--          pragma Storage_Size(1048);
--      end DisplayTask;

    procedure background;
end part_4;

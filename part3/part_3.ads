with System;

package part_3 is
    PRIO_IDLE: integer := 1;
    PRIO_DIST: integer := 2;
    PRIO_BUTTON: integer := 3;

    protected driving_command is
        procedure change_driving_command(update_priority: integer; speed: integer; driving_duration: integer, force: boolean := false);
        procedure read_current_command(update_priority: out integer; speed: out integer; driving_duration: out integer; version_out: out integer);
    private
        pragma Priority(System.Priority'Last);

        inner_update_priority : integer := PRIO_IDLE;
        inner_speed           : integer := 0;
        inner_driving_duration: integer := 0;
        version               : integer := 0;
    end driving_command;

    task ButtonpressTask is
        pragma Priority(System.Priority'Last - 3);
        pragma Storage_Size(4096);
    end ButtonpressTask;

    task MotorcontrolTask is
        pragma Priority(System.Priority'Last - 2);
        pragma Storage_Size(4096);
    end MotorcontrolTask;

    task DisplayTask is
        pragma Priority(System.Priority'Last - 5);
        pragma Storage_Size(4096);
    end DisplayTask;

--      task DistanceTask is
--          pragma Priority(System.Priority'Last - 4);
--          pragma Storage_Size(4096);
--      end DistanceTask;

    procedure background;
end part_3;

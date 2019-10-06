with system;

package Part_2 is
	TouchOnEvent : integer := 1;
	TouchOffEvent : integer := 0;

	protected Event is
		entry Wait(event_id: out integer);
		procedure Signal(event_id: in integer);
	private
		pragma Priority(System.Priority'Last);
		
		current_event_id: integer;
		Signalled: boolean := False;
	end Event;

	task EventdispatcherTask is
		pragma Storage_Size(4096);
	end EventdispatcherTask;

	task MotorcontrolTask is
		pragma Priority(System.Priority'Last - 2);
		pragma Storage_Size(4096);
	end MotorcontrolTask;

	procedure background;
end Part_2;

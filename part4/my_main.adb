with part_4;
with System;

procedure my_main is
	pragma Priority(System.Priority'First);
begin
	part_4.Background;
end my_main;

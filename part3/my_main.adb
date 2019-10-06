with part_3;
with System;

procedure my_main is
	pragma Priority(System.Priority'First);
begin
	part_3.Background;
end my_main;

with part_2;
with System;

procedure my_main is
	pragma Priority(System.Priority'First);
begin
	part_2.Background;
end my_main;

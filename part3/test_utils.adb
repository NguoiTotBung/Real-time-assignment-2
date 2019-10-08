------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                        Copyright (C) 2011, AdaCore                       --
--                                                                          --
-- This is free software; you can  redistribute it  and/or modify it under  --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. This is distributed in the hope that it will be useful, but WITH-  --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Real_Time;     use Ada.Real_Time;
with NXT.AVR;
with NXT.Display;       use NXT.Display;

use NXT;

package body Test_Utils is

   ------------------------
   -- Await_Button_Press --
   ------------------------

   procedure Await_Button_Press
      (Prompt   : String := "Press a button";
       Print_CR : Boolean := True)
   is
   begin
      Put (Prompt);
      if Print_CR then
         New_Line;
      end if;
      --  make sure no button is currently (still) pressed
      loop
         exit when NXT.AVR.Button = No_Button;
         delay until Clock + Milliseconds (10);
      end loop;
      --  wait for a new button press
      loop
         exit when NXT.AVR.Button /= No_Button;
         delay until Clock + Milliseconds (10);
      end loop;
      --  wait for pressed button to be released
      loop
         exit when NXT.AVR.Button = No_Button;
         delay until Clock + Milliseconds (10);
      end loop;
   end Await_Button_Press;

end Test_Utils;

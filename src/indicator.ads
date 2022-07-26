--
--  Copyright (C) 2022 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with RP.Timer;
with RP.GPIO;
private with RP.PWM;

package Indicator is

   subtype Milliseconds is Natural;
   type Percent is delta 0.001 range -100.0 .. 100.0;

   type Light
      (LED : not null access RP.GPIO.GPIO_Point)
   is tagged private;

   procedure Initialize
      (This : in out Light);

   procedure Fade_To
      (This       : in out Light;
       Brightness : Percent := 50.0;
       Duration   : Milliseconds := 1_000)
   with Pre => Brightness >= 0.0;

   procedure Update
      (This : in out Light);

   function Next_Update
      (This : Light)
      return RP.Timer.Time;

   function Fade_Complete
      (This : Light)
      return Boolean;

private

   type Light
      (LED : not null access RP.GPIO.GPIO_Point)
   is tagged record
      P : RP.PWM.PWM_Point;
      Target      : Percent;
      Current     : Percent;
      Increment   : Percent;
      Next        : RP.Timer.Time;
   end record;

   function To_Duty_Cycle
      (Brightness : Percent)
      return RP.PWM.Period;

end Indicator;

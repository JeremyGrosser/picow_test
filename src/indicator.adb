--
--  Copyright (C) 2022 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with RP.Timer; use RP.Timer;
with RP.ROM.Floating_Point;

package body Indicator is
   use type RP.PWM.Period;

   PWM_Frequency   : constant := 65_635_000;
   Max_Duty_Cycle  : constant RP.PWM.Period := RP.PWM.Period'Last - 1;
   Update_Interval : constant RP.Timer.Time := RP.Timer.Milliseconds (1);

   procedure Initialize
      (This : in out Light)
   is
      use RP.PWM;
   begin
      This.LED.all.Configure (RP.GPIO.Output, RP.GPIO.Floating, RP.GPIO.PWM);
      This.P := To_PWM (This.LED.all);
      RP.PWM.Initialize;
      Set_Mode (This.P.Slice, Free_Running);
      Set_Frequency (This.P.Slice, PWM_Frequency);
      Set_Interval (This.P.Slice, Max_Duty_Cycle);
      Set_Duty_Cycle (This.P.Slice, This.P.Channel, 0);
      This.Current := 0.0;
      This.Target := 0.0;
      This.Next := RP.Timer.Time'Last;
      Enable (This.P.Slice);
   end Initialize;

   function To_Duty_Cycle
      (Brightness : Percent)
      return RP.PWM.Period
   is
      function powf
         (X, Y : Float)
         return Float
      is
         --  Based on sdcc/device/lib/powf.c
         --  Not very accurate, but good enough for gamma curves.
         use RP.ROM.Floating_Point;
      begin
         if Y = 0.0 then
            return 1.0;
         elsif Y = 1.0 then
            return X;
         elsif X <= 0.0 then
            return 0.0;
         else
            return fexp (fln (X) * Y);
         end if;
      end powf;

      Gamma : constant := 1.8;
      X : Float;
   begin
      X := Float (Brightness) / Float (Percent'Last);
      X := powf (X, Gamma);
      X := X * Float (Max_Duty_Cycle);
      X := X + 0.5;
      return RP.PWM.Period (X);
   end To_Duty_Cycle;

   procedure Fade_To
      (This       : in out Light;
       Brightness : Percent := 50.0;
       Duration   : Milliseconds := 1_000)
   is
   begin
      This.Next := Clock;
      This.Target := Brightness;

      if Duration = 0 then
         This.Increment := This.Target - This.Current;
      else
         declare
            Num_Steps : constant Float := Float (RP.Timer.Milliseconds (Duration) / Update_Interval);
         begin
            This.Increment := Percent (Float (This.Target - This.Current) / Num_Steps);
         end;
      end if;
   end Fade_To;

   procedure Update
      (This : in out Light)
   is
      Distance : constant Percent := This.Target - This.Current;
   begin
      if not This.Fade_Complete and then Clock >= This.Next then
         if abs Distance <= abs This.Increment then
            This.Current := This.Target;
            This.Increment := 0.0;
            This.Next := RP.Timer.Time'Last;
         else
            This.Current := This.Current + This.Increment;
            This.Next := This.Next + Update_Interval;
         end if;
         RP.PWM.Set_Duty_Cycle (This.P.Slice, This.P.Channel, To_Duty_Cycle (This.Current));
      end if;
   end Update;

   function Next_Update (This : Light) return RP.Timer.Time
   is (This.Next);

   function Fade_Complete (This : Light) return Boolean
   is (This.Current = This.Target);

end Indicator;

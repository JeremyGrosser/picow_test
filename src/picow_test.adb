--
--  Copyright (C) 2022 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with RP.Device;
with RP.Clock;
with RP.GPIO;
with Pico_W;
with Indicator;

procedure Picow_Test is
   LED      : aliased RP.GPIO.GPIO_Point := (Pin => 15);
   Light    : Indicator.Light (LED => LED'Access);
   On       : Boolean := False;
begin
   RP.Clock.Initialize (Pico_W.XOSC_Frequency, Pico_W.XOSC_Startup_Delay);
   RP.Device.Timer.Enable;
   Pico_W.WLAN.Initialize;

   loop
      Light.Update;
      if Light.Fade_Complete then
         On := not On;
         Light.Fade_To
            (Brightness => (if On then 0.0 else 100.0),
             Duration   => 1_000);
      else
         RP.Device.Timer.Delay_Until (Light.Next_Update);
      end if;
   end loop;
end Picow_Test;

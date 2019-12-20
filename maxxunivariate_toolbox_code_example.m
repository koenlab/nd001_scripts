GND=erplab2GND('gui','exclude_chans',{'FT9','FT10','TP9','TP10'});
headinfo(GND);

GND=bin_dif(GND,22,21,'AC-AB');
GND=bin_dif(GND,11,12,'DE Hit-Miss');
GND=bin_dif(GND,17,18,'AB_AB Hit-Miss');
GND=bin_dif(GND,19,20,'AC_AC Hit-Miss');
GND=bin_dif(GND,24,25,'AB_AC Hit-Miss');
GND=bin_dif(GND,26,27,'AC_AB Hit-Miss');
headinfo(GND);

GND=clustGND(GND,28,'time_wind',[300 1000],'chan_hood',.61,'thresh_p',.05);
GND=clustGND(GND,29,'time_wind',[1000 1500],'chan_hood',.61,'thresh_p',.05);
GND=clustGND(GND,33,'time_wind',[1000 1500],'chan_hood',.61,'thresh_p',.05);

GND=clustGND(GND,30,'time_wind',[300 900],'chan_hood',.61,'thresh_p',.05);

GND=tmaxGND(GND,33,'time_wind',[400 1000]);
GND=tmaxGND(GND,33,'time_wind',[1000 1500]);
GND=tmaxGND(GND,33,'time_wind',[400 600]);
GND=tfdrGND(GND,33,'method','by','time_wind',[1000 1500]);



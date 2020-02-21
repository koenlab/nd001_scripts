GND=erplab2GND('gui','exclude_chans',{'FT9' 'FT10' 'TP9' 'TP10'},'bsln',[-200 0], ...
    'verblevel',3);
headinfo(GND);

GND=bin_dif(GND,7,8,'DE Hit-Miss');
GND=tmaxGND(GND,21,'time_wind',[300 1500],'time_block_dur',300,'mean_wind','yes');
GND=tfdrGND(GND,21,'method','bh','time_wind',[300 1500],'time_block_dur',300,'mean_wind','yes');

GND=clustGND(GND,16,'time_wind',[300 500],'chan_hood',.61,'thresh_p',.05, ...
    'mean_wind','yes','include_chans',{'Fp1' 'Fp2' 'AF3' 'AF4' 'AFz'});

GND=clustGND(GND,29,'time_wind',[1000 1500],'chan_hood',.61,'thresh_p',.05);
GND=clustGND(GND,33,'time_wind',[1000 1500],'chan_hood',.61,'thresh_p',.05);

GND=clustGND(GND,30,'time_wind',[300 900],'chan_hood',.61,'thresh_p',.05);

GND=tmaxGND(GND,33,'time_wind',[400 1000]);
GND=tmaxGND(GND,33,'time_wind',[1000 1500]);
GND=tmaxGND(GND,33,'time_wind',[400 600]);
GND=tfdrGND(GND,33,'method','by','time_wind',[1000 1500]);



t1 = lines get "seb1.st";
t1 = apply(t1, s->separateRegexp(" ",s));
--t1 = apply(t1, l->l/value);
--t1 = matrix apply(t1, l->apply(l, e->sub(e, ZZ/2)));
ts1 = {"index"=>{},"matrix"=>t1,"name"=>"wt1"};


t2 = lines get "seb2.st";
t2 = apply(t2, s->separateRegexp(" ",s));
--t2 = apply(t2, l->l/value);
--t2 = matrix apply(t2, l->apply(l, e->sub(e, ZZ/2)));

TS = {"input"=>{"timeSeriesData"=>{ts1,ts2},"type"=>"timeSeries"}}


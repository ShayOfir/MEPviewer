function IOcurve_params = get_IOcurve_params(subject, repetition)
    fn = ['results/' subject '/' repetition '_IOcurve_params.csv'];
    if exist(fn,'file')
        IOcurve_params = readtable(fn);
    else
        IOcurve_params = create_default_IOcurve_params;
    end
end

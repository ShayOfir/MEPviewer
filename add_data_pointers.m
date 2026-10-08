function result = add_data_pointers (x_datastart, x_dataend, y_datastart, y_dataend)
    datastart = x_datastart;
    dataend = x_dataend;
    last_dataend = dataend(end,end);
    y_datastart1 = y_datastart + last_dataend;
    y_dataend1 = y_dataend + last_dataend;
    datastart = [datastart, y_datastart1];
    dataend = [dataend, y_dataend1];
    result = {datastart, dataend};
end
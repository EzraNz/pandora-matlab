function gmax_obj = param_gmax(param_init_val, id, props)
gmax_obj = ...
    param_func({'conductance [nS]', 'conductance [nS]'}, ...
                    param_init_val, {'gmax'}, @(p, x) [p(1)], id, ...
                    props);
end
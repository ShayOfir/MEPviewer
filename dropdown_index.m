function pos = dropdown_index (dropdown)
            pos = 1;
            while (~strcmp(dropdown.Items{pos}, dropdown.Value))
                pos = pos + 1;
            end
            if pos > length(dropdown.Items)
                pos = 0;
                warning('Item not found in dropdown menu')
            end
end
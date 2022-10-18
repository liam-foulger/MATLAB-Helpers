function datatip_z2cdata(h)
    % h is a graphics object with a default X/Y/Z datatip and a 
    % CData property (e.g. pcolor).  The Z portion of the datatip
    % will be relaced with CData
    % Generate an invisible datatip to ensure that DataTipTemplate is generated
    dt = datatip(h,h.XData(1),h.YData(1),'Visible','off'); 
    % Replace datatip row labeled Z with CData
    idx = strcmpi('Z',{h.DataTipTemplate.DataTipRows.Label});
    newrow = dataTipTextRow('C',h.CData);
    h.DataTipTemplate.DataTipRows(idx) = newrow;
    % Remove invisible datatip
    delete(dt)
end
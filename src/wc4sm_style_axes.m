function wc4sm_style_axes(a,C)
%WC4SM_STYLE_AXES Apply the shared WCC4SM axes appearance (white background,
% muted axis color, light grid). C is the palette from WC4SM_COLORS.
%   Built-in mouse interactivity (scroll-zoom/pan/datatips and the hover
% toolbar) is disabled: zooming is provided by explicit controls, and stray
% mouse zoom used to leave axes stuck in a hard-to-restore manual-limits
% state. ButtonDownFcn callbacks are unaffected.

    a.Color='white';a.XColor=C.muted;a.YColor=C.muted;a.GridColor=[.86 .89 .92];a.Box='on';
    disableDefaultInteractivity(a);
    a.Toolbar.Visible='off';
end

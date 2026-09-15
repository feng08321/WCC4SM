function wc4sm_style_axes(a,C)
%WC4SM_STYLE_AXES Apply the shared WCC4SM axes appearance (white background,
% muted axis color, light grid). C is the palette from WC4SM_COLORS.

    a.Color='white';a.XColor=C.muted;a.YColor=C.muted;a.GridColor=[.86 .89 .92];a.Box='on';
end

function q = wc4sm_section_label(g,t)
%WC4SM_SECTION_LABEL Bold navy section header spanning both grid columns.

    q=uilabel(g,'Text',t,'FontWeight','bold','FontColor',[.07 .28 .46]);q.Layout.Column=[1 2];
end

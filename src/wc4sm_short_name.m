function s = wc4sm_short_name(p)
%WC4SM_SHORT_NAME File name with extension, or '' for an empty path.

    if isempty(p),s='';else,[~,n,e]=fileparts(p);s=[n e];end
end

function fig = wc4sm_plot_optimization_diagnostics(orderResult,addOneResult)
%WC4SM_PLOT_OPTIMIZATION_DIAGNOSTICS Plot model-order and Add-One histories.
    fig=figure('Name','WCC4SM calibration optimization diagnostics','Color','w');
    tl=tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');
    nexttile(tl);d=[orderResult.Degree];hold on;semilogy(d,[orderResult.FitRMSE],'-o','DisplayName','Fit RMSE');semilogy(d,[orderResult.LOORMSE],'-s','DisplayName','LOO RMSE');semilogy(d,[orderResult.ValidationRMSE],'-^','DisplayName','Validation RMSE');grid on;xlabel('Polynomial degree');ylabel('RMSE (nm)');title('Model order scan | logarithmic Y axis');legend('Location','best');
    nexttile(tl);if ~isempty(addOneResult),g=[addOneResult.Gain];bar(1:numel(g),g);xlabel('Candidate index');ylabel('Validation RMSE gain (nm)');title('Sequential Add-One gain');grid on;else,title('Sequential Add-One gain');axis off;end
end

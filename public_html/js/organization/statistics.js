/***************
 * Organization Statistics Panel
 */
AIR2.Organization.Statistics = function () {
    return new AIR2.UI.Panel({
        colspan: 2,
        title: 'Statistics',
        showTotal: true,
        iconCls: 'air2-icon-stats',
        itemSelector: '.air2-organization-stats-row',
        html: '<br/> <br/> <br/> <br/> <br/>'
    });
};

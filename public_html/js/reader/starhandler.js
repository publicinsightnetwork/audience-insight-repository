/***************
 * Mark things as favorite/unfavorite as stars are clicked
 */
AIR2.Reader.starHandler = function (dv) {

    // handle row clicks
    dv.on('click', function (dv, index, node, e) {
        var el, rec;

        if (e.getTarget('.mark-fav')) {
            e.preventDefault();

            el  = e.getTarget('.mark-fav', 5, true);
            rec = dv.getRecord(node);

            // add or remove favorite
            if (rec.data.live_favorite) {
                rec.data.live_favorite = false;
                el.removeClass('fav');
                el.set({title: 'Mark as Insightful'});

                Ext.Ajax.request({
                    url: AIR2.HOMEURL + '/reader/unfavorite/' +
                        rec.data.srs_uuid + '.json',
                    failure: function () {
                        rec.data.live_favorite = true;
                        el.addClass('fav');
                        el.set({title: 'Insightful'});
                    }
                });
            }
            else {
                rec.data.live_favorite = true;
                el.addClass('fav');
                el.set({title: 'Insightful'});

                Ext.Ajax.request({
                    url: AIR2.HOMEURL + '/reader/favorite/' +
                        rec.data.srs_uuid + '.json',
                    failure: function () {
                        rec.data.live_favorite = false;
                        el.removeClass('fav');
                        el.set({title: 'Mark as Insightful'});
                    }
                });
            }
        }
    });


};

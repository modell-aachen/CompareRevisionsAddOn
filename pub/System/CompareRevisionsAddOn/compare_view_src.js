jQuery(function() {
    /*
     * Twisties often have their controls in a different parent node and thus
     * do not get marked when there is a change in them. So when the twisty is
     * closed you do not note the change.
     * Adding a craInterweaveDiff to the controls unless they are already marked.
     */

    var markTwistyControls = function() {
        var id = $(this).attr('id').replace(/toggle$/, '');
        var $twisty = $('[id^="' + id + '"]:not(.craTwistyDiff)')
        $twisty.addClass('craTwistyDiff').children('a').append(' <span class"craTwistyNote">' + jsi18n.get('compare', '(section contains changes)') + '</span>');
    };

    var $nested = $('.twistyContent > [class^="craCompare"]');
    $nested.closest('.twistyContent').each(markTwistyControls);

    $('.twistyContent').filter('[class^="craCompare"]').each(markTwistyControls);
});

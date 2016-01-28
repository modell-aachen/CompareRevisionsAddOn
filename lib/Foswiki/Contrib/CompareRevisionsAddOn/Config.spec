# ---+ Extensions
# ---++ CompareRevisionsAddOn
# **PERL H**
# This setting is required to enable executing the compare script from the bin directory
$Foswiki::cfg{SwitchBoard}{compare} = {
    package  => 'Foswiki::Contrib::CompareRevisionsAddOn::Compare',
    function => 'compare',
    context  => { diff => 1,
                  comparing => 1
                },
    };
# **STRING**
# Define the skin to render the topic contents.
$Foswiki::cfg{Extensions}{CompareRevisionsAddOn}{skin} = 'classic';

# **PERL**
# Link to placeholder image. Set to empty string, if you want no placeholder image.
$Foswiki::cfg{Extensions}{CompareRevisionsAddOn}{placeholders} = {
    '\.(?:(?i)img|jpe?g|png|bmp|svg)$' => '%PUBURLPATH%/%SYSTEMWEB%/CompareRevisionsAddOn/Keep_tidy_ask%IF{"$LANGUAGE=\'de\'" then="_de" else="_en"}%.svg'
};

1;

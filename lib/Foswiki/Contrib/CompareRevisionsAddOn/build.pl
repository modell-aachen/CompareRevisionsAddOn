#!/usr/bin/perl -w
#
# Build for CompareRevisionsAddOn
#
BEGIN {
  foreach my $pc (split(/:/, $ENV{FOSWIKI_LIBS})) {
    unshift @INC, $pc;
  }
}

use Foswiki::Contrib::Build;

# Create the build object
$build = new Foswiki::Contrib::Build( 'CompareRevisionsAddOn' );

# name of web to upload to
$build->{UPLOADTARGETWEB} = 'Extensions';
# Full URL of pub directory
$build->{UPLOADTARGETPUB} = 'http://extensions.open-quality.com/pub';
# Full URL of bin directory
$build->{UPLOADTARGETSCRIPT} = 'http://extensions.open-quality.com/bin';
# Script extension
$build->{UPLOADTARGETSUFFIX} = '';

# Build the target on the command line, or the default target
$build->build($build->{target});


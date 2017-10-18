# See bottom of file for license and copyright information
use strict;
use warnings;

package CompareRevisionsAddOnTests;

use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use strict;
use warnings;

use Foswiki();
use Error qw ( :try );
use Foswiki::Contrib::CompareRevisionsAddOn::Compare();

use Test::MockModule;

my $mocks; # mocks will be stored in a package variable, so we can unmock them reliably when the test finished
my $mockTopicRefs;

my $completePage; # when writeCompletePage is called, it will store the page here
my $query;

# Mock topics will have the following structure:
# $mockTopics->{
#     "$web.$topic" => [
#         [date, creator, rev, comment, text], # this is the first rev
#         [date, creator, rev, comment, text], # second rev
#         ...
#      ]
# }
my $webTopic = "TestWeb.TestTopic";
my $webTopicExternal = "TestWeb.TestTopicExternal";
my $mockTopics = {};
$mockTopics->{$webTopicExternal} = [];
$mockTopics->{$webTopicExternal}->[1] = [1000, 'admin', 1, 'Person one', <<TML];
I like singing.
TML
$mockTopics->{$webTopicExternal}->[2] = [2000, 'admin', 2, 'Person two', <<TML];
I like dancing.
TML
$mockTopics->{$webTopicExternal}->[3] = [3000, 'admin', 3, 'Person three', <<TML];
I like trains.
TML

$mockTopics->{$webTopic} = [];
$mockTopics->{$webTopic}->[1] = [1000, 'admin', 1, 'Person one', <<TML];
I like singing.
TML
$mockTopics->{$webTopic}->[2] = [2000, 'admin', 2, 'Person two', <<TML];
I like dancing.
TML
$mockTopics->{$webTopic}->[3] = [3000, 'admin', 3, 'Person three', <<TML];
I like trains.
TML
$mockTopics->{$webTopic}->[4] = [4000, 'guest', 4, 'Person four', <<TML];
Nononono!
TML
$mockTopics->{$webTopic}->[5] = [5000, 'guest', 5, 'Train', <<TML];
Wootwoot.
TML

sub set_up {
    my $this = shift;

    $this->SUPER::set_up();

    $this->set_up_mocks();
}

sub set_up_mocks {
    my $this = shift;

    $mocks = {};
    foreach my $module (qw(
        Foswiki::Contrib::CompareRevisionsAddOn::Compare
    )) {
        $mocks->{$module} = Test::MockModule->new($module);
    }
}


sub tear_down {
    my $this = shift;

    foreach my $module (keys %$mocks) {
        $mocks->{$module}->unmock_all();
    }

    $this->SUPER::tear_down();
}

# Test if...
# ... it is possible to pass malicious code via the context parameter
# ... only numbers are allowed as context parameter
sub test_paramContextXss {
    my ( $this ) = @_;

    my $cliParams = { topic => "$this->{test_web}.$this->{test_topic}", action => 'compare', context => "evil-xss\"1" };
    $query = Unit::Request->new( $cliParams );

    my $session = $this->createNewFoswikiSession('admin', $query);

    my $revisions = Foswiki::Contrib::CompareRevisionsAddOn::Compare::_generateRevisions($query, 3, 2, 1);

    $this->assert($revisions !~ m#evil|xss#, "evil context-parameter has not been scrubbed");
    $this->assert($revisions =~ m#render=-1#, "context-parameter missing");
}

# Test if...
# ... it is possible to pass malicious code via the render parameter
sub test_paramRenderXss {
    my ( $this ) = @_;

    my $cliParams = { topic => "$this->{test_web}.$this->{test_topic}", action => 'compare', render => "evil\"xss" };
    $query = Unit::Request->new( $cliParams );

    my $session = $this->createNewFoswikiSession('admin', $query);

    my $revisions = Foswiki::Contrib::CompareRevisionsAddOn::Compare::_generateRevisions($query, 3, 2, 1);

    $this->assert($revisions !~ m#evil"#, "evil context-parameter has not been scrubbed");
    $this->assert($revisions =~ m#render=evilxss#, "evil skin-parameter has not been scrubbed or is missing");
}

# Test if...
# ... it is possible to pass malicious code via the skin parameter
sub test_paramSkinXss {
    my ( $this ) = @_;

    my $cliParams = { topic => "$this->{test_web}.$this->{test_topic}", action => 'compare', skin => "evil\"xss" };
    $query = Unit::Request->new( $cliParams );

    my $session = $this->createNewFoswikiSession('admin', $query);

    my $revisions = Foswiki::Contrib::CompareRevisionsAddOn::Compare::_generateRevisions($query, 3, 2, 1);

    $this->assert($revisions !~ m#evil"#, "evil context-parameter has not been scrubbed");
    $this->assert($revisions =~ m#skin=evilxss#, "evil skin-parameter has not been scrubbed or is missing");
}

# Test if...
# ... the rev2 parameter is ignored when 'external' was used
sub test_paramExternalRev2 {
    my ( $this ) = @_;

    my $cliParams = { topic => "$this->{test_web}.$this->{test_topic}", action => 'compare', external => "Test" };
    $query = Unit::Request->new( $cliParams );

    my $session = $this->createNewFoswikiSession('admin', $query);

    my $revisions = Foswiki::Contrib::CompareRevisionsAddOn::Compare::_generateRevisions($query, 10, 8, 9);

    my $numCompares = () = $revisions =~ m#%SCRIPTURLPATH{compare}%#g;
    $this->assert($numCompares == 3, "with external parameters, it should have generated 3 compare links");

    $query->delete('external');

    $revisions = Foswiki::Contrib::CompareRevisionsAddOn::Compare::_generateRevisions($query, 10, 8, 9);

    $numCompares = () = $revisions =~ m#%SCRIPTURLPATH{compare}%#g;
    $this->assert($numCompares == 2, "with external parameters, it should have generated 2 compare links and one text node '<'");
}

# Test if...
# ... the user can not compare topics, he has no VIEW access to
sub test_checkAclsCurrentTopicDenied {
    my ( $this ) = @_;

    my $topic = 'SecretTopic';

    my ($meta, $text) = Foswiki::Func::readTopic($this->{test_web}, $topic);
    $meta->text("   * Set ALLOWTOPICVIEW = AdminGroup");
    $meta->saveAs();

    my $cliParams = { topic => "$this->{test_web}.$topic", action => 'compare' };
    $query = Unit::Request->new( $cliParams );
    my $session = $this->createNewFoswikiSession($this->{test_user_login}, $query);

    try {
        my $UI_FN = $this->getUIFn('compare');
        my ($response) = $this->capture( $UI_FN, $this->{session} );

        $this->assert(0, "Test user $this->{test_user_login} was able to compare secret topic.");
    } catch Foswiki::AccessControlException with {
    };
}

# Test if...
# ... the user can NOT compare topics, he has no VIEW access to in a specific revision
# ... the user CAN compare revs, where the restrictions have been lifted
sub test_checkAclsCurrentTopicRev {
    my ( $this ) = @_;

    my $topic = 'SecretTopic';

    my ($meta) = Foswiki::Func::readTopic($this->{test_web}, $topic);
    $meta->text("   * Set ALLOWTOPICVIEW = AdminGroup");
    $meta->saveAs($meta->web, $meta->topic, forcenewrevision => 1);
    $meta->text("No acls");
    $meta->saveAs($meta->web, $meta->topic, forcenewrevision => 1);
    $meta->text("Still no acls");
    $meta->saveAs($meta->web, $meta->topic, forcenewrevision => 1);

    # comparing the latest revs should be allowed

    my $cliParams = { topic => "$this->{test_web}.$topic", action => 'compare', rev1 => 2, rev2 => 3 };
    $query = Unit::Request->new( $cliParams );
    my $session = $this->createNewFoswikiSession($this->{test_user_login}, $query);

    try {
        my $UI_FN = $this->getUIFn('compare');
        my ($response) = $this->capture( $UI_FN, $this->{session} );
    } catch Foswiki::AccessControlException with {
        $this->assert(0, "Test user $this->{test_user_login} was NOT able to compare secret topic revs he was granted access to.");
    };

    # comparing with the first rev should NOT be allowed

    $cliParams = { topic => "$this->{test_web}.$topic", action => 'compare', rev1 => 1, rev2 => 2 };
    $query = Unit::Request->new( $cliParams );
    $session = $this->createNewFoswikiSession($this->{test_user_login}, $query);

    try {
        my $UI_FN = $this->getUIFn('compare');
        my ($response) = $this->capture( $UI_FN, $this->{session} );

        $this->assert(0, "Test user $this->{test_user_login} was able to compare secret rev of secret topic.");
    } catch Foswiki::AccessControlException with {
    };
}

# Test if...
# ... the user can compare the topic, if he has VIEW access to it
sub test_checkAclsCurrentTopicAllowed {
    my ( $this ) = @_;

    my $topic = 'SecretTopic';

    my ($meta, $text) = Foswiki::Func::readTopic($this->{test_web}, $topic);
    $meta->text("   * Set ALLOWTOPICVIEW = $this->{test_user_login}");
    $meta->saveAs();

    my $cliParams = { topic => "$this->{test_web}.$topic", action => 'compare' };
    $query = Unit::Request->new( $cliParams );
    my $session = $this->createNewFoswikiSession($this->{test_user_login}, $query);

    try {
        my $UI_FN = $this->getUIFn('compare');
        my ($response) = $this->capture( $UI_FN, $this->{session} );
    } catch Foswiki::AccessControlException with {
        $this->assert(0, "Test user $this->{test_user_login} was NOT able to compare secret topic he was granted access to.");
    };
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Author: Modell Aachen GmbH

Copyright (C) 2008-2011 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.

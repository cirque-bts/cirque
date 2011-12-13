package Cirque;
use vars qw/ $VERSION /;
$VERSION = 0.01;

=head1 DESCRIPTION

Cirque is a Issue Tracking System and a Continuous Integration System, all in one bach.

=head1 INSTALLATION

First, you have to clone cirque from repository.

    $ git clone git://github.com/cirque-bts/cirque.git

And, create a mysql database for cirque.

    $ mysqladmin create cirque

Next, create tables, triggers, and procedures into cirque database.

    $ cd cirque
    $ mysql cirque -u root < misc/cirque.sql

Finally, modify etc/config.pl for your environment.

=head1 START UP CIRQUE

Following command in cirque source directory for startup.

    $ bin/cirqued

Afterwards, you can access to http://your-host:5000/ .


=head1 WANT TO WORK IT ON DOTCLOUD?

If you think so, you can use another Cirque distribution - it's cirque-on-cloud.

Check cirque-on-cloud at https://github.com/cirque-bts/cirque-on-cloud

=head1 SEE ALSO

http://cirque-bts.github.com/

=cut

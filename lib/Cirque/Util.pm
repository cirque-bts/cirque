package Cirque::Util;
use strict;
use utf8;
use feature 'state';
use parent qw(Exporter);
use Cwd ();
use Data::Dumper ();
use Data::UUID;
use File::Spec;
use Time::HiRes();
use Scope::Guard ();
use String::Urandom;

our @EXPORT_OK = qw(
    random_ascii_string
    random_utf8_string
    random_uuid
);

my @ascii = ('a'..'z', 'A'..'Z',0..9, '-', '_');
my @utf8chars = map { split // } split /\n/, <<EOM;
かんじざいぼさつぎょうじんはんにゃはらみったじしょうけんごうんかいくう
観自在菩薩行深般若波羅蜜多時照見五蘊皆空
どいっさいくやくしゃりししきふいくうくうふいしきしきそくぜくう
度一切苦厄舎利子色不異空空不異色色即是空
くうそくぜしきじゅそうぎょうしきやくぶにょぜしゃりしぜしょほうくうそう
空即是色受想行識亦復如是舎利子是諸法空相
ふしょうふめつふくふじょうふぞうふげんぜこくうちゅう
不生不滅不垢不浄不増不減是故空中
むしきむじゅそうぎょうしきむげんにびぜっしんいむしきしょうこうみそくほう
無色無受想行識無眼耳鼻舌身意無色声香味触法
むげんかいないしむいしきかいむむみょうやくむむみょうじん
無眼界乃至無意識界無無明亦無無明尽
ないしむろうしやくむろうしじんむくしゅうめつどうむちやくむとく
乃至無老死亦無老死尽無苦集滅道無智亦無得
いむしょとくこぼだいさつたえはんにゃはらみったこ
以無所得故菩提薩埵依般若波羅蜜多故
しんむけいげむけいげこむうくふおんりいっさいてんどうむそう
心無罣礙無罣礙故無有恐怖遠離一切顛倒夢想
くうぎょうねはんさんぜしょぶつえはんにゃはらみったこ
究竟涅槃三世諸仏依般若波羅蜜多故
とくあのくたらさんみゃくさんぼだいこちはんにゃはらみった
得阿耨多羅三藐三菩提故知般若波羅蜜多
ぜだいじんしゅぜだいみょうしゅぜむじょうしゅぜむとうどうしゅ
是大神呪是大明呪是無上呪是無等等呪
のうじょいっさいくしんじつふここせつはんにゃはらみったしゅ
能除一切苦真実不虚故説般若波羅蜜多呪
そくせつしゅわっぎゃていぎゃていはらぎゃていはらそうぎゃてい
即説呪日羯諦羯諦波羅羯諦波羅僧羯諦
ぼじそわかはんにゃしんぎょう
菩提薩婆訶般若心経
EOM

sub random_ascii_string($) {
    my $length = shift || 32;
    state $generator = String::Urandom->new(
        LENGTH => $length,
        CHARS  => [ @ascii ]
    );
    return $generator->rand_string;
}
sub random_utf8_string($) {
    my $length = shift || 32;
    state $generator = String::Urandom->new(
        LENGTH => $length,
        CHARS  => [ @ascii, @utf8chars ]
    );
    return $generator->rand_string;
}

sub merge_hashes {
    my ($left, $right) = @_;
    return { %$left, %$right };
}               
        
sub applyenv {
    my ($file) = @_;
    
    my $env = $ENV{DEPLOY_ENV};
    if (! $env ) {
        return ($file);
    }
    
    my $x_file = $file;    $x_file =~ s/\.([^\.]+)$/_$env.$1/;
    return ($file, $x_file);
}

my $UUID = Data::UUID->new;
sub random_uuid {
    $UUID->create_from_name_str( 'Cirque', join '.',
        Data::Dumper::Dumper( \@_ ),
        Time::HiRes::time(),
        {},
        rand(),
        $$
    );
}

1;

__END__

=head1 NAME

Cirque::Util

=head1 SYNOPSIS

    use Cirque::Util;

=head1 FUNCTIONS

=head2 random_ascii_string

=head2 random_utf8_string

=head2 random_uuid

=cut
1;

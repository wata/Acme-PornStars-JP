package Acme::PornStars::JP;
use strict;
use warnings;
our $VERSION = '0.01';
use utf8;
use Lingua::JA::Moji qw/kana2romaji/;
use URI;
use XML::Simple;
use Coro;
use Coro::Select;
use Furl::HTTP;
use Cache::FileCache;

sub new {
    my $class = shift;
    my $opt   = @_;
    my $cache = Cache::FileCache->new($opt || {
        cache_root         => '/tmp',
        namespace          => 'Acme-PornStars-JP',
        default_expires_in => '7d',
    });
    bless { cache => $cache }, $class;
}

sub get {
    my $self = shift;
    my $cache = $self->{cache};

    my $ret;
    unless ( $ret = $cache->get('pornstars') ) {
        my @coros;
        foreach my $i ( qw/ あ か さ た な は ま や ら・わ / ) {
            push @coros, async {
                return _initial_get->($i);
            };
        }
        my @pornstars;
        foreach my $coro (@coros) {
            my $pornstars = $coro->join;
            next unless $pornstars;
            push @pornstars, @{ $pornstars };
        }

        my $ret = \@pornstars;
        $cache->set('pornstars', $ret);
        $self->{pornstars} = $ret;
    }

    return $ret;
}

sub _initial_get {
    my $initial = shift;
    my $url = URI->new('http://ja.wikipedia.org/wiki/特別:データ書き出し/AV女優一覧_' . $initial . '行');

    my $furl = Furl::HTTP->new( agent => 'Mozilla/5.0' );
    my (undef, $code, undef, undef, $body) = $furl->get($url);
    die $code unless $code eq 200;

    my $content = XMLin($body)->{page}{revision}{text}{content};
    my @pornstars;
    foreach my $line ( split( /\n/, $content ) ) {
        next unless $line =~ /^\*\s\[\[/;
        if ( $line =~ /\[\[([^\[\]]+)\]\][（(]([^()（）]+)[)）](.*)/ ) {
            my ( $star_info, $tmp ) = ( { name => $1, yomi => $2 }, $3 );
            $star_info->{name} =~ s/.*\|//;
            $star_info->{engname} =
                kana2romaji( $star_info->{yomi},
                    { style => 'passport', ve_type => 'none' } );
            $star_info->{year} =
                $tmp =~ /[（(](?:\[\[)?(\d{4})\s*年(?:\]\])?[)）]/ ? $1 : '';
            $star_info->{initial} = $initial;
            push @pornstars, $star_info;
        }
    }
    return \@pornstars;
}

sub year {
    my ( $self, $year ) = @_;
    my @tmp;
    foreach my $star ( @{ $self->{pornstars} } ) {
        push @tmp, $star if $star->{year} eq $year;
    }
    return \@tmp;
}

sub name {
    my ( $self, $name ) = @_;
    my @tmp;
    foreach my $star ( @{ $self->{pornstars} } ) {
        push @tmp, $star if $star->{name} eq $name;
    }
    return \@tmp;
}

sub yomi {
    my ( $self, $yomi ) = @_;
    my @tmp;
    foreach my $star ( @{ $self->{pornstars} } ) {
        my $y = $star->{yomi};
        $y =~ s/[ 　]+//g;
        $yomi =~ s/[ 　]+//g;
        push @tmp, $star if $y eq $yomi;
    }
    return \@tmp;
}

sub engname {
    my ( $self, $engname) = @_;
    my @tmp;
    foreach my $star ( @{ $self->{pornstars} } ) {
        push @tmp, $star if $star->{engname} eq $engname;
    }
    return \@tmp;
}

1;
__END__

=head1 NAME

Acme::PornStars::JP -

=head1 SYNOPSIS

  use Acme::PornStars::JP;
  use YAML;
  my $pornstars = Acme::PornStars::JP->new(
      {
          'cache_root'         => '/tmp',
          'namespace'          => 'hoge',
          'default_expires_in' => '30d',
      },
  );
  $pornstars->get;
  my $starlist = $pornstars->year('2000');
  print YAML::Dump($starlist);

=head1 DESCRIPTION

Acme::PornStars::JP is

=head1 AUTHOR

Wataru Nagasawa E<lt>nagasawa {at} junkapp.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

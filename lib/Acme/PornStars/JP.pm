package Acme::PornStars::JP;
use strict;
use warnings;
our $VERSION = '0.01';
use utf8;
use Lingua::JA::Moji qw/kana2romaji/;
use URI;
use XML::Simple;
use Furl::HTTP;
use Cache::FileCache;

sub new {
    my $class = shift;
    my $opt   = @_;
    my $cache = Cache::FileCache->new($opt || {
        cache_root         => '/tmp',
        namespace          => 'pornstars',
        default_expires_in => '7d',
    });
    bless { cache => $cache }, $class;
}

sub get {
    my ( $self, $initial ) = @_;
    my $url = URI->new('http://ja.wikipedia.org/wiki/特別:データ書き出し/AV女優一覧_' . $initial . '行');
    my $cache = $self->{cache};

    my $ret;
    unless ( $ret = $cache->get($url) ) {
        my $furl = Furl::HTTP->new( agent => 'Mozilla/5.0' );
        my (undef, $code, undef, undef, $body) = $furl->get($url);
        die $code unless $code eq 200;

        my $content = XMLin($body)->{page}{revision}{text}{content};
        my @actress;
        foreach my $line ( split( /\n/, $content ) ) {
            next unless $line =~ /^\*\s\[\[/;
            if ( $line =~ /\[\[([^\[\]]+)\]\][（(]([^()（）]+)[)）](.*)/ ) {
                my ( $actress_info, $tmp ) = ( { name => $1, yomi => $2 }, $3 );
                $actress_info->{name} =~ s/.*\|//;
                $actress_info->{engname} =
                    kana2romaji( $actress_info->{yomi},
                                 { style => 'passport', ve_type => 'none' } );
                $actress_info->{year} =
                    $tmp =~ /[（(](?:\[\[)?(\d{4})\s*年(?:\]\])?[)）]/ ? $1 : '';
                $actress_info->{initial} = $initial;
                push @actress, $actress_info;
            }
        }
        $cache->set($url, \@actress);
        $ret = \@actress;
    }
    $self->{actress} = $ret;
    return $ret;
}

sub year {
    my ( $self, $year ) = @_;
    my @temp;
    foreach my $actress ( @{ $self->{actress} } ) {
        push @temp, $actress if $actress->{year} eq $year;
    }
    return \@temp;
}

sub name {
    my ( $self, $name ) = @_;
    foreach my $actress ( @{ $self->{actress} } ) {
        return $actress if $actress->{name} eq $name;
    }
    return;
}

sub yomi {
    my ( $self, $yomi ) = @_;
    foreach my $actress ( @{ $self->{actress} } ) {
        my $y = $actress->{yomi};
        $y =~ s/[ 　]+//g;
        $yomi =~ s/[ 　]+//g;
        return $actress if $y eq $yomi;
    }
    return;
}

sub engname {
    my ( $self, $engname) = @_;
    foreach my $actress ( @{ $self->{actress} } ) {
        return $actress if $actress->{engname} eq $engname;
    }
    return;
}

1;
__END__

=head1 NAME

Acme::PornStars::JP -

=head1 SYNOPSIS

  use Acme::PornStars::JP;
  use utf8;
  use YAML;
  my $pornstars = Acme::PornStars::JP->new(
      {
          'cache_root'         => '/tmp',
          'namespace'          => 'hoge',
          'default_expires_in' => '30d',
      },
  );
  $pornstars->get('あ');
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

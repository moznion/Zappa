# CONFORMING TO Github API v3

package Zappa::Github;
use strict;
use warnings;

use JSON;
use Furl;
use URI;
use Carp;
use Try::Tiny;
use Class::Load ':all';

sub new {
  my ($class, %opts) = @_;

  $opts{base_uri} ||= 'https://api.github.com/';
  $opts{parser}   ||= 'JSON';
  $opts{agent}    ||= Furl->new(
    agent   => $class,
    timeout => 10,
  );
  return bless {%opts}, $class;
}

sub get {
  my ($self, $path) = @_;

  my $uri = URI->new($self->{base_uri});
  $uri->path($path);
  my $response = $self->{agent}->get($uri);
  Carp::croak(sprintf "%s(code:%s)", $response->content, $response->code) unless $response->is_success;

  return try {
    JSON->new->utf8->decode($response->content);
  } catch {
    Carp::croak(sprintf "%s(uri:%s)", $_, $uri->as_string);
  }
}

# Repos Data
sub fetch_repos_contents {
  my ($self, $user, $repos) = @_;

  my $response;
  if ($repos =~ /^(.*?)\/(.*)/) {
    $response = $self->get(sprintf "/repos/%s/%s/%s/%s", $user, $1, 'contents', $2);
  } else {
    $response = $self->get(sprintf "/repos/%s/%s/%s", $user, $repos, 'contents');
  }
  my %directory;
  foreach my $content (@$response) {
    my %content_info;
    $content_info{'name'}     = $content->{'name'};
    $content_info{'type'}     = $content->{'type'};
    $content_info{'location'} = $content->{'_links'}->{'self'};
    $directory{$content->{'path'}} = \%content_info;
  }

  return %directory;
}

# User Data
sub fetch_user_repos {
  my ($self, $user) = @_;

  my $response = $self->get(sprintf "/users/%s/repos", $user);
  my @sorted_repositories = reverse sort { $a->{'id'} <=> $b->{'id'} } @$response;
  return @sorted_repositories;
}

# File Data
sub fetch_file_contents {
  my ($self, $user_name, $repos_name, $file_path) = @_;

  my $response = $self->get("repos/$user_name/$repos_name/contents/$file_path");
  return %$response;
}

1;

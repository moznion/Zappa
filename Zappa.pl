#!/usr/bin/env perl

use 5.016;

use utf8;
use FindBin;
use lib ("$FindBin::Bin/lib");

use MIME::Base64;
use Mojolicious::Lite;
use Zappa::Github;

my $github = Zappa::Github->new;

get '/' => 'index';


# REPOS
get '/repos/:user' => sub {
  my $self = shift;
  $self->stash(github => $github);

  $self->render('repos_list');
};

get '/repos/:user/*repos' => sub {
  my $self = shift;
  $self->stash(github => $github);

  $self->render('repos_contents');
};

# LOG
get '/repos_log/:user/:repos' => sub {
  my $self = shift;
  $self->stash(github => $github);

  $self->render('repos_log');
};

get '/repos_log/:user/:repos/:sha' => sub {
  my $self = shift;
  $self->stash(github => $github);

  $self->render('detailed_commit_log');
};

# FILE
get '/file/:user/:repos/*path' => sub {
  my $self = shift;

  my %contents = $github->fetch_file_contents(
    $self->stash->{'user'},
    $self->stash->{'repos'},
    $self->stash->{'path'}
  );

  $self->stash->{'path'} =~ /^(?:.*)\/(.*\.(.*))$/;
  my $filename  = $1;
  my $file_type = $2;
  if ($file_type =~ /jpg|jpeg|gif|png/i) {
    $self->stash(image    => $contents{'content'});
    $self->stash(filename => $filename);
    if ($file_type =~ /jpg|jpeg/i) {
      $self->stash(image_type => 'jpeg');
    } else {
      $self->stash(image_type => $file_type);
    }
    $self->render('image');
  } else {
    $contents{'content'} = MIME::Base64::decode($contents{'content'});
    $contents{'content'} =~ s/\r?\n/<br>/g;
    $self->render(text => $contents{'content'});
  }
};

app->start;

__END__

__DATA__

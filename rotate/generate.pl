#!/usr/bin/perl

use warnings;
use strict;

my %sides = ("front"=> "F", "back"=> "B", "left"=> "L", "right"=> "R", "up"=> "U", "down"=> "D");
my @cubieTypes = ("corner", "edge", "center");
my %inverse = ( "left" => "right", "right" => "left", "up" => "down", "down" => "up", "front" => "back", "back" => "front");
my %realSides = ( "left" => "left", "right" => "left", "up" => "up", "down" => "up", "front" => "front", "back" => "front");

my %arrows = (
	"front" => { "left" => "up", "right" => "down", "up" => "right", "down" => "left" },
	"left" => { "front" => "down", "back" => "up", "up" => "down", "down" => "down" },
	"up" => { "left" => "left", "right" => "left", "front" => "left", "back" => "left" }
);

my %titles = ("-" => "'", "2" => "2", "" => "");

sub GetArrow
{
	my $side = $_[0];
	my $direction = $_[1];
	my $rotation = $_[2];

	my $arrow = $arrows{$realSides{$side}}{$direction};

	if ($rotation eq '-' ^ ($side ne $realSides{$side}))
	{
		$arrow = $inverse{$arrow};
	}

	if ($rotation eq "2")
	{
		$arrow = "double-$arrow";
	}

	return $arrow;
}

my $side;

foreach $side (keys %sides)
{
	my $rotation;
	foreach $rotation ("", "-", "2")
	{
		my $degrees = 90;
		my $transitionSeconds = 1;

		if ($rotation eq "2")
		{
			$degrees = 180;
			$transitionSeconds = 1.5;
		}

		my $rotateX = 0;
		my $rotateY = 0;
		my $rotateZ = 0;

		if ($realSides{$side} eq "left")
		{
			if ($side eq "right" ^ $rotation eq "-")
			{
				$rotateX = -$degrees;
			}
			else
			{
				$rotateX = $degrees;
			}
		}
		elsif ($realSides{$side} eq "front")
		{
			if ($side eq "front" ^ $rotation eq "-")
			{
				$rotateZ = -$degrees;
			}
			else
			{
				$rotateZ = $degrees;
			}
		}
		elsif ($realSides{$side} eq "up")
		{
			if ($side eq "down" ^ $rotation eq "-")
			{
				$rotateY = -$degrees;
			}
			else
			{
				$rotateY = $degrees;
			}
		}

		my $filename = $sides{$side}.$rotation;
		my $title = $sides{$side} . $titles{$rotation};

		open (HTML, '>', "$filename.html");
		open (CSS, '>', "$filename.css");

		my $doubleRotateX = $rotateX * 2;
		my $doubleRotateY = $rotateY * 2;
		my $doubleRotateZ = $rotateZ * 2;

		print CSS << "ENDCSS";
\@import "../csscube-colors.css";
\@import "../csscube.css";
\@import "rotate.css";
.cube.rotate {
	transition: transform ${transitionSeconds}s;
	transform: rotateX(${rotateX}deg) rotateY(${rotateY}deg) rotateZ(${rotateZ}deg);

	animation-name: cube-rotate-animation;
	animation-duration: 2s;
	animation-delay: 0s;
	animation-iteration-count: 1;
	animation-timing-function: ease;
}

\@media(hover: hover) and (pointer: fine) {
	.cube.rotate:hover {
		transform: rotateX(0deg) rotateY(0deg) rotateZ(0deg);
	}
}

.cube.rotate:active {
	transform: rotateX(0deg) rotateY(0deg) rotateZ(0deg);
}

\@keyframes cube-rotate-animation {
	0% { transform: rotateX(${doubleRotateX}deg) rotateY(${doubleRotateY}deg) rotateZ(${doubleRotateZ}deg); }
	50% { transform: rotateX(${doubleRotateX}deg) rotateY(${doubleRotateY}deg) rotateZ(${doubleRotateZ}deg); }
	100% { transform: rotateX(${rotateX}deg) rotateY(${rotateY}deg) rotateZ(${rotateZ}deg); }
}
ENDCSS

		print HTML << "ENDHTML";
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8"/>
		<title>csscube by \@pixelbart</title>
		<link rel="stylesheet" href="$filename.css"/>
	</head>
	<body>
		<div class="box">
			<div class="row header">$title</div>
			<div class="row content">
				<div class="csscube">
ENDHTML

		my $x;
		my $y;
		my $z;
		my $sticker;
		my $group;

		foreach $group ("static", "rotate")
		{
			my $touchStart = "";
			if ($group eq "rotate")
			{
				# This is the reason why we can't completely sandbox the iframe. Thanks Mobile Safari!
				$touchStart = 'ontouchstart=""';
			}

			print HTML << "ENDHTML";
					<div class="cube $group" $touchStart>
ENDHTML
			foreach $x ("left", "center", "right")
			{
				foreach $y ("up", "center", "down")
				{
					foreach $z ("front", "center", "back")
					{
						if (($x eq $side || $y eq $side || $z eq $side) == ($group eq "rotate"))
						{
							my $centers = 0;
							my $type = "";
							my @edges;
							if ($z eq "center") { $centers++; } else { push(@edges, $z); }
							if ($x eq "center") { $centers++; } else { push(@edges, $x); }
							if ($y eq "center") { $centers++; } else { push(@edges, $y); }

							if ($centers < 3)
							{
								$type = $cubieTypes[$centers];

								my $e = join(" ", @edges);

								print HTML << "ENDHTML";
						<div class="cubie $e">
							<div class="$type $e">
ENDHTML

								foreach $sticker (keys %sides)
								{
									my $orientation = "inside";
									if ($e =~ /$sticker/)
									{
										$orientation = "outside";
										my $class = join(".", @edges);

										if ($group eq "static")
										{
											print CSS << "ENDCSS";
.$type.$class .sticker.$sticker { background-color: var(--csscube-$sticker-color-inactive); }
ENDCSS
										}
										elsif ($group eq "rotate" && $sticker ne $side)
										{
											my $arrow = GetArrow($side, $sticker, $rotation);
											print CSS << "ENDCSS";
.$type.$class .sticker.$sticker:after { content: var(--csscube-$arrow-arrow); }
ENDCSS
										}
									}

									print HTML << "ENDHTML";
								<div class="sticker $sticker $orientation"></div>
ENDHTML
								}

								print HTML << 'ENDHTML';
							</div>
						</div>
ENDHTML
							}
						}
					}
				}
			}

			print HTML << 'ENDHTML';
					</div>
ENDHTML
		}

		print HTML << 'ENDHTML';
				</div>
			</div>
			<div class="row footer">
ENDHTML

		my $menuSide;
		foreach $menuSide ("", "-", "2")
		{
			my $menuRotation;
			foreach $menuRotation (keys %sides)
			{
				my $menuFilename = $sides{$menuRotation}.$menuSide;
				my $menuTitle = $sides{$menuRotation}.$titles{$menuSide};
				my $menuActive = "";
				if ($menuFilename eq $filename)
				{
					$menuActive = " active";
				}

				print HTML << "ENDHTML";
				<div class="link$menuActive"><a href="$menuFilename.html">$menuTitle</a></div>
ENDHTML
			}
		}
		print HTML << 'ENDHTML'
			</div>
		</div>
	</body>
</html>
ENDHTML
	}
}

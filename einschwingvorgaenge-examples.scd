
/*
preparation
install this once
Quarks.install("https://github.com/dkmayer/miSCellaneous_lib/Classes/Nonlinear");
*/

// set the block size of the server
s.options.blockSize = 16; s.reboot;


/*
1.1. The simplest case (pure tone).

Working in a circular phase space.

The following examples help to understand dynamical systems on a circle.
If everything is in a circle, we can describe every point by a single number: the angle
The angle, we call it theta here, goes from 0 to 2pi (360°), which is the same again as 0.
So we can continue forever while staying in a limited range.

To know the vertical (y) position of a point in a circle, relative to a coordinate system,
we use the function sin(theta). For the horizontal position, cos(theta)

*/


// getting coordinates

t = pi / 3;
sin(t); // the y coordinate
cos(t); // the x coordinate
// if we compare two points at a distance of 2pi, are they the same?
// very much so (floating point arithmetic is a little bit off): almost zero.
cos(t + 2pi) - cos(t); // 4.4408920985006e-16

// an ever rising time and its x-y-coordinates
(
{
	var theta = Sweep.ar * 100;
	var x = cos(theta);
	var y = sin(theta);
	[theta, x, y]
}.plot(duration: 0.1, separately:true)
)

// listen to an endlessly rising value through a circle: sine tone
(
Ndef(\x, {
	var time = Sweep.ar;
	var freq = 200;
	var theta = time * freq * 2pi;
	theta.cos * 0.1
}).play;
)

// Question: how would you do frequency modulation?
// Question: the sweep cannot go to infinity, because computers have limited memory. What happens if we wait long enough? How can we get this earlier? How could we fix it?



/*
1.2 Non-uniform evolution
Adler's equation: theta' = mu + cos(theta)
we name the components of the phase space y[0], y[1] ... y[n-1] for an n-dimensional phase space
here, our phase space is 1-dimensional, so we only have y[0] and one equation in the differential equation below

this defines the differential equations
t is the time (which we do not use here)
y is the state of the phase space. It is an array, of n dimensions.
Here only with one element, theta, so the phase space is 1-dimensional
from the function that takes these arguments, we return also an array, of the same size
its elements are the derivatives, defined by a function, one for each dimension
t0 is the initial time
y0 is the initial state
there are more arguments, but for now this is enough.

*/


// definition of the ordinary differential equation (ODE)
// the equation is called adler equation, this is why we chose to call the definition \adler

(
Fb1_ODEdef(\adler, { |t, y, mu = 1.0|
	var theta = y[0];
	[
		{ mu + cos(theta) }
	]
}, t0: 0, y0: [0]);
)

// definition of the sound process that results from the solution of the ODE
// we pass the parameter mu and a time scale (400)
// we do not want a leakDC, which would center the resulting wave form
// for speakers, which is why we set leakDC: false.

// the solution here is the angle in a unit circle: its values go from 0 to 2pi,
// where 2pi is the same as 0. This is why we have to get

(
Ndef(\adler, {|mu=0.5|
	var theta = Fb1_ODE.ar(\adler, [mu], 400, leakDC: false);
	cos(theta) * 0.5;
}).play;
)

// display parameters and signals
(
ControlSpec.add(\mu, [0.5, 2, \lin]);
Ndef(\adler).gui;
s.scope.style_(1);
)

// moving around the bifurcation point

(
Ndef(\adler, {
	var mu = LFTri.kr(0.14).exprange(1, 1.05).poll(4, label:"  μ");
	var theta = Fb1_ODE.ar(\adler, [mu], 400, leakDC: false); // range 0..2pi
	cos(theta) * 0.5
}).play;
)

// we can sonify slow oscillations by modulating an impulse or sine oscillator with the system state
// here, we modulate both frequency and amplitude

(
Ndef(\adler, { |mu = 0.5|
	var theta = Fb1_ODE.ar(\adler, [mu], 400, leakDC: false); // range 0..2pi
	var ratio = theta.cos.linexp(-1, 1, 1, 4); // a half circle is two octaves (* 4)
	var amp = theta.sin.linexp(-1, 1, 0.01, 1); // the x coordinate is amplitude
	SinOsc.ar(ratio * 220) * amp * 0.1
}).play;
)

Ndef(\adler).xset(\mu, 0.5);
Ndef(\adler).xset(\mu, 1.5);
Ndef(\adler).xset(\mu, 1.2);
Ndef(\adler).xset(\mu, 1.057); // around 1 is the interesting part.
Ndef(\adler).xset(\mu, 1.001);





/*

Exploration: Try different functions of theta

*/

// plot functions
(
f = { |func|
	Fb1_ODEdef(\x, { |t, y|
		var theta = y[0];
		[
			{ func.(theta)  }
		]
	}, t0: 0, y0: [0]);

	{ Fb1_ODE.ar(\x, [0], 400, leakDC: false).cos }.plot(duration: 0.13)
};
)

f.({ |theta| 1.5 + cos(theta) });
f.({ |theta| 0.9 + cos(theta) });
f.({ |theta| 1.2 + (cos(theta) * cos(theta * 0.5)) });

// sonify functions
(
f = { |func|
	Fb1_ODEdef(\x, { |t, y|
		var theta = y[0];
		[
			{ func.(theta)  }
		]
	}, t0: 0, y0: [0]);

	Ndef(\adler, {
		var theta = Fb1_ODE.ar(\x, [mu], 200, leakDC: false);
		var ratio = theta.cos.linexp(-1, 1, 1, 4);
		var amp = theta.sin.linexp(-1, 1, 0.01, 1);
		SinOsc.ar(ratio * 220) * amp * 0.1
	}).play;
};
)


f.({ |theta| 1.5 + cos(theta) });
f.({ |theta| 0.9 + cos(theta) });
f.({ |theta| 1.2 + (cos(theta) * cos(theta * 0.5)) });


/*

1.3. The end of an oscillation, in 10 seconds
mu cahnges from 1.1 to 1 in 10 seconds

*/

(
Ndef(\adler, {
	var mu = XLine.kr(1.1, 1, 10).poll;
	Fb1_ODE.ar(\adler, [mu], tMul: 400) * 0.2
}).play;
s.scope.style_(1);
)





/*
2.2 The simplest physical oscillator (harmonic)
The phase space is 2-dimensional, so we have two equations

x' = v
v' = -gamma y - kx

*/


(
Fb1_ODEdef(\harmonic, { |t, y, gamma = 1.0, k = 1|
	var x = y[0];
	var v = y[1];
	[
		{ v },
		{
			var elastic = neg(gamma) * x;
			var friction = neg(k * x);
			elastic + friction
		}
	]
}, t0: 0, y0: [0, 1]);
)

// the same, more compact
(
Fb1_ODEdef(\harmonic, { |t, y, gamma = 1.0, k = 1|
	var x = y[0];
	var v = y[1];
	[
		{ v },
		{ neg(gamma) * x - (k * x) }
	]
}, t0: 0, y0: [0, 1]);

Ndef(\harmonic, { |gamma = 1, k = 1|
	Fb1_ODE.ar(\harmonic, [gamma, k], tMul: 400) * 0.2
}).play;
)

// display parameters and signals

(
ControlSpec.add(\gamma, [-0.2, 4, \lin]);
ControlSpec.add(\k, [0.001, 10, \exp]);
Ndef(\harmonic).gui;
s.scope.style_(2);
)


/*
2.3 Turning on the oscillation (negative friction)

x' = v
v' = gamma y - y^3 - kx

*/


(
Fb1_ODEdef(\selfsustained, { |t, y, gamma = 1.0, k = 1|
	var x = y[0];
	var v = y[1];
	[
		{ v },
		{ gamma * v - (v ** 3) - (k * x) }
	]
}, t0: 0, y0: [0, 1]);


Ndef(\selfsustained, { |gamma = 1, k = 1|
	Fb1_ODE.ar(\selfsustained, [gamma, k], tMul: 400) * 0.2
}).play;
)


// display parameters and signals
(
ControlSpec.add(\gamma, [-0.2, 4, \lin]);
ControlSpec.add(\k, [0.001, 3, \exp]);
Ndef(\selfsustained).gui;
s.scope.style_(2);
)

// modulate parameters with UGens in several parallel systems
(
Ndef(\selfsustained, {
	var channels, numParallel = 4;
	channels = {
		var gamma = LFDNoise1.kr(1).range(-0.2, 4);
		var k = LFDNoise1.kr(0.3).exprange(0.001, 3);
		Fb1_ODE.ar(\selfsustained, [gamma, k], tMul: 3200).at(0)
	}.dup(numParallel);
	Splay.ar(channels) * 0.2
}).play;
)


/*
2.3.1 A self-tuned oscillator

x' = v
v' = gamma y - y^3 - kx(1 + 0.16 sqrt(k) x^2)

*/


(
Fb1_ODEdef(\selftuned, { |t, y, gamma = 1.0, k = 1|
	var x = y[0];
	var v = y[1];
	[
		{ v },
		{
			var nonlinearTerm = 1 + (0.16 * sqrt(k) * x.squared);
			gamma * v - (v ** 3) - (k * x * nonlinearTerm)
		}
	]
}, t0: 0, y0: [0, 1]);

Ndef(\selftuned, { |gamma = 1, k = 1|

	Fb1_ODE.ar(\selftuned, [gamma, k], tMul: 400) * 0.2

}).play;
)

// display parameters and signals
(
ControlSpec.add(\gamma, [-0.2, 4, \lin]);
ControlSpec.add(\k, [0.001, 3, \exp]);
Ndef(\selftuned).gui;
s.scope.style_(2);
)

// compare self sustained and self tuned
(
Ndef(\x, { |gamma = 1, k = 1|
	var ssus = Fb1_ODE.ar(\selfsustained, [gamma, k], tMul: 400).at(0);
	var stun = Fb1_ODE.ar(\selftuned, [gamma, k], tMul: 400).at(0);
	[ssus, stun] * 0.2
}).play;
Ndef(\x).gui;
s.scope.style_(0);
)

// plot the waveforms at different values of k, to see how close the frequencies are
(
~plot = { |func, name = "", duration = 0.5|
	func.plot(duration)
	.superpose_(true)
	.plotColor_([Color.red, Color.blue])
	.axisLabelY_("v(t)")
	.axisLabelX_("t")
	.parent.name_(name)
};
~plot.({
	var gamma = [0.2, 1.5], k = 0.2;
	gamma.collect { |g| Fb1_ODE.ar(\selfsustained, [g, k], tMul: 500).at(0) }
}, "self sustained");
~plot.({
	var gamma = [0.2, 1.5], k = 0.2;
	gamma.collect { |g| Fb1_ODE.ar(\selftuned, [g, k], tMul: 500).at(0)}
},  "self tuned");
)




/*

2.4 Fictional frictions

*/


// excursion: developing a stick-slip friction profile
// 1. friction rises exponentially with v
{ |v| exp(2*v) }.plotGraph(from: -2, to: 2).domainSpecs_([-2, 2].asSpec);
// 2. and also falls exponentially again as v exceeds a threshold
{ |v| exp(neg(abs(2*v))) }.plotGraph(from: -2, to: 2).domainSpecs_([-2, 2].asSpec);
// 3. the direction of the friction should be always opposed to the velocity
{ |v| sign(v) * exp(neg(abs(2*v))) }.plotGraph(from: -2, to: 2).domainSpecs_([-2, 2].asSpec);
// 4. to smooth the friction profile, we use atan(v/0.05) instead of sign(v)
{ |v| atan(v/0.05) * exp(neg(abs(2*v))) }.plotGraph(from: -2, to: 2);


// a dynamical system with stick slip friction
// atan(dv / epsilon) * exp(-2 * dv.abs)

(
Fb1_ODEdef(\frictional, { |t, y, gamma = 1.0, k = 1, v0 = 1, epsilon = 0.05|
	var x = y[0];
	var v = y[1];
	[
		{ v },
		{
			var dv = v - v0;
			var fbow = atan(dv / epsilon) * exp(-2 * dv.abs);
			neg(gamma * fbow) - (k * x)
		}
	]
}, t0: 0, y0: [0, 1]);

Ndef(\frictional, { |gamma = 1, k = 1, v0 = 1, epsilon = 0.05|
	Fb1_ODE.ar(\frictional, [gamma, k, v0, epsilon], tMul: 400) * 0.2
}).play;
)

// display parameters and signals
(
ControlSpec.add(\gamma, [-2, 2, \lin]);
ControlSpec.add(\k, [0, 2, \lin]);
ControlSpec.add(\v0, [-5, 5, \lin]);
ControlSpec.add(\epsilon, [1e-8, 0.1, \lin]);
Ndef(\frictional).gui;
s.scope.style_(2);
)



/*

2.4.1 Other frictions

*/

// we factor the velocity so that the optimized formula is
// var vsq = v.squared;
// var ffic = v * (1 - vsq + (sigma * vsq.squared));

(
Fb1_ODEdef(\frictional2, { |t, y, gamma = 1.0, k = 1, sigma = 0.2|
	var x = y[0];
	var v = y[1];
	[
		{ v },
		{
			var vsq = v.squared;
			var ffic = v * (1 - vsq + (sigma * vsq.squared));
			neg(gamma * ffic) - (k * x)
		}
	]
}, t0: 0, y0: [0, 1]);


Ndef(\frictional2, { |gamma = 1, k = 1, sigma = 0.2|
	Fb1_ODE.ar(\frictional2, [gamma, k, sigma], tMul: 400) * 0.2
}).play;
)


// display parameters and signals
(
ControlSpec.add(\gamma, [-2, 2, \lin]);
ControlSpec.add(\k, [0, 2, \lin]);
ControlSpec.add(\v0, [-5, 5, \lin]);
ControlSpec.add(\sigma, [0.01, 0.5, \lin]);

Ndef(\frictional2).gui;
s.scope.style_(2);
)


/*

2.5 The meaning of a saddle

*/


(
Fb1_ODEdef(\homoclinic, { |t, y, mu = 0.1, delta = 0.5|
	var x = y[0];
	var v = y[1];
	[
		{ v },
		{
			var xsq = x.squared;
			x * (neg(v * delta) + x - xsq - (xsq * v)) - mu }
	]
}, t0: 0, y0: [-0.32, 0]);


Ndef(\homoclinic, { |mu = 0.17, delta = 0.5|
	Fb1_ODE.ar(\homoclinic, [mu, delta], y0: [0, 0], tMul: 400) * 0.2
}).play;
)

// display parameters and signals
(
ControlSpec.add(\mu, [0.01, 0.2, \lin]);
ControlSpec.add(\delta, [0.5, 1.5, \lin]);
Ndef(\homoclinic).gui;
s.scope.style_(2);
)


// sonification of the homoclinic bifurcation as frequency modulation
(
Ndef(\homoclinic, { |mu = 0.17, delta = 0.5|
	var ps = Fb1_ODE.ar(\homoclinic, [mu, delta], y0: [0, 0], tMul: 100, leakDC: false);
	var freq = ps.linlin(-1, 1, 300, 2000);
	SinOsc.ar(freq) * 0.1
}).play;
Ndef(\homoclinic).gui;
)






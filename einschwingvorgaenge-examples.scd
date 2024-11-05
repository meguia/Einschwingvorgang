
// preparation
Quarks.install("https://github.com/dkmayer/miSCellaneous_lib");
s.options.blockSize = 16; s.reboot;


// 1.1. The simplest case (pure tone)
// Example of a phase space that is a single angle θ (theta) in polar coordinates
// the radius is 1 ("unity"), and we provide the angle in radians, i.e. 360° equals 2pi

p = Polar(1, theta:0.75); // define a position in polar coordinates
p.asPoint.x // the x coordinate, which is the cosine of theta
p.asPoint.y // the y coordinate, which is the sine of theta
0.75.cos; // the x coordinate directly
(0.75 + 2pi).cos - 0.75.cos; // are they the same? very much so (floating point arithmetic is a little bit off): almost zero.


// an ever rising time and its cosine
(
{
	var theta = Sweep.ar * 100;
	var x = theta.cos;
	[theta, x]
}.plot(duration: 0.1, separately:true)
)

// listen to the sine tone
(
Ndef(\x, {
	var time = Sweep.ar;
	var freq = 200;
	var theta = time * freq * 2pi;
	theta.cos * 0.1
}).play;
)


/*
1.2 Non-uniform evolution
Adler's equation: theta' = mu + cos(theta)
we name the components of the phase space y[0], y[1] ... y[n-1] for an n-dimensional phase space
here, our phase space is 1-dimensional, so we only have y[0] and one equation in the differential equation below
theta is here y[0]
*/

(
Fb1_ODEdef(\adler, { |t, y, mu = 1.0|
	var theta = y[0];
	[
		{ mu + cos(theta) }
	]
}, t0: 0, y0: [0]);
)

(
Ndef(\x, {|mu=0.1|
	var theta = Fb1_ODE.ar(\adler, [mu], 400, leakDC: false);
	theta.cos * 0.5;
}).play;
)

ControlSpec.add(\mu, [0.5, 2, \lin]);
Ndef(\x).gui;
Ndef(\x).scope.style_(2);


Ndef(\x).set(\mu, 0.9);
Ndef(\x).set(\mu, 1.1);
Ndef(\x).set(\mu, 1.2);





/*

Different functions of theta

*/

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



/*

comparison: wave shaping

*/


(
Ndef(\x, {
	var theta = LFSaw.ar(300);
	SinOsc.ar(0, theta * 2pi) * 0.1;
}).play
)


(
Ndef(\x, {
	var theta = LFSaw.ar(100) + LFSaw.ar(-243.2) * 3;
	SinOsc.ar(0, theta * 2pi) * 0.1;
}).play
)


/*

1.3. The end of an oscillation, in 10 seconds

*/

(
Ndef(\x, {
	var mu = XLine.kr(1.1, 1, 10).poll;
	Fb1_ODE.ar(\adler, [mu], tMul: 400) * 0.2
}).play.scope;
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
		{ neg(gamma) * x - (k * x) }
	]
}, t0: 0, y0: [0, 1]);
)

// the same, more explicitly
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


(
Ndef(\hc, { |gamma = 1, k = 1|
	Fb1_ODE.ar(\harmonic, [gamma, k], tMul: 400) * 0.2
}).play;
Ndef(\hc).gui
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
)

(
Ndef(\hc, { |gamma = 1, k = 1|
	Fb1_ODE.ar(\selfsustained, [gamma, k], tMul: 400) * 0.2
}).play;

Ndef(\hc).gui;
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

Ndef(\hc, { |gamma = 1, k = 1|

	Fb1_ODE.ar(\selftuned, [gamma, k], tMul: 400) * 0.2

}).play;

Ndef(\hc).gui
)

// compare self sustained and self tuned
(
Ndef(\hc, { |gamma = 1, k = 1|
	var ssus = Fb1_ODE.ar(\selfsustained, [gamma, k], tMul: 400).at(0);
	var stun = Fb1_ODE.ar(\selftuned, [gamma, k], tMul: 400).at(0);
	[ssus, stun] * 0.2
}).play;
Ndef(\hc).gui
)


(
~plot = { |func, name = "", duration = 0.5|
	func.plot(duration)
	.superpose_(true)
	.plotColor_([Color.red, Color.blue])
	.axisLabelY_("v(t)")
	.axisLabelX_("t")
	.parent.name_(name)
};
~plot.({ var gamma = [0.2, 1.5], k = 0.2; gamma.collect { |g| Fb1_ODE.ar(\selfsustained, [g, k], tMul: 400).at(0) } }, "self sustained");
~plot.({ var gamma = [0.2, 1.5], k = 0.2; gamma.collect { |g| Fb1_ODE.ar(\selftuned, [g, k], tMul: 400).at(0)} },  "self tuned");
)




/*

2.4 Fictional frictions

*/


// developing a friction profile
{ |v| exp(2*v) }.plotGraph(from: -2, to: 2);
{ |v| exp(neg(abs(2*v))) }.plotGraph(from: -2, to: 2);
{ |v| sign(v) * exp(neg(abs(2*v))) }.plotGraph(from: -2, to: 2);
{ |v| atan(v/0.05) * exp(neg(abs(2*v))) }.plotGraph(from: -2, to: 2);




(
Fb1_ODEdef(\ficfric, { |t, y, gamma = 1.0, k = 1, v0 = 1, epsilon = 0.05|
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

Ndef(\ff, { |gamma = 1, k = 1, v0 = 1, epsilon = 0.05|
	Fb1_ODE.ar(\ficfric, [gamma, k, v0, epsilon], tMul: 400) * 0.2
}).play;
)


(
ControlSpec.add(\gamma, [-2, 2, \lin]);
ControlSpec.add(\k, [0, 2, \lin]);
ControlSpec.add(\v0, [-5, 5, \lin]);
ControlSpec.add(\epsilon, [1e-8, 0.1, \lin]);
Ndef(\ff).gui;
)



/*

2.4.1 Other frictions
(TOD BE FIXED)

*/



(
Fb1_ODEdef(\ficfric2, { |t, y, gamma = 1.0, k = 1, sigma = 0.2|
	var x = y[0];
	var v = y[1];
	[
		{ v },
		{
			var ffic = v * (1 - (v*v) + (sigma * v * v * v * v));
			neg(gamma * ffic) - (k * x)
		}
	]
}, t0: 0, y0: [0, 1]);
)


(
Ndef(\ff2, { |gamma = 1, k = 1, sigma = 0.2|
	Fb1_ODE.ar(\ficfric2, [gamma, k, sigma], tMul: 400) * 0.2
}).play;

ControlSpec.add(\gamma, [-2, 2, \lin]);
ControlSpec.add(\k, [0, 2, \lin]);
ControlSpec.add(\v0, [-5, 5, \lin]);
ControlSpec.add(\sigma, [0.01, 0.5, \lin]);

Ndef(\ff2).gui;
)


{ a = Line.kr(-4, 4, 0.01); a * a * a }.plot

-2 ** 2

/*

2.5 The meaning of a saddle

FIXME

*/


(
Fb1_ODEdef(\homoclinic, { |t, y, mu = 0.1, delta = 0.5|
	var x = y[0];
	var v = y[1];
	[
		{ v },
		{ neg(x * v * delta) + (x ** 2) - (x ** 3) - (x ** 2 * v) - mu }
	]
}, t0: 0, y0: [-0.32, 0]);
)

(
Ndef(\homoclinic, { |mu = 0.17, delta = 0.5|
	Fb1_ODE.ar(\homoclinic, [mu, delta], y0: [0, 0], tMul: 400) * 0.2
}).play;

ControlSpec.add(\mu, [0.01, 0.2, \lin]);
ControlSpec.add(\delta, [0.5, 1.5, \lin]);
Ndef(\homoclinic).gui;
)

s.scope
Ndef.clear


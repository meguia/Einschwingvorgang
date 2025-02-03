// you may try this if it is not too inefficient
s.options.blockSize = 1;
s.options.sampleRate = 96000;
//s.options.outDevice = "External Headphones";
s.reboot;



// or this
s.options.blockSize = 8;
s.options.sampleRate = 48000;
s.reboot;

///////////////////////////////////////////////////

// 1.1. The symmetric oscillator and the oscillation on the circle

// harmonic oscillator
// note, we name "y" to "state",
// the initial conditions y0 are the initial conditions of state.
(
Fb1_ODEdef(\harmonic, { |t, state, omega = 1.0|
	var x = state[0];
	var v = state[1];
	[
		{ v },
		{ omega.squared.neg * x }
	]
}, t0: 0, y0: [1, 0]);
)


(
Ndef(\harmonic, {|omega=0.5|
	var state = Fb1_ODE.ar(\harmonic, [omega], 400, y0:[1,0], leakDC: false);
	state * 0.5
}).play;
)

// ellipse is visible in scope
// display parameters and signals
(
ControlSpec.add(\omega, [0.01, 2, \lin]);
Ndef(\harmonic).gui;
s.scope.style_(2);
)


/*

given the two equations:

x' = v
v' = omega.squared.neg * x

we can factor omega into the coordinates (streching the x axis by omega)
so that we can now write

x' = omega * y
y' = omega.neg * x


*/

// harmonic oscillator with constant radius
(
Fb1_ODEdef(\harmonic, { |t, state, omega = 1.0|
	var x = state[0];
	var y = state[1];
	[
		{ omega * y },
		{ omega.neg * x }
	]
}, t0: 0, y0: [1, 0]);
)


(
Ndef(\harmonic, {|omega=0.5|
	var state = Fb1_ODE.ar(\harmonic, [omega], 400, y0:[1,0], leakDC: false);
	state * 0.2
}).play;
)

// now the shape is independent of omega (which still changes the frequency)
// display parameters and signals
(
ControlSpec.add(\omega, [0.01, 8, \exp]);
Ndef(\harmonic).gui;
s.scope.style_(2);
)



// harmonic oscillator with constant radius in polar coordinates
(
Fb1_ODEdef(\harmonic, { |t, state, omega = 1.0|
	var r = state[0]; // radius
	var theta = state[1]; // angle
	[
		{ 0 }, // we do not change the radius (amplitude)
		{ omega.neg } // the angular frequency is constant: we always multiply by a constant factor
	]
}, t0: 0, y0: [1, 1]);
)


// harmonic oscillator with constant radius in polar coordinates
(
Fb1_ODEdef(\harmonic, { |t, state, omega = 1.0|
	var theta = state[0]; // angle
	[
		{ omega.neg }
	]
}, t0: 0, y0: [1]);
)


(
Ndef(\harmonic, {|omega=0.5|
	var state = Fb1_ODE.ar(\harmonic,
		argList: [omega].lag,
		tMul: 400,
		y0:[1],
		leakDC: false
	);
	cos(state) * 0.2
}).play;
)

// now the shape is independent of omega (which still changes the frequency)
// display parameters and signals
(
ControlSpec.add(\omega, [0.01, 8, \exp]);
Ndef(\harmonic).gui;
s.scope.style_(2);
)

// use a cursor mapping
Ndef(\mouseX, { MouseX.kr(0.01, 8, 1) }); Ndef(\harmonic).set(\omega, Ndef(\mouseX));
Ndef(\harmonic).unset(\omega); // unlink it from the cursor again

// after a short while, we get floating point inaccuracies: theta grows and grows
// but in fact, the angle is a cyclic value, for which any theta + 2pi = theta.
// so we want to numerically keep the angle wrapped into the range [0..2pi[.
// this can be done with theta % 2pi. But we need to be able to filter the state itself
// not just through its derivative.
// This is where the "compose" function in Fb1_ODE is useful:
// here, we keep the radius untouched, but wrap theta in range.

(
Ndef(\harmonic, {|omega=0.5|
	var state = Fb1_ODE.ar(\harmonic,
		argList: [omega].lag,
		tMul: 400,
		y0:[1],
		leakDC: false,
		compose: { |state|
			var theta = state[0];
			[theta % 2pi]
		}
	);
	cos(state) * 0.2
}).play;
)

{ a = Line.ar(0,40,0.01); b = a % 2pi; [a, b, cos(b)] }.plot(separately:true)


// 5a, 5b


// harmonic oscillator with dissipation in both variables
(
Fb1_ODEdef(\harmonic, { |t, state, omega = 1.0, gamma = 0.01|
	var x = state[0];
	var y = state[1];
	[
		{ (omega * y) - (gamma * x) },
		{ (omega.neg * x) - (gamma * y) }
	]
}, t0: 0, y0: [1, 0]);
)


(
Ndef(\harmonic, {|omega=0.5, gamma = 0.01|
	var state = Fb1_ODE.ar(\harmonic, [omega, gamma], 400, y0:[1,0], leakDC: false);
	state * 0.2
}).play;
)

// now the shape is independent of omega (which still changes the frequency)
// display parameters and signals
(
ControlSpec.add(\omega, [0.01, 8, \exp]);
ControlSpec.add(\gamma, [0.0002, 0.05, \exp]);
Ndef(\harmonic).gui;
s.scope.style_(2);
)

// restart the system every second
Tdef(\x, { loop { 1.wait; Ndef(\harmonic).send } }).play;


// harmonic oscillator with dissipation in polar form
(
Fb1_ODEdef(\harmonic, { |t, state, omega = 1.0, gamma = 0.01|
	var r = state[0];
	var theta = state[1];
	[
		{ gamma.neg * r },
		{ omega.neg }
	]
}, t0: 0, y0: [1, 1]);
)

(
Ndef(\harmonic, {|omega=0.5, gamma = 0.01|
	var state = Fb1_ODE.ar(\harmonic, [omega, gamma], 400, y0:[1,0], leakDC: false);
	cos(state) * 0.2
}).play;
)

// display signal theta.sin
s.scope.style_(1);



// 1.2 Revisiting the self-oscillator. Hopf Normal Form


// dissipative harmonic system with two equations
(
Fb1_ODEdef(\harmonic, { |t, state, omega = 1.0, gamma = 0.01|
	var x = state[0];
	var y = state[1];
	[
		{ (omega * y) - (gamma * x) - (x * (x.squared + y.squared)) },
		{ (omega.neg * x) - (gamma * y) - (y * (x.squared + y.squared)) }
	]
}, t0: 0, y0: [1, 0]);
)

(
Ndef(\harmonic, {|omega=0.5, gamma = 0.01|
	var state = Fb1_ODE.ar(\harmonic, [omega, gamma], 400,
		y0:\initState.kr([1, 0]),
		leakDC: false
	);
	state * 0.2
}).play;
)


// display parameters and signals
(
ControlSpec.add(\omega, [0.01, 8, \exp]);
ControlSpec.add(\gamma, [0.0002, 0.05, \exp]);
Ndef(\harmonic).gui;
s.scope.style_(2);
)

// again, (x.squared + y.squared) is the square of the radius, so we can
// rewrite the system in a polar coordinate system
(
Fb1_ODEdef(\harmonic, { |t, state, omega = 1.0, gamma = 0.01|
	var r = state[0];
	var theta = state[1];
	[
		{ gamma * r - r.cubed },
		{ omega.neg }
	]
}, t0: 0, y0: [1, 0]);
)

(
Ndef(\harmonic, {|omega=0.5, gamma = 0.01|
	var state = Fb1_ODE.ar(\harmonic, [omega, gamma].poll, 400,
		y0: \initState.kr([1, 0]),
		leakDC: false,
		compose: { |state| var omega = state[0], theta = state[1]; [omega, theta % 2pi] }
	);
	var theta = state[1];
	cos(theta).poll * 0.2
}).play;
)

// display parameters and signals
(
ControlSpec.add(\omega, [0.01, 8, \exp]);
ControlSpec.add(\gamma, [0.0002, 0.5, \exp]);
Ndef(\harmonic).gui;
Ndef(\harmonic).scope.style_(0);
)

// restart the system every 2 seconds with different initial states
// slowly moving across the Hopf bifurcation

(
Tdef(\x, {
	20.do { |i|
		2.wait;
		Ndef(\harmonic).send([
			\omega, 1,
			\gamma, i.linlin(0, 20, -0.01, 0.05).postln, // <---- problem: no crossing of bifurcation happens yet.
			\initState, [1.0, 1.0].rand,
		]);
	}
}).play
)

// something to do: explore the different initial states by sonifying the initial path.



// 1.3 The self modulated oscillator and the first derivation of the Adler’s equation


// simplest case: just one oscillator modulating itself

(
Fb1_ODEdef(\selfmodulation, { |t, state, alpha = 0, omega = 0.5|
	var x, y;
	x = state[0];
	y = state[1];

	[
		{  (omega * y) + (alpha * x * y) },
		{ ((omega * x) + (alpha * x * x)).neg },
	]
}, y0: [1, 1]);


Ndef(\selfmodulation, {
	var l = \lag.kr(0.2);
	var params = [\alpha.kr(0.02, l), \omega.kr(0.5, l)];
	var eq = Fb1_ODE.ar(\selfmodulation, params, 700, y0:  [0, 1], leakDC: false);
	0.1 * eq[0];
}).play
)



// display parameters and signals
(
ControlSpec.add(\omega, [0, 4, \lin]);
ControlSpec.add(\alpha, [0, 4, \lin]);
Ndef(\selfmodulation).gui;
s.scope.style_(2);
)



// we can remap a little:

(
Ndef(\selfmodulation, {
	var l = \lag.kr(0.2);
	var factor = \selfMod.kr(0, l);
	var omega = \omega.kr(0.5, l);
	var alpha = omega * factor;
	var params = [alpha, omega];
	0.1 * Fb1_ODE.ar(\selfmodulation, params, 700, y0:  [0, 1], leakDC: false);
}).play
)



// display parameters and signals
(
ControlSpec.add(\omega, [0.01, 4, \exp]);
ControlSpec.add(\selfMod, [0, 1.5, \lin]);
Ndef(\selfmodulation).gui;
s.scope.style_(2);
)



// the radius is constant, so we can reformulate the oscillator in a polar coordinate system
// note that alpha is now rescale
(
Fb1_ODEdef(\selfmodulation, { |t, state, alpha = 0, omega = 0.5|
	var theta = state[0];
	[
		{ omega.neg - (alpha * cos(theta)) }
	]
}, y0: [1, 1]);


Ndef(\selfmodulation, {
	var l = \lag.kr(0.2);
	var params = [\alpha.kr(0.02, l), \omega.kr(0.5, l)];
	var eq = Fb1_ODE.ar(\selfmodulation, params, 700, y0:  [0, 1], leakDC: false);
	0.1 * eq[0].sin;
}).play
)

// display parameters and signals
(
ControlSpec.add(\omega, [0.01, 4, \lin]);
ControlSpec.add(\alpha, [0.01, 4, \lin]);
Ndef(\selfmodulation).gui;
Ndef(\selfmodulation).scope.style_(0);
)

// again, we can remap alpha to a selfMod parameter to express the degree of self modulation independent of omega
// at selfMod = 1, the oscillation ends

(
Ndef(\selfmodulation).clear;
Ndef(\selfmodulation, {
	var l = \lag.kr(0.2);
	var factor = \selfMod.kr(0, l);
	var omega = \omega.kr(0.5, l);
	var alpha = omega * factor;
	var params = [alpha, omega];
	var eq = Fb1_ODE.ar(\selfmodulation, params, 700, y0:  [0, 1], leakDC: false);
	0.1 * eq[0].sin;
}).play
)

// display parameters and signals
(
ControlSpec.add(\omega, [0.01, 4, \exp]);
ControlSpec.add(\selfMod, [0, 1.5, \lin]);
Ndef(\selfmodulation).gui;
Ndef(\selfmodulation).scope.style_(0);
)



/*

1.4

Multiple mutually modulated oscillators

*/

(
~makeDef = { |name, numOscillators|
	Fb1_ODEdef(name, { |t, state, as, oms|
		var ld, x, y, a, n;
		if(state.size.odd) { state = state.drop(-1) };

		oms = oms.asArray;
		// alphas are in groups of inputs for each oscillator:
		// the first array is all the alphas for the first oscillator etc.
		a = as.asArray.clump(numOscillators);

		x = state[0,2..]; // all even indices are x
		y = state[1,3..]; // all odd indices are y

		numOscillators.collect { |i|
			[
				{ oms[i] * (y[i] + sum(a[i] * x * y)) },
				{ oms[i] * (x[i] + sum(a[i] * x.squared)).neg },
			]
		}.flat


	}, y0: [0, 1].wrapExtend(numOscillators * 2).postln);
};

~makeNdef = { |name, numOscillators|
	Ndef(name).clear;
	Ndef(name, {
		var l = \lag.kr(0.2);
		var eq = Fb1_ODE.ar(name,
			[
				\a.kr(0 ! numOscillators.squared),
				\oms.kr(1 ! numOscillators)
			],
			400,
			y0:  [0, 1].wrapExtend(numOscillators * 2),
			leakDC: false,
			intType: \rk4 // <---not sure if it is necessary
		);
		eq[0,2..] // we keep only the amplitudes
	});
	Ndef(\out, { Limiter.ar(Splay.ar(Limiter.ar(Ndef.ar(name)))) * 0.3 }).play;
//	Ndef(\out, { Limiter.ar(Ndef.ar(name), 0.2) }).play; // for multi channel systems
	Ndef(name)
};

~makeGUI = { |name, numOscillators|
	var n = numOscillators.squared;
	Ndef(name).scope.style_(0);
	if(numOscillators > 1) {
		ControlSpec.add(\a, [0!n,1!n]);
	} {
		ControlSpec.add(\a, [0, 1])
	};
	Ndef(name).gui;
};

// make an intermapping for exploring different parameter relationships
// whith the xy-cursor movement
~mapAllToCursor = { |name, paramName, numOscillators, strength = 0.1|
	var c = { rrand(0, 2.0) } ! numOscillators;
	Ndef(\ctl, {
		var cursor = [MouseX.kr, MouseY.kr];
		sin(cursor * 2pi + (c * pi)) + 0.3 * strength max: 0
	});
	Ndef(\ctl)[1] = Task {
		loop {
			var a = s.getControlBusValues(Ndef(\ctl).index, numOscillators).round(0.001).postln;
			Ndef(name).set(paramName, a);
			0.1.wait;
		};
	};
	//Ndef(name).set(paramName, Ndef(\ctl)); // this would map continuously.
};

//~unmapCursor = { |name, paramName| Ndef(name).unset(paramName) };
)



~makeDef.(\fm1, 1);
~makeNdef.(\fm1, 1);
~makeGUI.(\fm1, 1);


~makeDef.(\fm2, 2);
~makeNdef.(\fm2, 2);
~makeGUI.(\fm2, 2);


~mapAllToCursor.(\fm2, \a, 3, 0.2);
~unmapCursor.(\fm2, \a);


// PROBLEM: they still explode for some parameter values
Ndef(\fm2).set(\a, [0, 0.3, 0.3, 0]);
Ndef(\fm2).set(\oms, [1, 1.2]*2);
Ndef(\fm2).send;

~makeDef.(\fm3, 3);
~makeNdef.(\fm3, 3);
~makeGUI.(\fm3, 3);

~mapAllToCursor.(\fm3, \a, 3, 0.2);
~unmapCursor.(\fm3, \a);


Ndef(\fm3).clear;

// introspection
Ndef(\ctl).scope
Tdef(\resend, { loop { 2.wait; Ndef(\fm2).send } }).play
NdefMixer(s);






/*
2 Coupled Oscillators on the circle

2.1 General formula for coupled oscillators: the Kuramoto Model

*/

(
~makeDef = { |name, numOscillators|
	Fb1_ODEdef(name, { |t, state, oms, k|
		var sys;
		var thetas = state.keep(numOscillators);
		numOscillators.collect { |i|
			{
				oms[i] + (k * sum(sin(thetas - thetas[i])))
			}
		}
	}, y0: 0 ! numOscillators);
};

~makeNdef = { |name, numOscillators|
	Ndef(name, {
		var l = \lag.kr(0.2);
		var oms = \oms.kr(1 ! numOscillators, l);
		var k = \k.kr(1, l);
		var sys = Fb1_ODE.ar(name,
			argList: [oms, k],
			tMul: 400,
			y0:  0.3 ! numOscillators,
			compose: { |state| state.wrap2(2pi * numOscillators) },
			leakDC: false,
			intType: \rk4, // <-- not sure if necessary.
		);

		var val = cos(sys);
		val
	});
	Ndef(\out, { Limiter.ar(Splay.ar(Limiter.ar(Ndef.ar(name)))) * 0.3}).play;
	Ndef(name)
};

~makeGUI = { |name|
	Ndef(name).scope.style_(0);
	ControlSpec.add(\k, [0, 1]);
	Ndef(name).gui;
};


)

// 2.2 Two simple coupled oscillators and the second derivation of the Adler’s equation

Ndef(\kuramoto).clear;
~makeDef.(\kuramoto, 2);
~makeNdef.(\kuramoto, 2);
~makeGUI.(\kuramoto);
Ndef(\kuramoto).set(\oms, [0.4, 0.47]*3, \k, 0.05);
Ndef(\kuramoto).set(\oms, [0.4, 0.47]*3, \k, 0.08);
Ndef(\kuramoto).set(\oms, [0.4, 0.47]*3, \k, 0.144);


// 2.3 Three uniformly coupled oscillators

~makeDef.(\kuramoto, 3);
~makeNdef.(\kuramoto, 3);
~makeGUI.(\kuramoto);
Ndef(\kuramoto).set(\oms, [0.4, 0.47, 0.65]*3, \k, 0.05);
Ndef(\kuramoto).set(\oms, [0.4, 0.47, 0.65]*3, \k, 0.08);
Ndef(\kuramoto).set(\oms, [0.4, 0.47, 0.65]*3, \k, 0.144);


// Eight uniformly coupled oscillators
// Kuramoto sine zoo longing for some anarchy
// may take a little while ...
~makeDef.(\kuramoto, 8);
~makeNdef.(\kuramoto, 8);
~makeGUI.(\kuramoto);
Ndef(\kuramoto).set(\oms, [0.4, 0.47, 0.65].wrapExtend(8) * 2);
Ndef(\kuramoto).set(\k, 0.04);

Ndef(\ctl_k, { MouseX.kr(0, 1) });
Ndef(\kuramoto).set(\k, Ndef(\ctl_k));
Ndef(\kuramoto).set(\oms, [0.4, 0.7, 1].wrapExtend(8) * 2);


Ndef(\ctl_a, { LFDNoise1.kr(0.4 ! 8).exprange(2, 15) });
Ndef(\kuramoto).set(\oms, Ndef(\ctl_a));



















// the following are some unfinished experiments with coupling extrenally.
///////////////////////////////////////////////////////////////////////////////////////////
// --------------------

// (
// Fb1_ODEdef(\oscillator, { |t, state, omega, k|
// 	var y = state[0];
// 	var inputs = [\in1.ar(0), \in2.ar(0)];
// 	omega.poll;
// 	[
// 		{ omega + (k * sum(cos(inputs))) }
// 	]
// }, y0: [0]);
// )



// SOMETHING IS WRONG HERE STILL :::
(
Fb1_ODEdef(\oscillator, { |t, state, omega, k|
	var x = state[0];
	var y = state[1];
	var lambda = { k * SinOsc.ar(0.8) };

	[
		{ (omega + lambda.value) * y },
		{ neg(omega + lambda.value) * x }
	]
}, y0: [0, 1]);
)



(
Fb1_ODEdef(\oscillator, { |t, state, omega, k|
	var x = state[0];
	var y = state[1];
	var inputs = state[2..3];
	state.size.postln;

	[
		{ var lambda = k * sum(inputs);(omega + lambda) * y },
		{ var lambda = k * sum(inputs);neg(omega + lambda) * x }
	]
}, y0: [0, 1, 0, 0]);
)


(
Ndef(\comodulation, {
	var inputs = [\in1.ar(0), \in2.ar(0)];
	var state = Fb1_ODE.ar(
		name: \oscillator,
		argList: [\omega.kr(2.3), \k.kr(0.0)],
		tMul: 700,
		y0: [0, 1, 0, 0],
		leakDC: false,
		compose: { |y, in| (y ++ in) },
        composeArIn: inputs
	);
	var output = state[0];
	0.1 * output
}).play
)





(
Fb1_ODEdef(\oscillator, { |t, state, omega, k, in1, in2|
	var x = state[0];
	var y = state[1];

	[
		{ var lambda = k * sum([in1, in2]); (omega + lambda) * y },
		{ var lambda = k * sum([in1, in2]); neg(omega + lambda) * x }
	]
}, y0: [0, 1]);
)


(
Ndef(\comodulation, {
	var inputs = [\in1.ar(0), \in2.ar(0)];
	var state = Fb1_ODE.ar(
		name: \oscillator,
		argList: [\omega.kr(2.3), \k.kr(0.0)] ++ inputs,
		tMul: 700,
		y0: [0, 1],
		leakDC: false,
	);
	var output = state[0];
	0.1 * output
}).play
)




Ndef(\x1, { SinOsc.ar(2.3) });
Ndef(\x2, { SinOsc.ar(44) });

Ndef(\comodulation).set(\in1, Ndef(\x1), \in2, Ndef(\x2));
Ndef(\comodulation).set(\k, 0.3);
Ndef(\comodulation).scope

/////////// is it possible to pass audio rate args?

// seems yes.

(
Fb1_ODEdef(\test, { |t, state, f0, in|
	var x = state[0];
	var y = state[1];

	[
		{  (in + f0) * y },
		{  neg(in + f0) * x }
	]
}, y0: [0, 1]);


Ndef(\comodulator_1, {
	var input = SinOsc.ar(MouseX.kr(20, 10000, 1)).range(2, 4);
	var state = Fb1_ODE.ar(\test, [\f0.kr(1), input], 700, y0: [0, 1], leakDC: false);
	0.1 * state
}).play(0);
)


(
Ndef(\comodulator_1, {
	var input = Ndef.ar(\comodulator_2, 1) * 3;
	var state = Fb1_ODE.ar(\test, [\f0.kr(1), input], 700, y0: [0, 1], leakDC: false);
	0.1 * state[0]
}).play(0);
Ndef(\comodulator_2, {
	var input = Ndef.ar(\comodulator_1, 1) * 14;
	var state = Fb1_ODE.ar(\test, [\f0.kr(1), input], 700, y0: [0, 1], leakDC: false);
	0.1 * state[0]
}).play(8);

)

NdefMixer(s);


///////////

(
Fb1_ODEdef(\oscillator, { |t, state, omega, k, in1, in2|
	var x = state[0];
	var y = state[1];
	var lambda = k * sum([in1, in2]);

	in1.dump;

	[
		{  (omega + lambda) * y },
		{  neg(omega + lambda) * x }
	]
}, y0: [0, 1]);
)


(
Ndef(\comodulator_1, {
	var params = [\omega.kr(2.3), \k.kr(0.0), \in1.ar(0), \in2.ar(0)];
	var state = Fb1_ODE.ar(\oscillator, params, 700, y0: [0, 1], leakDC: false);
	0.1 * state
}).play(0);

Ndef(\comodulator_2, {
	var params = [\omega.kr(3.3), \k.kr(0.0), \in1.ar(0), \in2.ar(0)];
	var state = Fb1_ODE.ar(\oscillator, params, 700, y0: [0, 1], leakDC: false);
	0.1 * state
}).play(6);

Ndef(\comodulator_3, {
	var params = [\omega.kr(4.1), \k.kr(0.0), \in1.ar(0), \in2.ar(0)];
	var state = Fb1_ODE.ar(\oscillator, params, 700, y0: [0, 1], leakDC: false);
	0.1 * state
}).play(12);
)

(
Ndef(\comodulator_1).set(\in1, Ndef(\comodulator_2), \in2, Ndef(\comodulator_3));
Ndef(\comodulator_2).set(\in1, Ndef(\comodulator_1), \in2, Ndef(\comodulator_3));
Ndef(\comodulator_3).set(\in1, Ndef(\comodulator_1), \in2, Ndef(\comodulator_2));
)

NdefMixer(s)



/*
preparation
install this once
Quarks.install("https://github.com/dkmayer/miSCellaneous_lib/Classes/Nonlinear");
*/

// set the block size of the server
s.options.blockSize = 16; s.reboot;


// h(p,t) = [xd0]
//function simplest!(du,u,h,p,t)
//	hs = h(p,t-p[1])[1]
//	du[1] = hs*(1.0-hs*hs) - 0.2*u[1]
//end

1/(440 * 44000)

(
var n =  44100 / 5;
var buf = Buffer.alloc(s, n).setn(0.1 ! n);
var tMul = 400;
Fb1_ODEdef(\delayed, { |t, y, tau = 0.1|
	var maxDelay = 1; //1 / (SampleRate.ir * tMul);
	var preBufferSize = maxDelay * ControlRate.ir;
	var initState = 0.1;
	//var buf = LocalBuf(preBufferSize, 1).set(initState ! n);
	// hs is value of y[0] at t-tau
	[
		{
			var phaseOffset = tau * maxDelay;
			var phase = LFSaw.kr(ControlRate.ir/preBufferSize).range(0, preBufferSize-1);
			var hs = BufRd.kr(1, buf, phase - phaseOffset, loop: 1);
			BufWr.kr(y[0], buf, phase);
			hs * (1 - hs.squared) - (0.2 * y[0])
		}
	]
}, t0: 0, y0: [0.1]);

Ndef(\x, { Fb1_ODE.kr(\delayed, [\tau.kr(0)], tMul: 400, leakDC: false); }).scope;

~buf = buf;
)

ControlSpec.add(\tau, [0, 1]);

Ndef(\x).gui;
Ndef(\x).set(\tau, 0.3);

~buf.plot
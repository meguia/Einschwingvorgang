
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

// h(p,t) = [xd0]
//function simplest!(du,u,h,p,t)
//	hs = h(p,t-p[1])[1]
//	du[1] = hs*(1.0-hs*hs) - 0.2*u[1]
//end


(
Fb1_ODEdef(\delayed, { |t, y, tau = 0.1|
	var hs = // value of y[0] at t-tau
	[
		{ gs*(1-(hs*hs)) - (0.2*y[0]) }
	]
}, t0: 0, y0: [0]);
)
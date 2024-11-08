/*

polar coordinates (a coordinate system based on angle and magnitude)

*/



// Example of a phase space that is a single angle θ (theta) in polar coordinates
// the radius is 1 ("unity"), and we provide the angle in radians, i.e. 360° equals 2pi

// what is a point in polar coordinates?
p = Polar(rho: 0.5, theta:0.75); // define a position in polar coordinates: length 0.5 and angle 0.75

// for a 1-dimensional phase space, there is only one veriable, the angle theta. rho is always 1
p = Polar(rho: 1, theta:0.5pi); // length 1 and angle pi/2 which is 90°
p = Polar(rho: 1, theta:pi/3); // length 1 and angle pi/3
p.asPoint; // a point in cartesian coordinates
p.asPoint.x // the x coordinate, which is the cosine of theta, scaled by the length rho
p.asPoint.y // the y coordinate, which is the sine of theta, scaled by the length rho
p.asPoint.asArray // or both coordinates as an array

// polar coordinates can also be used in sound signals
// for an output, we need their coordinates, of course.
{ Polar(1, Sweep.ar * 2pi * 100).asPoint.asArray }.plot

// many possibilities come from interpreting the cartesian coordinates
// as complex numbers. You can read about them in Complex helpfile.






/*

wave shaping:

A dynamical system assigns to every point n the state space a derivative (a change of state in time)
In a circular system, that means we traverse the circle at different speeds.
This is similar to wave shaping.

*/


(
Ndef(\x, {
	var speed = LFSaw.ar(MouseX.kr(2, 200, 1));
	var theta = Integrator.ar(speed).wrap(0, 2pi); // accumulate to the position and wrap
	SinOsc.ar(0, theta) * 0.1;
}).play
)
s.scope.style_(1);

(
Ndef(\x, {
	// a more complicated speed pattern
	var speed = LFSaw.ar(MouseX.kr(2, 100, 1)) * LFSaw.ar(MouseY.kr(2, 600, 1)) * 3;
	var theta = Integrator.ar(speed).wrap(0, 2pi);
	SinOsc.ar(0, theta) * 0.1;
}).play
)

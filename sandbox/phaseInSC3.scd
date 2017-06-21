/*

Example code exploring specification of phase in SC3.

1) Array: phasor.cos, phasor.sin
2) Signal *sineFill
3) Signal -ifft
4) SinOsc
5) SinOsc & Hilbert
6) SinOsc & HilbertFIR
7) SinOsc & PV_PhaseShift
8) SinOsc, DelayN & PV_PhaseShift270
9) SinOsc, DelayN & -1 * PV_PhaseShift90
10) Weaver Quadrature Method - PV_BrickWall

Joseph Anderson, 2016

*/

// *** Welcome to SuperCollider 3.8.0. ***


// 1) Signal - phasor.cos, phasor.sin : direct evaluation of phase

(
var size;
var phasor;

size = 2048;

// generate phasor
phasor = Signal.newFrom(Array.series (size+1, 0, 2pi / (size+1)).copyRange(0, size));  // generate "wrap around" end point, then discard

// cos
phasor.cos.plot("1) Cosine - phasor.cos");

// sin
phasor.sin.plot("1) Sine - phasor.sin");
)


// 2) Signal *sineFill : sine basis function

(
var size;

size = 2048;

// cos
Signal.sineFill(size, [1.0], [pi/2]).plot("2) Cosine - Signal *sineFill");

// sin
Signal.sineFill(size, [1.0], [0.0]).plot("2) Sine - Signal *sineFill");
)


// 3) Signal -ifft
(
var size;
var cosTable;
var zeros, realForCos, imagForSin;

size = 2048;

cosTable = Signal.fftCosTable(size);
zeros = Signal.newClear(size);

// cos
realForCos = zeros;  // zeros
realForCos.put(1, 1).put(size-1, 1);  // assign coefficients
realForCos = size/2 * realForCos;  // scale

ifft(realForCos, zeros, cosTable).real.plot("3) Cosine - Signal -ifft");

// sin
imagForSin = zeros;  // zeros
imagForSin.put(1, -1).put(size-1, 1);  // assign coefficients
imagForSin = size/2 * imagForSin;  // scale

ifft(zeros, imagForSin, cosTable).real.plot("3) Sine - Signal -ifft");
)


/*

UGen examples below

*/

// boot server
// SC_AudioDriver: sample rate = 44100.000000, driver's block size = 512
s.boot;


// 4) SinOsc : sine basis function

(
var size;
var dur, freq;

size = 2048;

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

// cos
{ SinOsc.ar(freq, pi/2) }.loadToFloatArray(
	dur,
	s,
	{ arg arr;
		{ arr.plot("4) Cosine - SinOsc *ar"); }.defer;
	}
);

// sin
{ SinOsc.ar(freq, 0.0) }.loadToFloatArray(
	dur,
	s,
	{ arg arr;
		{ arr.plot("4) Sine - SinOsc *ar"); }.defer;
	}
);
)



// 5) SinOsc & Hilbert: sine basis function

/*
From the Help:

Returns two channels with the original signal and a copy of that signal that has been shifted in phase by 90 degrees (0.5 pi radians). Hilbert outputs two channels containing the input signal and the transformed signal. Due to the method used, distortion occurs in the upper octave of the frequency spectrum (See HilbertFIR for an FFT implementation that avoids this, but introduces a significant delay).

---
My Notes:

This is an oversimplied description of the Hilbert Transform, particularly in the implemented Phase Difference Network (PDN) context of this UGen.

See: "https://en.wikipedia.org/wiki/Hilbert_transform#Table_of_selected_Hilbert_transforms".openOS

and

See: "https://ccrma.stanford.edu/~jos/st/Analytic_Signals_Hilbert_Transform.html".openOS

Is best to describe returning a quadrature pair. Also, JOS states: Ideally, this filter has magnitude 1 at all frequencies and introduces a phase shift of -pi/2 at each positive frequency and +pi/2 at each negative frequency.

In practice this means a phase rotation of -pi/2 is introduced.

*/


// -at(1) has the least amount of pulse delay, implying this is the cos channel. I.e.,
// Hilbert *ar returns: [ sin, cos ]

(
var size;
var dur, freq;
var overSample, start;

size = 2048;
overSample = 4;
start = 2 * size + 781;  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

// cos
{ Hilbert.ar(SinOsc.ar(freq, pi/2)).at(1) }.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("5) Cosine - Hilbert *ar", minval: -1, maxval: 1);
		}.defer;
	}
);

// sin
{ Hilbert.ar(SinOsc.ar(freq, pi/2)).at(0) }.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("5) Sine - Hilbert *ar", minval: -1, maxval: 1);
		}.defer;
	}
);
)


// 6) SinOsc & HilbertFIR: sine basis function

/*
From the Help:

Returns two channels with the original signal and a copy of that signal that has been shifted in phase by 90 degrees (0.5 pi radians). HilbertFIR outputs two channels containing the input signal and the transformed signal. HilbertFIR uses FFTs and a 90 degree phase shift to transform the signal, and results in a delay equal to the size of the buffer used for the FFT divided by the sample rate. The Hilbert UGen has less delay, but distorts in the upper octave of the frequency spectrum.

---
My Notes:

This is an oversimplied description of the Hilbert Transform, particularly in the implemented FFT Phase Rotation context of this UGen.

See: "https://en.wikipedia.org/wiki/Hilbert_transform#Table_of_selected_Hilbert_transforms".openOS

and

See: "https://ccrma.stanford.edu/~jos/st/Analytic_Signals_Hilbert_Transform.html".openOS

Is best to describe returning a quadrature pair. Also, JOS states: Ideally, this filter has magnitude 1 at all frequencies and introduces a phase shift of -pi/2 at each positive frequency and +pi/2 at each negative frequency.

In practice this means a phase rotation of -pi/2 is introduced.

*/


// Hilbert *ar returns: [ cos, -sin ]
//
// NOTE: phase performance is very inconsistent! Do some more tests to make a more detailed assessment.

(
var size;
var dur, freq;
var overSample, start;

size = 2048;
overSample = 3;
start = 2 * size;  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

// cos
{ HilbertFIR.ar(SinOsc.ar(freq, pi/2), LocalBuf.new(size)).at(0) }.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("6) Cosine - HilbertFIR *ar", minval: -1, maxval: 1);
		}.defer;
	}
);

// sin
{ -1 * HilbertFIR.ar(SinOsc.ar(freq, pi/2), LocalBuf.new(size)).at(1) }.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("6) Sine - HilbertFIR *ar", minval: -1, maxval: 1);
		}.defer;
	}
);
)



// 7) SinOsc & PV_PhaseShift: sine basis function

/*
From the Help:

Returns two channels with the original signal and a copy of that signal that has been shifted in phase by 90 degrees (0.5 pi radians). HilbertFIR outputs two channels containing the input signal and the transformed signal. HilbertFIR uses FFTs and a 90 degree phase shift to transform the signal, and results in a delay equal to the size of the buffer used for the FFT divided by the sample rate. The Hilbert UGen has less delay, but distorts in the upper octave of the frequency spectrum.

---
My Notes:

This is an oversimplied description of the Hilbert Transform, particularly in the implemented FFT Phase Rotation context of this UGen.

See: "https://en.wikipedia.org/wiki/Hilbert_transform#Table_of_selected_Hilbert_transforms".openOS

and

See: "https://ccrma.stanford.edu/~jos/st/Analytic_Signals_Hilbert_Transform.html".openOS

Is best to describe returning a quadrature pair. Also, JOS states: Ideally, this filter has magnitude 1 at all frequencies and introduces a phase shift of -pi/2 at each positive frequency and +pi/2 at each negative frequency.

In practice this means a phase rotation of -pi/2 is introduced.

*/


// NOTE: phase performance is very inconsistent! Do some more tests to make a more detailed assessment.
//
// Sould return result similar to HilbertFIR
//
// See note for Method 9)


(
var size;
var dur, freq;
var overSample, start;

size = 2048;
overSample = 4;
// start = 3 * size - (2*s.options.blockSize);  // offset - to sync cycle  : for phase = -pi/2
start = 3 * size - (s.options.blockSize);  // offset - to sync cycle  : for phase = 0
// start = 3 * size;  // offset - to sync cycle  : for phase = pi/2

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

// cos
{
	IFFT.ar(
		PV_PhaseShift.new(
			FFT.new(
				LocalBuf.new(size),
				SinOsc.ar(freq, pi/2)
			), 0.0
		)
	)
}.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("7) Cosine - PV_PhaseShift *new", minval: -1, maxval: 1);
		}.defer;
	}
);

// sin
{
	IFFT.ar(
		PV_PhaseShift.new(
			FFT.new(
				LocalBuf.new(size),
				SinOsc.ar(freq, pi/2)
			), -pi/2
		)
	)
}.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("7) Sine - PV_PhaseShift *ar", minval: -1, maxval: 1);
		}.defer;
	}
);

// // sin
// {
// 	-1 * IFFT.ar(
// 		PV_PhaseShift.new(
// 			FFT.new(
// 				LocalBuf.new(size),
// 				SinOsc.ar(freq, pi/2)
// 			), pi/2
// 		)
// 	)
// }.loadToFloatArray(
// 	overSample * dur,
// 	s,
// 	{ arg arr;
// 		{
// 			arr = arr.copyRange(start, start+size);
// 			arr.plot("7) Sine - PV_PhaseShift *ar", minval: -1, maxval: 1);
// 		}.defer;
// 	}
// );
)


// 8) SinOsc, DelayN & PV_PhaseShift270: sine basis function

/*
From the Help:

Shift phase of all bins by 270 degrees.

---
My Notes:

This is an oversimplied description of the Hilbert Transform, particularly in the implemented FFT Phase Rotation context of this UGen.

See: "https://en.wikipedia.org/wiki/Hilbert_transform#Table_of_selected_Hilbert_transforms".openOS

and

See: "https://ccrma.stanford.edu/~jos/st/Analytic_Signals_Hilbert_Transform.html".openOS

Is best to describe returning a quadrature pair. Also, JOS states: Ideally, this filter has magnitude 1 at all frequencies and introduces a phase shift of -pi/2 at each positive frequency and +pi/2 at each negative frequency.

In practice this means a phase rotation of -pi/2 is introduced.

*/

// NOTE: phase performance is very inconsistent! Do some more tests to make a more detailed assessment.
//
// See note for Method 9)

(
var size;
var dur, freq;
var overSample, start;

size = 2048;
overSample = 4;
start = 3 * size  - (2*s.options.blockSize);  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

// cos
{
	DelayN.ar(
		SinOsc.ar(freq, pi/2),
		(size - (2*s.options.blockSize)) / s.sampleRate,
		(size - (2*s.options.blockSize)) / s.sampleRate
	)
}.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("8) Cosine - DelayN *new", minval: -1, maxval: 1);
		}.defer;
	}
);

// sin
{
	IFFT.ar(
		PV_PhaseShift270.new(
			FFT.new(
				LocalBuf.new(size),
				SinOsc.ar(freq, pi/2)
			)
		)
	)
}.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("8) Sine - PV_PhaseShift270 *ar", minval: -1, maxval: 1);
		}.defer;
	}
);
)


// 9) SinOsc, DelayN & -1 * PV_PhaseShift90: sine basis function

// NOTE: inconsistent phase performance between
//
//            - PV_PhaseShift90      : size
//            - PV_PhaseShift270    : size  - (2*s.options.blockSize)
//            - PV_PhaseShift          : VARIES as above, & size - (s.options.blockSize) for phase = 0
//
// Not surprisingly, values are not valid across the range. This is to be expected as our test signal is a single period near DC.

(
var size;
var dur, freq;
var overSample, start;

size = 2048;
overSample = 4;
start = 3 * size;  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

// cos
{
	DelayN.ar(
		SinOsc.ar(freq, pi/2),
		size / s.sampleRate,
		size / s.sampleRate
	)
}.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("9) Cosine - DelayN *new", minval: -1, maxval: 1);
		}.defer;
	}
);

// sin
{
	-1 * IFFT.ar(
		PV_PhaseShift90.new(
			FFT.new(
				LocalBuf.new(size),
				SinOsc.ar(freq, pi/2)
			)
		)
	)
}.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("9) Sine - -1 * PV_PhaseShift90 *ar", minval: -1, maxval: 1);
		}.defer;
	}
);
)



// 10) Weaver Quadrature Method - PV_BrickWall

// Well behaved phase response!

(
var size;
var dur, freq;
var overSample, start;

size = 2048;
overSample = 4;
start = 3 * size - s.options.blockSize;  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

// cos - Delay
{
	DelayN.ar(
		SinOsc.ar(freq, pi/2),
		(size - s.options.blockSize) / s.sampleRate,
		(size - s.options.blockSize) / s.sampleRate
	)
}.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("10) Cosine - DelayN *new", minval: -1, maxval: 1);
		}.defer;
	}
);

// // cos - direct Weaver
// {
// 	var quadOsc;
// 	// var cosPath, sinPath;
//
// 	quadOsc = SinOsc.ar(s.sampleRate/4, [pi/2, 0]);
//
// 	// explicit...
// 	Mix.new(
// 		Array.with(
// 			IFFT.ar(
// 				PV_BrickWall.new(
// 					FFT.new(
// 						LocalBuf.new(size),
// 						2 * SinOsc.ar(freq, pi/2) * quadOsc.at(0)
// 					),
// 					-0.5
// 				)
// 			),
// 			IFFT.ar(
// 				PV_BrickWall.new(
// 					FFT.new(
// 						LocalBuf.new(size),
// 						2 * SinOsc.ar(freq, pi/2) * quadOsc.at(1)
// 					),
// 					-0.5
// 				)
// 			)
// 		) * quadOsc
// 	)
// }.loadToFloatArray(
// 	overSample * dur,
// 	s,
// 	{ arg arr;
// 		{
// 			arr = arr.copyRange(start, start+size);
// 			arr.plot("Cosine - Weaver", minval: -1, maxval: 1);
// 		}.defer;
// 	}
// );

// sin
{
	var quadOsc;
	// var cosPath, sinPath;

	quadOsc = SinOsc.ar(s.sampleRate/4, [pi/2, 0]);

	// explicit...
	Mix.new(
		Array.with(
			IFFT.ar(
				PV_BrickWall.new(
					FFT.new(
						LocalBuf.new(size),
						2 * SinOsc.ar(freq, pi/2) * quadOsc.at(0)
					),
					-0.5
				)
			),
			IFFT.ar(
				PV_BrickWall.new(
					FFT.new(
						LocalBuf.new(size),
						2 * SinOsc.ar(freq, pi/2) * quadOsc.at(1)
					),
					-0.5
				)
			)
		) * Array.with(quadOsc.at(1), -1 * quadOsc.at(0))
	)
}.loadToFloatArray(
	overSample * dur,
	s,
	{ arg arr;
		{
			arr = arr.copyRange(start, start+size);
			arr.plot("10) Sine - Weaver", minval: -1, maxval: 1);
		}.defer;
	}
);
)

s.quit
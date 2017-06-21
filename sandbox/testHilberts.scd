/*

Example code exploring magnitude response of Hilbert implementation in SC3.

Test Magnitude response in the time domain with Quadrature sweeps.
- Unit response
- Hilbert response
- System response


1) LPF example
2) Hilbert *ar


Joseph Anderson, 2016

*/

// *** Welcome to SuperCollider 3.8.0. ***


/*

UGen examples below

*/

// boot server
// SC_AudioDriver: sample rate = 44100.000000, driver's block size = 512
s.boot;


// 1) Quadrature measure - LPF example

(
var numOctaves, sizeOctave;
var freq0, freq1;
var size, dur;
var mindb, maxdb;

// --
// parameters
numOctaves = 10.0;  // number of octaves to test
sizeOctave = 2048;  // number of samples per octave

mindb = -30.0;
maxdb = 5.0;


// --
// calcs
size = numOctaves * sizeOctave;  // in samples
dur = size / s.sampleRate;  // in seconds

freq1 = s.sampleRate / 2;  // nyquist
freq0 = freq1 * 2.pow(-1 * numOctaves);  // low freq


// --
// post
("sampleRate: " ++ s.sampleRate).postln;
"-------------------".postln;
("Freq0: " ++ freq0).postln;
("Freq1: " ++ freq1).postln;


// --
// generate / test

{
	var freqEnv, quadOsc;

	freqEnv = XLine.ar(freq0, freq1, dur);

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	// quadOsc.squared.sum;  // direct

	LPF.ar(quadOsc).squared.sum; // LPF

}.loadToFloatArray(
	dur,
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;

			arrdb.plot("1) Quadrature - magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);
)


// 2) Quadrature measure - Hilbert *ar

(
var numOctaves, sizeOctave;
var freq0, freq1;
var size, dur;
var mindb, maxdb;
var systemProbePhase;

// --
// parameters
numOctaves = 10.0;  // number of octaves to test
sizeOctave = 4096;  // number of samples per octave

mindb = -10.0;
maxdb = 5.0;

systemProbePhase = pi/2;  // cos
// systemProbePhase = 0.0;  // sin


// --
// calcs
size = numOctaves * sizeOctave;  // in samples
dur = size / s.sampleRate;  // in seconds

freq1 = s.sampleRate / 2;  // nyquist
freq0 = freq1 * 2.pow(-1 * numOctaves);  // low freq


// --
// post
("sampleRate: " ++ s.sampleRate).postln;
"-------------------".postln;
("Freq0: " ++ freq0).postln;
("Freq1: " ++ freq1).postln;


// --
// generate / test

// Unit
{
	var freqEnv, quadOsc;
	var out;

	freqEnv = XLine.ar(freq1, freq0, dur);  // sweep in reverse

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	out = Hilbert.ar(quadOsc);
	out = Array.with(out.at(0).at(1), out.at(1).at(1)).squared.sum;  // Unit is 2nd output!

}.loadToFloatArray(
	dur,
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse

			arrdb.plot("2a) Hilbert *ar: Unit Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);

// Hilbert
{
	var freqEnv, quadOsc;
	var out;

	freqEnv = XLine.ar(freq1, freq0, dur);  // sweep in reverse

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	out = Hilbert.ar(quadOsc);
	out = Array.with(out.at(0).at(0), out.at(1).at(0)).squared.sum;  // Hilbert is 1st output!

}.loadToFloatArray(
	dur,
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse

			arrdb.plot("2b) Hilbert *ar: Hilbert Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);


// System
{
	var freqEnv, probeOsc;
	var out;

	freqEnv = XLine.ar(freq1, freq0, dur);  // sweep in reverse

	probeOsc = SinOsc.ar(freqEnv, systemProbePhase);

	// Hilbert.ar(probeOsc).squared.sum; // Test complete system: [Hilbert, Unit]
	out = Hilbert.ar(probeOsc);
	out = out.squared.sum;  // Test complete system: [Hilbert, Unit]

}.loadToFloatArray(
	dur,
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse

			arrdb.plot("2c) Hilbert *ar: System Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);
)


// 3) Quadrature measure - HilbertFIR *ar
//
// Poor "system" response. Possibilities include:
//    - mismatched "unit" delay
//    - inconsistent phase response of "hilbert"

(
var numOctaves, sizeOctave;
var freq0, freq1;
var size, dur;
var mindb, maxdb;
var systemProbePhase;
var sizePV, sizePVDur;

// --
// parameters
numOctaves = 10.0;  // number of octaves to test
sizeOctave = 4096;  // number of samples per octave

mindb = -10.0;
maxdb = 5.0;

systemProbePhase = pi/2;  // cos
// systemProbePhase = 0.0;  // sin

sizePV = sizeOctave;  // HilbertFIR size -- REALLY, this is the FFT size for PV


// --
// calcs
size = numOctaves * sizeOctave;  // in samples
dur = size / s.sampleRate;  // in seconds
sizePVDur = sizePV / s.sampleRate;  // in seconds

freq1 = s.sampleRate / 2;  // nyquist
freq0 = freq1 * 2.pow(-1 * numOctaves);  // low freq


// --
// post
("sampleRate: " ++ s.sampleRate).postln;
"-------------------".postln;
("Freq0: " ++ freq0).postln;
("Freq1: " ++ freq1).postln;


// --
// generate / test

// Unit
{
	var freqEnv, quadOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	out = Array.with(
		HilbertFIR.ar(quadOsc.at(0), LocalBuf.new(sizePV)).at(0),
		HilbertFIR.ar(quadOsc.at(1), LocalBuf.new(sizePV)).at(0)
	).squared.sum;  // Unit is 1st output!

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("3a) HilbertFIR *ar: Unit Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);

// Hilbert
{
	var freqEnv, quadOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	out = Array.with(
		HilbertFIR.ar(quadOsc.at(0), LocalBuf.new(sizePV)).at(1),
		HilbertFIR.ar(quadOsc.at(1), LocalBuf.new(sizePV)).at(1)
	).squared.sum;  // Hilbert is 2nd output (* -1)!

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("3b) HilbertFIR *ar: Hilbert Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);


// System
{
	var freqEnv, probeOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	probeOsc = SinOsc.ar(freqEnv, systemProbePhase);

	out = HilbertFIR.ar(probeOsc, LocalBuf.new(sizePV));
	out = out.squared.sum;  // Test complete system: [Unit, -Hilbert]

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("2c) HilbertFIR *ar: System Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);
)


// 4) Quadrature measure - PV_PhaseShift *ar
//
// Much more acceptable "system" response. This suggests that the problem with HilbertFIR is
//    - mismatched "unit" delay
//
// Additionally, there could be a windowing effect that is normalized by using PV_PhaseShift @ 0.0 deg

(
var numOctaves, sizeOctave;
var freq0, freq1;
var size, dur;
var mindb, maxdb;
var systemProbePhase;
var sizePV, sizePVDur;

// --
// parameters
numOctaves = 10.0;  // number of octaves to test
sizeOctave = 4096;  // number of samples per octave

mindb = -10.0;
maxdb = 5.0;

systemProbePhase = pi/2;  // cos
// systemProbePhase = 0.0;  // sin

sizePV = sizeOctave;  // HilbertFIR size -- REALLY, this is the FFT size for PV


// --
// calcs
size = numOctaves * sizeOctave;  // in samples
dur = size / s.sampleRate;  // in seconds
sizePVDur = sizePV / s.sampleRate;  // in seconds

freq1 = s.sampleRate / 2;  // nyquist
freq0 = freq1 * 2.pow(-1 * numOctaves);  // low freq


// --
// post
("sampleRate: " ++ s.sampleRate).postln;
"-------------------".postln;
("Freq0: " ++ freq0).postln;
("Freq1: " ++ freq1).postln;


// --
// generate / test

// Unit
{
	var freqEnv, quadOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	out = Array.with(
		IFFT.ar(
			PV_PhaseShift.new(
				FFT.new(
					LocalBuf.new(sizePV),
					quadOsc.at(0)
				), 0.0
			)
		),
		IFFT.ar(
			PV_PhaseShift.new(
				FFT.new(
					LocalBuf.new(sizePV),
					quadOsc.at(1)
				), 0.0
			)
		)
	).squared.sum;  // Unit is phase = 0

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("4a) PV_PhaseShift *ar: Unit Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);

// Hilbert
{
	var freqEnv, quadOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	out = Array.with(
		IFFT.ar(
			PV_PhaseShift.new(
				FFT.new(
					LocalBuf.new(sizePV),
					quadOsc.at(0)
				// ), -90.degrad
				), 90.degrad  // HilbertFIR
			)
		),
		IFFT.ar(
			PV_PhaseShift.new(
				FFT.new(
					LocalBuf.new(sizePV),
					quadOsc.at(1)
				// ), -90.degrad
				), 90.degrad  // HilbertFIR
			)
		)
	).squared.sum;  // Hilbert is phase = -90

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("4b) PV_PhaseShift *ar: Hilbert Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);


// System
{
	var freqEnv, probeOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	probeOsc = SinOsc.ar(freqEnv, systemProbePhase);

	out = Array.with(
		IFFT.ar(
			PV_PhaseShift.new(
				FFT.new(
					LocalBuf.new(sizePV),
					probeOsc
				), 0.0  // Unit
			)
		),
		IFFT.ar(
			PV_PhaseShift.new(
				FFT.new(
					LocalBuf.new(sizePV),
					probeOsc
				// ), -90.degrad
				), 90.degrad  // HilbertFIR
			)
		)
	);
	out = out.squared.sum;  // Test complete system: [Unit, -Hilbert]

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("4c) PV_PhaseShift *ar: System Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);
)


// 5) Quadrature measure - PV_PhaseShift *ar & DelayN

(
var numOctaves, sizeOctave;
var freq0, freq1;
var size, dur;
var mindb, maxdb;
var systemProbePhase;
var sizePV, sizePVDur;

// --
// parameters
numOctaves = 10.0;  // number of octaves to test
sizeOctave = 4096;  // number of samples per octave

mindb = -10.0;
maxdb = 5.0;

systemProbePhase = pi/2;  // cos
// systemProbePhase = 0.0;  // sin

sizePV = sizeOctave;  // HilbertFIR size -- REALLY, this is the FFT size for PV


// --
// calcs
size = numOctaves * sizeOctave;  // in samples
dur = size / s.sampleRate;  // in seconds
sizePVDur = sizePV / s.sampleRate;  // in seconds

freq1 = s.sampleRate / 2;  // nyquist
freq0 = freq1 * 2.pow(-1 * numOctaves);  // low freq


// --
// post
("sampleRate: " ++ s.sampleRate).postln;
"-------------------".postln;
("Freq0: " ++ freq0).postln;
("Freq1: " ++ freq1).postln;


// --
// generate / test

// Unit
{
	var freqEnv, quadOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	out = Array.with(
		DelayN.ar(quadOsc.at(0), sizePVDur - (s.options.blockSize/s.sampleRate), sizePVDur - (s.options.blockSize/s.sampleRate)),
		DelayN.ar(quadOsc.at(1), sizePVDur - (s.options.blockSize/s.sampleRate), sizePVDur - (s.options.blockSize/s.sampleRate))
	).squared.sum;  // Unit is phase = 0

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("5a) DelanN *ar: Unit Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);

// Hilbert
{
	var freqEnv, quadOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	out = Array.with(
		IFFT.ar(
			PV_PhaseShift.new(
				FFT.new(
					LocalBuf.new(sizePV),
					quadOsc.at(0)
					), -90.degrad
				// ), 90.degrad  // HilbertFIR
			)
		)
		,
		IFFT.ar(
			PV_PhaseShift.new(
				FFT.new(
					LocalBuf.new(sizePV),
					quadOsc.at(1)
					), -90.degrad
			// ), 90.degrad  // HilbertFIR
			)
		)
	).squared.sum;  // Hilbert is phase = -90

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("5b) PV_PhaseShift *ar: Hilbert Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);


// System
{
	var freqEnv, probeOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	probeOsc = SinOsc.ar(freqEnv, systemProbePhase);

	out = Array.with(
		DelayN.ar(
			probeOsc,
			sizePVDur - (s.options.blockSize/s.sampleRate),
			sizePVDur - (s.options.blockSize/s.sampleRate)
		),
		IFFT.ar(
			PV_PhaseShift.new(
				FFT.new(
					LocalBuf.new(sizePV),
					probeOsc
					), -90.degrad
			// ), 90.degrad  // HilbertFIR
			)
		)
	);
	out = out.squared.sum;  // Test complete system: [Unit, Hilbert]

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("4c) PV_PhaseShift *ar: System Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);
)


// 6) Quadrature measure - Weaver method: PV_BrickWall *ar

(
var numOctaves, sizeOctave;
var freq0, freq1;
var size, dur;
var mindb, maxdb;
var systemProbePhase;
var sizePV, sizePVDur;

// --
// parameters
numOctaves = 10.0;  // number of octaves to test
sizeOctave = 4096;  // number of samples per octave

mindb = -10.0;
maxdb = 5.0;

systemProbePhase = pi/2;  // cos
// systemProbePhase = 0.0;  // sin

sizePV = sizeOctave;  // HilbertFIR size -- REALLY, this is the FFT size for PV


// --
// calcs
size = numOctaves * sizeOctave;  // in samples
dur = size / s.sampleRate;  // in seconds
sizePVDur = sizePV / s.sampleRate;  // in seconds

freq1 = s.sampleRate / 2;  // nyquist
freq0 = freq1 * 2.pow(-1 * numOctaves);  // low freq


// --
// post
("sampleRate: " ++ s.sampleRate).postln;
"-------------------".postln;
("Freq0: " ++ freq0).postln;
("Freq1: " ++ freq1).postln;


// --
// generate / test

// Unit
{
	var freqEnv, quadOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	out = Array.with(
		DelayN.ar(quadOsc.at(0), sizePVDur - (s.options.blockSize/s.sampleRate), sizePVDur - (s.options.blockSize/s.sampleRate)),
		DelayN.ar(quadOsc.at(1), sizePVDur - (s.options.blockSize/s.sampleRate), sizePVDur - (s.options.blockSize/s.sampleRate))
	).squared.sum;  // Unit is phase = 0

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("6a) DelanN *ar: Unit Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);

// Hilbert
{
	var freqEnv, quadOsc;
	var out;
	var weavQuadOsc;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);
	weavQuadOsc = SinOsc.ar(s.sampleRate/4, [pi/2, 0]);

	out = Array.with(
		Mix.new(
			Array.with(
				IFFT.ar(
					PV_BrickWall.new(
						FFT.new(
							LocalBuf.new(sizePV),
							2 * quadOsc.at(0) * weavQuadOsc.at(0)
						),
						-0.5
					)
				),
				IFFT.ar(
					PV_BrickWall.new(
						FFT.new(
							LocalBuf.new(sizePV),
							2 * quadOsc.at(0) * weavQuadOsc.at(1)
						),
						-0.5
					)
				)
			) * Array.with(weavQuadOsc.at(1), -1 * weavQuadOsc.at(0))
		),
		Mix.new(
			Array.with(
				IFFT.ar(
					PV_BrickWall.new(
						FFT.new(
							LocalBuf.new(sizePV),
							2 * quadOsc.at(1) * weavQuadOsc.at(0)
						),
						-0.5
					)
				),
				IFFT.ar(
					PV_BrickWall.new(
						FFT.new(
							LocalBuf.new(sizePV),
							2 * quadOsc.at(1) * weavQuadOsc.at(1)
						),
						-0.5
					)
				)
			) * Array.with(weavQuadOsc.at(1), -1 * weavQuadOsc.at(0))
		)
	);
	out = out.squared.sum

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("6b) Weaver PV_BrickWall *ar: Hilbert Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);


// System
{
	var freqEnv, probeOsc;
	var out;
	var weavQuadOsc;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay

	probeOsc = SinOsc.ar(freqEnv, systemProbePhase);
	weavQuadOsc = SinOsc.ar(s.sampleRate/4, [pi/2, 0]);

	out = Array.with(
		DelayN.ar(
			probeOsc,
			sizePVDur - (s.options.blockSize/s.sampleRate),
			sizePVDur - (s.options.blockSize/s.sampleRate)
		),
		Mix.new(
			Array.with(
				IFFT.ar(
					PV_BrickWall.new(
						FFT.new(
							LocalBuf.new(sizePV),
							2 * probeOsc * weavQuadOsc.at(0)
						),
						-0.5
					)
				),
				IFFT.ar(
					PV_BrickWall.new(
						FFT.new(
							LocalBuf.new(sizePV),
							2 * probeOsc * weavQuadOsc.at(1)
						),
						-0.5
					)
				)
			) * Array.with(weavQuadOsc.at(1), -1 * weavQuadOsc.at(0))
		)
	);
	out = out.squared.sum;  // Test complete system: [Unit, Hilbert]

}.loadToFloatArray(
	dur + sizePVDur,  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("6c) Weaver PV_BrickWall *ar: System Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);
)


// // 7) Quadrature measure - FIR method: Convolution2 *ar
// //
// // Will need to review and optimise the Hilbert kernel, in terms of Hann window and coeff generation.
// // This is just a "quick & dirty" implementation from Zolzer.
// // A better approach will be to start from first principles, reflecting a LP prototype about the 1/2 band.
//
// (
// var numOctaves, sizeOctave;
// var freq0, freq1;
// var size, dur;
// var mindb, maxdb;
// var systemProbePhase;
// var sizePV, sizePVDur;
//
// // --
// // parameters
// numOctaves = 10.0;  // number of octaves to test
// sizeOctave = 4096;  // number of samples per octave
//
// mindb = -10.0;
// maxdb = 5.0;
//
// systemProbePhase = pi/2;  // cos
// // systemProbePhase = 0.0;  // sin
//
// sizePV = sizeOctave;  // HilbertFIR size -- REALLY, this is the FFT size for PV
//
//
// // --
// // calcs
// size = numOctaves * sizeOctave;  // in samples
// dur = size / s.sampleRate;  // in seconds
// sizePVDur = sizePV / s.sampleRate;  // in seconds
//
// freq1 = s.sampleRate / 2;  // nyquist
// freq0 = freq1 * 2.pow(-1 * numOctaves);  // low freq
//
//
// // --
// // post
// ("sampleRate: " ++ s.sampleRate).postln;
// "-------------------".postln;
// ("Freq0: " ++ freq0).postln;
// ("Freq1: " ++ freq1).postln;
//
//
// // --
// // generate / test
//
// // Unit
// {
// 	var freqEnv, quadOsc;
// 	var out;
//
// 	freqEnv = Env.new([freq1, freq0, freq0], [dur, 1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)], 'exp').ar;  // sweep in reverse, compensate for delay
//
// 	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);
//
// 	out = Array.with(
// 		DelayN.ar(quadOsc.at(0), sizePVDur - (s.options.blockSize/s.sampleRate), sizePVDur - (s.options.blockSize/s.sampleRate)),
// 		DelayN.ar(quadOsc.at(1), sizePVDur - (s.options.blockSize/s.sampleRate), sizePVDur - (s.options.blockSize/s.sampleRate))
// 	).squared.sum;  // Unit is phase = 0
//
// }.loadToFloatArray(
// 	dur + (1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)),  // compensate for delay
// 	s,
// 	{ arg arr;
// 		{
// 			var arrdb;
//
// 			arrdb = arr.ampdb;  // convert to dB
// 			arrdb = arrdb.reverse;  // reverse
// 			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay
//
// 			arrdb.plot("7a) DelanN *ar: Unit Magnitude", minval: mindb, maxval: maxdb);
//
// 		}.defer;
// 	}
// );
//
// // Hilbert
// {
// 	var freqEnv, quadOsc;
// 	var out;
// 	var hilbertCoeffs, i, kernel_i;
//
// 	// functions
// 	hilbertCoeffs =  { arg size;
// 		var xReal, xImag, reflect, window, half_win;
//
// 		half_win = (size)/2;
// 		reflect = [0.0, 1.0].dup(size/2).flat;
//
// 		window = Signal.hanningWindow(size);
//
// 		// real response
// 		xReal = Array.fill(size, { 0.0 });
// 		xReal.put(half_win, 1.0);
//
// 		// imaginary response
// 		xImag = Array.series(size, half_win.neg, 1);
// 		xImag = xImag.collect({ arg i;
// 			(i == 0).if({ 1 }, { (1-cos(pi * i)) / (pi * i) })
// 		}) * window;
// 		xImag = xImag * reflect;
//
// 		// return
// 		[xReal, xImag]
// 	};
//
// 	// design hilbert coefficients
// 	i = hilbertCoeffs.(sizePV).at(1);
// 	// kernel_i = LocalBuf.new(sizePV, 1).set(i);
// 	kernel_i = LocalBuf.newFrom(i);
// 	// i.plot;
// 	// kernel_i.plot;
//
// 	freqEnv = Env.new([freq1, freq0, freq0], [dur, 1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)], 'exp').ar;  // sweep in reverse, compensate for delay
//
// 	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);
//
// 	// out = Array.with(
// 	// 	Convolution2.ar(quadOsc.at(0), kernel_i, framesize: sizePV),
// 	// 	Convolution2.ar(quadOsc.at(1), kernel_i, framesize: sizePV)
// 	// );
// 	out = Array.with(
// 		quadOsc.at(0),
// 		quadOsc.at(1)
// 	);
// 	out = out.squared.sum
//
// }.loadToFloatArray(
// 	dur + (1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)),  // compensate for delay
// 	s,
// 	{ arg arr;
// 		{
// 			var arrdb;
//
// 			arrdb = arr.ampdb;  // convert to dB
// 			arrdb = arrdb.reverse;  // reverse
// 			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay
//
// 			arrdb.plot("7b) Convolution2 *ar: Hilbert Magnitude", minval: mindb, maxval: maxdb);
//
// 		}.defer;
// 	}
// );
//
//
// // // System
// // {
// // 	var freqEnv, probeOsc;
// // 	var out;
// // 	var weavQuadOsc;
// //
// // 	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay
// //
// // 	probeOsc = SinOsc.ar(freqEnv, systemProbePhase);
// // 	weavQuadOsc = SinOsc.ar(s.sampleRate/4, [pi/2, 0]);
// //
// // 	out = Array.with(
// // 		DelayN.ar(
// // 			probeOsc,
// // 			sizePVDur - (s.options.blockSize/s.sampleRate),
// // 			sizePVDur - (s.options.blockSize/s.sampleRate)
// // 		),
// // 		Mix.new(
// // 			Array.with(
// // 				IFFT.ar(
// // 					PV_BrickWall.new(
// // 						FFT.new(
// // 							LocalBuf.new(sizePV),
// // 							2 * probeOsc * weavQuadOsc.at(0)
// // 						),
// // 						-0.5
// // 					)
// // 				),
// // 				IFFT.ar(
// // 					PV_BrickWall.new(
// // 						FFT.new(
// // 							LocalBuf.new(sizePV),
// // 							2 * probeOsc * weavQuadOsc.at(1)
// // 						),
// // 						-0.5
// // 					)
// // 				)
// // 			) * Array.with(weavQuadOsc.at(1), -1 * weavQuadOsc.at(0))
// // 		)
// // 	);
// // 	out = out.squared.sum;  // Test complete system: [Unit, Hilbert]
// //
// // }.loadToFloatArray(
// // 	dur + sizePVDur,  // compensate for delay
// // 	s,
// // 	{ arg arr;
// // 		{
// // 			var arrdb;
// //
// // 			arrdb = arr.ampdb;  // convert to dB
// // 			arrdb = arrdb.reverse;  // reverse
// // 			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay
// //
// // 			arrdb.plot("6c) Weaver PV_BrickWall *ar: System Magnitude", minval: mindb, maxval: maxdb);
// //
// // 		}.defer;
// // 	}
// // );
// )


// 7) Quadrature measure - FIR method: Convolution2 *ar
//
// Will need to review and optimise the Hilbert kernel, in terms of Hann window and coeff generation.
// This is just a "quick & dirty" implementation from Zolzer.
// A better approach will be to start from first principles, reflecting a LP prototype about the 1/2 band.

// HACK... Generate kernel "before time"


// create hilbert kernel (odd)

// functions
~hilbertCoeffs =  { arg size;
	var xReal, xImag, reflect, window, half_win;

	half_win = (size)/2;
	reflect = [0.0, 1.0].dup(size/2).flat;

	window = Signal.hanningWindow(size);

	// real response
	xReal = Array.fill(size, { 0.0 });
	xReal.put(half_win, 1.0);

	// imaginary response
	xImag = Array.series(size, half_win.neg, 1);
	xImag = xImag.collect({ arg i;
		(i == 0).if({ 1 }, { (1-cos(pi * i)) / (pi * i) })
	}) * window;
	xImag = xImag * reflect;

	// return
	[xReal, xImag]
};

// design hilbert coefficients
a = ~hilbertCoeffs.(4096).at(1);
a.plot;
b = Buffer.loadCollection(s, a);
b.plot;


(
var numOctaves, sizeOctave;
var freq0, freq1;
var size, dur;
var mindb, maxdb;
var systemProbePhase;
var sizePV, sizePVDur;

// --
// parameters
numOctaves = 10.0;  // number of octaves to test
sizeOctave = 4096;  // number of samples per octave

mindb = -10.0;
maxdb = 5.0;

systemProbePhase = pi/2;  // cos
// systemProbePhase = 0.0;  // sin

sizePV = sizeOctave;  // HilbertFIR size -- REALLY, this is the FFT size for PV


// --
// calcs
size = numOctaves * sizeOctave;  // in samples
dur = size / s.sampleRate;  // in seconds
sizePVDur = sizePV / s.sampleRate;  // in seconds

freq1 = s.sampleRate / 2;  // nyquist
freq0 = freq1 * 2.pow(-1 * numOctaves);  // low freq


// --
// post
("sampleRate: " ++ s.sampleRate).postln;
"-------------------".postln;
("Freq0: " ++ freq0).postln;
("Freq1: " ++ freq1).postln;


// --
// generate / test

// Unit
{
	var freqEnv, quadOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, 1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)], 'exp').ar;  // sweep in reverse, compensate for delay

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	out = Array.with(
		DelayN.ar(quadOsc.at(0), sizePVDur - (s.options.blockSize/s.sampleRate), sizePVDur - (s.options.blockSize/s.sampleRate)),
		DelayN.ar(quadOsc.at(1), sizePVDur - (s.options.blockSize/s.sampleRate), sizePVDur - (s.options.blockSize/s.sampleRate))
	).squared.sum;  // Unit is phase = 0

}.loadToFloatArray(
	dur + (1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)),  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("7a) DelanN *ar: Unit Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);

// Hilbert
{
	var freqEnv, quadOsc;
	var out;
	// var hilbertCoeffs, i, kernel_i;
	//
	// // functions
	// hilbertCoeffs =  { arg size;
	// 	var xReal, xImag, reflect, window, half_win;
	//
	// 	half_win = (size)/2;
	// 	reflect = [0.0, 1.0].dup(size/2).flat;
	//
	// 	window = Signal.hanningWindow(size);
	//
	// 	// real response
	// 	xReal = Array.fill(size, { 0.0 });
	// 	xReal.put(half_win, 1.0);
	//
	// 	// imaginary response
	// 	xImag = Array.series(size, half_win.neg, 1);
	// 	xImag = xImag.collect({ arg i;
	// 		(i == 0).if({ 1 }, { (1-cos(pi * i)) / (pi * i) })
	// 	}) * window;
	// 	xImag = xImag * reflect;
	//
	// 	// return
	// 	[xReal, xImag]
	// };
	//
	// // design hilbert coefficients
	// i = hilbertCoeffs.(sizePV).at(1);
	// // kernel_i = LocalBuf.new(sizePV, 1).set(i);
	// kernel_i = LocalBuf.newFrom(i);
	// // i.plot;
	// // kernel_i.plot;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, 1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)], 'exp').ar;  // sweep in reverse, compensate for delay

	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);

	// out = Array.with(
	// 	Convolution2.ar(quadOsc.at(0), kernel_i, framesize: sizePV),
	// 	Convolution2.ar(quadOsc.at(1), kernel_i, framesize: sizePV)
	// );
	// out = Array.with(
	// 	Convolution2.ar(quadOsc.at(0), LocalBuf.newFrom(a), framesize: sizePV),
	// 	Convolution2.ar(quadOsc.at(1), LocalBuf.newFrom(a), framesize: sizePV)
	// );
	out = Array.with(
		Convolution2.ar(quadOsc.at(0), b, framesize: sizePV),  // using "hard coded" buffer
		Convolution2.ar(quadOsc.at(1), b, framesize: sizePV)
	);
	// out = Array.with(
	// 	quadOsc.at(0),
	// 	quadOsc.at(1)
	// );
	out = out.squared.sum

}.loadToFloatArray(
	dur + (1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)),  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("7b) Convolution2 *ar: Hilbert Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);


// System
{
	var freqEnv, probeOsc;
	var out;

	freqEnv = Env.new([freq1, freq0, freq0], [dur, 1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)], 'exp').ar;  // sweep in reverse, compensate for delay

	probeOsc = SinOsc.ar(freqEnv, systemProbePhase);

	out = Array.with(
		DelayN.ar(
			probeOsc,
			1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate),
			1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)
		),
		Convolution2.ar(probeOsc, b, framesize: sizePV),  // using "hard coded" buffer
	);
	out = out.squared.sum;  // Test complete system: [Unit, Hilbert]

}.loadToFloatArray(
	dur + (1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)),  // compensate for delay
	s,
	{ arg arr;
		{
			var arrdb;

			arrdb = arr.ampdb;  // convert to dB
			arrdb = arrdb.reverse;  // reverse
			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

			arrdb.plot("7c) Convolution2 *ar: System Magnitude", minval: mindb, maxval: maxdb);

		}.defer;
	}
);
)


// // 7) Quadrature measure - FIR method: Convolution2 *ar
// //
// // Will need to review and optimise the Hilbert kernel, in terms of Hann window and coeff generation.
// // This is just a "quick & dirty" implementation from Zolzer.
// // A better approach will be to start from first principles, reflecting a LP prototype about the 1/2 band.
// //
// // TEST with HilbertConv to start with!!!
//
// (
// var numOctaves, sizeOctave;
// var freq0, freq1;
// var size, dur;
// var mindb, maxdb;
// var systemProbePhase;
// var sizePV, sizePVDur;
//
// // --
// // parameters
// numOctaves = 10.0;  // number of octaves to test
// sizeOctave = 4096;  // number of samples per octave
//
// mindb = -10.0;
// maxdb = 5.0;
//
// systemProbePhase = pi/2;  // cos
// // systemProbePhase = 0.0;  // sin
//
// sizePV = sizeOctave;  // HilbertFIR size -- REALLY, this is the FFT size for PV
//
//
// // --
// // calcs
// size = numOctaves * sizeOctave;  // in samples
// dur = size / s.sampleRate;  // in seconds
// sizePVDur = sizePV / s.sampleRate;  // in seconds
//
// freq1 = s.sampleRate / 2;  // nyquist
// freq0 = freq1 * 2.pow(-1 * numOctaves);  // low freq
//
//
// // --
// // post
// ("sampleRate: " ++ s.sampleRate).postln;
// "-------------------".postln;
// ("Freq0: " ++ freq0).postln;
// ("Freq1: " ++ freq1).postln;
//
//
// // --
// // generate / test
//
// // Unit
// {
// 	var freqEnv, quadOsc;
// 	var out;
//
// 	freqEnv = Env.new([freq1, freq0, freq0], [dur, 1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)], 'exp').ar;  // sweep in reverse, compensate for delay
//
// 	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);
//
// 	// out = Array.with(
// 	// 	DelayN.ar(quadOsc.at(0), sizePVDur - (s.options.blockSize/s.sampleRate), sizePVDur - (s.options.blockSize/s.sampleRate)),
// 	// 	DelayN.ar(quadOsc.at(1), sizePVDur - (s.options.blockSize/s.sampleRate), sizePVDur - (s.options.blockSize/s.sampleRate))
// 	// ).squared.sum;  // Unit is phase = 0
//
// 	out = Array.with(
// 		HilbertConv.ar(quadOsc.at(0), sizePV).at(0),
// 		HilbertConv.ar(quadOsc.at(1), sizePV).at(0)
// 	).squared.sum;  // Unit is phase = 0
// 	// out = quadOsc.squared.sum;
//
// }.loadToFloatArray(
// 	dur + (1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)),  // compensate for delay
// 	s,
// 	{ arg arr;
// 		{
// 			var arrdb;
//
// 			arrdb = arr.ampdb;  // convert to dB
// 			arrdb = arrdb.reverse;  // reverse
// 			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay
//
// 			arrdb.plot("7a) DelanN *ar: Unit Magnitude", minval: mindb, maxval: maxdb);
//
// 		}.defer;
// 	}
// );
//
// // // Hilbert
// // {
// // 	var freqEnv, quadOsc;
// // 	var out;
// // 	var hilbertCoeffs, i, kernel_i;
// //
// // 	// functions
// // 	hilbertCoeffs =  { arg size;
// // 		var xReal, xImag, reflect, window, half_win;
// //
// // 		half_win = (size)/2;
// // 		reflect = [0.0, 1.0].dup(size/2).flat;
// //
// // 		window = Signal.hanningWindow(size);
// //
// // 		// real response
// // 		xReal = Array.fill(size, { 0.0 });
// // 		xReal.put(half_win, 1.0);
// //
// // 		// imaginary response
// // 		xImag = Array.series(size, half_win.neg, 1);
// // 		xImag = xImag.collect({ arg i;
// // 			(i == 0).if({ 1 }, { (1-cos(pi * i)) / (pi * i) })
// // 		}) * window;
// // 		xImag = xImag * reflect;
// //
// // 		// return
// // 		[xReal, xImag]
// // 	};
// //
// // 	// design hilbert coefficients
// // 	i = hilbertCoeffs.(sizePV).at(1);
// // 	// kernel_i = LocalBuf.new(sizePV, 1).set(i);
// // 	kernel_i = LocalBuf.newFrom(i);
// // 	// i.plot;
// // 	// kernel_i.plot;
// //
// // 	freqEnv = Env.new([freq1, freq0, freq0], [dur, 1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)], 'exp').ar;  // sweep in reverse, compensate for delay
// //
// // 	quadOsc = SinOsc.ar(freqEnv, [pi/2, 0.0]);
// //
// // 	// out = Array.with(
// // 	// 	Convolution2.ar(quadOsc.at(0), kernel_i, framesize: sizePV),
// // 	// 	Convolution2.ar(quadOsc.at(1), kernel_i, framesize: sizePV)
// // 	// );
// // 	out = Array.with(
// // 		quadOsc.at(0),
// // 		quadOsc.at(1)
// // 	);
// // 	out = out.squared.sum
// //
// // }.loadToFloatArray(
// // 	dur + (1.5 * sizePVDur  - (s.options.blockSize/s.sampleRate)),  // compensate for delay
// // 	s,
// // 	{ arg arr;
// // 		{
// // 			var arrdb;
// //
// // 			arrdb = arr.ampdb;  // convert to dB
// // 			arrdb = arrdb.reverse;  // reverse
// // 			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay
// //
// // 			arrdb.plot("7b) Convolution2 *ar: Hilbert Magnitude", minval: mindb, maxval: maxdb);
// //
// // 		}.defer;
// // 	}
// // );
//
//
// // // System
// // {
// // 	var freqEnv, probeOsc;
// // 	var out;
// // 	var weavQuadOsc;
// //
// // 	freqEnv = Env.new([freq1, freq0, freq0], [dur, sizePVDur], 'exp').ar;  // sweep in reverse, compensate for delay
// //
// // 	probeOsc = SinOsc.ar(freqEnv, systemProbePhase);
// // 	weavQuadOsc = SinOsc.ar(s.sampleRate/4, [pi/2, 0]);
// //
// // 	out = Array.with(
// // 		DelayN.ar(
// // 			probeOsc,
// // 			sizePVDur - (s.options.blockSize/s.sampleRate),
// // 			sizePVDur - (s.options.blockSize/s.sampleRate)
// // 		),
// // 		Mix.new(
// // 			Array.with(
// // 				IFFT.ar(
// // 					PV_BrickWall.new(
// // 						FFT.new(
// // 							LocalBuf.new(sizePV),
// // 							2 * probeOsc * weavQuadOsc.at(0)
// // 						),
// // 						-0.5
// // 					)
// // 				),
// // 				IFFT.ar(
// // 					PV_BrickWall.new(
// // 						FFT.new(
// // 							LocalBuf.new(sizePV),
// // 							2 * probeOsc * weavQuadOsc.at(1)
// // 						),
// // 						-0.5
// // 					)
// // 				)
// // 			) * Array.with(weavQuadOsc.at(1), -1 * weavQuadOsc.at(0))
// // 		)
// // 	);
// // 	out = out.squared.sum;  // Test complete system: [Unit, Hilbert]
// //
// // }.loadToFloatArray(
// // 	dur + sizePVDur,  // compensate for delay
// // 	s,
// // 	{ arg arr;
// // 		{
// // 			var arrdb;
// //
// // 			arrdb = arr.ampdb;  // convert to dB
// // 			arrdb = arrdb.reverse;  // reverse
// // 			arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay
// //
// // 			arrdb.plot("6c) Weaver PV_BrickWall *ar: System Magnitude", minval: mindb, maxval: maxdb);
// //
// // 		}.defer;
// // 	}
// // );
// )

s.quit
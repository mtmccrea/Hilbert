// test magnitude response of the new Hilberts

// TODO: need to clean up!  Confirm correct delays, etc...

(
var numOctaves, sizeOctave;
var freq0, freq1;
var size, dur;
var mindb, maxdb;
var systemProbePhase;
var sizePV, sizePVDur;
var del;

// --
// parameters
numOctaves = 10.0;  // number of octaves to test
sizeOctave = 4096;  // number of samples per octave

mindb = -10.0;
maxdb = 5.0;

systemProbePhase = pi/2;  // cos
// systemProbePhase = 0.0;  // sin

sizePV = sizeOctave;

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

fork({

	// System: HilbertW

	del = (sizePV - s.options.blockSize) / s.sampleRate;
	("Delay, HilbertW (fft): " ++ del).postln;

	{
		var freqEnv, probeOsc;
		var out;

		freqEnv = Env.new([freq1, freq0, freq0], [dur, del], 'exp').ar;  // sweep in reverse, compensate for delay

		probeOsc = SinOsc.ar(freqEnv, systemProbePhase);

		out = HilbertW.ar(probeOsc, size: sizePV);
		out = out.squared.sum;  // Test complete system: [Unit, Hilbert]

	}.loadToFloatArray(
		dur + del,  // compensate for delay
		s,
		{ arg arr;
			{
				var arrdb;

				arrdb = arr.ampdb;  // convert to dB
				arrdb = arrdb.reverse;  // reverse
				arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

				arrdb.plot("HilbertW (fft): System Magnitude", minval: mindb, maxval: maxdb);

			}.defer;
		}
	);

	1.wait;

	// System: HilbertH

	del = (sizePV - 1) / 2 + sizePV - s.options.blockSize / s.sampleRate;
	("Delay, HilbertH (FIR): " ++ del).postln;

	{
		var freqEnv, probeOsc;
		var out;

		freqEnv = Env.new([freq1, freq0, freq0], [dur, del], 'exp').ar;  // sweep in reverse, compensate for delay

		probeOsc = SinOsc.ar(freqEnv, systemProbePhase);

		out = HilbertH.ar(probeOsc, size: sizePV);
		out = out.squared.sum;  // Test complete system: [Unit, Hilbert]

	}.loadToFloatArray(
		dur + del,  // compensate for delay
		s,
		{ arg arr;
			{
				var arrdb;

				arrdb = arr.ampdb;  // convert to dB
				arrdb = arrdb.reverse;  // reverse
				arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

				arrdb.plot("HilbertH (FIR): System Magnitude", minval: mindb, maxval: maxdb);

			}.defer;
		}
	);

	1.wait;

	// System: HilbertPDN

	del = 0;
	("Delay, HilbertPDN (IIR): " ++ del).postln;

	{
		var freqEnv, probeOsc;
		var out;

		freqEnv = Env.new([freq1, freq0, freq0], [dur, del], 'exp').ar;  // sweep in reverse, compensate for delay

		probeOsc = SinOsc.ar(freqEnv, systemProbePhase);

		out = HilbertPDN.ar(probeOsc);
		out = out.squared.sum;  // Test complete system: [Unit, Hilbert]

	}.loadToFloatArray(
		dur + del,  // compensate for delay
		s,
		{ arg arr;
			{
				var arrdb;

				arrdb = arr.ampdb;  // convert to dB
				arrdb = arrdb.reverse;  // reverse
				arrdb = arrdb.copyFromStart(size.asInt - 1);  // compensate for delay

				arrdb.plot("HilbertPDN (IIR): System Magnitude", minval: mindb, maxval: maxdb);

			}.defer;
		}
	);

}, AppClock);
)
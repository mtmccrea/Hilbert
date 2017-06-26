/*
		TEST Weaver : HilbertWRe, HilbertWIm, HilbertW
*/

(
var size, dur, freq;
var overSample, start;

size = 2048;
overSample = 8;
start = 7 * size - s.options.blockSize;  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

{ // real
	HilbertWRe.ar(
		SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		size: size);
}.loadToFloatArray(overSample * dur, s, {
	|arr|
	defer {
		arr = arr.copyRange(start, start+size);
		arr.plot("Real; HilbertWRe; Cosine input", minval: -1, maxval: 1);
	}
}
);

{ // imaginary
	HilbertWIm.ar(
		SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		size: size);
}.loadToFloatArray(overSample * dur, s, {
	|arr|
	defer {
		arr = arr.copyRange(start, start+size);
		arr.plot("Imag; HilbertWIm; Cosine input", minval: -1, maxval: 1);
	}
}
);

{ // [real,imag]
	HilbertW.ar(
		SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		size: size);
}.loadToFloatArray(overSample * dur, s, {
	|arr|
	defer {
		arr = arr.clump(2).flop; // de-interleave
		arr = arr.collect(_.copyRange(start, start+size));
		arr.plot("[real, imag]; HilbertW; Cosine input", minval: -1, maxval: 1);
	}
}
);
)



/*
			TEST PDN : HilbertPDN.ar (FOS), HilbertPDN.ar1 (SOS)
*/

// TODO:
// it appears the sin/cos parts are reversed or the imaginary part has its phase inverted
// extract coef calculation to class method?
// offer just FOS or SOS version?
// separate into Re and Im versions like the other 2 implementations?

(
fork {
	var dur, freq, period;
	var overSample, start, plotdur, plotcycles;

	// freq = s.sampleRate/256;
	// freq = 4000;
	freq = 20;
	period = freq.reciprocal;
	overSample = 5; // how many cycles to capture
	start = (4 * period * s.sampleRate).asInt -1;  // offset - to sync cycle, start of plot
	dur = period * overSample;  // duration of capture, in seconds
	plotcycles = 1;
	plotdur = (period * s.sampleRate).asInt * plotcycles;

	{ // [real,imag]
		HilbertPDN.ar(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		);
	}.loadToFloatArray(dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+plotdur));
			arr.plot(format("[real, imag]; HilbertPDN.ar (FOS); Cosine input % Hz", freq), minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // [real,imag]
		HilbertPDN.ar1(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		);
	}.loadToFloatArray(dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+plotdur));
			arr.plot(format("[real, imag]; HilbertPDN.ar1 (SOS); Cosine input % Hz", freq), minval: -1, maxval: 1);
		}
	}
	);
}
)





/*
		TEST Hartley : HilbertHRe, HilbertHIm, HilbertH
*/

(
var size, dur, freq;
var overSample, start;

size = 2048;
overSample = 8;
// plot: jump to the 5th cycle, offset further to account for the delay of Convolution2
start = 5 * size + (((size - 1) / 2).floor).asInt + size - s.options.blockSize;  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

fork {
	{ // real
		HilbertHRe.ar(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size);
			arr.plot("Real; HilbertHRe; Cosine input", minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // imaginary
		HilbertHIm.ar(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size);
			arr.plot("Imag; HilbertHIm; Cosine input", minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // [real,imag]
		// HilbertH.ar( // all-in-one calculation of coefficients
		HilbertH.ar( // aggregating HilbertHRe and HilbertHIm
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size));
			arr.plot("[real, imag]; HilbertH; Cosine input", minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // [real (convolution), real (delayed)]
		var sig = SinOsc.ar(freq, pi/2); // cosine test, one cycle over fftbuffer size
		[
			HilbertHRe.arConv(sig, size),
			HilbertHRe.ar(sig, size)
		]
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size));
			arr.plot("[real (convolution), real (delayed)]; HilbertHRe; Cosine input", minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // difference between [real (delayed), real (convolution)]
		var sig = SinOsc.ar(freq, pi/2); // cosine test, one cycle over fftbuffer size
		HilbertHRe.ar(sig, size) - HilbertHRe.arConv(sig, size)
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size);
			arr.plot("difference between [real (delayed), real (convolution)]");
		}
	}
	);
}
)



/*   SCRATCH    */
(
p = CtkProtoNotes(

	// WEAVERs

	SynthDef(\weav, {arg outbus=2, freq=2000;
		var sig, h;
		sig = SinOsc.ar(freq, pi/2);  // cosine test
		h = HilbertW.ar(sig, size: 2048);
		Out.ar(outbus, h);
	}),

	SynthDef(\weavRe, {arg outbus=2, freq=2000;
		var sig, h;
		sig = SinOsc.ar(freq, pi/2);  // cosine test
		h = HilbertWRe.ar(sig, size: 2048);
		Out.ar(outbus, h);
	}),
	SynthDef(\weavIm, {arg outbus=2, freq=2000;
		var sig, h;
		sig = SinOsc.ar(freq, pi/2);  // cosine test
		h = HilbertWIm.ar(sig, size: 2048);
		Out.ar(outbus, h);
	})

)
)

// play to this bus to observe
~out = CtkAudio.play(2);

s.scope(2, ~out.busnum)

// weaver
x = p[\weav].note.outbus_(~out).play


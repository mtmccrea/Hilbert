// Single-sideband modulation with carrier using the Hilber quark

(
d = SynthDef(\ssblow, { |out=2, frq=1000, shft=10000, carAmp=1, amp=1|
    Out.ar( out,
        HilbertH.arSSB(
        // HilbertW.arSSB(
            Mix.ar(5.collect{|i| SinOsc.ar(frq * i + 1000, mul: 5.reciprocal * (i+1).reciprocal)}) + carAmp,
            freq: shft,
            size: 2048,
            mul: amp,
            // add: carAmp
        )
    )
}).add
)
x  = Synth(\ssblow)
x.set(\shft, 20000) // upper sidebands
x.set(\shft, -20000) // lower sidebands
x.set(\carAmp, -0.dbamp) // full carrier frequency
x.set(\carAmp, -300.dbamp) // remove carrier frequency

s.freqscope


// For Hilbert Help files
/*
        Sideband control: upper and lower bands
*/

// Build simple spectrum with a rolloff to shift in frequency
(
d = SynthDef(\help_HilbertPDN_ssb, { |out=0, frq=1000, shft=5000, amp=1|
    var sig;
    sig = Mix.ar(
        5.collect{|i|
            SinOsc.ar(frq * (i+1), mul: 5.reciprocal * (i+1).reciprocal)
        }
    );

    Out.ar( out,
        HilbertPDN.arSSB(
            sig,
            freq: shft,
            mul: amp,
        )
    )
}).add
)

// Play the synth to a bus
b = Bus.audio(s, 1);
x = Synth(\help_HilbertPDN_ssb, [\out, b.index, \frq, 400, \shft, 3000, \amp, 0.5]);

// View the spectrum
f = s.freqscope();
f.scope.inBus_(b.index);

x.set(\shft, -3000);    // lower sidebands: negative freqency shift
x.set(\shft, 3000);     // upper sidebands

// Cleanup
[x, b].do(_.free); f.window.close;


/*
        TEST Hartley : *arSSB

        single cosine cycle: period = size
*/
(
var size, dur, freq, harmonics;
var overSample, start;

size = 2048;
overSample = 4;
// plot: jump to the 2nd cycle, to account for "warm up" of Im kernel
start = 2 * size + ((size/ 2).floor).asInt - s.options.blockSize;  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

harmonics = 8;  // number of harmonics to SSB

{
    harmonics.do(
        { arg hNum;
            var ssbFreq;

            ssbFreq = hNum * freq;

            { // frequency shifting
                HilbertH.arSSB(
                    SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
                    ssbFreq,
                    size: size);
            }.loadToFloatArray(overSample * dur, s, {
                |arr|
                defer {
                    arr = arr.copyRange(start, start+size-1);
                    arr.plot(format("HilbertH *arSSB; Freq = % Hz", ssbFreq), minval: -1, maxval: 1);
                }
            }
            );

            0.5.wait;
        }
    )
}.fork
)
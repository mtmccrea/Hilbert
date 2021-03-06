/*
	Copyright Joseph Anderson and Michael McCrea, 2017
		J Anderson	j.anderson[at]ambisonictoolkit.net
		M McCrea		mtm5@uw.edu

	This file is part of the Hilbert quark for SuperCollider 3 and is free software:
	you can redistribute it and/or modify it under the terms of the GNU General
	Public License as published by the Free Software Foundation, either version 3
	of the License, or (at your option) any later version.

	This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
	without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	See the GNU General Public License for more details.
	<http://www.gnu.org/licenses/>.
*/


//---------------------------------------------------------------------
//	Various implementations of the Hilbert transform.
//
// ::Classes::
// Weaver method:
// HilbertW
// HilbertWRe
// HilbertWIm
//
// Harley method:
// HilbertH
// HilbertHRe
// HilbertHIm
//
// Phase Delay Network (PDN) method:
// HilbertPDN
// HilbertPDNRe
// HilbertPDNIm
//
//---------------------------------------------------------------------



/*
Hilbert transform - Weaver quadrature method
Well-behaved phase response.
Uses PV_BrickWall and is therefore delayed by:
(size - s.options.blockSize) / s.sampleRate
Real and imaginary components can be accessed independently using
HilbertWRe and HilbertWIm, respectively.
*/

HilbertW {

	*ar { |in, size = 2048, mul = 1, add = 0.0|

		^[
			HilbertWRe.ar(in, size, mul, add),
			HilbertWIm.ar(in, size, mul, add),
		]

	}
}

HilbertWRe {

	*ar { |in, size = 2048, mul = 1, add = 0.0|
		var del = (size - BlockSize.ir) / SampleRate.ir;
		^DelayN.ar(in, del, del, mul, add)
	}
}

HilbertWIm {

	*ar { |in, size = 2048, mul = 1, add = 0.0|
		var nyqDiv2, cos, sin, inputDbl, sinBr, cosBr, out;

		// quadrature oscillators at nyquist/2
		nyqDiv2 = SampleRate.ir/4;
		cos = SinOsc.ar(nyqDiv2, pi/2);
		sin = SinOsc.ar(nyqDiv2, 0);
		inputDbl = in * 2;

		// cosine and sine branches using brickwall for lowpass at nyquist/2
		cosBr = IFFT.ar(
			PV_BrickWall(
				FFT(
					LocalBuf(size),
					inputDbl * cos
				),
				-0.5
			)
		);

		sinBr = IFFT.ar(
			PV_BrickWall(
				FFT(
					LocalBuf(size),
					inputDbl * sin
				),
				-0.5
			)
		);

		// modulate and sum
		out = ([cosBr, sinBr] * [sin, cos.neg]).sum
		^(mul * (add + out))
	}
}




/*
Hilbert transform - Hartley method

Uses an FIR filter with Convolution2.ar and is therefore delayed by:
(size - 1) / 2 + size - s.options.blockSize
*/

HilbertH {

	// // all-in-one
	// *ar { arg in, size=2048, mul=1.0, add=0.0;
	// 	var kernel_r, kernel_i;
	// 	var hilbertCoeffs, r, i, real, imag;
	//
	// 	hilbertCoeffs =  { |size|
	// 		var xReal, xImag, reflect, window, half_win, arr;
	//
	// 		half_win = (size-1)/2;
	// 		reflect = [1.0, -1.0].dup(size/2).flat;
	// 		window = Signal.hanningWindow(size);
	//
	// 		// real response
	// 		xReal = Array.series(size, half_win.neg, 1);
	// 		xReal = xReal.collect({|i| (i == 0).if({ 1 }, { sin(pi * i) / (pi * i) }) }) * window;
	//
	// 		// imaginary response
	// 		xImag = xReal * reflect;
	// 		[xReal, xImag]
	// 	};
	//
	// 	#r, i = hilbertCoeffs.(size);
	//
	// 	kernel_r = LocalBuf(size, 1).set(r);
	// 	kernel_i = LocalBuf(size, 1).set(i);
	//
	// 	#real, imag = Convolution2.ar(in, [kernel_r, kernel_i], framesize: size, mul: mul, add: add);
	//
	// 	^[ real, imag ]
	// }

	// alternate
	*ar { |in, size=2048, mul=1.0, add=0.0|
		var r, kernel_r, real;

		^[
			HilbertHRe.ar(in, size, mul, add),
			HilbertHIm.ar(in, size, mul, add)
		]

	}

	*calcRealCoeffs { |size|
		var half_win, window, xReal;

		half_win = (size-1)/2;
		window = Signal.hanningWindow(size);

		// real response
		xReal = Array.series(size, half_win.neg, 1);
		^xReal.collect({|i| (i == 0).if({ 1 }, { sin(pi * i) / (pi * i) }) }) * window;
	}

	*calcImagCoeffs { |size, realCoeffs|
		var reflect;

		realCoeffs ?? {Error("realCoeffs not provided. You can generate them with HilbertH.calcRealCoeffs").throw};

		reflect = [1.0, -1.0].dup(size/2).flat;
		^realCoeffs * reflect;
	}
}

HilbertHRe {

	*ar { |in, size=2048, mul=1.0, add=0.0|
		var delay;

		delay = (size-1)/2 + size-BlockSize.ir;
		delay = delay / SampleRate.ir;

		// delay will be exactly between samples, so DelayL is OK
		// compared to generating the real component with
		// the convolution method, the difference in signal is ~120dB
		^DelayL.ar(in, delay, delay, mul, add);
	}

	// if identical signal paths are preferred
	// between real and imaginary parts, at the expense of an
	// extra convolution
	*arConv { |in, size=2048, mul=1.0, add=0.0|
		var r, kernel_r;

		r = HilbertH.calcRealCoeffs(size);
		kernel_r = LocalBuf(size, 1).set(r);

		^Convolution2.ar(in, kernel_r, framesize: size, mul: mul, add: add);
	}

}


HilbertHIm {
	*ar {
		| in, size=2048, mul=1.0, add=0.0 |
		var r, i, kernel_i, image;

		r = HilbertH.calcRealCoeffs(size);
		i = HilbertH.calcImagCoeffs(size, r);
		kernel_i = LocalBuf(size, 1).set(i);

		^Convolution2.ar(in, kernel_i, framesize: size, mul: mul, add: add);
	}
}


/*
Hilbert transform - Phase Difference Network (PDN), IIR
a 12 pole (6 per side) Hilbert IIR filter
based on Sean Costello and Bernie Hutchins
created by jl anderson - 7 jan 2001
*/

HilbertPDN {

	// Using first order sections.
	*ar { |in, mul = 1.0, add = 0.0|
		var numPoles, poles, gammas, coefs;
		var hilbertCos, hilbertSin;
		var out;

		// values taken from Bernie Hutchins, "Musical Engineer's Handbook"
		numPoles = 12;
		poles = [
			0.3609, 2.7412, 11.1573, 44.7581, 179.6242, 798.4578,
			1.2524, 5.5671, 22.3423, 89.6271, 364.7914, 2770.1114
		];
		gammas = (15.0 * pi / SampleRate.ir) * poles;

		coefs = [];
		numPoles.do({ arg i;
			coefs = coefs.add((gammas.at(i)-1)/(gammas.at(i)+1))
		});

		// Cos and Sin - not the prettiest - but it works!!!
		hilbertCos = in;
		numPoles.div(2).do({ arg i;
			hilbertCos = FOS.ar(hilbertCos, coefs.at(i), 1.0, coefs.at(i).neg)
		});
		hilbertSin = in;
		numPoles.div(2).do({ arg i;
			hilbertSin = FOS.ar(hilbertSin, coefs.at(i+6), 1.0, coefs.at(i+6).neg)
		});

		^( mul * ( add + [ hilbertCos, hilbertSin ] ) )
	}

	// Using second order sections.
	// long form
	*ar1 { |in, mul = 1.0, add = 0.0|

		var numPoles, poles, gammas, coefs, b1, b2;
		var hilbertCos, hilbertSin;
		var out;

		// values taken from Bernie Hutchins, "Musical Engineer's Handbook"
		// also found in Electronotes #43
		numPoles = 12;
		// pole values are grouped in a strange order, to allow for easy
		// generation of the second order coefficients
		poles = [
			0.3609, 798.4578, 2.7412, 179.6242, 11.1573, 44.7581,
			1.2524, 2770.1114, 5.5671, 364.7914, 22.3423, 89.6271
		];
		// math for bilinear transform of pole coefficients for 1st order allpass filters
		gammas = (15.0 * pi / SampleRate.ir) * poles;

		coefs = [];
		numPoles.do({ arg i;
			coefs = coefs.add((gammas.at(i)-1)/(gammas.at(i)+1))
		});

		// 1st order allpass filters coefs are grouped into coefs for 2nd order sections
		b1 = [];
		b2 = [];
		numPoles.div(2).do({ arg i;
			b1 = b1.add(coefs.at(2*i) + coefs.at((2*i)+1));
			b2 = b2.add(coefs.at(2*i) * coefs.at((2*i)+1));
		});

		// Cos and Sin - not the prettiest - but it works!!!
		hilbertCos = in;
		numPoles.div(4).do({ arg i;
			hilbertCos = SOS.ar(hilbertCos, b2.at(i), b1.at(i), 1.0, b1.at(i).neg, b2.at(i).neg)
		});
		hilbertSin = in;
		numPoles.div(4).do({ arg i;
			hilbertSin = SOS.ar(hilbertSin, b2.at(i+3), b1.at(i+3), 1.0, b1.at(i+3).neg, b2.at(i+3).neg)
		});

		^( mul * ( add + [ hilbertCos, hilbertSin ] ) )
	}

	// refactored form of *ar1 (SOS)
	*ar2 { |in, mul = 1.0, add = 0.0|
		^[
			HilbertPDNRe.ar(in, mul, add),
			HilbertPDNIm.ar(in, mul, add)
		]
	}


	*calcSOSCoefs { |...poles|
		var gammas, coefs, b1, b2;

		gammas = (15.0 * pi / SampleRate.ir) * poles;

		coefs = [];
		gammas.do({ arg gamma;
			coefs = coefs.add((gamma-1)/(gamma+1))
		});

		// 1st order allpass filters coefs are grouped into coefs for 2nd order sections
		b1 = [];
		b2 = [];
		// gathers even and odd
		poles.size.div(2).do({ arg i;
			b1 = b1.add(coefs[2*i] + coefs[(2*i)+1]);
			b2 = b2.add(coefs[2*i] * coefs[(2*i)+1]);
		});

		^[b1, b2]
	}
}

HilbertPDNRe {
	*ar { |in, mul = 1.0, add = 0.0|
		var b1, b2, hilbertCos;

		#b1, b2 = HilbertPDN.calcSOSCoefs(0.3609, 798.4578, 2.7412, 179.6242, 11.1573, 44.7581);

		hilbertCos = in;
		3.do({ |i|
			hilbertCos = SOS.ar(hilbertCos, b2[i], b1[i], 1.0, b1[i].neg, b2[i].neg)
		});

		^(mul * (add + hilbertCos))
	}
}

HilbertPDNIm {
	*ar { |in, mul = 1.0, add = 0.0|
		var b1, b2, hilbertSin;

		#b1, b2 = HilbertPDN.calcSOSCoefs(1.2524, 2770.1114, 5.5671, 364.7914, 22.3423, 89.6271);

		hilbertSin = in;
		3.do({ |i|
			hilbertSin = SOS.ar(hilbertSin, b2[i], b1[i], 1.0, b1[i].neg, b2[i].neg)
		});

		^(mul * (add + hilbertSin))
	}
}

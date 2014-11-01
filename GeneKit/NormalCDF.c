/***********************************************************

Copyright (c) 1992-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

All Rights Reserved.

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose and without fee is hereby granted, 
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in 
supporting documentation. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of a copyright holder
shall not be used in advertising or otherwise to promote the sale, use
or other dealings in this Software without prior written authorization
of the copyright holder.  Citations, discussions, and references to or regarding
this work in scholarly journals or other scholarly proceedings 
are exempted from this permission requirement.

Support for this work provided by:
The University of Wisconsin-Madison Chemistry Department
The National Institutes of Health/National Human Genome Research Institute
The Department of Energy


******************************************************************/

#include <math.h>

float normalCDFTable[] =
{
.5000, .5040, .5080, .5120, .5160, .5199, .5239, .5279, .5319, .5359, 
.5398, .5438, .5478, .5517, .5557, .5596, .5636, .5675, .5714, .5753, 
.5793, .5832, .5871, .5910, .5948, .5987, .6026, .6064, .6103, .6141, 
.6179, .6217, .6255, .6293, .6331, .6368, .6406, .6443, .6480, .6517, 
.6554, .6591, .6628, .6664, .6700, .6736, .6772, .6808, .6844, .6879, 

.6915, .6950, .6985, .7019, .7054, .7088, .7123, .7157, .7190, .7224, 
.7257, .7291, .7324, .7357, .7389, .7422, .7454, .7486, .7517, .7549, 
.7580, .7611, .7642, .7673, .7703, .7734, .7764, .7794, .7823, .7852, 
.7881, .7910, .7939, .7967, .7995, .8023, .8051, .8078, .8106, .8133, 
.8159, .8186, .8212, .8238, .8264, .8289, .8315, .8340, .8365, .8389, 

.8413, .8438, .8461, .8485, .8508, .8531, .8554, .8577, .8599, .8621, 
.8643, .8665, .8686, .8708, .8729, .8749, .8770, .8790, .8810, .8830, 
.8849, .8869, .8888, .8907, .8925, .8944, .8962, .8980, .8997, .9015, 
.9032, .9049, .9066, .9082, .9099, .9115, .9131, .9147, .9162, .9177, 
.9192, .9207, .9222, .9236, .9251, .9265, .9279, .9292, .9306, .9319, 

.9332, .9345, .9357, .9370, .9382, .9394, .9406, .9428, .9429, .9441, 
.9452, .9463, .9474, .9484, .9495, .9505, .9515, .9525, .9535, .9545, 
.9554, .9564, .9573, .9582, .9591, .9599, .9608, .9616, .9625, .9633, 
.9641, .9649, .9656, .9664, .9671, .9678, .9686, .9693, .9699, .9706, 
.9713, .9719, .9726, .9732, .9738, .9744, .9750, .9756, .9761, .9767, 

.9772, .9778, .9783, .9788, .9793, .9798, .9803, .9808, .9812, .9817, 
.9821, .9826, .9830, .9834, .9838, .9842, .9846, .9850, .9854, .9857, 
.9861, .9864, .9868, .9871, .9875, .9878, .9881, .9884, .9887, .9890, 
.9893, .9896, .9898, .9901, .9904, .9906, .9909, .9911, .9913, .9916, 
.9918, .9920, .9922, .9925, .9927, .9929, .9931, .9932, .9934, .9936, 

.9938, .9940, .9941, .9943, .9945, .9946, .9948, .9949, .9951, .9952, 
.9953, .9955, .9956, .9957, .9959, .9960, .9961, .9962, .9963, .9964, 
.9965, .9966, .9967, .9968, .9969, .9970, .9971, .9972, .9973, .9974, 
.9974, .9975, .9976, .9977, .9977, .9978, .9979, .9979, .9980, .9981, 
.9981, .9982, .9982, .9983, .9984, .9984, .9985, .9985, .9986, .9986, 

.9987, .9987, .9987, .9988, .9988, .9989, .9989, .9989, .9990, .9990
};

#define MAXTABLEIX  309

float lookupNormalCDF(float x)
{
	int	tableIx;
	
	tableIx = floor(fabs(x)*100 + 0.5);
	tableIx = tableIx > MAXTABLEIX ?  MAXTABLEIX : tableIx;
	
	if (x>=0)
		return normalCDFTable[tableIx];
	else
		return 1-normalCDFTable[tableIx];
}

// complementary error function--approximation
float erfcc(float x)
{
	float	z = fabs(x);
	float	t = 1.0/(1.0+(z/2.0));
	float	result;
	
	result = t*exp(-z*z-1.26551223+t*(1.00002368+t*(.37409196+
				t*(.09678418+t*(-.18628806+t*(.27886807+t*(-1.13520398+
				t*(1.48851587+t*(-.82215223+t*.17087277)))))))));
	if (x<0) result = 2.0 - result;
	
	return result;
}

#define SQRT2  1.41421356
// x is normalized to standard deviations
float calcNormalCDF(float x)
{
	if (x>=0)
		return (2-erfcc(x/SQRT2))/2.0;
	else
		return 1-((2-erfcc(-x/SQRT2))/2.0);
}

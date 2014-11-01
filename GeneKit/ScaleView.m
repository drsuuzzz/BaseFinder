
#import "ScaleView.h"

@implementation ScaleView

- initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	start = 0.0;
	end = 100.0;
	majorDivision = 10.0;
	minorDivision = 1.0;
	isVertical = NO;
	return self;
}

- (void)setVertical:(BOOL)value;
{
	isVertical = value;
}

- (void)setStart:(float)value
{
	start = value; 
}

- (void)setEnd:(float)value;
{
	end = value;
}

- (void)setMajorDiv:(float)value;
{
	majorDivision = value;
}

- (void)setMinorDiv:(float)value;
{
	minorDivision = value;
}

#ifdef OLDCODE
- drawDataMarkers:(int)startOffset
{
	int			x;
	NSRect	boundsRect;
	char		str[64];
	float		w1=100.0;
	id			tempFont;
	//	int			fontNum;
	
	boundsRect = [self bounds];
	PSsetgray(0);
	PSselectfont("Helvetica",8.0);
	tempFont = [[NSFontManager new] fontWithFamily:@"Helvetica" traits:NSUnboldFontMask weight:0 size:8];
	/** [tempFont set]; **/
	sprintf(str,"%dpts",endPoint+startOffset);
	/** PSstringwidth(str,&w1,&w2); **/
	w1 = [tempFont widthOfString:[NSString stringWithCString:str]];
	for(x=startPoint;x<endPoint;x++) {
		if(x%1000 == 0) {
			PSmoveto((x-startPoint)*xScale + 0.5, boundsRect.size.height);
			PSrlineto(0.0, -10.0);
			PSstroke();
			sprintf(str,"%dpts",startOffset+x);
			PSmoveto((x-startPoint)*xScale + 1.5, boundsRect.size.height-10.0);
			PSshow(str);
			PSstroke();
		}
		else if(x%100 == 0) {
			PSmoveto((x-startPoint)*xScale + 0.5, boundsRect.size.height);
			PSrlineto(0.0, -3.0);
			PSstroke();
			sprintf(str,"%dpts",startOffset+x);
			/* PSstringwidth(str,&w1,&w2);*/
			if(w1<75*xScale) {
				PSmoveto((x-startPoint)*xScale + 1.5, boundsRect.size.height-10.0);
				PSshow(str);
				PSstroke();
			}
		}
	}
	
	return self;
}
#endif

- (void)drawRect:(NSRect)rects
{
	float			x, temp;
//	char			str[64];
	float			w1=100.0;
	id				tempFont;
        NSBezierPath *path = [NSBezierPath bezierPath];
        NSPoint p;
        NSString *drawString;
        NSDictionary *attrib = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica-Regular" size:8.0], @"NSFontAttributeName", nil]; 
	
	if(![[self window] isVisible]) return;
  
        [[NSColor whiteColor] set];
//	PSsetgray(NSWhite);
	NSRectFill([self bounds]);
        [[NSColor blackColor] set];

	//PSsetgray(NSBlack);
	//PSsetrgbcolor(Red[channel], Green[channel], Blue[channel]);

	//mark minor ticks
	for(x=start; x<=end; x+=minorDivision) {
          temp = (([self bounds].size.width-1.0)/(float)(end-start)) * (x - start);
          p.x = temp; p.y = [self bounds].size.height-1.0;
          [path moveToPoint:p];
          p.y = [self bounds].size.height-1.0 - ([self bounds].size.height-11.0)*0.666;
          [path lineToPoint:p];
	//	PSmoveto(temp, [self bounds].size.height-1.0);
	//	PSlineto(temp, [self bounds].size.height-1.0 - ([self bounds].size.height-11.0)*0.666);
	}
        [path stroke];
	//PSstroke();

	//now mark and label the major ticks
        tempFont = [NSFont fontWithName:@"Helvetica-Regular" size:8.0];

//	PSselectfont("Helvetica",8.0);
//	tempFont = [[NSFontManager new] fontWithFamily:@"Helvetica" traits:NSUnboldFontMask weight:0 size:8];
	//sprintf(str,"%1.2f",end);
        drawString = [NSString stringWithFormat:@"%1.2f",end];
	w1 = [tempFont widthOfString:drawString];

	//PSsetlinewidth(1.0);
        [path setLineWidth:1.0];
	for(x=start; x<=end; x+=majorDivision) {
		temp = (([self bounds].size.width-1.0)/(float)(end-start)) * (x - start);
                p.x = temp; p.y = [self bounds].size.height-1.0;
                [path moveToPoint:p];
                p.y = 10.0;
                [path lineToPoint:p];
		/*PSmoveto(temp, [self bounds].size.height-1.0);
		PSlineto(temp, 10.0);
		PSstroke(); */
                
                drawString = [NSString stringWithFormat:@"%1.2f",x];
                p.y = 1.0;
                [drawString drawAtPoint:p withAttributes:attrib];

		//sprintf(str,"%1.2f",x);
		/*PSmoveto(temp, 1.0);
		PSshow(str);
		PSstroke(); */
	}
}

@end

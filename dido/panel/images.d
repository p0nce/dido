module dido.panel.images;

import dido.gui.context;

static immutable imageScrollbarN = cast(immutable(ubyte[])) import("scrollbarN.png");
static immutable imageScrollbarS = cast(immutable(ubyte[])) import("scrollbarS.png");
static immutable imageScrollbarE = cast(immutable(ubyte[])) import("scrollbarE.png");
static immutable imageScrollbarW = cast(immutable(ubyte[])) import("scrollbarW.png");
static immutable imageDlang      = cast(immutable(ubyte[])) import("dlang.png");
static immutable imageDido      = cast(immutable(ubyte[])) import("dido.png");

void addAllImage(UIContext context)
{
    context.addImage("scrollbarN", imageScrollbarN);
    context.addImage("scrollbarS", imageScrollbarS);
    context.addImage("scrollbarE", imageScrollbarE);
    context.addImage("scrollbarW", imageScrollbarW);
    context.addImage("dlang", imageDlang);
    context.addImage("dido", imageDido);
}
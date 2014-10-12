module dido.panel.images;

import dido.gui.context;

static immutable imageScrollbarN = cast(immutable(ubyte[])) import("scrollbarN.png");
static immutable imageScrollbarS = cast(immutable(ubyte[])) import("scrollbarS.png");
static immutable imageScrollbarE = cast(immutable(ubyte[])) import("scrollbarE.png");
static immutable imageScrollbarW = cast(immutable(ubyte[])) import("scrollbarW.png");
static immutable imageDido       = cast(immutable(ubyte[])) import("dido.png");
static immutable imageCorner     = cast(immutable(ubyte[])) import("corner.png");
static immutable imageBuild      = cast(immutable(ubyte[])) import("build.png");
static immutable imageRun        = cast(immutable(ubyte[])) import("run.png");

void addAllImage(UIContext context)
{
    context.addImage("scrollbarN", imageScrollbarN);
    context.addImage("scrollbarS", imageScrollbarS);
    context.addImage("scrollbarE", imageScrollbarE);
    context.addImage("scrollbarW", imageScrollbarW);
    context.addImage("corner", imageCorner);
    context.addImage("dido", imageDido);
    context.addImage("build", imageBuild);
    context.addImage("run", imageRun);
}
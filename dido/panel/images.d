module dido.panel.images;

import dido.gui.context;

static immutable imageDido       = cast(immutable(ubyte[])) import("dido.png");
static immutable imageCorner     = cast(immutable(ubyte[])) import("corner.png");
static immutable imageBuild      = cast(immutable(ubyte[])) import("build.png");
static immutable imageRun        = cast(immutable(ubyte[])) import("run.png");
static immutable imageCycle      = cast(immutable(ubyte[])) import("cycle.png");

void addAllImage(UIContext context)
{
    context.addImage("corner", imageCorner);
    context.addImage("dido", imageDido);
    context.addImage("build", imageBuild);
    context.addImage("run", imageRun);
    context.addImage("cycle", imageCycle);
}
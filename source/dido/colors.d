module dido.colors;

public import std.random;

import std.algorithm,
       std.math;

public import gfm.math.vector,
              gfm.math.funcs,
              gfm.math.simplerng;


vec3ub rgb(int r, int g, int b) pure nothrow
{
    return vec3ub(cast(ubyte)r, cast(ubyte)g, cast(ubyte)b);
}

vec4ub rgba(int r, int g, int b, int a) pure nothrow
{
    return vec4ub(cast(ubyte)r, cast(ubyte)g, cast(ubyte)b, cast(ubyte)a);
}

vec3ub lerpColor(vec3ub a, vec3ub b, float t) pure nothrow
{
    vec3f af = cast(vec3f)a;
    vec3f bf = cast(vec3f)b;
    vec3f of = af * (1 - t) + bf * t;
    return cast(vec3ub)(0.5f + of);
}

vec4ub lerpColor(vec4ub a, vec4ub b, float t) pure nothrow
{
    vec4f af = cast(vec4f)a;
    vec4f bf = cast(vec4f)b;
    vec4f of = af * (1 - t) + bf * t;
    return cast(vec4ub)(0.5f + of);
}

vec3ub mulColor(vec3ub color, float amount) pure nothrow
{
    vec3f fcolor = cast(vec3f)color / 255.0f;
    fcolor *= amount;
    return cast(vec3ub)(0.5f + fcolor * 255.0f);
}

vec4ub mulColor(vec4ub color, float amount) pure nothrow
{
    return vec4ub(mulColor(color.xyz, amount), color.w);
}


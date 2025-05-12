#define PI 3.14159265
#define STOP_MOTION false

const vec2 LIGHT = vec2(2.);

float sd_circle(vec2 c, vec2 p, float r) {
    return length(c-p)-r;
}

float sd_ellipse(vec2 c, vec2 p, float a, float b, float r) {
    return pow(p.x-c.x,2.)/(a*a)+pow(p.y-c.y,2.)/(b*b);
}

float sd_cloud(vec2 c, vec2 p){
    float t = max(step(sd_circle(vec2(c),p,0.12), 0.),
                  step(sd_circle(vec2(c.x+0.1,c.y+0.1),p,0.12), 0.));
    t = max(t, step(sd_circle(vec2(c.x+0.2,c.y),p,0.12), 0.));
    if (p.y < -0.1) {
        t = 0.;
    }
    t += 1.0-float(sd_ellipse(vec2(c.x+0.1,c.y-0.09), p, 0.3, 0.09, 0.5) >= 0.25);
    return t;
}

float shadow(float f) {
    return smoothstep(0.,1.,f);
}

float noise(vec2 p){
    return fract(sin(p.x*100.+p.y*6574.)*5647.);
}

vec3 paper(vec2 st){
    return texture(iChannel0,st).rbg*0.055;
}

vec3 draw_cloud(vec3 color, vec2 p, float i, float o){
    
    vec3 s = paper(vec2(p.x-5.*fract(0.03*iTime), p.y));
    float offset = 0.5*noise(vec2(i*floor(o),i/ceil(o)));
    float t = sd_cloud(vec2(mix(-2.1,1.9,fract(o)), 0.18+offset),p);
    color = t > 0. ? vec3(0.95+s.r, 0.95+s.g, 1.):color;
    return color;
}

float wave_movement(vec2 p, int s){
     return sin(p.x*PI*10.0+sin(iTime)*float(s)/5.0*2.0);
}

float sun_rays(vec2 c, float r){
     return sin(24.*atan(c.y-c.x*r, c.x+c.y*r))*0.019;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) 
{
    if (STOP_MOTION && mod(float(iFrame), 12.0) >= 1.) {
        discard;
    }
    vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3 p = paper(uv);
    
    //sky
    vec3 col = vec3(0.66, 0.76, 0.96)+p*0.9;
    
    //sun
    vec2 sun = uv-vec2(1.05,0.5);
    float rot = fract(0.25*iTime);
    float rays = sun_rays(sun, rot);
    float puls = sin(iTime*1.5)/115.;
    float radius = 0.29 + rays + puls;
    
    for (int i = 0; i < 5; i++)
    {
        if (length(sun.xy) <= (radius-float(i)/15.)) 
        {
            rot = -1.*rot;
            rays = sun_rays(sun, rot);
            radius = (i > 1) ? 0.33 : 0.31 + rays + puls;
            col = p*1.5+0.95*vec3(0.96,0.35+float(i)/5.1,0.);
        }
        col -= 0.03*min(1.,(length(sun.xy)-(radius-float(i)/15.)));
        
        if (i==2) {
            float dist = length(sun.xy)-(0.33-float(i)/10.);
        }
    }
    
    //clouds
    col = draw_cloud(col,uv,1.,0.05*iTime+0.2);
    col = draw_cloud(col,uv,2.,0.05*iTime+0.5);
    col = draw_cloud(col,uv,3.,0.05*iTime-0.15);

    //waves
    for (int i = 0; i <= 50; i++)
    {
        p = paper(vec2(uv.x+sin(iTime)*0.38*float(i-5)/30.,
                       uv.y+sin(iTime)*0.04))*1.5;
        if (uv.y*25.0+sin(iTime)+float(i)*1.4+5. <
            wave_movement(uv,i-5))
        {
            col = p+vec3(0.,0.,(float(i-5)/23.0)+0.55);
        }
    }
    
    fragColor = vec4(col,0.);
}


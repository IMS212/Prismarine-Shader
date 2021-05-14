float waterH(vec3 pos){
	float noise=0;
	noise+=texture2D(noisetex,(pos.xz+vec2(frameTimeCounter)*.5-pos.y*.7)/WATER_CAUSTICS_AMOUNT*1.1).r*1.;
	noise+=texture2D(noisetex,(pos.xz-vec2(frameTimeCounter)*.5-pos.y*.7)/WATER_CAUSTICS_AMOUNT*2.5).r*.8;
	noise-=texture2D(noisetex,(pos.xz+vec2(frameTimeCounter)*.5+pos.y*.7)/WATER_CAUSTICS_AMOUNT*4.5).r*.6;
	noise+=texture2D(noisetex,(pos.xz-vec2(frameTimeCounter)*.5-pos.y*.7)/WATER_CAUSTICS_AMOUNT*7.0).r*.4;
	noise-=texture2D(noisetex,(pos.xz+vec2(frameTimeCounter)*.5+pos.y*.7)/WATER_CAUSTICS_AMOUNT*16.0).r*.2;
	
	return noise;
}

float getCausticWaves(vec3 posxz){
	float deltaPos=.9;
	float caustic_h0=waterH(posxz);
	float caustic_h1=waterH(posxz+vec3(deltaPos,0.,0.));
	float caustic_h2=waterH(posxz+vec3(-deltaPos,0.,0.));
	float caustic_h3=waterH(posxz+vec3(0.,0.,deltaPos));
	float caustic_h4=waterH(posxz+vec3(0.,0.,-deltaPos));
	
	float caustic=max((1.-abs(.5-caustic_h0))*(1.-(abs(caustic_h1-caustic_h2)+abs(caustic_h3-caustic_h4))),0.);
	caustic=max(pow(caustic,3.5),0.)*2.;
	
	return caustic;
}
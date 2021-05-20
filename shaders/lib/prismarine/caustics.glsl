float waterH(vec3 pos){
	float noise=0;
	noise+= texture2D(noisetex,(pos.xz+vec2(frameTimeCounter)*0.5-pos.y*0.2)/1024.0* 1.1).r*1.0;
	noise+= texture2D(noisetex,(pos.xz-vec2(frameTimeCounter)*0.5-pos.y*0.2)/1024.0* 1.5).r*0.8;
	noise-= texture2D(noisetex,(pos.xz+vec2(frameTimeCounter)*0.5+pos.y*0.2)/1024.0* 2.5).r*0.6;
	noise+= texture2D(noisetex,(pos.xz-vec2(frameTimeCounter)*0.5-pos.y*0.2)/1024.0* 5.0).r*0.4;
	noise-= texture2D(noisetex,(pos.xz+vec2(frameTimeCounter)*0.5+pos.y*0.2)/1024.0* 8.0).r*0.2;
	
	return pow(clamp((noise+0.8)/3.0,0.0,1.0),2.2);
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
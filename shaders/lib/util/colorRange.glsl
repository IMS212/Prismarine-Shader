vec3 rangeCompress(vec3 x){
	return pow(x/32.0,vec3(1.0/2.2));
}
vec3 rangeExpand(vec3 x){
	return pow(x,vec3(2.2))*32.0;
}
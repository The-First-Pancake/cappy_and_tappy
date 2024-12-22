shader_type canvas_item;

uniform sampler2D noise;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float water_speed:hint_range(0.0, 0.5, 0.001) = 0.1;
uniform float color_detect_threshold = 0.6;
uniform float border_threshold = 0.2;
uniform int pixelation_amount = 5;
//suggest color code: ff00ff
uniform vec4 water_dev_color: source_color = vec4(1, 0, 1, 1);
uniform vec4 water_color: source_color = vec4(0,0,1,1);
uniform vec4 border_color: source_color = vec4(1,1,1,1);

void fragment(){
	//2 UV references from Screen
	vec2 uv = UV;
	//move water around
	uv.x += sin(TIME) * water_speed;
	uv.y -= cos(TIME) * water_speed;
	//2 references to noise texture
	vec2 grid_uv = round(uv * float(pixelation_amount)) / float(pixelation_amount);
	vec4 n = texture(noise, grid_uv);
	//get a blurred version of the screen texture
	vec4 screen_tex = textureLod(SCREEN_TEXTURE,SCREEN_UV,0.0).rgba;
	vec4 screen_tex_blurred = textureLod(SCREEN_TEXTURE,SCREEN_UV,2.0).rgba;
	vec4 particle_color;
	//check if the color is pink i.e ff00ff
	//if it is set it to the new color else set it to transparent
	if(step(color_detect_threshold,screen_tex) == water_dev_color){
		particle_color = (n*0.1) + border_color;
		//particle_color = border_color;
		if (step(border_threshold, screen_tex_blurred) == water_dev_color){
			particle_color = (n*0.5) + water_color;
		}
	} else {
		//transparent
		particle_color = vec4(0.0);
	}
	//assign final color
	COLOR = particle_color;
}
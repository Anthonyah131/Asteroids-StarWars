draw_text(10, 10, string(points));

if (paused) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(-1);
    draw_set_color(c_white);
    draw_text(room_width/2, room_height/2, "PAUSA");
}

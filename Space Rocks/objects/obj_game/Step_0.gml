if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("P"))) {
    paused = !paused;

    if (paused) {
        instance_deactivate_all(true);
    } else {
        instance_activate_all();
    }
}

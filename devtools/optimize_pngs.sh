# from https://github.com/luanti-org/minetest_game/blob/master/utils/optimize_textures.sh
# added multicore support
find .. -name '*.png' -print0 | xargs -0 -n 1 -P $(nproc) optipng -o7 -zm1-9 -nc -strip all -clobber

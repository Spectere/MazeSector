#!/bin/sh

# Default size (if none is specified).
size=737280

if [ $# -gt 0 ]; then
    case $1 in
        360)
            # 360KB
            size=368640
            ;;

        720)
            # 720KB
            size=737280
            ;;

        1200)
            # 1.2MB
            size=1228800
            ;;
        
        1440)
            # 1.44MB
            size=1474560
            ;;

        2880)
            # 2.88MB
            size=2949120
            ;;

        8)
            echo "Invalid floppy format. The following formats are supported:"
            echo ""
            echo "    360 - 360KiB, double-sided, double-density"
            echo "    720 - 720KiB, double-sided, double-density"
            echo "   1200 - 1200KiB, double-sided, high-density"
            echo "   1440 - 1440KiB, double-sided, high-density"
            echo "   2880 - 2880KiB, double-sided, extended-density"
            exit 1
            ;;
    esac
fi

nasm -f bin -o bin/boot.bin main.asm \
&& dd if=/dev/zero bs=${size} count=1 of=bin/maze.img \
&& dd if=bin/boot.bin bs=512 count=1 of=bin/maze.img conv=notrunc \
&& echo \
&& python3 golf_score.py bin/boot.bin \
&& echo

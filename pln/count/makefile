all:
	rm -f *.png
	perl count.pl -open ../../ -verbose -separated -out image

clean:
	find . -maxdepth 1 \( \! -iname "makefile" \! -iname "*.pl" \! -iname README.markdown \) -exec rm -f '{}' \;
	find . -name *~ -or -name *.*~ | xargs rm -f

open:
	open image_*

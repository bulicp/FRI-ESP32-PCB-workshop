# 5.4 Pours and stitching vias

Covered in detail in sections 4.3 and 4.4: the GND pours on `F.Cu` and `B.Cu` fill the free area outside the antenna keepout, and **stitching vias** tie them to the plane on `In1.Cu`. Pour and stitch after routing, because every new trace on an outer layer changes where the pour's fragments lie.

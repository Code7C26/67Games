-- Second art pass. Hand-stepped silhouettes, intentional material details.
-- This redraws the MAP inflatables and scenery. Player ducks are untouched.
return function(p)
local new,frame,rect,px,line,ell,poly,box,flush,save,panel,tube=p.new,p.frame,p.rect,p.px,p.line,p.ell,p.poly,p.box,p.flush,p.save,p.panel,p.tube
local ink='30384c';local navy='3b5d76';local cream='e3d4b2';local white='fff2d6';local coral='dc715e';local red='a74b4d';local yellow='f6cb5c';local blue='428fc0';local pale='b8edff'
local function bolts(x,y,w,h)
 for _,q in ipairs({{x,y},{x+w,y},{x,y+h},{x+w,y+h}})do rect(q[1],q[2],3,3,ink);px(q[1],q[2],'d8e5dc')end
end
local function boards(x,y,w,h,vertical)
 rect(x,y,w,h,'9c724e')
 if vertical then for xx=x,x+w-1,8 do rect(xx,y,2,h,'694f40');rect(xx+2,y,1,h,'c49d69');for yy=y+7,y+h-3,19 do line(xx+4,yy,xx+4,yy+7,'79553f')end end
 else for yy=y,y+h-1,8 do rect(x,yy,w,2,'705342');rect(x+1,yy+2,w-2,1,'c49d69');for xx=x+5,x+w-5,19 do line(xx,yy+5,xx+9,yy+5,'815c43')end end end
end

-- The pool mascot has squared cheeks, a broad angular bill and a stepped tail.
new(160,144,'Inflable de la pileta / silueta a escalones')
for f=1,8 do frame(f);local dy=({0,0,2,2,0,0,-2,-2})[f]
 poly({{18,117},{34,111},{129,111},{145,117},{145,125},{129,131},{34,131},{18,125}},'4c9fc5')
 line(26,130,54,130,'a7e2f8',2);line(117,128,139,123,'a7e2f8',2)
 local function shape(points,c)local a={};for _,v in ipairs(points)do a[#a+1]={v[1],v[2]+dy}end;poly(a,c)end
 local function r(x,y,w,h,c)rect(x,y+dy,w,h,c)end
 shape({{14,59},{26,68},{34,78},{68,74},{70,36},{78,36},{78,22},{88,22},{88,12},{96,12},{96,19},{112,19},{112,25},{124,25},{124,39},{132,39},{132,75},{124,75},{124,88},{138,88},{138,108},{130,108},{130,118},{112,118},{112,124},{42,124},{42,118},{28,118},{28,108},{18,108},{18,91},{10,91},{10,69},{14,69}},'634d38')
 shape({{16,67},{30,80},{40,86},{76,82},{76,39},{84,39},{84,26},{94,26},{94,19},{108,24},{108,29},{120,29},{120,43},{126,43},{126,71},{118,71},{118,92},{132,92},{132,106},{124,106},{124,114},{108,114},{108,120},{44,120},{44,114},{32,114},{32,105},{24,105},{24,89},{16,85}},'d49c3f')
 shape({{23,77},{38,88},{76,88},{80,68},{80,41},{88,41},{88,31},{114,31},{114,41},{120,41},{120,65},{112,65},{112,89},{125,95},{125,104},{115,104},{115,113},{47,113},{47,108},{35,108},{35,98},{26,98}},yellow)
 shape({{88,33},{110,33},{110,38},{118,38},{118,50},{112,50},{112,45},{87,45}},'ffe58b')
 r(88,28,20,4,'fff0b6');r(82,43,5,16,'ffe58b');r(95,20,8,4,'fff0b6')
 -- Angular eye and low eyebrow, echoing Patogen's readable character faces.
 r(108,44,11,14,'fff0b6');r(113,49,6,10,ink);r(113,49,2,3,white);r(109,42,11,3,'ab7b33')
 shape({{112,59},{141,59},{141,63},{151,63},{151,79},{145,79},{145,85},{116,85},{116,79},{108,79},{108,65}},'754a37')
 shape({{116,63},{139,63},{139,67},{147,67},{147,75},{117,75},{112,71},{112,67}},'eea254')
 r(118,64,21,4,'ffc773');r(116,77,28,4,'d47b42');r(120,73,27,3,'a45d3b');r(132,64,4,2,'c87942')
 -- Flat folded wing panels, not a circular inset.
 shape({{38,86},{72,82},{88,87},{84,95},{77,95},{77,103},{64,103},{64,108},{42,103},{35,96}},'b88132')
 shape({{41,87},{69,86},{82,89},{77,93},{70,93},{70,99},{62,99},{62,103},{45,99},{40,95}},'edb94c')
 r(44,88,22,3,'ffdf7a');r(44,92,12,2,'f7d36a')
 -- Segmented welded seams and a small inflation valve along the skirt.
 for x=50,108,8 do r(x,115,4,2,'af7f32')end
 r(108,109,7,6,'8e6934');r(110,110,3,3,'d9ad56');r(34,105,7,3,'ffe083')
 flush(f)
end;save('pato_gigante',true,.2)

new(96,88,'Sombrilla / ocho gajos / costuras')
for f=1,8 do frame(f);local sw=({0,0,1,1,0,0,-1,-1})[f]
 poly({{14,66},{74,63},{89,71},{75,81},{26,82},{10,75}},'b8aa93');rect(46,36,5,43,ink);rect(47,37,2,38,'b9cfd0')
 local function sh(q,c)local a={};for _,v in ipairs(q)do a[#a+1]={v[1]+sw,v[2]}end;poly(a,c)end
 sh({{47,5},{64,11},{81,23},{91,38},{85,49},{67,57},{47,60},{25,56},{8,48},{3,36},{16,20},{32,11}},ink)
 sh({{47,9},{62,14},{78,26},{86,38},{80,46},{65,52},{47,55},{27,51},{12,44},{8,36},{20,24},{34,14}},coral)
 for _,q in ipairs({{{47,10},{34,15},{13,37},{12,43},{27,48}},{{47,10},{47,53},{65,50}},{{47,10},{77,27},{84,37},{80,43}}})do sh(q,white)end
 line(47+sw,10,27+sw,50,red);line(47+sw,10,65+sw,52,red);line(47+sw,10,10+sw,37,red);line(47+sw,10,85+sw,37,red)
 for _,q in ipairs({{20,29},{30,21},{57,36},{68,28}})do rect(q[1]+sw,q[2],2,4,'efac88')end
 rect(43+sw,5,9,5,'c49343');rect(45+sw,4,5,3,yellow);rect(43,76,12,3,ink);flush(f)
end;save('sombrilla',true,.22)

new(96,128,'Palmera / hojas segmentadas / tronco con corteza')
for f=1,8 do frame(f);local sw=({0,1,2,1,0,-1,-2,-1})[f]
 ell(25,111,53,12,'b8aa93');poly({{40,116},{53,116},{58,81},{53,37},{43,37},{47,81}},'634e3e');poly({{44,114},{50,114},{54,82},{49,40},{46,40},{50,82}},'ad8555')
 for y=47,110,8 do line(45,y,53,y-3,'d4ac70',2);line(43,y+3,51,y+1,'805f42',2)end
 local cx=48+sw;local cy=37
 for k=0,7 do local a=k*math.pi/4;local dx,dy=math.cos(a),math.sin(a);local nx,ny=-dy,dx
  local q={};q[#q+1]={cx,cy}
  for side=1,-1,-2 do
   for z=1,6 do local j=side==1 and z or 7-z;local len=j*6.5;local spread=(7-j)*1.7;local xx=cx+dx*len;local yy=cy+dy*len*.60+math.max(0,j-2)*1.7;q[#q+1]={math.floor(xx+nx*spread*side),math.floor(yy+ny*spread*side)};q[#q+1]={math.floor(xx+dx*2+nx*spread*.48*side),math.floor(yy+dy+ny*spread*.48*side)}end
   if side==1 then q[#q+1]={math.floor(cx+dx*44),math.floor(cy+dy*26+9)}end
  end
  poly(q,k%2==0 and '3d6d5f' or '5a896a')
  line(cx,cy,math.floor(cx+dx*40),math.floor(cy+dy*24+8),k%2==0 and '80a77c' or '9eb785',2)
 end
 rect(cx-6,cy-2,6,7,'6f543b');rect(cx,cy,6,7,'aa8050');rect(cx-4,cy-1,3,3,'c49d68');flush(f)
end;save('palmera',true,.22)

new(416,144,'Vestuarios / construccion baja / puertas saloon')
for f=1,12 do frame(f)
 rect(12,131,396,12,'b8aa93');rect(6,37,402,97,ink);rect(10,40,394,89,'b7c5b4');rect(14,44,386,76,'d9d8bc')
 -- Vertical weatherboard siding and warm floor threshold.
 for x=16,400,12 do rect(x,44,2,78,'a2b3a5');rect(x+2,46,1,74,'f2e8c9')end
 rect(9,121,398,8,'7c6249');boards(12,123,392,8,false)
 -- Rear roof and 3-layer overhang: visible thickness and individual wooden shingles.
 poly({{8,34},{26,4},{388,4},{410,34},{410,43},{8,43}},ink)
 poly({{15,33},{30,8},{385,8},{403,33}},'867653')
 for y=10,31,7 do for x=29-(y//7%2)*8,387,16 do rect(x,y,14,5,'ae986a');rect(x+1,y,12,1,'c8b17a');rect(x+13,y+1,1,4,'655e4a')end end
 rect(10,34,398,5,'d4b983');rect(10,39,398,5,'65523f');rect(12,44,394,3,'819585')
 -- Three changing cabins. Saloon leaves are half-height with slats and hinges.
 for j=0,2 do local x=26+j*106
  rect(x,51,88,70,ink);rect(x+4,55,80,62,'59695f');rect(x+8,58,72,54,'455752');rect(x-3,49,7,76,'88633f');rect(x-1,51,2,73,'c39a60');rect(x+85,49,7,76,'88633f');rect(x+86,51,2,73,'d6b77c')
  rect(x+5,56,77,4,'2e4746');rect(x+8,109,72,8,'78917d');rect(x+8,110,72,2,'9eaf8d')
  local phase=(f+j*4)%12;local opened=phase==3 and 5 or (phase==4 and 9 or (phase==5 and 5 or 0));local w=36-opened
  for side=0,1 do local xx=side==0 and x+6 or x+82-w
   poly({{xx,73},{xx+6,68},{xx+w-6,68},{xx+w,73},{xx+w,106},{xx,106}},'634831')
   poly({{xx+2,75},{xx+7,71},{xx+w-7,71},{xx+w-2,75},{xx+w-2,103},{xx+2,103}},'b58b52')
   for yy=76,98,5 do rect(xx+3,yy,w-6,2,'735336');rect(xx+3,yy+2,w-6,1,'d0a66a')end
   rect(xx+3,72,3,32,'d2b079');rect(xx+w-6,74,3,29,'8e693e');rect(xx+3,100,w-6,3,'d8b57b')
   for yy=78,96,16 do rect(side==0 and xx-2 or xx+w-1,yy,5,3,ink);px(side==0 and xx-1 or xx+w,yy,'bbc5b2')end
   rect(side==0 and xx+w-5 or xx+3,87,2,5,'e6c880')
  end
  rect(x+36,50,17,13,'eddbb0');rect(x+40,53,9,2,'6c6b52');rect(x+43,55,3,5,'6c6b52')
 end
 -- Recessed locker alcove belongs to the building rather than floating outdoors.
 rect(347,50,48,69,ink);rect(350,53,42,63,'5f838d')
 for j=0,1 do for row=0,1 do local xx,yy=352+j*19,55+row*29;rect(xx,yy,17,26,'88a9ac');rect(xx+2,yy+1,13,2,'c6d6c7');rect(xx+12,yy+11,2,6,ink);for k=0,2 do rect(xx+3,yy+6+k*3,7,1,'4e7580')end;rect(xx+4,yy+18,6,4,cream)end end
 bolts(15,48,383,72)
 flush(f)
end;save('vestuarios',true,.28)

-- More articulated slide rails: joints, bracket plates, stepped water streaks.
new(272,240,'Toboganes / barandillas / juntas / fibra pintada')
for f=1,8 do frame(f);poly({{20,211},{246,211},{258,225},{234,234},{28,234},{11,225}},'b8aa93')
 for _,x in ipairs({35,126,225})do rect(x,73,10,139,ink);rect(x+2,75,6,134,'87a6ab');rect(x+2,77,2,130,'c6d5c9');for y=90,200,29 do rect(x-2,y,14,5,'52778a');bolts(x,y+1,8,0)end;rect(x-7,207,24,7,ink)end
 panel(16,12,130,76,navy);boards(22,44,118,21,false)
 for x=25,139,14 do rect(x,18,4,45,ink);rect(x+1,18,2,44,'d5ded0')end
 rect(13,11,137,6,ink);rect(14,12,135,2,white);rect(19,64,125,7,'a6b7b5');bolts(23,67,116,0)
 local a={{70,77},{109,100},{177,99},{216,126},{210,151},{163,166},{111,170},{80,197},{90,221}}
 local b={{112,77},{148,83},{202,88},{245,116},{246,153},{219,181},{170,198},{160,225}}
 tube(a,21,ink,red);tube(a,18,red,coral);tube(b,19,ink,'b18c37');tube(b,16,'bc963d',yellow)
 tube({{70,81},{111,105},{177,104},{211,127},{205,147},{162,161},{110,166},{75,196},{85,220}},7,'307ba7','7bc9e8')
 tube({{112,81},{151,88},{201,93},{239,118},{240,150},{215,176},{165,194},{155,223}},6,'307ba7','a1dcf1')
 for _,q in ipairs({{102,91},{171,89},{214,134},{155,173},{93,185}})do line(q[1],q[2],q[1]+5,q[2]+6,'eea183',2);rect(q[1]+2,q[2],2,2,ink)end
 for j=0,10 do local y=88+j*11;rect(23,y,28,4,ink);rect(24,y,26,2,white);rect(21,y-2,3,8,ink);rect(50,y-2,3,8,ink)end
 -- Falling water is a separate sprite anchored to each outlet in Godot.
 for j=0,3 do local x=108+j*23;local y=101+((j+f)%3);line(x,y,x+8,y,pale,2)end
 flush(f)
end;save('toboganes',true,.14)

-- Furniture is constructed from separate timber, cloth and metal components.
new(40,80,'Reposera / bastidor / tejido / toalla')
rect(7,62,5,13,ink);rect(29,62,5,13,ink);rect(9,63,2,10,'a7b4ae');rect(30,63,2,10,'a7b4ae');poly({{5,9},{33,9},{36,63},{4,63}},ink);poly({{8,12},{30,12},{33,59},{7,59}},'548aa4')
for x=10,29,7 do rect(x,15,3,41,'b7d8dc');for y=17,57,4 do rect(x,y,3,1,'8eb8c9')end end
rect(7,36,25,4,ink);rect(8,36,24,2,'d7e0cb');rect(2,31,4,33,'7f999e');rect(34,31,4,33,'7f999e');rect(2,31,2,25,white);rect(35,31,2,25,white);rect(11,17,19,14,'ddc18b');rect(12,18,17,2,white);rect(12,27,17,2,'a9865e');for x=12,28,3 do rect(x,31,1,3,cream)end;bolts(6,12,28,48);flush();save('reposera')
new(64,32,'Banco / tablas / tornilleria');rect(8,20,6,10,ink);rect(51,20,6,10,ink);rect(10,21,2,7,'91a3a0');rect(52,21,2,7,'91a3a0');rect(2,4,60,22,ink);boards(4,6,56,18,false);bolts(8,8,47,12);flush();save('banco')
new(64,48,'Mesa / madera / vasos / pajitas');poly({{8,32},{52,32},{61,39},{50,44},{14,44},{4,39}},'b8aa93');rect(27,19,7,25,ink);rect(29,20,3,21,'a2b9b6');poly({{12,4},{51,4},{61,13},{61,23},{51,31},{12,31},{3,23},{3,13}},ink);poly({{13,7},{50,7},{58,14},{58,21},{50,27},{13,27},{6,21},{6,14}},'c8a16c');for y=11,24,6 do line(10,y,54,y,'92704b');line(12,y+1,52,y+1,'ebc791')end;rect(17,10,8,12,red);rect(17,9,8,3,pale);rect(18,13,2,7,coral);line(21,4,21,11,ink);rect(40,14,9,11,navy);rect(40,13,9,2,pale);rect(41,16,2,7,'6eafc2');line(45,8,44,15,red);flush();save('mesa')
end

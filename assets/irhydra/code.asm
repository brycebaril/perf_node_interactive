--- FUNCTION SOURCE (SetFunctionName) id{0,0} ---
(g,h,i){
if((typeof(h)==='symbol')){
h="["+%SymbolDescription(h)+"]";
}
if((i===(void 0))){
%FunctionSetName(g,h);
}else{
%FunctionSetName(g,i+" "+h);
}
}
--- END ---
--- FUNCTION SOURCE (ToName) id{1,0} ---
(i){
return(typeof(i)==='symbol')?i:ToString(i);
}
--- END ---
--- FUNCTION SOURCE (join) id{2,0} ---
(C){
if((this==null)&&!(%_IsUndetectableObject(this)))throw MakeTypeError(14,"Array.prototype.join");
var o=((%_IsSpecObject(%IS_VAR(this)))?this:$toObject(this));
var v=(o.length>>>0);
return InnerArrayJoin(C,o,v);
}
--- END ---
--- FUNCTION SOURCE (DoRegExpExec) id{3,0} ---
(j,k,l){
var m=%_RegExpExec(j,k,l,e);
if(m!==null)$regexpLastMatchInfoOverride=null;
return m;
}
--- END ---
--- FUNCTION SOURCE (PropertyDescriptor_HasValue) id{4,0} ---
(){
return this.hasValue_;
}
--- END ---
--- FUNCTION SOURCE (posix._makeLong) id{5,0} ---
(path) {
  return path;
}
--- END ---
--- FUNCTION SOURCE (PropertyDescriptor_HasGetter) id{6,0} ---
(){
return this.hasGetter_;
}
--- END ---
--- FUNCTION SOURCE (IsAccessorDescriptor) id{7,0} ---
(G){
if((G===(void 0)))return false;
return G.hasGetter()||G.hasSetter();
}
--- END ---
--- FUNCTION SOURCE (IsDataDescriptor) id{8,0} ---
(G){
if((G===(void 0)))return false;
return G.hasValue()||G.hasWritable();
}
--- END ---
--- FUNCTION SOURCE (PropertyDescriptor_HasEnumerable) id{9,0} ---
(){
return this.hasEnumerable_;
}
--- END ---
--- FUNCTION SOURCE (PropertyDescriptor_HasConfigurable) id{10,0} ---
(){
return this.hasConfigurable_;
}
--- END ---
--- FUNCTION SOURCE (PropertyDescriptor_HasSetter) id{11,0} ---
(){
return this.hasSetter_;
}
--- END ---
--- FUNCTION SOURCE (GifReaderLZWOutputIndexStream) id{12,0} ---
(code_stream, p, output, output_length) {
  var min_code_size = code_stream[p++];

  var clear_code = 1 << min_code_size;
  var eoi_code = clear_code + 1;
  var next_code = eoi_code + 1;

  var cur_code_size = min_code_size + 1;  // Number of bits per code.
  // NOTE: This shares the same name as the encoder, but has a different
  // meaning here.  Here this masks each code coming from the code stream.
  var code_mask = (1 << cur_code_size) - 1;
  var cur_shift = 0;
  var cur = 0;

  var op = 0;  // Output pointer.
  
  var subblock_size = code_stream[p++];

  // TODO(deanm): Would using a TypedArray be any faster?  At least it would
  // solve the fast mode / backing store uncertainty.
  // var code_table = Array(4096);
  var code_table = new Int32Array(4096);  // Can be signed, we only use 20 bits.

  var prev_code = null;  // Track code-1.

  while (true) {
    // Read up to two bytes, making sure we always 12-bits for max sized code.
    while (cur_shift < 16) {
      if (subblock_size === 0) break;  // No more data to be read.

      cur |= code_stream[p++] << cur_shift;
      cur_shift += 8;

      if (subblock_size === 1) {  // Never let it get to 0 to hold logic above.
        subblock_size = code_stream[p++];  // Next subblock.
      } else {
        --subblock_size;
      }
    }

    // TODO(deanm): We should never really get here, we should have received
    // and EOI.
    if (cur_shift < cur_code_size)
      break;

    var code = cur & code_mask;
    cur >>= cur_code_size;
    cur_shift -= cur_code_size;

    // TODO(deanm): Maybe should check that the first code was a clear code,
    // at least this is what you're supposed to do.  But actually our encoder
    // now doesn't emit a clear code first anyway.
    if (code === clear_code) {
      // We don't actually have to clear the table.  This could be a good idea
      // for greater error checking, but we don't really do any anyway.  We
      // will just track it with next_code and overwrite old entries.

      next_code = eoi_code + 1;
      cur_code_size = min_code_size + 1;
      code_mask = (1 << cur_code_size) - 1;

      // Don't update prev_code ?
      prev_code = null;
      continue;
    } else if (code === eoi_code) {
      break;
    }

    // We have a similar situation as the decoder, where we want to store
    // variable length entries (code table entries), but we want to do in a
    // faster manner than an array of arrays.  The code below stores sort of a
    // linked list within the code table, and then "chases" through it to
    // construct the dictionary entries.  When a new entry is created, just the
    // last byte is stored, and the rest (prefix) of the entry is only
    // referenced by its table entry.  Then the code chases through the
    // prefixes until it reaches a single byte code.  We have to chase twice,
    // first to compute the length, and then to actually copy the data to the
    // output (backwards, since we know the length).  The alternative would be
    // storing something in an intermediate stack, but that doesn't make any
    // more sense.  I implemented an approach where it also stored the length
    // in the code table, although it's a bit tricky because you run out of
    // bits (12 + 12 + 8), but I didn't measure much improvements (the table
    // entries are generally not the long).  Even when I created benchmarks for
    // very long table entries the complexity did not seem worth it.
    // The code table stores the prefix entry in 12 bits and then the suffix
    // byte in 8 bits, so each entry is 20 bits.

    var chase_code = code < next_code ? code : prev_code;

    // Chase what we will output, either {CODE} or {CODE-1}.
    var chase_length = 0;
    var chase = chase_code;
    while (chase > clear_code) {
      chase = code_table[chase] >> 8;
      ++chase_length;
    }

    var k = chase;
    
    var op_end = op + chase_length + (chase_code !== code ? 1 : 0);
    if (op_end > output_length) {
      console.log("Warning, gif stream longer than expected.");
      return;
    }

    // Already have the first byte from the chase, might as well write it fast.
    output[op++] = k;

    op += chase_length;
    var b = op;  // Track pointer, writing backwards.

    if (chase_code !== code)  // The case of emitting {CODE-1} + k.
      output[op++] = k;

    chase = chase_code;
    while (chase_length--) {
      chase = code_table[chase];
      output[--b] = chase & 0xff;  // Write backwards.
      chase >>= 8;  // Pull down to the prefix code.
    }

    if (prev_code !== null && next_code < 4096) {
      code_table[next_code++] = prev_code << 8 | k;
      // TODO(deanm): Figure out this clearing vs code growth logic better.  I
      // have an feeling that it should just happen somewhere else, for now it
      // is awkward between when we grow past the max and then hit a clear code.
      // For now just check if we hit the max 12-bits (then a clear code should
      // follow, also of course encoded in 12-bits).
      if (next_code >= code_mask+1 && cur_code_size < 12) {
        ++cur_code_size;
        code_mask = code_mask << 1 | 1;
      }
    }

    prev_code = code;
  }

  if (op !== output_length) {
    console.log("Warning, gif stream shorter than expected.");
  }

  return output;
}
--- END ---
[deoptimizing (DEOPT soft): begin 0x7bbfe0a7e29 <JS Function GifReaderLZWOutputIndexStream (SharedFunctionInfo 0x2ac9639f3819)> (opt #12) @53, FP to SP delta: 512]
            ;;; deoptimize at 0_5213: Insufficient type feedback for combined type of binary operation
  reading input frame GifReaderLZWOutputIndexStream => node=5, args=290, height=20; inputs:
      0: 0x7bbfe0a7e29 ; (frame function) 0x7bbfe0a7e29 <JS Function GifReaderLZWOutputIndexStream (SharedFunctionInfo 0x2ac9639f3819)>
      1: 0x36cdc0e04131 ; [fp - 288] 0x36cdc0e04131 <undefined>
      2: 0x7bbfe006401 ; [fp - 280] 0x7bbfe006401 <an Uint8Array with map 0x3d4eb9d1d389>
      3: 91597 ; (int) [fp - 440] 
      4: 0x7bbfe0bbaf1 ; [fp - 264] 0x7bbfe0bbaf1 <an Uint8Array with map 0x3d4eb9d1d331>
      5: 0x57e4000000000 ; [fp - 256] 360000
      6: 0x7bbfe0a7cb9 ; [fp - 248] 0x7bbfe0a7cb9 <FixedArray[6]>
      7: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      8: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      9: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     10: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     11: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     12: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     13: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     14: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     15: 0x57e4000000000 ; [fp - 408] 360000
     16: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     17: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     18: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     19: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     20: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     21: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     22: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     23: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     24: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     25: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
  translating frame GifReaderLZWOutputIndexStream => node=290, height=152
    0x7ffc654cd668: [top + 216] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd660: [top + 208] <- 0x7bbfe006401 ;  0x7bbfe006401 <an Uint8Array with map 0x3d4eb9d1d389>  (input #2)
    0x7ffc654cd658: [top + 200] <- 0x165cd00000000 ;  91597  (input #3)
    0x7ffc654cd650: [top + 192] <- 0x7bbfe0bbaf1 ;  0x7bbfe0bbaf1 <an Uint8Array with map 0x3d4eb9d1d331>  (input #4)
    0x7ffc654cd648: [top + 184] <- 0x57e4000000000 ;  360000  (input #5)
    0x7ffc654cd640: [top + 176] <- 0x376e6fee7ace ;  caller's pc
    0x7ffc654cd638: [top + 168] <- 0x7ffc654cd720 ;  caller's fp
    0x7ffc654cd630: [top + 160] <- 0x7bbfe0a7cb9 ;  context    0x7bbfe0a7cb9 <FixedArray[6]>  (input #6)
    0x7ffc654cd628: [top + 152] <- 0x7bbfe0a7e29 ;  function    0x7bbfe0a7e29 <JS Function GifReaderLZWOutputIndexStream (SharedFunctionInfo 0x2ac9639f3819)>  (input #0)
    0x7ffc654cd620: [top + 144] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #7)
    0x7ffc654cd618: [top + 136] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #8)
    0x7ffc654cd610: [top + 128] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #9)
    0x7ffc654cd608: [top + 120] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #10)
    0x7ffc654cd600: [top + 112] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #11)
    0x7ffc654cd5f8: [top + 104] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #12)
    0x7ffc654cd5f0: [top + 96] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #13)
    0x7ffc654cd5e8: [top + 88] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #14)
    0x7ffc654cd5e0: [top + 80] <- 0x57e4000000000 ;  360000  (input #15)
    0x7ffc654cd5d8: [top + 72] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #16)
    0x7ffc654cd5d0: [top + 64] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #17)
    0x7ffc654cd5c8: [top + 56] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #18)
    0x7ffc654cd5c0: [top + 48] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #19)
    0x7ffc654cd5b8: [top + 40] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #20)
    0x7ffc654cd5b0: [top + 32] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #21)
    0x7ffc654cd5a8: [top + 24] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #22)
    0x7ffc654cd5a0: [top + 16] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #23)
    0x7ffc654cd598: [top + 8] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #24)
    0x7ffc654cd590: [top + 0] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #25)
[deoptimizing (soft): end 0x7bbfe0a7e29 <JS Function GifReaderLZWOutputIndexStream (SharedFunctionInfo 0x2ac9639f3819)> @53 => node=290, pc=0x376e6fee94b2, state=NO_REGISTERS, alignment=no padding, took 0.072 ms]
--- FUNCTION SOURCE (GifReader.decodeAndBlitFrameRGBA) id{13,0} ---
(frame_num, pixels) {
    var frame = this.frameInfo(frame_num);
    var num_pixels = frame.width * frame.height;
    var index_stream = new Uint8Array(num_pixels);  // At most 8-bit indices.
    GifReaderLZWOutputIndexStream(
        buf, frame.data_offset, index_stream, num_pixels);
    var palette_offset = frame.palette_offset;

    // NOTE(deanm): It seems to be much faster to compare index to 256 than
    // to === null.  Not sure why, but CompareStub_EQ_STRICT shows up high in
    // the profile, not sure if it's related to using a Uint8Array.
    var trans = frame.transparent_index;
    if (trans === null) trans = 256;

    // We are possibly just blitting to a portion of the entire frame.
    // That is a subrect within the framerect, so the additional pixels
    // must be skipped over after we finished a scanline.
    var framewidth  = frame.width;
    var framestride = width - framewidth;
    var xleft       = framewidth;  // Number of subrect pixels left in scanline.

    // Output indicies of the top left and bottom right corners of the subrect.
    var opbeg = ((frame.y * width) + frame.x) * 4;
    var opend = ((frame.y + frame.height) * width + frame.x) * 4;
    var op    = opbeg;

    var scanstride = framestride * 4;

    // Use scanstride to skip past the rows when interlacing.  This is skipping
    // 7 rows for the first two passes, then 3 then 1.
    if (frame.interlaced === true) {
      scanstride += width * 4 * 7;  // Pass 1.
    }

    var interlaceskip = 8;  // Tracking the row interval in the current pass.

    for (var i = 0, il = index_stream.length; i < il; ++i) {
      var index = index_stream[i];

      if (xleft === 0) {  // Beginning of new scan line
        op += scanstride;
        xleft = framewidth;
        if (op >= opend) { // Catch the wrap to switch passes when interlacing.
          scanstride = framestride * 4 + width * 4 * (interlaceskip-1);
          // interlaceskip / 2 * 4 is interlaceskip << 1.
          op = opbeg + (framewidth + framestride) * (interlaceskip << 1);
          interlaceskip >>= 1;
        }
      }

      if (index === trans) {
        op += 4;
      } else {
        var r = buf[palette_offset + index * 3];
        var g = buf[palette_offset + index * 3 + 1];
        var b = buf[palette_offset + index * 3 + 2];
        pixels[op++] = r;
        pixels[op++] = g;
        pixels[op++] = b;
        pixels[op++] = 255;
      }
      --xleft;
    }
  }
--- END ---
--- FUNCTION SOURCE (GifReaderLZWOutputIndexStream) id{14,0} ---
(code_stream, p, output, output_length) {
  var min_code_size = code_stream[p++];

  var clear_code = 1 << min_code_size;
  var eoi_code = clear_code + 1;
  var next_code = eoi_code + 1;

  var cur_code_size = min_code_size + 1;  // Number of bits per code.
  // NOTE: This shares the same name as the encoder, but has a different
  // meaning here.  Here this masks each code coming from the code stream.
  var code_mask = (1 << cur_code_size) - 1;
  var cur_shift = 0;
  var cur = 0;

  var op = 0;  // Output pointer.
  
  var subblock_size = code_stream[p++];

  // TODO(deanm): Would using a TypedArray be any faster?  At least it would
  // solve the fast mode / backing store uncertainty.
  // var code_table = Array(4096);
  var code_table = new Int32Array(4096);  // Can be signed, we only use 20 bits.

  var prev_code = null;  // Track code-1.

  while (true) {
    // Read up to two bytes, making sure we always 12-bits for max sized code.
    while (cur_shift < 16) {
      if (subblock_size === 0) break;  // No more data to be read.

      cur |= code_stream[p++] << cur_shift;
      cur_shift += 8;

      if (subblock_size === 1) {  // Never let it get to 0 to hold logic above.
        subblock_size = code_stream[p++];  // Next subblock.
      } else {
        --subblock_size;
      }
    }

    // TODO(deanm): We should never really get here, we should have received
    // and EOI.
    if (cur_shift < cur_code_size)
      break;

    var code = cur & code_mask;
    cur >>= cur_code_size;
    cur_shift -= cur_code_size;

    // TODO(deanm): Maybe should check that the first code was a clear code,
    // at least this is what you're supposed to do.  But actually our encoder
    // now doesn't emit a clear code first anyway.
    if (code === clear_code) {
      // We don't actually have to clear the table.  This could be a good idea
      // for greater error checking, but we don't really do any anyway.  We
      // will just track it with next_code and overwrite old entries.

      next_code = eoi_code + 1;
      cur_code_size = min_code_size + 1;
      code_mask = (1 << cur_code_size) - 1;

      // Don't update prev_code ?
      prev_code = null;
      continue;
    } else if (code === eoi_code) {
      break;
    }

    // We have a similar situation as the decoder, where we want to store
    // variable length entries (code table entries), but we want to do in a
    // faster manner than an array of arrays.  The code below stores sort of a
    // linked list within the code table, and then "chases" through it to
    // construct the dictionary entries.  When a new entry is created, just the
    // last byte is stored, and the rest (prefix) of the entry is only
    // referenced by its table entry.  Then the code chases through the
    // prefixes until it reaches a single byte code.  We have to chase twice,
    // first to compute the length, and then to actually copy the data to the
    // output (backwards, since we know the length).  The alternative would be
    // storing something in an intermediate stack, but that doesn't make any
    // more sense.  I implemented an approach where it also stored the length
    // in the code table, although it's a bit tricky because you run out of
    // bits (12 + 12 + 8), but I didn't measure much improvements (the table
    // entries are generally not the long).  Even when I created benchmarks for
    // very long table entries the complexity did not seem worth it.
    // The code table stores the prefix entry in 12 bits and then the suffix
    // byte in 8 bits, so each entry is 20 bits.

    var chase_code = code < next_code ? code : prev_code;

    // Chase what we will output, either {CODE} or {CODE-1}.
    var chase_length = 0;
    var chase = chase_code;
    while (chase > clear_code) {
      chase = code_table[chase] >> 8;
      ++chase_length;
    }

    var k = chase;
    
    var op_end = op + chase_length + (chase_code !== code ? 1 : 0);
    if (op_end > output_length) {
      console.log("Warning, gif stream longer than expected.");
      return;
    }

    // Already have the first byte from the chase, might as well write it fast.
    output[op++] = k;

    op += chase_length;
    var b = op;  // Track pointer, writing backwards.

    if (chase_code !== code)  // The case of emitting {CODE-1} + k.
      output[op++] = k;

    chase = chase_code;
    while (chase_length--) {
      chase = code_table[chase];
      output[--b] = chase & 0xff;  // Write backwards.
      chase >>= 8;  // Pull down to the prefix code.
    }

    if (prev_code !== null && next_code < 4096) {
      code_table[next_code++] = prev_code << 8 | k;
      // TODO(deanm): Figure out this clearing vs code growth logic better.  I
      // have an feeling that it should just happen somewhere else, for now it
      // is awkward between when we grow past the max and then hit a clear code.
      // For now just check if we hit the max 12-bits (then a clear code should
      // follow, also of course encoded in 12-bits).
      if (next_code >= code_mask+1 && cur_code_size < 12) {
        ++cur_code_size;
        code_mask = code_mask << 1 | 1;
      }
    }

    prev_code = code;
  }

  if (op !== output_length) {
    console.log("Warning, gif stream shorter than expected.");
  }

  return output;
}
--- END ---
--- FUNCTION SOURCE (ArrayBuffer) id{15,0} ---
(i){
if(%_IsConstructCall()){
var j=$toPositiveInteger(i,125);
%ArrayBufferInitialize(this,j,false);
}else{
throw MakeTypeError(20,"ArrayBuffer");
}
}
--- END ---
--- FUNCTION SOURCE (slice) id{16,0} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
--- FUNCTION SOURCE () id{17,0} ---
(a, b) {
    return (a[0] + a[1] + a[2] + a[3]) - (b[0] + b[1] + b[2] + b[3])
  }
--- END ---
--- FUNCTION SOURCE (subarray) id{18,0} ---
(R,S){
if(!(%_ClassOf(this)==='Uint8Array')){
throw MakeTypeError(33,"Uint8Array.subarray",this);
}
var T=(%_IsSmi(%IS_VAR(R))?R:%NumberToInteger($toNumber(R)));
if(!(S===(void 0))){
S=(%_IsSmi(%IS_VAR(S))?S:%NumberToInteger($toNumber(S)));
}
var U=%_TypedArrayGetLength(this);
if(T<0){
T=q(0,U+T);
}else{
T=r(U,T);
}
var V=(S===(void 0))?U:S;
if(V<0){
V=q(0,U+V);
}else{
V=r(V,U);
}
if(V<T){
V=T;
}
var C=V-T;
var W=
%_ArrayBufferViewGetByteOffset(this)+T*1;
return new h(%TypedArrayGetBuffer(this),
W,C);
}
--- END ---
--- FUNCTION SOURCE (Uint8ArrayConstructByArrayBuffer) id{19,0} ---
(v,w,x,y){
if(!(x===(void 0))){
x=
$toPositiveInteger(x,139);
}
if(!(y===(void 0))){
y=$toPositiveInteger(y,139);
}
var z=%_ArrayBufferGetByteLength(w);
var A;
if((x===(void 0))){
A=0;
}else{
A=x;
if(A % 1!==0){
throw MakeRangeError(138,
"start offset","Uint8Array",1);
}
if(A>z){
throw MakeRangeError(140);
}
}
var B;
var C;
if((y===(void 0))){
if(z % 1!==0){
throw MakeRangeError(138,
"byte length","Uint8Array",1);
}
B=z-A;
C=B/1;
}else{
var C=y;
B=C*1;
}
if((A+B>z)
||(C>%_MaxSmi())){
throw MakeRangeError(139);
}
%_TypedArrayInitialize(v,1,w,A,B,true);
}
--- END ---
--- FUNCTION SOURCE (Buffer) id{20,0} ---
(arg) {
  // Common case.
  if (typeof arg === 'number') {
    // If less than zero, or NaN.
    if (arg < 0 || arg !== arg)
      arg = 0;
    return allocate(arg);
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(arg, arguments[1]);
  }

  // Unusual.
  return fromObject(arg);
}
--- END ---
--- FUNCTION SOURCE (fromString) id{20,1} ---
(string, encoding) {
  if (typeof encoding !== 'string' || encoding === '')
    encoding = 'utf8';

  var length = byteLength(string, encoding);
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}
--- END ---
INLINE (fromString) id{20,1} AS 1 AT <0:247>
--- FUNCTION SOURCE (slice) id{20,2} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{20,2} AS 2 AT <1:382>
--- FUNCTION SOURCE (alignPool) id{20,3} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{20,3} AS 3 AT <1:448>
--- FUNCTION SOURCE (QuickSort) id{21,0} ---
(y,m,aF){
var aM=0;
while(true){
if(aF-m<=10){
aE(y,m,aF);
return;
}
if(aF-m>1000){
aM=aJ(y,m,aF);
}else{
aM=m+((aF-m)>>1);
}
var aO=y[m];
var aP=y[aF-1];
var aQ=y[aM];
var aR=%_CallFunction((void 0),aO,aP,aC);
if(aR>0){
var aH=aO;
aO=aP;
aP=aH;
}
var aS=%_CallFunction((void 0),aO,aQ,aC);
if(aS>=0){
var aH=aO;
aO=aQ;
aQ=aP;
aP=aH;
}else{
var aT=%_CallFunction((void 0),aP,aQ,aC);
if(aT>0){
var aH=aP;
aP=aQ;
aQ=aH;
}
}
y[m]=aO;
y[aF-1]=aQ;
var aU=aP;
var aV=m+1;
var aW=aF-1;
y[aM]=y[aV];
y[aV]=aU;
partition:for(var t=aV+1;t<aW;t++){
var aG=y[t];
var aI=%_CallFunction((void 0),aG,aU,aC);
if(aI<0){
y[t]=y[aV];
y[aV]=aG;
aV++;
}else if(aI>0){
do{
aW--;
if(aW==t)break partition;
var aX=y[aW];
aI=%_CallFunction((void 0),aX,aU,aC);
}while(aI>0);
y[t]=y[aW];
y[aW]=aG;
if(aI<0){
aG=y[t];
y[t]=y[aV];
y[aV]=aG;
aV++;
}
}
}
if(aF-aW<aV-m){
aN(y,aW,aF);
aF=aV;
}else{
aN(y,m,aV);
m=aW;
}
}
}
--- END ---
--- FUNCTION SOURCE (alignPool) id{22,0} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
--- FUNCTION SOURCE (sortPixels) id{23,0} ---
(pixels) {
  var split = []
  for (var i = 0; i < pixels.length; i += 4) {
    split.push(pixels.slice(i, i + 4))
  }
  var sorted = split.sort(function (a, b) {
    return (a[0] + a[1] + a[2] + a[3]) - (b[0] + b[1] + b[2] + b[3])
  })
  var newbuff = new Buffer(pixels.length)
  for (var j = 0; j < sorted.length; j++) {
    newbuff[j * 4] = sorted[j][0]
    newbuff[j * 4 + 1] = sorted[j][1]
    newbuff[j * 4 + 2] = sorted[j][2]
    newbuff[j * 4 + 3] = sorted[j][3]
  }
  return newbuff
}
--- END ---
--- FUNCTION SOURCE (slice) id{23,1} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{23,1} AS 1 AT <0:97>
--- FUNCTION SOURCE (Buffer) id{23,2} ---
(arg) {
  // Common case.
  if (typeof arg === 'number') {
    // If less than zero, or NaN.
    if (arg < 0 || arg !== arg)
      arg = 0;
    return allocate(arg);
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(arg, arguments[1]);
  }

  // Unusual.
  return fromObject(arg);
}
--- END ---
INLINE (Buffer) id{23,2} AS 2 AT <0:252>
--- FUNCTION SOURCE (fromString) id{23,3} ---
(string, encoding) {
  if (typeof encoding !== 'string' || encoding === '')
    encoding = 'utf8';

  var length = byteLength(string, encoding);
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}
--- END ---
INLINE (fromString) id{23,3} AS 3 AT <2:247>
--- FUNCTION SOURCE (slice) id{23,4} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{23,4} AS 4 AT <3:382>
--- FUNCTION SOURCE (alignPool) id{23,5} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{23,5} AS 5 AT <3:448>
--- FUNCTION SOURCE (min) id{24,0} ---
(h,i){
var j=%_ArgumentsLength();
if(j==2){
h=((typeof(%IS_VAR(h))==='number')?h:$nonNumberToNumber(h));
i=((typeof(%IS_VAR(i))==='number')?i:$nonNumberToNumber(i));
if(i>h)return h;
if(h>i)return i;
if(h==i){
return(h===0&&%_IsMinusZero(h))?h:i;
}
return $NaN;
}
var k=(1/0);
for(var l=0;l<j;l++){
var m=%_Arguments(l);
m=((typeof(%IS_VAR(m))==='number')?m:$nonNumberToNumber(m));
if((!%_IsSmi(%IS_VAR(m))&&!(m==m))||m<k||(k===0&&m===0&&%_IsMinusZero(m))){
k=m;
}
}
return k;
}
--- END ---
--- FUNCTION SOURCE (ToPositiveInteger) id{25,0} ---
(i,aa){
var M=(%_IsSmi(%IS_VAR(i))?i:%NumberToIntegerMapMinusZero($toNumber(i)));
if(M<0)throw MakeRangeError(aa);
return M;
}
--- END ---
--- FUNCTION SOURCE (medianPixel) id{26,0} ---
(pixels) {
  var sorted = sortPixels(pixels)
  var mid = (sorted.length / 2) - ((sorted.length / 2) % 4)
  return sorted.slice(mid, mid + 4)
}
--- END ---
--- FUNCTION SOURCE (sortPixels) id{26,1} ---
(pixels) {
  var split = []
  for (var i = 0; i < pixels.length; i += 4) {
    split.push(pixels.slice(i, i + 4))
  }
  var sorted = split.sort(function (a, b) {
    return (a[0] + a[1] + a[2] + a[3]) - (b[0] + b[1] + b[2] + b[3])
  })
  var newbuff = new Buffer(pixels.length)
  for (var j = 0; j < sorted.length; j++) {
    newbuff[j * 4] = sorted[j][0]
    newbuff[j * 4 + 1] = sorted[j][1]
    newbuff[j * 4 + 2] = sorted[j][2]
    newbuff[j * 4 + 3] = sorted[j][3]
  }
  return newbuff
}
--- END ---
INLINE (sortPixels) id{26,1} AS 1 AT <0:26>
--- FUNCTION SOURCE (slice) id{26,2} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{26,2} AS 2 AT <1:97>
--- FUNCTION SOURCE (Buffer) id{26,3} ---
(arg) {
  // Common case.
  if (typeof arg === 'number') {
    // If less than zero, or NaN.
    if (arg < 0 || arg !== arg)
      arg = 0;
    return allocate(arg);
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(arg, arguments[1]);
  }

  // Unusual.
  return fromObject(arg);
}
--- END ---
INLINE (Buffer) id{26,3} AS 3 AT <1:252>
--- FUNCTION SOURCE (fromString) id{26,4} ---
(string, encoding) {
  if (typeof encoding !== 'string' || encoding === '')
    encoding = 'utf8';

  var length = byteLength(string, encoding);
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}
--- END ---
INLINE (fromString) id{26,4} AS 4 AT <3:247>
--- FUNCTION SOURCE (slice) id{26,5} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{26,5} AS 5 AT <4:382>
--- FUNCTION SOURCE (alignPool) id{26,6} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{26,6} AS 6 AT <4:448>
--- FUNCTION SOURCE (slice) id{26,7} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{26,7} AS 7 AT <0:121>
--- FUNCTION SOURCE (sort) id{27,0} ---
(aC){
if((this==null)&&!(%_IsUndetectableObject(this)))throw MakeTypeError(14,"Array.prototype.sort");
var o=$toObject(this);
var v=(o.length>>>0);
return %_CallFunction(o,v,aC,InnerArraySort);
}
--- END ---
--- FUNCTION SOURCE (allocate) id{28,0} ---
(size) {
  if (size === 0) {
    const ui8 = new Uint8Array(size);
    Object.setPrototypeOf(ui8, Buffer.prototype);
    return ui8;
  }
  if (size < (Buffer.poolSize >>> 1)) {
    if (size > (poolSize - poolOffset))
      createPool();
    var b = allocPool.slice(poolOffset, poolOffset + size);
    poolOffset += size;
    alignPool();
    return b;
  } else {
    // Even though this is checked above, the conditional is a safety net and
    // sanity check to prevent any subsequent typed array allocation from not
    // being zero filled.
    if (size > 0)
      flags[kNoZeroFill] = 1;
    const ui8 = new Uint8Array(size);
    Object.setPrototypeOf(ui8, Buffer.prototype);
    return ui8;
  }
}
--- END ---
--- FUNCTION SOURCE (createPool) id{28,1} ---
() {
  poolSize = Buffer.poolSize;
  if (poolSize > 0)
    flags[kNoZeroFill] = 1;
  allocPool = new Uint8Array(poolSize);
  Object.setPrototypeOf(allocPool, Buffer.prototype);
  poolOffset = 0;
}
--- END ---
INLINE (createPool) id{28,1} AS 1 AT <0:223>
--- FUNCTION SOURCE (slice) id{28,2} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{28,2} AS 2 AT <0:259>
--- FUNCTION SOURCE (alignPool) id{28,3} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{28,3} AS 3 AT <0:325>
--- FUNCTION SOURCE (Uint8ArrayConstructByLength) id{29,0} ---
(v,y){
var D=(y===(void 0))?
0:$toPositiveInteger(y,139);
if(D>%_MaxSmi()){
throw MakeRangeError(139);
}
var E=D*1;
if(E>%_TypedArrayMaxSizeInHeap()){
var w=new d(E);
%_TypedArrayInitialize(v,1,w,0,E,true);
}else{
%_TypedArrayInitialize(v,1,null,0,E,true);
}
}
--- END ---
--- FUNCTION SOURCE (Uint8Array) id{30,0} ---
(O,P,Q){
if(%_IsConstructCall()){
if((%_ClassOf(O)==='ArrayBuffer')||(%_ClassOf(O)==='SharedArrayBuffer')){
Uint8ArrayConstructByArrayBuffer(this,O,P,Q);
}else if((typeof(O)==='number')||(typeof(O)==='string')||
(typeof(O)==='boolean')||(O===(void 0))){
Uint8ArrayConstructByLength(this,O);
}else{
var J=O[symbolIterator];
if((J===(void 0))||J===$arrayValues){
Uint8ArrayConstructByArrayLike(this,O);
}else{
Uint8ArrayConstructByIterable(this,O,J);
}
}
}else{
throw MakeTypeError(20,"Uint8Array")
}
}
--- END ---
--- FUNCTION SOURCE (setPrototypeOf) id{31,0} ---
(J,am){
if((J==null)&&!(%_IsUndetectableObject(J)))throw MakeTypeError(14,"Object.setPrototypeOf");
if(am!==null&&!(%_IsSpecObject(am))){
throw MakeTypeError(79,am);
}
if((%_IsSpecObject(J))){
%SetPrototype(J,am);
}
return J;
}
--- END ---
--- FUNCTION SOURCE (InnerArraySort) id{32,0} ---
(v,aC){
if(!(%_ClassOf(aC)==='Function')){
aC=function(O,aD){
if(O===aD)return 0;
if(%_IsSmi(O)&&%_IsSmi(aD)){
return %SmiLexicographicCompare(O,aD);
}
O=$toString(O);
aD=$toString(aD);
if(O==aD)return 0;
else return O<aD?-1:1;
};
}
var aE=function InsertionSort(y,m,aF){
for(var t=m+1;t<aF;t++){
var aG=y[t];
for(var am=t-1;am>=m;am--){
var aH=y[am];
var aI=%_CallFunction((void 0),aH,aG,aC);
if(aI>0){
y[am+1]=aH;
}else{
break;
}
}
y[am+1]=aG;
}
};
var aJ=function(y,m,aF){
var aK=[];
var aL=200+((aF-m)&15);
for(var t=m+1,am=0;t<aF-1;t+=aL,am++){
aK[am]=[t,y[t]];
}
%_CallFunction(aK,function(y,z){
return %_CallFunction((void 0),y[1],z[1],aC);
},ArraySort);
var aM=aK[aK.length>>1][0];
return aM;
}
var aN=function QuickSort(y,m,aF){
var aM=0;
while(true){
if(aF-m<=10){
aE(y,m,aF);
return;
}
if(aF-m>1000){
aM=aJ(y,m,aF);
}else{
aM=m+((aF-m)>>1);
}
var aO=y[m];
var aP=y[aF-1];
var aQ=y[aM];
var aR=%_CallFunction((void 0),aO,aP,aC);
if(aR>0){
var aH=aO;
aO=aP;
aP=aH;
}
var aS=%_CallFunction((void 0),aO,aQ,aC);
if(aS>=0){
var aH=aO;
aO=aQ;
aQ=aP;
aP=aH;
}else{
var aT=%_CallFunction((void 0),aP,aQ,aC);
if(aT>0){
var aH=aP;
aP=aQ;
aQ=aH;
}
}
y[m]=aO;
y[aF-1]=aQ;
var aU=aP;
var aV=m+1;
var aW=aF-1;
y[aM]=y[aV];
y[aV]=aU;
partition:for(var t=aV+1;t<aW;t++){
var aG=y[t];
var aI=%_CallFunction((void 0),aG,aU,aC);
if(aI<0){
y[t]=y[aV];
y[aV]=aG;
aV++;
}else if(aI>0){
do{
aW--;
if(aW==t)break partition;
var aX=y[aW];
aI=%_CallFunction((void 0),aX,aU,aC);
}while(aI>0);
y[t]=y[aW];
y[aW]=aG;
if(aI<0){
aG=y[t];
y[t]=y[aV];
y[aV]=aG;
aV++;
}
}
}
if(aF-aW<aV-m){
aN(y,aW,aF);
aF=aV;
}else{
aN(y,m,aV);
m=aW;
}
}
};
var aY=function CopyFromPrototype(aZ,v){
var ba=0;
for(var bb=%_GetPrototype(aZ);bb;bb=%_GetPrototype(bb)){
var p=%GetArrayKeys(bb,v);
if((typeof(p)==='number')){
var bc=p;
for(var t=0;t<bc;t++){
if(!(%_CallFunction(aZ,t,i))&&(%_CallFunction(bb,t,i))){
aZ[t]=bb[t];
if(t>=ba){ba=t+1;}
}
}
}else{
for(var t=0;t<p.length;t++){
var Y=p[t];
if(!(Y===(void 0))&&!(%_CallFunction(aZ,Y,i))
&&(%_CallFunction(bb,Y,i))){
aZ[Y]=bb[Y];
if(Y>=ba){ba=Y+1;}
}
}
}
}
return ba;
};
var bd=function(aZ,m,aF){
for(var bb=%_GetPrototype(aZ);bb;bb=%_GetPrototype(bb)){
var p=%GetArrayKeys(bb,aF);
if((typeof(p)==='number')){
var bc=p;
for(var t=m;t<bc;t++){
if((%_CallFunction(bb,t,i))){
aZ[t]=(void 0);
}
}
}else{
for(var t=0;t<p.length;t++){
var Y=p[t];
if(!(Y===(void 0))&&m<=Y&&
(%_CallFunction(bb,Y,i))){
aZ[Y]=(void 0);
}
}
}
}
};
var be=function SafeRemoveArrayHoles(aZ){
var bf=0;
var bg=v-1;
var bh=0;
while(bf<bg){
while(bf<bg&&
!(aZ[bf]===(void 0))){
bf++;
}
if(!(%_CallFunction(aZ,bf,i))){
bh++;
}
while(bf<bg&&
(aZ[bg]===(void 0))){
if(!(%_CallFunction(aZ,bg,i))){
bh++;
}
bg--;
}
if(bf<bg){
aZ[bf]=aZ[bg];
aZ[bg]=(void 0);
}
}
if(!(aZ[bf]===(void 0)))bf++;
var t;
for(t=bf;t<v-bh;t++){
aZ[t]=(void 0);
}
for(t=v-bh;t<v;t++){
if(t in %_GetPrototype(aZ)){
aZ[t]=(void 0);
}else{
delete aZ[t];
}
}
return bf;
};
if(v<2)return this;
var J=(%_IsArray(this));
var bi;
if(!J){
bi=aY(this,v);
}
var bj=%RemoveArrayHoles(this,v);
if(bj==-1){
bj=be(this);
}
aN(this,0,bj);
if(!J&&(bj+1<bi)){
bd(this,bj,bi);
}
return this;
}
--- END ---
--- FUNCTION SOURCE (avg) id{33,0} ---
(frames, alg) {
  // Some images strangely have different pixel counts per frame.
  // Pick the largest and go with that I guess?
  var len = frames.reduce(function min(p, c) {
    var length = c.data.length
    if (length <= p) {
      return length
    }
    return p
  }, Number.MAX_VALUE)

  if (len === 1) {
    return frames[0].data
  }
  var avgFrame = new Buffer(len)
  for (var i = 0; i < len; i += 4) {
    var pixels = new Buffer(4 * frames.length)
    for (var j = 0; j < frames.length; j++) {
      frames[j].data.copy(pixels, j * 4, i, i + 4)
      //pixels[j*4] = frames[j].data[i]
      //pixels[j*4+1] = frames[j].data[i+1]
      //pixels[j*4+2] = frames[j].data[i+2]
      //pixels[j*4+3] = frames[j].data[i+3]
    }
    var avgPixel = alg(pixels)
    avgPixel.copy(avgFrame, i)
  }
  return avgFrame
}
--- END ---
--- FUNCTION SOURCE (Buffer) id{33,1} ---
(arg) {
  // Common case.
  if (typeof arg === 'number') {
    // If less than zero, or NaN.
    if (arg < 0 || arg !== arg)
      arg = 0;
    return allocate(arg);
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(arg, arguments[1]);
  }

  // Unusual.
  return fromObject(arg);
}
--- END ---
INLINE (Buffer) id{33,1} AS 1 AT <0:360>
--- FUNCTION SOURCE (fromString) id{33,2} ---
(string, encoding) {
  if (typeof encoding !== 'string' || encoding === '')
    encoding = 'utf8';

  var length = byteLength(string, encoding);
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}
--- END ---
INLINE (fromString) id{33,2} AS 2 AT <1:247>
--- FUNCTION SOURCE (slice) id{33,3} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{33,3} AS 3 AT <2:382>
--- FUNCTION SOURCE (alignPool) id{33,4} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{33,4} AS 4 AT <2:448>
--- FUNCTION SOURCE (Buffer) id{33,5} ---
(arg) {
  // Common case.
  if (typeof arg === 'number') {
    // If less than zero, or NaN.
    if (arg < 0 || arg !== arg)
      arg = 0;
    return allocate(arg);
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(arg, arguments[1]);
  }

  // Unusual.
  return fromObject(arg);
}
--- END ---
INLINE (Buffer) id{33,5} AS 5 AT <0:430>
--- FUNCTION SOURCE (fromString) id{33,6} ---
(string, encoding) {
  if (typeof encoding !== 'string' || encoding === '')
    encoding = 'utf8';

  var length = byteLength(string, encoding);
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}
--- END ---
INLINE (fromString) id{33,6} AS 6 AT <5:247>
--- FUNCTION SOURCE (slice) id{33,7} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{33,7} AS 7 AT <6:382>
--- FUNCTION SOURCE (alignPool) id{33,8} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{33,8} AS 8 AT <6:448>
--- FUNCTION SOURCE (medianPixel) id{33,9} ---
(pixels) {
  var sorted = sortPixels(pixels)
  var mid = (sorted.length / 2) - ((sorted.length / 2) % 4)
  return sorted.slice(mid, mid + 4)
}
--- END ---
INLINE (medianPixel) id{33,9} AS 9 AT <0:754>
--- FUNCTION SOURCE (sortPixels) id{33,10} ---
(pixels) {
  var split = []
  for (var i = 0; i < pixels.length; i += 4) {
    split.push(pixels.slice(i, i + 4))
  }
  var sorted = split.sort(function (a, b) {
    return (a[0] + a[1] + a[2] + a[3]) - (b[0] + b[1] + b[2] + b[3])
  })
  var newbuff = new Buffer(pixels.length)
  for (var j = 0; j < sorted.length; j++) {
    newbuff[j * 4] = sorted[j][0]
    newbuff[j * 4 + 1] = sorted[j][1]
    newbuff[j * 4 + 2] = sorted[j][2]
    newbuff[j * 4 + 3] = sorted[j][3]
  }
  return newbuff
}
--- END ---
INLINE (sortPixels) id{33,10} AS 10 AT <9:26>
--- FUNCTION SOURCE (slice) id{33,11} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{33,11} AS 11 AT <10:97>
--- FUNCTION SOURCE (Buffer) id{33,12} ---
(arg) {
  // Common case.
  if (typeof arg === 'number') {
    // If less than zero, or NaN.
    if (arg < 0 || arg !== arg)
      arg = 0;
    return allocate(arg);
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(arg, arguments[1]);
  }

  // Unusual.
  return fromObject(arg);
}
--- END ---
INLINE (Buffer) id{33,12} AS 12 AT <10:252>
--- FUNCTION SOURCE (fromString) id{33,13} ---
(string, encoding) {
  if (typeof encoding !== 'string' || encoding === '')
    encoding = 'utf8';

  var length = byteLength(string, encoding);
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}
--- END ---
INLINE (fromString) id{33,13} AS 13 AT <12:247>
--- FUNCTION SOURCE (slice) id{33,14} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{33,14} AS 14 AT <13:382>
--- FUNCTION SOURCE (alignPool) id{33,15} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{33,15} AS 15 AT <13:448>
[deoptimizing (DEOPT eager): begin 0x100fecf4dc39 <JS Function avg (SharedFunctionInfo 0x2ac96392ee49)> (opt #33) @45, FP to SP delta: 440]
            ;;; deoptimize at 5_272: out of bounds
  reading input frame avg => node=3, args=106, height=7; inputs:
      0: 0x100fecf4dc39 ; (frame function) 0x100fecf4dc39 <JS Function avg (SharedFunctionInfo 0x2ac96392ee49)>
      1: 0x36cdc0e04131 ; r9 0x36cdc0e04131 <undefined>
      2: 0x100fecfa5909 ; r8 0x100fecfa5909 <JS Array[51]>
      3: 0x100fecf4dbf1 ; rsi 0x100fecf4dbf1 <JS Function medianPixel (SharedFunctionInfo 0x2ac96392eba9)>
      4: 0x100fecf4dac9 ; rcx 0x100fecf4dac9 <FixedArray[26]>
      5: 1440000 ; rdx 
      6: 0x100fecfa58b9 ; rbx 0x100fecfa58b9 <an Uint8Array with map 0x3d4eb9d1d389>
      7: 1788 ; rax 
      8: 0x36cdc0e04131 ; (literal 7) 0x36cdc0e04131 <undefined>
      9: 0x36cdc0e04131 ; (literal 7) 0x36cdc0e04131 <undefined>
     10: 0x36cdc0e04131 ; (literal 7) 0x36cdc0e04131 <undefined>
  translating frame avg => node=106, height=48
    0x7ffc654cd5f0: [top + 96] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd5e8: [top + 88] <- 0x100fecfa5909 ;  0x100fecfa5909 <JS Array[51]>  (input #2)
    0x7ffc654cd5e0: [top + 80] <- 0x100fecf4dbf1 ;  0x100fecf4dbf1 <JS Function medianPixel (SharedFunctionInfo 0x2ac96392eba9)>  (input #3)
    0x7ffc654cd5d8: [top + 72] <- 0x376e6fef0f21 ;  caller's pc
    0x7ffc654cd5d0: [top + 64] <- 0x7ffc654cd610 ;  caller's fp
    0x7ffc654cd5c8: [top + 56] <- 0x100fecf4dac9 ;  context    0x100fecf4dac9 <FixedArray[26]>  (input #4)
    0x7ffc654cd5c0: [top + 48] <- 0x100fecf4dc39 ;  function    0x100fecf4dc39 <JS Function avg (SharedFunctionInfo 0x2ac96392ee49)>  (input #0)
    0x7ffc654cd5b8: [top + 40] <- 0x15f90000000000 ;  1440000  (input #5)
    0x7ffc654cd5b0: [top + 32] <- 0x100fecfa58b9 ;  0x100fecfa58b9 <an Uint8Array with map 0x3d4eb9d1d389>  (input #6)
    0x7ffc654cd5a8: [top + 24] <- 0x6fc00000000 ;  1788  (input #7)
    0x7ffc654cd5a0: [top + 16] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #8)
    0x7ffc654cd598: [top + 8] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #9)
    0x7ffc654cd590: [top + 0] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #10)
[deoptimizing (eager): end 0x100fecf4dc39 <JS Function avg (SharedFunctionInfo 0x2ac96392ee49)> @45 => node=106, pc=0x376e6fef14e0, state=NO_REGISTERS, alignment=no padding, took 0.052 ms]
--- FUNCTION SOURCE (InsertionSort) id{34,0} ---
(y,m,aF){
for(var t=m+1;t<aF;t++){
var aG=y[t];
for(var am=t-1;am>=m;am--){
var aH=y[am];
var aI=%_CallFunction((void 0),aH,aG,aC);
if(aI>0){
y[am+1]=aH;
}else{
break;
}
}
y[am+1]=aG;
}
}
--- END ---
--- FUNCTION SOURCE (avg) id{35,0} ---
(frames, alg) {
  // Some images strangely have different pixel counts per frame.
  // Pick the largest and go with that I guess?
  var len = frames.reduce(function min(p, c) {
    var length = c.data.length
    if (length <= p) {
      return length
    }
    return p
  }, Number.MAX_VALUE)

  if (len === 1) {
    return frames[0].data
  }
  var avgFrame = new Buffer(len)
  for (var i = 0; i < len; i += 4) {
    var pixels = new Buffer(4 * frames.length)
    for (var j = 0; j < frames.length; j++) {
      frames[j].data.copy(pixels, j * 4, i, i + 4)
      //pixels[j*4] = frames[j].data[i]
      //pixels[j*4+1] = frames[j].data[i+1]
      //pixels[j*4+2] = frames[j].data[i+2]
      //pixels[j*4+3] = frames[j].data[i+3]
    }
    var avgPixel = alg(pixels)
    avgPixel.copy(avgFrame, i)
  }
  return avgFrame
}
--- END ---
--- FUNCTION SOURCE (Buffer) id{35,1} ---
(arg) {
  // Common case.
  if (typeof arg === 'number') {
    // If less than zero, or NaN.
    if (arg < 0 || arg !== arg)
      arg = 0;
    return allocate(arg);
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(arg, arguments[1]);
  }

  // Unusual.
  return fromObject(arg);
}
--- END ---
INLINE (Buffer) id{35,1} AS 1 AT <0:360>
--- FUNCTION SOURCE (fromString) id{35,2} ---
(string, encoding) {
  if (typeof encoding !== 'string' || encoding === '')
    encoding = 'utf8';

  var length = byteLength(string, encoding);
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}
--- END ---
INLINE (fromString) id{35,2} AS 2 AT <1:247>
--- FUNCTION SOURCE (slice) id{35,3} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{35,3} AS 3 AT <2:382>
--- FUNCTION SOURCE (alignPool) id{35,4} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{35,4} AS 4 AT <2:448>
--- FUNCTION SOURCE (Buffer) id{35,5} ---
(arg) {
  // Common case.
  if (typeof arg === 'number') {
    // If less than zero, or NaN.
    if (arg < 0 || arg !== arg)
      arg = 0;
    return allocate(arg);
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(arg, arguments[1]);
  }

  // Unusual.
  return fromObject(arg);
}
--- END ---
INLINE (Buffer) id{35,5} AS 5 AT <0:430>
--- FUNCTION SOURCE (fromString) id{35,6} ---
(string, encoding) {
  if (typeof encoding !== 'string' || encoding === '')
    encoding = 'utf8';

  var length = byteLength(string, encoding);
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}
--- END ---
INLINE (fromString) id{35,6} AS 6 AT <5:247>
--- FUNCTION SOURCE (slice) id{35,7} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{35,7} AS 7 AT <6:382>
--- FUNCTION SOURCE (alignPool) id{35,8} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{35,8} AS 8 AT <6:448>
--- FUNCTION SOURCE (medianPixel) id{35,9} ---
(pixels) {
  var sorted = sortPixels(pixels)
  var mid = (sorted.length / 2) - ((sorted.length / 2) % 4)
  return sorted.slice(mid, mid + 4)
}
--- END ---
INLINE (medianPixel) id{35,9} AS 9 AT <0:754>
--- FUNCTION SOURCE (sortPixels) id{35,10} ---
(pixels) {
  var split = []
  for (var i = 0; i < pixels.length; i += 4) {
    split.push(pixels.slice(i, i + 4))
  }
  var sorted = split.sort(function (a, b) {
    return (a[0] + a[1] + a[2] + a[3]) - (b[0] + b[1] + b[2] + b[3])
  })
  var newbuff = new Buffer(pixels.length)
  for (var j = 0; j < sorted.length; j++) {
    newbuff[j * 4] = sorted[j][0]
    newbuff[j * 4 + 1] = sorted[j][1]
    newbuff[j * 4 + 2] = sorted[j][2]
    newbuff[j * 4 + 3] = sorted[j][3]
  }
  return newbuff
}
--- END ---
INLINE (sortPixels) id{35,10} AS 10 AT <9:26>
--- FUNCTION SOURCE (slice) id{35,11} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{35,11} AS 11 AT <10:97>
--- FUNCTION SOURCE (Buffer) id{35,12} ---
(arg) {
  // Common case.
  if (typeof arg === 'number') {
    // If less than zero, or NaN.
    if (arg < 0 || arg !== arg)
      arg = 0;
    return allocate(arg);
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(arg, arguments[1]);
  }

  // Unusual.
  return fromObject(arg);
}
--- END ---
INLINE (Buffer) id{35,12} AS 12 AT <10:252>
--- FUNCTION SOURCE (fromString) id{35,13} ---
(string, encoding) {
  if (typeof encoding !== 'string' || encoding === '')
    encoding = 'utf8';

  var length = byteLength(string, encoding);
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}
--- END ---
INLINE (fromString) id{35,13} AS 13 AT <12:247>
--- FUNCTION SOURCE (slice) id{35,14} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{35,14} AS 14 AT <13:382>
--- FUNCTION SOURCE (alignPool) id{35,15} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{35,15} AS 15 AT <13:448>
--- FUNCTION SOURCE () id{36,0} ---
(a, b) {
    return (a[0] + a[1] + a[2] + a[3]) - (b[0] + b[1] + b[2] + b[3])
  }
--- END ---
--- FUNCTION SOURCE (QuickSort) id{37,0} ---
(y,m,aF){
var aM=0;
while(true){
if(aF-m<=10){
aE(y,m,aF);
return;
}
if(aF-m>1000){
aM=aJ(y,m,aF);
}else{
aM=m+((aF-m)>>1);
}
var aO=y[m];
var aP=y[aF-1];
var aQ=y[aM];
var aR=%_CallFunction((void 0),aO,aP,aC);
if(aR>0){
var aH=aO;
aO=aP;
aP=aH;
}
var aS=%_CallFunction((void 0),aO,aQ,aC);
if(aS>=0){
var aH=aO;
aO=aQ;
aQ=aP;
aP=aH;
}else{
var aT=%_CallFunction((void 0),aP,aQ,aC);
if(aT>0){
var aH=aP;
aP=aQ;
aQ=aH;
}
}
y[m]=aO;
y[aF-1]=aQ;
var aU=aP;
var aV=m+1;
var aW=aF-1;
y[aM]=y[aV];
y[aV]=aU;
partition:for(var t=aV+1;t<aW;t++){
var aG=y[t];
var aI=%_CallFunction((void 0),aG,aU,aC);
if(aI<0){
y[t]=y[aV];
y[aV]=aG;
aV++;
}else if(aI>0){
do{
aW--;
if(aW==t)break partition;
var aX=y[aW];
aI=%_CallFunction((void 0),aX,aU,aC);
}while(aI>0);
y[t]=y[aW];
y[aW]=aG;
if(aI<0){
aG=y[t];
y[t]=y[aV];
y[aV]=aG;
aV++;
}
}
}
if(aF-aW<aV-m){
aN(y,aW,aF);
aF=aV;
}else{
aN(y,m,aV);
m=aW;
}
}
}
--- END ---
--- FUNCTION SOURCE (InsertionSort) id{38,0} ---
(y,m,aF){
for(var t=m+1;t<aF;t++){
var aG=y[t];
for(var am=t-1;am>=m;am--){
var aH=y[am];
var aI=%_CallFunction((void 0),aH,aG,aC);
if(aI>0){
y[am+1]=aH;
}else{
break;
}
}
y[am+1]=aG;
}
}
--- END ---
--- FUNCTION SOURCE (ToObject) id{39,0} ---
(i){
if((typeof(i)==='string'))return new e(i);
if((typeof(i)==='number'))return new g(i);
if((typeof(i)==='boolean'))return new d(i);
if((typeof(i)==='symbol'))return %NewSymbolWrapper(i);
if((i==null)&&!(%_IsUndetectableObject(i))){
throw MakeTypeError(113);
}
return i;
}
--- END ---
--- FUNCTION SOURCE (abs) id{40,0} ---
(e){
e=+e;
return(e>0)?e:0-e;
}
--- END ---
--- FUNCTION SOURCE (replaceBackground) id{41,0} ---
(frames, replacer, tolerance) {
  tolerance = tolerance != null ? tolerance : 50

//  var background = meanFrame(frames)
  var background = medianFrame(frames)
  for (var i = 0; i < frames.length; i++) {
    var dupe = copy(frames[i].data)
    replacer(dupe)
    var rgba = frames[i].data
    for (var j = 0; j < background.length; j += 4) {
      var rDiff = Math.abs(rgba[j] - background[j])
      var gDiff = Math.abs(rgba[j+1] - background[j+1])
      var bDiff = Math.abs(rgba[j+2] - background[j+2])
      if (!(rDiff > tolerance || gDiff > tolerance || bDiff > tolerance)) {
      //if (rDiff + gDiff + bDiff < tolerance) {
        var start = (j > dupe.length) ? 0 : j
        rgba[j] = dupe[start + 0]
        rgba[j+1] = dupe[start + 1]
        rgba[j+2] = dupe[start + 2]
      }
    }
  }
}
--- END ---
--- FUNCTION SOURCE (medianFrame) id{41,1} ---
(frames, alg) {
  return avg(frames, medianPixel)
}
--- END ---
INLINE (medianFrame) id{41,1} AS 1 AT <0:140>
--- FUNCTION SOURCE (copy) id{41,2} ---
(rgba) {
  var dupe = new Buffer(rgba.length)
  rgba.copy(dupe)
  return dupe
}
--- END ---
INLINE (copy) id{41,2} AS 2 AT <0:219>
--- FUNCTION SOURCE (Buffer) id{41,3} ---
(arg) {
  // Common case.
  if (typeof arg === 'number') {
    // If less than zero, or NaN.
    if (arg < 0 || arg !== arg)
      arg = 0;
    return allocate(arg);
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(arg, arguments[1]);
  }

  // Unusual.
  return fromObject(arg);
}
--- END ---
INLINE (Buffer) id{41,3} AS 3 AT <2:22>
--- FUNCTION SOURCE (fromString) id{41,4} ---
(string, encoding) {
  if (typeof encoding !== 'string' || encoding === '')
    encoding = 'utf8';

  var length = byteLength(string, encoding);
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}
--- END ---
INLINE (fromString) id{41,4} AS 4 AT <3:247>
--- FUNCTION SOURCE (slice) id{41,5} ---
(start, end) {
  const buffer = this.subarray(start, end);
  Object.setPrototypeOf(buffer, Buffer.prototype);
  return buffer;
}
--- END ---
INLINE (slice) id{41,5} AS 5 AT <4:382>
--- FUNCTION SOURCE (alignPool) id{41,6} ---
() {
  // Ensure aligned slices
  if (poolOffset & 0x7) {
    poolOffset |= 0x7;
    poolOffset++;
  }
}
--- END ---
INLINE (alignPool) id{41,6} AS 6 AT <4:448>
--- FUNCTION SOURCE (replacer) id{41,7} ---
(frame) {
      frame.fill(0)
    }
--- END ---
INLINE (replacer) id{41,7} AS 7 AT <0:244>
--- FUNCTION SOURCE (DefineOwnProperty) id{42,0} ---
(J,V,G,Y){
if(%_IsJSProxy(J)){
if((typeof(V)==='symbol'))return false;
var w=FromGenericPropertyDescriptor(G);
return DefineProxyProperty(J,V,w,Y);
}else if((%_IsArray(J))){
return DefineArrayProperty(J,V,G,Y);
}else{
return DefineObjectProperty(J,V,G,Y);
}
}
--- END ---
--- FUNCTION SOURCE (GIFEncoder.removeAlphaChannel) id{43,0} ---
(data) {
  var w = this.width;
  var h = this.height;
  var pixels = new Uint8Array(w * h * 3);

  var count = 0;

  for (var i = 0; i < h; i++) {
    for (var j = 0; j < w; j++) {
      var b = (i * w * 4) + j * 4;
      pixels[count++] = data[b];
      pixels[count++] = data[b+1];
      pixels[count++] = data[b+2];
    }
  }

  return pixels;
}
--- END ---
[deoptimizing (DEOPT eager): begin 0x3ed23a86f091 <JS Function abs (SharedFunctionInfo 0x36cdc0e69bd9)> (opt #40) @2, FP to SP delta: 24]
            ;;; deoptimize at 0_8: lost precision
  reading input frame abs => node=2, args=3, height=1; inputs:
      0: 0x3ed23a86f091 ; (frame function) 0x3ed23a86f091 <JS Function abs (SharedFunctionInfo 0x36cdc0e69bd9)>
      1: 0x3ed23a854651 ; [fp + 24] 0x3ed23a854651 <a MathConstructor with map 0x3d4eb9d0ad49>
      2: 0x7bbff3ebea1 ; [fp + 16] 0x7bbff3ebea1 <Number: 0.015625>
      3: 0x3ed23a871969 ; [fp - 24] 0x3ed23a871969 <FixedArray[15]>
  translating frame abs => node=3, height=0
    0x7ffc654cd278: [top + 40] <- 0x3ed23a854651 ;  0x3ed23a854651 <a MathConstructor with map 0x3d4eb9d0ad49>  (input #1)
    0x7ffc654cd270: [top + 32] <- 0x7bbff3ebea1 ;  0x7bbff3ebea1 <Number: 0.015625>  (input #2)
    0x7ffc654cd268: [top + 24] <- 0x376e6ff4264e ;  caller's pc
    0x7ffc654cd260: [top + 16] <- 0x7ffc654cd2e0 ;  caller's fp
    0x7ffc654cd258: [top + 8] <- 0x3ed23a871969 ;  context    0x3ed23a871969 <FixedArray[15]>  (input #3)
    0x7ffc654cd250: [top + 0] <- 0x3ed23a86f091 ;  function    0x3ed23a86f091 <JS Function abs (SharedFunctionInfo 0x36cdc0e69bd9)>  (input #0)
[deoptimizing (eager): end 0x3ed23a86f091 <JS Function abs (SharedFunctionInfo 0x36cdc0e69bd9)> @2 => node=3, pc=0x376e6ff0d186, state=NO_REGISTERS, alignment=no padding, took 0.037 ms]
--- FUNCTION SOURCE (abs) id{44,0} ---
(e){
e=+e;
return(e>0)?e:0-e;
}
--- END ---
--- FUNCTION SOURCE (contest) id{45,0} ---
(b, g, r) {
    /*
      finds closest neuron (min dist) and updates freq
      finds best neuron (min dist-bias) and returns position
      for frequently chosen neurons, freq[i] is high and bias[i] is negative
      bias[i] = gamma * ((1 / netsize) - freq[i])
    */

    var bestd = ~(1 << 31);
    var bestbiasd = bestd;
    var bestpos = -1;
    var bestbiaspos = bestpos;

    var i, n, dist, biasdist, betafreq;
    for (i = 0; i < netsize; i++) {
      n = network[i];

      dist = Math.abs(n[0] - b) + Math.abs(n[1] - g) + Math.abs(n[2] - r);
      if (dist < bestd) {
        bestd = dist;
        bestpos = i;
      }

      biasdist = dist - ((bias[i]) >> (intbiasshift - netbiasshift));
      if (biasdist < bestbiasd) {
        bestbiasd = biasdist;
        bestbiaspos = i;
      }

      betafreq = (freq[i] >> betashift);
      freq[i] -= betafreq;
      bias[i] += (betafreq << gammashift);
    }

    freq[bestpos] += beta;
    bias[bestpos] -= betagamma;

    return bestbiaspos;
  }
--- END ---
--- FUNCTION SOURCE (alterneigh) id{46,0} ---
(radius, i, b, g, r) {
    var lo = Math.abs(i - radius);
    var hi = Math.min(i + radius, netsize);

    var j = i + 1;
    var k = i - 1;
    var m = 1;

    var p, a;
    while ((j < hi) || (k > lo)) {
      a = radpower[m++];

      if (j < hi) {
        p = network[j++];
        p[0] -= (a * (p[0] - b)) / alpharadbias;
        p[1] -= (a * (p[1] - g)) / alpharadbias;
        p[2] -= (a * (p[2] - r)) / alpharadbias;
      }

      if (k > lo) {
        p = network[k--];
        p[0] -= (a * (p[0] - b)) / alpharadbias;
        p[1] -= (a * (p[1] - g)) / alpharadbias;
        p[2] -= (a * (p[2] - r)) / alpharadbias;
      }
    }
  }
--- END ---
--- FUNCTION SOURCE (altersingle) id{47,0} ---
(alpha, i, b, g, r) {
    network[i][0] -= (alpha * (network[i][0] - b)) / initalpha;
    network[i][1] -= (alpha * (network[i][1] - g)) / initalpha;
    network[i][2] -= (alpha * (network[i][2] - r)) / initalpha;
  }
--- END ---
[deoptimizing (DEOPT soft): begin 0x7bbfe01ac69 <JS Function alterneigh (SharedFunctionInfo 0x100fecfd14a1)> (opt #46) @26, FP to SP delta: 64]
            ;;; deoptimize at 0_473: Insufficient type feedback for keyed load
  reading input frame alterneigh => node=6, args=499, height=8; inputs:
      0: 0x7bbfe01ac69 ; (frame function) 0x7bbfe01ac69 <JS Function alterneigh (SharedFunctionInfo 0x100fecfd14a1)>
      1: 0x36cdc0e04131 ; [fp + 56] 0x36cdc0e04131 <undefined>
      2: 0x1300000000 ; [fp + 48] 19
      3: 0x4600000000 ; [fp + 40] 70
      4: 0xc2000000000 ; r12 3104
      5: 0x46000000000 ; [fp + 24] 1120
      6: 0x2000000000 ; r14 32
      7: 0x7bbfe01aad1 ; [fp - 24] 0x7bbfe01aad1 <FixedArray[18]>
      8: 5.100000e+01 ; xmm1 (bool)
      9: 8.900000e+01 ; xmm2 (bool)
     10: 72 ; rax 
     11: 69 ; rdx 
     12: 2 ; (int) [fp - 32] 
     13: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     14: 223541 ; rbx 
  translating frame alterneigh => node=499, height=56
    0x7ffc654cd308: [top + 128] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd300: [top + 120] <- 0x1300000000 ;  19  (input #2)
    0x7ffc654cd2f8: [top + 112] <- 0x4600000000 ;  70  (input #3)
    0x7ffc654cd2f0: [top + 104] <- 0xc2000000000 ;  3104  (input #4)
    0x7ffc654cd2e8: [top + 96] <- 0x46000000000 ;  1120  (input #5)
    0x7ffc654cd2e0: [top + 88] <- 0x2000000000 ;  32  (input #6)
    0x7ffc654cd2d8: [top + 80] <- 0x376e6ff41f51 ;  caller's pc
    0x7ffc654cd2d0: [top + 72] <- 0x7ffc654cd398 ;  caller's fp
    0x7ffc654cd2c8: [top + 64] <- 0x7bbfe01aad1 ;  context    0x7bbfe01aad1 <FixedArray[18]>  (input #7)
    0x7ffc654cd2c0: [top + 56] <- 0x7bbfe01ac69 ;  function    0x7bbfe01ac69 <JS Function alterneigh (SharedFunctionInfo 0x100fecfd14a1)>  (input #0)
    0x7ffc654cd2b8: [top + 48] <- 0x3300000000 ;  51  (input #8)
    0x7ffc654cd2b0: [top + 40] <- 0x5900000000 ;  89  (input #9)
    0x7ffc654cd2a8: [top + 32] <- 0x4800000000 ;  72  (input #10)
    0x7ffc654cd2a0: [top + 24] <- 0x4500000000 ;  69  (input #11)
    0x7ffc654cd298: [top + 16] <- 0x200000000 ;  2  (input #12)
    0x7ffc654cd290: [top + 8] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #13)
    0x7ffc654cd288: [top + 0] <- 0x3693500000000 ;  223541  (input #14)
[deoptimizing (soft): end 0x7bbfe01ac69 <JS Function alterneigh (SharedFunctionInfo 0x100fecfd14a1)> @26 => node=499, pc=0x376e6ff43793, state=NO_REGISTERS, alignment=no padding, took 0.054 ms]
--- FUNCTION SOURCE (alterneigh) id{48,0} ---
(radius, i, b, g, r) {
    var lo = Math.abs(i - radius);
    var hi = Math.min(i + radius, netsize);

    var j = i + 1;
    var k = i - 1;
    var m = 1;

    var p, a;
    while ((j < hi) || (k > lo)) {
      a = radpower[m++];

      if (j < hi) {
        p = network[j++];
        p[0] -= (a * (p[0] - b)) / alpharadbias;
        p[1] -= (a * (p[1] - g)) / alpharadbias;
        p[2] -= (a * (p[2] - r)) / alpharadbias;
      }

      if (k > lo) {
        p = network[k--];
        p[0] -= (a * (p[0] - b)) / alpharadbias;
        p[1] -= (a * (p[1] - g)) / alpharadbias;
        p[2] -= (a * (p[2] - r)) / alpharadbias;
      }
    }
  }
--- END ---
--- FUNCTION SOURCE (inxbuild) id{49,0} ---
() {
    var i, j, p, q, smallpos, smallval, previouscol = 0, startpos = 0;
    for (i = 0; i < netsize; i++) {
      p = network[i];
      smallpos = i;
      smallval = p[1]; // index on g
      // find smallest in i..netsize-1
      for (j = i + 1; j < netsize; j++) {
        q = network[j];
        if (q[1] < smallval) { // index on g
          smallpos = j;
          smallval = q[1]; // index on g
        }
      }
      q = network[smallpos];
      // swap p (i) and q (smallpos) entries
      if (i != smallpos) {
        j = q[0];   q[0] = p[0];   p[0] = j;
        j = q[1];   q[1] = p[1];   p[1] = j;
        j = q[2];   q[2] = p[2];   p[2] = j;
        j = q[3];   q[3] = p[3];   p[3] = j;
      }
      // smallval entry is now in position i

      if (smallval != previouscol) {
        netindex[previouscol] = (startpos + i) >> 1;
        for (j = previouscol + 1; j < smallval; j++)
          netindex[j] = i;
        previouscol = smallval;
        startpos = i;
      }
    }
    netindex[previouscol] = (startpos + maxnetpos) >> 1;
    for (j = previouscol + 1; j < 256; j++)
      netindex[j] = maxnetpos; // really 256
  }
--- END ---
[deoptimizing (DEOPT soft): begin 0x7bbfe01acf9 <JS Function inxbuild (SharedFunctionInfo 0x100fecfd15f1)> (opt #49) @39, FP to SP delta: 184]
            ;;; deoptimize at 0_1035: Insufficient type feedback for LHS of binary operation
  reading input frame inxbuild => node=1, args=52, height=9; inputs:
      0: 0x7bbfe01acf9 ; (frame function) 0x7bbfe01acf9 <JS Function inxbuild (SharedFunctionInfo 0x100fecfd15f1)>
      1: 0x36cdc0e04131 ; [fp - 112] 0x36cdc0e04131 <undefined>
      2: 0x7bbfe01aad1 ; [fp - 96] 0x7bbfe01aad1 <FixedArray[18]>
      3: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      4: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      5: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      6: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      7: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      8: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      9: 0x7bbfe214819 ; rbx 0x7bbfe214819 <Number: 255>
     10: 0xff00000000 ; [fp - 104] 255
  translating frame inxbuild => node=52, height=64
    0x7ffc654cd3a8: [top + 96] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd3a0: [top + 88] <- 0x376e6ff4046a ;  caller's pc
    0x7ffc654cd398: [top + 80] <- 0x7ffc654cd3c8 ;  caller's fp
    0x7ffc654cd390: [top + 72] <- 0x7bbfe01aad1 ;  context    0x7bbfe01aad1 <FixedArray[18]>  (input #2)
    0x7ffc654cd388: [top + 64] <- 0x7bbfe01acf9 ;  function    0x7bbfe01acf9 <JS Function inxbuild (SharedFunctionInfo 0x100fecfd15f1)>  (input #0)
    0x7ffc654cd380: [top + 56] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #3)
    0x7ffc654cd378: [top + 48] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #4)
    0x7ffc654cd370: [top + 40] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #5)
    0x7ffc654cd368: [top + 32] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #6)
    0x7ffc654cd360: [top + 24] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #7)
    0x7ffc654cd358: [top + 16] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #8)
    0x7ffc654cd350: [top + 8] <- 0x7bbfe214819 ;  0x7bbfe214819 <Number: 255>  (input #9)
    0x7ffc654cd348: [top + 0] <- 0xff00000000 ;  255  (input #10)
[deoptimizing (soft): end 0x7bbfe01acf9 <JS Function inxbuild (SharedFunctionInfo 0x100fecfd15f1)> @39 => node=52, pc=0x376e6ff44e8d, state=NO_REGISTERS, alignment=no padding, took 0.042 ms]
--- FUNCTION SOURCE (inxsearch) id{50,0} ---
(b, g, r) {
    var a, p, dist;

    var bestd = 1000; // biggest possible dist is 256*3
    var best = -1;

    var i = netindex[g]; // index on g
    var j = i - 1; // start at netindex[g] and work outwards

    while ((i < netsize) || (j >= 0)) {
      if (i < netsize) {
        p = network[i];
        dist = p[1] - g; // inx key
        if (dist >= bestd) i = netsize; // stop iter
        else {
          i++;
          if (dist < 0) dist = -dist;
          a = p[0] - b; if (a < 0) a = -a;
          dist += a;
          if (dist < bestd) {
            a = p[2] - r; if (a < 0) a = -a;
            dist += a;
            if (dist < bestd) {
              bestd = dist;
              best = p[3];
            }
          }
        }
      }
      if (j >= 0) {
        p = network[j];
        dist = g - p[1]; // inx key - reverse dif
        if (dist >= bestd) j = -1; // stop iter
        else {
          j--;
          if (dist < 0) dist = -dist;
          a = p[0] - b; if (a < 0) a = -a;
          dist += a;
          if (dist < bestd) {
            a = p[2] - r; if (a < 0) a = -a;
            dist += a;
            if (dist < bestd) {
              bestd = dist;
              best = p[3];
            }
          }
        }
      }
    }

    return best;
  }
--- END ---
--- FUNCTION SOURCE (GIFEncoder.analyzePixels) id{51,0} ---
() {
  var len = this.pixels.length;
  var nPix = len / 3;

  // TODO: Re-use indexedPixels
  this.indexedPixels = new Uint8Array(nPix);

  var imgq = new NeuQuant(this.pixels, this.sample);
  imgq.buildColormap(); // create reduced palette
  this.colorTab = imgq.getColormap();

  // map image pixels to new palette
  var k = 0;
  for (var j = 0; j < nPix; j++) {
    var index = imgq.lookupRGB(
      this.pixels[k++] & 0xff,
      this.pixels[k++] & 0xff,
      this.pixels[k++] & 0xff
    );
    this.usedEntry[index] = true;
    this.indexedPixels[j] = index;
  }

  this.pixels = null;
  this.colorDepth = 8;
  this.palSize = 7;

  // get closest match to transparent color if specified
  if (this.transparent !== null) {
    this.transIndex = this.findClosest(this.transparent);
  }
}
--- END ---
[deoptimizing (DEOPT soft): begin 0x3ed23a8fced1 <JS Function inxsearch (SharedFunctionInfo 0x100fecfd1699)> (opt #50) @27, FP to SP delta: 24]
            ;;; deoptimize at 0_940: Insufficient type feedback for combined type of binary operation
  reading input frame inxsearch => node=4, args=495, height=8; inputs:
      0: 0x3ed23a8fced1 ; (frame function) 0x3ed23a8fced1 <JS Function inxsearch (SharedFunctionInfo 0x100fecfd1699)>
      1: 0x3ed23a8fcf19 ; [fp + 40] 0x3ed23a8fcf19 <a NeuQuant with map 0x3d4eb9d0eb81>
      2: 0x8700000000 ; r9 135
      3: 0x6c00000000 ; r8 108
      4: 0x00000000 ; r11 0
      5: 0x3ed23a8fce31 ; [fp - 24] 0x3ed23a8fce31 <FixedArray[18]>
      6: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      7: 0xc518ec195b9 ; rdx 0xc518ec195b9 <a Float64Array with map 0x3d4eb9d157c9>
      8: 0.000000e+00 ; xmm7 (bool)
      9: 0x7bbff1f1dc1 ; r12 0x7bbff1f1dc1 <Number: 135>
     10: 1.080000e+02 ; xmm6 (bool)
     11: 74 ; rax 
     12: 72 ; rbx 
  translating frame inxsearch => node=495, height=56
    0x7ffc654cd390: [top + 112] <- 0x3ed23a8fcf19 ;  0x3ed23a8fcf19 <a NeuQuant with map 0x3d4eb9d0eb81>  (input #1)
    0x7ffc654cd388: [top + 104] <- 0x8700000000 ;  135  (input #2)
    0x7ffc654cd380: [top + 96] <- 0x6c00000000 ;  108  (input #3)
    0x7ffc654cd378: [top + 88] <- 0x00000000 ;  0  (input #4)
    0x7ffc654cd370: [top + 80] <- 0x376e6ff49dfc ;  caller's pc
    0x7ffc654cd368: [top + 72] <- 0x7ffc654cd428 ;  caller's fp
    0x7ffc654cd360: [top + 64] <- 0x3ed23a8fce31 ;  context    0x3ed23a8fce31 <FixedArray[18]>  (input #5)
    0x7ffc654cd358: [top + 56] <- 0x3ed23a8fced1 ;  function    0x3ed23a8fced1 <JS Function inxsearch (SharedFunctionInfo 0x100fecfd1699)>  (input #0)
    0x7ffc654cd350: [top + 48] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #6)
    0x7ffc654cd348: [top + 40] <- 0xc518ec195b9 ;  0xc518ec195b9 <a Float64Array with map 0x3d4eb9d157c9>  (input #7)
    0x7ffc654cd340: [top + 32] <- 0x00000000 ;  0  (input #8)
    0x7ffc654cd338: [top + 24] <- 0x7bbff1f1dc1 ;  0x7bbff1f1dc1 <Number: 135>  (input #9)
    0x7ffc654cd330: [top + 16] <- 0x6c00000000 ;  108  (input #10)
    0x7ffc654cd328: [top + 8] <- 0x4a00000000 ;  74  (input #11)
    0x7ffc654cd320: [top + 0] <- 0x4800000000 ;  72  (input #12)
[deoptimizing (soft): end 0x3ed23a8fced1 <JS Function inxsearch (SharedFunctionInfo 0x100fecfd1699)> @27 => node=495, pc=0x376e6ff473e7, state=NO_REGISTERS, alignment=no padding, took 0.089 ms]
[deoptimizing (DEOPT eager): begin 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)> (opt #51) @31, FP to SP delta: 144]
            ;;; deoptimize at 0_522: out of bounds
  reading input frame GIFEncoder.analyzePixels => node=1, args=226, height=8; inputs:
      0: 0x2ac96395d689 ; (frame function) 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)>
      1: 0x3ed23a8fcf31 ; rbx 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d3f149>
      2: 0x100fecf7fb11 ; [fp - 128] 0x100fecf7fb11 <FixedArray[8]>
      3: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      4: 360000 ; (int) [fp - 120] 
      5: 0x3ed23a8fcf19 ; [fp - 112] 0x3ed23a8fcf19 <a NeuQuant with map 0x3d4eb9d0eb81>
      6: 360873 ; (int) [fp - 144] 
      7: 120290 ; (int) [fp - 104] 
      8: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      9: 0x7bbff1f22f1 ; rax 0x7bbff1f22f1 <Number: 67>
  translating frame GIFEncoder.analyzePixels => node=226, height=56
    0x7ffc654cd438: [top + 88] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d3f149>  (input #1)
    0x7ffc654cd430: [top + 80] <- 0x376e6ff3e4d3 ;  caller's pc
    0x7ffc654cd428: [top + 72] <- 0x7ffc654cd458 ;  caller's fp
    0x7ffc654cd420: [top + 64] <- 0x100fecf7fb11 ;  context    0x100fecf7fb11 <FixedArray[8]>  (input #2)
    0x7ffc654cd418: [top + 56] <- 0x2ac96395d689 ;  function    0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)>  (input #0)
    0x7ffc654cd410: [top + 48] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #3)
    0x7ffc654cd408: [top + 40] <- 0x57e4000000000 ;  360000  (input #4)
    0x7ffc654cd400: [top + 32] <- 0x3ed23a8fcf19 ;  0x3ed23a8fcf19 <a NeuQuant with map 0x3d4eb9d0eb81>  (input #5)
    0x7ffc654cd3f8: [top + 24] <- 0x581a900000000 ;  360873  (input #6)
    0x7ffc654cd3f0: [top + 16] <- 0x1d5e200000000 ;  120290  (input #7)
    0x7ffc654cd3e8: [top + 8] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #8)
    0x7ffc654cd3e0: [top + 0] <- 0x7bbff1f22f1 ;  0x7bbff1f22f1 <Number: 67>  (input #9)
[deoptimizing (eager): end 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)> @31 => node=226, pc=0x376e6ff3fd7f, state=TOS_REG, alignment=no padding, took 0.059 ms]
--- FUNCTION SOURCE (inxsearch) id{52,0} ---
(b, g, r) {
    var a, p, dist;

    var bestd = 1000; // biggest possible dist is 256*3
    var best = -1;

    var i = netindex[g]; // index on g
    var j = i - 1; // start at netindex[g] and work outwards

    while ((i < netsize) || (j >= 0)) {
      if (i < netsize) {
        p = network[i];
        dist = p[1] - g; // inx key
        if (dist >= bestd) i = netsize; // stop iter
        else {
          i++;
          if (dist < 0) dist = -dist;
          a = p[0] - b; if (a < 0) a = -a;
          dist += a;
          if (dist < bestd) {
            a = p[2] - r; if (a < 0) a = -a;
            dist += a;
            if (dist < bestd) {
              bestd = dist;
              best = p[3];
            }
          }
        }
      }
      if (j >= 0) {
        p = network[j];
        dist = g - p[1]; // inx key - reverse dif
        if (dist >= bestd) j = -1; // stop iter
        else {
          j--;
          if (dist < 0) dist = -dist;
          a = p[0] - b; if (a < 0) a = -a;
          dist += a;
          if (dist < bestd) {
            a = p[2] - r; if (a < 0) a = -a;
            dist += a;
            if (dist < bestd) {
              bestd = dist;
              best = p[3];
            }
          }
        }
      }
    }

    return best;
  }
--- END ---
--- FUNCTION SOURCE (GIFEncoder.analyzePixels) id{53,0} ---
() {
  var len = this.pixels.length;
  var nPix = len / 3;

  // TODO: Re-use indexedPixels
  this.indexedPixels = new Uint8Array(nPix);

  var imgq = new NeuQuant(this.pixels, this.sample);
  imgq.buildColormap(); // create reduced palette
  this.colorTab = imgq.getColormap();

  // map image pixels to new palette
  var k = 0;
  for (var j = 0; j < nPix; j++) {
    var index = imgq.lookupRGB(
      this.pixels[k++] & 0xff,
      this.pixels[k++] & 0xff,
      this.pixels[k++] & 0xff
    );
    this.usedEntry[index] = true;
    this.indexedPixels[j] = index;
  }

  this.pixels = null;
  this.colorDepth = 8;
  this.palSize = 7;

  // get closest match to transparent color if specified
  if (this.transparent !== null) {
    this.transIndex = this.findClosest(this.transparent);
  }
}
--- END ---
[deoptimizing (DEOPT soft): begin 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)> (opt #53) @35, FP to SP delta: 144]
            ;;; deoptimize at 0_584: Insufficient type feedback for generic named access
  reading input frame GIFEncoder.analyzePixels => node=1, args=178, height=7; inputs:
      0: 0x2ac96395d689 ; (frame function) 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)>
      1: 0x3ed23a8fcf31 ; rdx 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d3f149>
      2: 0x100fecf7fb11 ; [fp - 128] 0x100fecf7fb11 <FixedArray[8]>
      3: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      4: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      5: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      6: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      7: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      8: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
  translating frame GIFEncoder.analyzePixels => node=178, height=48
    0x7ffc654cd438: [top + 80] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d3f149>  (input #1)
    0x7ffc654cd430: [top + 72] <- 0x376e6ff3e4d3 ;  caller's pc
    0x7ffc654cd428: [top + 64] <- 0x7ffc654cd458 ;  caller's fp
    0x7ffc654cd420: [top + 56] <- 0x100fecf7fb11 ;  context    0x100fecf7fb11 <FixedArray[8]>  (input #2)
    0x7ffc654cd418: [top + 48] <- 0x2ac96395d689 ;  function    0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)>  (input #0)
    0x7ffc654cd410: [top + 40] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #3)
    0x7ffc654cd408: [top + 32] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #4)
    0x7ffc654cd400: [top + 24] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #5)
    0x7ffc654cd3f8: [top + 16] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #6)
    0x7ffc654cd3f0: [top + 8] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #7)
    0x7ffc654cd3e8: [top + 0] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #8)
[deoptimizing (soft): end 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)> @35 => node=178, pc=0x376e6ff3fe8f, state=NO_REGISTERS, alignment=no padding, took 0.055 ms]
[marking dependent code 0x376e6ff4ac41 (opt #53) for deoptimization, reason: prototype-check]
[marking dependent code 0x376e6ff499a1 (opt #51) for deoptimization, reason: prototype-check]
[deoptimize marked code in all contexts]
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{54,0} ---
(val) {
  this.data.push(val);
}
--- END ---
--- FUNCTION SOURCE (nextPixel) id{55,0} ---
() {
    if (remaining === 0) return EOF;
    --remaining;
    var pix = pixels[curPixel++];
    return pix & 0xff;
  }
--- END ---
--- FUNCTION SOURCE (compress) id{56,0} ---
(init_bits, outs) {
    var fcode, c, i, ent, disp, hsize_reg, hshift;

    // Set up the globals: g_init_bits - initial number of bits
    g_init_bits = init_bits;

    // Set up the necessary values
    clear_flg = false;
    n_bits = g_init_bits;
    maxcode = MAXCODE(n_bits);

    ClearCode = 1 << (init_bits - 1);
    EOFCode = ClearCode + 1;
    free_ent = ClearCode + 2;

    a_count = 0; // clear packet

    ent = nextPixel();

    hshift = 0;
    for (fcode = HSIZE; fcode < 65536; fcode *= 2) ++hshift;
    hshift = 8 - hshift; // set hash code range bound
    hsize_reg = HSIZE;
    cl_hash(hsize_reg); // clear hash table

    output(ClearCode, outs);

    outer_loop: while ((c = nextPixel()) != EOF) {
      fcode = (c << BITS) + ent;
      i = (c << hshift) ^ ent; // xor hashing
      if (htab[i] === fcode) {
        ent = codetab[i];
        continue;
      } else if (htab[i] >= 0) { // non-empty slot
        disp = hsize_reg - i; // secondary hash (after G. Knott)
        if (i === 0) disp = 1;
        do {
          if ((i -= disp) < 0) i += hsize_reg;
          if (htab[i] === fcode) {
            ent = codetab[i];
            continue outer_loop;
          }
        } while (htab[i] >= 0);
      }
      output(ent, outs);
      ent = c;
      if (free_ent < 1 << BITS) {
        codetab[i] = free_ent++; // code -> hashtable
        htab[i] = fcode;
      } else {
        cl_block(outs);
      }
    }

    // Put out the final code.
    output(ent, outs);
    output(EOFCode, outs);
  }
--- END ---
--- FUNCTION SOURCE (MAXCODE) id{56,1} ---
(n_bits) {
    return (1 << n_bits) - 1;
  }
--- END ---
INLINE (MAXCODE) id{56,1} AS 1 AT <0:264>
--- FUNCTION SOURCE (nextPixel) id{56,2} ---
() {
    if (remaining === 0) return EOF;
    --remaining;
    var pix = pixels[curPixel++];
    return pix & 0xff;
  }
--- END ---
INLINE (nextPixel) id{56,2} AS 2 AT <0:424>
--- FUNCTION SOURCE (cl_hash) id{56,3} ---
(hsize) {
    for (var i = 0; i < hsize; ++i) htab[i] = -1;
  }
--- END ---
INLINE (cl_hash) id{56,3} AS 3 AT <0:596>
--- FUNCTION SOURCE (nextPixel) id{56,4} ---
() {
    if (remaining === 0) return EOF;
    --remaining;
    var pix = pixels[curPixel++];
    return pix & 0xff;
  }
--- END ---
INLINE (nextPixel) id{56,4} AS 4 AT <0:695>
--- FUNCTION SOURCE (char_out) id{57,0} ---
(c, outs) {
    accum[a_count++] = c;
    if (a_count >= 254) flush_char(outs);
  }
--- END ---
[marking dependent code 0x376e6ff515e1 (opt #56) for deoptimization, reason: property-cell-changed]
[deoptimize marked code in all contexts]
[deoptimizer unlinked: compress / 7bbfe1c9b11]
[deoptimizing (DEOPT lazy): begin 0x7bbfe1c9b11 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)> (opt #56) @40, FP to SP delta: 168]
  reading input frame compress => node=3, args=560, height=8; inputs:
      0: 0x7bbfe1c9b11 ; (frame function) 0x7bbfe1c9b11 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)>
      1: 0x36cdc0e04131 ; [fp - 144] 0x36cdc0e04131 <undefined>
      2: 0x36cdc0e04131 ; (literal 4) 0x36cdc0e04131 <undefined>
      3: 0x3ed23a8fcf31 ; [fp - 136] 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      4: 0x7bbfe1c9949 ; [fp - 128] 0x7bbfe1c9949 <FixedArray[28]>
      5: 49663 ; (int) [fp - 160] 
      6: 12 ; (int) [fp - 152] 
      7: 0x13f00000000 ; [fp - 168] 319
      8: 0x36cdc0e04131 ; (literal 4) 0x36cdc0e04131 <undefined>
      9: 0x36cdc0e04131 ; (literal 4) 0x36cdc0e04131 <undefined>
     10: 0x138b00000000 ; [fp - 120] 5003
     11: 4 ; (int) [fp - 112] 
  translating frame compress => node=560, height=56
    0x7ffc654cd3d0: [top + 104] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd3c8: [top + 96] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #2)
    0x7ffc654cd3c0: [top + 88] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #3)
    0x7ffc654cd3b8: [top + 80] <- 0x376e6ff4e19e ;  caller's pc
    0x7ffc654cd3b0: [top + 72] <- 0x7ffc654cd3f0 ;  caller's fp
    0x7ffc654cd3a8: [top + 64] <- 0x7bbfe1c9949 ;  context    0x7bbfe1c9949 <FixedArray[28]>  (input #4)
    0x7ffc654cd3a0: [top + 56] <- 0x7bbfe1c9b11 ;  function    0x7bbfe1c9b11 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)>  (input #0)
    0x7ffc654cd398: [top + 48] <- 0xc1ff00000000 ;  49663  (input #5)
    0x7ffc654cd390: [top + 40] <- 0xc00000000 ;  12  (input #6)
    0x7ffc654cd388: [top + 32] <- 0x13f00000000 ;  319  (input #7)
    0x7ffc654cd380: [top + 24] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #8)
    0x7ffc654cd378: [top + 16] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #9)
    0x7ffc654cd370: [top + 8] <- 0x138b00000000 ;  5003  (input #10)
    0x7ffc654cd368: [top + 0] <- 0x400000000 ;  4  (input #11)
[deoptimizing (lazy): end 0x7bbfe1c9b11 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)> @40 => node=560, pc=0x376e6ff4eb9d, state=NO_REGISTERS, alignment=no padding, took 0.062 ms]
--- FUNCTION SOURCE (compress) id{58,0} ---
(init_bits, outs) {
    var fcode, c, i, ent, disp, hsize_reg, hshift;

    // Set up the globals: g_init_bits - initial number of bits
    g_init_bits = init_bits;

    // Set up the necessary values
    clear_flg = false;
    n_bits = g_init_bits;
    maxcode = MAXCODE(n_bits);

    ClearCode = 1 << (init_bits - 1);
    EOFCode = ClearCode + 1;
    free_ent = ClearCode + 2;

    a_count = 0; // clear packet

    ent = nextPixel();

    hshift = 0;
    for (fcode = HSIZE; fcode < 65536; fcode *= 2) ++hshift;
    hshift = 8 - hshift; // set hash code range bound
    hsize_reg = HSIZE;
    cl_hash(hsize_reg); // clear hash table

    output(ClearCode, outs);

    outer_loop: while ((c = nextPixel()) != EOF) {
      fcode = (c << BITS) + ent;
      i = (c << hshift) ^ ent; // xor hashing
      if (htab[i] === fcode) {
        ent = codetab[i];
        continue;
      } else if (htab[i] >= 0) { // non-empty slot
        disp = hsize_reg - i; // secondary hash (after G. Knott)
        if (i === 0) disp = 1;
        do {
          if ((i -= disp) < 0) i += hsize_reg;
          if (htab[i] === fcode) {
            ent = codetab[i];
            continue outer_loop;
          }
        } while (htab[i] >= 0);
      }
      output(ent, outs);
      ent = c;
      if (free_ent < 1 << BITS) {
        codetab[i] = free_ent++; // code -> hashtable
        htab[i] = fcode;
      } else {
        cl_block(outs);
      }
    }

    // Put out the final code.
    output(ent, outs);
    output(EOFCode, outs);
  }
--- END ---
--- FUNCTION SOURCE (MAXCODE) id{58,1} ---
(n_bits) {
    return (1 << n_bits) - 1;
  }
--- END ---
INLINE (MAXCODE) id{58,1} AS 1 AT <0:264>
--- FUNCTION SOURCE (nextPixel) id{58,2} ---
() {
    if (remaining === 0) return EOF;
    --remaining;
    var pix = pixels[curPixel++];
    return pix & 0xff;
  }
--- END ---
INLINE (nextPixel) id{58,2} AS 2 AT <0:424>
--- FUNCTION SOURCE (cl_hash) id{58,3} ---
(hsize) {
    for (var i = 0; i < hsize; ++i) htab[i] = -1;
  }
--- END ---
INLINE (cl_hash) id{58,3} AS 3 AT <0:596>
--- FUNCTION SOURCE (nextPixel) id{58,4} ---
() {
    if (remaining === 0) return EOF;
    --remaining;
    var pix = pixels[curPixel++];
    return pix & 0xff;
  }
--- END ---
INLINE (nextPixel) id{58,4} AS 4 AT <0:695>
[deoptimizing (DEOPT soft): begin 0x7bbfe1c9b11 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)> (opt #58) @39, FP to SP delta: 168]
            ;;; deoptimize at 0_1002: Insufficient type feedback for combined type of binary operation
  reading input frame compress => node=3, args=419, height=9; inputs:
      0: 0x7bbfe1c9b11 ; (frame function) 0x7bbfe1c9b11 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)>
      1: 0x36cdc0e04131 ; r9 0x36cdc0e04131 <undefined>
      2: 0x36cdc0e04131 ; (literal 4) 0x36cdc0e04131 <undefined>
      3: 0x3ed23a8fcf31 ; r8 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      4: 0x7bbfe1c9949 ; rsi 0x7bbfe1c9949 <FixedArray[28]>
      5: 258796 ; r12 
      6: 63 ; r11 
      7: 284 ; rdi 
      8: 748 ; rdx 
      9: 0x36cdc0e04131 ; (literal 4) 0x36cdc0e04131 <undefined>
     10: 0x138b00000000 ; rbx 5003
     11: 4 ; rax 
     12: 4719 ; rcx 
  translating frame compress => node=419, height=64
    0x7ffc654cd3d0: [top + 112] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd3c8: [top + 104] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #2)
    0x7ffc654cd3c0: [top + 96] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #3)
    0x7ffc654cd3b8: [top + 88] <- 0x376e6ff4e19e ;  caller's pc
    0x7ffc654cd3b0: [top + 80] <- 0x7ffc654cd3f0 ;  caller's fp
    0x7ffc654cd3a8: [top + 72] <- 0x7bbfe1c9949 ;  context    0x7bbfe1c9949 <FixedArray[28]>  (input #4)
    0x7ffc654cd3a0: [top + 64] <- 0x7bbfe1c9b11 ;  function    0x7bbfe1c9b11 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)>  (input #0)
    0x7ffc654cd398: [top + 56] <- 0x3f2ec00000000 ;  258796  (input #5)
    0x7ffc654cd390: [top + 48] <- 0x3f00000000 ;  63  (input #6)
    0x7ffc654cd388: [top + 40] <- 0x11c00000000 ;  284  (input #7)
    0x7ffc654cd380: [top + 32] <- 0x2ec00000000 ;  748  (input #8)
    0x7ffc654cd378: [top + 24] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #9)
    0x7ffc654cd370: [top + 16] <- 0x138b00000000 ;  5003  (input #10)
    0x7ffc654cd368: [top + 8] <- 0x400000000 ;  4  (input #11)
    0x7ffc654cd360: [top + 0] <- 0x126f00000000 ;  4719  (input #12)
[deoptimizing (soft): end 0x7bbfe1c9b11 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)> @39 => node=419, pc=0x376e6ff4e954, state=TOS_REG, alignment=no padding, took 0.048 ms]
--- FUNCTION SOURCE (compress) id{59,0} ---
(init_bits, outs) {
    var fcode, c, i, ent, disp, hsize_reg, hshift;

    // Set up the globals: g_init_bits - initial number of bits
    g_init_bits = init_bits;

    // Set up the necessary values
    clear_flg = false;
    n_bits = g_init_bits;
    maxcode = MAXCODE(n_bits);

    ClearCode = 1 << (init_bits - 1);
    EOFCode = ClearCode + 1;
    free_ent = ClearCode + 2;

    a_count = 0; // clear packet

    ent = nextPixel();

    hshift = 0;
    for (fcode = HSIZE; fcode < 65536; fcode *= 2) ++hshift;
    hshift = 8 - hshift; // set hash code range bound
    hsize_reg = HSIZE;
    cl_hash(hsize_reg); // clear hash table

    output(ClearCode, outs);

    outer_loop: while ((c = nextPixel()) != EOF) {
      fcode = (c << BITS) + ent;
      i = (c << hshift) ^ ent; // xor hashing
      if (htab[i] === fcode) {
        ent = codetab[i];
        continue;
      } else if (htab[i] >= 0) { // non-empty slot
        disp = hsize_reg - i; // secondary hash (after G. Knott)
        if (i === 0) disp = 1;
        do {
          if ((i -= disp) < 0) i += hsize_reg;
          if (htab[i] === fcode) {
            ent = codetab[i];
            continue outer_loop;
          }
        } while (htab[i] >= 0);
      }
      output(ent, outs);
      ent = c;
      if (free_ent < 1 << BITS) {
        codetab[i] = free_ent++; // code -> hashtable
        htab[i] = fcode;
      } else {
        cl_block(outs);
      }
    }

    // Put out the final code.
    output(ent, outs);
    output(EOFCode, outs);
  }
--- END ---
--- FUNCTION SOURCE (MAXCODE) id{59,1} ---
(n_bits) {
    return (1 << n_bits) - 1;
  }
--- END ---
INLINE (MAXCODE) id{59,1} AS 1 AT <0:264>
--- FUNCTION SOURCE (nextPixel) id{59,2} ---
() {
    if (remaining === 0) return EOF;
    --remaining;
    var pix = pixels[curPixel++];
    return pix & 0xff;
  }
--- END ---
INLINE (nextPixel) id{59,2} AS 2 AT <0:424>
--- FUNCTION SOURCE (cl_hash) id{59,3} ---
(hsize) {
    for (var i = 0; i < hsize; ++i) htab[i] = -1;
  }
--- END ---
INLINE (cl_hash) id{59,3} AS 3 AT <0:596>
--- FUNCTION SOURCE (nextPixel) id{59,4} ---
() {
    if (remaining === 0) return EOF;
    --remaining;
    var pix = pixels[curPixel++];
    return pix & 0xff;
  }
--- END ---
INLINE (nextPixel) id{59,4} AS 4 AT <0:695>
--- FUNCTION SOURCE (output) id{60,0} ---
(code, outs) {
    cur_accum &= masks[cur_bits];

    if (cur_bits > 0) cur_accum |= (code << cur_bits);
    else cur_accum = code;

    cur_bits += n_bits;

    while (cur_bits >= 8) {
      char_out((cur_accum & 0xff), outs);
      cur_accum >>= 8;
      cur_bits -= 8;
    }

    // If the next entry is going to be too big for the code size,
    // then increase it, if possible.
    if (free_ent > maxcode || clear_flg) {
      if (clear_flg) {
        maxcode = MAXCODE(n_bits = g_init_bits);
        clear_flg = false;
      } else {
        ++n_bits;
        if (n_bits == BITS) maxcode = 1 << BITS;
        else maxcode = MAXCODE(n_bits);
      }
    }

    if (code == EOFCode) {
      // At EOF, write the rest of the buffer.
      while (cur_bits > 0) {
        char_out((cur_accum & 0xff), outs);
        cur_accum >>= 8;
        cur_bits -= 8;
      }
      flush_char(outs);
    }
  }
--- END ---
--- FUNCTION SOURCE (char_out) id{60,1} ---
(c, outs) {
    accum[a_count++] = c;
    if (a_count >= 254) flush_char(outs);
  }
--- END ---
INLINE (char_out) id{60,1} AS 1 AT <0:192>
--- FUNCTION SOURCE (flush_char) id{60,2} ---
(outs) {
    if (a_count > 0) {
      outs.writeByte(a_count);
      outs.writeBytes(accum, 0, a_count);
      a_count = 0;
    }
  }
--- END ---
INLINE (flush_char) id{60,2} AS 2 AT <1:62>
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{60,3} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{60,3} AS 3 AT <2:43>
--- FUNCTION SOURCE (ByteCapacitor.writeBytes) id{60,4} ---
(array, offset, length) {
  for (var l = length || array.length, i = offset || 0; i < l; i++) {
    this.writeByte(array[i]);
  }
}
--- END ---
INLINE (ByteCapacitor.writeBytes) id{60,4} AS 4 AT <2:74>
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{60,5} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{60,5} AS 5 AT <4:105>
--- FUNCTION SOURCE (MAXCODE) id{60,6} ---
(n_bits) {
    return (1 << n_bits) - 1;
  }
--- END ---
INLINE (MAXCODE) id{60,6} AS 6 AT <0:631>
[deoptimizing (DEOPT soft): begin 0x7bbfe1c9c79 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)> (opt #60) @36, FP to SP delta: 72]
            ;;; deoptimize at 0_599: Insufficient type feedback for RHS of binary operation
  reading input frame output => node=3, args=268, height=1; inputs:
      0: 0x7bbfe1c9c79 ; (frame function) 0x7bbfe1c9c79 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)>
      1: 0x36cdc0ec8a59 ; [fp + 32] 0x36cdc0ec8a59 <JS Global Object>
      2: 0x64500000000 ; [fp + 24] 1605
      3: 0x3ed23a8fcf31 ; r8 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      4: 0x7bbfe1c9949 ; rax 0x7bbfe1c9949 <FixedArray[28]>
  translating frame output => node=268, height=0
    0x7ffc654cd2f8: [top + 48] <- 0x36cdc0ec8a59 ;  0x36cdc0ec8a59 <JS Global Object>  (input #1)
    0x7ffc654cd2f0: [top + 40] <- 0x64500000000 ;  1605  (input #2)
    0x7ffc654cd2e8: [top + 32] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #3)
    0x7ffc654cd2e0: [top + 24] <- 0x376e6ff545c4 ;  caller's pc
    0x7ffc654cd2d8: [top + 16] <- 0x7ffc654cd3b0 ;  caller's fp
    0x7ffc654cd2d0: [top + 8] <- 0x7bbfe1c9949 ;  context    0x7bbfe1c9949 <FixedArray[28]>  (input #4)
    0x7ffc654cd2c8: [top + 0] <- 0x7bbfe1c9c79 ;  function    0x7bbfe1c9c79 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)>  (input #0)
[deoptimizing (soft): end 0x7bbfe1c9c79 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)> @36 => node=268, pc=0x376e6ff4f8ca, state=NO_REGISTERS, alignment=no padding, took 0.034 ms]
--- FUNCTION SOURCE (output) id{61,0} ---
(code, outs) {
    cur_accum &= masks[cur_bits];

    if (cur_bits > 0) cur_accum |= (code << cur_bits);
    else cur_accum = code;

    cur_bits += n_bits;

    while (cur_bits >= 8) {
      char_out((cur_accum & 0xff), outs);
      cur_accum >>= 8;
      cur_bits -= 8;
    }

    // If the next entry is going to be too big for the code size,
    // then increase it, if possible.
    if (free_ent > maxcode || clear_flg) {
      if (clear_flg) {
        maxcode = MAXCODE(n_bits = g_init_bits);
        clear_flg = false;
      } else {
        ++n_bits;
        if (n_bits == BITS) maxcode = 1 << BITS;
        else maxcode = MAXCODE(n_bits);
      }
    }

    if (code == EOFCode) {
      // At EOF, write the rest of the buffer.
      while (cur_bits > 0) {
        char_out((cur_accum & 0xff), outs);
        cur_accum >>= 8;
        cur_bits -= 8;
      }
      flush_char(outs);
    }
  }
--- END ---
--- FUNCTION SOURCE (char_out) id{61,1} ---
(c, outs) {
    accum[a_count++] = c;
    if (a_count >= 254) flush_char(outs);
  }
--- END ---
INLINE (char_out) id{61,1} AS 1 AT <0:192>
--- FUNCTION SOURCE (flush_char) id{61,2} ---
(outs) {
    if (a_count > 0) {
      outs.writeByte(a_count);
      outs.writeBytes(accum, 0, a_count);
      a_count = 0;
    }
  }
--- END ---
INLINE (flush_char) id{61,2} AS 2 AT <1:62>
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{61,3} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{61,3} AS 3 AT <2:43>
--- FUNCTION SOURCE (ByteCapacitor.writeBytes) id{61,4} ---
(array, offset, length) {
  for (var l = length || array.length, i = offset || 0; i < l; i++) {
    this.writeByte(array[i]);
  }
}
--- END ---
INLINE (ByteCapacitor.writeBytes) id{61,4} AS 4 AT <2:74>
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{61,5} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{61,5} AS 5 AT <4:105>
--- FUNCTION SOURCE (MAXCODE) id{61,6} ---
(n_bits) {
    return (1 << n_bits) - 1;
  }
--- END ---
INLINE (MAXCODE) id{61,6} AS 6 AT <0:631>
[deoptimizing (DEOPT soft): begin 0x7bbfe1c9c79 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)> (opt #61) @40, FP to SP delta: 72]
            ;;; deoptimize at 0_759: Insufficient type feedback for combined type of binary operation
  reading input frame output => node=3, args=329, height=1; inputs:
      0: 0x7bbfe1c9c79 ; (frame function) 0x7bbfe1c9c79 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)>
      1: 0x36cdc0e04131 ; [fp + 32] 0x36cdc0e04131 <undefined>
      2: 0x10100000000 ; [fp + 24] 257
      3: 0x3ed23a8fcf31 ; [fp + 16] 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      4: 0x7bbfe1c9949 ; rbx 0x7bbfe1c9949 <FixedArray[28]>
  translating frame output => node=329, height=0
    0x7ffc654cd2f8: [top + 48] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd2f0: [top + 40] <- 0x10100000000 ;  257  (input #2)
    0x7ffc654cd2e8: [top + 32] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #3)
    0x7ffc654cd2e0: [top + 24] <- 0x376e6ff547eb ;  caller's pc
    0x7ffc654cd2d8: [top + 16] <- 0x7ffc654cd3b0 ;  caller's fp
    0x7ffc654cd2d0: [top + 8] <- 0x7bbfe1c9949 ;  context    0x7bbfe1c9949 <FixedArray[28]>  (input #4)
    0x7ffc654cd2c8: [top + 0] <- 0x7bbfe1c9c79 ;  function    0x7bbfe1c9c79 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)>  (input #0)
[deoptimizing (soft): end 0x7bbfe1c9c79 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)> @40 => node=329, pc=0x376e6ff4fb90, state=NO_REGISTERS, alignment=no padding, took 0.034 ms]
--- FUNCTION SOURCE (Float64Array) id{62,0} ---
(O,P,Q){
if(%_IsConstructCall()){
if((%_ClassOf(O)==='ArrayBuffer')||(%_ClassOf(O)==='SharedArrayBuffer')){
Float64ArrayConstructByArrayBuffer(this,O,P,Q);
}else if((typeof(O)==='number')||(typeof(O)==='string')||
(typeof(O)==='boolean')||(O===(void 0))){
Float64ArrayConstructByLength(this,O);
}else{
var J=O[symbolIterator];
if((J===(void 0))||J===$arrayValues){
Float64ArrayConstructByArrayLike(this,O);
}else{
Float64ArrayConstructByIterable(this,O,J);
}
}
}else{
throw MakeTypeError(20,"Float64Array")
}
}
--- END ---
--- FUNCTION SOURCE (learn) id{63,0} ---
() {
    var i;

    var lengthcount = pixels.length;
    var alphadec = 30 + ((samplefac - 1) / 3);
    var samplepixels = lengthcount / (3 * samplefac);
    var delta = ~~(samplepixels / ncycles);
    var alpha = initalpha;
    var radius = initradius;

    var rad = radius >> radiusbiasshift;

    if (rad <= 1) rad = 0;
    for (i = 0; i < rad; i++)
      radpower[i] = alpha * (((rad * rad - i * i) * radbias) / (rad * rad));

    var step;
    if (lengthcount < minpicturebytes) {
      samplefac = 1;
      step = 3;
    } else if ((lengthcount % prime1) !== 0) {
      step = 3 * prime1;
    } else if ((lengthcount % prime2) !== 0) {
      step = 3 * prime2;
    } else if ((lengthcount % prime3) !== 0)  {
      step = 3 * prime3;
    } else {
      step = 3 * prime4;
    }

    var b, g, r, j;
    var pix = 0; // current pixel

    i = 0;
    while (i < samplepixels) {
      b = (pixels[pix] & 0xff) << netbiasshift;
      g = (pixels[pix + 1] & 0xff) << netbiasshift;
      r = (pixels[pix + 2] & 0xff) << netbiasshift;

      j = contest(b, g, r);

      altersingle(alpha, j, b, g, r);
      if (rad !== 0) alterneigh(rad, j, b, g, r); // alter neighbours

      pix += step;
      if (pix >= lengthcount) pix -= lengthcount;

      i++;

      if (delta === 0) delta = 1;
      if (i % delta === 0) {
        alpha -= alpha / alphadec;
        radius -= radius / radiusdec;
        rad = radius >> radiusbiasshift;

        if (rad <= 1) rad = 0;
        for (j = 0; j < rad; j++)
          radpower[j] = alpha * (((rad * rad - j * j) * radbias) / (rad * rad));
      }
    }
  }
--- END ---
--- FUNCTION SOURCE (inxbuild) id{64,0} ---
() {
    var i, j, p, q, smallpos, smallval, previouscol = 0, startpos = 0;
    for (i = 0; i < netsize; i++) {
      p = network[i];
      smallpos = i;
      smallval = p[1]; // index on g
      // find smallest in i..netsize-1
      for (j = i + 1; j < netsize; j++) {
        q = network[j];
        if (q[1] < smallval) { // index on g
          smallpos = j;
          smallval = q[1]; // index on g
        }
      }
      q = network[smallpos];
      // swap p (i) and q (smallpos) entries
      if (i != smallpos) {
        j = q[0];   q[0] = p[0];   p[0] = j;
        j = q[1];   q[1] = p[1];   p[1] = j;
        j = q[2];   q[2] = p[2];   p[2] = j;
        j = q[3];   q[3] = p[3];   p[3] = j;
      }
      // smallval entry is now in position i

      if (smallval != previouscol) {
        netindex[previouscol] = (startpos + i) >> 1;
        for (j = previouscol + 1; j < smallval; j++)
          netindex[j] = i;
        previouscol = smallval;
        startpos = i;
      }
    }
    netindex[previouscol] = (startpos + maxnetpos) >> 1;
    for (j = previouscol + 1; j < 256; j++)
      netindex[j] = maxnetpos; // really 256
  }
--- END ---
--- FUNCTION SOURCE (GIFEncoder.analyzePixels) id{65,0} ---
() {
  var len = this.pixels.length;
  var nPix = len / 3;

  // TODO: Re-use indexedPixels
  this.indexedPixels = new Uint8Array(nPix);

  var imgq = new NeuQuant(this.pixels, this.sample);
  imgq.buildColormap(); // create reduced palette
  this.colorTab = imgq.getColormap();

  // map image pixels to new palette
  var k = 0;
  for (var j = 0; j < nPix; j++) {
    var index = imgq.lookupRGB(
      this.pixels[k++] & 0xff,
      this.pixels[k++] & 0xff,
      this.pixels[k++] & 0xff
    );
    this.usedEntry[index] = true;
    this.indexedPixels[j] = index;
  }

  this.pixels = null;
  this.colorDepth = 8;
  this.palSize = 7;

  // get closest match to transparent color if specified
  if (this.transparent !== null) {
    this.transIndex = this.findClosest(this.transparent);
  }
}
--- END ---
--- FUNCTION SOURCE (getColormap) id{65,1} ---
() {
    var map = [];
    var index = [];

    for (var i = 0; i < netsize; i++)
      index[network[i][3]] = i;

    var k = 0;
    for (var l = 0; l < netsize; l++) {
      var j = index[l];
      map[k++] = (network[j][0]);
      map[k++] = (network[j][1]);
      map[k++] = (network[j][2]);
    }
    return map;
  }
--- END ---
INLINE (getColormap) id{65,1} AS 1 AT <0:264>
[deoptimizing (DEOPT eager): begin 0x2ac96395d1e1 <JS Function ByteCapacitor.writeByte (SharedFunctionInfo 0x2ac96394aca1)> (opt #54) @3, FP to SP delta: 24]
            ;;; deoptimize at 0_20: wrong map
  reading input frame ByteCapacitor.writeByte => node=2, args=3, height=1; inputs:
      0: 0x2ac96395d1e1 ; (frame function) 0x2ac96395d1e1 <JS Function ByteCapacitor.writeByte (SharedFunctionInfo 0x2ac96394aca1)>
      1: 0x3ed23a8fcf31 ; rbx 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      2: 0x2100000000 ; [fp + 16] 33
      3: 0x100fecf7fb11 ; [fp - 24] 0x100fecf7fb11 <FixedArray[8]>
  translating frame ByteCapacitor.writeByte => node=3, height=0
    0x7ffc654cd400: [top + 40] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #1)
    0x7ffc654cd3f8: [top + 32] <- 0x2100000000 ;  33  (input #2)
    0x7ffc654cd3f0: [top + 24] <- 0x376e6ff4cf7a ;  caller's pc
    0x7ffc654cd3e8: [top + 16] <- 0x7ffc654cd430 ;  caller's fp
    0x7ffc654cd3e0: [top + 8] <- 0x100fecf7fb11 ;  context    0x100fecf7fb11 <FixedArray[8]>  (input #3)
    0x7ffc654cd3d8: [top + 0] <- 0x2ac96395d1e1 ;  function    0x2ac96395d1e1 <JS Function ByteCapacitor.writeByte (SharedFunctionInfo 0x2ac96394aca1)>  (input #0)
[deoptimizing (eager): end 0x2ac96395d1e1 <JS Function ByteCapacitor.writeByte (SharedFunctionInfo 0x2ac96394aca1)> @3 => node=3, pc=0x376e6ff38cde, state=NO_REGISTERS, alignment=no padding, took 0.043 ms]
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{66,0} ---
(val) {
  this.data.push(val);
}
--- END ---
[deoptimizing (DEOPT eager): begin 0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)> (opt #59) @25, FP to SP delta: 176]
            ;;; deoptimize at 0_695: value mismatch
  reading input frame compress => node=3, args=274, height=8; inputs:
      0: 0x7bbfe085861 ; (frame function) 0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)>
      1: 0x36cdc0e04131 ; r9 0x36cdc0e04131 <undefined>
      2: 0x36cdc0e04131 ; (literal 4) 0x36cdc0e04131 <undefined>
      3: 0x3ed23a8fcf31 ; r8 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      4: 0x7bbfe085699 ; rsi 0x7bbfe085699 <FixedArray[28]>
      5: 0x36cdc0e04131 ; (literal 4) 0x36cdc0e04131 <undefined>
      6: 0x36cdc0e04131 ; (literal 4) 0x36cdc0e04131 <undefined>
      7: 0x36cdc0e04131 ; (literal 4) 0x36cdc0e04131 <undefined>
      8: 329 ; rdx 
      9: 0x36cdc0e04131 ; (literal 4) 0x36cdc0e04131 <undefined>
     10: 5003 ; rbx 
     11: 4 ; (int) [fp - 120] 
  translating frame compress => node=274, height=56
    0x7ffc654cd3d0: [top + 104] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd3c8: [top + 96] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #2)
    0x7ffc654cd3c0: [top + 88] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #3)
    0x7ffc654cd3b8: [top + 80] <- 0x376e6ff4e19e ;  caller's pc
    0x7ffc654cd3b0: [top + 72] <- 0x7ffc654cd3f0 ;  caller's fp
    0x7ffc654cd3a8: [top + 64] <- 0x7bbfe085699 ;  context    0x7bbfe085699 <FixedArray[28]>  (input #4)
    0x7ffc654cd3a0: [top + 56] <- 0x7bbfe085861 ;  function    0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)>  (input #0)
    0x7ffc654cd398: [top + 48] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #5)
    0x7ffc654cd390: [top + 40] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #6)
    0x7ffc654cd388: [top + 32] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #7)
    0x7ffc654cd380: [top + 24] <- 0x14900000000 ;  329  (input #8)
    0x7ffc654cd378: [top + 16] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #9)
    0x7ffc654cd370: [top + 8] <- 0x138b00000000 ;  5003  (input #10)
    0x7ffc654cd368: [top + 0] <- 0x400000000 ;  4  (input #11)
[deoptimizing (eager): end 0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)> @25 => node=274, pc=0x376e6ff4ed15, state=NO_REGISTERS, alignment=no padding, took 0.045 ms]
--- FUNCTION SOURCE (compress) id{67,0} ---
(init_bits, outs) {
    var fcode, c, i, ent, disp, hsize_reg, hshift;

    // Set up the globals: g_init_bits - initial number of bits
    g_init_bits = init_bits;

    // Set up the necessary values
    clear_flg = false;
    n_bits = g_init_bits;
    maxcode = MAXCODE(n_bits);

    ClearCode = 1 << (init_bits - 1);
    EOFCode = ClearCode + 1;
    free_ent = ClearCode + 2;

    a_count = 0; // clear packet

    ent = nextPixel();

    hshift = 0;
    for (fcode = HSIZE; fcode < 65536; fcode *= 2) ++hshift;
    hshift = 8 - hshift; // set hash code range bound
    hsize_reg = HSIZE;
    cl_hash(hsize_reg); // clear hash table

    output(ClearCode, outs);

    outer_loop: while ((c = nextPixel()) != EOF) {
      fcode = (c << BITS) + ent;
      i = (c << hshift) ^ ent; // xor hashing
      if (htab[i] === fcode) {
        ent = codetab[i];
        continue;
      } else if (htab[i] >= 0) { // non-empty slot
        disp = hsize_reg - i; // secondary hash (after G. Knott)
        if (i === 0) disp = 1;
        do {
          if ((i -= disp) < 0) i += hsize_reg;
          if (htab[i] === fcode) {
            ent = codetab[i];
            continue outer_loop;
          }
        } while (htab[i] >= 0);
      }
      output(ent, outs);
      ent = c;
      if (free_ent < 1 << BITS) {
        codetab[i] = free_ent++; // code -> hashtable
        htab[i] = fcode;
      } else {
        cl_block(outs);
      }
    }

    // Put out the final code.
    output(ent, outs);
    output(EOFCode, outs);
  }
--- END ---
--- FUNCTION SOURCE (cl_block) id{67,1} ---
(outs) {
    cl_hash(HSIZE);
    free_ent = ClearCode + 2;
    clear_flg = true;
    output(ClearCode, outs);
  }
--- END ---
INLINE (cl_block) id{67,1} AS 1 AT <0:1405>
--- FUNCTION SOURCE (cl_hash) id{67,2} ---
(hsize) {
    for (var i = 0; i < hsize; ++i) htab[i] = -1;
  }
--- END ---
INLINE (cl_hash) id{67,2} AS 2 AT <1:13>
--- FUNCTION SOURCE (ByteCapacitor.writeBytes) id{68,0} ---
(array, offset, length) {
  for (var l = length || array.length, i = offset || 0; i < l; i++) {
    this.writeByte(array[i]);
  }
}
--- END ---
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{68,1} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{68,1} AS 1 AT <0:105>
--- FUNCTION SOURCE (output) id{69,0} ---
(code, outs) {
    cur_accum &= masks[cur_bits];

    if (cur_bits > 0) cur_accum |= (code << cur_bits);
    else cur_accum = code;

    cur_bits += n_bits;

    while (cur_bits >= 8) {
      char_out((cur_accum & 0xff), outs);
      cur_accum >>= 8;
      cur_bits -= 8;
    }

    // If the next entry is going to be too big for the code size,
    // then increase it, if possible.
    if (free_ent > maxcode || clear_flg) {
      if (clear_flg) {
        maxcode = MAXCODE(n_bits = g_init_bits);
        clear_flg = false;
      } else {
        ++n_bits;
        if (n_bits == BITS) maxcode = 1 << BITS;
        else maxcode = MAXCODE(n_bits);
      }
    }

    if (code == EOFCode) {
      // At EOF, write the rest of the buffer.
      while (cur_bits > 0) {
        char_out((cur_accum & 0xff), outs);
        cur_accum >>= 8;
        cur_bits -= 8;
      }
      flush_char(outs);
    }
  }
--- END ---
--- FUNCTION SOURCE (MAXCODE) id{69,1} ---
(n_bits) {
    return (1 << n_bits) - 1;
  }
--- END ---
INLINE (MAXCODE) id{69,1} AS 1 AT <0:468>
--- FUNCTION SOURCE (char_out) id{69,2} ---
(c, outs) {
    accum[a_count++] = c;
    if (a_count >= 254) flush_char(outs);
  }
--- END ---
INLINE (char_out) id{69,2} AS 2 AT <0:774>
--- FUNCTION SOURCE (flush_char) id{69,3} ---
(outs) {
    if (a_count > 0) {
      outs.writeByte(a_count);
      outs.writeBytes(accum, 0, a_count);
      a_count = 0;
    }
  }
--- END ---
INLINE (flush_char) id{69,3} AS 3 AT <0:872>
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{69,4} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{69,4} AS 4 AT <3:43>
--- FUNCTION SOURCE (ByteCapacitor.writeBytes) id{69,5} ---
(array, offset, length) {
  for (var l = length || array.length, i = offset || 0; i < l; i++) {
    this.writeByte(array[i]);
  }
}
--- END ---
INLINE (ByteCapacitor.writeBytes) id{69,5} AS 5 AT <3:74>
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{69,6} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{69,6} AS 6 AT <5:105>
[deoptimizing (DEOPT eager): begin 0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)> (opt #67) @31, FP to SP delta: 192]
            ;;; deoptimize at 0_1405: value mismatch
  reading input frame compress => node=3, args=586, height=8; inputs:
      0: 0x7bbfe085861 ; (frame function) 0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)>
      1: 0x36cdc0e04131 ; [fp - 152] 0x36cdc0e04131 <undefined>
      2: 0x36cdc0e04131 ; (literal 3) 0x36cdc0e04131 <undefined>
      3: 0x3ed23a8fcf31 ; [fp - 144] 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      4: 0x7bbfe085699 ; rax 0x7bbfe085699 <FixedArray[28]>
      5: 0x36cdc0e04131 ; (literal 3) 0x36cdc0e04131 <undefined>
      6: 0x36cdc0e04131 ; (literal 3) 0x36cdc0e04131 <undefined>
      7: 0x36cdc0e04131 ; (literal 3) 0x36cdc0e04131 <undefined>
      8: 0x4e00000000 ; [fp - 168] 78
      9: 0x36cdc0e04131 ; (literal 3) 0x36cdc0e04131 <undefined>
     10: 5003 ; (int) [fp - 128] 
     11: 4 ; (int) [fp - 120] 
  translating frame compress => node=586, height=56
    0x7ffc654cd3d0: [top + 104] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd3c8: [top + 96] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #2)
    0x7ffc654cd3c0: [top + 88] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #3)
    0x7ffc654cd3b8: [top + 80] <- 0x376e6ff4e19e ;  caller's pc
    0x7ffc654cd3b0: [top + 72] <- 0x7ffc654cd3f0 ;  caller's fp
    0x7ffc654cd3a8: [top + 64] <- 0x7bbfe085699 ;  context    0x7bbfe085699 <FixedArray[28]>  (input #4)
    0x7ffc654cd3a0: [top + 56] <- 0x7bbfe085861 ;  function    0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)>  (input #0)
    0x7ffc654cd398: [top + 48] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #5)
    0x7ffc654cd390: [top + 40] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #6)
    0x7ffc654cd388: [top + 32] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #7)
    0x7ffc654cd380: [top + 24] <- 0x4e00000000 ;  78  (input #8)
    0x7ffc654cd378: [top + 16] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #9)
    0x7ffc654cd370: [top + 8] <- 0x138b00000000 ;  5003  (input #10)
    0x7ffc654cd368: [top + 0] <- 0x400000000 ;  4  (input #11)
[deoptimizing (eager): end 0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)> @31 => node=586, pc=0x376e6ff4ecbc, state=NO_REGISTERS, alignment=no padding, took 0.046 ms]
[deoptimizing (DEOPT eager): begin 0x7bbfe0859c9 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)> (opt #69) @15, FP to SP delta: 96]
            ;;; deoptimize at 0_468: value mismatch
  reading input frame output => node=3, args=237, height=4; inputs:
      0: 0x7bbfe0859c9 ; (frame function) 0x7bbfe0859c9 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)>
      1: 0x36cdc0e04131 ; [fp + 32] 0x36cdc0e04131 <undefined>
      2: 0x10000000000 ; [fp + 24] 256
      3: 0x3ed23a8fcf31 ; [fp + 16] 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      4: 0x7bbfe085699 ; rbx 0x7bbfe085699 <FixedArray[28]>
      5: 0x7bbfe085939 ; rsi 0x7bbfe085939 <JS Function MAXCODE (SharedFunctionInfo 0xc518ec2e299)>
      6: 0x36cdc0e04131 ; (literal 6) 0x36cdc0e04131 <undefined>
      7: 0x900000000 ; rdi 9
  translating frame output => node=237, height=24
    0x7ffc654cd320: [top + 72] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd318: [top + 64] <- 0x10000000000 ;  256  (input #2)
    0x7ffc654cd310: [top + 56] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #3)
    0x7ffc654cd308: [top + 48] <- 0x376e6ff57e0d ;  caller's pc
    0x7ffc654cd300: [top + 40] <- 0x7ffc654cd340 ;  caller's fp
    0x7ffc654cd2f8: [top + 32] <- 0x7bbfe085699 ;  context    0x7bbfe085699 <FixedArray[28]>  (input #4)
    0x7ffc654cd2f0: [top + 24] <- 0x7bbfe0859c9 ;  function    0x7bbfe0859c9 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)>  (input #0)
    0x7ffc654cd2e8: [top + 16] <- 0x7bbfe085939 ;  0x7bbfe085939 <JS Function MAXCODE (SharedFunctionInfo 0xc518ec2e299)>  (input #5)
    0x7ffc654cd2e0: [top + 8] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #6)
    0x7ffc654cd2d8: [top + 0] <- 0x900000000 ;  9  (input #7)
[deoptimizing (eager): end 0x7bbfe0859c9 <JS Function output (SharedFunctionInfo 0xc518ec2e3e9)> @15 => node=237, pc=0x376e6ff4f791, state=TOS_REG, alignment=no padding, took 0.034 ms]
--- FUNCTION SOURCE (compress) id{70,0} ---
(init_bits, outs) {
    var fcode, c, i, ent, disp, hsize_reg, hshift;

    // Set up the globals: g_init_bits - initial number of bits
    g_init_bits = init_bits;

    // Set up the necessary values
    clear_flg = false;
    n_bits = g_init_bits;
    maxcode = MAXCODE(n_bits);

    ClearCode = 1 << (init_bits - 1);
    EOFCode = ClearCode + 1;
    free_ent = ClearCode + 2;

    a_count = 0; // clear packet

    ent = nextPixel();

    hshift = 0;
    for (fcode = HSIZE; fcode < 65536; fcode *= 2) ++hshift;
    hshift = 8 - hshift; // set hash code range bound
    hsize_reg = HSIZE;
    cl_hash(hsize_reg); // clear hash table

    output(ClearCode, outs);

    outer_loop: while ((c = nextPixel()) != EOF) {
      fcode = (c << BITS) + ent;
      i = (c << hshift) ^ ent; // xor hashing
      if (htab[i] === fcode) {
        ent = codetab[i];
        continue;
      } else if (htab[i] >= 0) { // non-empty slot
        disp = hsize_reg - i; // secondary hash (after G. Knott)
        if (i === 0) disp = 1;
        do {
          if ((i -= disp) < 0) i += hsize_reg;
          if (htab[i] === fcode) {
            ent = codetab[i];
            continue outer_loop;
          }
        } while (htab[i] >= 0);
      }
      output(ent, outs);
      ent = c;
      if (free_ent < 1 << BITS) {
        codetab[i] = free_ent++; // code -> hashtable
        htab[i] = fcode;
      } else {
        cl_block(outs);
      }
    }

    // Put out the final code.
    output(ent, outs);
    output(EOFCode, outs);
  }
--- END ---
[deoptimizing (DEOPT eager): begin 0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)> (opt #70) @44, FP to SP delta: 184]
            ;;; deoptimize at 0_1471: value mismatch
  reading input frame compress => node=3, args=275, height=8; inputs:
      0: 0x7bbfe085861 ; (frame function) 0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)>
      1: 0x36cdc0e04131 ; [fp - 152] 0x36cdc0e04131 <undefined>
      2: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      3: 0x3ed23a8fcf31 ; [fp - 144] 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      4: 0x7bbfe085699 ; rax 0x7bbfe085699 <FixedArray[28]>
      5: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      6: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      7: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      8: 1137 ; rsi 
      9: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     10: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
     11: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
  translating frame compress => node=275, height=56
    0x7ffc654cd3d0: [top + 104] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #1)
    0x7ffc654cd3c8: [top + 96] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #2)
    0x7ffc654cd3c0: [top + 88] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #3)
    0x7ffc654cd3b8: [top + 80] <- 0x376e6ff4e19e ;  caller's pc
    0x7ffc654cd3b0: [top + 72] <- 0x7ffc654cd3f0 ;  caller's fp
    0x7ffc654cd3a8: [top + 64] <- 0x7bbfe085699 ;  context    0x7bbfe085699 <FixedArray[28]>  (input #4)
    0x7ffc654cd3a0: [top + 56] <- 0x7bbfe085861 ;  function    0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)>  (input #0)
    0x7ffc654cd398: [top + 48] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #5)
    0x7ffc654cd390: [top + 40] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #6)
    0x7ffc654cd388: [top + 32] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #7)
    0x7ffc654cd380: [top + 24] <- 0x47100000000 ;  1137  (input #8)
    0x7ffc654cd378: [top + 16] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #9)
    0x7ffc654cd370: [top + 8] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #10)
    0x7ffc654cd368: [top + 0] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #11)
[deoptimizing (eager): end 0x7bbfe085861 <JS Function compress (SharedFunctionInfo 0xc518ec2e0a1)> @44 => node=275, pc=0x376e6ff4ed1a, state=NO_REGISTERS, alignment=no padding, took 0.047 ms]
[marking dependent code 0x376e6ff61d21 (opt #65) for deoptimization, reason: prototype-check]
[deoptimize marked code in all contexts]
[deoptimizer unlinked: GIFEncoder.analyzePixels / 2ac96395d689]
[deoptimizing (DEOPT lazy): begin 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)> (opt #65) @9, FP to SP delta: 152]
  reading input frame GIFEncoder.analyzePixels => node=1, args=99, height=8; inputs:
      0: 0x2ac96395d689 ; (frame function) 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)>
      1: 0x3ed23a8fcf31 ; [fp + 16] 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      2: 0x100fecf7fb11 ; [fp - 72] 0x100fecf7fb11 <FixedArray[8]>
      3: 0x36cdc0e04131 ; (literal 2) 0x36cdc0e04131 <undefined>
      4: 360000 ; (int) [fp - 80] 
      5: 0x36cdc0e04131 ; (literal 2) 0x36cdc0e04131 <undefined>
      6: 0x36cdc0e04131 ; (literal 2) 0x36cdc0e04131 <undefined>
      7: 0x36cdc0e04131 ; (literal 2) 0x36cdc0e04131 <undefined>
      8: 0x36cdc0e04131 ; (literal 2) 0x36cdc0e04131 <undefined>
      9: 0x7bbfe0db2a9 ; rax 0x7bbfe0db2a9 <a NeuQuant with map 0x3d4eb9d404e1>
  translating frame GIFEncoder.analyzePixels => node=99, height=56
    0x7ffc654cd438: [top + 88] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #1)
    0x7ffc654cd430: [top + 80] <- 0x376e6ff3e4d3 ;  caller's pc
    0x7ffc654cd428: [top + 72] <- 0x7ffc654cd458 ;  caller's fp
    0x7ffc654cd420: [top + 64] <- 0x100fecf7fb11 ;  context    0x100fecf7fb11 <FixedArray[8]>  (input #2)
    0x7ffc654cd418: [top + 56] <- 0x2ac96395d689 ;  function    0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)>  (input #0)
    0x7ffc654cd410: [top + 48] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #3)
    0x7ffc654cd408: [top + 40] <- 0x57e4000000000 ;  360000  (input #4)
    0x7ffc654cd400: [top + 32] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #5)
    0x7ffc654cd3f8: [top + 24] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #6)
    0x7ffc654cd3f0: [top + 16] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #7)
    0x7ffc654cd3e8: [top + 8] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #8)
    0x7ffc654cd3e0: [top + 0] <- 0x7bbfe0db2a9 ;  0x7bbfe0db2a9 <a NeuQuant with map 0x3d4eb9d404e1>  (input #9)
[deoptimizing (lazy): end 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)> @9 => node=99, pc=0x376e6ff3fab0, state=TOS_REG, alignment=no padding, took 0.043 ms]
--- FUNCTION SOURCE (GIFEncoder.analyzePixels) id{71,0} ---
() {
  var len = this.pixels.length;
  var nPix = len / 3;

  // TODO: Re-use indexedPixels
  this.indexedPixels = new Uint8Array(nPix);

  var imgq = new NeuQuant(this.pixels, this.sample);
  imgq.buildColormap(); // create reduced palette
  this.colorTab = imgq.getColormap();

  // map image pixels to new palette
  var k = 0;
  for (var j = 0; j < nPix; j++) {
    var index = imgq.lookupRGB(
      this.pixels[k++] & 0xff,
      this.pixels[k++] & 0xff,
      this.pixels[k++] & 0xff
    );
    this.usedEntry[index] = true;
    this.indexedPixels[j] = index;
  }

  this.pixels = null;
  this.colorDepth = 8;
  this.palSize = 7;

  // get closest match to transparent color if specified
  if (this.transparent !== null) {
    this.transIndex = this.findClosest(this.transparent);
  }
}
--- END ---
--- FUNCTION SOURCE (compress) id{72,0} ---
(init_bits, outs) {
    var fcode, c, i, ent, disp, hsize_reg, hshift;

    // Set up the globals: g_init_bits - initial number of bits
    g_init_bits = init_bits;

    // Set up the necessary values
    clear_flg = false;
    n_bits = g_init_bits;
    maxcode = MAXCODE(n_bits);

    ClearCode = 1 << (init_bits - 1);
    EOFCode = ClearCode + 1;
    free_ent = ClearCode + 2;

    a_count = 0; // clear packet

    ent = nextPixel();

    hshift = 0;
    for (fcode = HSIZE; fcode < 65536; fcode *= 2) ++hshift;
    hshift = 8 - hshift; // set hash code range bound
    hsize_reg = HSIZE;
    cl_hash(hsize_reg); // clear hash table

    output(ClearCode, outs);

    outer_loop: while ((c = nextPixel()) != EOF) {
      fcode = (c << BITS) + ent;
      i = (c << hshift) ^ ent; // xor hashing
      if (htab[i] === fcode) {
        ent = codetab[i];
        continue;
      } else if (htab[i] >= 0) { // non-empty slot
        disp = hsize_reg - i; // secondary hash (after G. Knott)
        if (i === 0) disp = 1;
        do {
          if ((i -= disp) < 0) i += hsize_reg;
          if (htab[i] === fcode) {
            ent = codetab[i];
            continue outer_loop;
          }
        } while (htab[i] >= 0);
      }
      output(ent, outs);
      ent = c;
      if (free_ent < 1 << BITS) {
        codetab[i] = free_ent++; // code -> hashtable
        htab[i] = fcode;
      } else {
        cl_block(outs);
      }
    }

    // Put out the final code.
    output(ent, outs);
    output(EOFCode, outs);
  }
--- END ---
--- FUNCTION SOURCE (output) id{73,0} ---
(code, outs) {
    cur_accum &= masks[cur_bits];

    if (cur_bits > 0) cur_accum |= (code << cur_bits);
    else cur_accum = code;

    cur_bits += n_bits;

    while (cur_bits >= 8) {
      char_out((cur_accum & 0xff), outs);
      cur_accum >>= 8;
      cur_bits -= 8;
    }

    // If the next entry is going to be too big for the code size,
    // then increase it, if possible.
    if (free_ent > maxcode || clear_flg) {
      if (clear_flg) {
        maxcode = MAXCODE(n_bits = g_init_bits);
        clear_flg = false;
      } else {
        ++n_bits;
        if (n_bits == BITS) maxcode = 1 << BITS;
        else maxcode = MAXCODE(n_bits);
      }
    }

    if (code == EOFCode) {
      // At EOF, write the rest of the buffer.
      while (cur_bits > 0) {
        char_out((cur_accum & 0xff), outs);
        cur_accum >>= 8;
        cur_bits -= 8;
      }
      flush_char(outs);
    }
  }
--- END ---
--- FUNCTION SOURCE (cl_hash) id{74,0} ---
(hsize) {
    for (var i = 0; i < hsize; ++i) htab[i] = -1;
  }
--- END ---
[marking dependent code 0x376e6ff676a1 (opt #71) for deoptimization, reason: prototype-check]
[deoptimize marked code in all contexts]
[deoptimizer unlinked: GIFEncoder.analyzePixels / 2ac96395d689]
[deoptimizing (DEOPT lazy): begin 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)> (opt #71) @9, FP to SP delta: 136]
  reading input frame GIFEncoder.analyzePixels => node=1, args=99, height=8; inputs:
      0: 0x2ac96395d689 ; (frame function) 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)>
      1: 0x3ed23a8fcf31 ; [fp + 16] 0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>
      2: 0x100fecf7fb11 ; [fp - 72] 0x100fecf7fb11 <FixedArray[8]>
      3: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      4: 360000 ; (int) [fp - 80] 
      5: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      6: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      7: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      8: 0x36cdc0e04131 ; (literal 1) 0x36cdc0e04131 <undefined>
      9: 0x7bbff37b521 ; rax 0x7bbff37b521 <a NeuQuant with map 0x3d4eb9d40539>
  translating frame GIFEncoder.analyzePixels => node=99, height=56
    0x7ffc654cd438: [top + 88] <- 0x3ed23a8fcf31 ;  0x3ed23a8fcf31 <a GIFEncoder with map 0x3d4eb9d454f9>  (input #1)
    0x7ffc654cd430: [top + 80] <- 0x376e6ff3e4d3 ;  caller's pc
    0x7ffc654cd428: [top + 72] <- 0x7ffc654cd458 ;  caller's fp
    0x7ffc654cd420: [top + 64] <- 0x100fecf7fb11 ;  context    0x100fecf7fb11 <FixedArray[8]>  (input #2)
    0x7ffc654cd418: [top + 56] <- 0x2ac96395d689 ;  function    0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)>  (input #0)
    0x7ffc654cd410: [top + 48] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #3)
    0x7ffc654cd408: [top + 40] <- 0x57e4000000000 ;  360000  (input #4)
    0x7ffc654cd400: [top + 32] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #5)
    0x7ffc654cd3f8: [top + 24] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #6)
    0x7ffc654cd3f0: [top + 16] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #7)
    0x7ffc654cd3e8: [top + 8] <- 0x36cdc0e04131 ;  0x36cdc0e04131 <undefined>  (input #8)
    0x7ffc654cd3e0: [top + 0] <- 0x7bbff37b521 ;  0x7bbff37b521 <a NeuQuant with map 0x3d4eb9d40539>  (input #9)
[deoptimizing (lazy): end 0x2ac96395d689 <JS Function GIFEncoder.analyzePixels (SharedFunctionInfo 0x2ac96394b679)> @9 => node=99, pc=0x376e6ff3fab0, state=TOS_REG, alignment=no padding, took 0.051 ms]
--- FUNCTION SOURCE (GIFEncoder.analyzePixels) id{75,0} ---
() {
  var len = this.pixels.length;
  var nPix = len / 3;

  // TODO: Re-use indexedPixels
  this.indexedPixels = new Uint8Array(nPix);

  var imgq = new NeuQuant(this.pixels, this.sample);
  imgq.buildColormap(); // create reduced palette
  this.colorTab = imgq.getColormap();

  // map image pixels to new palette
  var k = 0;
  for (var j = 0; j < nPix; j++) {
    var index = imgq.lookupRGB(
      this.pixels[k++] & 0xff,
      this.pixels[k++] & 0xff,
      this.pixels[k++] & 0xff
    );
    this.usedEntry[index] = true;
    this.indexedPixels[j] = index;
  }

  this.pixels = null;
  this.colorDepth = 8;
  this.palSize = 7;

  // get closest match to transparent color if specified
  if (this.transparent !== null) {
    this.transIndex = this.findClosest(this.transparent);
  }
}
--- END ---
--- FUNCTION SOURCE (flush_char) id{76,0} ---
(outs) {
    if (a_count > 0) {
      outs.writeByte(a_count);
      outs.writeBytes(accum, 0, a_count);
      a_count = 0;
    }
  }
--- END ---
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{76,1} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{76,1} AS 1 AT <0:43>
--- FUNCTION SOURCE (ByteCapacitor.writeBytes) id{76,2} ---
(array, offset, length) {
  for (var l = length || array.length, i = offset || 0; i < l; i++) {
    this.writeByte(array[i]);
  }
}
--- END ---
INLINE (ByteCapacitor.writeBytes) id{76,2} AS 2 AT <0:74>
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{76,3} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{76,3} AS 3 AT <2:105>
--- FUNCTION SOURCE (Float64ArrayConstructByArrayLike) id{77,0} ---
(v,F){
var y=F.length;
var D=$toPositiveInteger(y,139);
if(D>%_MaxSmi()){
throw MakeRangeError(139);
}
var G=false;
var E=D*8;
if(E<=%_TypedArrayMaxSizeInHeap()){
%_TypedArrayInitialize(v,8,null,0,E,false);
}else{
G=
%TypedArrayInitializeFromArrayLike(v,8,F,D);
}
if(!G){
for(var H=0;H<D;H++){
v[H]=F[H];
}
}
}
--- END ---
--- FUNCTION SOURCE (Int32ArrayConstructByLength) id{78,0} ---
(v,y){
var D=(y===(void 0))?
0:$toPositiveInteger(y,139);
if(D>%_MaxSmi()){
throw MakeRangeError(139);
}
var E=D*4;
if(E>%_TypedArrayMaxSizeInHeap()){
var w=new d(E);
%_TypedArrayInitialize(v,6,w,0,E,true);
}else{
%_TypedArrayInitialize(v,6,null,0,E,true);
}
}
--- END ---
--- FUNCTION SOURCE (debugs.(anonymous function)) id{79,0} ---
() {}
--- END ---
--- FUNCTION SOURCE (GIFEncoder.writeShort) id{80,0} ---
(pValue) {
  this.writeByte(pValue & 0xFF);
  this.writeByte((pValue >> 8) & 0xFF);
}
--- END ---
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{80,1} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{80,1} AS 1 AT <0:18>
--- FUNCTION SOURCE (ByteCapacitor.writeByte) id{80,2} ---
(val) {
  this.data.push(val);
}
--- END ---
INLINE (ByteCapacitor.writeByte) id{80,2} AS 2 AT <0:51>
--- FUNCTION SOURCE (isNull) id{81,0} ---
(arg) {
  return arg === null;
}
--- END ---
--- FUNCTION SOURCE (MAXCODE) id{82,0} ---
(n_bits) {
    return (1 << n_bits) - 1;
  }
--- END ---

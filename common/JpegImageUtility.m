//
//  JpegImageUtility.m
//  pixiViewer
//
//  Created by nya on 09/08/21.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "JpegImageUtility.h"


#ifdef USE_JPEGLIB


#import "jpeglib.h"


@interface WinBitmap : NSObject {
	NSMutableData	*data_;
	UInt8			*dataPtr_;
	int				width_, height_;
}

- (id) initWithWidth:(int)w height:(int)h;
- (UInt8 *) lineBuffer;
- (void) lineBufferNext;

- (UIImage *) createImage;

@end

static void writeShort(UInt8 *ptr, UInt16 val) {
	*ptr = (UInt8)(val % 0xFF);
	ptr++;
	*ptr = (UInt8)((val >> 8) % 0xFF);
	ptr++;
}

static void writeLong(UInt8 *ptr, UInt32 val) {
	*ptr = (UInt8)(val % 0xFF);
	ptr++;
	*ptr = (UInt8)((val >> 8) % 0xFF);
	ptr++;
	*ptr = (UInt8)((val >> 16) % 0xFF);
	ptr++;
	*ptr = (UInt8)((val >> 24) % 0xFF);
	ptr++;
}

@implementation WinBitmap

- (UInt64) imageLineBytes {
	int	mod = width_ * 3 % 4;
	if (mod) {
		return width_ * 3 + (4 - mod);
	} else {
		return width_ * 3;
	}
}

- (UInt32) imageDataSize {
	return [self imageLineBytes] * height_;
}

/// ファイルヘッダ
- (UInt32) fileHeaderSize {
	return 14;
}

// 情報ヘッダ
- (long) infoHeaderSize {
	return 40;
}

- (long) writeFileHeader {
	unsigned long		filesize;
	unsigned long		offset;
	long long			longlong;
	
	UInt8				*ptr = dataPtr_;
	
	// offset
	offset = [self fileHeaderSize] + [self infoHeaderSize];

	// filesize
	longlong = [self imageLineBytes] * height_ + offset;
	if (longlong > 0xFFFFFFFF) {
		return -1;
	} else {
		filesize = longlong;
	}
	
	// 識別文字 BM 
	*ptr = 'B';
	ptr++;
	*ptr = 'M';
	ptr++;

	// ファイルサイズ bfSize 
	writeLong(ptr, filesize);
	
	// 予約エリア bfReserved1 
	writeShort(ptr, 0x0000);

	// 予約エリア bfReserved2 
	writeShort(ptr, 0x0000);

	// データ部までのオフセット bfOffBits 
	writeLong(ptr, offset);
	
	dataPtr_ += [self fileHeaderSize];
	return 0;
}

- (long) writeInfoHeader {
	unsigned long		ulong;
	long				slong;
	unsigned short		ushort;
	long				err = 0;

	UInt8				*ptr = dataPtr_;
		
	// 情報ヘッダサイズ
	ulong = [self infoHeaderSize];
	writeLong(ptr, ulong);

	// 幅
	if (width_ & 0x80000000) {
		// 範囲オーバー
		return -1;
	}
	slong = width_;
	writeLong(ptr, slong);

	// 高さ
	if (height_ & 0x80000000) {
		// 範囲オーバー
		return -1;
	}
	slong = height_;
	writeLong(ptr, slong);
	
	// プレーン数(常に1)
	ushort = 1;
	writeShort(ptr, ushort);
	
	// 色ビット数[bit]	1,4,8,(16),24,32
	ushort = 24;
	writeShort(ptr, ushort);
	
	// 圧縮形式	0,1,2,3
	//0 - BI_RGB（無圧縮）
	//1 - BI_RLE8（Run-Length-Encoded 8bits/pixel）
	//2 - BI_RLE4（Run-Length-Encoded 4bits/pixel）
	//3 - BI_BITFIELDS
	ulong = 0;
	writeLong(ptr, ulong);
	
	// 画像データサイズ[byte]
	ulong = [self imageDataSize];
	writeLong(ptr, ulong);
	
	// 水平解像度[dot/m]
	ulong = 0x0B12;				// 72dpi
	writeLong(ptr, ulong);

	// 垂直解像度[dot/m]
	ulong = 0x0B12;				// 72dpi
	writeLong(ptr, ulong);
	
	// 格納パレット数[使用色数]
	ulong = 0;
	writeLong(ptr, ulong);
	
	// 重要色数
	ulong = 0;
	writeLong(ptr, ulong);

	dataPtr_ += [self infoHeaderSize];
	return err;
}

- (id) initWithWidth:(int)w height:(int)h {
	self = [super init];
	if (self) {
		width_ = w;
		height_ = h;
		data_ = [[NSMutableData alloc] initWithLength:[self imageDataSize]];
		if (data_ == nil) {
			[self release];
			return nil;
		}
		dataPtr_ = (UInt8 *)[data_ mutableBytes];
		
		if ([self writeFileHeader]) {
			[self release];
			return nil;
		}
		
		if ([self writeInfoHeader]) {
			[self release];
			return nil;
		}
		
		// 最後の行へ
		dataPtr_ += [self imageLineBytes] * (height_ - 1);
	}
	return self;
}

- (void) dealloc {
	[data_ release];
	[super dealloc];
}

- (long) addLine:(NSData *)data {
	int					idx;
	
	unsigned char		*rgb = (unsigned char *)[data bytes];
	const unsigned long length = [data length];
	
	if (width_ * 3 != length) {
		return -1;
	}
		
	// rgb -> bgr
	for (idx = 0; idx < length; idx += 3) {
		dataPtr_[idx] = rgb[idx + 2];
		dataPtr_[idx + 1] = rgb[idx + 1];
		dataPtr_[idx + 2] = rgb[idx];
	}
	
	dataPtr_ -= [self imageLineBytes];
	return 0;
}

- (UInt8 *) lineBuffer {
	return dataPtr_;
}

- (void) lineBufferNext {
	int		idx;
	UInt8	tmp;
	
	// rgb -> bgr
	for (idx = 0; idx < 3 * width_; idx += 3) {
		tmp = dataPtr_[idx];
		dataPtr_[idx] = dataPtr_[idx + 2];
		dataPtr_[idx + 2] = tmp;
	}
	
	dataPtr_ -= [self imageLineBytes];
}

- (UIImage *) createImage {
	return [[UIImage alloc] initWithData:data_];
}

@end


/* メモリソースからのJPEG展開用マネージャ */
typedef struct {
	struct jpeg_source_mgr pub;	/* public fields */

	JOCTET * buffer;
	unsigned long buffer_length;
} memory_source_mgr;
typedef memory_source_mgr *memory_src_ptr;


METHODDEF(void) memory_init_source (j_decompress_ptr cinfo)
{
}


METHODDEF(boolean) memory_fill_input_buffer (j_decompress_ptr cinfo)
{
	memory_src_ptr src = (memory_src_ptr) cinfo->src;

	src->buffer[0] = (JOCTET) 0xFF;
	src->buffer[1] = (JOCTET) JPEG_EOI;
	src->pub.next_input_byte = src->buffer;
	src->pub.bytes_in_buffer = 2;
	return TRUE;
}

METHODDEF(void) memory_skip_input_data (j_decompress_ptr cinfo, long num_bytes)
{
	memory_src_ptr src = (memory_src_ptr) cinfo->src;

	if (num_bytes > 0) {
		src->pub.next_input_byte += (size_t) num_bytes;
		src->pub.bytes_in_buffer -= (size_t) num_bytes;
	}
}

METHODDEF(void) memory_term_source (j_decompress_ptr cinfo)
{
}


GLOBAL(void)
jpeg_memory_src (j_decompress_ptr cinfo, const void *data, unsigned long len)
{
	memory_src_ptr src;

	if (cinfo->src == NULL) {	/* first time for this JPEG object? */
		cinfo->src = (struct jpeg_source_mgr *)
		(*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_PERMANENT,
		  sizeof(memory_source_mgr));
		src = (memory_src_ptr) cinfo->src;
		src->buffer = (JOCTET *)
		(*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_PERMANENT,
		  len * sizeof(JOCTET));
	}

	src = (memory_src_ptr) cinfo->src;

	src->pub.init_source = memory_init_source;
	src->pub.fill_input_buffer = memory_fill_input_buffer;
	src->pub.skip_input_data = memory_skip_input_data;
	src->pub.resync_to_restart = jpeg_resync_to_restart; /* use default method */
	src->pub.term_source = memory_term_source;

	src->pub.bytes_in_buffer = len;
	src->pub.next_input_byte = (JOCTET*)data;
}

#pragma mark-

// 独自のエラーハンドリングを行う場合使用
typedef struct image_reader_jpeg_err_mgr {
	struct jpeg_error_mgr pub;	/* "public" fields */

	// 独自の拡張部分
	jmp_buf setjmp_buffer;	/* for return to caller */
} ImageReaderErrorManager;

/// dpi <- dpm
static double DPIFromDotPerMeter(const long dpm) {
	return (long)dpm * 0.0254;
}

METHODDEF(void) my_error_exit (j_common_ptr cinfo) {
	ImageReaderErrorManager		*myerr = (ImageReaderErrorManager *)cinfo->err;

	(*cinfo->err->output_message) (cinfo);

	// setjmp へ戻る
	longjmp(myerr->setjmp_buffer, 1);
}

#pragma mark-

UIImage *JpegRestrictedImage(NSData *data) {
	struct jpeg_decompress_struct	cinfo;
    ImageReaderErrorManager			jerr;
	UIImage		*ret = nil;

	// エラー
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;

    // 以降の jpeg ライブラリ内でエラーが生じた場合、資源を開放して終わる。
    if (setjmp(jerr.setjmp_buffer)) {
		goto bail;
    }
	// 作成
    jpeg_create_decompress(&cinfo);

	// 入力
	jpeg_memory_src(&cinfo, [data bytes], [data length]);
    // ファイルの情報ヘッダの読込み
    jpeg_read_header(&cinfo, TRUE);

	// サイズチェック
	if (cinfo.image_width <= 0 || cinfo.image_height <= 0) {
		goto bail;
	} else if (cinfo.image_width <= 1024 && cinfo.image_height <= 1024) {
		// UIImage作れます
		ret = [[UIImage alloc] initWithData:data];
		[ret autorelease];
		goto bail;
	}
	
	// 分割数
	int	col = (cinfo.image_width - 1) / 1024 + 1;
	int	row = (cinfo.image_height - 1) / 1024 + 1;
	int	x, y;
	
	float mag;
	if (cinfo.image_height < cinfo.image_width) {
		mag = 1024.0 / (float)cinfo.image_width;
	} else {
		mag = 1024.0 / (float)cinfo.image_height;
	}
	
	for (y = 0; y < row; y++) {
		int	h;
		if (cinfo.image_height > 1024) {
			if (y < row - 1) {
				h = 1024;
			} else {
				h = cinfo.image_height - (1024 * row - 1);
			}
		} else {
			h = cinfo.image_height;
		}
		for (x = 0; x < col; x++) {
			int	w;
			if (cinfo.image_width > 1024) {
				if (x < col - 1) {
					w = 1024;
				} else {
					w = cinfo.image_height - (1024 * col - 1);
				}
			} else {
				w = cinfo.image_height;
			}
			
			
		}
	}
	
	CGSize	newSize = CGSizeMake(mag * cinfo.image_width, mag * cinfo.image_width);
	UIGraphicsBeginImageContext(newSize);

	if (col == 1) {
		int	line;
		int	w, h;
		w = cinfo.image_width;

		for (y = 0; y < row; y++) {
			if (cinfo.image_height > 1024) {
				if (y < row - 1) {
					h = 1024;
				} else {
					h = cinfo.image_height - (1024 * row - 1);
				}
			} else {
				h = cinfo.image_height;
			}
		
			WinBitmap *bitmap = [[WinBitmap alloc] initWithWidth:w height:h];
			if (bitmap == nil) {
				assert(0);
				goto bail;
			}
		
			for (line = 0; line < h; line++) {
				JDIMENSION	readed;
				UInt8		*ptr = [bitmap lineBuffer];
						
				readed = jpeg_read_scanlines(&cinfo, &ptr, 1);
				if (readed != 1) {
					assert(0);
					[bitmap release];
					goto bail;
				}
				[bitmap lineBufferNext];
			}
		
			CGRect	ir;
			ir.origin.x = 0;
			ir.origin.y = 1024 * y * mag;
			ir.size.width = w * mag;
			ir.size.height = h * mag;
		
			UIImage	*part = [bitmap createImage];
			[bitmap release];
			[part drawInRect:ir];
			[part release];
		}
	} else {
	
	}

	ret = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();			

bail:
	jpeg_destroy_decompress(&cinfo);
	return ret;
}


#else

UIImage *JpegRestrictedImage(NSData *data) {
	UIImage	*ret = [[UIImage alloc] initWithData:data];
	[ret autorelease];
	return ret;
}

#endif

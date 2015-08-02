/*
Copyright (c) 2012, Broadcom Europe Ltd
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the copyright holder nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/** \file
 *  Jpeg encoder and decoder library using the hardware jpeg codec
 */

#include "interface/mmal/mmal.h"
#include "interface/mmal/util/mmal_component_wrapper.h"
#include "interface/mmal/util/mmal_util_params.h"
#include "interface/mmal/mmal_logging.h"
#include "brcmimage.h"
#include "stdio.h"

/*******************************************************************************
* Defines
*******************************************************************************/
#define MMAL_COMPONENT_IMAGE_DECODE "vc.aggregator.pipeline:ril.image_decode:video_convert"
#define MMAL_COMPONENT_IMAGE_ENCODE "vc.ril.image_encode"

#define ENABLE_SLICE_MODE 0

#define CHECK_MMAL_STATUS(status, jerr, msg, ...) \
   if (status != MMAL_SUCCESS) {LOG_ERROR(msg, ## __VA_ARGS__); \
   err = BRCMIMAGE_ERROR_##jerr; goto error;}

/*******************************************************************************
* Type definitions
*******************************************************************************/
struct BRCMIMAGE_T
{
   BRCMIMAGE_TYPE_T type;
   unsigned int encoding;
   unsigned int ref_count;
   unsigned int init;

   MMAL_WRAPPER_T *mmal;
   unsigned int slice_height;

   VCOS_MUTEX_T lock;
   VCOS_MUTEX_T process_lock;
   VCOS_SEMAPHORE_T sema;
};

/*******************************************************************************
* Local prototypes
*******************************************************************************/
static BRCMIMAGE_STATUS_T brcmimage_init_encoder(BRCMIMAGE_T *);
static BRCMIMAGE_STATUS_T brcmimage_init_decoder(BRCMIMAGE_T *);
static BRCMIMAGE_STATUS_T brcmimage_configure_encoder(BRCMIMAGE_T *, BRCMIMAGE_REQUEST_T *);
static BRCMIMAGE_STATUS_T brcmimage_configure_decoder(BRCMIMAGE_T *, BRCMIMAGE_REQUEST_T *);
static BRCMIMAGE_STATUS_T brcmimage_encode(BRCMIMAGE_T *, BRCMIMAGE_REQUEST_T *);
static BRCMIMAGE_STATUS_T brcmimage_decode(BRCMIMAGE_T *, BRCMIMAGE_REQUEST_T *);
static void brcmimage_destroy(BRCMIMAGE_T *);

static MMAL_FOURCC_T brcmimage_pixfmt_to_encoding(BRCMIMAGE_PIXEL_FORMAT_T);
static unsigned int brcmimage_copy_pixels(uint8_t *out, unsigned int out_size,
   const uint8_t *in, unsigned int in_size, BRCMIMAGE_PIXEL_FORMAT_T fmt,
   unsigned int out_width, unsigned int out_height,
   unsigned int in_width, unsigned int in_height,
   unsigned int line_offset, unsigned int convert_from);

#define MAX_ENCODER_TYPES 10
static BRCMIMAGE_T *brcmimage_encoder[MAX_ENCODER_TYPES];
static BRCMIMAGE_T *brcmimage_decoder[MAX_ENCODER_TYPES];

/*******************************************************************************
* Platform specific code
*******************************************************************************/
static VCOS_ONCE_T once = VCOS_ONCE_INIT;
static VCOS_MUTEX_T brcmimage_lock;

static void brcmimage_init_once(void)
{
   vcos_mutex_create(&brcmimage_lock, VCOS_FUNCTION);

   for (int i=0; i < MAX_ENCODER_TYPES; i++)
   {
       brcmimage_encoder[i] = NULL;
       brcmimage_decoder[i] = NULL;
   }

}

#define LOCK() vcos_mutex_lock(&brcmimage_lock)
#define UNLOCK() vcos_mutex_unlock(&brcmimage_lock)
#define LOCK_COMP(ctx) vcos_mutex_lock(&(ctx)->lock)
#define UNLOCK_COMP(ctx) vcos_mutex_unlock(&(ctx)->lock)
#define LOCK_PROCESS(ctx) vcos_mutex_lock(&(ctx)->process_lock)
#define UNLOCK_PROCESS(ctx) vcos_mutex_unlock(&(ctx)->process_lock)
#define WAIT(ctx) vcos_semaphore_wait(&(ctx)->sema)
#define SIGNAL(ctx) vcos_semaphore_post(&(ctx)->sema)

/*******************************************************************************
* Implementation
*******************************************************************************/

inline int getEncoderIndexFromType(unsigned int encoding)
{
    switch(encoding)
    {
        case MMAL_ENCODING_GIF: return 1; break;
        case MMAL_ENCODING_PNG: return 2; break;
        case MMAL_ENCODING_PPM: return 3; break;
        case MMAL_ENCODING_TGA: return 4; break;
        case MMAL_ENCODING_BMP: return 5; break;
        default:
            return 0;
    }
}

BRCMIMAGE_STATUS_T brcmimage_create(BRCMIMAGE_TYPE_T type, unsigned int encoding, BRCMIMAGE_T **ctx)
{
   BRCMIMAGE_STATUS_T status = BRCMIMAGE_SUCCESS;
   BRCMIMAGE_T **comp;

   if (type == BRCMIMAGE_TYPE_ENCODER)
      comp = &brcmimage_encoder[getEncoderIndexFromType(encoding)];
   else
      comp = &brcmimage_decoder[getEncoderIndexFromType(encoding)];

   vcos_once(&once, brcmimage_init_once);
   LOCK();
   if (!*comp)
   {
      int init1, init2, init3;
      *comp = (BRCMIMAGE_T*)calloc(sizeof(BRCMIMAGE_T), 1);
      if (!*comp)
      {
         UNLOCK();
         return BRCMIMAGE_ERROR_NOMEM;
      }
      (*comp)->type = type;
      (*comp)->encoding = encoding;
      init1 = vcos_mutex_create(&(*comp)->lock, "brcmimage lock") != VCOS_SUCCESS;
      init2 = vcos_mutex_create(&(*comp)->process_lock, "brcmimage process lock") != VCOS_SUCCESS;
      init3 = vcos_semaphore_create(&(*comp)->sema, "brcmimage sema", 0) != VCOS_SUCCESS;
      if (init1 | init2 | init3)
      {
         if (init1) vcos_mutex_delete(&(*comp)->lock);
         if (init2) vcos_mutex_delete(&(*comp)->process_lock);
         if (init3) vcos_semaphore_delete(&(*comp)->sema);
         free(comp);
         UNLOCK();
         return BRCMIMAGE_ERROR_NOMEM;
      }
   }
   (*comp)->ref_count++;
   UNLOCK();

   LOCK_COMP(*comp);
   if (!(*comp)->init)
   {
      if (type == BRCMIMAGE_TYPE_ENCODER)
         status = brcmimage_init_encoder(*comp);
      else
         status = brcmimage_init_decoder(*comp);

      (*comp)->init = status == BRCMIMAGE_SUCCESS;
   }
   UNLOCK_COMP(*comp);

   if (status != BRCMIMAGE_SUCCESS)
      brcmimage_release(*comp);

   *ctx = *comp;
   return status;
}

void brcmimage_acquire(BRCMIMAGE_T *ctx)
{
   LOCK_COMP(ctx);
   ctx->ref_count++;
   UNLOCK_COMP(ctx);
}

void brcmimage_release(BRCMIMAGE_T *ctx)
{
   LOCK_COMP(ctx);
   if (--ctx->ref_count)
   {
      UNLOCK_COMP(ctx);
      return;
   }

   LOCK();
   if (ctx->type == BRCMIMAGE_TYPE_ENCODER)
      brcmimage_encoder[ctx->encoding] = NULL;
   else
      brcmimage_decoder[ctx->encoding] = NULL;
   UNLOCK();
   UNLOCK_COMP(ctx);

   brcmimage_destroy(ctx);
   return;
}

BRCMIMAGE_STATUS_T brcmimage_process(BRCMIMAGE_T *ctx, BRCMIMAGE_REQUEST_T *req)
{
   BRCMIMAGE_STATUS_T status;

   /* Sanity check */
   if ((req->input && req->input_handle) ||
       (req->output && req->output_handle))
   {
      LOG_ERROR("buffer pointer and handle both set (%p/%u %p/%u)",
            req->input, req->input_handle, req->output, req->output_handle);
      return BRCMIMAGE_ERROR_REQUEST;
   }

   LOCK_PROCESS(ctx);
   if (ctx->type == BRCMIMAGE_TYPE_ENCODER)
      status = brcmimage_encode(ctx, req);
   else
      status = brcmimage_decode(ctx, req);
   UNLOCK_PROCESS(ctx);

   return status;
}

static void brcmimage_destroy(BRCMIMAGE_T *ctx)
{
   if (ctx->mmal)
      mmal_wrapper_destroy(ctx->mmal);
   vcos_mutex_delete(&ctx->lock);
   vcos_mutex_delete(&ctx->process_lock);
   vcos_semaphore_delete(&ctx->sema);
   free(ctx);
}

static void brcmimage_mmal_cb(MMAL_WRAPPER_T *wrapper)
{
   BRCMIMAGE_T *ctx = (BRCMIMAGE_T*)wrapper->user_data;
   SIGNAL(ctx);
}

static BRCMIMAGE_STATUS_T brcmimage_init_encoder(BRCMIMAGE_T *ctx)
{
   MMAL_STATUS_T status;
   BRCMIMAGE_STATUS_T err = BRCMIMAGE_SUCCESS;

   /* Create encoder component */
   status = mmal_wrapper_create(&ctx->mmal, MMAL_COMPONENT_IMAGE_ENCODE);
   CHECK_MMAL_STATUS(status, INIT, "failed to create encoder");
   ctx->mmal->user_data = ctx;
   ctx->mmal->callback = brcmimage_mmal_cb;

   /* Configure things that won't change from encode to encode */
   mmal_port_parameter_set_boolean(ctx->mmal->control,
      MMAL_PARAMETER_EXIF_DISABLE, MMAL_TRUE);

   ctx->mmal->output[0]->format->encoding = ctx->encoding;
   status = mmal_port_format_commit(ctx->mmal->output[0]);
   CHECK_MMAL_STATUS(status, INIT, "failed to commit output port format");

   ctx->mmal->output[0]->buffer_size = ctx->mmal->output[0]->buffer_size_min;
   ctx->mmal->output[0]->buffer_num = 3;
   status = mmal_wrapper_port_enable(ctx->mmal->output[0], 0);
   CHECK_MMAL_STATUS(status, INIT, "failed to enable output port");

   LOG_DEBUG("encoder initialised (output chunk size %i)\n",
      ctx->mmal->output[0]->buffer_size);
   return BRCMIMAGE_SUCCESS;

 error:
   return err;
}

static BRCMIMAGE_STATUS_T brcmimage_init_decoder(BRCMIMAGE_T *ctx)
{
   MMAL_STATUS_T status;
   BRCMIMAGE_STATUS_T err = BRCMIMAGE_SUCCESS;

   /* Create decoder component */
   status = mmal_wrapper_create(&ctx->mmal, MMAL_COMPONENT_IMAGE_DECODE);
   CHECK_MMAL_STATUS(status, INIT, "failed to create decoder");
   ctx->mmal->user_data = ctx;
   ctx->mmal->callback = brcmimage_mmal_cb;

   /* Configure things that won't change from decode to decode */
   ctx->mmal->input[0]->format->encoding = ctx->encoding;
   status = mmal_port_format_commit(ctx->mmal->input[0]);
   CHECK_MMAL_STATUS(status, INIT, "failed to commit input port format");

   ctx->mmal->input[0]->buffer_size = ctx->mmal->input[0]->buffer_size_min;
   ctx->mmal->input[0]->buffer_num = 3;
   status = mmal_wrapper_port_enable(ctx->mmal->input[0], 0);
   CHECK_MMAL_STATUS(status, INIT, "failed to enable input port");

   LOG_DEBUG("decoder initialised (input chunk size %i)\n",
      ctx->mmal->input[0]->buffer_size);
   return BRCMIMAGE_SUCCESS;

 error:
   return BRCMIMAGE_ERROR_INIT;
}

/* Configuration which needs to be done on a per encode basis */
static BRCMIMAGE_STATUS_T brcmimage_configure_encoder(BRCMIMAGE_T *ctx,
   BRCMIMAGE_REQUEST_T *req)
{
   MMAL_STATUS_T status = MMAL_SUCCESS;
   MMAL_FOURCC_T encoding = brcmimage_pixfmt_to_encoding(req->pixel_format);
   MMAL_PORT_T *port_in;
   BRCMIMAGE_STATUS_T err = BRCMIMAGE_SUCCESS;
   MMAL_BOOL_T slice_mode = MMAL_FALSE;

   if (encoding == MMAL_ENCODING_UNKNOWN)
      status = MMAL_EINVAL;
   CHECK_MMAL_STATUS(status, INPUT_FORMAT, "format not supported (%i)",
      req->pixel_format);

   if (!req->buffer_width)
      req->buffer_width = req->width;
   if (!req->buffer_height)
      req->buffer_height = req->height;
   if (req->buffer_width < req->width || req->buffer_height < req->height)
      status = MMAL_EINVAL;
   CHECK_MMAL_STATUS(status, INPUT_FORMAT, "invalid buffer width/height "
      "(%i<=%i %i<=%i)", req->buffer_width, req->width, req->buffer_height,
      req->height);

   ctx->slice_height = 0;
   ctx->mmal->status = MMAL_SUCCESS;
   port_in = ctx->mmal->input[0];

   /* The input port needs to be re-configured to take into account
    * the properties of the new frame to encode */
   if (port_in->is_enabled)
   {
      status = mmal_wrapper_port_disable(port_in);
      CHECK_MMAL_STATUS(status, EXECUTE, "failed to disable input port");
   }

   port_in->format->encoding = encoding;
   port_in->format->es->video.width =
      port_in->format->es->video.crop.width = req->width;
   port_in->format->es->video.height =
      port_in->format->es->video.crop.height = req->height;
   port_in->buffer_num = 1;

   if (!req->input_handle &&
         (port_in->format->encoding == MMAL_ENCODING_I420 ||
          port_in->format->encoding == MMAL_ENCODING_I422))
   {
      if (port_in->format->encoding == MMAL_ENCODING_I420)
         port_in->format->encoding = MMAL_ENCODING_I420_SLICE;
      else if (port_in->format->encoding == MMAL_ENCODING_I422)
         port_in->format->encoding = MMAL_ENCODING_I422_SLICE;
      slice_mode = MMAL_TRUE;
      port_in->buffer_num = 3;
   }

   status = mmal_port_format_commit(port_in);
   CHECK_MMAL_STATUS(status, INPUT_FORMAT, "failed to commit input port format");

   ctx->slice_height = slice_mode ? 16 : port_in->format->es->video.height;
   port_in->buffer_size = port_in->buffer_size_min;

   if (req->input_handle)
      status = mmal_wrapper_port_enable(port_in, MMAL_WRAPPER_FLAG_PAYLOAD_USE_SHARED_MEMORY);
   else
      status = mmal_wrapper_port_enable(port_in, MMAL_WRAPPER_FLAG_PAYLOAD_ALLOCATE);
   CHECK_MMAL_STATUS(status, EXECUTE, "failed to enable input port");

   mmal_port_parameter_set_uint32(ctx->mmal->output[0],
      MMAL_PARAMETER_JPEG_Q_FACTOR, req->quality);

   if (!ctx->mmal->output[0]->is_enabled)
   {
      status = mmal_wrapper_port_enable(ctx->mmal->output[0], 0);
      CHECK_MMAL_STATUS(status, EXECUTE, "failed to enable output port");
   }

   LOG_DEBUG("encoder configured (%4.4s:%ux%u|%ux%u slice: %u)\n",
      (char *)&port_in->format->encoding,
      port_in->format->es->video.crop.width, port_in->format->es->video.crop.height,
      port_in->format->es->video.width, port_in->format->es->video.height,
      ctx->slice_height);
   return BRCMIMAGE_SUCCESS;

 error:
   return err;
}

/* Configuration which needs to be done on a per decode basis */
static BRCMIMAGE_STATUS_T brcmimage_configure_decoder(BRCMIMAGE_T *ctx,
   BRCMIMAGE_REQUEST_T *req)
{
   MMAL_STATUS_T status = MMAL_SUCCESS;
   MMAL_FOURCC_T encoding = brcmimage_pixfmt_to_encoding(req->pixel_format);
   MMAL_PORT_T *port_out;
   BRCMIMAGE_STATUS_T err = BRCMIMAGE_SUCCESS;

   if (encoding != MMAL_ENCODING_I420 &&
       encoding != MMAL_ENCODING_I422 &&
       encoding != MMAL_ENCODING_RGBA)
      status = MMAL_EINVAL;
   CHECK_MMAL_STATUS(status, OUTPUT_FORMAT, "format not supported");

   ctx->slice_height = 0;
   ctx->mmal->status = MMAL_SUCCESS;
   port_out = ctx->mmal->output[0];

   /* The input port needs to be re-configured to take into account
    * the properties of the new frame to decode */
   if (port_out->is_enabled)
   {
       status = mmal_wrapper_port_disable(port_out);
       CHECK_MMAL_STATUS(status, EXECUTE, "failed to disable output port");
   }

   /* We assume that we do not know the format of the new jpeg to be decoded
    * and configure the input port for autodetecting the new format */
   port_out->format->encoding = encoding;
   port_out->format->es->video.width =
      port_out->format->es->video.crop.width = 0;
   port_out->format->es->video.height =
      port_out->format->es->video.crop.height = 0;
   status = mmal_port_format_commit(port_out);
   CHECK_MMAL_STATUS(status, OUTPUT_FORMAT, "failed to commit output port format");

   port_out->buffer_num = 1;
   if (req->output_handle)
      status = mmal_wrapper_port_enable(port_out, MMAL_WRAPPER_FLAG_PAYLOAD_USE_SHARED_MEMORY);
   else
      status = mmal_wrapper_port_enable(port_out, MMAL_WRAPPER_FLAG_PAYLOAD_ALLOCATE);
   CHECK_MMAL_STATUS(status, EXECUTE, "failed to enable output port");

   LOG_DEBUG("decoder configured (%4.4s:%ux%u|%ux%u)\n", (char *)&port_out->format->encoding,
         port_out->format->es->video.crop.width, port_out->format->es->video.crop.height,
         port_out->format->es->video.width, port_out->format->es->video.height);
   return BRCMIMAGE_SUCCESS;

 error:
   return err;
}

static BRCMIMAGE_STATUS_T brcmimage_encode(BRCMIMAGE_T *ctx,
   BRCMIMAGE_REQUEST_T *je)
{
   BRCMIMAGE_STATUS_T err;
   MMAL_STATUS_T status = MMAL_SUCCESS;
   MMAL_BUFFER_HEADER_T *in, *out;
   MMAL_BOOL_T eos = MMAL_FALSE;
   const uint8_t *outBuf = je->output;
   unsigned int loop = 0, slices = 0, outBufSize = je->output_alloc_size;
   MMAL_PORT_T *port_in = ctx->mmal->input[0];
   MMAL_PORT_T *port_out = ctx->mmal->output[0];

   je->output_size = 0;
   err = brcmimage_configure_encoder(ctx, je);
   if (err != BRCMIMAGE_SUCCESS)
      return err;

   /* Then we read the encoded data back from the encoder */

   while (!eos && status == MMAL_SUCCESS)
   {
      /* send buffers to be filled */
      while (mmal_wrapper_buffer_get_empty(port_out, &out, 0) == MMAL_SUCCESS)
      {
         out->data = (uint8_t *)outBuf;
         out->alloc_size = MMAL_MIN(port_out->buffer_size, outBufSize);
         outBufSize -= out->alloc_size;
         outBuf += out->alloc_size;
         status = mmal_port_send_buffer(port_out, out);
         CHECK_MMAL_STATUS(status, EXECUTE, "failed to send buffer");
      }

      /* Send slices to be encoded */
      if (slices * ctx->slice_height < port_in->format->es->video.height &&
          mmal_wrapper_buffer_get_empty(port_in, &in, 0) == MMAL_SUCCESS)
      {
         if (je->input_handle)
         {
            in->data = (uint8_t *)je->input_handle;
            in->length = in->alloc_size = je->input_size;
         }
         else
         {
            in->length = brcmimage_copy_pixels(in->data, in->alloc_size,
               je->input, je->input_size, je->pixel_format,
               port_in->format->es->video.width,
               ctx->slice_height, je->buffer_width, je->buffer_height,
               slices * ctx->slice_height, 1);
            if (!in->length)
               status = MMAL_EINVAL;
            CHECK_MMAL_STATUS(status, INPUT_BUFFER, "input buffer too small");
         }

         slices++;
         if (slices * ctx->slice_height >= port_in->format->es->video.height)
             in->flags = MMAL_BUFFER_HEADER_FLAG_EOS;
         status = mmal_port_send_buffer(port_in, in);
         CHECK_MMAL_STATUS(status, EXECUTE, "failed to send buffer");
      }

      status = mmal_wrapper_buffer_get_full(port_out, &out, 0);
      if (status == MMAL_EAGAIN)
      {
         status = MMAL_SUCCESS;
         WAIT(ctx);
         continue;
      }
      CHECK_MMAL_STATUS(status, EXECUTE, "failed to get full buffer");

      LOG_DEBUG("received %i bytes\n", out->length);
      je->output_size += out->length;
      eos = out->flags & MMAL_BUFFER_HEADER_FLAG_EOS;

      /* Detect when the encoder is running out of space for its output */
      if (++loop >= port_out->buffer_num && !eos && !out->length)
      {
         LOG_ERROR("no more output space for encoder");
         status = MMAL_EINVAL;
      }

      mmal_buffer_header_release(out);
   }

   /* Check if buffer was too small */
   CHECK_MMAL_STATUS(status, OUTPUT_BUFFER, "output buffer too small");

   LOG_DEBUG("encoded W:%ixH:%i:%i (%i bytes) in %i slices\n",
         je->width, je->height, je->pixel_format, je->output_size, slices);
   mmal_port_flush(port_out);
   return BRCMIMAGE_SUCCESS;

 error:
   mmal_wrapper_port_disable(port_in);
   mmal_wrapper_port_disable(port_out);
   return err;
}

static BRCMIMAGE_STATUS_T brcmimage_decode(BRCMIMAGE_T *ctx,
   BRCMIMAGE_REQUEST_T *jd)
{
   BRCMIMAGE_STATUS_T err;
   MMAL_STATUS_T status;
   MMAL_BUFFER_HEADER_T *in, *out;
   MMAL_BOOL_T eos = MMAL_FALSE;
   const uint8_t *inBuf = jd->input;
   unsigned int slices = 0, inBufSize = jd->input_size;
   MMAL_PORT_T *port_in = ctx->mmal->input[0];
   MMAL_PORT_T *port_out = ctx->mmal->output[0];
   LOG_DEBUG("decode %i bytes\n", jd->input_size);

   jd->output_size = 0;
   err = brcmimage_configure_decoder(ctx, jd);
   if (err != BRCMIMAGE_SUCCESS)
      return err;

   while (!eos)
   {
      /* Send as many chunks of data to decode as we can */
      while (inBufSize)
      {
         status = mmal_wrapper_buffer_get_empty(port_in, &in, 0);
         if (status == MMAL_EAGAIN)
            break;
         CHECK_MMAL_STATUS(status, EXECUTE, "failed to get empty buffer (%i)", status);

         in->data = (uint8_t *)inBuf;
         in->length = MMAL_MIN(port_in->buffer_size, inBufSize);
         in->alloc_size = in->length;
         inBufSize -= in->length;
         inBuf += in->length;
         in->flags = inBufSize ? 0 : MMAL_BUFFER_HEADER_FLAG_EOS;
         LOG_DEBUG("send decode in (%i bytes)\n", in->length);
         status = mmal_port_send_buffer(port_in, in);
         CHECK_MMAL_STATUS(status, EXECUTE, "failed to send input buffer");
      }

      /* Check for decoded data */
      status = mmal_wrapper_buffer_get_full(port_out, &out, 0);
      if (status == MMAL_EAGAIN)
      {
         WAIT(ctx);
         continue;
      }
      CHECK_MMAL_STATUS(status, EXECUTE, "error decoding");

      /* Check if a new format has been auto-detected by the decoder */
      if (out->cmd == MMAL_EVENT_FORMAT_CHANGED)
      {
         MMAL_EVENT_FORMAT_CHANGED_T *event = mmal_event_format_changed_get(out);

         if (event)
            mmal_format_copy(port_out->format, event->format);
         mmal_buffer_header_release(out);

         if (!event)
            status = MMAL_EINVAL;
         CHECK_MMAL_STATUS(status, EXECUTE, "invalid format change event");

         LOG_DEBUG("new format (%4.4s:%ux%u|%ux%u)\n", (char *)&event->format->encoding,
            event->format->es->video.crop.width, event->format->es->video.crop.height,
            event->format->es->video.width, event->format->es->video.height);

         /* re-setup the output port for the new format */
         status = mmal_wrapper_port_disable(port_out);
         CHECK_MMAL_STATUS(status, EXECUTE, "failed to disable output port");

         ctx->slice_height = event->format->es->video.height;
         if (ENABLE_SLICE_MODE && !jd->output_handle)
         {
            /* setup slice mode */
            if (port_out->format->encoding == MMAL_ENCODING_I420 ||
               port_out->format->encoding == MMAL_ENCODING_I422)
            {
               if (port_out->format->encoding == MMAL_ENCODING_I420)
                  port_out->format->encoding = MMAL_ENCODING_I420_SLICE;
               if (port_out->format->encoding == MMAL_ENCODING_I422)
                  port_out->format->encoding = MMAL_ENCODING_I422_SLICE;
               ctx->slice_height = 16;
               port_out->buffer_num = 3;
            }
         }

         LOG_DEBUG("using slice size %u\n", ctx->slice_height);
         status = mmal_port_format_commit(port_out);
         CHECK_MMAL_STATUS(status, EXECUTE, "invalid format change event");
         port_out->buffer_size = port_out->buffer_size_min;
         if (jd->output_handle)
            status = mmal_wrapper_port_enable(port_out, MMAL_WRAPPER_FLAG_PAYLOAD_USE_SHARED_MEMORY);
         else
            status = mmal_wrapper_port_enable(port_out, MMAL_WRAPPER_FLAG_PAYLOAD_ALLOCATE);
         CHECK_MMAL_STATUS(status, EXECUTE, "failed to enable output port");

         /* send all our output buffers to the decoder */
         while (mmal_wrapper_buffer_get_empty(port_out, &out, 0) == MMAL_SUCCESS)
         {
            if (jd->output_handle)
            {
               out->data = (uint8_t*)jd->output_handle;
               out->alloc_size = jd->output_alloc_size;
            }
            status = mmal_port_send_buffer(port_out, out);
            CHECK_MMAL_STATUS(status, EXECUTE, "failed to send output buffer");
         }

         continue;
      }

      /* We have part of our output frame */
      jd->width = port_out->format->es->video.crop.width;
      if (!jd->width)
         jd->width = port_out->format->es->video.width;
      if (jd->output_handle)
         jd->buffer_width = port_out->format->es->video.width;
      if (!jd->buffer_width)
         jd->buffer_width = jd->width;
      jd->height = port_out->format->es->video.crop.height;
      if (!jd->height)
         jd->height = port_out->format->es->video.height;
      if (jd->output_handle)
         jd->buffer_height = port_out->format->es->video.height;
      if (!jd->buffer_height)
         jd->buffer_height = jd->height;

      if (jd->output_handle)
      {
         jd->output_size += out->length;
      }
      else
      {
         jd->output_size = brcmimage_copy_pixels(jd->output, jd->output_alloc_size,
            out->data, out->length, jd->pixel_format,
            jd->buffer_width, jd->buffer_height,
            port_out->format->es->video.width,
            ctx->slice_height, slices * ctx->slice_height, 0);
         slices++;
      }

      eos = out->flags & MMAL_BUFFER_HEADER_FLAG_EOS;
      out->length = 0;
      if (eos)
      {
         mmal_buffer_header_release(out);
      }
      else
      {
         status = mmal_port_send_buffer(port_out, out);
         CHECK_MMAL_STATUS(status, EXECUTE, "failed to send output buffer");
      }

      if (!jd->output_size)
         status = MMAL_EINVAL;
      CHECK_MMAL_STATUS(status, OUTPUT_BUFFER, "invalid output buffer");
   }

   LOG_DEBUG("decoded W:%ixH%i:(W%ixH%i):%i in %i slices\n",
      jd->width, jd->height, jd->buffer_width, jd->buffer_height,
      jd->pixel_format, slices);
   mmal_port_flush(port_in);

   return BRCMIMAGE_SUCCESS;

 error:
   mmal_port_flush(port_in);
   return err;
}

/*****************************************************************************/
static struct {
    BRCMIMAGE_PIXEL_FORMAT_T pixel_format;
    MMAL_FOURCC_T encoding;
} mmal_raw_conversion[] = {
    {PIXEL_FORMAT_I420, MMAL_ENCODING_I420},
    {PIXEL_FORMAT_YV12, MMAL_ENCODING_I420},
    {PIXEL_FORMAT_I422, MMAL_ENCODING_I422},
    {PIXEL_FORMAT_YV16, MMAL_ENCODING_I422},
    {PIXEL_FORMAT_YUYV, MMAL_ENCODING_I422},
    {PIXEL_FORMAT_RGBA, MMAL_ENCODING_RGBA},
    {PIXEL_FORMAT_UNKNOWN, MMAL_ENCODING_UNKNOWN} };

static MMAL_FOURCC_T brcmimage_pixfmt_to_encoding(BRCMIMAGE_PIXEL_FORMAT_T pixel_format)
{
   unsigned int i;
   for (i = 0; mmal_raw_conversion[i].encoding != MMAL_ENCODING_UNKNOWN; i++)
      if (mmal_raw_conversion[i].pixel_format == pixel_format)
         break;
   return mmal_raw_conversion[i].encoding;
}

extern void log(const char * format, ...);

// Copy a raw frame from 1 buffer to another, taking care of
// stride / height differences between the input and output buffers.
static unsigned int brcmimage_copy_pixels(uint8_t *out, unsigned int out_size,
    const uint8_t *in, unsigned int in_size, BRCMIMAGE_PIXEL_FORMAT_T fmt,
    unsigned int out_width, unsigned int out_height,
    unsigned int in_width, unsigned int in_height,
    unsigned int line_offset, unsigned int convert_from)
{
    struct {
        uint8_t *data;
        unsigned int pitch;
        unsigned int height;
    } planes[2][3];
    unsigned int num_planes = 0;
    unsigned int i, size = 0;
    unsigned int in_height_full = in_height;
    unsigned int out_height_full = out_height;
    unsigned int k = convert_from ? 1 : 0;

    // Sanity check line_offset
    if (line_offset >= (convert_from ? in_height : out_height))
    {
        return 0;
    }

    if (convert_from)
       in_height -= line_offset;
    else
       out_height -= line_offset;

    if (fmt == PIXEL_FORMAT_I420 ||
        fmt == PIXEL_FORMAT_YV12)
    {
       planes[0][0].data = out;
       planes[0][0].pitch = out_width;
       planes[0][0].height = out_height;

       planes[1][0].data = (uint8_t *)in;
       planes[1][0].pitch = in_width;
       planes[1][0].height = in_height;

       planes[0][1].pitch = planes[0][2].pitch = out_width / 2;
       planes[0][1].height = planes[0][2].height = out_height / 2;
       planes[0][1].data = planes[0][0].data + out_width * out_height_full;
       planes[0][2].data = planes[0][1].data + out_width * out_height_full / 4;

       planes[1][1].pitch = planes[1][2].pitch = in_width / 2;
       planes[1][1].height = planes[1][2].height = in_height / 2;
       planes[1][1].data = planes[1][0].data + in_width * in_height_full;
       planes[1][2].data = planes[1][1].data + in_width * in_height_full / 4;

       if (fmt == PIXEL_FORMAT_YV12)
       {
          // We need to swap U and V
          uint8_t *tmp = planes[1][2].data;
          planes[1][2].data = planes[1][1].data;
          planes[1][1].data = tmp;
       }

       // Add the line offset
       planes[k][0].data += planes[k][0].pitch * line_offset;
       planes[k][1].data += planes[k][1].pitch * line_offset/2;
       planes[k][2].data += planes[k][2].pitch * line_offset/2;

       num_planes = 3;
       size = out_width * out_height_full * 3 / 2;

       if (in_size < in_width * in_height * 3 / 2)
          return 0;

   } else if (fmt == PIXEL_FORMAT_I422 ||
              fmt == PIXEL_FORMAT_YV16 ||
              fmt == PIXEL_FORMAT_YUYV)
   {
      planes[0][0].data = out;
      planes[0][0].pitch = out_width;
      planes[0][0].height = out_height;

      planes[1][0].data = (uint8_t *)in;
      planes[1][0].pitch = in_width;
      planes[1][0].height = in_height;

      planes[0][1].pitch = planes[0][2].pitch = out_width / 2;
      planes[0][1].height = planes[0][2].height = out_height;
      planes[0][1].data = planes[0][0].data + out_width * out_height_full;
      planes[0][2].data = planes[0][1].data + out_width * out_height_full / 2;

      planes[1][1].pitch = planes[1][2].pitch = in_width / 2;
      planes[1][1].height = planes[1][2].height = in_height;
      planes[1][1].data = planes[1][0].data + in_width * in_height_full;
      planes[1][2].data = planes[1][1].data + in_width * in_height_full / 2;

      // Add the line offset
      planes[k][0].data += planes[k][0].pitch * line_offset;
      planes[k][1].data += planes[k][1].pitch * line_offset;
      planes[k][2].data += planes[k][2].pitch * line_offset;
      if (fmt == PIXEL_FORMAT_YUYV)
         planes[k][0].data += planes[k][0].pitch * line_offset;

      if (fmt == PIXEL_FORMAT_YV16)
      {
         // We need to swap U and V
         uint8_t *tmp = planes[1][2].data;
         planes[1][2].data = planes[1][1].data;
         planes[1][1].data = tmp;
      }

      num_planes = 3;
      size = out_width * out_height_full * 2;

      if (in_size < in_width * in_height * 2)
         return 0;
   } else if (fmt == PIXEL_FORMAT_RGBA)
   {
       planes[0][0].data = out;
       planes[0][0].pitch = out_width * 4;
       planes[0][0].height = out_height;

       planes[1][0].data = (uint8_t *)in;
       planes[1][0].pitch = in_width * 4;
       planes[1][0].height = in_height;

       // Add the line offset
       planes[k][0].data += planes[k][0].pitch * line_offset;

       num_planes = 1;
       size = out_width * out_height_full * 4;

       if (in_size < in_width * in_height * 4)
          return 0;
   }

   if (out_size < size)
      return 0;

   // Special case for YUYV where don't just copy but convert to/from I422
   if (fmt == PIXEL_FORMAT_YUYV)
   {
      unsigned int width = in_width > out_width ? out_width : in_width;
      unsigned int height = in_height > out_height ? out_height : in_height;
      uint8_t *y = planes[convert_from ? 0 : 1][0].data;
      uint8_t *u = planes[convert_from ? 0 : 1][1].data;
      uint8_t *v = planes[convert_from ? 0 : 1][2].data;
      uint8_t *yuyv = planes[convert_from ? 1 : 0][0].data;
      unsigned int y_diff = (convert_from ? out_width : in_width) - width;
      unsigned int yuyv_diff = ((convert_from ? in_width : out_width) - width) * 2;

      while (height--)
      {
         if (convert_from)
            for (i = width / 2; i; i--)
            {
                *y++ = *yuyv++;
                *u++ = *yuyv++;
                *y++ = *yuyv++;
                *v++ = *yuyv++;
            }
         else
            for (i = width / 2; i; i--)
            {
                *yuyv++ = *y++;
                *yuyv++ = *u++;
                *yuyv++ = *y++;
                *yuyv++ = *v++;
            }

         yuyv += yuyv_diff;
         y += y_diff;
         u += y_diff >> 1;
         v += y_diff >> 1;
      }

      return size;
   }

   for (i = 0; i < num_planes; i++)
   {
      unsigned int width = MMAL_MIN(planes[0][i].pitch, planes[1][i].pitch);
      unsigned int height = MMAL_MIN(planes[0][i].height, planes[1][i].height);
      uint8_t *data_out = planes[0][i].data;
      uint8_t *data_in = planes[1][i].data;

      while (height--)
      {
         memcpy(data_out, data_in, width);
         data_out += planes[0][i].pitch;
         data_in += planes[1][i].pitch;
      }
   }

   return size;
}

package com.example.tt_video_automator.gpu

import android.graphics.*
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLUtils
import android.opengl.Matrix
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.max

/**
 * High-performance GPU Video Renderer using OpenGL ES 3.0 shaders.
 * Performs background blurring, aspect ratio fit, overlay composition,
 * color adjustment, noise uniqueness, and karaoke subtitle rendering
 * entirely in GPU VRAM without CPU memory copying.
 */
class GpuVideoRenderer(
    private val outputWidth: Int = 720,
    private val outputHeight: Int = 1280
) {
    private val vertexBuffer: FloatBuffer
    private val textureBuffer: FloatBuffer
    private val overlayTextureBuffer: FloatBuffer

    private var oesProgram: GlProgram? = null
    private var blurProgram: GlProgram? = null
    private var overlayProgram: GlProgram? = null

    var oesTextureId: Int = 0
        private set
    var bannerTextureId: Int = 0
        private set
    var textOverlayTextureId: Int = 0
        private set

    private val mvpMatrix = FloatArray(16)
    private val stMatrix = FloatArray(16)

    // Text & Subtitle canvas bitmap for dynamic overlay
    private var textBitmap: Bitmap? = null
    private var textCanvas: Canvas? = null
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    }
    private val highlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#FFCC00") // Neon yellow karaoke highlight
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.BLACK
        style = Paint.Style.STROKE
        strokeWidth = 6f
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    }

    init {
        val squareCoords = floatArrayOf(
            -1.0f, -1.0f,
             1.0f, -1.0f,
            -1.0f,  1.0f,
             1.0f,  1.0f
        )
        val textureCoords = floatArrayOf(
            0.0f, 0.0f,
            1.0f, 0.0f,
            0.0f, 1.0f,
            1.0f, 1.0f
        )
        // 2D Bitmap/Canvas coordinates flipped vertically so Y=0 is top
        val overlayCoords = floatArrayOf(
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f
        )

        vertexBuffer = ByteBuffer.allocateDirect(squareCoords.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(squareCoords)
        vertexBuffer.position(0)

        textureBuffer = ByteBuffer.allocateDirect(textureCoords.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(textureCoords)
        textureBuffer.position(0)

        overlayTextureBuffer = ByteBuffer.allocateDirect(overlayCoords.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(overlayCoords)
        overlayTextureBuffer.position(0)

        Matrix.setIdentityM(mvpMatrix, 0)
        Matrix.setIdentityM(stMatrix, 0)

        initGl()
    }

    private fun initGl() {
        // Vertex shader for 2D quad mapping
        val vertexShader = """
            attribute vec4 aPosition;
            attribute vec4 aTextureCoord;
            uniform mat4 uMVPMatrix;
            uniform mat4 uSTMatrix;
            varying vec2 vTextureCoord;
            void main() {
                gl_Position = uMVPMatrix * aPosition;
                vTextureCoord = (uSTMatrix * aTextureCoord).xy;
            }
        """.trimIndent()

        // Fragment shader for Camera / Video Decoder OES Texture with Color Adjustment & Clean GPU Noise
        val oesFragmentShader = """
            #extension GL_OES_EGL_image_external : require
            precision highp float;
            varying vec2 vTextureCoord;
            uniform samplerExternalOES sTexture;
            uniform float uBrightness;
            uniform float uContrast;
            uniform float uSaturation;
            uniform float uNoiseLevel;
            uniform float uSeed;

            float hash(vec2 p) {
                vec3 p3 = fract(vec3(p.xyx) * 0.1031 + uSeed * 0.0137);
                p3 += dot(p3, p3.yzx + 33.33);
                return fract((p3.x + p3.y) * p3.z);
            }

            void main() {
                vec4 color = texture2D(sTexture, vTextureCoord);
                
                // Brightness
                color.rgb += uBrightness;
                
                // Contrast
                color.rgb = (color.rgb - 0.5) * uContrast + 0.5;
                
                // Saturation
                float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
                color.rgb = mix(vec3(luminance), color.rgb, uSaturation);
                
            // Fine-grain subtle noise uniqueness
            if (uNoiseLevel > 0.0001) {
                float n = (hash(vTextureCoord * 1000.0) - 0.5) * uNoiseLevel;
                color.rgb += n;
            }
                
                gl_FragColor = color;
            }
        """.trimIndent()

        // 9-Tap Fast Gaussian Blur Fragment Shader for Background Layer
        val blurFragmentShader = """
            #extension GL_OES_EGL_image_external : require
            precision highp float;
            varying vec2 vTextureCoord;
            uniform samplerExternalOES sTexture;
            uniform vec2 uTexelOffset;

            void main() {
                vec4 sum = vec4(0.0);
                vec2 tc = vTextureCoord;
                
                sum += texture2D(sTexture, tc - uTexelOffset * 4.0) * 0.05;
                sum += texture2D(sTexture, tc - uTexelOffset * 3.0) * 0.09;
                sum += texture2D(sTexture, tc - uTexelOffset * 2.0) * 0.12;
                sum += texture2D(sTexture, tc - uTexelOffset) * 0.15;
                sum += texture2D(sTexture, tc) * 0.18;
                sum += texture2D(sTexture, tc + uTexelOffset) * 0.15;
                sum += texture2D(sTexture, tc + uTexelOffset * 2.0) * 0.12;
                sum += texture2D(sTexture, tc + uTexelOffset * 3.0) * 0.09;
                sum += texture2D(sTexture, tc + uTexelOffset * 4.0) * 0.05;
                
                gl_FragColor = sum * 0.75; // slightly darkened for premium background look
            }
        """.trimIndent()

        // Standard 2D RGBA Overlay Fragment Shader (Banners and Subtitles)
        val overlayFragmentShader = """
            precision mediump float;
            varying vec2 vTextureCoord;
            uniform sampler2D sTexture;
            uniform float uAlpha;

            void main() {
                vec4 col = texture2D(sTexture, vTextureCoord);
                gl_FragColor = col * uAlpha;
            }
        """.trimIndent()

        // OES Fragment Shader for Hardware-Decoded Animated Video Banner
        val bannerOesFragmentShader = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            varying vec2 vTextureCoord;
            uniform samplerExternalOES sTexture;
            uniform float uAlpha;

            void main() {
                vec4 col = texture2D(sTexture, vTextureCoord);
                gl_FragColor = col * uAlpha;
            }
        """.trimIndent()

        oesProgram = GlProgram(vertexShader, oesFragmentShader)
        blurProgram = GlProgram(vertexShader, blurFragmentShader)
        overlayProgram = GlProgram(vertexShader, overlayFragmentShader)
        bannerOesProgram = GlProgram(vertexShader, bannerOesFragmentShader)

        // Generate textures for video decoder surfaces and overlays
        val textures = IntArray(5)
        GLES20.glGenTextures(5, textures, 0)
        oesTextureId = textures[0]
        bannerTextureId = textures[1]
        textOverlayTextureId = textures[2]
        bannerOesTextureId = textures[3]
        blackTextureId = textures[4]

        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTextureId)
        GLES20.glTexParameterf(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR.toFloat())
        GLES20.glTexParameterf(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR.toFloat())
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)

        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, bannerOesTextureId)
        GLES20.glTexParameterf(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR.toFloat())
        GLES20.glTexParameterf(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR.toFloat())
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)

        val blackBmp = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888).apply {
            setPixel(0, 0, Color.BLACK)
        }
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, blackTextureId)
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, blackBmp, 0)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_NEAREST)
        blackBmp.recycle()

        textBitmap = Bitmap.createBitmap(outputWidth, outputHeight, Bitmap.Config.ARGB_8888)
        textCanvas = Canvas(textBitmap!!)
    }

    private var blackTextureId: Int = 0
    private var lastSubtitleText: String? = null
    private var lastActiveWordIndex: Int = -2
    private var lastPartText: String? = null
    private var lastHookText: String? = null
    private var bannerOesProgram: GlProgram? = null
    var bannerOesTextureId: Int = 0
        private set

    /**
     * Renders a complete 9:16 frame with background blur, centered video,
     * banner overlay, subtitles, part badges, and uniqueness parameters.
     */
    fun drawFrame(
        transformMatrix: FloatArray,
        videoWidth: Int,
        videoHeight: Int,
        brightness: Float = 0.0f,
        contrast: Float = 1.0f,
        saturation: Float = 1.0f,
        noiseLevel: Float = 0.0f,
        seed: Float = 0.0f,
        isMirrored: Boolean = false,
        bannerBitmap: Bitmap? = null,
        hasVideoBanner: Boolean = false,
        bannerTransformMatrix: FloatArray? = null,
        bannerAspectRatio: Float = 16f / 9f,
        bannerXRatio: Float = 0.0f,
        bannerYRatio: Float = 0.122f,
        bannerWidthRatio: Float = 1.0f,
        bannerHeightRatio: Float = 0.161f,
        activeSubtitleText: String? = null,
        activeWordIndex: Int = -1,
        subtitleYRatio: Float = 0.72f,
        partNumberText: String? = null,
        partNumberYRatio: Float = 0.033f,
        textHook: String? = null,
        textHookYRatio: Float = 0.08f,
        fadeFactor: Float = 1.0f
    ) {
        GLES20.glViewport(0, 0, outputWidth, outputHeight)
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)

        // 1. Draw Blurred 9:16 Background
        drawBackgroundBlur(transformMatrix)

        // 2. Draw Centered Main Video
        drawMainVideo(
            transformMatrix = transformMatrix,
            videoWidth = videoWidth,
            videoHeight = videoHeight,
            brightness = brightness,
            contrast = contrast,
            saturation = saturation,
            noiseLevel = noiseLevel,
            seed = seed,
            isMirrored = isMirrored
        )

        // 3. Draw Banner (Video via OES Hardware Texture or Static Bitmap)
        if (hasVideoBanner && bannerTransformMatrix != null) {
            drawVideoBannerOes(bannerTransformMatrix, bannerAspectRatio, bannerXRatio, bannerYRatio, bannerWidthRatio, bannerHeightRatio)
        } else if (bannerBitmap != null) {
            drawBanner(bannerBitmap, bannerXRatio, bannerYRatio, bannerWidthRatio, bannerHeightRatio)
        }

        // 4. Draw Text Overlays (Subtitles + Part Number + Hook)
        if (!activeSubtitleText.isNullOrEmpty() || !partNumberText.isNullOrEmpty() || !textHook.isNullOrEmpty()) {
            drawTextOverlays(
                subtitleText = activeSubtitleText,
                activeWordIndex = activeWordIndex,
                subtitleYRatio = subtitleYRatio,
                partText = partNumberText,
                partYRatio = partNumberYRatio,
                hookText = textHook,
                hookYRatio = textHookYRatio
            )
        }

        // 5. Draw Smooth Fade-In / Fade-Out Black Overlay
        if (fadeFactor < 0.999f) {
            drawFadeOverlay((1.0f - fadeFactor).coerceIn(0.0f, 1.0f))
        }
    }

    private fun drawFadeOverlay(blackAlpha: Float) {
        val prog = overlayProgram ?: return
        prog.use()
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE2)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, blackTextureId)
        GLES20.glUniform1i(prog.getUniformLocation("sTexture"), 2)

        val aPosition = prog.getAttribLocation("aPosition")
        val aTextureCoord = prog.getAttribLocation("aTextureCoord")
        val uMVPMatrix = prog.getUniformLocation("uMVPMatrix")
        val uSTMatrix = prog.getUniformLocation("uSTMatrix")
        val uAlpha = prog.getUniformLocation("uAlpha")

        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glVertexAttribPointer(aPosition, 2, GLES20.GL_FLOAT, false, 8, vertexBuffer)

        GLES20.glEnableVertexAttribArray(aTextureCoord)
        GLES20.glVertexAttribPointer(aTextureCoord, 2, GLES20.GL_FLOAT, false, 8, overlayTextureBuffer)

        Matrix.setIdentityM(mvpMatrix, 0)
        Matrix.setIdentityM(stMatrix, 0)
        GLES20.glUniformMatrix4fv(uMVPMatrix, 1, false, mvpMatrix, 0)
        GLES20.glUniformMatrix4fv(uSTMatrix, 1, false, stMatrix, 0)
        GLES20.glUniform1f(uAlpha, blackAlpha)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTextureCoord)
        GLES20.glDisable(GLES20.GL_BLEND)
    }

    private fun drawBackgroundBlur(transformMatrix: FloatArray) {
        val prog = blurProgram ?: return
        prog.use()

        val aPosition = prog.getAttribLocation("aPosition")
        val aTextureCoord = prog.getAttribLocation("aTextureCoord")
        val uMVPMatrix = prog.getUniformLocation("uMVPMatrix")
        val uSTMatrix = prog.getUniformLocation("uSTMatrix")
        val uTexelOffset = prog.getUniformLocation("uTexelOffset")

        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glVertexAttribPointer(aPosition, 2, GLES20.GL_FLOAT, false, 8, vertexBuffer)

        GLES20.glEnableVertexAttribArray(aTextureCoord)
        GLES20.glVertexAttribPointer(aTextureCoord, 2, GLES20.GL_FLOAT, false, 8, textureBuffer)

        Matrix.setIdentityM(mvpMatrix, 0)
        GLES20.glUniformMatrix4fv(uMVPMatrix, 1, false, mvpMatrix, 0)
        GLES20.glUniformMatrix4fv(uSTMatrix, 1, false, transformMatrix, 0)

        // Blur spread vector (4 pixels radius on 720p)
        GLES20.glUniform2f(uTexelOffset, 4.0f / outputWidth, 4.0f / outputHeight)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTextureId)
        GLES20.glUniform1i(prog.getUniformLocation("sTexture"), 0)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTextureCoord)
    }

    private fun drawMainVideo(
        transformMatrix: FloatArray,
        videoWidth: Int,
        videoHeight: Int,
        brightness: Float,
        contrast: Float,
        saturation: Float,
        noiseLevel: Float,
        seed: Float,
        isMirrored: Boolean
    ) {
        val prog = oesProgram ?: return
        prog.use()

        val aPosition = prog.getAttribLocation("aPosition")
        val aTextureCoord = prog.getAttribLocation("aTextureCoord")
        val uMVPMatrix = prog.getUniformLocation("uMVPMatrix")
        val uSTMatrix = prog.getUniformLocation("uSTMatrix")
        val uBrightness = prog.getUniformLocation("uBrightness")
        val uContrast = prog.getUniformLocation("uContrast")
        val uSaturation = prog.getUniformLocation("uSaturation")
        val uNoiseLevel = prog.getUniformLocation("uNoiseLevel")
        val uSeed = prog.getUniformLocation("uSeed")

        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glVertexAttribPointer(aPosition, 2, GLES20.GL_FLOAT, false, 8, vertexBuffer)

        GLES20.glEnableVertexAttribArray(aTextureCoord)
        GLES20.glVertexAttribPointer(aTextureCoord, 2, GLES20.GL_FLOAT, false, 8, textureBuffer)

        // Calculate aspect fit scale matrix
        val canvasAspect = outputWidth.toFloat() / outputHeight.toFloat()
        val videoAspect = if (videoHeight > 0) videoWidth.toFloat() / videoHeight.toFloat() else canvasAspect

        Matrix.setIdentityM(mvpMatrix, 0)
        if (videoAspect > canvasAspect) {
            // Video is wider than 9:16 -> fit width, scale down height
            val scaleY = canvasAspect / videoAspect
            Matrix.scaleM(mvpMatrix, 0, 1.0f, scaleY, 1.0f)
        } else {
            // Video is taller -> fit height, scale down width
            val scaleX = videoAspect / canvasAspect
            Matrix.scaleM(mvpMatrix, 0, scaleX, 1.0f, 1.0f)
        }

        if (isMirrored) {
            Matrix.scaleM(mvpMatrix, 0, -1.0f, 1.0f, 1.0f)
        }

        GLES20.glUniformMatrix4fv(uMVPMatrix, 1, false, mvpMatrix, 0)
        GLES20.glUniformMatrix4fv(uSTMatrix, 1, false, transformMatrix, 0)
        GLES20.glUniform1f(uBrightness, brightness)
        GLES20.glUniform1f(uContrast, contrast)
        GLES20.glUniform1f(uSaturation, saturation)
        GLES20.glUniform1f(uNoiseLevel, noiseLevel)
        GLES20.glUniform1f(uSeed, seed)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTextureId)
        GLES20.glUniform1i(prog.getUniformLocation("sTexture"), 0)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTextureCoord)
    }

    private fun drawBanner(
        bannerBitmap: Bitmap,
        xRatio: Float,
        yRatio: Float,
        widthRatio: Float,
        heightRatio: Float
    ) {
        val prog = overlayProgram ?: return
        prog.use()

        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, bannerTextureId)
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bannerBitmap, 0)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glUniform1i(prog.getUniformLocation("sTexture"), 1)

        val aPosition = prog.getAttribLocation("aPosition")
        val aTextureCoord = prog.getAttribLocation("aTextureCoord")
        val uMVPMatrix = prog.getUniformLocation("uMVPMatrix")
        val uSTMatrix = prog.getUniformLocation("uSTMatrix")
        val uAlpha = prog.getUniformLocation("uAlpha")

        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glVertexAttribPointer(aPosition, 2, GLES20.GL_FLOAT, false, 8, vertexBuffer)

        GLES20.glEnableVertexAttribArray(aTextureCoord)
        GLES20.glVertexAttribPointer(aTextureCoord, 2, GLES20.GL_FLOAT, false, 8, overlayTextureBuffer)

        val wRatio = if (widthRatio > 0.01f) widthRatio else 1.0f
        val hRatio = if (heightRatio > 0.01f) heightRatio else ((bannerBitmap.height.toFloat() / bannerBitmap.width.toFloat()) * (outputWidth.toFloat() / outputHeight.toFloat()))

        val centerXRatio = xRatio + (wRatio / 2.0f)
        val centerYRatio = yRatio + (hRatio / 2.0f)

        val glCenterX = (centerXRatio * 2.0f) - 1.0f
        val glCenterY = 1.0f - (centerYRatio * 2.0f)

        Matrix.setIdentityM(mvpMatrix, 0)
        Matrix.translateM(mvpMatrix, 0, glCenterX, glCenterY, 0.0f)
        Matrix.scaleM(mvpMatrix, 0, wRatio, hRatio, 1.0f)

        Matrix.setIdentityM(stMatrix, 0)
        GLES20.glUniformMatrix4fv(uMVPMatrix, 1, false, mvpMatrix, 0)
        GLES20.glUniformMatrix4fv(uSTMatrix, 1, false, stMatrix, 0)
        GLES20.glUniform1f(uAlpha, 1.0f)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTextureCoord)
        GLES20.glDisable(GLES20.GL_BLEND)
    }

    private fun drawVideoBannerOes(
        bannerTransformMatrix: FloatArray,
        bannerAspectRatio: Float,
        xRatio: Float,
        yRatio: Float,
        widthRatio: Float,
        heightRatio: Float
    ) {
        val prog = bannerOesProgram ?: return
        prog.use()

        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE3)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, bannerOesTextureId)
        GLES20.glUniform1i(prog.getUniformLocation("sTexture"), 3)

        val aPosition = prog.getAttribLocation("aPosition")
        val aTextureCoord = prog.getAttribLocation("aTextureCoord")
        val uMVPMatrix = prog.getUniformLocation("uMVPMatrix")
        val uSTMatrix = prog.getUniformLocation("uSTMatrix")
        val uAlpha = prog.getUniformLocation("uAlpha")

        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glVertexAttribPointer(aPosition, 2, GLES20.GL_FLOAT, false, 8, vertexBuffer)

        GLES20.glEnableVertexAttribArray(aTextureCoord)
        GLES20.glVertexAttribPointer(aTextureCoord, 2, GLES20.GL_FLOAT, false, 8, textureBuffer)

        val wRatio = if (widthRatio > 0.01f) widthRatio else 1.0f
        val hRatio = if (heightRatio > 0.01f) heightRatio else ((1.0f / bannerAspectRatio) * (outputWidth.toFloat() / outputHeight.toFloat()))

        val centerXRatio = xRatio + (wRatio / 2.0f)
        val centerYRatio = yRatio + (hRatio / 2.0f)

        val glCenterX = (centerXRatio * 2.0f) - 1.0f
        val glCenterY = 1.0f - (centerYRatio * 2.0f)

        Matrix.setIdentityM(mvpMatrix, 0)
        Matrix.translateM(mvpMatrix, 0, glCenterX, glCenterY, 0.0f)
        Matrix.scaleM(mvpMatrix, 0, wRatio, hRatio, 1.0f)

        GLES20.glUniformMatrix4fv(uMVPMatrix, 1, false, mvpMatrix, 0)
        GLES20.glUniformMatrix4fv(uSTMatrix, 1, false, bannerTransformMatrix, 0)
        GLES20.glUniform1f(uAlpha, 1.0f)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTextureCoord)
        GLES20.glDisable(GLES20.GL_BLEND)
    }

    private fun drawTextOverlays(
        subtitleText: String?,
        activeWordIndex: Int,
        subtitleYRatio: Float,
        partText: String?,
        partYRatio: Float,
        hookText: String?,
        hookYRatio: Float
    ) {
        val prog = overlayProgram ?: return
        val canvas = textCanvas ?: return
        val bitmap = textBitmap ?: return

        val isDirty = (subtitleText != lastSubtitleText ||
                activeWordIndex != lastActiveWordIndex ||
                partText != lastPartText ||
                hookText != lastHookText)

        if (isDirty) {
            lastSubtitleText = subtitleText
            lastActiveWordIndex = activeWordIndex
            lastPartText = partText
            lastHookText = hookText

            // Clear transparent canvas
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
            val centerX = outputWidth / 2f

            // A. Draw Part Number Badge ("ЧАСТЬ N")
            if (!partText.isNullOrEmpty()) {
                val partFontSize = 26f
                val pTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                    textSize = partFontSize
                    typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    textAlign = Paint.Align.CENTER
                }
                val pStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.BLACK
                    textSize = partFontSize
                    typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    textAlign = Paint.Align.CENTER
                    style = Paint.Style.STROKE
                    strokeWidth = 4f
                }
                val pWidth = pTextPaint.measureText(partText)
                val pLineY = (outputHeight * partYRatio).coerceIn(40f, outputHeight - 40f)
                val pBox = RectF(
                    centerX - pWidth / 2f - 20f,
                    pLineY - partFontSize - 10f,
                    centerX + pWidth / 2f + 20f,
                    pLineY + 10f
                )
                val pBoxPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.parseColor("#CC000000") // 80% dark background
                    style = Paint.Style.FILL
                }
                val pBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.parseColor("#80FFFFFF") // 50% white subtle border
                    style = Paint.Style.STROKE
                    strokeWidth = 2f
                }
                canvas.drawRoundRect(pBox, 12f, 12f, pBoxPaint)
                canvas.drawRoundRect(pBox, 12f, 12f, pBorderPaint)
                canvas.drawText(partText, centerX, pLineY, pStrokePaint)
                canvas.drawText(partText, centerX, pLineY, pTextPaint)
            }

            // B. Draw Text Hook / Title Banner ("Плашка с заголовком")
            if (!hookText.isNullOrEmpty()) {
                val maxAllowedWidth = outputWidth * 0.88f // 88% screen width (633px on 720p)
                var hookFontSize = 26f

                val hTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                    textSize = hookFontSize
                    typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    textAlign = Paint.Align.CENTER
                }
                val hStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.BLACK
                    textSize = hookFontSize
                    typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    textAlign = Paint.Align.CENTER
                    style = Paint.Style.STROKE
                    strokeWidth = 4.5f
                }

                var hWidth = hTextPaint.measureText(hookText)
                if (hWidth > maxAllowedWidth) {
                    val scale = maxAllowedWidth / hWidth
                    hookFontSize = (hookFontSize * scale).coerceAtLeast(18f)
                    hTextPaint.textSize = hookFontSize
                    hStrokePaint.textSize = hookFontSize
                    hStrokePaint.strokeWidth = (hookFontSize * 0.16f).coerceIn(3.0f, 4.5f)
                    hWidth = hTextPaint.measureText(hookText)
                }

                val hLineY = (outputHeight * hookYRatio).coerceIn(40f, outputHeight - 40f)
                val padX = (hookFontSize * 0.8f).coerceIn(16f, 24f)
                val padY = (hookFontSize * 0.4f).coerceIn(8f, 14f)

                val hBox = RectF(
                    centerX - hWidth / 2f - padX,
                    hLineY - hookFontSize - padY,
                    centerX + hWidth / 2f + padX,
                    hLineY + padY
                )
                val hBoxPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.parseColor("#D9000000") // 85% high-contrast dark background
                    style = Paint.Style.FILL
                }
                val hBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.parseColor("#80FFFFFF") // 50% subtle white border
                    style = Paint.Style.STROKE
                    strokeWidth = 2f
                }

                canvas.drawRoundRect(hBox, 14f, 14f, hBoxPaint)
                canvas.drawRoundRect(hBox, 14f, 14f, hBorderPaint)
                canvas.drawText(hookText, centerX, hLineY, hStrokePaint)
                canvas.drawText(hookText, centerX, hLineY, hTextPaint)
            }

            // C. Draw Subtitles (if active)
            if (!subtitleText.isNullOrEmpty()) {
                val words = subtitleText.split(" ")
                var fontSize = 28f
                textPaint.textSize = fontSize
                var wordWidths = FloatArray(words.size) { i -> textPaint.measureText(words[i]) }
                var spaceWidth = textPaint.measureText(" ")
                var totalTextWidth = wordWidths.sum() + spaceWidth * (words.size - 1)
                val maxAllowedWidth = outputWidth * 0.80f // max 80% of width (576px on 720p)

                // Auto-scale font down if phrase is long so it NEVER overflows screen
                if (totalTextWidth > maxAllowedWidth) {
                    val scale = maxAllowedWidth / totalTextWidth
                    fontSize = (fontSize * scale).coerceAtLeast(18f)
                    textPaint.textSize = fontSize
                    wordWidths = FloatArray(words.size) { i -> textPaint.measureText(words[i]) }
                    spaceWidth = textPaint.measureText(" ")
                    totalTextWidth = wordWidths.sum() + spaceWidth * (words.size - 1)
                }

                highlightPaint.textSize = fontSize
                strokePaint.textSize = fontSize
                strokePaint.strokeWidth = (fontSize * 0.15f).coerceIn(3.5f, 5.5f)

                val lineY = outputHeight * subtitleYRatio
                val padX = (fontSize * 0.6f).coerceIn(14f, 22f)
                val padY = (fontSize * 0.35f).coerceIn(8f, 14f)
                val boxRect = RectF(
                    centerX - totalTextWidth / 2f - padX,
                    lineY - fontSize - padY,
                    centerX + totalTextWidth / 2f + padX,
                    lineY + padY
                )
                val boxPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.parseColor("#B3000000") // 70% dark translucent box
                    style = Paint.Style.FILL
                }
                canvas.drawRoundRect(boxRect, 14f, 14f, boxPaint)

                // Draw each word cleanly from left to right
                var curX = centerX - totalTextWidth / 2f
                for (i in words.indices) {
                    val w = words[i]
                    val wWidth = wordWidths[i]
                    val wordCenterX = curX + wWidth / 2f

                    val paint = when {
                        i == activeWordIndex -> highlightPaint
                        i < activeWordIndex -> highlightPaint
                        else -> textPaint
                    }

                    // Outline stroke
                    canvas.drawText(w, wordCenterX, lineY, strokePaint)
                    // Fill
                    canvas.drawText(w, wordCenterX, lineY, paint)

                    curX += wWidth + spaceWidth
                }
            }

            // Upload cached canvas bitmap to OpenGL texture ONLY when text/activeWord changes
            GLES20.glActiveTexture(GLES20.GL_TEXTURE2)
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textOverlayTextureId)
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        } else {
            GLES20.glActiveTexture(GLES20.GL_TEXTURE2)
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textOverlayTextureId)
        }

        prog.use()
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

        GLES20.glUniform1i(prog.getUniformLocation("sTexture"), 2)

        val aPosition = prog.getAttribLocation("aPosition")
        val aTextureCoord = prog.getAttribLocation("aTextureCoord")
        val uMVPMatrix = prog.getUniformLocation("uMVPMatrix")
        val uSTMatrix = prog.getUniformLocation("uSTMatrix")
        val uAlpha = prog.getUniformLocation("uAlpha")

        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glVertexAttribPointer(aPosition, 2, GLES20.GL_FLOAT, false, 8, vertexBuffer)

        GLES20.glEnableVertexAttribArray(aTextureCoord)
        GLES20.glVertexAttribPointer(aTextureCoord, 2, GLES20.GL_FLOAT, false, 8, overlayTextureBuffer)

        Matrix.setIdentityM(mvpMatrix, 0)
        Matrix.setIdentityM(stMatrix, 0)
        GLES20.glUniformMatrix4fv(uMVPMatrix, 1, false, mvpMatrix, 0)
        GLES20.glUniformMatrix4fv(uSTMatrix, 1, false, stMatrix, 0)
        GLES20.glUniform1f(uAlpha, 1.0f)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTextureCoord)
        GLES20.glDisable(GLES20.GL_BLEND)
    }

    fun release() {
        oesProgram?.release()
        blurProgram?.release()
        overlayProgram?.release()
        bannerOesProgram?.release()
        val textures = intArrayOf(oesTextureId, bannerTextureId, textOverlayTextureId, bannerOesTextureId, blackTextureId)
        GLES20.glDeleteTextures(5, textures, 0)
        textBitmap?.recycle()
        textBitmap = null
    }
}

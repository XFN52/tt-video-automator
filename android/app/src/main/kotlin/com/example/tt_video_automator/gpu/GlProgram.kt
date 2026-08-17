package com.example.tt_video_automator.gpu

import android.opengl.GLES20
import android.opengl.GLES30
import android.util.Log

/**
 * Helper for compiling and linking OpenGL ES shaders into reusable GL programs.
 */
class GlProgram(vertexSource: String, fragmentSource: String) {
    var programHandle: Int = 0
        private set

    init {
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource)
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource)

        programHandle = GLES20.glCreateProgram()
        checkGlError("glCreateProgram")
        if (programHandle == 0) {
            throw RuntimeException("Could not create GL program")
        }

        GLES20.glAttachShader(programHandle, vertexShader)
        checkGlError("glAttachShader (vertex)")
        GLES20.glAttachShader(programHandle, fragmentShader)
        checkGlError("glAttachShader (fragment)")
        GLES20.glLinkProgram(programHandle)

        val linkStatus = IntArray(1)
        GLES20.glGetProgramiv(programHandle, GLES20.GL_LINK_STATUS, linkStatus, 0)
        if (linkStatus[0] != GLES20.GL_TRUE) {
            val info = GLES20.glGetProgramInfoLog(programHandle)
            GLES20.glDeleteProgram(programHandle)
            programHandle = 0
            throw RuntimeException("Could not link GL program: $info")
        }

        GLES20.glDeleteShader(vertexShader)
        GLES20.glDeleteShader(fragmentShader)
    }

    fun use() {
        GLES20.glUseProgram(programHandle)
    }

    fun getAttribLocation(name: String): Int {
        return GLES20.glGetAttribLocation(programHandle, name)
    }

    fun getUniformLocation(name: String): Int {
        return GLES20.glGetUniformLocation(programHandle, name)
    }

    fun release() {
        if (programHandle != 0) {
            GLES20.glDeleteProgram(programHandle)
            programHandle = 0
        }
    }

    companion object {
        private const val TAG = "GlProgram"

        fun loadShader(shaderType: Int, source: String): Int {
            var shader = GLES20.glCreateShader(shaderType)
            checkGlError("glCreateShader type=$shaderType")
            GLES20.glShaderSource(shader, source)
            GLES20.glCompileShader(shader)

            val compiled = IntArray(1)
            GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0)
            if (compiled[0] == 0) {
                val info = GLES20.glGetShaderInfoLog(shader)
                GLES20.glDeleteShader(shader)
                shader = 0
                throw RuntimeException("Could not compile shader $shaderType: $info\nSource:\n$source")
            }
            return shader
        }

        fun checkGlError(op: String) {
            val error = GLES20.glGetError()
            if (error != GLES20.GL_NO_ERROR) {
                val msg = "$op: glError 0x${Integer.toHexString(error)}"
                Log.e(TAG, msg)
                throw RuntimeException(msg)
            }
        }
    }
}

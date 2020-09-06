/*
 * Copyright (C) 2020. by perol_notsf, All rights reserved
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

package com.perol.pixez

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaScannerConnection
import android.net.Uri
import android.provider.DocumentsContract
import android.webkit.MimeTypeMap
import android.widget.Toast
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import com.waynejo.androidndkgif.GifEncoder
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.*
import kotlin.Comparator

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.perol.dev/save"
    private val ENCODE_CHANNEL = "samples.flutter.dev/battery"

    val OPEN_DOCUMENT_TREE_CODE = 190
    val PICK_IMAGE_FILE = 2
    var pendingResult: MethodChannel.Result? = null
    var pendingPickResult: MethodChannel.Result? = null
    private fun pickFile() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }
        startActivityForResult(intent, PICK_IMAGE_FILE)
    }

    private fun splicingUrl(parentUri: String, fileName: String) = if (parentUri.endsWith(":")) {
        parentUri + fileName
    } else {
        "$parentUri/$fileName"
    }

    private fun choiceFolder(needHint: Boolean = true) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
        }
        if (needHint)
            Toast.makeText(context, getString(R.string.choose_a_suitable_image_storage_directory), Toast.LENGTH_SHORT).show()
        startActivityForResult(intent, OPEN_DOCUMENT_TREE_CODE)
    }

    private fun needChoice() =
            contentResolver.persistedUriPermissions.takeWhile { it.isReadPermission && it.isWritePermission }
                    .isEmpty()

    private fun isFileExist(name: String): Boolean {
        val treeDocument = DocumentFile.fromTreeUri(this@MainActivity, contentResolver.persistedUriPermissions.takeWhile { it.isReadPermission && it.isWritePermission }.first().uri)!!
        if (name.contains("/")) {
            val names = name.split("/")
            if (names.size >= 2) {
                val treeId = DocumentsContract.getTreeDocumentId(treeDocument.uri)
                val folderName = names.first()
                val fName = names.last()
                val dirId = splicingUrl(treeId, folderName)
                val dirUri = DocumentsContract.buildDocumentUriUsingTree(treeDocument.uri, dirId)
                val dirDocument = DocumentFile.fromSingleUri(this, dirUri)
                return if (dirDocument == null || !dirDocument.exists()) {
                    false
                } else if (dirDocument.isFile) {
                    dirDocument.delete()
                    false
                } else {
                    val fileId = splicingUrl(dirId, fName)
                    val fileUri = DocumentsContract.buildDocumentUriUsingTree(treeDocument.uri, fileId)
                    val targetFile = DocumentFile.fromSingleUri(this, fileUri)
                    targetFile != null && targetFile.exists()
                }
            } else {
                return false
            }
        }
        val treeId = DocumentsContract.getTreeDocumentId(treeDocument.uri)
        val fileId = splicingUrl(treeId, name)
        val fileUri = DocumentsContract.buildDocumentUriUsingTree(treeDocument.uri, fileId)
        val targetFile = DocumentFile.fromSingleUri(this, fileUri)
        return targetFile != null && targetFile.exists()
    }

    private fun writeFileUri(fileName: String): Uri? {
        val mimeType = if (fileName.endsWith("jpg", ignoreCase = true) || fileName.endsWith("jpeg", ignoreCase = true)) {
            "image/jpg"
        } else {
            if (fileName.endsWith("png")) {
                "image/png"
            } else {
                "image/gif"
            }
        }
        val permissions =
                contentResolver.persistedUriPermissions.takeWhile { it.isReadPermission && it.isWritePermission }
        if (permissions.isEmpty()) {
            choiceFolder()
            return null
        }
        val parentUri =
                permissions
                        .first().uri
        val treeDocument = DocumentFile.fromTreeUri(this@MainActivity, parentUri)!!
        val treeId = DocumentsContract.getTreeDocumentId(treeDocument.uri)
        if (fileName.contains("/")) {
            val names = fileName.split("/")
            if (names.size >= 2) {
                val fName = names.last()
                val folderName = names.first()
                var folderDocument = treeDocument.findFile(folderName)
                if (folderDocument == null) {
                    folderDocument = treeDocument.createDirectory(folderName);
                }
                val file = folderDocument?.findFile(fName)
                if (file != null && file.exists()) {
                    file.delete()
                }
                return folderDocument?.createFile(mimeType, fName)?.uri
            }
        }
        val fileId = splicingUrl(treeId, fileName)
        val fileUri = DocumentsContract.buildDocumentUriUsingTree(treeDocument.uri, fileId)
        val targetFile = DocumentFile.fromSingleUri(this, fileUri)
        if (targetFile != null) {
            if (targetFile.exists()) {
                targetFile.delete()
            }
        }
        return treeDocument.createFile(mimeType, fileName)?.uri
    }

    fun wr(data: ByteArray, uri: Uri) {
        contentResolver.openOutputStream(uri, "w")?.write(data)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "save") {
                val data = call.argument<ByteArray>("data")!!
                val name = call.argument<String>("name")!!
                GlobalScope.launch(Dispatchers.Main) {
                    withContext(Dispatchers.IO) {
                        writeFileUri(name)?.let {
                            wr(data, it)
                        }
                    }
                    result.success(true)
                }
            }
            if (call.method == "scan") {
                val path = call.argument<String>("path")!!
                MediaScannerConnection.scanFile(
                        this@MainActivity,
                        arrayOf(path),
                        arrayOf(
                                MimeTypeMap.getSingleton()
                                        .getMimeTypeFromExtension(File(path).extension)
                        )
                ) { _, _ ->
                }
                result.success(true);
            }
            if (call.method == "get_path") {
                GlobalScope.launch(Dispatchers.Main) {
                    val path = withContext(Dispatchers.IO) {
                        getPath()
                    }
                    result.success(path)
                }
            }
            if (call.method == "exist") {
                val name = call.argument<String>("name")!!
                GlobalScope.launch(Dispatchers.Main) {
                    val isFileExist = withContext(Dispatchers.IO) {
                        isFileExist(name)
                    }
                    result.success(isFileExist)
                }
            }
            if (call.method == "need_choice") {
                GlobalScope.launch(Dispatchers.Main) {
                    val need = withContext(Dispatchers.IO) {
                        needChoice()
                    }
                    result.success(need)
                }
            }
            if (call.method == "choice_folder") {
                choiceFolder()
                pendingPickResult = result
            }
            if (call.method == "pick_file") {
                pendingResult = result
                pickFile()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENCODE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getBatteryLevel") {
                val name = call.argument<String>("name")!!
                val path = call.argument<String>("path")!!
                val delay = call.argument<Int>("delay")!!
                GlobalScope.launch(Dispatchers.Main) {
                    withContext(Dispatchers.IO) {
                        encodeGif(name, path, delay)
                    }
                    Toast.makeText(this@MainActivity, getString(R.string.encode_success), Toast.LENGTH_SHORT).show()
                    result.success(true)
                }
            }
        }
    }


    override fun onActivityResult(
            requestCode: Int, resultCode: Int,
            data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            PICK_IMAGE_FILE -> if (resultCode == Activity.RESULT_OK) {
                data?.data?.also { uri ->
                    Log.d("path", uri.toString())
                    val dataR = applicationContext.contentResolver.openInputStream(uri)?.readBytes()
                    pendingResult?.success(dataR)
                    pendingResult = null
                }
            } else {
                pendingResult?.success(null)
                pendingResult = null
            }
            OPEN_DOCUMENT_TREE_CODE ->
                if (resultCode == Activity.RESULT_OK) {
                    data?.data?.also { uri ->
                        Log.d("path", uri.toString())
                        if (uri.toString().toLowerCase(Locale.ROOT).contains("download")) {
                            Toast.makeText(applicationContext, getString(R.string.do_not_choice_download_folder_message), Toast.LENGTH_LONG).show()
                            choiceFolder(needHint = false)
                            return
                        }
                        val contentResolver = applicationContext.contentResolver
                        val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        contentResolver.takePersistableUriPermission(uri, takeFlags)
                        for (i in contentResolver.persistedUriPermissions) {
                            if (i.isReadPermission && i.isWritePermission && i.uri != uri) {
                                contentResolver.releasePersistableUriPermission(i.uri, takeFlags)
                            }
                        }
                        pendingPickResult?.success(true)
                        pendingPickResult = null
                    }
                } else {
                    Toast.makeText(applicationContext, getString(R.string.failure_to_obtain_authorization_may_cause_some_functions_to_fail_or_crash), Toast.LENGTH_SHORT).show()
                    pendingPickResult?.success(false)
                    pendingPickResult = null
                }
        }
    }

    private fun getPath(): String? {
        val list = contentResolver.persistedUriPermissions.takeWhile { it.isReadPermission && it.isWritePermission }
        if (list.isEmpty()) {
            return null
        }
        return list.first().uri.toString()
    }

    private fun encodeGif(name: String, path: String, delay: Int) {
        val file = File(path)
        file.let {
            val tempFile = File(applicationContext.cacheDir, "${
                if (name.contains("/")) {
                    name.split("/").last()
                } else {
                    name
                }
            }.gif")
            try {
                val fileName = "${name}.gif"
                val uri = writeFileUri(fileName)
/*                if (!tempFile.exists()) {
                    tempFile.createNewFile()
                }*/
                Log.d("tempFile path:", tempFile.path)
                val listFiles = it.listFiles()
                if (listFiles == null || listFiles.isEmpty()) {
                    throw RuntimeException("unzip files not found")
                }
                val arrayFile = mutableListOf<File>()
                for (i in listFiles) {
                    if (i.name.contains("jpg") || i.name.contains("png")) {
                        arrayFile.add(i)
                    }
                }
                arrayFile.sortWith(Comparator { o1, o2 -> o1.name.compareTo(o2.name) })
                val bitmap: Bitmap = BitmapFactory.decodeFile(arrayFile.first().path)
                val encoder = GifEncoder()
                encoder.init(bitmap.width, bitmap.height, tempFile.path, GifEncoder.EncodingType.ENCODING_TYPE_STABLE_HIGH_MEMORY)
                for (i in arrayFile.indices) {
                    if (i != 0) {
                        encoder.encodeFrame(BitmapFactory.decodeFile(arrayFile[i].path), delay)
                    } else encoder.encodeFrame(bitmap, delay)
                }
                encoder.close()
                contentResolver.openOutputStream(uri!!, "w")?.write(tempFile.inputStream().readBytes())
            } catch (e: Exception) {
                e.printStackTrace()
                tempFile.delete()
                it.deleteRecursively()
            }
        }
    }

}

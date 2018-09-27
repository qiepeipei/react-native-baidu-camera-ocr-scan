package com.baidu;

/**
 * Created by qiepeipei on 2018/8/24.
 */
import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.support.annotation.Nullable;
import android.support.v4.app.ActivityCompat;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import com.baidu.ocr.sdk.OCR;
import com.baidu.ocr.sdk.OnResultListener;
import com.baidu.ocr.sdk.exception.OCRError;
import com.baidu.ocr.sdk.model.AccessToken;
import com.baidu.ocr.sdk.model.BankCardParams;
import com.baidu.ocr.sdk.model.BankCardResult;
import com.baidu.ocr.sdk.model.GeneralBasicParams;
import com.baidu.ocr.sdk.model.GeneralResult;
import com.baidu.ocr.sdk.model.IDCardParams;
import com.baidu.ocr.sdk.model.IDCardResult;
import com.baidu.ocr.sdk.model.OcrRequestParams;
import com.baidu.ocr.sdk.model.OcrResponseResult;
import com.baidu.ocr.ui.camera.CameraActivity;
import com.baidu.ocr.ui.camera.CameraNativeHelper;
import com.baidu.ocr.ui.camera.CameraView;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.UUID;

import cn.bingoogolapple.qrcode.core.BGAQRCodeUtil;
import cn.bingoogolapple.qrcode.zxing.QRCodeEncoder;

public class BaiDuOcrModule extends ReactContextBaseJavaModule {
    static public BaiDuOcrModule myBaiDuOcrModule;
    private static final String SD_PATH = "/sdcard/dskqxt/pic/";
    private static final String IN_PATH = "/dskqxt/pic/";

    private static final int REQUEST_CODE_BANKCARD = 111; //银行卡
    private static final int REQUEST_CODE_CARD_FRONT = 151; //身份证正面
    private static final int REQUEST_CODE_CARD_BACK = 152; //身份证反面
    private static final int REQUEST_CODE_BUSINESS_LICENSE = 123; //营业执照
    private static final int REQUEST_CODE_LICENSE_PLATE = 122; //车牌号码
    private static final int REQUEST_CODE_DRIVING_LICENSE = 121; //驾驶证
    private static final int REQUEST_CODE_VEHICLE_LICENSE = 120; //行驶证
    private static final int REQUEST_CODE_RECEIPT = 124; //通用票据
    private static final int REQUEST_CODE_GENERAL_BASIC = 106; //通用文字识别

    private static final int REQUEST_CODE_CAMERA = 102;
    private static final int REQUEST_CAMERA = 103;
    private static final int REQUEST_QR_CODE = 112; //二维码扫描

    private Uri photoUri;
    private String filename;
    private Boolean isCamera = false;


    public BaiDuOcrModule(ReactApplicationContext reactContext) {
        super(reactContext);
        myBaiDuOcrModule = this;
        reactContext.addActivityEventListener(mActivityEventListener);
    }

    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {

        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            Log.d("momo","requestCode=" + String.valueOf(requestCode));
            Log.d("momo","resultCode=" + String.valueOf(resultCode));


            if(requestCode == REQUEST_CODE_BANKCARD && resultCode == Activity.RESULT_OK){
                String filePath = FileUtil.getSaveFile(getReactApplicationContext()).getAbsolutePath();
                recCreditCard(filePath); //解析银行卡

            }else if(requestCode == REQUEST_CODE_CARD_FRONT && resultCode == Activity.RESULT_OK){
                String filePath = FileUtil.getSaveFile(getReactApplicationContext()).getAbsolutePath();
                recIDCard(IDCardParams.ID_CARD_SIDE_FRONT, filePath); //解析身份证正面

            }else if(requestCode == REQUEST_CODE_CARD_BACK && resultCode == Activity.RESULT_OK) {
                String filePath = FileUtil.getSaveFile(getReactApplicationContext()).getAbsolutePath();
                recIDCard(IDCardParams.ID_CARD_SIDE_BACK, filePath); //解析身份证反面

            }else if(requestCode == REQUEST_CODE_BUSINESS_LICENSE && resultCode == Activity.RESULT_OK){
                String filePath = FileUtil.getSaveFile(getReactApplicationContext()).getAbsolutePath();
                recBusinessLicense(filePath); //解析营业执照

            }else if(requestCode == REQUEST_CODE_LICENSE_PLATE && resultCode == Activity.RESULT_OK){
                String filePath = FileUtil.getSaveFile(getReactApplicationContext()).getAbsolutePath();
                recPlateLicense(filePath); //车牌号

            }else if(requestCode == REQUEST_CODE_DRIVING_LICENSE && resultCode == Activity.RESULT_OK){
                String filePath = FileUtil.getSaveFile(getReactApplicationContext()).getAbsolutePath();
                recDrivingLicense(filePath); //驾驶证

            }else if(requestCode == REQUEST_CODE_VEHICLE_LICENSE && resultCode == Activity.RESULT_OK){
                String filePath = FileUtil.getSaveFile(getReactApplicationContext()).getAbsolutePath();
                recVehicleLicense(filePath); //行驶证

            }else if(requestCode == REQUEST_CODE_RECEIPT && resultCode == Activity.RESULT_OK){
                String filePath = FileUtil.getSaveFile(getReactApplicationContext()).getAbsolutePath();
                recReceipt(filePath); //通用票据

            }else if(requestCode == REQUEST_CODE_GENERAL_BASIC && resultCode == Activity.RESULT_OK){
                String filePath = FileUtil.getSaveFile(getReactApplicationContext()).getAbsolutePath();
                recGeneralBasic(filePath); //通用文字识别

            }else if(requestCode == REQUEST_QR_CODE && resultCode == Activity.RESULT_OK){
                String qrcode = data.getStringExtra("ScanResult");
                QRCodeReturn(qrcode);//二维码扫描返回

            }
            else if(requestCode == REQUEST_CAMERA && resultCode == Activity.RESULT_OK){

                if(isCamera.equals(true)){
                    isCamera = false;
                    String filePath = getRealPathFromURI(photoUri);
                    Log.d("momo",filePath);
                    defaultReturn(filePath,1);
                }

                if (data != null) {
                    Uri uri = data.getData();
                    String filePath = getRealPathFromURI(uri);
                    Log.d("momo",filePath);
                    defaultReturn(filePath,0);
                }
            }

        }
    };

    private String getRealPathFromURI(Uri contentURI) {
        String result;
        Cursor cursor = null;
        try {
            cursor = getReactApplicationContext().getContentResolver().query(contentURI, null, null, null, null);
        } catch (Throwable e) {
            e.printStackTrace();
        }
        if (cursor == null) {
            result = contentURI.getPath();
        } else {
            cursor.moveToFirst();
            int idx = cursor.getColumnIndex(MediaStore.Images.ImageColumns.DATA);
            result = cursor.getString(idx);
            cursor.close();
        }
        return result;
    }

    @Override
    public String getName() {
        return "RCTBaiDuOcrModule";
    }


    @ReactMethod
    public void initOcr(String ak,String sk,final Callback callback){

        OCR.getInstance(getCurrentActivity()).initAccessTokenWithAkSk(
                new OnResultListener<AccessToken>() {
                    @Override
                    public void onResult(AccessToken result) {


                        Log.d("momo", "初始化成功");
                        initLicense();
                        callback.invoke(0);
                    }

                    @Override
                    public void onError(OCRError error) {
                        error.printStackTrace();

                        System.out.println(error);
                        Log.d("momo", "初始化失败");
                        callback.invoke(-1);
                    }
                }, getReactApplicationContext(),
                ak,
                sk);

    }


    private void initLicense() {
        CameraNativeHelper.init(getCurrentActivity(), OCR.getInstance(getCurrentActivity()).getLicense(),
                new CameraNativeHelper.CameraNativeInitCallback() {
                    @Override
                    public void onError(int errorCode, Throwable e) {
                        final String msg;
                        switch (errorCode) {
                            case CameraView.NATIVE_SOLOAD_FAIL:
                                msg = "加载so失败，请确保apk中存在ui部分的so";
                                break;
                            case CameraView.NATIVE_AUTH_FAIL:
                                msg = "授权本地质量控制token获取失败";
                                break;
                            case CameraView.NATIVE_INIT_FAIL:
                                msg = "本地质量控制";
                                break;
                            default:
                                msg = String.valueOf(errorCode);
                        }

                    }
                });
    }





    @ReactMethod
    public void callOcr(String type){

        Intent intent = new Intent(getCurrentActivity(), CameraActivity.class);
        intent.putExtra(CameraActivity.KEY_OUTPUT_FILE_PATH,
                FileUtil.getSaveFile(getReactApplicationContext()).getAbsolutePath());

        if(type.equals("CAMERA")){
            intent.putExtra(CameraActivity.KEY_CONTENT_TYPE, CameraActivity.CONTENT_TYPE_BANK_CARD);
            getCurrentActivity().startActivityForResult(intent, REQUEST_CODE_BANKCARD);
        }else if(type.equals("CARD_FRONT")){
            intent.putExtra(CameraActivity.KEY_CONTENT_TYPE, CameraActivity.CONTENT_TYPE_ID_CARD_FRONT);
            getCurrentActivity().startActivityForResult(intent, REQUEST_CODE_CARD_FRONT);
        }else if(type.equals("CARD_BACK")){
            intent.putExtra(CameraActivity.KEY_CONTENT_TYPE, CameraActivity.CONTENT_TYPE_ID_CARD_BACK);
            getCurrentActivity().startActivityForResult(intent, REQUEST_CODE_CARD_BACK);
        }else if(type.equals("BUSINESS_LICENSE")){
            intent.putExtra(CameraActivity.KEY_CONTENT_TYPE, CameraActivity.CONTENT_TYPE_GENERAL);
            getCurrentActivity().startActivityForResult(intent, REQUEST_CODE_BUSINESS_LICENSE);
        }else if(type.equals("PLATE_LICENSE")){
            intent.putExtra(CameraActivity.KEY_CONTENT_TYPE, CameraActivity.CONTENT_TYPE_GENERAL);
            getCurrentActivity().startActivityForResult(intent, REQUEST_CODE_LICENSE_PLATE);
        }else if(type.equals("DRIVER_LICENSE")){
            intent.putExtra(CameraActivity.KEY_CONTENT_TYPE, CameraActivity.CONTENT_TYPE_GENERAL);
            getCurrentActivity().startActivityForResult(intent, REQUEST_CODE_DRIVING_LICENSE);
        }else if(type.equals("DRIVING_LICENSE")){
            intent.putExtra(CameraActivity.KEY_CONTENT_TYPE, CameraActivity.CONTENT_TYPE_GENERAL);
            getCurrentActivity().startActivityForResult(intent, REQUEST_CODE_VEHICLE_LICENSE);
        }else if(type.equals("GENERAL_BILL")){
            intent.putExtra(CameraActivity.KEY_CONTENT_TYPE, CameraActivity.CONTENT_TYPE_GENERAL);
            getCurrentActivity().startActivityForResult(intent, REQUEST_CODE_RECEIPT);
        }else if(type.equals("GENERAL_TEXT")){
            intent.putExtra(CameraActivity.KEY_CONTENT_TYPE, CameraActivity.CONTENT_TYPE_GENERAL);
            getCurrentActivity().startActivityForResult(intent, REQUEST_CODE_GENERAL_BASIC);

        }

    }

    @ReactMethod
    public void callQRCode(){


        if (ActivityCompat.checkSelfPermission(getReactApplicationContext(), Manifest.permission.CAMERA)
                != PackageManager.PERMISSION_GRANTED) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                ActivityCompat.requestPermissions(getCurrentActivity(),
                        new String[]{Manifest.permission.CAMERA},
                        800);
                return;
            }
        }

        Intent intent = new Intent(getCurrentActivity(), QRCodeActivity.class);

        getCurrentActivity().startActivityForResult(intent, REQUEST_QR_CODE);

    }


    @SuppressLint("StaticFieldLeak")
    @ReactMethod
    public void createQRCode(final String jsonStr){

        new AsyncTask<Void, Void, Bitmap>() {
            @Override
            protected Bitmap doInBackground(Void... params) {
                return QRCodeEncoder.syncEncodeQRCode(jsonStr, BGAQRCodeUtil.dp2px(getReactApplicationContext(), 150));
            }

            @Override
            protected void onPostExecute(Bitmap bitmap) {
               Log.d("momo","二维码生成成功");
               String pathStr = saveBitmap(getReactApplicationContext(), bitmap);
                WritableMap params = Arguments.createMap();
                params.putString("type","DEFAULT");
                params.putString("url",pathStr);
                params.putString("filePath", "file://" + pathStr);
                sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
            }
        }.execute();

    }


    /**
     * 随机生产文件名
     *
     * @return
     */
    private static String generateFileName() {
        return UUID.randomUUID().toString();
    }


    /**
     * 保存bitmap到本地
     *
     * @param context
     * @param mBitmap
     * @return
     */
    public static String saveBitmap(Context context, Bitmap mBitmap) {
        String savePath;
        File filePic;
        savePath = context.getApplicationContext().getFilesDir()
                .getAbsolutePath()
                + IN_PATH;
        try {
            filePic = new File(savePath + generateFileName() + ".jpg");
            if (!filePic.exists()) {
                filePic.getParentFile().mkdirs();
                filePic.createNewFile();
            }
            FileOutputStream fos = new FileOutputStream(filePic);
            mBitmap.compress(Bitmap.CompressFormat.JPEG, 100, fos);
            fos.flush();
            fos.close();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            return null;
        }

        return filePic.getAbsolutePath();
    }


    @ReactMethod
    public void callCamera(){

        if (ActivityCompat.checkSelfPermission(getReactApplicationContext(), Manifest.permission.CAMERA)
                != PackageManager.PERMISSION_GRANTED) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                ActivityCompat.requestPermissions(getCurrentActivity(),
                        new String[]{Manifest.permission.CAMERA},
                        800);
                return;
            }
        }

        SimpleDateFormat timeStampFormat = new SimpleDateFormat("yyyyMMddHHmmss");
        filename = timeStampFormat.format(new Date());
        ContentValues values = new ContentValues(); //使用本地相册保存拍摄照片
        values.put(MediaStore.Images.Media.TITLE, filename);
        photoUri = getReactApplicationContext().getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);

        Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        intent.putExtra(MediaStore.EXTRA_OUTPUT, photoUri);
        isCamera = true;
//        intent.setType("image/*");
        getCurrentActivity().startActivityForResult(intent, REQUEST_CAMERA);

    }

    @ReactMethod
    public void callAlbum(){

        if (ActivityCompat.checkSelfPermission(getReactApplicationContext(), Manifest.permission.READ_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                ActivityCompat.requestPermissions(getCurrentActivity(),
                        new String[]{Manifest.permission.READ_EXTERNAL_STORAGE},
                        801);
                return;
            }
        }
        Intent intent = new Intent(Intent.ACTION_PICK);
        intent.setType("image/*");
        getCurrentActivity().startActivityForResult(intent, REQUEST_CAMERA);

    }


    @ReactMethod
    public void callSelect(){



        if (ActivityCompat.checkSelfPermission(getReactApplicationContext(), Manifest.permission.READ_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                ActivityCompat.requestPermissions(getCurrentActivity(),
                        new String[]{Manifest.permission.READ_EXTERNAL_STORAGE},
                        801);
                return;
            }
        }
        Intent intent = new Intent(Intent.ACTION_PICK);
        intent.setType("image/*");
        getCurrentActivity().startActivityForResult(intent, REQUEST_CAMERA);

    }



    private void sendEvent(ReactContext reactContext,
                           String eventName,
                           @Nullable WritableMap params) {
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, params);
    }


    //默认返回
    private void QRCodeReturn(String data){

        WritableMap params = Arguments.createMap();
        params.putString("type","QRCODE");
        params.putString("data",data);
        sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

    }


    //默认返回
    private void defaultReturn(String filePath,int type){

        Bitmap image = BitmapFactory.decodeFile(filePath);//filePath

        Log.d("momo","filePath="+filePath);
        String path = compressImage(filePath,getReactApplicationContext(), type ,true);
        Log.d("momo","path="+path);

        WritableMap params = Arguments.createMap();
        params.putString("type","DEFAULT");
        params.putString("url",path);
        params.putString("filePath", "file://" + path);
        sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

    }

    private static String getFixLenthString(int strLength) {
        Random rm = new Random();
        // 获得随机数
        double pross = (1 + rm.nextDouble()) * Math.pow(10, strLength);
        // 将获得的获得随机数转化为字符串
        String fixLenthString = String.valueOf(pross);
        // 返回固定的长度的随机数
        return fixLenthString.substring(2, strLength + 1);
    }

    /**
     * 根据图片路径压缩图片并返回压缩后图片的路径
     * @param mCurrentPhotoPath
     * @param context
     * @return
     */
    public String compressImage(String mCurrentPhotoPath, Context context,int type, boolean isCompression) {

        if (mCurrentPhotoPath != null) {

            try {
                File f = new File(mCurrentPhotoPath);
                Bitmap old_bm = getSmallBitmap(mCurrentPhotoPath);
                Bitmap bm = old_bm;
                if(type ==1){
                    bm = rotateBitmap(old_bm,90);
                }

                //获取文件路径 即：/data/data/***/files目录下的文件
                String path = context.getFilesDir().getPath();
//                Log.e(TAG, "compressImage:path== "+path );
                //获取缓存路径
                File cacheDir = context.getCacheDir();
//                Log.e(TAG, "compressImage:cacheDir== "+cacheDir );
//                File newfile = new File(
//                getAlbumDir(), "small_" + f.getName());
                File newfile = new File(
                        cacheDir, "small_" + f.getName());
                FileOutputStream fos = new FileOutputStream(newfile);
                if(isCompression){
                    bm.compress(Bitmap.CompressFormat.JPEG, 60, fos);
                }else{
                    bm.compress(Bitmap.CompressFormat.JPEG, 100, fos);
                }


                return newfile.getPath();

            } catch (Exception e) {
                Log.e("momo", "error", e);
            }

        } else {
            Log.e("momo", "save: 图片路径为空");
        }
        return mCurrentPhotoPath;
    }

    /**
     * 根据路径获得突破并压缩返回bitmap用于显示
     *
     * @param filePath
     * @return
     */
    public static Bitmap getSmallBitmap(String filePath) {
        final BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(filePath, options);

        options.inSampleSize = calculateInSampleSize(options, 480, 800);

        options.inJustDecodeBounds = false;



        return BitmapFactory.decodeFile(filePath, options);
    }

    /**
     * 选择变换
     *
     * @param origin 原图
     * @param alpha  旋转角度，可正可负
     * @return 旋转后的图片
     */
    private Bitmap rotateBitmap(Bitmap origin, float alpha) {
        if (origin == null) {
            return null;
        }
        int width = origin.getWidth();
        int height = origin.getHeight();
        Matrix matrix = new Matrix();
        matrix.setRotate(alpha);
        // 围绕原地进行旋转
        Bitmap newBM = Bitmap.createBitmap(origin, 0, 0, width, height, matrix, false);
        if (newBM.equals(origin)) {
            return newBM;
        }
        origin.recycle();
        return newBM;
    }

    /**
     * 计算图片的缩放值
     *
     * @param options
     * @param reqWidth
     * @param reqHeight
     * @return
     */
    public static int calculateInSampleSize(BitmapFactory.Options options,
                                            int reqWidth, int reqHeight) {
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;

        if (height > reqHeight || width > reqWidth) {
            final int heightRatio = Math.round((float) height
                    / (float) reqHeight);
            final int widthRatio = Math.round((float) width / (float) reqWidth);
            inSampleSize = heightRatio < widthRatio ? heightRatio : widthRatio;
        }
        return inSampleSize;
    }



    /**
     * 解析通用文字
     *
     * @param filePath 图片路径
     */
    private void recGeneralBasic(final String filePath) {
        GeneralBasicParams param = new GeneralBasicParams();
        param.setDetectDirection(true);
        param.setImageFile(new File(filePath));
        OCR.getInstance(getReactApplicationContext()).recognizeGeneralBasic(param, new OnResultListener<GeneralResult>() {
            @Override
            public void onResult(GeneralResult result) {
                System.out.println(result.getJsonRes());
                if (result != null) {
                    String json_data = result.getJsonRes();
                    WritableMap params = Arguments.createMap();
                    params.putInt("error",0);
                    params.putString("type","GENERAL_BILL");
                    params.putString("data",json_data);
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

                }else{

                    WritableMap params = Arguments.createMap();
                    params.putInt("error",-2);
                    params.putString("type","GENERAL_BILL");
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                }

            }

            @Override
            public void onError(OCRError ocrError) {

                WritableMap params = Arguments.createMap();
                params.putInt("error",-1);
                params.putString("msg",ocrError.getMessage());
                params.putString("type","DRIVING_LICENSE");
                String path = compressImage(filePath,getReactApplicationContext(),0, true);
                params.putString("url",path);
                params.putString("filePath", "file://" + path);
                sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

            }
        });
    }




    /**
     * 解析通用票据
     *
     * @param filePath 图片路径
     */
    private void recReceipt(final String filePath) {
        OcrRequestParams param = new OcrRequestParams();
        param.setImageFile(new File(filePath));

        OCR.getInstance(getReactApplicationContext()).recognizeReceipt(param, new OnResultListener<OcrResponseResult>() {
            @Override
            public void onResult(OcrResponseResult result) {
                System.out.println(result.getJsonRes());
                if (result != null) {
                    String json_data = result.getJsonRes();
                    WritableMap params = Arguments.createMap();
                    params.putInt("error",0);
                    params.putString("type","GENERAL_BILL");
                    params.putString("data",json_data);
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

                }else{

                    WritableMap params = Arguments.createMap();
                    params.putInt("error",-2);
                    params.putString("type","GENERAL_BILL");
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                }

            }

            @Override
            public void onError(OCRError ocrError) {

                WritableMap params = Arguments.createMap();
                params.putInt("error",-1);
                params.putString("msg",ocrError.getMessage());
                params.putString("type","DRIVING_LICENSE");
                String path = compressImage(filePath,getReactApplicationContext(),0, true);
                params.putString("url",path);
                params.putString("filePath", "file://" + path);
                sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

            }
        });

    }



    /**
     * 解析行驶证
     *
     * @param filePath 图片路径
     */
    private void recVehicleLicense(final String filePath) {
        OcrRequestParams param = new OcrRequestParams();
        param.setImageFile(new File(filePath));

        OCR.getInstance(getReactApplicationContext()).recognizeVehicleLicense(param, new OnResultListener<OcrResponseResult>() {
            @Override
            public void onResult(OcrResponseResult result) {
                System.out.println(result.getJsonRes());
                if (result != null) {
                    String json_data = result.getJsonRes();
                    try {

                        WritableMap params = Arguments.createMap();

                        JSONObject dataObject = new JSONObject(json_data);
                        JSONObject wordObject = dataObject.getJSONObject("words_result");

                        JSONObject fdjhmObject = wordObject.getJSONObject("发动机号码");
                        String engineNum = fdjhmObject.getString("words");
                        params.putString("engineNum",engineNum);

                        JSONObject hphmObject = wordObject.getJSONObject("号牌号码");
                        String carNum = hphmObject.getString("words");
                        params.putString("carNum",carNum);

                        JSONObject syrObject = wordObject.getJSONObject("所有人");
                        String allPeople = syrObject.getString("words");
                        params.putString("allPeople",allPeople);

                        JSONObject syxzObject = wordObject.getJSONObject("使用性质");
                        String useNature = syxzObject.getString("words");
                        params.putString("useNature",useNature);

                        JSONObject zzObject = wordObject.getJSONObject("住址");
                        String address = zzObject.getString("words");
                        params.putString("address",address);

                        JSONObject zcrqObject = wordObject.getJSONObject("注册日期");
                        String regDate = zcrqObject.getString("words");
                        params.putString("regDate",regDate);

                        JSONObject clsbdhObject = wordObject.getJSONObject("车辆识别代号");
                        String carIdentificationNum = clsbdhObject.getString("words");
                        params.putString("carIdentificationNum",carIdentificationNum);

                        JSONObject ppxhObject = wordObject.getJSONObject("品牌型号");
                        String brandType = ppxhObject.getString("words");
                        params.putString("brandType",brandType);

                        JSONObject cllxObject = wordObject.getJSONObject("车辆类型");
                        String carType = cllxObject.getString("words");
                        params.putString("carType",carType);

                        JSONObject fzrqObject = wordObject.getJSONObject("发证日期");
                        String startCardDate = fzrqObject.getString("words");
                        params.putString("startCardDate",startCardDate);

                        params.putInt("error",0);
                        params.putString("type","DRIVER_LICENSE");
                        String path = compressImage(filePath,getReactApplicationContext(),0, true);
                        params.putString("url",path);
                        params.putString("filePath", "file://" + path);
                        sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

                    } catch (JSONException e) {

                        WritableMap params = Arguments.createMap();
                        params.putInt("error",-2);
                        params.putString("type","DRIVING_LICENSE");
                        String path = compressImage(filePath,getReactApplicationContext(),0, true);
                        params.putString("url",path);
                        params.putString("filePath", "file://" + path);
                        sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                    }

                }else{

                    WritableMap params = Arguments.createMap();
                    params.putInt("error",-2);
                    params.putString("type","DRIVING_LICENSE");
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                }

            }

            @Override
            public void onError(OCRError ocrError) {

                WritableMap params = Arguments.createMap();
                params.putInt("error",-1);
                params.putString("msg",ocrError.getMessage());
                params.putString("type","DRIVING_LICENSE");
                String path = compressImage(filePath,getReactApplicationContext(),0, true);
                params.putString("url",path);
                params.putString("filePath", "file://" + path);
                sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

            }
        });

    }



    /**
     * 解析驾驶证
     *
     * @param filePath 图片路径
     */
    private void recDrivingLicense(final String filePath) {
        OcrRequestParams param = new OcrRequestParams();
        param.setImageFile(new File(filePath));

        OCR.getInstance(getReactApplicationContext()).recognizeDrivingLicense(param, new OnResultListener<OcrResponseResult>() {
            @Override
            public void onResult(OcrResponseResult result) {
                System.out.println(result.getJsonRes());
                if (result != null) {
                    String json_data = result.getJsonRes();
                    try {

                        WritableMap params = Arguments.createMap();

                        JSONObject dataObject = new JSONObject(json_data);
                        JSONObject wordObject = dataObject.getJSONObject("words_result");

                        JSONObject zjcxObject = wordObject.getJSONObject("准驾车型");
                        String carType = zjcxObject.getString("words");
                        params.putString("carType",carType);

                        JSONObject zhObject = wordObject.getJSONObject("证号");
                        String cardNum = zhObject.getString("words");
                        params.putString("cardNum",cardNum);

                        JSONObject zzObject = wordObject.getJSONObject("住址");
                        String address = zzObject.getString("words");
                        params.putString("address",address);

                        JSONObject xmObject = wordObject.getJSONObject("姓名");
                        String name = xmObject.getString("words");
                        params.putString("name",name);

                        JSONObject tObject = wordObject.getJSONObject("至");
                        String to = tObject.getString("words");
                        params.putString("to",to);

                        JSONObject sexObject = wordObject.getJSONObject("性别");
                        String sex = sexObject.getString("words");
                        params.putString("sex",sex);

                        JSONObject csrqObject = wordObject.getJSONObject("出生日期");
                        String birthDate = csrqObject.getString("words");
                        params.putString("birthDate",birthDate);

                        JSONObject ccrlrqObject = wordObject.getJSONObject("初次领证日期");
                        String firstReceiveDate = ccrlrqObject.getString("words");
                        params.putString("firstReceiveDate",firstReceiveDate);

                        JSONObject gjObject = wordObject.getJSONObject("国籍");
                        String nationality = gjObject.getString("words");
                        params.putString("nationality",nationality);

                        JSONObject yxsxObject = wordObject.getJSONObject("有效期限");
                        String validDate = yxsxObject.getString("words");
                        params.putString("validDate",validDate);

                        params.putInt("error",0);
                        params.putString("type","DRIVER_LICENSE");
                        String path = compressImage(filePath,getReactApplicationContext(),0, true);
                        params.putString("url",path);
                        params.putString("filePath", "file://" + path);
                        sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

                    } catch (JSONException e) {

                        WritableMap params = Arguments.createMap();
                        params.putInt("error",-2);
                        params.putString("type","DRIVER_LICENSE");
                        String path = compressImage(filePath,getReactApplicationContext(),0, true);
                        params.putString("url",path);
                        params.putString("filePath", "file://" + path);
                        sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                    }

                }else{

                    WritableMap params = Arguments.createMap();
                    params.putInt("error",-2);
                    params.putString("type","DRIVER_LICENSE");
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                }

            }

            @Override
            public void onError(OCRError ocrError) {

                WritableMap params = Arguments.createMap();
                params.putInt("error",-1);
                params.putString("msg",ocrError.getMessage());
                params.putString("type","PLATE_LICENSE");
                String path = compressImage(filePath,getReactApplicationContext(),0, true);
                params.putString("url",path);
                params.putString("filePath", "file://" + path);
                sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

            }
        });

    }


    /**
     * 解析车牌号
     *
     * @param filePath 图片路径
     */
    private void recPlateLicense(final String filePath) {
        OcrRequestParams param = new OcrRequestParams();
        param.setImageFile(new File(filePath));

        OCR.getInstance(getReactApplicationContext()).recognizeLicensePlate(param, new OnResultListener<OcrResponseResult>() {
            @Override
            public void onResult(OcrResponseResult result) {
                if (result != null) {
                    String json_data = result.getJsonRes();
                    try {

                        WritableMap params = Arguments.createMap();

                        JSONObject dataObject = new JSONObject(json_data);
                        JSONObject wordObject = dataObject.getJSONObject("words_result");

                        String color = wordObject.getString("color");
                        String number = wordObject.getString("number");
                        params.putString("color",color);
                        params.putString("number",number);

                        params.putInt("error",0);
                        params.putString("type","PLATE_LICENSE");
                        String path = compressImage(filePath,getReactApplicationContext(),0, true);
                        params.putString("url",path);
                        params.putString("filePath", "file://" + path);
                        sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

                    } catch (JSONException e) {

                        WritableMap params = Arguments.createMap();
                        params.putInt("error",-2);
                        params.putString("type","BUSINESS_LICENSE");
                        String path = compressImage(filePath,getReactApplicationContext(),0, true);
                        params.putString("url",path);
                        params.putString("filePath", "file://" + path);
                        sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                    }

                }else{

                    WritableMap params = Arguments.createMap();
                    params.putInt("error",-2);
                    params.putString("type","PLATE_LICENSE");
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                }

            }

            @Override
            public void onError(OCRError ocrError) {

                WritableMap params = Arguments.createMap();
                params.putInt("error",-1);
                params.putString("msg",ocrError.getMessage());
                params.putString("type","PLATE_LICENSE");
                String path = compressImage(filePath,getReactApplicationContext(),0, true);
                params.putString("url",path);
                params.putString("filePath", "file://" + path);
                sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

            }
        });

    }



    /**
     * 解析营业执照
     *
     * @param filePath 图片路径
     */
    private void recBusinessLicense(final String filePath) {
        Log.d("momo","输出营业执照图片=" + filePath);
        OcrRequestParams param = new OcrRequestParams();
        param.setImageFile(new File(filePath));
        OCR.getInstance(getReactApplicationContext()).recognizeBusinessLicense(param, new OnResultListener<OcrResponseResult>() {
            @Override
            public void onResult(OcrResponseResult result) {
                System.out.println(result.getJsonRes());
                if (result != null) {
                    String json_data = result.getJsonRes();
                    try {

                        WritableMap params = Arguments.createMap();

                        JSONObject dataObject = new JSONObject(json_data);
                        JSONObject wordObject = dataObject.getJSONObject("words_result");

                        JSONObject shxydmObject = wordObject.getJSONObject("社会信用代码");
                        String socialCreditCode = shxydmObject.getString("words");
                        params.putString("socialCreditCode",socialCreditCode);

                        JSONObject frObject = wordObject.getJSONObject("法人");
                        String principal = frObject.getString("words");
                        params.putString("principal",principal);

                        JSONObject dwmcObject = wordObject.getJSONObject("单位名称");
                        String unitName = dwmcObject.getString("words");
                        params.putString("unitName",unitName);

                        JSONObject clrqObject = wordObject.getJSONObject("成立日期");
                        String buildDate = clrqObject.getString("words");
                        params.putString("buildDate",buildDate);

                        JSONObject zjbhObject = wordObject.getJSONObject("证件编号");
                        String cardNum = zjbhObject.getString("words");
                        params.putString("cardNum",cardNum);

                        JSONObject zczbObject = wordObject.getJSONObject("注册资本");
                        String regCapital = zczbObject.getString("words");
                        params.putString("regCapital",regCapital);

                        JSONObject yxqObject = wordObject.getJSONObject("有效期");
                        String effectiveDate = yxqObject.getString("words");
                        params.putString("effectiveDate",effectiveDate);

                        JSONObject dzObject = wordObject.getJSONObject("地址");
                        String address = dzObject.getString("words");
                        params.putString("address",address);

                        params.putInt("error",0);
                        params.putString("type","BUSINESS_LICENSE");
                        String path = compressImage(filePath,getReactApplicationContext(),0, true);
                        params.putString("url",path);
                        params.putString("filePath", "file://" + path);
                        sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

                    } catch (JSONException e) {

                        WritableMap params = Arguments.createMap();
                        params.putInt("error",-2);
                        params.putString("type","BUSINESS_LICENSE");
                        String path = compressImage(filePath,getReactApplicationContext(),0, true);
                        params.putString("url",path);
                        params.putString("filePath", "file://" + path);
                        sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                    }

                }else{

                    WritableMap params = Arguments.createMap();
                    params.putInt("error",-2);
                    params.putString("type","BUSINESS_LICENSE");
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                }

            }

            @Override
            public void onError(OCRError ocrError) {

                WritableMap params = Arguments.createMap();
                params.putInt("error",-1);
                params.putString("msg",ocrError.getMessage());
                params.putString("type","BUSINESS_LICENSE");
                String path = compressImage(filePath,getReactApplicationContext(),0, true);
                params.putString("url",path);
                params.putString("filePath", "file://" + path);
                sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

            }
        });

    }


    /**
     * 解析银行卡
     *
     * @param filePath 图片路径
     */
    private void recCreditCard(final String filePath) {
        // 银行卡识别参数设置
        BankCardParams param = new BankCardParams();
        param.setImageFile(new File(filePath));

        // 调用银行卡识别服务
        OCR.getInstance(getReactApplicationContext()).recognizeBankCard(param, new OnResultListener<BankCardResult>() {
            @Override
            public void onResult(BankCardResult result) {
                if (result != null) {
                    String type;
                    if (result.getBankCardType() == BankCardResult.BankCardType.Credit) {
                        type = "信用卡";
                    } else if (result.getBankCardType() == BankCardResult.BankCardType.Debit) {
                        type = "借记卡";
                    } else {
                        type = "不能识别";
                    }

                    WritableMap params = Arguments.createMap();
                    params.putInt("error",0);
                    params.putString("type","BANK_CARD");
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    params.putString("cardNum",(!TextUtils.isEmpty(result.getBankCardNumber()) ? result.getBankCardNumber() : ""));
                    params.putString("cardType",type);
                    params.putString("cardname",(!TextUtils.isEmpty(result.getBankName()) ? result.getBankName() : ""));

                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

                }else{

                    WritableMap params = Arguments.createMap();
                    params.putInt("error",-2);
                    params.putString("type","BANK_CARD");
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                }
            }

            @Override
            public void onError(OCRError error) {

                WritableMap params = Arguments.createMap();
                params.putInt("error",-1);
                params.putString("type","BANK_CARD");
                String path = compressImage(filePath,getReactApplicationContext(),0, true);
                params.putString("url",path);
                params.putString("filePath", "file://" + path);
                params.putString("msg",error.getMessage());

                sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

                Log.d("momo", "onError: " + error.getMessage());
            }

        });
    }


    /**
     * 解析身份证图片
     *
     * @param idCardSide 身份证正反recIDCard面
     * @param filePath   图片路径
     */
    private void recIDCard(final String idCardSide,final String filePath) {
        IDCardParams param = new IDCardParams();
        param.setImageFile(new File(filePath));
        // 设置身份证正反面
        param.setIdCardSide(idCardSide);
        // 设置方向检测
        param.setDetectDirection(true);
        // 设置图像参数压缩质量0-100, 越大图像质量越好但是请求时间越长。 不设置则默认值为20
        param.setImageQuality(60);
        OCR.getInstance(getReactApplicationContext()).recognizeIDCard(param, new OnResultListener<IDCardResult>() {
            @Override
            public void onResult(IDCardResult result) {
                if (result != null) {

                    WritableMap params = Arguments.createMap();
                    params.putInt("error",0);
                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);

                    if(idCardSide.equals("front")){

                        String name = "";
                        String sex = "";
                        String nation = "";
                        String birthday = "";
                        String num = "";
                        String address = "";

                        if (result.getName() != null) {
                            name = result.getName().toString();
                        }
                        if (result.getGender() != null) {
                            sex = result.getGender().toString();
                        }
                        if (result.getEthnic() != null) {
                            nation = result.getEthnic().toString();
                        }
                        if (result.getBirthday() != null) {
                            birthday = result.getBirthday().toString();
                        }
                        if (result.getIdNumber() != null) {
                            num = result.getIdNumber().toString();
                        }
                        if (result.getAddress() != null) {
                            address = result.getAddress().toString();
                        }

                        params.putString("name",name);
                        params.putString("sex",sex);
                        params.putString("nation",nation);
                        params.putString("birthday",birthday);
                        params.putString("num",num);
                        params.putString("address",address);
                        params.putString("type","CARD_FRONT");

                    }else{

                        String signDate = "";
                        String expiryDate = "";
                        String signUnit = "";

                        if (result.getSignDate() != null) {
                            signDate = result.getSignDate().toString();
                        }
                        if (result.getExpiryDate() != null) {
                            expiryDate = result.getExpiryDate().toString();
                        }
                        if (result.getIssueAuthority() != null) {
                            signUnit = result.getIssueAuthority().toString();
                        }

                        params.putString("signDate",signDate);
                        params.putString("expiryDate",expiryDate);
                        params.putString("signUnit",signUnit);
                        params.putString("type","CARD_BACK");
                    }

                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                }else{

                    WritableMap params = Arguments.createMap();
                    params.putInt("error",-2);
                    if(idCardSide.equals("front")){
                        params.putString("type","CARD_FRONT");
                    }else{
                        params.putString("type","CARD_BACK");
                    }

                    String path = compressImage(filePath,getReactApplicationContext(),0, true);
                    params.putString("url",path);
                    params.putString("filePath", "file://" + path);
                    sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);
                }
            }

            @Override
            public void onError(OCRError error) {

                Log.d("momo", "onError: " + error.getMessage());
                WritableMap params = Arguments.createMap();
                params.putInt("error",-1);

                if(idCardSide.equals("front")){
                    params.putString("type","CARD_FRONT");
                }else{
                    params.putString("type","CARD_BACK");
                }
                String path = compressImage(filePath,getReactApplicationContext(),0, true);
                params.putString("url",path);
                params.putString("filePath", "file://" + path);
                params.putString("msg",error.getMessage());

                sendEvent(getReactApplicationContext(), "BaiDuOcrEmitter", params);

            }
        });
    }




}

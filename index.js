/**
 * Created by qiepeipei on 18/8/25.
 */
'use strict';
import {
    DeviceEventEmitter,
    NativeModules,
    PermissionsAndroid,
    NativeEventEmitter,
    Platform,
    ImageEditor,
} from 'react-native'
let baiduEventEmitterIos = new NativeEventEmitter(NativeModules.BaiDuOcrModule);
class BaiDuOcr{

    constructor () {

        this.baiduCallBack = null;
        this.baiduOcrEventIos = null;
        this.baiduOcrEventAndroid = null;
    }
    requestAndroidPermissions() {

        return new Promise((resolve, reject)=>{

            if (Platform.OS === 'android') {
                var permissions = [
                    PermissionsAndroid.PERMISSIONS.CAMERA,
                    PermissionsAndroid.PERMISSIONS.READ_EXTERNAL_STORAGE,
                    PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE
                ];

                try {
                    PermissionsAndroid.requestMultiple(permissions).then(granted => {
                        resolve(true);
                    });
                } catch (err) {
                    resolve(false);
                }
            } else if (Platform.OS === 'ios') {
                resolve(true);
            }
        })

    }


    //初始化
    init(ak,sk,callBack){
        NativeModules.BaiDuOcrModule.initOcr(ak,sk,callBack);
    }

    //调用相机
    callCamera(callBack){
        this.baiduCallBack = callBack;
        NativeModules.BaiDuOcrModule.callCamera();
    }

    //调用相册
    callAlbum(callBack){
        this.baiduCallBack = callBack;
        NativeModules.BaiDuOcrModule.callAlbum();
    }

    //调用识别二维码
    callQRCode(callBack){
        this.baiduCallBack = callBack;
        NativeModules.BaiDuOcrModule.callQRCode();
    }

    //生成二维码
    createQRCode(jsonStr, callBack){
        this.baiduCallBack = callBack;
        NativeModules.BaiDuOcrModule.createQRCode(jsonStr);
    }

    //识别 type CAMERA  银行卡  CARD_FRONT 身份证正面    CARD_BACK 身份证反面 
    ocr(type,callBack){
        this.baiduCallBack = callBack;
        let myType = type || "";
        NativeModules.BaiDuOcrModule.callOcr(myType);
    }

    //监听
    addListener(){

        if(Platform.OS === "ios"){

            this.baiduOcrEventIos = baiduEventEmitterIos.addListener(
                'BaiDuOcrEmitter',
                (data) =>{
                    console.log("输出监听回调");
                    console.log(data);
                    if(this.baiduCallBack){
                        this.baiduCallBack(data);
                        this.baiduCallBack = null;
                    }
                });

        }else{
            this.baiduOcrEventAndroid = DeviceEventEmitter.addListener("BaiDuOcrEmitter",(data)=>{
                console.log("输出监听回调");
                console.log(data);
                if(this.baiduCallBack){
                    this.baiduCallBack(data);
                    this.baiduCallBack = null;
                }
            })
        }
       
    }

    //移除监听
    removeListener(){
        if(Platform.OS === "ios"){
            this.baiduOcrEventIos && this.baiduOcrEventIos.remove();
        }else{
            this.baiduOcrEventAndroid && this.baiduOcrEventAndroid.remove();
        }
    }

}
export default new BaiDuOcr();
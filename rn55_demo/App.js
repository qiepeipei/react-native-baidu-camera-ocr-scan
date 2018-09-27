/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  Platform,
  StyleSheet,
  NativeEventEmitter,
  NativeModules,
  Text,
  Button,
  View,
  Image,
} from 'react-native';

import BaiduOcrScan from './react-native-baidu-ocr-scan';

export default class App extends Component{
  constructor (props) {
   super(props);
   
   this.state = {
     uri:"file://data/user/0/com.rn55/files/dskqxt/pic/c33c0a68-02f3-49a1-93a9-1554639dd455.jpg"
   }
   
   this.subscription = null;


  }

  componentDidMount(){

    this.subscription = BaiduOcrScan.addListener();
  
  }

  componentWillUnmount(){
    this.subscription && this.subscription.remove();
  }


  render() {
    return (
      <View style={{flex:1,flexWrap:"wrap",flexDirection:"row",justifyContent: 'center',alignContent: 'center'}}>
        <View style={{margin:5}}>
          <Button title="初始化" onPress={this.initOcr.bind(this)}/>
        </View>
        <View style={{margin:5}}>
          <Button title="银行卡识别" onPress={this.callOcr.bind(this,"CAMERA")}/>
        </View>
        <View style={{margin:5}}>
          <Button title="身份证正面识别" onPress={this.callOcr.bind(this,"CARD_FRONT")}/>
        </View>
        <View style={{margin:5}}>
          <Button title="身份证反面识别" onPress={this.callOcr.bind(this,"CARD_BACK")}/>
        </View>
        <View style={{margin:5}}>
          <Button title="营业执照识别" onPress={this.callOcr.bind(this,"BUSINESS_LICENSE")}/>
        </View>
        <View style={{margin:5}}>
          <Button title="车牌识别" onPress={this.callOcr.bind(this,"PLATE_LICENSE")}/>
        </View>
        <View style={{margin:5}}>
          <Button title="驾驶证识别" onPress={this.callOcr.bind(this,"DRIVER_LICENSE")}/>
        </View>
        <View style={{margin:5}}>
          <Button title="行驶证识别" onPress={this.callOcr.bind(this,"DRIVING_LICENSE")}/>
        </View>
        <View style={{margin:5}}>
          <Button title="通用票据识别" onPress={this.callOcr.bind(this,"GENERAL_BILL")}/>
        </View>
        <View style={{margin:5}}>
          <Button title="通用文字识别" onPress={this.callOcr.bind(this,"GENERAL_TEXT")}/>
        </View>
        <View style={{margin:5}}>
          <Button title="调用相机" onPress={this.callCamera.bind(this)}/>
        </View>
        <View style={{margin:5}}>
          <Button title="调用相册" onPress={this.callAlbum.bind(this)}/>
        </View>
        <View style={{margin:5}}>
          <Button title="识别二维码" onPress={this.callQRCode.bind(this)}/>
        </View>
        <View style={{margin:5}}>
          <Button title="生成二维码" onPress={this.createQRCode.bind(this)}/>
        </View>
        <View>
          <Image style={{width:200,height:200}} resizeMode="stretch" source={{uri:this.state.uri}}/>
        </View>
      </View>
    );
  }

  initOcr(){
    BaiduOcrScan.init("","",(data)=>{
      console.log(`初始化成功 code=${data}`);
     });
  }

  createQRCode(){
    BaiduOcrScan.createQRCode("momo",(data)=>{
      console.log("生成二维码成功,输出结果");
      this.setState({
        uri:data.filePath
      });
      console.log(data);
    });
  }

  callQRCode(){
    BaiduOcrScan.callQRCode((data)=>{
      console.log("输出二维码扫描结果");
    })
  }

  callOcr(type){

    BaiduOcrScan.ocr(type,(data)=>{
      console.log("输出调用识别回调");
      console.log(data);
    });
  }
  //相机
  callCamera(){
    BaiduOcrScan.callCamera((data)=>{
      console.log("输出调用相机回调");
      console.log(data);
    });
  }
  //相册
  callAlbum(){
    BaiduOcrScan.callAlbum((data)=>{
      console.log("输出调用相册回调");
      console.log(data);
    });
  }

}

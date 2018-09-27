![Mou icon1](/assets/a1.png)
![Mou icon1](/assets/a2.png)

- [添加监听](#添加监听)
- [初始化](#初始化)
- [使用实例](#使用实例)
- [安装方法](#安装方法)
## 添加监听
必须先执行此操作
`

    import BaiduOcrScan from 'react-native-baidu-ocr-scan';
    componentDidMount(){
        this.subscription = BaiduOcrScan.addListener();
    }
    componentWillUnmount(){
        this.subscription?this.subscription.remove():null;
    }`



## 初始化
单调用相机 相册 二维码扫描 二维码生成是不需要初始化的,其他识别类功能必须先初始化

ak和sk去这里进行注册' http://ai.baidu.com/tech/ocr

    BaiduOcrScan.init("ak","sk",(data)=>{
      console.log(`初始化成功`);
    });




### 使用实例
参考[App.js](https://github.com/qiepeipei/react-native-baidu-camera-ocr-scan/blob/master/rn55_demo/App.js)


### 安装方法
## npm i react-native-baidu-camera-ocr-scan -save

## 自动配置
执行此命令
#### react-native link react-native-baidu-camera-ocr-scan

注意ios必须手动执行后续操作才可以使用
- [ios后续步骤](#ios后续步骤)

## 手动配置
#### android配置
1. 设置 `android/setting.gradle`

    ```
    ...
    
    include ':ReactNativeBaiduOcrScan'
    project(':ReactNativeBaiduOcrScan').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-baidu-camera-ocr-scan/android')
    
    ```

2. 设置 `android/app/build.gradle`

    ```
    dependencies {
        compile project(':ReactNativeBaiduOcrScan')
    }
    ```
    
3. 注册模块 (到 MainApplication.java)


    import com.baidu.BaiDuOcrPackage;
    public class MainApplication extends Application implements ReactApplication {
      ......

        @Override
    	protected List<ReactPackage> getPackages() {
      		return Arrays.<ReactPackage>asList(
          			new MainReactPackage(),
          			new new BaiDuOcrPackage()      //<--- 添加
      		);
    	} 

      ......

    }


### ios配置

1. 右键 Libraries 选择Add Files To "项目名" 进入../node_modules/react-native-baidu-camera-ocr-scan/ios/目录 选择RCTBaiDuOcrModule.xcodeproj 添加

2. 在项目Build Phases下的Link Binary With Libraries 下 添加 libRCTBaiDuOcrModule.a 库文件

### ios后续步骤
![Mou icon1](/assets/a3.png)
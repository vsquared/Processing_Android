/*
 For use on Android devices.
 Has both in/out streams.
 Rev.1
*/

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;
import java.util.Set;
import java.util.UUID;
 
// Make sure sketch permissions are set for Bluetooth
// ACCESS_COARSE_LOCATION
// BLUETOOTH
// BLUETOOTH_ADMIN

// DropDownList control => a.)displayFld b.)arrow c.)list
 
BluetoothAdapter bluetoothAdapter = null;

final int _deviceDisplayX =  30;
final int _deviceDisplayY = 60;
final int _deviceDisplayW = 450;
final int _deviceDisplayH = 60;
final int _deviceItemH = 120;
final int _deviceArrwX = _deviceDisplayX + _deviceDisplayW;
final int _deviceArrwY = _deviceDisplayY;
final int _deviceArrwSize = _deviceDisplayH;

final int _connectBtnX = 600;
final int _connectBtnY = 60;
final int _connectBtnW = 250;
final int _connectBtnH = 60;

final int _quitBtnX = 890;
final int _quitBtnY = 60;
final int _quitBtnW = 150;
final int _quitBtnH = 60;

int value = 0;

boolean deviceListDrop;
boolean connectSelected;

color BLUE = color(64,124,188);
color GREEN = color(0,126,0);

String[] deviceArray = {};
String[] deviceAddress = {};
int[] _deviceItemY;
int selectedDevice = -1;
int numDevices = 0;

Thread runThread;
byte[] readBuffer;
int buffer_index;
int counter;
boolean stop_thread, plotting = false, init = true;

 void findPairedBluetoothDevices() {
 bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
 if (bluetoothAdapter == null) {
    println("Device doesn't support Bluetooth.");
 } else {
   Set<BluetoothDevice> pairedDevices = bluetoothAdapter.getBondedDevices();
   if (pairedDevices.size() > 0) {
    // Get the name and address of each paired device.
     for (BluetoothDevice device : pairedDevices) {
      // device = append(device,device);
       String deviceName = device.getName();
       String deviceHardwareAddress = device.getAddress(); // MAC address
       deviceAddress = append(deviceAddress, device.getAddress());
       String deviceInfo = deviceName + "\n   " + deviceHardwareAddress;
       deviceArray = append(deviceArray, deviceInfo);
     }       
  }
 }
}

class DeviceDisplay {
  
 void press() {
 // device arrow touches
  if(deviceListDrop){
   deviceListDrop = false;
   } else {
   deviceListDrop = true;
  }
 }
  
 void deviceDisplayString(String str) {
  fill(255); // display field background color
  noStroke();
  rect(_deviceDisplayX,_deviceDisplayY,_deviceDisplayW,_deviceDisplayH);
  fill(0); // text color
  textSize(42);
  text(str, _deviceDisplayX + 10, _deviceDisplayY + 15, _deviceDisplayW, _deviceDisplayH);
}

 void display(){
 // display field
  if(selectedDevice == -1){
   deviceDisplayString("Select device:");   
  } else {
   deviceDisplayString(deviceArray[selectedDevice]); 
  }
 // arrow
  fill(255);
  noStroke();
  rect(_deviceArrwX, _deviceArrwY, _deviceArrwSize, _deviceArrwSize);
  fill(GREEN);
  triangle(_deviceArrwX+5,_deviceArrwY+5,_deviceArrwX+_deviceArrwSize-5,_deviceArrwY+5,_deviceArrwX+_deviceArrwSize/2,_deviceArrwY+_deviceArrwSize-5);
 }
  
}

DeviceDisplay deviceDisplay;

class DeviceList {
 
 void press(float mx, float my){
   // device list touches
   if (deviceArray.length > 0) {
   for(int j = 0; j < deviceArray.length; j++){
    if((mx >= _deviceDisplayX) && (mx <= _deviceDisplayX + _deviceDisplayW) && (my >= _deviceItemY[j] ) && (my <= _deviceItemY[j] + _deviceItemH)) {
     selectedDevice = j;
     deviceListDrop = false;
     // erases list
     fill(BLUE);
     rect(_deviceDisplayX, _deviceDisplayY, _deviceDisplayW, _deviceDisplayY + _deviceDisplayH + deviceArray.length*_deviceItemH);
    } 
   }
  }
 } 
  
 void display(){
  // deviceListItems
  if (deviceListDrop){
   if (deviceArray.length > 0) { 
   _deviceItemY = new int[deviceArray.length];
    for(int j = 0; j < deviceArray.length; j++) {
     _deviceItemY[j] = (_deviceDisplayY + _deviceDisplayH) + j*_deviceItemH;      
     fill(255);
     noStroke();
     rect(_deviceDisplayX,_deviceItemY[j],_deviceDisplayW,_deviceItemH);
     fill(0);
     textSize(42);
     text(deviceArray[j], _deviceDisplayX + 10, _deviceItemY[j] + 15, _deviceDisplayW, _deviceItemH);
    }  
   }
  }  else {
    if (deviceArray.length > 0) {    
     fill(BLUE);
     noStroke();
     rect(_deviceDisplayX, _deviceDisplayY, _deviceDisplayW, _deviceItemH * numDevices * 2);
    }
   } 
  }
 
 }

DeviceList deviceList;

 class ConnectBtn {
 // Changes color from gray to green when bluetooth is connected  
 void display(){
 if(connectSelected) {
   fill(151,186,66,255); // background color - GREEN
   noStroke();
   rect(_connectBtnX, _connectBtnY, _connectBtnW, _connectBtnH, 15);
   fill(0); // text color
   textSize(42);
   text("Disconnect", _connectBtnX + 20, _connectBtnY + 15, _connectBtnW, _connectBtnH);
  } else {
   fill(209); // background color - GRAY
   noStroke();
   rect(_connectBtnX, _connectBtnY, _connectBtnW, _connectBtnH, 15);
   fill(0); // text color
   textSize(42);
   text("Connect", _connectBtnX + 20, _connectBtnY + 15, _connectBtnW, _connectBtnH);
  }
 }
 
 void press() {  
  if(connectSelected == false){
  //  connectBluetooth();
    connectSelected = true;
    println("Connect selected.");
    connectThread = new ConnectThread(bluetoothAdapter.getRemoteDevice(deviceAddress[selectedDevice]));
    connectThread.run();
    } else {
      //disconnectBluetooth();
    connectSelected = false;
    println("Disconnect selected.");
    connectThread.cancel();
   }
 }
}

ConnectBtn connectBtn;

class QuitBtn {
  
 void display(){
   fill(209); // background color - GRAY
   noStroke();
   rect(_quitBtnX, _quitBtnY, _quitBtnW, _quitBtnH, 15);
   fill(0); // text color
   textSize(42);
   text("Quit", _quitBtnX + 25, _quitBtnY + 15, _quitBtnW, _quitBtnH);
 }
 
 void press(){
   exit();
 }
  
}
QuitBtn quitBtn;

// **** Android Code for Bluetooth Connection **** //
class ConnectedThread extends Thread {
    private final BluetoothSocket mmSocket;
    private final InputStream mmInStream;
    private final OutputStream mmOutStream;

    public ConnectedThread(BluetoothSocket socket) {
        mmSocket = socket;
        InputStream tmpIn = null;
        OutputStream tmpOut = null;
        // Get input and output streams using temp objects because
        // member streams are final
        try {
            tmpIn = socket.getInputStream();
            tmpOut = socket.getOutputStream();
        } catch (IOException e) { }

        mmInStream = tmpIn;
        mmOutStream = tmpOut;
    }

   public void run() {
   println("ConnectedThread: run() called.");
   // N.B. Set for line feed delimiter
   final byte delimiter = 10; //This is ASCII code for a lf
   stop_thread = false;
   buffer_index = 0;
   readBuffer = new byte[1024];   
    // Read from InputStream until an exception occurs
        while (true) {
          try {            
          int bytesAvailable = mmInStream.available();                        
          if (bytesAvailable > 0) {
            byte[] packetBytes = new byte[bytesAvailable];
            mmInStream.read(packetBytes);
            for (int i = 0; i < bytesAvailable; i++) {
              byte b = packetBytes[i];
              if (b == delimiter) {
                byte[] encodedBytes = new byte[buffer_index];
                System.arraycopy(readBuffer, 0, encodedBytes, 0, encodedBytes.length);
                final String data = new String(encodedBytes, "US-ASCII");
                println("data =", data);
                //plot(data);
                buffer_index = 0;
              } else {
                readBuffer[buffer_index++] = b;
              }
            }
          }  
                
            }
            catch (IOException e) {
                break;
            }
        }
    }
    /* Call this from the main activity to send data to the remote device */
    public void write(byte[] bytes) {
        try {
            mmOutStream.write(bytes);
        } catch (IOException e) { }
    }

    /* Call this from the main activity to shutdown the connection */
    public void cancel() {
        try {
            mmSocket.close();
        } catch (IOException e) { }
    }
}

ConnectedThread connectedThread;

class ConnectThread extends Thread {
 final BluetoothSocket mmSocket;
 final BluetoothDevice mmDevice;

    public ConnectThread(BluetoothDevice device) {
        // Use a temporary object that is later assigned to mmSocket because mmSocket is final.
        BluetoothSocket tmp = null;
        mmDevice = device;

        try {
            // Get a BluetoothSocket to connect with the given BluetoothDevice.
            tmp = device.createRfcommSocketToServiceRecord(UUID.fromString("00001101-0000-1000-8000-00805f9b34fb"));
        } catch (IOException e) {
            println("Socket's create() method failed");
        }
        mmSocket = tmp;
    }

void manageConnectedSocket(BluetoothSocket socket) {
    connectedThread = new ConnectedThread(socket);
    connectedThread.start();
}

    public void run() {
        // Cancel discovery because it otherwise slows down the connection.
        bluetoothAdapter.cancelDiscovery();

        try {
            // Connect to the remote device through the socket. This call blocks
            // until it succeeds or throws an exception.
            mmSocket.connect();
        } catch (IOException connectException) {
            // Unable to connect; close the socket and return.
            println("Could not connect to the client socket: ", connectException);
            try {
                mmSocket.close();
            } catch (IOException closeException) {
                println("Could not close the client socket: ", closeException);
            }
            return;
        }
     // Connection attempt succeeded; perform work associated with connection in separate thread.
        manageConnectedSocket(mmSocket);
    }
    // Closes the client socket and causes the thread to finish.
    public void cancel() {
        try {
            mmSocket.close();
        } catch (IOException e) {
            println("Could not close the client socket");
        }
    }
}

ConnectThread connectThread;

void setup() {
  fullScreen();
  background(BLUE); 
  orientation(LANDSCAPE);  
  findPairedBluetoothDevices();
  deviceDisplay = new DeviceDisplay();
  deviceList = new DeviceList();
  deviceListDrop = false;
  connectBtn = new ConnectBtn();
  connectSelected = false;
  quitBtn = new QuitBtn();
  frameRate(60);
}

void draw() {
 background(BLUE);
 // maintains display of buttons 
 deviceDisplay.display();
 if(deviceListDrop == true) {
  deviceList.display();
 }
 connectBtn.display();
 quitBtn.display();
}

// traps button touches
void mousePressed(){
 if((mouseX >= _deviceArrwX) && (mouseX <= _deviceArrwX+_deviceArrwSize) && (mouseY >= _deviceArrwY) && (mouseY <= _deviceArrwY+_deviceArrwSize)){
  deviceDisplay.press();
 }  
 if(deviceListDrop) {
  if((mouseX >= _deviceDisplayX) && (mouseX <= _deviceDisplayX + _deviceDisplayW) && (mouseY >= _deviceDisplayY + _deviceDisplayH) && (mouseY <= _deviceDisplayY + _deviceDisplayH + deviceArray.length*_deviceItemH)) {
    deviceList.press(mouseX, mouseY);
   }
 }
  
 if((mouseX >= _connectBtnX) && (mouseX <= _connectBtnX+_connectBtnW) && (mouseY >= _connectBtnY) && (mouseY <= _connectBtnY+_connectBtnH)){
  connectBtn.press();
 }

 if((mouseX >= _quitBtnX) && (mouseX <= _quitBtnX + _quitBtnW) && (mouseY >= _quitBtnY) && (mouseY <= _quitBtnY + _quitBtnH)){
  quitBtn.press();
 }

}

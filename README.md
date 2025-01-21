# XNav
A navigation app for XReal Beam

# Description:
XReam Beam is a device connected to XReal glasses to provide feature-rich AR experience, such stablized follow-up mode, 3-Dof fixed display, screen zoom/distance/size control, Corner view mode, etc. It is an Android device but has not mobile modem or GPS module, therefore, even it supports running Android apps, but while running a map/navigation map, it cannot reflect the current location on the map due to lacking of the GPS module. 

XNav app will be running on a mobile phone (Android/iOS) which shares Internaet access through access point to the Beam device as a server and on Beam as a client. The server mode app will feed the GPS location information to Beam client in 5 seconds interval. Meanwhile, the Beam client can provide map/navigation feature to the users with the GPS information received from the XNave server. 

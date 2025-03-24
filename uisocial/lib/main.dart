import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      home: Scaffold(

        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UISOCIAL',style: TextStyle(color: Colors.green,fontSize: 70,fontWeight: FontWeight.bold))
              ],
            ),
            Image.asset('assets/uisocial.png'),
            Column(
              children: [
                ElevatedButton(onPressed: (){}, child: Text('Iniciar sesion'),style: ElevatedButton.styleFrom(backgroundColor: Colors.white,padding: EdgeInsets.symmetric(horizontal: 100,vertical: 20),minimumSize: Size(double.infinity, 50),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
                SizedBox(height: 20),
                ElevatedButton(onPressed: (){}, child: Text('Registrarse'),style: ElevatedButton.styleFrom(backgroundColor: Colors.white,padding: EdgeInsets.symmetric(horizontal: 100,vertical: 20),minimumSize: Size(double.infinity, 50),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))))
              ],
            )
          ],
        ),
      ),
    );
  }
}
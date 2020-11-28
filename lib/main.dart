import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_json_widget/flutter_json_widget.dart';
import 'package:linkedin_login/linkedin_login.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter LinkedIn login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter LinkedIn login'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String redirectUrl = "https://url.com";
  String clientId = ""; /// Your linkedin client id
  String clientSecret = ""; /// Your linkedin client secret
  Dio dio = Dio();
  Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            LinkedInButtonStandardWidget(
              onTap: linkedInLogin
            ),
            result != null && result.isNotEmpty
              ? CachedNetworkImage(imageUrl: result["pic_url"])
              : Text(""),
            result != null && result.isNotEmpty
              ? JsonViewerWidget(result)
              : Text("Sign in to get result")
          ],
        ),
      ),
    );
  }

  linkedInLogin() async{
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) =>
          LinkedInUserWidget(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            redirectUrl: redirectUrl,
            clientId: clientId,
            clientSecret: clientSecret,
            onGetUserProfile: (LinkedInUserModel linkedInUser) async{
              /// This api call retrives profile picture
              Response response = await dio.get(
                  "https://api.linkedin.com/v2/me?projection=(profilePicture(displayImage~:playableStreams))",
                  options: Options(
                      responseType: ResponseType.json,
                      sendTimeout: 60000,
                      receiveTimeout: 60000,
                      headers: {
                        HttpHeaders.authorizationHeader: "Bearer ${linkedInUser.token.accessToken}"
                      }
                  )
              );
              var profilePic = response.data["profilePicture"]["displayImage~"]["elements"][0]["identifiers"][0]["identifier"];

              Map<String, dynamic> postJson = {
                "user_id": linkedInUser.userId,
                "email": linkedInUser.email.elements[0].handleDeep.emailAddress,
                "pic_url": profilePic,
                "name": linkedInUser.firstName.localized.label + ' ' + linkedInUser.lastName.localized.label,
                "token": linkedInUser.token.accessToken,
                "expires_in": linkedInUser.token.expiresIn
              };
              setState(() {
                result = postJson;
              });
              Navigator.of(context).pop();
            },
            catchError: (LinkedInErrorObject error) {
              print('Error description: ${error.description} Error code: ${error.statusCode.toString()}');
            },
          ),
        fullscreenDialog: true,
      ),
    );
  }
}

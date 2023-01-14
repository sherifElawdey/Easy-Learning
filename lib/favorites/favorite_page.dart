import 'package:easy_learning/favorites/item.dart';
import 'package:easy_learning/favorites/sqlite.dart';
import 'package:easy_learning/helper/methods.dart';
import 'package:easy_learning/video/view_page.dart';
import 'package:easy_learning/widgets/widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_youtube_downloader/flutter_youtube_downloader.dart';

List dataList = [];
class FavoritePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FavoritePage();
  }
}

class _FavoritePage extends State<FavoritePage> {
  var database = DataBaseSql();
  bool searchClicked = false,searchedText=false,loading=false;
  String? searchText;
  final TextEditingController _searchController =TextEditingController();
  @override
  void initState() {
    super.initState();
    database = DataBaseSql();
    searchClicked = false;
    searchedText=false;
    loading=false;
    searchText='';
  }

  @override
  Widget build(BuildContext context) {
    if (dataList.isEmpty) {
      setState(() {
        getItems();
      });
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: loading?CircularProgressIndicator():text('Favorites', 20, FontWeight.w600),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (searchClicked) {
                  searchClicked = false;
                } else {
                  searchClicked = true;
                }
              });
            },
            icon:searchClicked ? Icon(Icons.keyboard_arrow_up,size: 40,) :Icon(Icons.search),
          )
        ],
        bottom: searchClicked ? PreferredSize(
          preferredSize: Size.fromHeight(65),
          child: Container(
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(color: blueColor,style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextFormField(
              style: textStyle(20, FontWeight.w300),
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon:Icon(Icons.search,color: blueColor),
                suffixIcon: IconButton(
                  icon:Icon(Icons.clear),
                  onPressed: (){
                    setState(() {
                      _searchController.text='';
                      searchText='';
                    });
                  },
                ),
                hintText: 'search in favorite....',
                hintStyle: textStyle(20, FontWeight.w300),
                border: InputBorder.none
              ),
              onChanged:(value){setState(() {
                searchText=value;
              });},
            ),
          ),
        )
        :PreferredSize(child: Container(), preferredSize: Size.fromHeight(0)),
      ),
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: getItems(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else {
            if (dataList.length == 0) {
              return Center(
                  child: Icon(
                Icons.favorite_border,
                size: 350,
                color: Colors.white.withOpacity(0.3),
              ));
            } else {
              return Padding(
                padding:EdgeInsets.only(top: 30, right: 10, left: 10, bottom: 10),
                child:ListView.builder(
                  itemBuilder: (context, int index){
                    Item item = Item.fromMap(dataList[index]);
                    if(item.name.toString().toLowerCase().contains(searchText!.toLowerCase())){
                      searchedText=true;
                    }else{searchedText=false;}
                    if(searchedText){
                      return Container(
                        height: 75,
                        margin: EdgeInsets.only(left: 20, right: 20, top: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: ListTile(
                          onTap: () async{
                            setState(() {
                              loading = true;
                            });
                            final result = await FlutterYoutubeDownloader.extractYoutubeLink(item.path.toString(),18);
                            setState(() {
                              loading=false;
                            });

                            goToPage(context, ViewPage(file: item,url: result));
                          },
                          title: text('${item.name}', 17, FontWeight.w500),
                          subtitle: text('${item.time}', 13, FontWeight.w300),
                          leading: Icon(
                            Icons.play_arrow,
                            size: 60,
                            color: Colors.white,
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              deleteItem(item.id, context);
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: appColor,
                            ),
                          ),
                        ));
                    }else{
                      return Container();
                    }
                  },
                  itemCount: dataList.length,
                ),
              );
            }
          }
        }
      ),
    );
  }

  Future getItems() async {
    await database.initializedDatabase();
    dataList = await database.getAllItems(favoriteTableName);
  }
  Future deleteItem(int? id, BuildContext context) async {
    AlertDialog alertDialog = AlertDialog(
      backgroundColor: blueColor,
      title: text('Delete video', 17, FontWeight.w500),
      content: text('Do you want to delete this video', 14, FontWeight.w300),
      actions: [
        TextButton(
          onPressed: () async {
            await database.initializedDatabase();
            int result = await database.deleteItem(favoriteTableName, id!);
            if (result == 0) {
              customSnackBar(
                  msg: 'failed to delete this video. please try again  ',
                  context: context);
            } else {
              customSnackBar(msg: 'this video deleted', context: context);
            }
            backToPage(context);
            setState(() {
              getItems();
            });
          },
          child: text('Yes', 14, FontWeight.w300),
        ),
        TextButton(
          onPressed: () {
            backToPage(context);
          },
          child: text('No', 14, FontWeight.w300),
        ),
      ],
    );
    showDialog(context: context, builder: (_) => alertDialog);
  }

}

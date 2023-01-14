class Item{
  int? _id;
  String? _path;
  String? _name;
  String? _time;
  String? _date;
  Item(this._path, this._name, this._time, this._date);
  Item.map(dynamic obj){
    this._id=obj['id'];
    this._path=obj['path'];
    this._name=obj['name'];
    this._time=obj['time'];
    this._date=obj['date'];
  }

  int? get id => _id;
  String? get name => _name;
  String? get path => _path;
  String? get time => _time;
  String? get date => _date;

  Map<String,dynamic> toMap(){
    var map = Map<String,dynamic>();
    map['path']=path;
    map['name']=name;
    map['time']=time;
    map['date']=date;
    return map;
  }
  Item.fromMap(Map<String,dynamic> map){
    this._id=map['id'];
    this._path=map['path'];
    this._name=map['name'];
    this._time=map['time'];
    this._date=map['date'];
  }

}
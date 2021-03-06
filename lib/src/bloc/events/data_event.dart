import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quotesapp/src/bloc/blocs/data_bloc.dart';
import 'package:quotesapp/src/models/quote_data.dart';
import 'package:intl/intl.dart';
import 'package:quotesapp/utils/tools.dart';

abstract class DataEvent{}

class FetchData extends DataEvent{
  List<QuoteData> _quotes = [];
  FetchData(DataBloc bloc, String date) {
    List<QuoteData> hold;
    fetch(bloc, hold, date);
  }

  void fetch(DataBloc bloc, List<QuoteData> hold, String dateString) async{
    QuoteData quote;

    
    final db = Firestore.instance;
    Future <List <DocumentSnapshot>> list() async {
      var data = await db.collection('quotes').getDocuments();
      var docs = data.documents;
      return docs;
    }
    list().then((data) async {
      data.forEach((val) {
        print(val);
        quote = new QuoteData(quote: val['quote']??'Nothing', author: val['author']??'Nothing', isLiked: val['isLiked']??false);
        _quotes.add(quote);
      });
    }).then((value) {
      if(dateString == null) {
        DateTime currentTime= DateTime.now();
        Tools.prefs.setString('date', DateFormat("dd-MM-yyyy").format(currentTime).toString());
        int ran = Random().nextInt(_quotes.length);
        bloc.quoteIndex = ran;
        Tools.prefs.setInt('no', ran);
      }else {
        var inputFormat = DateFormat("dd-MM-yyyy");
        DateTime checkedDate= inputFormat.parse(dateString);
        DateTime currentTime= DateTime.now();
        if(DateTime(checkedDate.year, checkedDate.month, checkedDate.day).difference(DateTime(currentTime.year, currentTime.month, currentTime.day)).inDays == 1) {
          Tools.prefs.setString('date', DateFormat("dd-MM-yyyy").format(currentTime).toString());
          int ran = Random().nextInt(_quotes.length);
          bloc.quoteIndex = ran;
          Tools.prefs.setInt('no', ran);
        }
      }
      bloc.add(FetchDataSuccess(_quotes));
    });
    
  }
}

class FetchDataSuccess extends DataEvent {
  List<QuoteData> quotes;
  
  FetchDataSuccess(this.quotes);
}

class AddFav extends DataEvent {
  int index;
  bool fav;
  AddFav(String quote, this.fav, this.index, DataBloc bloc){
    addFav(quote, fav, bloc);
  }

  void addFav(String quote, bool fav, DataBloc bloc) async{
    
    final db = Firestore.instance;
    await db.collection('quotes').where('quote', isEqualTo: quote).getDocuments().then((value) {
      print(value);
      value.documents.forEach((element) {
        db.collection("quotes").document(element.documentID).updateData({'isLiked': !fav}).then((value){
          bloc.add(AddFavSuccess(index, fav));
        });
      });
    });
  }
}

class AddFavSuccess extends DataEvent {
  int index;
  bool fav;

  AddFavSuccess(this.index, this.fav);
}

class FetchFav extends DataEvent {
  List<QuoteData> _fquotes = [];
  FetchFav(DataBloc bloc){
    getFav(bloc);
  }

  void getFav(DataBloc bloc){
    QuoteData fquote;
    final db = Firestore.instance;
    Future <List <DocumentSnapshot>> favList() async {
      var data = await db.collection('quotes').where('isLiked', isEqualTo: true).getDocuments();
      var docs = data.documents;
      return docs;
    }
    favList().then((data) async {
      data.forEach((val) {
        print(val);
        fquote = new QuoteData(quote: val['quote']??'Nothing', author: val['author']??'Nothing', isLiked: val['isLiked']??false);
        _fquotes.add(fquote);
      });
    }).then((value) {
      bloc.add(FetchFavSuccess(_fquotes));
    });
  }
}

class FetchFavSuccess extends DataEvent {
  List<QuoteData> favquotes;
  
  FetchFavSuccess(this.favquotes);
}
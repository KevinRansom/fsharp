using System;
class P {
  static void Main(string[] a){
    for(int i=0;i<a.Length;i++){
      var s=a[i]; var hex=""; foreach(var c in s) hex+=((int)c).ToString("X4")+" ";
      Console.WriteLine("arg["+i+"] len="+s.Length+" = '"+s+"' codepoints=[ "+hex.Trim()+" ]");
    }
  }
}

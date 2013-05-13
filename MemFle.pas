Unit Memfle;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is "MemFle.pas"
 *
 * The developer was Joseph Wilcock as an exercise to develop new object
 * and conversion settings.
 * This is free to use for free and commercial projects with the only requirement
 * is to provide credit to the original author and to supply this source if requested.
 * It is my hope more people will be able to use this and learn and create newer
 * and better code for the future.
 *
 * Contributor(s): (none so far)
 *
 * ***** END LICENSE BLOCK ***** *)

{ A stream object to speed up the file reading process
  Version 2.02
  Version 2.03 14Feb00
  Version 2.04 01Mar00 - Added the "GetBoolean"
  Version 2.05 08Mar00 - Added the "GetCommaDelim"
  Version 2.06 17Mar00 - Added the "FFileName"
                                   "QuickSave"
                                   "CompleteBlind"
                                   "GrepSystem"
                       Removed the "TotalErasure"
  Version 2.07 06Jun00 - Added new "Peek" functions
                         Added new feature to "GrepSystem"
  Version 2.08 10Jul00 - Changed the Conv Rec Integers to ensure the size of
                        variables.  Added the "Conv" functions to get more
                        data types.
  Version 2.09 05Nov00 - Removed dependancy on S_HUGE for Win32
  Version 2.10 08Jan01 - Removed Win3.X compatablility
                         Added Duplication abililty
                         Added mulitple write operations.
                         --Debugging required!!! -jgw
  Version 2.11 16Jan01 - Changed the way strings are delt with, using pointers
                        and functions that are significantly quicker.
  Version 2.12 11June2001 - Added the "reset" function.
  Version 2.13 1August2001 - Added a special "GetString()" that takes into
                        consideration of quoted strings.
  Version 2.14 27October2001 - It appears that my "EndOfFile" routine
                        was off by one.  Ikanaiyo!
  Version 2.15 29October2001 - I added "PeekNextChar: AnsiChar;" in order to startup
                        on the idea of expanding the "GetCommaDelim2" function
  Version 2.16 April 28, 2003 - I figured that I had to adjust my "GetCommaDelim"
      to eliminate white space between each field.
  Version 2.17 May 28, 2003 - The GetString(Delim) shouldn't have eaten up
       multiple instances of a delimiter... I think I was trying to duplicate something...
       maybe in excel?...anyway
  Version 2.18 April 13, 2003 - Added the idea that unix-format text could happen.
}{
Type         Range                    Format
======================================================
Shortint     –128..127                  signed 8-bit
Smallint     –32768..32767          signed 16-bit
Longint         –2,147,483,648..2,147,483,647  signed 32-bit
Int64         –2^63..2^63–1          signed 64-bit
Byte         0..255                   unsigned 8-bit
Word         0..65535                 unsigned 16-bit
Longword     0..4294967295            unsigned 32-bit

Real48       2.9 x 10^–39 .. 1.7 x 10^38    11–12    6
Single       1.5 x 10^–45 .. 3.4 x 10^38    7–8    4
Double       5.0 x 10^–324 .. 1.7 x 10^308    15–16    8
Extended     3.6 x 10^–4951 .. 1.1 x 10^4932    19–20    10
Comp         –2^63+1 .. 2^63 –1                 19–20   8
Currency    –922337203685477.5808..
                922337203685477.5807            19–20    8 }

Interface

Uses Classes, SysUtils;

Type
  EMemoryFileError = Class( Exception );

  TUnicodeRec = Record
    case byte of
      1: ( Low1Char: AnsiChar );
      2: ( Low2Char: AnsiChar );
      3: ( Hi1Char: AnsiChar );
      4: ( Hi2Char: AnsiChar );
      5: ( UniChar: WideChar );
    end;

  TConvertRec = Record
    Case byte Of
      1: ( DblInt: LongInt );
      2: ( LargeWord: LongWord );
      3: ( HiWord: Word;
        LoWord: Word );
      4: ( HiInt: SmallInt;
        LoInt: SmallInt );
      5: ( Bite: Array[ 1..4 ] Of Byte );
      6: ( SBite: Array[ 1..4 ] Of ShortInt );
      7: ( Float: Single );
  End;

  TLargeConvertRec = Record
    Case byte Of
      1: ( IntSF: Int64 );
      2: ( HiWord: LongWord;
        LoWord: LongWord );
      3: ( HiInt: LongInt;
        LoInt: LongInt );
      4: ( Bite: Array[ 1..8 ] Of Byte );
      5: ( HiFloatF: Single;
        LoFloatF: Single );
      6: ( TwoFloat: Double );
      7: ( OldReal: Real48;
        Left: Array[ 1..2 ] Of byte );
  End;

  TMemoryFile = Class( TMemoryStream )
  Private
    FCurPos: LongInt;
    FPch: PAnsiChar;

    FFileName: AnsiString;

    Function GetCurrentPosition: LongInt;
    Function GetFullSize: LongInt;
  Public
    Constructor Create;
    Constructor CreateBySize( StartSize: LongInt );
    Procedure Reset;
    Procedure Duplicate( ObjRef: TMemoryFile ); Overload;
    Procedure Duplicate( ObjRef: TMemoryFile; Start, Finish: LongInt ); Overload;

      // File Operations
    Procedure LoadFromFile( FileName: AnsiString );
    Procedure LoadFromStream( ObjRef: TStream );
    Procedure QuickSave;
    Procedure CarrageReturn;
    Function EndOfLine: Boolean;
    Function EndOfFile: Boolean;

      // Special Operations
    Function SeekAndReplace( Marko, Polo: AnsiString ): LongInt;
    Procedure CompleteBlind( Interval: LongInt );
    Function GrepSystem( Flag: Byte; System: AnsiString ): TStringList;
    Procedure EncryptFile( const CryptKey: AnsiString; Shift: Boolean );
    Procedure DecryptFile( const CryptKey: AnsiString; Shift: Boolean );


      // See but not committ
    Function Peek: AnsiChar;
    Function PeekAbsNext: AnsiChar;
    Function PeekNextChar: AnsiChar;
    Function PeekSingleString( Delim: AnsiChar ): AnsiString;
    Function PeekCommaDelim: AnsiString;
    Function AdvanceWhiteSpace: AnsiString;

      // Assume "Text" file and get info
    Function GetString( Delim: AnsiChar ): AnsiString;
    Function GetStringEx( Delim: AnsiChar ): AnsiString;
    Function GetSingleString( Delim: AnsiChar ): AnsiString;
    Function GetBoolean( Delim: AnsiChar ): Boolean;
    Function GetCommaDelim: AnsiString;
    Function GetCommaDelim2: AnsiString;
    Function GetLine: AnsiString;
    Function GetToEndOfLine: AnsiString;
    Function GetByte: Byte;
    Function GetWord: Word;
    Function GetChar: AnsiChar;
    Function GetReal( Delim: AnsiChar ): Extended;
    Function GetInteger( Delim: AnsiChar ): LongInt;
    Function GetBuffer( Len: Byte ): AnsiString;

    // new unicode versions
    Function GetWChar: WideChar;
    Function GetWLine: WideString;

      // Assume "Binary" and get Info
    Function GetConvInt: SmallInt;
    Function GetConvLong: LongInt;
    Function GetConvInt64: Int64;
    Function GetConvWord: Word;
    Function GetConvLongWord: LongWord;
    Function GetConvReal48: Real48;
    Function GetConvSingle: Single;
    Function GetConvDouble: Double;

      // Write Information
    Function SetBuffer( Const Value: AnsiString ): Boolean;
    Function SetChar( Const Value: AnsiChar ): Boolean;
    Function SetInteger( Const Value: LongInt ): Boolean;
    Function SetFloat( Const Value: Extended; Const Prec: LongInt ): Boolean;
    Function SetConvInt( Const Value: SmallInt ): Boolean;
    Function SetConvLong( Const Value: LongInt ): Boolean;
    Function SetConvInt64( Const Value: Int64 ): Boolean;
    Function SetConvWord( Const Value: Word ): Boolean;
    Function SetConvLongWord( Const Value: LongWord ): Boolean;
    Function WriteByStream( ObjRef: TStream ): Boolean;
    Function WriteCarrageReturn: Boolean;
    Function WriteNull: Boolean;

  Public
    Function ResetPosition( NewPosition: LongInt; NewLocation: PAnsiChar ): Boolean;
    Property FullSize: LongInt Read GetFullSize;
    Property CurrentPosition: LongInt Read GetCurrentPosition;
    Property CurrentPointer: PAnsiChar Read FPch;
  End;

Implementation

Procedure HugeInc( Var HugePtr: Pointer; Amount: LongInt );
Begin
  HugePtr := PAnsiChar( HugePtr ) + Amount;
End;

Procedure HugeDec( Var HugePtr: Pointer; Amount: LongInt );
Begin
  HugePtr := PAnsiChar( HugePtr ) - Amount;
End;

Function HugeOffset( HugePtr: Pointer; Amount: LongInt ): Pointer;
Begin
  Result := PAnsiChar( HugePtr ) + Amount;
End;

Procedure HMemCpy( DstPtr, SrcPtr: Pointer; Amount: LongInt );
Begin
  Move( SrcPtr^, DstPtr^, Amount );
End;

Function TMemoryFile.GetCurrentPosition: LongInt;
Begin
  Result := FCurPos;
End;

Function TMemoryFile.GetFullSize: LongInt;
Begin
  Result := Size;
End;

Constructor TMemoryFile.Create;
Begin
  Inherited Create;
  Reset;
End;

Constructor TMemoryFile.CreateBySize( StartSize: LongInt );
Begin
  Inherited Create;
  FCurPos := 0;
  Inherited SetSize( StartSize );
End;

Procedure TMemoryFile.Reset;
Begin
  FCurPos := 0;
  FPch := Memory;
End;

function TMemoryFile.ResetPosition(NewPosition: Integer;
  NewLocation: PAnsiChar): Boolean;
begin
  Result := True;
  try  // The idea here is a "Peek" function.  Store the current positions
       //    of the pointer and value, then reset them right back.  That way
       //    we have a full back-forth stream.  I decided to do this rather
       //    than storing it internally so to keep the overhead down.
       //   ========================== New to 2.12
    if ( NewPosition >= 0 ) and ( NewPosition <= Self.Size ) and ( FPch <> nil ) then
      begin
        FCurPos := NewPosition;
        FPch := NewLocation;
      end;
  except
    Result := False;
  end;
end;

Procedure TMemoryFile.Duplicate( ObjRef: TMemoryFile );
Begin
  HMemCpy( Memory, ObjRef.Memory, ObjRef.Size );
End;

Procedure TMemoryFile.Duplicate( ObjRef: TMemoryFile; Start, Finish: LongInt );
Var
  ptr: PAnsiChar;
Begin
  ptr := ObjRef.Memory;
  Inc( ptr, Start );
  HMemCpy( Memory, ptr, Finish - Start + 1 );
End;

Procedure TMemoryFile.LoadFromFile( FileName: AnsiString );
Var
  FilStr: TFileStream;
Begin
  FilStr := TFileStream.Create( FileName, fmOpenRead );
  Try
    FFileName := FileName;
    LoadFromStream( FilStr );
  Finally
    FilStr.Free;
  End;
End;

Procedure TMemoryFile.LoadFromStream( ObjRef: TStream );
Begin
  Inherited LoadFromStream( ObjRef );
  Reset;
End;

Procedure TMemoryFile.QuickSave;
Var
  FilStr: TFileStream;
Begin
  If FileExists( FFileName ) Then
    Begin
      FilStr := TFileStream.Create( FFileName, fmOpenWrite );
      Try
        SaveToStream( FilStr );
      Finally
        FilStr.Free;
      End;
    End;
End;

Function TMemoryFile.Peek: AnsiChar;
Var
  TmpChar: AnsiChar;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  TmpChar := AnsiChar( FPch^ );
  Result := TmpChar;
End;

{"Peek" functions are usefull in trying to search through a file
without moving the virtual file pointer. }

Function TMemoryFile.PeekSingleString( Delim: AnsiChar ): AnsiString;
{  We are inc'ing to one ONE delimiter, as in CSV Files}
Var
  OrgLoc: Pointer;
  OrgCurPos: LongInt;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  Result := '';
  OrgLoc := FPch;
  OrgCurPos := FCurPos;
  Try
    Result := Self.GetSingleString( Delim );
  Finally
    FPch := OrgLoc;
    FCurPos := OrgCurPos;
  End;
End;

Function TMemoryFile.PeekCommaDelim: AnsiString;
Var
  OrgLoc: Pointer;
  OrgCurPos: LongInt;
Begin
  OrgLoc := FPch;
  OrgCurPos := FCurPos;
  Try
    Result := Self.GetCommaDelim;
  Finally
    FPch := OrgLoc;
    FCurPos := OrgCurPos;
  End;
End;

Function TMemoryFile.EndOfLine: Boolean;
Var
  TmpChar: AnsiChar;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  TmpChar := AnsiChar( FPch^ );
  Result := ( TmpChar = #13 ) or ( TmpChar = #10 );
End;

Function TMemoryFile.EndOfFile: Boolean;
Begin
  Result := FCurPos >= Size;// - 1;
End;

Procedure TMemoryFile.CarrageReturn;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );

  If FCurPos < Size + 1 Then
    Begin
      Inc( FPch );
      Inc( FCurPos );
    End;

  If ( FCurPos < Size + 1 ) Then
    Begin
      if PeekNextChar = #10 then
        begin
          Inc( FPch );
          Inc( FCurPos );
        end;
    End;
End;

Function TMemoryFile.GetSingleString( Delim: AnsiChar ): AnsiString;
{  We are inc'ing to one ONE delimiter, as in CSV Files}
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  Result := '';
  If ( AnsiChar( FPch^ ) <> Delim ) Then
    Begin
      While Not( EndOfLine ) And Not( EndOfFile ) And ( AnsiChar( FPch^ ) <> Delim ) Do
        Begin
          Result := Result + AnsiChar( FPch^ );
          Inc( FPch );
          Inc( FCurPos );
        End;
    End;
  If AnsiChar( FPch^ ) = Delim Then
    Begin
      Inc( FPch );
      Inc( FCurPos );
    End;
End;

Function TMemoryFile.GetString( Delim: AnsiChar ): AnsiString;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  Result := '';
  If ( AnsiChar( FPch^ ) <> Delim ) Then
    Begin
      While Not ( EndOfLine ) And Not ( EndOfFile ) And ( AnsiChar( FPch^ ) <> Delim ) Do
        Begin
          Result := Result + AnsiChar( FPch^ );
          Inc( FPch );
          Inc( FCurPos );
        End;
    End;
  If AnsiChar( FPch^ ) = Delim Then
    Begin
      Inc( FPch );
      Inc( FCurPos );
    End;
End;

Function TMemoryFile.GetBoolean( Delim: AnsiChar ): Boolean;
Var
  tmpStr: AnsiString;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  tmpStr := GetSingleString( Delim );
  If Pos( 'TRUE', tmpStr ) <> 0 Then
    Result := True
  Else
    Result := False;
End;

Function TMemoryFile.GetCommaDelim: AnsiString;
Begin
  If Peek = '"' Then
    Begin
      GetChar;
      Result := GetSingleString( '"' );
      GetSingleString( ',' );
    End
  Else
    Result := GetSingleString( ',' );
  /// We need to trim off white space--the standard CSV format
  ///   allows for spaces between comma's and the next entry.
  /// NOTE:  This is white spaces *between* each field of the
  ///   file, and not the actual information of the file.  If
  ///   a text entry needs leading white space, it needs a
  ///   double quote marker.
  AdvanceWhiteSpace;
End;

Function TMemoryFile.GetLine: AnsiString;
Begin
  Result := Self.GetToEndOfLine;
  If ( EndOfLine ) And Not ( EndOfFile ) Then
    CarrageReturn;
End;

Function TMemoryFile.GetToEndOfLine: AnsiString;
Var
  P: PAnsiChar;
Begin                                   // Ansi Strings are big... should work
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  p := FPch;
  While Not ( EndOfLine ) And Not ( EndOfFile ) Do
    Begin
      Inc( FPch );
      Inc( FCurPos );
    End;
  System.SetString( Result, P, FPch - P );
End;

Function TMemoryFile.GetReal( Delim: AnsiChar ): Extended;
Var
  TmpStr: AnsiString;
  Code: LongInt;
  p: PAnsiChar;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  P := FPch;
  While Not ( EndOfLine ) And Not ( EndOfFile ) And ( AnsiChar( FPch^ ) <> Delim ) Do
    Begin
      Inc( FPch );
      Inc( FCurPos );
    End;
  System.SetString( tmpstr, P, FPch - P );

  If Peek = Delim Then
    Begin
      Inc( FPch );
      Inc( FCurPos );
    End;
  Val( TmpStr, Result, Code );
  If Code <> 0 Then
    Raise EMemoryFileError.Create( 'Invalid (Real) Numeric type' );
End;

Function TMemoryFile.GetInteger( Delim: AnsiChar ): LongInt;
Var
  TmpStr: AnsiString;
  Code: LongInt;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  TmpStr := '';
  While Not ( EndOfLine ) And Not ( EndOfFile ) And ( AnsiChar( FPch^ ) <> Delim ) Do
    Begin
      TmpStr := TmpStr + AnsiChar( FPch^ );
      Inc( FPch );
      Inc( FCurPos );
    End;
  If Peek = Delim Then
    Begin
      Inc( FPch );
      Inc( FCurPos );
    End;
  Val( TmpStr, Result, Code );
  If Code <> 0 Then
    Raise EMemoryFileError.Create( 'Invalid (LongInt) Numeric type' );
End;

Function TMemoryFile.GetBuffer( Len: Byte ): AnsiString;
Var
  TmpStr: AnsiString;
  X: LongInt;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  TmpStr := '';
  X := 0;
  While Not ( EndOfLine ) And Not ( EndOfFile ) And ( X < Len ) Do
    Begin
      TmpStr := TmpStr + AnsiChar( FPch^ );
      Inc( FPch );
      Inc( FCurPos );
      Inc( X );
    End;
  Result := TmpStr;
End;

Function TMemoryFile.SeekAndReplace( Marko, Polo: AnsiString ): LongInt;

  Function SmothStr( Value: AnsiString; Len: Byte ): AnsiString;
  Var
    st, X: Byte;
  Begin
    St := Length( Value );
    Result := Value;
    If Len > St Then
      Begin
        For X := St + 1 To Len Do
          Result := Result + ' ';
      End;
  End;

Var
  X: LongInt;
Begin
  Result := -1;
  If Length( Marko ) < Length( Polo ) Then
    Marko := SmothStr( Marko, Length( Polo ) );
  If Length( Polo ) < Length( Marko ) Then
    Polo := SmothStr( Polo, Length( Marko ) );
  Reset;
  While Not ( EndOfFile ) Do
    Begin
      While Not ( EndOfFile ) And ( AnsiChar( FPch^ ) <> Marko[ 1 ] ) Do
        Begin
          Inc( FPch );
          Inc( FCurPos );
        End;
      If AnsiChar( FPch^ ) = Marko[ 1 ] Then
        Begin
          X := 2;
          While Not ( EndOfFile ) And ( Marko[ X ] = AnsiChar( FPch^ ) )
            And ( X <= Length( Marko ) ) Do
            Begin
              Inc( FPch );
              Inc( FCurPos );
              Inc( X );
            End;
        End;
    End;
End;

Procedure TMemoryFile.CompleteBlind( Interval: LongInt );
Var
  X: LongInt;
Begin
  If ( FPch = Nil ) And ( FFileName <> '' ) Then
    Raise EMemoryFileError.Create( 'No file to access' );
  For X := 1 To Interval Do
    Begin
      Randomize;
      Self.Reset;
      While Not ( Self.EndOfFile ) Do
        Begin
          AnsiChar( FPch^ ) := AnsiChar( Random( 255 ) );
          If Not ( Self.EndOfFile ) Then
            Begin
              Inc( FPch );
              Inc( FCurPos );
            End;
        End;
      Self.QuickSave;
      Self.Reset;
      While Not ( Self.EndOfFile ) Do
        Begin
          AnsiChar( FPch^ ) := #0;
          If Not ( Self.EndOfFile ) Then
            Begin
              Inc( FPch );
              Inc( FCurPos );
            End;
        End;
      Self.QuickSave;
    End;
End;

Function TMemoryFile.SetConvInt( Const Value: SmallInt ): Boolean;
Var
  ConvRec: TConvertRec;
  x: byte;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If ( Size - FCurPos ) > SizeOF( SmallInt ) Then
    Begin
      ConvRec.HiInt := Value;
      For X := 1 To 2 Do
        Begin
          Byte( FPch^ ) := ConvRec.Bite[ x ];
          Inc( FPch );
          Inc( FCurPos );
        End;
    End;
  Result := EndOfFile;
End;

Function TMemoryFile.SetConvLong( Const Value: LongInt ): Boolean;
Var
  ConvRec: TConvertRec;
  x: Byte;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If ( Size - FCurPos ) > SizeOF( LongInt ) Then
    Begin
      ConvRec.DblInt := Value;
      For X := 1 To 4 Do
        Begin
          Byte( FPch^ ) := ConvRec.Bite[ x ];
          Inc( FPch );
          Inc( FCurPos );
        End;
    End;
  Result := EndOfFile;
End;

Function TMemoryFile.SetConvInt64( Const Value: Int64 ): Boolean;
Var
  ConvRec: TLargeConvertRec;
  x: Byte;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If ( Size - FCurPos ) > SizeOF( Int64 ) Then
    Begin
      ConvRec.IntSF := Value;
      For X := 1 To 8 Do
        Begin
          Byte( FPch^ ) := ConvRec.Bite[ x ];
          Inc( FPch );
          Inc( FCurPos );
        End;
    End;
  Result := EndOfFile;
End;

Function TMemoryFile.SetConvWord( Const Value: Word ): Boolean;
Var
  ConvRec: TConvertRec;
  x: byte;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If ( Size - FCurPos ) > SizeOF( Word ) Then
    Begin
      ConvRec.HiWord := Value;
      For X := 1 To 2 Do
        Begin
          Byte( FPch^ ) := ConvRec.Bite[ x ];
          Inc( FPch );
          Inc( FCurPos );
        End;
    End;
  Result := EndOfFile;
End;

Function TMemoryFile.SetConvLongWord( Const Value: LongWord ): Boolean;
Var
  ConvRec: TConvertRec;
  x: Byte;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If ( Size - FCurPos ) > SizeOF( LongWord ) Then
    Begin
      ConvRec.LargeWord := Value;
      For X := 1 To 4 Do
        Begin
          Byte( FPch^ ) := ConvRec.Bite[ x ];
          Inc( FPch );
          Inc( FCurPos );
        End;
    End;
  Result := EndOfFile;
End;

Function TMemoryFile.SetBuffer( Const Value: AnsiString ): Boolean;
Var
  X: LongInt;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  For X := 0 To Length( Value ) Do
    Begin
      If ( EndOfFile ) Then
        Break;
      Byte( FPch^ ) := Byte( Value[ X ] );
      Inc( FPch );
      Inc( FCurPos );
    End;
  Result := EndOfFile;
End;

Function TMemoryFile.SetChar( Const Value: AnsiChar ): Boolean;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If Not ( EndOfFile ) Then
    Begin
      Byte( FPch^ ) := Byte( Value );
      Inc( FPch );
      Inc( FCurPos );
    End;
  Result := EndOfFile;
End;

Function TMemoryFile.SetInteger( Const Value: LongInt ): Boolean;
Var
  tmpStr: AnsiString;
  x: LongInt;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  Result := True;
  try
    tmpStr := IntToStr( Value );
    If ( Size - FCurPos ) > Length( tmpStr ) Then
      Begin
        For X := 1 To Length( tmpStr ) Do
          Begin
            Byte( FPch^ ) := Byte( tmpStr[ X ] );
            Inc( FPch );
            Inc( FCurPos );
          End;
      End;
  except
    Result := False;
  end;
End;

Function TMemoryFile.SetFloat( Const Value: Extended; Const Prec: LongInt ): Boolean;
Var
  tmpStr: AnsiString;
  X: LongInt;
Begin
  Result := True;
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  try
    Str( Value: 1: Prec, tmpStr );
    If ( Size - FCurPos ) > Length( tmpStr ) Then
      Begin
        For X := 1 To Length( tmpStr ) Do
          Begin
            Byte( FPch^ ) := Byte( tmpStr[ X ] );
            Inc( FPch );
            Inc( FCurPos );
          End;
      End;
  except
    Result := False;
  end;
End;

Function TMemoryFile.WriteByStream( ObjRef: TStream ): Boolean;
Begin
///// Obviously, I haven't gotten around to this function yet.... -jgw
  Result := False;
End;

Function TMemoryFile.WriteCarrageReturn: Boolean;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If Not ( EndOfFile ) Then
    Begin
      Byte( FPch^ ) := 13;
      Inc( FPch );
      Inc( FCurPos );
    End;
  If Not ( EndOfFile ) Then
    Begin
      Byte( FPch^ ) := 10;
      Inc( FPch );
      Inc( FCurPos );
    End;
  Result := EndOfFile;
End;

Function TMemoryFile.WriteNull: Boolean;
Begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If Not ( EndOfFile ) Then
    Begin
      Byte( FPch^ ) := 0;
      Inc( FPch );
      Inc( FCurPos );
    End;
  Result := EndOfFile;
End;

Function TMemoryFile.GetByte: Byte;
Begin
  Result := 0;
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If Not ( EndOfFile ) Then
    Begin
      Result := Byte( FPch^ );
      Inc( FPch );
      Inc( FCurPos );
    End;
End;

Function TMemoryFile.GetWord: Word;
Begin
  Result := GetByte;
  Result := Result Shl 8;
  Result := Result + GetByte;
End;

Function TMemoryFile.GetChar: AnsiChar;
Begin
  Result := #0;
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If Not ( EndOfFile ) Then
    Begin
      Result := AnsiChar( FPch^ );
      Inc( FPch );
      Inc( FCurPos );
    End;
End;

Function TMemoryFile.GetConvLong: LongInt;
Var
  Conv: TConvertRec;
  X: Byte;
Begin
  For x := 1 To 4 Do
    Conv.Bite[ X ] := GetByte;
  Result := Conv.DblInt;
End;

Function TMemoryFile.GetConvWord: Word;
Var
  Conv: TConvertRec;
  X: Byte;
Begin
  For x := 1 To 2 Do
    Conv.Bite[ X ] := GetByte;
  Result := Conv.HiWord;
End;

Function TMemoryFile.GetConvLongWord: LongWord;
Var
  Conv: TConvertRec;
  X: Byte;
Begin
  For x := 1 To 2 Do
    Conv.Bite[ X ] := GetByte;
  Result := Conv.LargeWord;
End;

Function TMemoryFile.GetConvInt64: Int64;
Var
  Conv: TLargeConvertRec;
  X: Byte;
Begin
  For x := 1 To 8 Do
    Conv.Bite[ X ] := GetByte;
  Result := Conv.IntSF;
End;

Function TMemoryFile.GetConvReal48: Real48;
Var
  Conv: TLargeConvertRec;
  X: Byte;
Begin
  For x := 1 To 6 Do
    Conv.Bite[ X ] := GetByte;
  Conv.Bite[ 7 ] := 0;
  Conv.Bite[ 8 ] := 0;

  Result := Conv.OldReal;
End;

Function TMemoryFile.GetConvInt: SmallInt;
Var
  Conv: TConvertRec;
  X: Byte;
Begin
  For x := 1 To 2 Do
    Conv.Bite[ X ] := GetByte;
  Result := Conv.HiInt;
End;

Function TMemoryFile.GetConvSingle: Single;
Var
  Conv: TConvertRec;
  X: Byte;
Begin
  For x := 1 To 4 Do
    Conv.Bite[ X ] := GetByte;
  Result := Conv.Float;
End;

Function TMemoryFile.GetConvDouble: Double;
Var
  Conv: TLargeConvertRec;
  X: Byte;
Begin
  For x := 1 To 8 Do
    Conv.Bite[ X ] := GetByte;
  Result := Conv.TwoFloat;
End;

{This function creates a new object in the "Result" of the function.  Therefore
responsibilty of disposing this memory is up to the calling block.}

Function TMemoryFile.GrepSystem( Flag: Byte; System: AnsiString ): TStringList;
{
 $01 - Case Sensitive      $F1 -
 $02 - No Indexed Result   $F2 -
 $04 - Indexes Only        $F4 -
 $08 - NON-Text Format     $F8 -
}
Var
  tmpStr: AnsiString;
  X: LongInt;
  Y: SmallInt;
Begin
  Result := TStringList.Create;
  Try
    X := 1;
    tmpStr := '';
    If Flag And $01 = $01 Then
      System := UpperCase( System );
    If Flag And $08 <> $08 Then
      Begin                             {Standard ASCII Text format assumed; ie.  80 columns w/cflf afterward}
        While Not ( Self.EndOfFile ) Do
          Begin
            tmpStr := Self.GetLine;
            If Flag And $01 = $01 Then
              tmpStr := UpperCase( tmpStr );
            If Pos( System, tmpStr ) <> 0 Then
              Begin
                If Flag And $02 = $02 Then
                  Result.Add( tmpStr )
                Else If Flag And $04 = $04 Then
                  Result.Add( IntToStr( X ) )
                Else
                  Result.Add( IntToStr( X ) + ':' + tmpStr );
              End;
            Inc( X );
          End;
      End
    Else                                {Assume nothing.  Base search byte by byte on length of "System"}
      Begin
        For Y := 1 To Length( System ) Do
          tmpStr := tmpStr + Self.GetChar;
        While Not ( Self.EndOfFile ) Do
          Begin
            If Flag And $01 = $01 Then
              tmpStr := UpperCase( tmpStr );
            If Pos( System, tmpStr ) <> 0 Then
              Begin
                If Flag And $02 = $02 Then
                  Result.Add( tmpStr )
                Else If Flag And $04 = $04 Then
                  Result.Add( IntToStr( X ) )
                Else
                  Result.Add( IntToStr( X ) + ':' + tmpStr );
              End;
            Inc( X );
            If Length( tmpStr ) > 0 Then
              Delete( tmpStr, 1, 1 );
            tmpStr := tmpStr + Self.GetChar;
          End;
      End;
  Except
    Result.Free;
    Result := Nil;
  End;
End;

function TMemoryFile.GetStringEx(Delim: AnsiChar): AnsiString;
Begin
  // Since this one doesn't follow a standard, I'm keeping the quotes
  //   for the quoted strings.  In some cases, this is required.  Of
  //   course, other quoted strings uses single quotes.... but hey
  //   how many ways does a person need, anyway... -2.13
  If Peek = '"' Then
    Begin
      GetChar;
      Result := '"' + GetSingleString( '"' ) + '"';
      GetSingleString( Delim );
    End
  Else
    Result := GetSingleString( Delim );
end;

function TMemoryFile.GetCommaDelim2: AnsiString;
begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  Result := '';
  If ( AnsiChar( FPch^ ) <> ',' ) Then
    Begin
      if AnsiChar( FPch^ ) = '"' then
        begin

        end;
      While Not ( EndOfLine ) And Not ( EndOfFile ) And ( AnsiChar( FPch^ ) <> ',' ) Do
        Begin
          Result := Result + AnsiChar( FPch^ );
          Inc( FPch );
          Inc( FCurPos );
        End;
    End;
  If AnsiChar( FPch^ ) = ',' Then
    Begin
      Inc( FPch );
      Inc( FCurPos );
    End;
end;

function TMemoryFile.PeekNextChar: AnsiChar;
Var
  OrgLoc: Pointer;
  OrgCurPos: LongInt;
Begin
  OrgLoc := FPch;
  OrgCurPos := FCurPos;
  Try
    Result := GetChar;
    While Result = #32 do
      Result := GetChar;
  Finally
    FPch := OrgLoc;
    FCurPos := OrgCurPos;
  End;
end;

procedure TMemoryFile.EncryptFile(const CryptKey: AnsiString; Shift: Boolean);
var
  x: LongInt;
begin
  Reset;
  if Shift then
    begin
      while Not( EndOfFile ) do
        begin
          Byte( FPch^ ) := Byte( FPch^ ) shl 1;
          Inc( FPch );
          Inc( FCurPos );
        end;
    end;
  Reset;
  while Not( EndOfFile ) do
    begin
      for x := 1 to Length(CryptKey) do
        begin
          if Not( EndOfFile ) then
            begin
              Byte( FPch^ ) := Byte( FPch^ ) xor Byte( CryptKey[x] );
              Inc( FPch );
              Inc( FCurPos );
            end;
        end;
    end;
end;

procedure TMemoryFile.DecryptFile(const CryptKey: AnsiString; Shift: Boolean);
var
  x: LongInt;
begin
  Reset;
  while Not( EndOfFile ) do
    begin
      for x := 1 to Length(CryptKey) do
        begin
          if Not( EndOfFile ) then
            begin
              Byte( FPch^ ) := Byte( FPch^ ) xor Byte( CryptKey[x] );
              Inc( FPch );
              Inc( FCurPos );
            end;
        end;
    end;
  Reset;
  if Shift then
    begin
      while Not( EndOfFile ) do
        begin
          Byte( FPch^ ) := Byte( FPch^ ) shr 1;
          Inc( FPch );
          Inc( FCurPos );
        end;
    end;
end;

function TMemoryFile.AdvanceWhiteSpace: AnsiString;
begin
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  Result := '';
  If Not( EndOFLine ) and Not( EndOfFile ) and ( AnsiChar( FPch^ ) <= #32 ) Then
    Begin
      While Not( EndOfLine ) And Not( EndOfFile ) And ( AnsiChar( FPch^ ) <= #32 ) Do
        Begin
          Result := Result + AnsiChar( FPch^ );
          Inc( FPch );
          Inc( FCurPos );
        End;
    End;
end;

function TMemoryFile.GetWChar: WideChar;
var
  tmp: TUnicodeRec;
begin
  Result := #0;
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  If Not ( EndOfFile ) Then
    Begin
      tmp.Hi2Char := AnsiChar( FPch^ );
      Inc( FPch );
      Inc( FCurPos );
    End;
  If Not ( EndOfFile ) Then
    Begin
      tmp.Hi1Char := AnsiChar( FPch^ );
      Inc( FPch );
      Inc( FCurPos );
    End;
  If Not ( EndOfFile ) Then
    Begin
      tmp.Low2Char := AnsiChar( FPch^ );
      Inc( FPch );
      Inc( FCurPos );
    End;
  If Not ( EndOfFile ) Then
    Begin
      tmp.Low1Char := AnsiChar( FPch^ );
      Inc( FPch );
      Inc( FCurPos );
    End;
  Result := tmp.UniChar;
end;

function TMemoryFile.GetWLine: WideString;
Begin                                   // Ansi Strings are big... should work
  If FPch = Nil Then
    Raise EMemoryFileError.Create( 'No file to access' );
  Result := '';
  While Not ( EndOfLine ) And Not ( EndOfFile ) Do
    Begin
      Result := Result + GetWChar;
    End;
end;

function TMemoryFile.PeekAbsNext: AnsiChar;
var
  tmpPch: PAnsiChar;
begin
  tmpPch := FPch;
  inc( tmpPch );
  Result := tmpPch^;
end;

End.


VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "HighScores"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Type HighScore
    Score As Long
    Player As String * 50
End Type

Private Type HighScoreRecord
    Data(1 To 128) As Long
End Type

Private mHighScores(1 To 10) As HighScore
Private mlKey() As Long

Public Function ClearScores()
    Dim llCtr As Long
    
    For llCtr = 1 To 10
        mHighScores(llCtr).Score = 0
        mHighScores(llCtr).Player = ""
    Next llCtr
End Function

Public Function AddScore(rsPlayer As String, ByVal vlScore As Long) As Long
    Dim llCtr As Long
    Dim llIdx As Long
    
    llIdx = -1
    For llCtr = 1 To 10
        If vlScore > mHighScores(llCtr).Score Then
            llIdx = llCtr
            Exit For
        End If
    Next llCtr

    If llIdx > 0 Then
        For llCtr = 10 To llIdx + 1 Step -1
            mHighScores(llCtr) = mHighScores(llCtr - 1)
        Next llCtr
        
        mHighScores(llIdx).Score = vlScore
        mHighScores(llIdx).Player = rsPlayer & Space(50 - Len(rsPlayer))
    End If
    
    AddScore = llIdx
End Function

Public Sub SetPlayer(ByVal vlIdx As Long, rsPlayer As String)
    mHighScores(vlIdx).Player = rsPlayer & Space(50 - Len(rsPlayer))
End Sub

Public Sub GetScore(ByVal vlPlace As Long, ByRef rsPlayer As String, ByRef rlScore As Long)
    rlScore = mHighScores(vlPlace).Score
    rsPlayer = RTrim$(mHighScores(vlPlace).Player)
End Sub

Public Sub ReadScores(rsPath As String)
    On Error GoTo ReadScores_ErrorHandler
    Dim liFileNum As Integer
    Dim llCtr1 As Long
    Dim llCtr2 As Long
    Dim llCurrentKey As Long
    Dim llCurrentChar As Long
    Dim llChecksum As Long
    Dim llSavedChecksum As Long
    Dim llScore As Long
    Dim lHighScoreRecord As HighScoreRecord
    
    liFileNum = FreeFile()
    Open rsPath For Random Access Read As #FreeFile Len = Len(lHighScoreRecord)
    
    For llCtr1 = 1 To 10
        Get #liFileNum, , lHighScoreRecord
        For llCtr2 = 1 To 50
            llCurrentKey = mlKey((llCtr2 Mod UBound(mlKey)) + 1) + llCtr2 + llCtr1
            llCurrentChar = lHighScoreRecord.Data(llCtr2) Xor llCurrentKey
            llChecksum = llChecksum + llCurrentChar
            Mid$(mHighScores(llCtr1).Player, llCtr2, 1) = Chr$(llCurrentChar)
        Next llCtr2
        
        llCurrentKey = mlKey((51 Mod UBound(mlKey)) + 1) + 51 + llCtr1
        llScore = lHighScoreRecord.Data(51) Xor llCurrentKey
        llChecksum = llChecksum + llScore
        
        For llCtr2 = 52 To 127
            llCurrentKey = mlKey((llCtr2 Mod UBound(mlKey)) + 1) + llCtr2 + llCtr1
            llCurrentChar = lHighScoreRecord.Data(llCtr2) Xor llCurrentKey
            llChecksum = llChecksum + llCurrentChar
        Next llCtr2
        
        llCurrentKey = mlKey((128 Mod UBound(mlKey)) + 1) + 128 + llCtr1
        llSavedChecksum = lHighScoreRecord.Data(128) Xor llCurrentKey
    
        If llSavedChecksum <> llChecksum Then
            llScore = (Int(9 * Rnd) + 1) * 100
        End If
        
        mHighScores(llCtr1).Score = llScore
    Next llCtr1

    Close #FreeFile
    
    Exit Sub
    
ReadScores_ErrorHandler:
    Debug.Print Err.Number, Err.Description
    Err.Clear
    On Error Resume Next
    Close #FreeFile
End Sub

Public Sub WriteScores(rsPath As String)
    On Error GoTo WriteScores_ErrorHandler
    Dim liFileNum As Integer
    Dim llCtr1 As Long
    Dim llCtr2 As Long
    Dim llCurrentKey As Long
    Dim llCurrentChar As Long
    Dim llChecksum As Long
    Dim llScore As Long
    Dim lHighScoreRecord As HighScoreRecord
    
    liFileNum = FreeFile()
    Open rsPath For Random Access Write As #FreeFile Len = Len(lHighScoreRecord)
    
    For llCtr1 = 1 To 10
        For llCtr2 = 1 To 50
            llCurrentKey = mlKey((llCtr2 Mod UBound(mlKey)) + 1) + llCtr2 + llCtr1
            llCurrentChar = Asc(Mid$(mHighScores(llCtr1).Player, llCtr2, 1))
            llChecksum = llChecksum + llCurrentChar
            lHighScoreRecord.Data(llCtr2) = llCurrentChar Xor llCurrentKey
        Next llCtr2
        
        llScore = mHighScores(llCtr1).Score
        
        llCurrentKey = mlKey((51 Mod UBound(mlKey)) + 1) + 51 + llCtr1
        llChecksum = llChecksum + llScore
        lHighScoreRecord.Data(51) = llScore Xor llCurrentKey
    
        For llCtr2 = 52 To 127
            llCurrentKey = mlKey((llCtr2 Mod UBound(mlKey)) + 1) + llCtr2 + llCtr1
            lHighScoreRecord.Data(llCtr2) = Int(Rnd * &H7FFF) * IIf(CInt(Rnd * 1) = 1, 1, -1)
            llChecksum = llChecksum + llCurrentChar
            lHighScoreRecord.Data(llCtr2) = llCurrentChar Xor llCurrentKey
        Next llCtr2
        
        llCurrentKey = mlKey((128 Mod UBound(mlKey)) + 1) + 128 + llCtr1
        lHighScoreRecord.Data(128) = llChecksum Xor llCurrentKey
        
        Put #liFileNum, , lHighScoreRecord
    Next llCtr1

    Close #FreeFile
    
    Exit Sub
    
WriteScores_ErrorHandler:
    Debug.Print Err.Number, Err.Description
    Err.Clear
    On Error Resume Next
    Close #FreeFile
End Sub

Public Sub SetKey(ParamArray Keys())
    Dim llCtr As Long
    Dim llNumKeys As Long
    Dim llIdx As Long
    
    llIdx = 1
    llNumKeys = UBound(Keys) - LBound(Keys) + 1
    ReDim mlKey(1 To llNumKeys)
    For llCtr = LBound(Keys) To UBound(Keys)
        mlKey(llIdx) = Keys(llCtr)
        llIdx = llIdx + 1
    Next llCtr
End Sub

Private Sub Class_Initialize()
    Call SetKey( _
        &HBFF5&, &H663D&, &H5AC5&, &H70D5&, &H969B&, &HCEB5&, &H1D90&, &H7BA0&, _
        &HD9A3&, &H34&, &HC8A3&, &H3132&, &H506&, &H8328&, &HC011&, &H65F4&, _
        &HA8C0&, &H1631&, &H100F&, &HDEBF&, &HC730&, &HB726&, &H93E7&, &HA673&, _
        &H880C&, &H9D3F&, &HAD78&, &H3B74&, &H58EA&, &H3EC8&, &HD2B3&, &H2047&, _
        &HE5F7&, &H5984&, &HFDCE&, &H4C99&, &H14A4&, &HFD47&, &HA24&, &HB987&, _
        &H1C63&, &H5F3B&, &H6C83&, &HE656&, &H681E&, &HF8BB&, &H87DC&, &H567D&, _
        &HA9D0&, &H747A&, &H5657&, &HFEC6&, &HB1F9&, &HF34D&, &HC67C&, &HDA30&, _
        &HD90D&, &H9B6C&, &H28FA&, &H681F&, &H6CE5&, &HF424&, &H12B3&, &H3BE9&, _
        &H28AD&, &HBA37&, &H5FFD&, &H186B&, &HE384&, &HDE7A&, &HFA22&, &H4CB1&, _
        &HE33E&, &H9516&, &H3610&, &H4F1&, &H9585&, &H7667&, &HB999&, &H2C1&, _
        &HA783&, &H3020&, &H4BE4&, &HEDB&, &HFD98&, &HD114&, &HEB8A&, &H434F&, _
        &HAF3A&, &H8F8D&, &HDA19&, &HD41&, &H4840&, &HD3B8&, &HCDA4&, &HF156&, _
        &H69D5&, &H6957&, &H6F61&, &HF54B&, &H34B&, &H416E&, &HCCB8&, &H122E&, _
        &H5025&, &HB0E5&, &H475A&, &HB922&, &HAA5B&, &H2E4C&, &H5547&, &H6BDE&, _
        &HB1D9&, &H6931&, &HEFA6&, &H2EFE&, &H79FF&, &H519B&, &HE301&, &HFF91&, _
        &H1A62&, &H5983&, &HB206&, &H3AF9&, &HFEF9&, &HCC65&, &HD397&, &H838D& _
    )
    
    Dim llCtr As Long
    
    For llCtr = 1 To 10
        mHighScores(llCtr).Score = 0
        mHighScores(llCtr).Player = Space(50)
    Next llCtr
    
End Sub

Imports OSIsoft.PI.ACE
Imports PITimeServer
Imports OSIsoft.PI.ACE.PIACEBIFunctions
Imports PISDK

'Imports System.CodeDom.Compiler
'Imports System.Reflection ' MethodInfo
'Imports System.Collections.Generic
'Imports Ciloci.Flee 'expression parser



Public Class CommonFunctions


    ''' <summary>
    ''' Gets the first PI event of a Tag near the specified time or returns nothing.
    ''' Searches back from the specified time first, and if nothing is found searches forward.
    ''' Note: Code has got stuck in a loop before - but was not resolved
    ''' </summary>
    ''' <param name="ACETag">
    ''' The PIAcePoint of interest.
    ''' </param>
    ''' <param name="GetTime">
    ''' The time to retrieve the value from as PITime - use PIACEBIFunctions.ParseTime(...,...) to convert from date time to PITime
    ''' </param>
    ''' <param name="Tol">
    ''' Time match (negative) tolerance in seconds as double. ie. will return an event within (+)-0.5 seconds of the GetTime
    ''' If pTol is specified the returned event will have a time stamp within GetTime - Tol and GetTime + pTol
    ''' </param>
    ''' <param name="pTol">
    ''' Time match positive tolerance in seconds as double. ie. returned event will have a time stamp within GetTime - Tol and GetTime + pTol
    ''' </param>
    ''' <returns>
    ''' PIACE event with value  and time, or nothing is the data is bad or does not exist
    ''' </returns>
    ''' <remarks>
    ''' updated 2009-06-24 08:44
    ''' Note: Code has got stuck in a loop before - but was not resolved (loop break after 100 iterations has been implemented)
    ''' </remarks>
    Public Shared Function GetValueAtTime_old(ByVal ACETag As PIACEPoint, ByVal GetTime As PITime, ByVal Tol As Double, Optional ByVal pTol As Double = 0) As PIACEEvent

        'get list of pi values and find on that matches time

        Dim whileLoopBreakLimit As Long = 100
        Dim Whilecount As Long = 0
        Dim events As PIACEEvent
        Dim TimeJump As Long = 1 ' time added to first lookup time - incase there is a value at the lookup time
        Dim TotAdd As Long = 1 ' time added to first totaliser time

        'If positive tolerance has no value entered
        If pTol = 0 Then pTol = Tol

        ' Get data at time
        events.Value = Nothing
        Try

            'get value but did not use TotTag.value(time) as the previous point is returned
            ' set time lookup to 1 second after the event tag. If there is a data point at the execution time (as there normally is for event calculations),
            ' the data point will be missed and the previous point returned.
            ' PreVal/Event returns the previous point even of there is a point at the time specified
            ' Need to minus clockdrift, the server adds the drift to the local machine time for data extraction
            ' Set the tag Clockoffset = false for the clock drift not to be factored in - work on local PC but not server. Therefore minuses clockdrift manually

            ' manually correct for clock drift as ACETag.AdjustClockOffset = False - did not work on the server
            Dim Addtime As String = CStr(System.Math.Abs(TimeJump - CDbl(ACETag.ClockDrift))) 'System.Math.Abs(TimeJump)
            If TimeJump - CDbl(ACETag.ClockDrift) >= 0 Then 'TimeJump >= 0 Then
                Addtime = "+" & Addtime & "s"
            Else
                Addtime = "-" & Addtime & "s"
            End If


            ' Must minus clock drift, therfore change sign
            Dim CDriftString As String = CStr(System.Math.Abs(CDbl(ACETag.ClockDrift)))
            If CDbl(ACETag.ClockDrift) >= 0 Then 'TimeJump >= 0 Then
                CDriftString = "-" & CDriftString & "s"
            Else
                CDriftString = "+" & CDriftString & "s"
            End If


            Dim CurrentEvnt As PIACEEvent = Nothing
            Dim IntrimEvntTime As PITimeServer.PITime = Nothing

            'Recurse back from current time
            'get first previous time and event to check
            Dim CurrentEvntTime As PITimeServer.PITime = ACETag.PrevEvent(ParseTime(Addtime, CStr(GetTime.UTCSeconds)))
            CurrentEvnt.Value = CStr(ACETag.PrevVal(ParseTime(Addtime, CStr(GetTime.UTCSeconds))))

            'if current time < specified time - go forward

            Whilecount = 0
            While CurrentEvntTime.UTCSeconds - GetTime.UTCSeconds < -Tol  ' Current value is in the past - go forward
                IntrimEvntTime = ACETag.NextEvent(ParseTime(CDriftString, CurrentEvntTime.LocalDate.ToString))
                CurrentEvnt.Value = CStr(ACETag.NextVal(ParseTime(CDriftString, CurrentEvntTime.LocalDate.ToString)))
                CurrentEvntTime = IntrimEvntTime
                Whilecount += 1
                If Whilecount > whileLoopBreakLimit Then Throw New Exception("while loop iteration limit reached = " & whileLoopBreakLimit)
            End While

            Whilecount = 0
            While CurrentEvntTime.UTCSeconds - GetTime.UTCSeconds > pTol  ' Current value is in the future - go back
                IntrimEvntTime = ACETag.PrevEvent(ParseTime(CDriftString, CurrentEvntTime.LocalDate.ToString))
                CurrentEvnt.Value = CStr(ACETag.PrevVal(ParseTime(CDriftString, CurrentEvntTime.LocalDate.ToString)))
                CurrentEvntTime = IntrimEvntTime
                Whilecount += 1
                If Whilecount > whileLoopBreakLimit Then Throw New Exception("while loop itteration limit reached = " & whileLoopBreakLimit)
            End While


            'Check time match
            If CurrentEvntTime.UTCSeconds - GetTime.UTCSeconds > -Tol And CurrentEvntTime.UTCSeconds - GetTime.UTCSeconds < pTol Then
                events.TimeStamp = CurrentEvntTime.UTCSeconds  'get event time
                events.Value = CurrentEvnt.Value
            Else
                events = Nothing
            End If

        Catch ex As Exception
            events = Nothing
        End Try


        Return events
    End Function

    ''' <summary>
    ''' Generates two dates, the first of which is 05:01am of at least 24 hours prior, the second of which is 05:00am the next day.
    ''' </summary>
    ''' <param name="ExeTime">
    ''' 
    ''' </param>
    ''' <returns>
    ''' A Date time Array, index 0 = time at start of period; index 1 = time at end of period 
    ''' </returns>
    ''' <remarks>
    ''' An older function that only works for 1 day periods from 05:00:01 to 05:00:00 - use "GetTotalizedPeriod" for a more options
    ''' updated 2009-03-31 10:30
    ''' </remarks>
    Public Shared Function GenerateFiveAMYesterdayDates(ByVal ExeTime As Object) As DateTime()
        Dim whileLoopBreakLimit As Long = 100
        Dim Whilecount As Long = 0
        'Generate relevant datetimes
        Dim first_date, second_date As DateTime
        Try
            Dim datenow As Date = ParseTime(CStr(ExeTime)).LocalDate
            datenow = datenow.Subtract(datenow.TimeOfDay)
            first_date = datenow.Add(New TimeSpan(-1, 5, 0, 1))
            second_date = datenow.Add(New TimeSpan(0, 5, 0, 0))
            If Now.Hour < 5 Then 'It's executed earlier than today's values - set yesterday's values
                first_date = first_date.AddDays(-1)
                second_date = second_date.AddDays(-1)
            End If
            Dim dates As DateTime() = {first_date, second_date}
            Return dates
        Catch ex As Exception
            'It's stuffed - just give up already...
            Throw New Exception("Fundamental date calculation failed.")
        End Try
    End Function

    ''' <summary>
    ''' This method saves the value of the tag at the given time using the PI SDK (as opposed to the standard ACE method).
    ''' This is useful for saving the value at an exact time, with no drift; or writing multiple values into PI.
    ''' </summary>
    ''' <param name="tagname">
    ''' The tag name as a string.
    ''' </param>
    ''' <param name="tagval">
    ''' The tag's value.
    ''' </param>
    ''' <param name="time">
    ''' The time at which this value occured.
    ''' </param>
    ''' <remarks>
    ''' The PI ACE calculation context needs to run off the modular database, and there needes to be 1 alias in the root node of the context for this method to work.
    ''' The PI server for PIAlias.Item(1) is used for all output tags - this will result in errors if tags from multiple servers are present
    ''' updated 2009-03-31 10:30
    ''' updated 2011-11-30 got servername from context path finds tag directly from this
    ''' </remarks>
    Public Shared Sub SendViaPISDK(ByVal Context As String, ByVal tagname As String, ByVal tagval As Object, ByVal time As DateTime)

        'Get piserver from Context
        Dim ContextPath As String() = Context.Split({"\"}, StringSplitOptions.RemoveEmptyEntries)
        Dim ServerName As String = ContextPath(0)

        Dim _PISDK As New PISDK.PISDK
        Dim OutPoint As PISDK.PIPoint

        Try
            OutPoint = _PISDK.GetPoint("\\" & ServerName & "\" & tagname)

            'Test out for testing otherwise a value is writen out
            OutPoint.Data.UpdateValue(tagval, time)

        Catch ex As Exception

            Throw New Exception("Error on write out " & ex.Message)

        End Try



        'old To be removed after testing
        'Dim OutPointList As PointList
        'Dim OutPoint As PISDK.PIPoint
        'Dim Server As PISDK.Server
        'Dim ErinFindorWrite As Boolean = False
        'Try
        '    Server = GetPIModuleFromPath(Context).PIAliases.Item(1).Server
        '    'use the SDK to send values to PI as modual has no spesific output alias
        '    'OutPointList = Server.GetPoints("Tag = '" & CurModule.PIAliases.Item(nn).DataSource.Name.ToString & "'")
        '    Try
        '        OutPointList = Server.GetPoints("Tag = '" & tagname & "'")
        '        'object.UpdateValue NewValue, TimeStamp, [MergeType], [AsyncStatus]
        '        OutPoint = OutPointList.Item(1)

        '        'Test out for testing otherwise a value is writen out
        '        OutPoint.Data.UpdateValue(tagval, time)
        '    Catch ex As Exception
        '        ErinFindorWrite = True
        '        Throw New Exception(ex.Message & "; " & "Could not find PI tag or error writing out")
        '    End Try

        'Catch ex As Exception
        '    If ErinFindorWrite = True Then
        '        Throw New Exception(ex.Message)
        '    Else
        '        Throw New Exception(ex.Message & "; " & "Could not find PI server")
        '    End If

        'End Try

    End Sub

    ''' <summary>
    ''' Writes out a value to PI, with option to test (no writeout), check value against the tags zero and span, write to a second date 
    ''' </summary>
    ''' <param name="TagAlias">PI ACE Alias to write to</param>
    ''' <param name="tagval">Value to write out</param>
    ''' <param name="FirstDate">Date Time to write to</param>
    ''' <param name="TestWriteOut">true = running a test and no value is writen; false = write a value out</param>
    ''' <param name="CheckToZeroSpan">true = check the input Value to see if it is with the zero and span range
    ''' If less than TagZero then "Under Range" is writen out
    ''' If greater than TagZero + TagSpan then "Over Range" is writen out
    ''' </param>
    ''' <param name="SecondDate"> optinal second date to write the input value to</param>
    ''' <param name="Zero">specify a zero to overide the TagZero or when TagZero is known PIACEPoint.Zero</param>
    ''' <param name="Span">specify a span to overide the TagSpan or when TagSpan is known PIACEPoint.Span</param>
    ''' <remarks></remarks>
    Public Shared Sub SendViaPISDK(ByVal TagAlias As PIAlias, ByVal tagval As Object, FirstDate As DateTime, _
                                 Optional TestWriteOut As Boolean = False, _
                                 Optional CheckToZeroSpan As Boolean = False, _
                                 Optional SecondDate As DateTime = Nothing, _
                                 Optional Zero As Double = Double.NaN, _
                                 Optional Span As Double = Double.NaN)

        Dim OutPoint As PISDK.PIPoint

        Try
            OutPoint = TagAlias.DataSource

            'Test out for testing otherwise a value is writen out
            UpdateViaPISDDKWithCheck(OutPoint, tagval, FirstDate, TestWriteOut, CheckToZeroSpan, SecondDate, Zero, Span)

        Catch ex As Exception

            Throw New Exception("Error on write out " & ex.Message)

        End Try

    End Sub
    ''' <summary>
    ''' Writes out a value to PI, with option to test (no writeout), check value against the tags zero and span, write to a second date 
    ''' </summary>
    ''' <param name="OutPoint">PI Point to write to</param>
    ''' <param name="tagval">Value to write out</param>
    ''' <param name="FirstDate">Date Time to write to</param>
    ''' <param name="TestWriteOut">true = running a test and no value is writen; false = write a value out</param>
    ''' <param name="CheckToZeroSpan">true = check the input Value to see if it is with the zero and span range
    ''' If less than TagZero then "Under Range" is writen out
    ''' If greater than TagZero + TagSpan then "Over Range" is writen out
    ''' </param>
    ''' <param name="SecondDate"> optinal second date to write the input value to</param>
    ''' <param name="Zero">specify a zero to overide the TagZero or when TagZero is known PIACEPoint.Zero</param>
    ''' <param name="Span">specify a span to overide the TagSpan or when TagSpan is known PIACEPoint.Span</param>
    ''' <remarks></remarks>
    Public Shared Sub SendViaPISDK(ByVal OutPoint As PIPoint, ByVal tagval As Object, FirstDate As DateTime, _
                                 Optional TestWriteOut As Boolean = False, _
                                 Optional CheckToZeroSpan As Boolean = False, _
                                 Optional SecondDate As DateTime = Nothing, _
                                 Optional Zero As Double = Double.NaN, _
                                 Optional Span As Double = Double.NaN)

        Try

            'Test out for testing otherwise a value is writen out
            UpdateViaPISDDKWithCheck(OutPoint, tagval, FirstDate, TestWriteOut, CheckToZeroSpan, SecondDate, Zero, Span)

        Catch ex As Exception

            Throw New Exception("Error on write out " & ex.Message)

        End Try

    End Sub
    ''' <summary>
    ''' Writes out a value to PI, with option to test (no writeout), check value against the tags zero and span, write to a second date 
    ''' </summary>
    ''' <param name="OutACEPoint">PI ACE Point to write to</param>
    ''' <param name="tagval">Value to write out</param>
    ''' <param name="FirstDate">Date Time to write to</param>
    ''' <param name="TestWriteOut">true = running a test and no value is writen; false = write a value out</param>
    ''' <param name="CheckToZeroSpan">true = check the input Value to see if it is with the zero and span range
    ''' If less than TagZero then "Under Range" is writen out
    ''' If greater than TagZero + TagSpan then "Over Range" is writen out
    ''' </param>
    ''' <param name="SecondDate"> optinal second date to write the input value to</param>
    ''' <param name="Zero">specify a zero to overide the TagZero or when TagZero is known PIACEPoint.Zero</param>
    ''' <param name="Span">specify a span to overide the TagSpan or when TagSpan is known PIACEPoint.Span</param>
    ''' <remarks></remarks>
    Public Shared Sub SendViaPISDK(ByVal OutACEPoint As PIACEPoint, ByVal tagval As Object, FirstDate As DateTime, _
                                 Optional TestWriteOut As Boolean = False, _
                                 Optional CheckToZeroSpan As Boolean = False, _
                                 Optional SecondDate As DateTime = Nothing, _
                                 Optional Zero As Double = Double.NaN, _
                                 Optional Span As Double = Double.NaN)

        Dim ServerName As String = OutACEPoint.Server
        Dim TagName As String = OutACEPoint.Tag

        Dim _PISDK As New PISDK.PISDK
        Dim OutPoint As PISDK.PIPoint

        Try
            OutPoint = _PISDK.GetPoint("\\" & ServerName & "\" & TagName)

            'Test out for testing otherwise a value is writen out
            UpdateViaPISDDKWithCheck(OutPoint, tagval, FirstDate, TestWriteOut, CheckToZeroSpan, SecondDate, OutACEPoint.Zero, OutACEPoint.Span)

        Catch ex As Exception

            Throw New Exception("Error on write out " & ex.Message)

        End Try

    End Sub

    ''' <summary>
    ''' Writes out a value to PI, with option to test (no writeout), check value against the tags zero and span, write to a second date 
    ''' </summary>
    ''' <param name="FullTagName">full PITag name to write to  //server/Tag</param>
    ''' <param name="tagval">Value to write out</param>
    ''' <param name="FirstDate">Date Time to write to</param>
    ''' <param name="TestWriteOut">true = running a test and no value is writen; false = write a value out</param>
    ''' <param name="CheckToZeroSpan">true = check the input Value to see if it is with the zero and span range
    ''' If less than TagZero then "Under Range" is writen out
    ''' If greater than TagZero + TagSpan then "Over Range" is writen out
    ''' </param>
    ''' <param name="SecondDate"> optinal second date to write the input value to</param>
    ''' <param name="Zero">specify a zero to overide the TagZero or when TagZero is known PIACEPoint.Zero</param>
    ''' <param name="Span">specify a span to overide the TagSpan or when TagSpan is known PIACEPoint.Span</param>
    ''' <remarks></remarks>
    Public Shared Sub SendViaPISDK(ByVal FullTagName As String, ByVal tagval As Object, FirstDate As DateTime, _
                                 Optional TestWriteOut As Boolean = False, _
                                 Optional CheckToZeroSpan As Boolean = False, _
                                 Optional SecondDate As DateTime = Nothing, _
                                 Optional Zero As Double = Double.NaN, _
                                 Optional Span As Double = Double.NaN)

        Dim _PISDK As New PISDK.PISDK
        Dim OutPoint As PISDK.PIPoint


        Try
            OutPoint = _PISDK.GetPoint(FullTagName)

            'Test out for testing otherwise a value is writen out
            UpdateViaPISDDKWithCheck(OutPoint, tagval, FirstDate, TestWriteOut, CheckToZeroSpan, SecondDate, Zero, Span)

        Catch ex As Exception

            Throw New Exception("Error on write out " & ex.Message)

        End Try

    End Sub
    ''' <summary>
    ''' This method saves the value of the tag at the given time using the PI SDK 
    ''' It uses a PIPoint passed into the function and is more efficient than SendViaPISDK
    ''' </summary>
    ''' <param name="PITag">
    ''' The tag name as a string. = PIAlias.DataSource
    ''' </param>
    ''' <param name="tagval">
    ''' The tag's value.
    ''' </param>
    ''' <param name="time">
    ''' The time at which this value occurred.
    ''' </param>
    ''' <param name="Testing">
    ''' False = Value written  to PI, True = no value written to PI
    ''' </param>
    ''' <remarks>
    ''' This method should be used as the preferred write out as it is more efficient that SendViaPISDK (which has to first search for the tag using a string input)
    ''' Writes out when the PI SDK tag is know, the SDK tag is available from the PIAlias.DataSource property
    ''' writePISDK(PIAlias.DataSource, 23, 2010-08-17 06:00:01)
    ''' updated 2010-08-17 
    '''  </remarks>
    Public Shared Sub writePISDK(ByVal PItag As PIPoint, ByVal tagval As Object, ByVal time As DateTime, ByVal Testing As Boolean)


        If Not Testing Then
            Try
                'Test out for testing otherwise a value is writen out
                PItag.Data.UpdateValue(tagval, time)
            Catch ex As Exception

                Throw New Exception(ex.Message & "; " & "Could not find PI tag or error writing out")
            End Try
        End If




    End Sub

    ''' <summary>
    ''' Writes out a value to PI, with option to test (no writeout), check value against the tags zero and span, write to a second date 
    ''' </summary>
    ''' <param name="PiTag">PIpoint to write to</param>
    ''' <param name="Value">Value to write out</param>
    ''' <param name="FirstDate">Date Time to write to</param>
    ''' <param name="TestWriteOut">true = running a test and no value is writen; false = write a value out</param>
    ''' <param name="CheckToZeroSpan">true = check the input Value to see if it is with the zero and span range
    ''' If less than TagZero then "Under Range" is writen out
    ''' If greater than TagZero + TagSpan then "Over Range" is writen out
    ''' </param>
    ''' <param name="SecondDate"> optinal second date to write the input value to</param>
    ''' <param name="Zero">specify a zero to overide the TagZero or when TagZero is known PIACEPoint.Zero</param>
    ''' <param name="Span">specify a span to overide the TagSpan or when TagSpan is known PIACEPoint.Span</param>
    ''' <remarks></remarks>
    Public Shared Sub UpdateViaPISDDKWithCheck(PiTag As PIPoint, Value As Object, FirstDate As DateTime, _
                                 Optional TestWriteOut As Boolean = False, _
                                 Optional CheckToZeroSpan As Boolean = False, _
                                 Optional SecondDate As DateTime = Nothing, _
                                 Optional Zero As Double = Double.NaN, _
                                 Optional Span As Double = Double.NaN)
        Dim val As Double
        'only write out second date if there is a second date and testing is not flagged
        Dim notWriteOutSecond As Boolean = Not ((Not (SecondDate = Nothing)) And (Not TestWriteOut))

        Try


            ' only check value to zero and span if source can be converter to a double and the Bit to check to zero and span is enabled
            If Double.TryParse(Value.ToString, val) And CheckToZeroSpan Then
                If Double.IsNaN(Zero) Then Zero = CDbl(PiTag.PointAttributes.Item("zero").Value)
                If Double.IsNaN(Span) Then Span = CDbl(PiTag.PointAttributes.Item("span").Value)

                If val < Zero Then
                    If Not TestWriteOut Then PiTag.Data.UpdateValue("Under Range", FirstDate)
                    If Not notWriteOutSecond Then PiTag.Data.UpdateValue("Under Range", SecondDate)
                ElseIf val > Zero + Span Then
                    If Not TestWriteOut Then PiTag.Data.UpdateValue("Over Range", FirstDate)
                    If Not notWriteOutSecond Then PiTag.Data.UpdateValue("Over Range", SecondDate)
                Else
                    If Not TestWriteOut Then PiTag.Data.UpdateValue(Value, FirstDate)
                    If Not notWriteOutSecond Then PiTag.Data.UpdateValue(Value, SecondDate)
                End If
            Else
                If Not TestWriteOut Then PiTag.Data.UpdateValue(Value, FirstDate)
                If Not notWriteOutSecond Then PiTag.Data.UpdateValue(Value, SecondDate)
            End If

        Catch ex As Exception
            Throw New Exception("Error on UpdateViaPISDDKWithCheck " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Removes a value from PI, either the first value whith multivalue times or all values
    ''' </summary>
    ''' <param name="OutACEPoint">AcePoint to Remove value from</param>
    ''' <param name="FirstDate">Date to remove value</param>
    ''' <param name="TestRemove">true = running a test and no value is writen; false = write a value out</param>
    ''' <param name="RemoveAllorFirst">true = removes all values at the time
    ''' True = remove all values
    ''' False = remove first value
    ''' </param>
    ''' <param name="SecondDate"> optinal second date to remove value from</param>
    ''' <param name="RemoveRange">optional  remove a range of values first date to second date</param> 
    ''' <remarks></remarks>
    Public Shared Sub RemoveViaPISDK(OutACEPoint As PIACEPoint, FirstDate As DateTime, _
                                 Optional TestRemove As Boolean = False, _
                                 Optional RemoveAllorFirst As Boolean = False, _
                                 Optional SecondDate As DateTime = Nothing, _
                                 Optional RemoveRange As Boolean = False)


        Dim ServerName As String = OutACEPoint.Server
        Dim TagName As String = OutACEPoint.Tag

        Dim _PISDK As New PISDK.PISDK
        Dim OutPoint As PISDK.PIPoint

        Try
            OutPoint = _PISDK.GetPoint("\\" & ServerName & "\" & TagName)

            'Test out for testing otherwise a value is writen out
            RemoveViaPISDDKWithCheck(OutPoint, FirstDate, TestRemove, RemoveAllorFirst, SecondDate, RemoveRange)

        Catch ex As Exception

            Throw New Exception("Error on remove out " & ex.Message)

        End Try

    End Sub

    ''' <summary>
    ''' Removes a value from PI, either the first value whith multivalue times or all values
    ''' </summary>
    ''' <param name="TagAlias">PIAlias to Remove value from</param>
    ''' <param name="FirstDate">Date to remove value</param>
    ''' <param name="TestRemove">true = running a test and no value is writen; false = write a value out</param>
    ''' <param name="RemoveAllorFirst">true = removes all values at the time
    ''' True = remove all values
    ''' False = remove first value
    ''' </param>
    ''' <param name="SecondDate"> optinal second date to remove value from</param>
    ''' <param name="RemoveRange">optional  remove a range of values first date to second date</param> 
    ''' <remarks></remarks>
    Public Shared Sub RemoveViaPISDK(TagAlias As PIAlias, FirstDate As DateTime, _
                                 Optional TestRemove As Boolean = False, _
                                 Optional RemoveAllorFirst As Boolean = False, _
                                 Optional SecondDate As DateTime = Nothing, _
                                 Optional RemoveRange As Boolean = False)


        Dim _PISDK As New PISDK.PISDK
        Dim OutPoint As PISDK.PIPoint

        Try
            OutPoint = TagAlias.DataSource

            'Test out for testing otherwise a value is writen out
            RemoveViaPISDDKWithCheck(OutPoint, FirstDate, TestRemove, RemoveAllorFirst, SecondDate, RemoveRange)

        Catch ex As Exception

            Throw New Exception("Error on remove out " & ex.Message)

        End Try

    End Sub
    ''' <summary>
    ''' Removes a value from PI, either the first value whith multivalue times or all values
    ''' </summary>
    ''' <param name="PiTag">PIpoint to Remove valuye from</param>
    ''' <param name="FirstDate">Date to remove value</param>
    ''' <param name="TestRemove">true = running a test and no value is writen; false = write a value out</param>
    ''' <param name="RemoveAllorFirst">true = removes all values at the time
    ''' True = remove all values
    ''' False = remove first value
    ''' </param>
    ''' <param name="SecondDate"> optinal second date to remove value from</param>
    ''' <param name="RemoveRange">optional  remove a range of values first date to second date</param> 
    ''' <remarks></remarks>
    Public Shared Sub RemoveViaPISDDKWithCheck(PiTag As PIPoint, FirstDate As DateTime, _
                                 Optional TestRemove As Boolean = False, _
                                 Optional RemoveAllorFirst As Boolean = False, _
                                 Optional SecondDate As DateTime = Nothing, _
                                 Optional RemoveRange As Boolean = False)

        'only write out second date if there is a second date and testing is not flagged
        Dim RemoveSecond As Boolean = (Not (SecondDate = Nothing)) And (Not TestRemove) And (Not RemoveRange)
        '                                           false                    false                    true
        '                               true                           true               false

        If RemoveRange And (SecondDate = Nothing) Then
            SecondDate = FirstDate
        End If

        Try


            ' only check value to zero and span if source can be converted to a double and the Bit to check to zero and span is enabled
            If RemoveAllorFirst Then
                If RemoveRange Then
                    PiTag.Data.RemoveValues(FirstDate, SecondDate, DataRemovalConstants.drRemoveAll)
                Else
                    If Not TestRemove Then PiTag.Data.RemoveValues(FirstDate, FirstDate, DataRemovalConstants.drRemoveAll)
                    If RemoveSecond Then PiTag.Data.RemoveValues(SecondDate, SecondDate, DataRemovalConstants.drRemoveAll)
                End If

            Else
                If RemoveRange Then
                    PiTag.Data.RemoveValues(FirstDate, SecondDate, DataRemovalConstants.drRemoveFirstOnly)
                Else
                    If Not TestRemove Then PiTag.Data.RemoveValues(FirstDate, FirstDate, DataRemovalConstants.drRemoveFirstOnly)
                    If RemoveSecond Then PiTag.Data.RemoveValues(SecondDate, SecondDate, DataRemovalConstants.drRemoveFirstOnly)
                End If
            End If

        Catch ex As Exception
            Throw New Exception("Error on RemoveViaPISDDKWithCheck " & ex.Message)
        End Try
    End Sub
    ''' <summary>
    ''' A method to calculate the event-weighted total of all numeric samples within the given period.
    ''' </summary>
    ''' <param name="tag">
    ''' The tag which will be totalized.
    ''' </param>
    ''' <param name="first_date">
    ''' The start time
    ''' </param>
    ''' <param name="second_date">
    ''' The end time.
    ''' </param>
    ''' <returns>
    ''' Nothing if no data
    ''' </returns>
    ''' <remarks>
    ''' Sep 20 2012 was converting to string before adding. so values where concatenating and not adding.
    ''' Sep 28 2012 was adding to double.NaN.
    ''' </remarks>
    Public Shared Function GetTotalizedPeriod(ByRef tag As PIACEPoint, ByVal first_date As DateTime, ByVal second_date As DateTime) As PIACEEvent

        Dim tot As Double = Double.NaN
        Dim total As PIACEEvent = Nothing
        Try
            Dim values As PIValues = tag.Values(first_date, second_date, BoundaryTypeConstants.btInside)
            For i As Integer = 1 To values.Count
                If IsNumeric(values(i).Value) And values(i).IsGood And (values(i).TimeStamp.UTCSeconds >= ParseTime(first_date.ToString).UTCSeconds And values(i).TimeStamp.UTCSeconds <= ParseTime(second_date.ToString).UTCSeconds) Then
                    If Double.IsNaN(tot) Then
                        tot = Convert.ToDouble(values(i).Value)
                    Else
                        tot += Convert.ToDouble(values(i).Value)
                    End If

                End If
            Next

            If Not Double.IsNaN(tot) Then
                total.Value = CStr(tot)
            End If


            Return total
        Catch ex As Exception

            total.Value = Nothing

            Return total 'If there's an error return nothing
        End Try



    End Function

    ''' <summary>
    ''' Get a the last finalised-Totaliser-value before the given time using the tag attributes
    ''' If time is 06:32 and the totaliser ends at 06:00:00 - return value at 06:00:00
    ''' </summary>
    ''' <param name="TotTag">
    ''' The PIAcePoints of interest.
    ''' </param>
    ''' <returns>
    ''' PI event of the value and time stamp
    ''' </returns>
    ''' <remarks>
    ''' updated 2009-03-31 10:30
    ''' NOTE from Elmer Botha 2009-07-13:
    ''' This function must no longer be used as it only works for a totaliser tag.
    ''' Rather use GetACE2TotValue as it accommodates all types of tags. 
    ''' </remarks>
    Public Shared Function GetTotValue(ByVal TotTag As PIACEPoint, ByVal ExecTime As PITime) As PIACEEvent
        Dim whileLoopBreakLimit As Long = 100
        Dim Whilecount As Long = 0
        Dim events As PIACEEvent
        Dim TotEndTime As PITime = Nothing
        Dim WhileItt As Long = 145 ' ok for 5min period over 1 day
        Dim TimeJump As Long = 1 ' time added to first lookup time - incase there is a value at the lookup time

        ' set time lookup to 1 second after the event tag.
        ' If there is a data point at the execution time (as there normally is for event based calculations),
        ' the data point will be missed and the previous point returned.
        ' PreVal/Event returns the previous point even of there is a point at the time specified
        ' Need to minus clockdrift, the server adds the drift to the local machine time for data extraction



        Try 'construct totaliser final write time from tag atributes and totalising time
            Dim TotTagPeriod As String = CStr(TotTag.GetAttribute("period"))
            Dim TotTagOffset As String = CStr(TotTag.GetAttribute("Offset"))

            'first period-in-day end, write out time
            Dim FirstPeriodinDayEndTime As PITime = PIACEBIFunctions.ParseTime(TotTagPeriod & " " & TotTagOffset, BOD(ExecTime).LocalDate.ToString)

            If FirstPeriodinDayEndTime.UTCSeconds <= ExecTime.UTCSeconds Then 'Totaliser total is possibly correct or old; go forward
                'go forward 1 totaliser period
                Dim NextEndTime As PITime = PIACEBIFunctions.ParseTime(TotTagPeriod, FirstPeriodinDayEndTime.LocalDate.ToString)

                If NextEndTime.UTCSeconds > ExecTime.UTCSeconds Then ' correct

                    TotEndTime = FirstPeriodinDayEndTime

                Else 'totaliser time is old go forward
                    Dim Wit As Long = 0
                    While NextEndTime.UTCSeconds <= ExecTime.UTCSeconds
                        TotEndTime = NextEndTime
                        NextEndTime = PIACEBIFunctions.ParseTime(TotTagPeriod, NextEndTime.LocalDate.ToString)

                        Wit = Wit + 1
                        If NextEndTime.LocalDate > Now Then 'gone to far into the future
                            Throw New Exception("Date in future")
                            Exit While
                        End If

                        If Wit > WhileItt Then
                            Throw New Exception("Too many itterations")
                            Exit While
                        End If




                    End While

                End If

            Else 'recurse back beacuse totaliser end time is too far ahead
                'go back 1 totaliser period
                Dim PreviousEndTime As PITime = PIACEBIFunctions.ParseTime(TotTagPeriod.Replace("+", "-"), FirstPeriodinDayEndTime.LocalDate.ToString)
                Dim Wit As Long = 0

                While PreviousEndTime.UTCSeconds > ExecTime.UTCSeconds ' stops on first period <= input time

                    PreviousEndTime = PIACEBIFunctions.ParseTime(TotTagPeriod.Replace("+", "-"), PreviousEndTime.LocalDate.ToString)

                    Wit = Wit + 1
                    If Wit > WhileItt Then
                        Throw New Exception("Too many itterations")
                        Exit While
                    End If


                End While
                'need first period end that is <= input time
                TotEndTime = PreviousEndTime

            End If


        Catch ex As Exception
            ' not a totalising tag

            Throw New Exception("Not a totalising tag")
        End Try


        ' Get data at time
        events.Value = Nothing
        Try 'get value but did not use TotTag.value(time) as the previous point is returned
            ' set time lookup to 1 second after the event tag. If there is a data point at the execution time (as there normally is for event calculations),
            ' the data point will be missed and the previous point returned.
            ' PreVal/Event returns the previous point even of there is a point at the time specified
            ' Need to minus clockdrift, the server adds the drift to the local machine time for data extraction
            ' Set the tag Clockoffset = false for the clock drift not to be factored in - work on local PC but not server. Therefore minuses clockdrift manually


            Dim Addtime As String = CStr(System.Math.Abs(TimeJump - CDbl(TotTag.ClockDrift))) 'System.Math.Abs(TimeJump)
            If TimeJump - CDbl(TotTag.ClockDrift) >= 0 Then 'TimeJump >= 0 Then
                Addtime = "+" & Addtime & "s"
            Else
                Addtime = "-" & Addtime & "s"
            End If

            'TotTag.AdjustClockOffset = False

            ' Must minus clock drift, therfore change sign
            Dim CDrifeString As String = CStr(System.Math.Abs(CDbl(TotTag.ClockDrift)))
            If CDbl(TotTag.ClockDrift) >= 0 Then 'TimeJump >= 0 Then
                CDrifeString = "-" & CDrifeString & "s"
            Else
                CDrifeString = "+" & CDrifeString & "s"
            End If




            Dim TimeStep As PITimeServer.PITime = TotTag.PrevEvent(PIACEBIFunctions.ParseTime(Addtime, TotEndTime.LocalDate.ToString))

            If TimeStep.UTCSeconds = TotEndTime.UTCSeconds Then 'times match
                events.Value = CStr(TotTag.PrevVal(PIACEBIFunctions.ParseTime(Addtime, TotEndTime.LocalDate.ToString))) 'get value at time
                events.TimeStamp = TimeStep.UTCSeconds  'get event time

            Else
                Dim Wit As Long = 0

                While TimeStep.UTCSeconds > TotEndTime.UTCSeconds

                    TimeStep = TotTag.PrevEvent(ParseTime(CDrifeString, CStr(TimeStep.UTCSeconds))) '= TotTag.PrevEvent(TimeStep)


                    If TimeStep.UTCSeconds = TotEndTime.UTCSeconds Then
                        events.Value = CStr(TotTag.PrevVal(ParseTime(CDrifeString, CStr(TimeStep.UTCSeconds)))) '= TotTag.PrevVal(TimeStep) 'get value at time
                        events.TimeStamp = TimeStep.UTCSeconds  'get event time
                        Exit While
                    End If
                    Wit = Wit + 1
                    If Wit > WhileItt Then
                        Throw New Exception("Too many itterations")
                        Exit While
                    End If


                End While


                While events.TimeStamp < TotEndTime.UTCSeconds

                    TimeStep = TotTag.NextEvent(ParseTime(CDrifeString, CStr(TimeStep.UTCSeconds))) '= TotTag.NextEvent(TimeStep)

                    If TimeStep.UTCSeconds = TotEndTime.UTCSeconds Then
                        events.Value = CStr(TotTag.NextVal(ParseTime(CDrifeString, CStr(TimeStep.UTCSeconds)))) '= TotTag.NextVal(TimeStep) 'get value at time
                        events.TimeStamp = TimeStep.UTCSeconds  'get event time
                        Exit While
                    End If


                    Wit = Wit + 1
                    If TimeStep.LocalDate > Now Then 'gone to far into the future
                        Throw New Exception("Date in future")
                        Exit While
                    End If

                    If Wit > WhileItt Then
                        Throw New Exception("Too many itterations")
                        Exit While
                    End If

                End While



            End If


            If (IsNumeric(events.Value) = False) Then
                events.Value = Nothing
            End If




        Catch ex As Exception
            Throw New Exception("No Data")

        End Try


        If (events.Value = Nothing) Then
            Throw New Exception("It's got missing values")
        End If

        'TotTag.AdjustClockOffset = True

        Return events
    End Function
    ''' <summary>
    ''' Gets the last value of a 2 point totaliser output, before or at the current execution time
    ''' If time is 06:32 and the totaliser ends at 06:00:00 - return value at 06:00:00, OR if time is 06:00:00 and the totaliser ends at 06:00:00 - return value at 06:00:00
    ''' </summary>
    ''' <param name="ACETag">
    ''' The PIAcePoint of interest.
    ''' </param>
    ''' <param name="ExecTime">
    ''' The Execution time as PITime.
    ''' </param>
    ''' <param name="ACE2TotPeriod">
    ''' The period (in seconds as long) of the 2 point totlaiser been looked at - used for validation
    ''' </param>
    ''' <param name="Tol">
    ''' 2 point value match tolerance percent Abs((value1-value2)/Ave) less than or equal to Tol/100
    ''' </param>
    ''' <returns>
    ''' PI ace event with value  and time, or nothing if the data is bad or does not exist
    ''' </returns>
    ''' <remarks>
    ''' Warren: Was taken out of service on 2011-12-01
    ''' Note 2011-08-02 - Warren: should change this to use GetValueAtTime and feed in the start or end time of the Total
    ''' updated 2009-10-27 - reduced the time span to look  back, the the last totalisation period was bad the previous period was returned when it should not have been
    ''' Note from Elmer Botha 2009-07-13: Use this function rather than GetTotValue. GetTotalValue only accomodates totaliser tags
    ''' </remarks>
    Public Shared Function old_GetACE2TotValue(ByVal ACETag As PIACEPoint, ByVal ExecTime As PITime, ByVal ACE2TotPeriod As Long, ByVal Tol As Double) As PIACEEvent
        Dim whileLoopBreakLimit As Long = 100
        Dim Whilecount As Long = 0
        Dim While1count As Long = 0
        Dim events As PIACEEvent
        Dim TotEndTime As PITime = Nothing
        Dim TimeJump As Long = 1 ' time added to first lookup time - incase there is a value at the lookup time
        Dim TotAdd As Long = 1 ' time added to first totaliser time


        ' Get data at time
        events.Value = Nothing
        Try

            'get value but did not use TotTag.value(time) as the previous point is returned
            ' set time lookup to 1 second after the event tag. If there is a data point at the execution time (as there normally is for event calculations),
            ' the data point will be missed and the previous point returned.
            ' PreVal/Event returns the previous point even of there is a point at the time specified
            ' Need to minus clockdrift, the server adds the drift to the local machine time for data extraction
            ' Set the tag Clockoffset = false for the clock drift not to be factored in - work on local PC but not server. Therefore minuses clockdrift manually

            ' manually correct for clock drift as ACETag.AdjustClockOffset = False - did not work on the server
            Dim Addtime As String = CStr(System.Math.Abs(TimeJump - CDbl(ACETag.ClockDrift))) 'System.Math.Abs(TimeJump)
            If TimeJump - CDbl(ACETag.ClockDrift) >= 0 Then 'TimeJump >= 0 Then
                Addtime = "+" & Addtime & "s"
            Else
                Addtime = "-" & Addtime & "s"
            End If


            ' Must minus clock drift, therfore change sign
            Dim CDriftString As String = CStr(System.Math.Abs(CDbl(ACETag.ClockDrift)))
            If CDbl(ACETag.ClockDrift) >= 0 Then 'TimeJump >= 0 Then
                CDriftString = "-" & CDriftString & "s"
            Else
                CDriftString = "+" & CDriftString & "s"
            End If

            Dim CurrentEvnt As PIACEEvent = Nothing


            'Recurse back from current time
            'get first previous time and event to check
            Dim CurrentEvntTime As PITimeServer.PITime = ACETag.PrevEvent(ParseTime(Addtime, ExecTime.LocalDate.ToString))
            CurrentEvnt.Value = CStr(ACETag.PrevVal(ParseTime(Addtime, ExecTime.LocalDate.ToString)))

            'Check that run event looked at is less then 1 periods in the past otherwise no value
            While1count = 0
            While Math.Abs(ExecTime.UTCSeconds - CurrentEvntTime.UTCSeconds) <= ACE2TotPeriod
                ' time within 2 periods in the past

                ' If result is neumeric, check that there is a second value at - 1period +1s
                If IsNumeric(CurrentEvnt.Value) = True Then
                    Dim BackEvnt As PIACEEvent = Nothing
                    'if there is return value
                    'check return times
                    'find what the previous point fot the 2 value should be
                    Dim BackFindTime As PITimeServer.PITime = ParseTime(CurrentEvntTime.LocalDate.AddSeconds(TotAdd - ACE2TotPeriod).ToString)
                    'get the values at this time
                    Dim BackEvntTime As PITimeServer.PITime = ACETag.PrevEvent(ParseTime(Addtime, BackFindTime.LocalDate.ToString))
                    BackEvnt.Value = CStr(ACETag.PrevVal(ParseTime(Addtime, BackFindTime.LocalDate.ToString)))

                    Whilecount = 0
                    'less likly to go forward, put this firt so that the calc does not go back then forward
                    While BackFindTime.UTCSeconds > BackEvntTime.UTCSeconds And Math.Abs(BackFindTime.UTCSeconds - BackEvntTime.UTCSeconds) <= ACE2TotPeriod * 2
                        'get Next values
                        'find new value first, before getting new time
                        BackEvnt.Value = CStr(ACETag.NextVal(ParseTime(CDriftString, BackEvntTime.LocalDate.ToString)))
                        BackEvntTime = ACETag.NextEvent(ParseTime(CDriftString, BackEvntTime.LocalDate.ToString))
                        Whilecount += 1
                        If Whilecount > whileLoopBreakLimit Then Throw New Exception("while loop itteration limit reached = " & whileLoopBreakLimit)
                    End While

                    Whilecount = 0
                    While BackFindTime.UTCSeconds < BackEvntTime.UTCSeconds And Math.Abs(BackFindTime.UTCSeconds - BackEvntTime.UTCSeconds) <= ACE2TotPeriod * 2
                        'get previous values
                        'find new value first, before getting new time
                        BackEvnt.Value = CStr(ACETag.PrevVal(ParseTime(CDriftString, BackEvntTime.LocalDate.ToString)))
                        BackEvntTime = ACETag.PrevEvent(ParseTime(CDriftString, BackEvntTime.LocalDate.ToString))
                        Whilecount += 1
                        If Whilecount > whileLoopBreakLimit Then Throw New Exception("while loop itteration limit reached = " & whileLoopBreakLimit)
                    End While



                    ' fails is values are not nuemeric - exits while as there would be no result
                    Try
                        If BackFindTime.UTCSeconds = BackEvntTime.UTCSeconds Then

                            'check if values are nearly equal
                            Dim Valave As Double = (System.Convert.ToDouble(BackEvnt.Value) + System.Convert.ToDouble(CurrentEvnt.Value)) / 2
                            If Valave = 0 And CDbl(CurrentEvnt.Value) = 0 Then
                                'times match and values match
                                events.Value = CStr(ACETag.PrevVal(ParseTime(CDriftString, CurrentEvntTime.LocalDate.ToString))) ' 'get value at time
                                events.TimeStamp = CurrentEvntTime.UTCSeconds  'get event time
                                Exit While
                            ElseIf Math.Abs((System.Convert.ToDouble(BackEvnt.Value) - System.Convert.ToDouble(CurrentEvnt.Value)) / Valave) <= Tol / 100 Then
                                'times match and values match
                                events.Value = CStr(ACETag.PrevVal(ParseTime(CDriftString, CurrentEvntTime.LocalDate.ToString))) ' 'get value at time
                                events.TimeStamp = CurrentEvntTime.UTCSeconds  'get event time
                                Exit While
                            End If




                        End If
                    Catch ex As Exception
                        Exit While
                    End Try



                End If

                ' step time back to Previous event and check again
                'find new value first, before getting new time
                CurrentEvnt.Value = CStr(ACETag.PrevVal(ParseTime(CDriftString, CurrentEvntTime.LocalDate.ToString)))
                CurrentEvntTime = ACETag.PrevEvent(ParseTime(CDriftString, CurrentEvntTime.LocalDate.ToString))

                While1count += 1
                If While1count > whileLoopBreakLimit Then Throw New Exception("while loop itteration limit reached = " & whileLoopBreakLimit)
            End While

        Catch ex As Exception

        End Try


        Return events
    End Function

    ''' <summary>
    ''' Update 2019-05-15: retired calc as some totalisers and ACE/AF calculations now only output one value at the start of the period and not 2 values.
    ''' 
    ''' Gets the last finalised value of a 2 point totaliser period, before or at the current execution time
    ''' If a last finalised value does not exist in the last period, then nothing is returned
    ''' If time is 06:32 and the totaliser ends at 06:00:00 - return value at 06:00:00, OR if time is 06:00:00 and the totaliser ends at 06:00:00 - return value at 06:00:00
    ''' </summary>
    ''' <param name="ACETag">
    ''' The PIAcePoint of interest.
    ''' </param>
    ''' <param name="ExecTime">
    ''' The Execution time as PITime.
    ''' </param>
    ''' <param name="ACE2TotPeriod">
    ''' The period (in seconds as long) of the 2 point totlaiser been looked at - used for validation
    ''' </param>
    ''' <param name="Tol">
    ''' 2 point value match tolerance percent Abs((value1-value2)/Ave) less than or equal to Tol/100
    ''' </param>
    ''' <returns>
    ''' PI ace event with value  and time, or nothing if the data is bad or does not exist (no finalised value in the last period)
    ''' </returns>
    ''' <remarks>
    ''' Note 2011-12-01 Warren created
    ''' </remarks>
    Public Shared Function old_20190515_GetACE2TotValue(ByVal ACETag As PIACEPoint, ByVal ExecTime As PITime, ByVal ACE2TotPeriod As Long, ByVal Tol As Double) As PIACEEvent
        Dim ACEevent As PIACEEvent = Nothing
        Dim TimeJump As Long = 1 ' time added to first lookup time - incase there is a value at the lookup time
        Dim TotAdd As Long = 1 ' time added to first totaliser time
        Dim TimeRoundPlaces As Integer = 2
        Dim MatchTime As Double = Double.NaN

        'get last good event
        'get values in 2 periods
        'find and validate last item



        Try
            ' Get last event
            'Dim CurrentEvntTime As PITimeServer.PITime = ACETag.PrevEvent(ExecTime)

            ' Get events for 2 periods
            Dim _PIValues As PIValues = ACETag.Values(ExecTime.LocalDate, ExecTime.LocalDate.AddSeconds(-ACE2TotPeriod), BoundaryTypeConstants.btOutside)

            'loop through events and write good values to a Dictionary

            Dim Events As Dictionary(Of Double, Object) = New Dictionary(Of Double, Object)


            For Each _PIval As PIValue In _PIValues
                'only look at value that are good and are before the execution time
                If _PIval.TimeStamp.UTCSeconds < ExecTime.UTCSeconds And _PIval.IsGood Then
                    ' onlt add first of multiple events at one time
                    If Not Events.ContainsKey(Math.Round(_PIval.TimeStamp.UTCSeconds, TimeRoundPlaces)) Then Events.Add(Math.Round(_PIval.TimeStamp.UTCSeconds, TimeRoundPlaces), _PIval.Value)
                End If

            Next

            'No good values
            If Events.Count = 0 Then Return Nothing

            'find event pairs based on time
            'Dim EventPairList As Dictionary(Of Double, Object) = New Dictionary(Of Double, Object)

            For Each eKey As Double In Events.Keys
                Dim TotStartTime As Double = eKey - ACE2TotPeriod + TotAdd

                If Events.ContainsKey(TotStartTime) Then
                    'Time match was found

                    'check values match
                    If IsNumeric(Events(eKey)) Then

                        Dim Vals As Double = Double.NaN
                        Dim Vale As Double = Double.NaN
                        Dim Valav As Double = Double.NaN

                        If Double.TryParse(Events(TotStartTime).ToString, Vals) And Double.TryParse(Events(eKey).ToString, Vale) Then
                            Valav = (Vals + Vale) / 2

                            If Valav = 0 And Vals = 0 Then
                                'values match
                                MatchTime = eKey
                            ElseIf Math.Abs((Vals - Vale) / Valav) <= Tol / 100 Then
                                'values within tol
                                MatchTime = eKey
                            End If

                        Else
                            Return Nothing
                        End If

                        Exit For
                    ElseIf IsDate(Events(eKey)) Then
                        Dim Vals As DateTime
                        Dim Vale As DateTime

                        If DateTime.TryParse(Events(TotStartTime).ToString, Vals) And DateTime.TryParse(Events(eKey).ToString, Vale) Then

                            If Math.Abs(Vale.Subtract(Vale).TotalSeconds) < 0.25 Then
                                'values within tol
                                MatchTime = eKey
                            End If

                        End If

                        MatchTime = eKey
                        Exit For
                    Else
                        If Events(eKey).ToString = Events(TotStartTime).ToString Then
                            MatchTime = eKey
                        End If
                        Exit For
                    End If



                    Exit For

                End If



            Next


            If Not Double.IsNaN(MatchTime) Then
                ' A match was found find Event to return
                For Each PiVal As PIValue In _PIValues
                    If Math.Round(PiVal.TimeStamp.UTCSeconds, TimeRoundPlaces) = MatchTime Then
                        ACEevent.TimeStamp = PiVal.TimeStamp.UTCSeconds
                        ACEevent.Value = PiVal.Value.ToString
                        Return ACEevent
                    End If
                Next

            Else
                Return Nothing
            End If

        Catch ex As Exception
            Return Nothing
        End Try


        Return ACEevent



    End Function
    ''' <summary>
    ''' Recurses back to get the last good (Neumeric) data event in the database
    ''' </summary>
    ''' <param name="Tag">
    ''' The PIAcePoint of interest - needs to be an floating point or integer.
    ''' </param>
    ''' <param name="CurTime">
    ''' The Execution time as PITime.
    ''' </param>
    ''' <returns>
    ''' Last good event as PIACEEvent in the database = nothing if non exists
    ''' </returns>
    ''' <remarks>
    ''' updated 2009-11-02 10:30
    ''' re-writen 2013-05-03 more effiecent method
    ''' </remarks>
    Public Shared Function GetLastGood_Num(ByVal Tag As PIACEPoint, ByVal CurTime As PITime) As PIACEEvent
         Dim point As New PIACEEvent

        Try


            Dim _PISDK As New PISDK.PISDK
            Dim piPoint As PISDK.PIPoint


            piPoint = _PISDK.GetPoint("\\" & Tag.Server & "\" & Tag.Tag)
            Dim filtstring As String = "BadVal('" & Tag.Tag & "') = 0"

            'get first set of values
            Dim piVals As PIValues = piPoint.Data.RecordedValuesByCount(CurTime, 2, DirectionConstants.dReverse, BoundaryTypeConstants.btInside, filtstring, FilteredViewConstants.fvRemoveFiltered)


            If piVals.Count > 0 Then

                Dim itemindex As Integer = 1

                If piVals(itemindex).TimeStamp.UTCSeconds = CurTime.UTCSeconds Then itemindex = 2
                'Get next value is there is a value at the first time

                Dim res As Double = Double.NaN

                If Double.TryParse(piVals(itemindex).Value.ToString(), res) Then
                    point.TimeStamp = piVals(itemindex).TimeStamp.UTCSeconds
                    point.Value = piVals(itemindex).Value.ToString()
                Else
                    point = Nothing
                End If


            Else
                point = Nothing
            End If


        Catch ex As Exception

            point = Nothing


        End Try


        Return point

    End Function
    ''' <summary>
    ''' Recurses back to get the last good data event in the historian
    ''' </summary>
    ''' <param name="Tag">
    ''' The PIAcePoint of interest.
    ''' </param>
    ''' <param name="CurTime">
    ''' The Execution time as PITime.
    ''' </param>
    ''' <returns>
    ''' Last good event as PIACEEvent in the database = nothing if non exists
    ''' </returns>
    ''' <remarks>
    ''' updated 2010-06-17 15:24
    ''' re-writen 2013-05-03 Isgood(time) function was failing, chnaged to use pisdk to get compressed datab with a filter
    ''' </remarks>
    Public Shared Function GetLastGood(ByVal Tag As PIACEPoint, ByVal CurTime As PITime) As PIACEEvent

        Dim point As New PIACEEvent



        Try

            'Tag.


            Dim _PISDK As New PISDK.PISDK
            Dim piPoint As PISDK.PIPoint


            piPoint = _PISDK.GetPoint("\\" & Tag.Server & "\" & Tag.Tag)
            Dim filtstring As String = "BadVal('" & Tag.Tag & "') = 0"

            'get first set of values
            Dim piVals As PIValues = piPoint.Data.RecordedValuesByCount(CurTime, 2, DirectionConstants.dReverse, BoundaryTypeConstants.btInside, filtstring, FilteredViewConstants.fvRemoveFiltered)


            If piVals.Count > 0 Then
                Dim itemindex As Integer = 1

                If piVals(itemindex).TimeStamp.UTCSeconds = CurTime.UTCSeconds Then itemindex = 2
                'Get next value is there is a value at the first time

                point.TimeStamp = piVals(itemindex).TimeStamp.UTCSeconds

                'type conversion
                Dim valtype As Type = piVals(itemindex).Value.GetType


                Select Case piPoint.PointType
                    Case PointTypeConstants.pttypDigital
                        point.Value = CType(piVals(itemindex).Value, PISDK.DigitalState).Name.ToString()

                    Case PointTypeConstants.pttypTimestamp
                        point.Value = CType(piVals(itemindex).Value, PITimeServer.PITime).LocalDate.ToString
                    Case Else
                        point.Value = piVals(itemindex).Value.ToString()
                End Select


            Else
                point = Nothing
            End If





        Catch ex As Exception

            point = Nothing


        End Try

        Return point

    End Function
    ''' <remarks>
    ''' <summary>
    ''' Recurses forward to get the first good (Neumeric) data event in the database
    ''' </summary>
    ''' <param name="Tag">
    ''' The PIAcePoint of interest.
    ''' </param>
    ''' <param name="CurTime">
    ''' The Execution time as PITime.
    ''' </param>
    ''' <returns>
    ''' Next good PIACEEvent in the database = nothing if non exists
    ''' </returns>
    ''' updated 2009-03-31 10:30
    ''' re-writen 2013-05-03 more effiecent method
    ''' </remarks>
    Public Shared Function GetNextGood_Num(ByVal Tag As PIACEPoint, ByVal CurTime As PITime) As PIACEEvent
        Dim point As New PIACEEvent

        Try

            'Tag.


            Dim _PISDK As New PISDK.PISDK
            Dim piPoint As PISDK.PIPoint


            piPoint = _PISDK.GetPoint("\\" & Tag.Server & "\" & Tag.Tag)
            Dim filtstring As String = "BadVal('" & Tag.Tag & "') = 0"

            'get first set of values
            Dim piVals As PIValues = piPoint.Data.RecordedValuesByCount(CurTime, 2, DirectionConstants.dForward, BoundaryTypeConstants.btInside, filtstring, FilteredViewConstants.fvRemoveFiltered)


            If piVals.Count > 0 Then
                Dim itemindex As Integer = 1
                If piVals(itemindex).TimeStamp.UTCSeconds = CurTime.UTCSeconds Then itemindex = 2
                'Get next value is there is a value at the first time

                Dim res As Double = Double.NaN

                If Double.TryParse(piVals(itemindex).Value.ToString(), res) Then
                    point.TimeStamp = piVals(itemindex).TimeStamp.UTCSeconds
                    point.Value = piVals(itemindex).Value.ToString()
                Else
                    point = Nothing
                End If


            Else
                point = Nothing
            End If


        Catch ex As Exception

            point = Nothing


        End Try


        Return point

    End Function
    ''' <remarks>
    ''' <summary>
    ''' Recurses forward to get the first good data event in the database
    ''' </summary>
    ''' <param name="Tag">
    ''' The PIAcePoint of interest.
    ''' </param>
    ''' <param name="CurTime">
    ''' The Execution time as PITime.
    ''' </param>
    ''' <returns>
    ''' Next good PIACEEvent in the database = nothing if non exists
    ''' </returns>
    ''' updated 2010-06-17 15:24
    ''' re-writen 2013-05-03 Isgood(time) function was failing, chnaged to use pisdk to get compressed datab with a filter
    ''' </remarks>
    Public Shared Function GetNextGood(ByVal Tag As PIACEPoint, ByVal CurTime As PITime) As PIACEEvent

        Dim point As New PIACEEvent

        Try

            'Tag.


            Dim _PISDK As New PISDK.PISDK
            Dim piPoint As PISDK.PIPoint


            piPoint = _PISDK.GetPoint("\\" & Tag.Server & "\" & Tag.Tag)
            Dim filtstring As String = "BadVal('" & Tag.Tag & "') = 0"

            'get first set of values
            Dim piVals As PIValues = piPoint.Data.RecordedValuesByCount(CurTime, 2, DirectionConstants.dForward, BoundaryTypeConstants.btInside, filtstring, FilteredViewConstants.fvRemoveFiltered)


            If piVals.Count > 0 Then
                Dim itemindex As Integer = 1
                If piVals(itemindex).TimeStamp.UTCSeconds = CurTime.UTCSeconds Then itemindex = 2
                'Get next value is there is a value at the first time

                point.TimeStamp = piVals(itemindex).TimeStamp.UTCSeconds

                'type conversion
                Dim valtype As Type = piVals(itemindex).Value.GetType

                Dim b7 As Double = 7

                Select Case piPoint.PointType
                    Case PointTypeConstants.pttypDigital
                        point.Value = CType(piVals(itemindex).Value, PISDK.DigitalState).Name.ToString()

                    Case PointTypeConstants.pttypTimestamp
                        point.Value = CType(piVals(itemindex).Value, PITimeServer.PITime).LocalDate.ToString
                    Case Else
                        point.Value = piVals(itemindex).Value.ToString()
                End Select


            Else
                point = Nothing
            End If


        Catch ex As Exception

            point = Nothing


        End Try


        Return point

    End Function

    ''' <summary>
    ''' Generates two dates, the first of which is 1 second into the start of the totalisation period and the second is at the end of the totalisation period
    ''' eg. GenerateTotPeriodDates(24 feb 05:00:01, 86400, 18000) yields 23 feb 05:00:01 and 24 feb 05:00:00
    ''' eg. GenerateTotPeriodDates(24 feb 05:00:01, 3600, 0) yields 24 feb 04:00:01 and 24 feb 05:00:00
    ''' The dates returned are for the first totalisation period that has closed (finalised) before the given date time 
    ''' </summary>
    ''' <param name="ExecTime">
    ''' current/exicution time as pi time
    ''' </param>
    ''' <param name="TotPeriod">
    ''' The totalisation period in seconds as long = seconds between each totalisation period, 24 hrs = 86400
    ''' </param>
    ''' <param name="TotOffset">
    ''' The offset of the totalisation period in seconds as long, 5 am = 18000
    ''' </param>
    ''' <returns>
    ''' DateTime array of: index 0 = time at 1 second into the start of the period and index 1 = time at the end of the period.
    ''' </returns>
    ''' <remarks>
    ''' updated 2009-03-31 10:30
    ''' </remarks>
    Public Shared Function GenerateTotPeriodDates(ByVal ExecTime As PITime, ByVal TotPeriod As Long, ByVal TotOffset As Long) As DateTime()
        'Generate relevant datetimes
        Dim first_date, second_date As DateTime


        Try
            Dim ExecTime_UTC As Long = CLng(ParseTime(ParseTime(ExecTime.LocalDate.ToString).LocalDate.ToLocalTime.ToString).UTCSeconds) ' to compensate for time zone adjustments when using universal time
            ' this gets the local date as seconds past 1 Jan 1970 00:00:00

            ' compensate for time zone adjustments before finding dates
            Dim ModTime As Long
            'get the remainder of the current time less the offset and the period
            System.Math.DivRem(ExecTime_UTC - TotOffset, TotPeriod, ModTime)

            second_date = ParseTime(CStr(ExecTime_UTC - ModTime)).LocalDate.ToUniversalTime ' to compensate for time zone adjustments when using universal time

            first_date = second_date.AddSeconds(-TotPeriod).AddSeconds(1) ' less period and add 1 second
            Dim dates As DateTime() = {first_date, second_date}
            Return dates

        Catch ex As Exception
            'It's stuffed - just give up already...
            Throw New Exception("Fundamental date calculation failed.")
        End Try
    End Function
    ''' <summary>
    ''' Value interpolated at the time given, numeric values only
    ''' </summary>
    ''' <param name="Tag">
    ''' The PIAcePoint of interest.
    ''' </param>
    ''' <param name="CurTime">
    ''' The Execution time as PItime.
    ''' </param>
    ''' <returns>
    ''' PIACE event of the interpolated value; = nothing if non exists
    ''' </returns>
    ''' <remarks>
    ''' updated 2009-11-02 Is numeric check on result
    ''' </remarks>
    Public Shared Function IterpolatedVal(ByVal Tag As PIACEPoint, ByVal CurTime As PITime) As PIACEEvent

        Dim Val As PIACEEvent = Nothing

        Try
            Dim Ev1 As PIACEEvent = GetLastGood(Tag, ParseTime(CurTime.LocalDate.ToString)) ' incase there is a value at the current time
            Dim Ev2 As PIACEEvent = GetNextGood(Tag, CurTime)

            If Ev1.Value Is Nothing = False And Ev1.Value Is Nothing = False Then
                If System.Math.Round(Ev1.TimeStamp, 3) = System.Math.Round(CurTime.UTCSeconds, 3) Then ' there was a value at the requested timestamp

                    Val = Ev1
                Else
                    Val.Value = System.Convert.ToString(CDbl(Ev1.Value) + (CDbl(Ev2.Value) - CDbl(Ev1.Value)) / (Ev2.TimeStamp - Ev1.TimeStamp) * (CurTime.UTCSeconds - Ev1.TimeStamp))

                    Val.TimeStamp = CurTime.UTCSeconds

                    If IsNumeric(Val.Value) = False Then Throw New Exception("Not numeric")
                End If
            End If
        Catch ex As Exception
            Val = Nothing
        End Try

        Return Val

    End Function








    ''' Returns a pivalue at the specified time, if there is no value then nothing is returned
    ''' </summary>
    ''' <param name="PItag"></param>
    ''' <param name="Time"></param>
    ''' <param name="TimeTol">
    ''' time tolerance will match a value if the time is within the tolerence Abs(valuetime - required time) less than timetol</param>
    ''' <returns> a PI Value</returns>
    ''' <remarks></remarks>
    Public Shared Function PIValAtTime(PItag As PIACEPoint, Time As PITime, TimeTol As Double) As PIValue

        Dim retVal As PIValue = Nothing '= New PIValue
        'Dim retRes As CalcResult = New CalcResult(Double.NaN, ValueAction.Val_MarkBad)

        Dim Vals As PIValues = PItag.Values(Time.UTCSeconds - 10, Time.UTCSeconds + 10) '.AddHours(-1), endDate.AddHours(1))


        For Each val As PIValue In Vals

            If System.Math.Abs(val.TimeStamp.UTCSeconds - Time.UTCSeconds) < TimeTol Then ' values are withing 0.5 of a second

                retVal = val


                Exit For
            End If

            'End If

        Next

        Return retVal


    End Function


End Class
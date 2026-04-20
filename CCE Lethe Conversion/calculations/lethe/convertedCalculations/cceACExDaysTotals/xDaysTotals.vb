Imports OSIsoft.PI.ACE
'Imports PIACECommon
'Imports PIACE
Imports OSIsoft.PI.ACE.PIACEBIFunctions

Imports PISDK
Imports PITimeServer
'Imports xDaysTotal.StreamDataDomainServiceData.StreamDataDomainServiceData
Imports System.Net
'Imports System.Collections
Imports System.Linq

Namespace xDaysTotal
    Public Class xDaysTotalClass

        Public Function runCalc(ExeTime As Double, CalcPath As String) As Double
            'NB NB NB NB NB NB NB NB NB NB NB
            'NB check/update the streammapper server in the service referance

            Dim TestWriteOut As Boolean = False
            Dim CheckZeroAndSpan As Boolean = False
            Dim WriteOutHour As Integer = 6

            Dim ExecTime As Double = ExeTime

            Dim ExecPitime As PITime = New PITime()
            ExecPitime.UTCSeconds = ExecTime

            'RecalculateItems
            Dim Recalc As Boolean = False
            Dim reBatchsize As Integer = 0
            Dim reStartDate As DateTime = Now
            Dim reEndDate As DateTime = reStartDate

            'for testing
            'ExecPitime.LocalDate = Convert.ToDateTime("2013-01-17 07:00:00")
            Dim Start_date, End_date As DateTime


            Dim ODataService As String
            Dim ODataMethod As String
            Dim ODataParameter As String
            Dim cODataParameter As String

            Dim DaysBack As Double = 0
            Dim DaysToCalc As Double = 1

            Dim p_CurModule As PIModule = PIACEBIFunctions.GetPIModuleFromPath(CalcPath)

            Try




                LogPIACEMessage(MessageLevel.mlErrors, "#&* SM run. Current Time: - " & Now.ToString & " Execution Time: - " & ExecPitime.LocalDate.ToString(), CalcPath)

                Try


                    ODataService = p_CurModule.ParentList(1).PIProperties("Configuration-OdataService").Value.ToString()
                    ODataMethod = p_CurModule.ParentList(1).PIProperties("Configuration-ODataMethod").Value.ToString()
                    ODataParameter = p_CurModule.ParentList(1).PIProperties("Configuration-OdataParameters").Value.ToString()
                    cODataParameter = ODataParameter

                    DaysBack = Convert.ToDouble(p_CurModule.PIProperties("DaysBack").Value)
                    DaysToCalc = Convert.ToDouble(p_CurModule.PIProperties("DaysToCalc").Value)

                    Recalc = Convert.ToBoolean(p_CurModule.PIProperties("BackCalculate").Value)

                    If Recalc Then
                        reBatchsize = Convert.ToInt32(p_CurModule.PIProperties("BackCalculate").PIProperties("Batchsize").Value)
                        reStartDate = Convert.ToDateTime(p_CurModule.PIProperties("BackCalculate").PIProperties("StartDate").Value)
                        reEndDate = Convert.ToDateTime(p_CurModule.PIProperties("BackCalculate").PIProperties("EndDate").Value)
                        ' reset Recalc
                        p_CurModule.PIProperties("BackCalculate").Value = False

                    End If


                Catch ex As Exception
                    LogPIACEMessage(OSIsoft.PI.ACE.MessageLevel.mlErrors, "#&* SM error. Error Loading Configuration String.  Current Time: - " & Now.ToString & " Execution Time: - " & ExecPitime.LocalDate.ToString() & " -error: " & ex.Message.ToString, CalcPath)
                    Throw New Exception("Error loading config" & ex.Message)

                End Try


                Try

                    'loop through date batches
                    Dim reDaysRun As Integer = 0
                    Dim reLoops As Integer = 1
                    If Recalc Then

                        If reEndDate > Now Or reStartDate > Now Then
                            Throw New Exception("EndDate or StartDate greater then today")
                        End If
                        reDaysRun = CInt((reEndDate.Date - reStartDate.Date).TotalDays)
                        reLoops = CInt(Math.Ceiling(reDaysRun / reBatchsize))
                        'set end date - gets updated on first run
                        End_date = reStartDate.Date + New TimeSpan(WriteOutHour, 0, 0)
                        ' End_date = reStartDate.AddDays(reBatchsize)
                    End If

                    For dl = 1 To reLoops
                        'recalculation loops



                        'Set dates
                        If Recalc Then
                            'recalculating set dates
                            Start_date = End_date
                            End_date = Start_date.AddDays(reBatchsize)
                            If End_date.Date > reEndDate.Date Then
                                End_date = reEndDate.Date + New TimeSpan(WriteOutHour, 0, 0)
                            End If

                        Else
                            ' not recalculating set normal dates
                            Dim dates As DateTime() = CommonFunctions.GenerateTotPeriodDates(ExecPitime, 86400, WriteOutHour * 3600)
                            End_date = dates(1).AddDays(DaysBack)
                            Start_date = End_date.AddDays(-DaysToCalc)
                        End If

                        'substitute dates into parameters
                        cODataParameter = ODataParameter.Replace("#StartDate#", Start_date.ToString())
                        cODataParameter = cODataParameter.Replace("#EndDate#", End_date.ToString())

                        If ODataParameter.Contains("#StartLot#") Then
                            ' convert dates to lot
                            Dim sLot As Int32 = Start_date.Year * 1000 + Start_date.DayOfYear
                            Dim eLot As Int32 = End_date.Year * 1000 + End_date.DayOfYear
                            cODataParameter = cODataParameter.Replace("#StartLot#", sLot.ToString())
                            cODataParameter = cODataParameter.Replace("#EndLot#", eLot.ToString())
                        End If

                        Dim queryURI As System.Uri = New System.Uri(ODataService & ODataMethod & cODataParameter)
                        Dim StreamMapper As StreamDataDomainServiceData.StreamDataDomainServiceData = New StreamDataDomainServiceData.StreamDataDomainServiceData(New System.Uri(ODataService))
                        'NB check/update the streammapper server in the service referance

                        'StreamMapper.Credentials = New NetworkCredential("user", "pw", "angloiit.net") 'New System.Net.CredentialCache(New NetworkCredential("", ""))


                        Dim credentials As ICredentials = CredentialCache.DefaultCredentials
                        Dim currCred As NetworkCredential = credentials.GetCredential(queryURI, "Windows")
                        StreamMapper.Credentials = currCred


                        Dim _PISDK As PISDK.PISDK = New PISDK.PISDK





                        Dim resultList As List(Of StreamDataDomainServiceData.StreamTotal) = StreamMapper.Execute(Of StreamDataDomainServiceData.StreamTotal)(queryURI).ToList
                        'List of tags
                        Dim Taglist As IEnumerable(Of String) = (From Res In resultList Select Res.PITag).Distinct()

                        For Each cTag As String In Taglist

                            Try

                                If Not String.IsNullOrEmpty(cTag) Then

                                    Dim testTag As String = "\\devpi.angloiit.net\CCE.ReceiptsHourly.WriteOutTest"
                                    Dim testPiTag As PIPoint = _PISDK.GetPoint(testTag)

                                    Dim stTag As String = cTag
                                    ' get all results for tag
                                    Dim TagResultList As List(Of StreamDataDomainServiceData.StreamTotal) = (From R In resultList Where R.PITag = stTag).ToList

                                    Dim piTag As PIPoint = _PISDK.GetPoint(cTag)
                                    Dim nPIValues As PIValues = New PIValues
                                    nPIValues.ReadOnly = False

                                    For Each Stot As StreamDataDomainServiceData.StreamTotal In TagResultList

                                        Dim FirstDate As DateTime = Stot.Day.Date.AddHours(WriteOutHour)
                                        Dim SecondDate As DateTime = FirstDate.AddDays(1)
                                        FirstDate = FirstDate.AddSeconds(1)

                                        'If Not String.IsNullOrEmpty(Stot.Message) Then
                                        'LogPIACEMessage(OSIsoft.PI.ACE.MessageLevel.mlErrors, "#&* SM return message.  Current Time: - " & Now.ToString & " Execution Time: - " & ExecPitime.LocalDate.ToString() & " -message: " & Stot.Message.ToString, MyBase.Context)
                                        'End If

                                        Dim nPIval1 As PIValue = New PIValue
                                        Dim nP1Time As PITime = New PITime()
                                        nP1Time.LocalDate = FirstDate
                                        nPIval1.TimeStamp = nP1Time
                                        nPIval1.Value = Stot.Result

                                        '20181113 remove second value - OM and to conform to Analysis format
                                        'Dim nPIval2 As PIValue = New PIValue



                                        'Dim nP2Time As PITime = New PITime()
                                        'nP2Time.LocalDate = SecondDate
                                        'nPIval2.TimeStamp = nP2Time
                                        'nPIval2.Value = Stot.Result

                                        nPIValues.Insert(nPIval1)
                                        ' nPIValues.Insert(nPIval2)

                                    Next

                                    LogPIACEMessage(OSIsoft.PI.ACE.MessageLevel.mlErrors, "Writing " & nPIValues.Count.ToString & " values to pi Tag: " & cTag, CalcPath)

                                    Dim wErrs As PISDKCommon.PIErrors = New PISDKCommon.PIErrors

                                    'Writeout all values to Tag
                                    wErrs = piTag.Data.UpdateValues(nPIValues, DataMergeConstants.dmReplaceDuplicates)

                                    'Clear values
                                    nPIValues = Nothing

                                    For Each Err As PISDKCommon.PIError In wErrs
                                        LogPIACEMessage(OSIsoft.PI.ACE.MessageLevel.mlErrors, "#&* SM value write error. Write data To Pi.  Current Time: - " & Now.ToString & " Execution Time: - " & ExecPitime.LocalDate.ToString() & " -error: " & Err.Description & " -Cause: " & Err.Cause.ToString() & " -Source: " & Err.Source, CalcPath)
                                    Next

                                    'Writeout all values to Test Tag
                                    wErrs = testPiTag.Data.UpdateValues(nPIValues, DataMergeConstants.dmReplaceDuplicates)

                                    'If piTag.Name = "WVS:ACE:DailyIn.DM.InFeed" Then
                                    'CommonFunctions.UpdateViaPISDDKWithCheck(piTag, Stot.Result, FirstDate, TestWriteOut, CheckZeroAndSpan, SecondDate)
                                    'End If




                                End If
                            Catch ex As Exception
                                LogPIACEMessage(OSIsoft.PI.ACE.MessageLevel.mlErrors, "#&* SM error. Write data To Pi.  Current Time: - " & Now.ToString & " Execution Time: - " & ExecPitime.LocalDate.ToString() & " -error: " & ex.Message.ToString, CalcPath)
                            End Try


                        Next

                        ' dl += 1
                        'For Each Stot As StreamDataDomainServiceData.StreamTotal In StreamMapper.Execute(Of StreamDataDomainServiceData.StreamTotal)(queryURI)

                        '    Try

                        '        If Not String.IsNullOrEmpty(Stot.PITag) Then

                        '            Dim piTag As PIPoint = _PISDK.GetPoint(Stot.PITag)
                        '            Dim FirstDate As DateTime = Stot.Day.Date.AddHours(WriteOutHour)
                        '            Dim SecondDate As DateTime = FirstDate.AddDays(1)
                        '            FirstDate = FirstDate.AddSeconds(1)

                        '            'If Not String.IsNullOrEmpty(Stot.Message) Then
                        '            'LogPIACEMessage(OSIsoft.PI.ACE.MessageLevel.mlErrors, "#&* SM return message.  Current Time: - " & Now.ToString & " Execution Time: - " & ExecPitime.LocalDate.ToString() & " -message: " & Stot.Message.ToString, MyBase.Context)
                        '            'End If


                        '            Dim nPIval As PIValue = New PIValue
                        '            'Dim fd As PITime = PITimeServer
                        '            'fd.
                        '            nPIval.TimeStamp.LocalDate = FirstDate
                        '            nPIval.Value = Stot.Result


                        '            'If piTag.Name = "WVS:ACE:DailyIn.DM.InFeed" Then
                        '            CommonFunctions.UpdateViaPISDDKWithCheck(piTag, Stot.Result, FirstDate, TestWriteOut, CheckZeroAndSpan, SecondDate)
                        '            'End If




                        '        End If
                        '    Catch ex As Exception
                        '        LogPIACEMessage(OSIsoft.PI.ACE.MessageLevel.mlErrors, "#&* SM error. Write data To Pi.  Current Time: - " & Now.ToString & " Execution Time: - " & ExecPitime.LocalDate.ToString() & " -error: " & ex.Message.ToString, MyBase.Context)
                        '    End Try

                        'Next
                    Next

                    'Write out run success to run tag

                    Return 1

                Catch ex As Exception
                    LogPIACEMessage(OSIsoft.PI.ACE.MessageLevel.mlErrors, "#&* SM error. Error running Calculation.  Current Time: - " & Now.ToString & " -error: " & ex.Message.ToString, CalcPath)
                    Return 0
                    Throw New Exception("Error running Calc" & ex.Message)
                End Try

            Catch ex As Exception
                LogPIACEMessage(OSIsoft.PI.ACE.MessageLevel.mlErrors, "#&* SM error. General.  Current Time: - " & Now.ToString & " -error: " & ex.Message.ToString, CalcPath)
                'p_CurModule.PIProperties("ErrorMessage").Value = Now.ToString + ex.Message
                Throw New Exception("Error running Calc" & ex.Message) 'Remove 
                Return 0
            End Try
        End Function

    End Class

End Namespace


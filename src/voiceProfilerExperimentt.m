function varargout = voiceProfilerExperimentt(varargin)
% VOICEPROFILEREXPERIMENTT MATLAB code for voiceProfilerExperimentt.fig
%      VOICEPROFILEREXPERIMENTT, by itself, creates a new VOICEPROFILEREXPERIMENTT or raises the existing
%      singleton*.
%
%      H = VOICEPROFILEREXPERIMENTT returns the handle to a new VOICEPROFILEREXPERIMENTT or the handle to
%      the existing singleton*.
%
%      VOICEPROFILEREXPERIMENTT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VOICEPROFILEREXPERIMENTT.M with the given input arguments.
%
%      VOICEPROFILEREXPERIMENTT('Property','Value',...) creates a new VOICEPROFILEREXPERIMENTT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before voiceProfilerExperimentt_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to voiceProfilerExperimentt_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help voiceProfilerExperimentt

% Last Modified by GUIDE v2.5 26-Oct-2019 11:33:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @voiceProfilerExperimentt_OpeningFcn, ...
    'gui_OutputFcn',  @voiceProfilerExperimentt_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end


% --- Executes just before voiceProfilerExperimentt is made visible.
function voiceProfilerExperimentt_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to voiceProfilerExperimentt (see VARARGIN)

% Choose default command line output for voiceProfilerExperimentt
handles.output = hObject;
handles = setDefaults(handles);
handles = initializeGUI(handles);

%--- audio input preparation
handles.recordObj1 = audiorecorder(handles.baseParameters.samplingFrequency,24,1);
set(handles.recordObj1,'TimerPeriod',handles.recorderTimerInterval, ...
    'TimerFcn', @recorderTimerFcn, 'userdata', handles);
set(handles.counterTxt, 'String', num2str(handles.audioRecorderCount));
guidata(hObject, handles);
%--- audio output preparation

%--- timer function to update level display
timerForLevelAxis = timer('TimerFcn',@levelDisplayTimerFcn,'ExecutionMode','singleshot', ...
    'userData',handles);
handles.timerForLevelAxis = timerForLevelAxis;


% Update handles structure
guidata(hObject, handles);

%--- GUI element setting
set(handles.eggLevelAxis, 'visible', 'off');
set(handles.eggIndicatorHandle, 'visible', 'off');
set(handles.eggHandle, 'visible', 'off');

%--- start GUI
handles.recordingMode = 'calibration';
set(handles.recordObj1, 'userdata', handles);
record(handles.recordObj1);

% UIWAIT makes voiceProfilerExperimentt wait for user response (see UIRESUME)
% uiwait(handles.voiceAttributeGUI);
end


% --- Outputs from this function are returned to the command line.
function varargout = voiceProfilerExperimentt_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

%--- private functions
function levelDisplayTimerFcn(hObject, event, handles)
handlesLvl = get(hObject, 'userdata');
handles = get(handlesLvl.recordObj1, 'userdata');
fs = handles.samplingFrequency;
peakCheckBuffer = handles.recordingBuffer(max(1, (handles.lastPoint - fs:handles.lastPoint)));
set(handles.splIndicatorHandle, 'ydata', 20 * log10(max(abs(peakCheckBuffer))) * [1 1]);
rmsCheckBuffer = handles.recordingBuffer(max(1, (handles.lastPoint - round(fs * 0.125):handles.lastPoint)));
set(handles.barHandle, 'ydata', [20 * log10(std(rmsCheckBuffer)) * [1 1] -100 -100]);
distance = str2double(get(handles.micDistTxt, 'string'));%, num2str(disance));
gainCorrection = 20 * log10(distance / 30);
calibratedSPL = 20 * log10(std(rmsCheckBuffer)) + handles.calibCoeff + gainCorrection;
set(handles.splIndicatorCalHandle, 'ydata', calibratedSPL * [1 1] + 1);
set(handles.splCrossHair, 'ydata', calibratedSPL * [1 1]);
output = sourceAttributesAnalysis(rmsCheckBuffer, fs, [1 length(rmsCheckBuffer)], ...
    handles.initialStruct);
cdata = get(handles.profileHandle, 'cdata');
[nn, mm] = size(cdata);
dispMap = cdata;
contents = cellstr(get(handles.attributeMenu,'String'));
dispMode = contents{get(handles.attributeMenu,'Value')};
fLow = handlesLvl.baseParameters.fLow;
fcList = handlesLvl.baseParameters.fcList;
sgOrgS = stftSpectrogramStructure(rmsCheckBuffer,fs,60,5,'blackman');
txx = sgOrgS.temporalPositions;
pwrDb = 10 * log10(sum(sgOrgS.rawSpectrogram(:, txx >= 0.028 & txx <= 0.125 - 0.028)'));
pwrRaw = sum(sgOrgS.rawSpectrogram(:, txx >= 0.028 & txx <= 0.125 - 0.028)');
h1 = 0; h2 = 0;
deltaF = sgOrgS.frequencyAxis(2);
fx = sgOrgS.frequencyAxis;
if sum(output.fixed_points_measure(:, 1) > 15) > 30
    mes = output.fixed_points_measure(:, 1);
    rawFo = output.fixed_points_freq(:, 1);
    avfo = mean(rawFo(mes > 15));
    avMes = min(50, mean(mes(mes > 15)));
    freqID = round(12 * log2(avfo / fLow)) + 1;
    splID = round((calibratedSPL - 30) / 2) + 1;
    h1 = pwrDb(round(avfo / deltaF) + 1);
    h2 = pwrDb(round(2 * avfo / deltaF) + 1);
    h1p = 10 * log10(sum(pwrRaw(fx > avfo/sqrt(2) & fx < avfo*sqrt(2))));
    sngfp = 10 * log10(sum(pwrRaw(fx > 2000 & fx < 5000)));
    currentCount = 0;
    switch get(handles.calibratedText, 'visible')
        case 'on'
            if freqID >= 1 && freqID <= mm && splID >= 1 && splID <= nn
                handlesLvl.baseParameters.counterMap(splID, freqID) = ...
                    handlesLvl.baseParameters.counterMap(splID, freqID) + 1;
                currentCount = handlesLvl.baseParameters.counterMap(splID, freqID);
                handlesLvl.baseParameters.snrMap(splID, freqID) = ...
                    handlesLvl.baseParameters.snrMap(splID, freqID) + avMes;
                handlesLvl.baseParameters.h2h1Map(splID, freqID) = ...
                    handlesLvl.baseParameters.h2h1Map(splID, freqID) + h2 - h1;
                handlesLvl.baseParameters.singFrmntMap(splID, freqID) = ...
                    handlesLvl.baseParameters.singFrmntMap(splID, freqID) + sngfp - h1p;
            end
    end
    set(handles.colorScaleNameHandle, 'string', dispMode);
    switch dispMode
        case 'COUNT'
            dispMapRaw = handlesLvl.baseParameters.counterMap;
            dispMap = dispMapRaw / max(dispMapRaw(:)) * 254;
            set(handles.colorScaleHandle, 'ydata', [0 max(dispMapRaw(:))]);
            set(handles.colorBarAxis, 'ylim', [0 max(0.01, max(dispMapRaw(:)))]);
            set(handles.currentValueHandle, 'ydata', currentCount * [1 1]);
            dispMapCurrent = currentCount / max(dispMapRaw(:)) * 254;
            %set(handles.colorIndicatorHandle,'cdata', dispMap(splID, freqID));
        case 'SNR'
            dispMapRaw = handlesLvl.baseParameters.snrMap ... 
                ./ handlesLvl.baseParameters.counterMap;
            dispMapRaw(isnan(dispMapRaw)) = 0;
            dispMapRaw(dispMapRaw == Inf) = 0;
            %dispMap = dispMapRaw / max(dispMapRaw(:)) * 254;
            dispMap = (dispMapRaw - 10) / (50 - 10) * 254;
            %set(handles.colorScaleHandle, 'ydata', [0 max(dispMapRaw(:))]);
            set(handles.colorScaleHandle, 'ydata', [10 50]);
            %set(handles.colorBarAxis, 'ylim', [0 max(dispMapRaw(:))]);
            set(handles.colorBarAxis, 'ylim', [10 50]);
            set(handles.currentValueHandle, 'ydata', avMes * [1 1]);
            dispMapCurrent = (avMes - 10) / (50 - 10) * 254;
            %set(handles.colorIndicatorHandle,'cdata', avMes);
        case 'H2-H1'
            dispMapRaw = handlesLvl.baseParameters.h2h1Map ... 
                ./ handlesLvl.baseParameters.counterMap;
            dispMapRaw(isnan(dispMapRaw)) = -50;
            dispMapRaw(dispMapRaw == Inf) = -50;
            dispMap = (dispMapRaw + 50) / (30 + 50) * 254;
            set(handles.colorScaleHandle, 'ydata', [-50 30]);
            set(handles.colorBarAxis, 'ylim', [-50 30]);
            set(handles.currentValueHandle, 'ydata', (h2 - h1) * [1 1]);
            dispMapCurrent = ((h2 - h1) + 50) / (30 + 50) * 254;
            %set(handles.colorIndicatorHandle,'cdata', (h2 - h1));
        case 'SgFrmnt'
            %baseParameters.singFrmntMap
            dispMapRaw = handlesLvl.baseParameters.singFrmntMap ... 
                ./ handlesLvl.baseParameters.counterMap;
            dispMapRaw(isnan(dispMapRaw)) = -50;
            dispMapRaw(dispMapRaw == Inf) = -50;
            dispMap = (dispMapRaw + 50) / (20 + 50) * 254;
            set(handles.colorScaleHandle, 'ydata', [-50 20]);
            set(handles.colorBarAxis, 'ylim', [-50 20]);
            set(handles.currentValueHandle, 'ydata', (sngfp - h1p) * [1 1]);
            dispMapCurrent = ((sngfp - h1p) + 50) / (20 + 50) * 254;
            %set(handles.colorIndicatorHandle,'cdata', (sngfp - h1p));
    end
    set(handles.foCrossHair, 'xdata', 12 * log2(avfo / fLow) * [1 1] + 1);
    set(handles.splCrossHair, 'visible', 'on');
    set(handles.foCrossHair, 'visible', 'on');
    set(handles.pitchIndicatorHandle, 'visible', 'on');
    semitoneAxis = handlesLvl.baseParameters.semitoneAxis;
    kbdAxis = handlesLvl.baseParameters.kbdAxis;
    a4Kbd = interp1(semitoneAxis, kbdAxis, log2(avfo / fLow) * 12, 'linear', 'extrap');
    a4OnModSemitone = (a4Kbd + 0.5 / 7) / (6 + 1/7) * (length(fcList) + 1) - 0.5;
    set(handles.pitchIndicatorHandle, 'xdata', [a4OnModSemitone, log2(avfo / fLow) * 12 + 1]);
    set(handles.currentValueHandle, 'visible', 'on');
    set(handles.colorIndicatorHandle,'cdata', dispMapCurrent);
else
    set(handles.splCrossHair, 'visible', 'off');
    set(handles.foCrossHair, 'visible', 'off');
    set(handles.pitchIndicatorHandle, 'visible', 'off');
    set(handles.currentValueHandle, 'visible', 'off');
end
set(handles.profileHandle, 'cdata', dispMap);
%disp(20 * log10(max(abs(peakCheckBuffer))));
set(hObject, 'userdata', handlesLvl);
end

function recorderTimerFcn(hObject, event, handle)
handles = get(hObject, 'userdata');
tmpAudio = getaudiodata(handles.recordObj1);
n_audio = length(tmpAudio);
handles.updateLength = n_audio - handles.lastPoint;
handles.recordingBuffer(handles.lastPoint:n_audio) = ...
    tmpAudio(handles.lastPoint:n_audio);
handles.previousPoint = handles.lastPoint + 1;
handles.lastPoint = n_audio;
set(hObject, 'userdata', handles);
%set(handles.timerForWaveDraw, 'userdata', handles);
%set(handles.timerForWaveletDraw, 'userdata', handles);
handles.audioRecorderCount = handles.audioRecorderCount - 1;
if handles.audioRecorderCount < 1 %n_audio > handles.recordingDuration * handles.samplingFrequency
    stop(handles.recordObj1);
    switch handles.recordingMode
        case 'measurement'
            set(handles.counterTxt, 'string', 'Done!');
            %startButton_Callback(handles.startButton, 'dummy', handles)
            set(hObject, 'userdata', handles);
        case 'calibration'
            set(handles.counterTxt, 'string', 'Initializing');
            startButton_Callback(handles.startButton, 'dummy', handles)
    end
else
    start(handles.timerForLevelAxis);
    %start(handles.timerForWaveletDraw);
    %endTime = handles.updateLength / handles.samplingFrequency;
    %set(handles.counterTxt, 'string', num2str(endTime * 1000, '%03.2f'));
    set(handles.counterTxt, 'string', num2str(handles.audioRecorderCount));
    set(hObject, 'userdata', handles);
end
%set(hObj
end

function handles = setDefaults(handles)
handles.recorderTimerInterval = 0.05; % 50ms
%handles.recorderTimerInterval = 0.125; % 125ms
handles.recordingDuration = 25;
handles.samplingFrequency = 44100; % Hz
fs = handles.samplingFrequency;
handles.lastPoint = 1;
handles.lastPointer = 1;
handles.wavePowerDuration = 2;
handles.recordingBuffer = zeros(round((handles.wavePowerDuration + 1) * fs), 1);
handles.maxTargetPoint = 400;% This is for audio recorder
handles.maxAudioRecorderCount = handles.maxTargetPoint;
handles.audioRecorderCount = handles.maxAudioRecorderCount;
handles.calibCoeff = 70 - (-20);
handles.low_frequency = 55;
handles.high_freuency = 1760;
handles.channels_in_octav = 6;
handles.downSampling = 1;
handles.stretching_factor = 1.2;
fs = handles.samplingFrequency;
xt = rand(round(fs / 5), 1);
handles.initialStruct = sourceAttributesAnalysis(xt, fs, [1 length(xt)], ...
    handles.low_frequency, handles.high_freuency, ...
    handles.channels_in_octav, handles.downSampling, handles.stretching_factor, ...
    'sixterm', 8, 4);
handles.wvltStrDs = handles.initialStruct.wvltStrDs;
end

function handles = initializeGUI(handles)
baseParameters = struct;
baseParameters.samplingFrequency = 44100; % Hz
fs = baseParameters.samplingFrequency;
fLow = 27.5; % Hz
nOctave = 6;
fHigh = fLow * 2 ^ nOctave;
fcList = fLow * 2 .^ (0:1 / 12:nOctave)';
baseParameters.fLow = fLow;
baseParameters.fHigh = fHigh;
baseParameters.nOctave = nOctave;
baseParameters.fcList = fcList;
levelList = (30:2:120)';
baseParameters.levelList = levelList;
baseParameters.counterMap = zeros(length(levelList), length(fcList));
baseParameters.snrMap = zeros(length(levelList), length(fcList));
baseParameters.h2h1Map = zeros(length(levelList), length(fcList));
baseParameters.singFrmntMap = zeros(length(levelList), length(fcList));
baseParameters.valueMap = rand(length(levelList), length(fcList)) * 255;
%--- piano image
axes(handles.pianoImageAxis)
semitoneBase = [0:11] / 12;
semitoneAxis = [semitoneBase, semitoneBase + 1, semitoneBase + 2, semitoneBase + 3, ...
    semitoneBase + 4, semitoneBase + 5] * 12;
kbdBase = [0 0.5 1 1.5 2 3 3.5 4 4.5 5 5.5 6] / 7;
kbdAxis = [kbdBase, kbdBase + 1, kbdBase + 2, kbdBase + 3, ...
    kbdBase + 4, kbdBase + 5];
kbdIm = imread('pianoKeyT.png');
kbdImValue = sum(kbdIm, 3);
imagesc([- 0.5 / 7, 6 + 0.5 / 7], [0 1], kbdImValue);
tmpCmap = colormap(jet);
tmpCmap(1:30, :) = tmpCmap(1:30, :) * 0;
tmpCmap(30:end, :) = tmpCmap(30:end, :) * 0 + 1;
%colormap(handles.pianoImageAxis, tmpCmap);
hold on;
a4Kbd = interp1(semitoneAxis, kbdAxis, log2(440 / fLow) * 12, 'linear', 'extrap');
%plot(log2(440 / fLow) * 12 + 0.7, 0.8, 'go', 'markersize', 10, 'linewidth', 3);
plot(a4Kbd, 0.8, 'go', 'markersize', 10, 'linewidth', 3);
axis off
hold off
%colormap(handles.pianoImageAxis, [0 0 0;1 1 1]);
%--- pitch (fo) indicator
axes(handles.pitchAxis);
fchk = 440 / 2;%fLow;
a4Kbd = interp1(semitoneAxis, kbdAxis, log2(fchk / fLow) * 12, 'linear', 'extrap');
a4OnModSemitone = (a4Kbd + 0.5 / 7) / (6 + 1/7) * (length(fcList) + 1) - 0.5;
handles.pitchIndicatorHandle = ...
    plot([a4OnModSemitone, log2(fchk / fLow) * 12], [0 1], 'g', 'linewidth', 5);
%axis([-0.5, 6 * 12 + 1.5, 0 1]);
axis([0.5, length(fcList) + 0.5, 0 1]);
set(gca, 'xtick', [], 'ytick', []);
baseParameters.semitoneAxis = semitoneAxis;
baseParameters.kbdAxis = kbdAxis;
%--- VVRP image
axes(handles.profileAxis);
handles.profileHandle = image([1 length(fcList)], [levelList(1) levelList(end)], baseParameters.valueMap);
axis('xy');
%colormapMod = colormap(parula(255));
colormapMod = colormap(jet(255));
%colorbar('westoutside');
colormapMod(1, :) = [1, 1, 1];
colormap(handles.profileAxis, colormapMod);
set(gca, 'xtick', 12 * log2([55 110 220 440 880] / fLow) + 1, ...
    'xticklabel', {'A1', 'A2','A3','A4','A5'})
hold all
handles.splCrossHair = plot([0 length(fcList) + 1], 70 * [1 1], 'g');
handles.foCrossHair = plot(length(fcList) / 2 * [1 1], [levelList(1) levelList(end)], 'g');
for tmpLvl = [30:10:120]
    plot([1 length(fcList)], tmpLvl * [1 1], 'color', 0.8 * [1 1 1], 'linewidth', 1);
end
for tmpFo = [55 110 220 440 880]
    plot(12 * log2(tmpFo / fLow) * [1 1] + 1, [levelList(1) levelList(end)], 'color', 0.8 * [1 1 1], 'linewidth', 1);
    text(12 * log2(tmpFo / fLow) + 1, 118, num2str(tmpFo), 'HorizontalAlignmen', 'center');
end
ylabel('sound pressure level (dB at 30cm)');
hold off
%---- colorbar for VVRP image
axes(handles.colorBarAxis)
baseParameters.colorScale = (1:255)';
handles.colorScaleHandle = image([0 1], [0 1], baseParameters.colorScale);
axis('xy');
colormap(handles.colorBarAxis, colormapMod);
hold all
handles.currentValueHandle = plot([0 1], 0.5 * [1 1], 'r', 'linewidth', 3);
hold off
handles.colorScaleNameHandle = ylabel('COUNT');
axis([0 1 0 1])
set(gca, 'xtick', [])
%--- color indicator
axes(handles.colorIndAxis);
handles.colorIndicatorHandle = image(rand(1, 1)*8);
colormap(handles.colorIndAxis, colormapMod);
axis 'off'
%--- Sound pressure level indicator
axes(handles.splAxis);
handles.splIndicatorCalHandle = plot([0 1], [70 70], 'g', 'linewidth', 5);
axis([0, 1, levelList(1) - 1, levelList(end) + 1]);
set(gca, 'xtick', [], 'ytick', []);
%--- level indicator
axes(handles.levelAxis);
handles.splIndicatorHandle = plot([0 1], -[10 10], 'r', 'linewidth', 3);
hold all
%handles.splIndicatorHandle = plot([0 1], -[20 20], 'g', 'linewidth', 5);
handles.barHandle = patch([0.2 0.8 0.8 0.2], [-20 -20 -100 -100], 'g');
hold off
axis([0 1 -100 0]);
set(gca, 'xtick', []);
xlabel('Voice')
ylabel('input level (dB rel. MSB');
grid on;
%--- EGG level indicator
axes(handles.eggLevelAxis);
handles.eggIndicatorHandle = plot([0 1], -[10 10], 'r', 'linewidth', 3);
hold all
%handles.splIndicatorHandle = plot([0 1], -[20 20], 'g', 'linewidth', 5);
handles.eggHandle = patch([0.2 0.8 0.8 0.2], [-20 -20 -100 -100], 'g');
hold off
axis([0 1 -100 0]);
set(gca, 'xtick', []);
xlabel('EGG')
%ylabel('input level (dB rel. MSB');
grid on;
set(handles.calibratedText, 'visible', 'off');
%--- save to handles
handles.baseParameters = baseParameters;
colormap(handles.pianoImageAxis, tmpCmap);
end


%--- end of private functions


% --- Executes on button press in calibrateButton.
function calibrateButton_Callback(hObject, eventdata, handles)
% hObject    handle to calibrateButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = get(handles.recordObj1, 'userdata');
fs = handles.samplingFrequency;
if handles.audioRecorderCount > 20 && ...
        handles.audioRecorderCount < handles.maxTargetPoint - 20
    tmpAudio = getaudiodata(handles.recordObj1);
    n_audio = length(tmpAudio);
    tmpWave = tmpAudio(max(1, n_audio - 2 * fs:n_audio));
    output = loudnessWithC(tmpWave, fs);
    recrded70dB = output.slow(end);
    handles.calibCoeff = 70 - recrded70dB;
    set(handles.calibratedText, 'visible', 'on');
    set(handles.recordObj1, 'userdata', handles);
end
end

% --- Executes on button press in reportButton.
function reportButton_Callback(hObject, eventdata, handles)
% hObject    handle to reportButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in quitButton.
function quitButton_Callback(hObject, eventdata, handles)
% hObject    handle to quitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isrecording(handles.recordObj1)
    stop(handles.recordObj1)
end
pause(0.5)
close(handles.voiceAttributeGUI);
end


% --- Executes on selection change in attributeMenu.
function attributeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to attributeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns attributeMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from attributeMenu
end


% --- Executes during object creation, after setting all properties.
function attributeMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to attributeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in testButton.
function testButton_Callback(hObject, eventdata, handles)
% hObject    handle to testButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in playRefButton.
function playRefButton_Callback(hObject, eventdata, handles)
% hObject    handle to playRefButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in playWorkButton.
function playWorkButton_Callback(hObject, eventdata, handles)
% hObject    handle to playWorkButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in startButton.
function startButton_Callback(hObject, eventdata, handles)
% hObject    handle to startButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = get(handles.recordObj1, 'userdata');
handles.audioRecorderCount = handles.maxAudioRecorderCount;
handles.lastPoint = 1;
set(handles.recordObj1, 'userdata', handles);
disp('restarting');
record(handles.recordObj1);
end


% --- Executes on selection change in micPositionPopup.
function micPositionPopup_Callback(hObject, eventdata, handles)
% hObject    handle to micPositionPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns micPositionPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from micPositionPopup
contents = cellstr(get(hObject,'String'));
tmp = contents{get(hObject,'Value')};
disance = str2double(tmp(1:2));
set(handles.micDistTxt, 'string', num2str(disance));
end

% --- Executes during object creation, after setting all properties.
function micPositionPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to micPositionPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in clearMapButton.
function clearMapButton_Callback(hObject, eventdata, handles)
% hObject    handle to clearMapButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handlesLvl = get(handles.timerForLevelAxis, 'userdata');
handlesLvl.baseParameters.counterMap = handlesLvl.baseParameters.counterMap * 0;
handlesLvl.baseParameters.snrMap = handlesLvl.baseParameters.counterMap;
handlesLvl.baseParameters.h2h1Map = handlesLvl.baseParameters.counterMap;
handlesLvl.baseParameters.singFrmntMap = handlesLvl.baseParameters.counterMap;
handlesLvl.baseParameters.valueMap = handlesLvl.baseParameters.counterMap;
set(handles.profileHandle, 'cdata', handlesLvl.baseParameters.counterMap);
set(handles.timerForLevelAxis, 'userdata', handlesLvl);
end

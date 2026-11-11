-- Auto Translator made by Do7463 
-- credit to Daive he teached me how to get user's current language
local WIN_W = 500  
local WIN_H = 400 

local ROOT_PATH = FileMgr.GetMenuRootPath()
local BASE_DIR = ROOT_PATH .. "\\Lua\\AutoTranslate"
local TRANS_DIR = ROOT_PATH .. "\\Translations"
local CONFIG_PATH = BASE_DIR .. "\\config.json"

local BASE_RAW_URL = "https://raw.githubusercontent.com/Do6563/Cherax-Translation-Hub/main/Translations/"
local BASE_VERSION_URL = "https://raw.githubusercontent.com/Do6563/Cherax-Translation-Hub/main/Versions/"

local IS_RUNNING = true 

local listHash = 476570075     
local buttonHash = 1079343186 
local batchSize = 500
local watchedFeatures = {}
local transData = {}
local executionStep = 0
local wasPlayerExisting = true 
local initTime = 0 
local currentIndex = 1

local DOWNLOAD_TIMEOUT = 15000 

local SETUP_LANGUAGES = {
    "Polish", "Turkish", "Bangladesh", "Hungarian", "Indonesian", "Arabic","Bulgarian"
}

-- Messages
local GuideText = {
    line1 = "English environment detected.",
    line2 = "If you use a language not officially supported by GTA,",
    line3 = "please select from the options below."
}

local State = { 
    IDLE=0, WIZARD=100, CHECK_VERSION=1, DOWNLOADING=2, 
    REFRESHING=3, SELECTING=4, WAIT_CLICK=5, CLICKING=6, 
    WATCHING=7, ERROR=8, STOPPED=999 
}
local currentState = State.IDLE
local curlRequest = nil
local currentConfig = {}

local transData = {}
local watchedFeatures = {}
local currentIndex = 1
local activeFileName = nil  
local serverVersion = 0
local SystemLanguage = "English"
local ForcedLanguage = nil 

-- lua unload 
local __LUA_UNLOADING = false
local __LUA_UNLOAD_FRAMES = 0
local lastFeatureCount = 0
local lastLuaScanTime = 0
local LUA_SCAN_INTERVAL = 1000 

local timerStart = 0
local downloadStartTime = 0 
local scriptLoadTime = Time.GetEpocheMs()
local STARTUP_DELAY = 1000 

local LocalText = {
    ["English"] = {
        ["init"] = "Translation System Initialized.",
        ["update_found"] = "Update Found! Downloading file...",
        ["downloading"] = "Downloading language file...",
        ["download_success"] = "Download and Save Success.",
        ["loaded"] = "Translation Loaded: ",
        ["applied"] = " Applied.",
        ["file_error"] = "File not found on server (404).",
        ["setup_complete"] = "Setup Complete: ",
        ["script_stopped"] = "Script has been stopped."
    },
    ["Korean"] = {
        ["init"] = "번역 시스템 초기화 완료.",
        ["update_found"] = "업데이트 감지됨! 파일 다운로드 중...",
        ["downloading"] = "언어 파일 다운로드 중...",
        ["download_success"] = "다운로드 및 저장 성공.",
        ["loaded"] = "번역본 불러옴: ",
        ["applied"] = "번역 적용 완료",
        ["file_error"] = "서버에 파일이 없습니다(404).",
        ["setup_complete"] = "설정 완료: ",
        ["script_stopped"] = "스크립트가 종료되었습니다."
    },
    ["Brazilian"] = {
        ["init"] = "Sistema de tradução inicializado.",
        ["update_found"] = "Atualização encontrada! Baixando arquivo...",
        ["downloading"] = "Baixando arquivo de idioma...",
        ["download_success"] = "Download e salvamento concluídos.",
        ["loaded"] = "Tradução carregada: ",
        ["applied"] = " Aplicado.",
        ["file_error"] = "Arquivo não encontrado no servidor (404).",
        ["setup_complete"] = "Configuração concluída: ",
        ["script_stopped"] = "O script foi interrompido."
    },
    ["Chinese"] = {
        ["init"] = "翻译系统已初始化。",
        ["update_found"] = "发现更新！正在下载文件...",
        ["downloading"] = "正在下载语言文件...",
        ["download_success"] = "下载并保存成功。",
        ["loaded"] = "翻译已加载: ",
        ["applied"] = " 已应用。",
        ["file_error"] = "服务器上未找到文件 (404)。",
        ["setup_complete"] = "设置完成: ",
        ["script_stopped"] = "脚本已停止。"
    },
    ["French"] = {
        ["init"] = "Système de traduction initialisé.",
        ["update_found"] = "Mise à jour trouvée ! Téléchargement du fichier...",
        ["downloading"] = "Téléchargement du fichier de langue...",
        ["download_success"] = "Téléchargement et enregistrement réussis.",
        ["loaded"] = "Traduction chargée : ",
        ["applied"] = " Appliqué.",
        ["file_error"] = "Fichier non trouvé sur le serveur (404).",
        ["setup_complete"] = "Configuration terminée : ",
        ["script_stopped"] = "Le script a été arrêté."
    },
    ["German"] = {
        ["init"] = "Übersetzungssystem initialisiert.",
        ["update_found"] = "Update gefunden! Datei wird heruntergeladen...",
        ["downloading"] = "Sprachdatei wird heruntergeladen...",
        ["download_success"] = "Download und Speicherung erfolgreich.",
        ["loaded"] = "Übersetzung geladen: ",
        ["applied"] = " Angewendet.",
        ["file_error"] = "Datei nicht auf dem Server gefunden (404).",
        ["setup_complete"] = "Einrichtung abgeschlossen: ",
        ["script_stopped"] = "Skript wurde gestoppt."
    },
    ["Italian"] = {
        ["init"] = "Sistema di traduzione inizializzato.",
        ["update_found"] = "Aggiornamento trovato! Download del file...",
        ["downloading"] = "Download del file lingua...",
        ["download_success"] = "Download e salvataggio completati.",
        ["loaded"] = "Traduzione caricata: ",
        ["applied"] = " Applicato.",
        ["file_error"] = "File non trovato sul server (404).",
        ["setup_complete"] = "Configurazione completata: ",
        ["script_stopped"] = "Lo script è stato arrestato."
    },
    ["Japanese"] = {
        ["init"] = "翻訳システムを初期化しました。",
        ["update_found"] = "アップデートが見つかりました！ファイルをダウンロード中...",
        ["downloading"] = "言語ファイルをダウンロード中...",
        ["download_success"] = "ダウンロードと保存に成功しました。",
        ["loaded"] = "翻訳を読み込みました: ",
        ["applied"] = " 適用完了。",
        ["file_error"] = "サーバーにファイルが見つかりません (404)。",
        ["setup_complete"] = "設定完了: ",
        ["script_stopped"] = "スクリプトが停止しました。"
    },
    ["Polish"] = {
        ["init"] = "System tłumaczeń został zainicjowany.",
        ["update_found"] = "Znaleziono aktualizację! Pobieranie pliku...",
        ["downloading"] = "Pobieranie pliku językowego...",
        ["download_success"] = "Pobieranie i zapisywanie zakończone sukcesem.",
        ["loaded"] = "Tłumaczenie załadowane: ",
        ["applied"] = " Zastosowano.",
        ["file_error"] = "Nie znaleziono pliku na serwerze (404).",
        ["setup_complete"] = "Konfiguracja zakończona: ",
        ["script_stopped"] = "Skrypt został zatrzymany."
    },
    ["Russian"] = {
        ["init"] = "Система перевода инициализирована.",
        ["update_found"] = "Найдено обновление! Загрузка файла...",
        ["downloading"] = "Загрузка языкового файла...",
        ["download_success"] = "Загрузка и сохранение выполнены.",
        ["loaded"] = "Перевод загружен: ",
        ["applied"] = " Применено.",
        ["file_error"] = "Файл не найден на сервере (404).",
        ["setup_complete"] = "Настройка завершена: ",
        ["script_stopped"] = "Скрипт остановлен."
    },
    ["Spanish"] = {
        ["init"] = "Sistema de traducción inicializado.",
        ["update_found"] = "¡Actualización encontrada! Descargando archivo...",
        ["downloading"] = "Descargando archivo de idioma...",
        ["download_success"] = "Descarga y guardado exitosos.",
        ["loaded"] = "Traducción cargada: ",
        ["applied"] = " Aplicado.",
        ["file_error"] = "Archivo no encontrado en el servidor (404).",
        ["setup_complete"] = "Configuración completada: ",
        ["script_stopped"] = "El script se ha detenido."
    },
    ["Bangladesh"] = {
        ["init"] = "অনুবাদ সিস্টেম শুরু হয়েছে।",
        ["update_found"] = "আপডেট পাওয়া গেছে! ফাইল ডাউনলোড হচ্ছে...",
        ["downloading"] = "ভাষা ফাইল ডাউনলোড হচ্ছে...",
        ["download_success"] = "ডাউনলোড এবং সংরক্ষণ সফল হয়েছে।",
        ["loaded"] = "অনুবাদ লো드 হয়েছে: ",
        ["applied"] = " প্রয়োগ করা হয়েছে।",
        ["file_error"] = "সার্ভারে ফাইল পাওয়া যায়নি (404)।",
        ["setup_complete"] = "সেটআপ সম্পন্ন: ",
        ["script_stopped"] = "স্ক্রিপ্ট বন্ধ করা হয়েছে।"
    },
    ["Hungarian"] = {
        ["init"] = "Fordítórendszer inicializálva.",
        ["update_found"] = "Frissítés elérhető! Fájl letöltése...",
        ["downloading"] = "Nyelvi fájl letöltése...",
        ["download_success"] = "Sikeres letöltés és mentés.",
        ["loaded"] = "Fordítás betöltve: ",
        ["applied"] = " Alkalmazva.",
        ["file_error"] = "Fájl nem található a szerveren (404).",
        ["setup_complete"] = "Beállítás kész: ",
        ["script_stopped"] = "A szkript leállt."
    },
    ["Indonesian"] = {
        ["init"] = "Sistem terjemahan diinisialisasi.",
        ["update_found"] = "Pembaruan ditemukan! Mengunduh berkas...",
        ["downloading"] = "Mengunduh berkas bahasa...",
        ["download_success"] = "Unduhan dan penyimpanan berhasil.",
        ["loaded"] = "Terjemahan dimuat: ",
        ["applied"] = " Diterapkan.",
        ["file_error"] = "Berkas tidak ditemukan di server (404).",
        ["setup_complete"] = "Pengaturan selesai: ",
        ["script_stopped"] = "Skrip telah dihentikan."
    },
    ["Arabic"] = {
        ["init"] = "تم تهيئة نظام الترجمة.",
        ["update_found"] = "تم العثور على تحديث! جاري تحميل الملف...",
        ["downloading"] = "جاري تحميل ملف اللغة...",
        ["download_success"] = "تم التحميل والحفظ بنجاح.",
        ["loaded"] = "تم تحميل الترجمة: ",
        ["applied"] = " تم التطبيق.",
        ["file_error"] = "الملف غير موجود على الخادم (404).",
        ["setup_complete"] = "اكتمل الإعداد: ",
        ["script_stopped"] = "تم إيقاف السكريبت."
    }
}


local function T(key)
    local lang = ForcedLanguage or SystemLanguage
    if  LocalText[lang] and LocalText[lang][key] then
            return LocalText[lang][key]
    else 
        return LocalText["English"][key] or key end
end

-- [File Utils]
local function SaveBinaryFile(filepath, content)
    if not content or #content == 0 then return false end
    local file = io.open(filepath, "wb")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

local function GenerateConfigJSON(locked, filename, version, forcedLang)
    local fLangStr = forcedLang or ""
    return string.format('{\n\t"locked": %s,\n\t"activeFile": "%s",\n\t"version": %d,\n\t"forcedLang": "%s"\n}', 
        tostring(locked), filename or "", version or 0, fLangStr)
end

local function DetectLanguageNative()
    local langId = -1
    
    if Natives and Natives.InvokeInt then
        langId = Natives.InvokeInt(0x2BDD44CC428A7EAE)
    end
    
    local LangMap = { [0]="English", [1]="French", [2]="German", [3]="Italian", [4]="Spanish", [5]="Brazilian", [6]="Polish", [7]="Russian", [8]="Korean", [9]="Chinese", [10]="Japanese", [11]="Mexican", [12]="Chinese" }
    
    return LangMap[langId] or "English"
end

local function LoadData(content)
    local data = {}
    for key, value in content:gmatch('"(-?%d+)"%s*:%s*"(.-)"') do
        local cleanVal = value:gsub("\\n", "\n")
        data[key] = cleanVal
    end
    return data
end

local function CollectListFeatures()
    watchedFeatures = {}
    local allFeatures = FeatureMgr.GetAllFeatures()
    for _, feat in pairs(allFeatures) do
        local fType = feat:GetType()
        if fType >= 11 and fType <= 14 then
            table.insert(watchedFeatures, feat)
        end
    end
end

local function CheckAndTranslate(feat)
    if __LUA_UNLOADING then return end 

    local originalList = feat:GetList()
    if not originalList or #originalList == 0 then return end

    local firstItem = originalList[1]
    local hash = Utils.Joaat(firstItem)
    local hashStr = string.format("%.0f", hash)
    if hash < 0 then hashStr = string.format("%.0f", hash + 4294967296) end

    local targetVal = transData[hashStr]
    if targetVal and targetVal ~= firstItem then
        local newList = {}
        for _, optName in ipairs(originalList) do
            local h = Utils.Joaat(optName)
            local hStr = string.format("%.0f", h)
            if h < 0 then hStr = string.format("%.0f", h + 4294967296) end

            if transData[hStr] then
                table.insert(newList, transData[hStr])
            else
                table.insert(newList, optName)
            end
        end
        feat:SetList(newList)
    end
end


local function ApplyTranslationAndTheme()
    local root = TRANS_DIR .. "\\"
    local content = FileMgr.ReadFileContent(root .. activeFileName)
    
    local translatedTargetName = nil

    if content then 
        transData = LoadData(content)
        
        if targetName then
            local h = Utils.Joaat(targetName)
            local hStr = string.format("%.0f", h)
            if h < 0 then hStr = string.format("%.0f", h + 4294967296) end
            
            if transData[hStr] then
                translatedTargetName = transData[hStr]
            end
        end
    end

    local listFeature = FeatureMgr.GetFeature(listHash)
    if listFeature then
        local files = listFeature:GetList()
        local targetIndex = -1
        
        for i, fileName in ipairs(files) do
            local matchOriginal = string.find(fileName, targetName)
            
            local matchTranslated = false
            if translatedTargetName and string.find(fileName, translatedTargetName) then
                matchTranslated = true
            end

            if matchOriginal or matchTranslated then
                targetIndex = i - 1
                break
            end
        end

        if targetIndex ~= -1 then
            listFeature:SetListIndex(targetIndex)
        end
    end

    local loadBtn = FeatureMgr.GetFeature(buttonHash)
    if loadBtn then loadBtn:OnClick() end 

    -- 3. 번역 덮어쓰기
    CollectListFeatures()
    for _, feat in ipairs(watchedFeatures) do
        CheckAndTranslate(feat)
    end

    if GUI then GUI.AddToast("Auto Setup", T("applied"), 2000, 0) end
end

local function CheckNewLuaLoaded()
    if __LUA_UNLOADING then return end

    local now = Time.GetEpocheMs()
    if now - lastLuaScanTime < LUA_SCAN_INTERVAL then return end
    lastLuaScanTime = now

    local all = FeatureMgr.GetAllFeatures()
    local count = #all

    if lastFeatureCount == 0 then
        lastFeatureCount = count
        return
    end

    if count ~= lastFeatureCount then
        lastFeatureCount = count
        CollectListFeatures()
        for _, feat in ipairs(watchedFeatures) do
            CheckAndTranslate(feat)
        end
    end
end

local function StartVersionCheck()
    if currentState == State.DOWNLOADING or currentState == State.CHECK_VERSION then return end
    targetName = ForcedLanguage or SystemLanguage 
    if targetName == "English" then currentState = State.WATCHING; initTime = Time.GetEpocheMs(); return end
    
    local versionTarget = BASE_VERSION_URL .. targetName .. "_version.txt"
    curlRequest = Curl.Easy()
    curlRequest:Setopt(eCurlOption.CURLOPT_URL, versionTarget)
    curlRequest:Setopt(eCurlOption.CURLOPT_USERAGENT, "Mozilla/5.0")
    curlRequest:Perform()
    currentState = State.CHECK_VERSION
end

local function ConfirmLanguage(langName)
    ForcedLanguage = langName
    activeFileName = langName .. ".json"
    targetName = langName
    FileMgr.WriteFileContent(CONFIG_PATH, GenerateConfigJSON(false, activeFileName, 0, ForcedLanguage), false)
    GUI.AddToast("Setup", T("setup_complete") .. langName, 3000, 0)
    StartVersionCheck()
end

local function QuitAndUnload()
    IS_RUNNING = false
    currentState = State.STOPPED
    GUI.AddToast("System", T("script_stopped"), 4000, 0)
end

local function TextCentered(text)
    local windowWidth = ImGui.GetWindowWidth()
    local textWidth = ImGui.CalcTextSize(text)
    ImGui.SetCursorPosX((windowWidth - textWidth) * 0.5)
    ImGui.Text(text)
end

local function DrawImGuiWizard()
    if currentState ~= State.WIZARD or not IS_RUNNING then return end
    
    local screenW, screenH = ImGui.GetDisplaySize()
    local posX = (screenW / 2) - (WIN_W / 2)
    local posY = (screenH / 2) - (WIN_H / 2)
    
    ImGui.SetNextWindowPos(posX, posY, 8) 
    ImGui.SetNextWindowSize(WIN_W, WIN_H, 1) 
    
    if ImGui.Begin("Language Setup", true, 34) then 
        ImGui.Spacing(); ImGui.Spacing()
        
        TextCentered(GuideText.line1)
        ImGui.Spacing()
        TextCentered(GuideText.line2)
        TextCentered(GuideText.line3)
        
        ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing(); ImGui.Spacing()
        
        local columns = 2 
        local itemSpacing = 15 
        local sidePadding = 25 
        local availWidth = ImGui.GetWindowWidth() - (sidePadding * 2)
        local btnW = (availWidth - itemSpacing) / 2
        local btnH = 35 

        for i, lang in ipairs(SETUP_LANGUAGES) do
            if (i % columns) == 1 then ImGui.SetCursorPosX(sidePadding)
            else ImGui.SameLine(); ImGui.SetCursorPosX(sidePadding + btnW + itemSpacing) end

            if ImGui.Button(lang, btnW, btnH) then ConfirmLanguage(lang) end
        end
        
        ImGui.SetCursorPosY(WIN_H - 50) 
        ImGui.Separator(); ImGui.Spacing()
        
        ImGui.PushStyleColor(21, 0.8, 0.1, 0.1, 1.0) 
        ImGui.PushStyleColor(22, 0.9, 0.2, 0.2, 1.0) 
        ImGui.PushStyleColor(23, 0.6, 0.0, 0.0, 1.0) 
        ImGui.SetCursorPosX(sidePadding)
        
        if ImGui.Button("Quit & Unload Script", availWidth, 30) then QuitAndUnload() end
        ImGui.PopStyleColor(3) 
        ImGui.End() 
    end
end

local function InitSystem()
    if not FileMgr.DoesFileExist(BASE_DIR) then FileMgr.CreateDir(BASE_DIR) end
    if not FileMgr.DoesFileExist(TRANS_DIR) then FileMgr.CreateDir(TRANS_DIR) end
    
    SystemLanguage = DetectLanguageNative()

    local forcedLangLoaded = nil

    if FileMgr.DoesFileExist(CONFIG_PATH) then
        local content = FileMgr.ReadFileContent(CONFIG_PATH)
        local locked = content:match('"locked":%s*true')
        local fName = content:match('"activeFile":%s*"(.-)"') or ""
        local ver = tonumber(content:match('"version":%s*(%d+)')) or 0
        
        forcedLangLoaded = content:match('"forcedLang":%s*"(.-)"')
        if forcedLangLoaded == "" then forcedLangLoaded = nil end

        if (not forcedLangLoaded) and (fName and fName ~= "") then
            forcedLangLoaded = fName:gsub(".json", "")
        end

        currentConfig = { locked = (locked ~= nil), activeFile = fName, version = ver, forcedLang = forcedLangLoaded }
    else
        currentConfig = { locked = false, activeFile = "", version = 0, forcedLang = nil }
        FileMgr.WriteFileContent(CONFIG_PATH, GenerateConfigJSON(false, "", 0, nil), false)
    end
    
    if forcedLangLoaded or (currentConfig.activeFile and currentConfig.activeFile ~= "") then 
        
        if forcedLangLoaded then ForcedLanguage = forcedLangLoaded end
        
        if ForcedLanguage then 
            targetName = ForcedLanguage
            activeFileName = ForcedLanguage .. ".json" 
        elseif currentConfig.activeFile ~= "" then
            activeFileName = currentConfig.activeFile
            targetName = activeFileName:gsub(".json", "")
            if not ForcedLanguage then ForcedLanguage = targetName end
        end
        
        serverVersion = currentConfig.version
        StartVersionCheck()
        
    elseif SystemLanguage == "English" then 
        currentState = State.WIZARD
    else 
        targetName = SystemLanguage
        activeFileName = SystemLanguage .. ".json"
        StartVersionCheck()
    end
end

local isSystemInitialized = false

local function OnPresentLoop()
    if Time.GetEpocheMs() - scriptLoadTime < STARTUP_DELAY then return end

    if not isSystemInitialized then
        InitSystem()
        isSystemInitialized = true
    end
    
    DrawImGuiWizard()
    
    if currentState == State.CHECK_VERSION and curlRequest then
        if curlRequest:GetFinished() then
            local code, response = curlRequest:GetResponse(); curlRequest = nil 
            if code == eCurlCode.CURLE_OK and response then

                local sVer = 0
            if string.find(response, "<!DOCTYPE") or string.find(response, "<html>") then
                sVer = 0
            else
                sVer = tonumber(response:match("(%d+)")) or 0
            end
                if sVer then
                    serverVersion = sVer
                    if serverVersion > currentConfig.version then 
                        GUI.AddToast("Translator", T("update_found"), 3000, 0)
                        currentState = State.DOWNLOADING
                        downloadStartTime = Time.GetEpocheMs()
                    else 
                        if FileMgr.DoesFileExist(TRANS_DIR .. "\\" .. activeFileName) then 
                            currentState = State.WATCHING; initTime = Time.GetEpocheMs() 
                        else 
                            currentState = State.DOWNLOADING; downloadStartTime = Time.GetEpocheMs() 
                        end 
                    end
                else -- version mismatch detect
                     if FileMgr.DoesFileExist(TRANS_DIR .. "\\" .. activeFileName) then 
                        currentState = State.WATCHING; initTime = Time.GetEpocheMs() 
                    else 
                        currentState = State.ERROR 
                    end
                end
            else 
                if FileMgr.DoesFileExist(TRANS_DIR .. "\\" .. activeFileName) then 
                    currentState = State.WATCHING; initTime = Time.GetEpocheMs() 
                else 
                    currentState = State.ERROR 
                end 
            end
        end

    elseif currentState == State.DOWNLOADING then
        if curlRequest == nil then 
            GUI.AddToast("Translator", T("downloading"), 2000, 0)
            curlRequest = Curl.Easy()
            curlRequest:Setopt(eCurlOption.CURLOPT_URL, BASE_RAW_URL .. activeFileName)
            curlRequest:Setopt(eCurlOption.CURLOPT_USERAGENT, "Mozilla/5.0")
            curlRequest:Perform()
        else 
            if Time.GetEpocheMs() - downloadStartTime > DOWNLOAD_TIMEOUT then 
                curlRequest = nil
                GUI.AddToast("Error", T("download_fail"), 4000, 0)
                currentState = State.ERROR
                return 
            end
            
            if curlRequest:GetFinished() then 
                local code, response = curlRequest:GetResponse(); curlRequest = nil 
                
                if code == eCurlCode.CURLE_OK and response and #response > 10 and (string.find(response, "{") or string.find(response, "%[")) then 
                    if SaveBinaryFile(TRANS_DIR .. "\\" .. activeFileName, response) then 
                        GUI.AddToast("Translator", T("download_success"), 3000, 0)
                        
                        FileMgr.WriteFileContent(CONFIG_PATH, GenerateConfigJSON(true, activeFileName, serverVersion, ForcedLanguage), false)
                        
                        local content = FileMgr.ReadFileContent(TRANS_DIR .. "\\" .. activeFileName)
                                if content then transData = LoadData(content) end

                    CollectListFeatures()
                        for _, feat in ipairs(watchedFeatures) do CheckAndTranslate(feat) end
                        
                        currentState = State.WATCHING
                        initTime = Time.GetEpocheMs() 
                    else 
                        currentState = State.ERROR 
                    end
                else 
                    GUI.AddToast("Error", "Server File Invalid", 4000, 0)
                    currentState = State.ERROR 
                end 
            end 
        end
    
    elseif currentState == State.WATCHING then
        
        local currentTime = Time.GetEpocheMs()
        local elapsed = currentTime - initTime

        if executionStep == 0 and elapsed > 100 then
            executionStep = 1
        end

        if executionStep == 1 and elapsed > 500 then
            ApplyTranslationAndTheme() 
            executionStep = 2
        end

        if executionStep == 2 then
            local playerPed = Natives.InvokeInt(0x50FAC3A3E030A6E1, -1)
            local isPlayerExisting = (playerPed ~= 0)

            if isPlayerExisting and not wasPlayerExisting then
                if elapsed > 2000 then
                    CollectListFeatures()
                    if GUI then GUI.AddToast("Auto Setup", "Watcher Active", 1500, 0) end
                    executionStep = 3
                end
            end
            wasPlayerExisting = isPlayerExisting
        end

        if executionStep >= 2 and #watchedFeatures > 0 then
            for i = 1, batchSize do
                currentIndex = currentIndex + 1
                if currentIndex > #watchedFeatures then currentIndex = 1 end
                local feat = watchedFeatures[currentIndex]
                if feat then
                    CheckAndTranslate(feat)
                end
            end
        end
    end
end

EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
    if currentState == State.WATCHING and executionStep >= 2 then
        CheckNewLuaLoaded()
    end
end)

EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
    local count = #FeatureMgr.GetAllFeatures()

    if lastFeatureCount ~= 0 and count < lastFeatureCount then
        __LUA_UNLOADING = true
        __LUA_UNLOAD_FRAMES = 0
    end

    if __LUA_UNLOADING then
        __LUA_UNLOAD_FRAMES = __LUA_UNLOAD_FRAMES + 1
        if __LUA_UNLOAD_FRAMES >= 1 then
            __LUA_UNLOADING = false
            __LUA_UNLOAD_FRAMES = 0
            CollectListFeatures()
            for _, feat in ipairs(watchedFeatures) do
                CheckAndTranslate(feat)
            end
        end
    end
end)

EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, OnPresentLoop)
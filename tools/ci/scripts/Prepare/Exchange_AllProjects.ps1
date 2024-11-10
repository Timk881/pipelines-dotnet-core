    param(
        [string]$SourcesDirectory
        )
    
    # copy standard files into project directory
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Ersa_Maschine.apj                                        -Destination $SourcesDirectory\ 
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Package.pkg                                              -Destination $SourcesDirectory\Logical
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Physical.pkg                                             -Destination $SourcesDirectory\Physical
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\mappView\Package.pkg                                     -Destination $SourcesDirectory\Logical\mappView
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\mappView\Widgets\Package.pkg                             -Destination $SourcesDirectory\Logical\mappView\Widgets
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Logical\Allgemein_Task_Basis\Alarm\Package.pkg           -Destination $SourcesDirectory\Logical\Allgemein_Tasks_Basis\Alarm
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Logical\Lib_Common\Lib_Manager\Package.pkg               -Destination $SourcesDirectory\Logical\Lib_Common\Lib_Manager
    Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\All\BR\Logical\Lib_Common\Lib_DeviceList\Package.pkg            -Destination $SourcesDirectory\Logical\Lib_Common\Lib_DeviceList
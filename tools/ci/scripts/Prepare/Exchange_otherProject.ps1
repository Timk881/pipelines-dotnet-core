    param(
        [string]$Machinetype,
        [string]$SourcesDirectory
        )

    # copy files of machinetype into project directory
    Copy-Item -Path   C:\SPS\Unittest\TechnikerProjektarbeit\WorkProject\BasisProject.apj                               -Destination $SourcesDirectory\ 
    #Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Package.pkg                                     -Destination $SourcesDirectory\Logical
    #Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Physical.pkg                                    -Destination $SourcesDirectory\Physical
    #Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\mappView\Package.pkg                            -Destination $SourcesDirectory\Logical\mappView
    #Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\mappView\Widgets\Package.pkg                    -Destination $SourcesDirectory\Logical\mappView\Widgets
    #Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Logical\Allgemein_Task_Basis\Alarm\Package.pkg  -Destination $SourcesDirectory\Logical\Allgemein_Tasks_Basis\Alarm
    #Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Logical\Lib_Common\Lib_Manager\Package.pkg      -Destination $SourcesDirectory\Logical\Lib_Common\Lib_Manager
    #Copy-Item -Path $SourcesDirectory\Flashcard_Ordner_User\$Machinetype\BR\Logical\Lib_Common\Lib_DeviceList\Package.pkg   -Destination $SourcesDirectory\Logical\Lib_Common\Lib_DeviceList

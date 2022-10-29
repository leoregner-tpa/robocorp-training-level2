*** Settings ***
Documentation       Training for RoboCorp certificate level II
...                 https://robocorp.com/docs/courses/build-a-robot#rules-for-the-robot

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Greet
    ${fileName}=    Ask For Filename
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    @{orders}=    Get Orders
    Process Orders Despite Errors    ${orders}
    Archive Order Summaries    ${fileName}
    [Teardown]    Clean Up


*** Keywords ***
Greet
    ${name}=    Get Secret    name
    Log    Hello, ${name}[firstName]

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv
    @{list}=    Read Table From CSV    orders.csv
    RETURN    @{list}

Process Orders Despite Errors
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        TRY
            Click Element    class:btn-dark
            Process Order    ${order}
        EXCEPT
            WHILE    ${True}
                TRY
                    Process Order    ${order}
                    BREAK
                EXCEPT
                    Log    zach.
                END
            END
        END
    END

Process Order
    [Arguments]    ${order}
    Select Head    ${order}[Head]
    Select Body    ${order}[Body]
    Select Legs    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Click Button    id:preview
    Take Picture of Robot
    Click Button    id:order
    Export PDF
    Insert Picture into PDF
    Click Button    id:order-another
    Store PDF    ${order}[Order number]

Select Head
    [Arguments]    ${id}
    Select From List By Value    head    ${id}

Select Body
    [Arguments]    ${id}
    ${elementId}=    Catenate    SEPARATOR=    id-body-    ${id}
    Click Element    id:${elementId}

Select Legs
    [Arguments]    ${id}
    Input Text    css:[type=number]    ${id}

Take Picture of Robot
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Element Is Visible    css:[alt=Head]
    Wait Until Element Is Visible    css:[alt=Body]
    Wait Until Element Is Visible    css:[alt=Legs]
    RPA.Browser.Selenium.Capture Element Screenshot    id:robot-preview-image    robot.png

Export PDF
    Wait Until Element Is Visible    id:receipt
    ${receiptHtml}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receiptHtml}    receipt.pdf

Insert Picture into PDF
    ${files}=    Create List
    ...    receipt.pdf
    ...    robot.png
    Add Files To Pdf    ${files}    summary.pdf

Store PDF
    [Arguments]    ${fileName}
    Create Directory    temp
    Copy File    summary.pdf    temp${/}${fileName}.pdf

Ask For Filename
    Add text input    filePath    File Name:
    ${data}=    Run Dialog
    RETURN    ${data}[filePath]

Archive Order Summaries
    [Arguments]    ${fileName}
    Archive Folder With Zip    temp    ${OUTPUT_DIR}${/}${fileName}.zip

Clean Up
    TRY
        Remove File    orders.csv
        Remove File    robot.png
        Remove File    receipt.pdf
        Remove File    summary.pdf
        Remove Directory    temp    recursive=${True}
    FINALLY
        Close Browser
    END

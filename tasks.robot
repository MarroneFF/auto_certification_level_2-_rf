*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.


Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Archive

*** Variables ***
${DOWNLOAD_PATH}=   ${OUTPUT DIR}${/}orders.csv
${form_head}=    //select[@id='head']
${form_address}=    //input[@id='address']
${TEMP_OUTPUT_DIRECTORY}=       ${CURDIR}${/}temp

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Set up directories
    Process orders

*** Keywords ***
Set up directories
    Create Directory    ${TEMP_OUTPUT_DIRECTORY}

Process orders
    Open Robot Order Website
    ${orders}=    Get Orders
    FOR    ${order}    IN    @{orders}
        Run Keyword And Continue On Failure  Order Robot    ${order}
    END
    Create a ZIP file of receipt PDF files
    [Teardown]    Cleanup temporary PDF directory


Open Robot Order Website
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order
    Close the annoying modal
    Maximize Browser Window

Close the annoying modal
    Click Button When Visible    //button[normalize-space()='OK']
Get Orders
    Download    https://robotsparebinindustries.com/orders.csv    target_file=${DOWNLOAD_PATH}    overwrite=True
    @{orders}=    Read table from CSV    ${DOWNLOAD_PATH}
    RETURN    ${orders}

Order Robot
    [Arguments]    ${order}
    #Head List
    Select From List By Index    ${form_head}    ${order}[Head]
    #Body Radio Button
    Select Radio Button    body    ${order}[Body]
    #Legs
    ${legs_locator}=    Set Variable    xpath://input[@type='number']
    Input Text    ${legs_locator}    ${order}[Legs]
    #Address text box
    Input Text    ${form_address}    ${order}[Address]
    Click Button    //button[@id='preview']
    Wait Until Page Contains Element    //div[@id='robot-preview-image']    5
    Click Button    //button[@id='order']
    ${pdf}=    Store the order receipt as a PDF file    ${order}
    Click Button    //button[@id='order-another']
    Close the annoying modal

Store the order receipt as a PDF file
    [Arguments]    ${order}
    Wait Until Element Is Visible    //div[@id='receipt']
    Wait Until Element Is Visible    //div[@id='robot-preview-image']
    ${screenshot}=    Take a screenshot of the robot    ${TEMP_OUTPUT_DIRECTORY}${/}${order}[Order number]
    ${receipt}=    Get Element Attribute    //div[@id='receipt']    outerHTML
    ${pdf}=    Html To Pdf    ${receipt}    ${TEMP_OUTPUT_DIRECTORY}${/}${order}[Order number]\_receipt.pdf
    Embed the robot screenshot to the receipt PDF file
    ...    ${TEMP_OUTPUT_DIRECTORY}${/}${order}[Order number]\.png
    ...    ${TEMP_OUTPUT_DIRECTORY}${/}${order}[Order number]\_receipt.pdf

Take a screenshot of the robot
    [Arguments]    ${order}
    Capture Element Screenshot    //div[@id='robot-preview-image']    ${order}.png


Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${pdf}

Create a ZIP file of receipt PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${TEMP_OUTPUT_DIRECTORY}    ${zip_file_name}

Cleanup temporary PDF directory
    Remove Directory    ${TEMP_OUTPUT_DIRECTORY}    True
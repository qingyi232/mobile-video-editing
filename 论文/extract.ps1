$word = New-Object -ComObject Word.Application
$word.Visible = $false
$docPath = "F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书(1).docx"
$doc = $word.Documents.Open($docPath)
$text = $doc.Content.Text
$doc.Close($false)
$word.Quit()
$outPath = "F:\26毕设2\移动端短视频智能剪辑app\论文\thesis_text.txt"
[System.IO.File]::WriteAllText($outPath, $text, [System.Text.Encoding]::UTF8)
Write-Host "Done"

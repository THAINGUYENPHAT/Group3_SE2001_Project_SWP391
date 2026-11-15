param(
    [string]$Maven = 'mvn',
    [string]$Java = 'java',
    [switch]$Integration
)

$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
& $Maven -o -f (Join-Path $project 'pom.xml') package -DskipTests
if ($LASTEXITCODE -ne 0) { throw 'Maven build failed.' }

$classpath = @(
    (Join-Path $project 'target/test-classes'),
    (Join-Path $project 'target/classes'),
    (Join-Path $project 'target/OECS-1.0-SNAPSHOT/WEB-INF/lib/*'),
    (Join-Path $env:USERPROFILE '.m2/repository/jakarta/platform/jakarta.jakartaee-api/10.0.0/jakarta.jakartaee-api-10.0.0.jar')
) -join [IO.Path]::PathSeparator

& $Java '-Dfile.encoding=UTF-8' -cp $classpath service.AdminCleanupChecks
if ($LASTEXITCODE -ne 0) { throw 'Admin cleanup checks failed.' }

if ($Integration) {
    # The existing harness creates and removes its own isolated test database.
    & $Java '-Dfile.encoding=UTF-8' -cp $classpath service.CheckoutIntegrationChecks `
        (Join-Path (Split-Path -Parent $project) 'DB_OECS.sql') '--staff-cancel-only'
    if ($LASTEXITCODE -ne 0) { throw 'Admin order integration checks failed.' }
}

function Set-CIPPAuthenticationPolicy {
    [CmdletBinding()]
    param(
        $TenantFilter,
        $AuthenticationMethodId,
        $EnableGroups, # Not sure if i need this, but it's for if the all_users is not the target for enablement
        $OptionalInput, # Used for stuff like the 
        $APIName = 'Set Authentication Policy', # Should this be 'Standards'
        $ExecutingUser,
        [ValidateSet('enabled', 'disabled')]$State # enabled or disabled
    )
        
    switch ($AuthenticationMethodId) {

        # FIDO2
        'FIDO2' {

            if ($State -eq 'enabled') {
                # Enable FIDO2
                try {
                    $body = '{"@odata.type":"#microsoft.graph.fido2AuthenticationMethodConfiguration","id":"Fido2","includeTargets":[{"id":"all_users","isRegistrationRequired":false,"targetType":"group","displayName":"All users"}],"excludeTargets":[],"isAttestationEnforced":true,"isSelfServiceRegistrationAllowed":true,"keyRestrictions":{"aaGuids":[],"enforcementType":"block","isEnforced":false},"state":"enabled"}'
                    New-GraphPostRequest -tenantid $TenantFilter -Uri 'https://graph.microsoft.com/beta/policies/authenticationmethodspolicy/authenticationMethodConfigurations/Fido2' -Type patch -Body $body -ContentType 'application/json'
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            }
            # Disable FIDO2
            elseif ($State -eq 'disabled') {
                try {
                    # Get current state and disable
                    $GraphRequest = New-GraphGetRequest -uri 'https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/fido2' -tenantid $TenantFilter
                    $GraphRequest.state = $State
                    $body = ($GraphRequest | ConvertTo-Json -Depth 10)
                    $GraphRequest = New-GraphPostRequest -tenantid $TenantFilter -Uri 'https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/fido2' -Type patch -Body $body -ContentType 'application/json'
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
    
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } else {
                # Catch invalid input
                Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
            }

        }

        # Microsoft Authenticator
        'MicrosoftAuthenticator' {  

            if ($State -eq 'enabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } elseif ($State -eq 'disabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } else {
                # Catch invalid input
                Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
            }

        }
        # SMS
        'SMS' {  

            if ($State -eq 'enabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } elseif ($State -eq 'disabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } else {
                # Catch invalid input
                Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
            }
        }
        # Temporary Access Pass
        'TemporaryAccessPass' {  

            if ($State -eq 'enabled') {
                # Get the TAP config from the standards table. If it's not there, use the default value of true
                $ConfigTable = Get-CippTable -tablename 'standards'
                $TAPConfig = ((Get-CIPPAzDataTableEntity @ConfigTable -Filter "PartitionKey eq 'standards' and RowKey eq '$TenantFilter'").JSON | ConvertFrom-Json).Standards.TAP.config
                if (!$TAPConfig) {
                    $TAPConfig = ((Get-CIPPAzDataTableEntity @ConfigTable -Filter "PartitionKey eq 'standards' and RowKey eq 'AllTenants'").JSON | ConvertFrom-Json).Standards.TAP.config
                }
                if (!$TAPConfig) { $TAPConfig = 'true' }

                try {
                    # Vaiable values
                    $MinimumLifetime = '60' #Minutes
                    $MaximumLifetime = '480' #minutes
                    $DefaultLifeTime = '60' #minutes
                    $DefaultLength = '8'
                
                    # Build the body of the request
                    $CurrentInfo = [PSCustomObject]@{
                        '@odata.type'            = '#microsoft.graph.temporaryAccessPassAuthenticationMethodConfiguration'
                        id                       = 'TemporaryAccessPass'
                        includeTargets           = @(
                            @{
                                id                     = 'all_users'
                                isRegistrationRequired = $false
                                targetType             = 'group'
                                displayName            = 'All users'
                            }
                        )
                        defaultLength            = $DefaultLength
                        defaultLifetimeInMinutes = $DefaultLifeTime
                        isUsableOnce             = $TAPConfig
                        maximumLifetimeInMinutes = $MaximumLifetime
                        minimumLifetimeInMinutes = $MinimumLifetime
                        state                    = $State
                    }
                
                    # Convert to JSON and send the request
                    $body = (ConvertTo-Json -Compress -Depth 10 -InputObject $CurrentInfo)
                (New-GraphPostRequest -tenantid $TenantFilter -Uri 'https://graph.microsoft.com/beta/policies/authenticationmethodspolicy/authenticationMethodConfigurations/TemporaryAccessPass' -Type patch -asApp $true -Body $body -ContentType 'application/json') 
                
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } elseif ($State -eq 'disabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } else {
                # Catch invalid input
                Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
            } 
        } 
    
        # Hardware OATH tokens (Preview)
        'HardwareOATH' {  

            if ($State -eq 'enabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } elseif ($State -eq 'disabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } else {
                # Catch invalid input
                Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
            }
        }
        # Third-party software OATH tokens
        'softwareOath' {  

            if ($State -eq 'enabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } elseif ($State -eq 'disabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } else {
                # Catch invalid input
                Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
            }
        }
        # Voice call
        'Voice' {  

            if ($State -eq 'enabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } elseif ($State -eq 'disabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } else {
                # Catch invalid input
                Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
            }
        }
        # Email OTP
        'Email' {  

            if ($State -eq 'enabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } elseif ($State -eq 'disabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } else {
                # Catch invalid input
                Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
            }
        }
        # Certificate-based authentication
        'x509Certificate' {  
            
            if ($State -eq 'enabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } elseif ($State -eq 'disabled') {
                try {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Enabled $AuthenticationMethodId Support" -sev Info
                } catch {
                    Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
                }
            } else {
                # Catch invalid input
                Write-LogMessage -API $APIName -tenant $TenantFilter -message "Failed to $State $AuthenticationMethodId Support: $($_.exception.message)" -sev Error
            }

        }
        Default {
            Write-LogMessage -API $APIName -tenant $TenantFilter -message 'Somehow you hit the default case. You did something wrong' -sev Error
            return 'Somehow you hit the default case. You did something wrong'
        }
    }











}
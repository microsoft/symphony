BeforeAll {
  Import-Module BenchPress.Azure

  # arrange
  $storageAccountResourceGroupName = $env:storageAccountResourceGroupName
  $storageAccountName = $env:storageAccountName
  $appConfigResourceGroupName = $env:appConfigResourceGroupName
  $appConfigAccountName = $env:appConfigAccountName
  $appConfigItemsLength = $env:appConfigItemsLength
}

Describe "End to End Tests" {
  Context "Test end to end" {
    It "should check the parameters and environment variables configured correctly" {
      # act and assert
      $storageAccountResourceGroupName | Should -Not -Be $Null
      $storageAccountName | Should -Not -Be $Null
      $appConfigResourceGroupName | Should -Not -Be $Null
      $appConfigAccountName | Should -Not -Be $Null
      $appConfigItemsLength | Should -BeGreaterThan 0
    }

    It "should check the storage account is ready" {
      # act and assert
      $storageAccountResource = Confirm-AzBPStorageAccount -ResourceGroupName $storageAccountResourceGroupName -Name $storageAccountName
      $storageAccountResource | Should -Be -Not $null
    }

    It "should check the storage account is configured correctly" {
      # act and assert
      $storageAccountResource = Confirm-AzBPStorageAccount -ResourceGroupName $storageAccountResourceGroupName -Name $storageAccountName

      $storageAccountResource.ResourceDetails.ProvisioningState | Should -Be "Succeeded"
      $storageAccountResource.ResourceDetails.Kind | Should -Be "StorageV2"
      $storageAccountResource.ResourceDetails.Sku.Name | Should -Be "Standard_LRS"
      $storageAccountResource.ResourceDetails.EnableHttpsTrafficOnly | Should -Be $true
    }

    It "should check the app config is ready" {
      # act and assert
      $appConfigResource = Get-AzBPResource -ResourceName $appConfigAccountName -ResourceGroupName $appConfigResourceGroupName

      $appConfigResource | Should -Be -Not $null
    }
  }
}

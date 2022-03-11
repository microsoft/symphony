Describe "Infra App"
  Context "Resource Groups - Custom Matcher"
    It 'should have a resource group named azverify-test1'
      When call run_az  "az group show -g azverify-test1 -o json"
      The output should include_name 'azverify-test1'
      The output should include_location 'westus'
      The output should include_json '.properties.provisioningState' 'Succeeded'
      The status should eq 0     
    End         
  End
End
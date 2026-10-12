> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
> 
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
> 
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc. 

## Private endpoint compatibility

Private endpoint role assignments and locks are now applied rather than ignored. Existing callers that supplied these settings will create the corresponding resources on their next apply; omitted or null settings still create none.

The default private endpoint subresource and IP configuration member remain `disks`. Changing `subresource_name` or an IP configuration's `member_name` replaces the private endpoint, including when an older version silently discarded a non-default value for either attribute. Endpoint names, tags, resource addresses, and the `resource_group_name` input's resource group **name** semantics are unchanged.

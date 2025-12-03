asset DefaultProxyEmitterDisablingSetting of UPlayerDefaultProxyEmitterActivationSettings
{
	bCanActivate = false;
}

// A simple generic capability for those situations where we need to disable the audio proxy capabilities.
class UPlayerProxyEmitterDisablingCapability : UHazePlayerCapability
{
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplySettings(DefaultProxyEmitterDisablingSetting, this, EHazeSettingsPriority::Override);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsWithAsset(DefaultProxyEmitterDisablingSetting, this);
	}
}
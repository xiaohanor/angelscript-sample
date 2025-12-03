asset SnowMonkeyShapeshiftProxySettings of UPlayerDefaultProxyEmitterActivationSettings
{
	CameraDistanceActivationBufferDistance = 900;
}

class UTundraSnowMonkeyShapeshiftAudioCapability : UTundraShapeshiftingAudioCapabilityBase
{
	default ShapeshiftShape = ETundraShapeshiftActiveShape::Big;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Player.ApplySettings(SnowMonkeyShapeshiftProxySettings, this, EHazeSettingsPriority::Override);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsWithAsset(SnowMonkeyShapeshiftProxySettings, this);
	}
}
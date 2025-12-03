asset TreeGuardianShapeshiftProxySettings of UPlayerDefaultProxyEmitterActivationSettings
{
	CameraDistanceActivationBufferDistance = 900;
}

class UTundraTreeGuardianShapeshiftAudioCapability : UTundraShapeshiftingAudioCapabilityBase
{
	default ShapeshiftShape = ETundraShapeshiftActiveShape::Big;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Player.ApplySettings(TreeGuardianShapeshiftProxySettings, this, EHazeSettingsPriority::Override);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsWithAsset(TreeGuardianShapeshiftProxySettings, this);
	}
}
asset FantasyOtterShapeshiftProxySettings of UPlayerDefaultProxyEmitterActivationSettings
{
	CameraDistanceActivationBufferDistance = 200;
}

class UTundraFantasyOtterShapeshiftAudioCapability : UTundraShapeshiftingAudioCapabilityBase
{
	default ShapeshiftShape = ETundraShapeshiftActiveShape::Small;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		Player.ApplySettings(FantasyOtterShapeshiftProxySettings, this, EHazeSettingsPriority::Override);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsWithAsset(FantasyOtterShapeshiftProxySettings, this);
	}
}
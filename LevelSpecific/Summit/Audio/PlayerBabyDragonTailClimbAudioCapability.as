
asset PlayerBabyDragonClimbProxySettings of UPlayerDefaultProxyEmitterActivationSettings
{
	bOverride_CameraDistanceActivationBufferDistance = true;
	CameraDistanceActivationBufferDistance = 600;
}

class UPlayerBabyDragonTailClimbAudioCapability : UHazePlayerCapability
{
	UPlayerTailBabyDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DragonComp.ClimbState == ETailBabyDragonClimbState::Enter;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return DragonComp.ClimbState == ETailBabyDragonClimbState::None;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplySettings(PlayerBabyDragonClimbProxySettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsWithAsset(PlayerBabyDragonClimbProxySettings, this);
	}
}
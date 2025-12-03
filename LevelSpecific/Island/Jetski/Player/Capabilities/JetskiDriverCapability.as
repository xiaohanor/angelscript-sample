asset JetskiPlayerHealthSettings of UPlayerHealthSettings
{
	bGameOverWhenBothPlayersDead = true;
};

class UJetskiDriverCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -100;

	UJetskiDriverComponent DriverComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UJetskiDriverComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DriverComp.SpawnJetski();
		DriverComp.ActivateJetski();

		Player.ApplySettings(JetskiPlayerHealthSettings, this);

		if(DriverComp.CameraSettings != nullptr)
		    Player.ApplyCameraSettings(DriverComp.CameraSettings, 0.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
		
		Player.ClearCameraSettingsByInstigator(this);

		DriverComp.DeactivateJetski();
	}
};
struct FDentistBossToggleToolActivationParams
{
	bool bToggleOn;
	EDentistBossTool ToolToToggle;
}

class UDentistBossToggleToolCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossToggleToolActivationParams Params;

	ADentistBoss Dentist;
	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossToggleToolActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Tool = Dentist.Tools[Params.ToolToToggle];
		if(Params.bToggleOn)
			Tool.Activate();
		else
			Tool.Deactivate();

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};
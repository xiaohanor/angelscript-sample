struct FDentistBossToggleToolCollisionActivationParams
{
	bool bToggleOn;
	EDentistBossTool ToolToToggle;
}

class UDentistBossToggleToolCollisionCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossToggleToolCollisionActivationParams Params;

	ADentistBoss Dentist;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossToggleToolCollisionActivationParams InParams)
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
			Tool.RemoveActorCollisionBlock(Dentist);
		else
			Tool.AddActorCollisionBlock(Dentist);

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};
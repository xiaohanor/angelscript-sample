struct FDentistBossBlendViewSizeActivationParams
{
	bool bClear = false;
	AHazePlayerCharacter ViewOverridePlayer;
	EHazeViewPointBlendSpeed BlendSpeed;
	EHazeViewPointSize BlendSize;
}

class UDentistBossBlendViewSizeCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossBlendViewSizeActivationParams Params;

	ADentistBoss Dentist;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossBlendViewSizeActivationParams InParams)
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
		if(Params.bClear)
			Params.ViewOverridePlayer.ClearViewSizeOverride(Dentist, Params.BlendSpeed);
		else
			Params.ViewOverridePlayer.ApplyViewSizeOverride(Dentist, Params.BlendSize, Params.BlendSpeed, EHazeViewPointPriority::Gameplay);
		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};
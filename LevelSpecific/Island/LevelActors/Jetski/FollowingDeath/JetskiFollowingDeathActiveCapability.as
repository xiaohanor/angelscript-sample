class UJetskiFollowingDeathActiveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Jetski::Tags::JetskiFollowingDeath);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AJetskiFollowingDeath FollowingDeath;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FollowingDeath = Cast<AJetskiFollowingDeath>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
#if !RELEASE
		if(DevTogglesJetski::DisableFollowingDeath.IsEnabled())
			return false;
#endif

		if(!Jetski::IsActive())
			return false;

		for(auto Player : Game::Players)
		{
			if(Player.bIsParticipatingInCutscene)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
#if !RELEASE
		if(DevTogglesJetski::DisableFollowingDeath.IsEnabled())
			return true;
#endif

		if(!Jetski::IsActive())
			return true;

		for(auto Player : Game::Players)
		{
			if(Player.bIsParticipatingInCutscene)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FollowingDeath.bIsActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FollowingDeath.bIsActive = false;
	}
};
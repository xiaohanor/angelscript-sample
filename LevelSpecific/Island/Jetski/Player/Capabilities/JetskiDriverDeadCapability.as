class UJetskiDriverDeadCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Death);
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UPlayerHealthComponent HealthComp;
	UPlayerRespawnComponent RespawnComp;

	bool bViewPrioritizesOtherPlayer = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UPlayerHealthComponent::Get(Player);
		RespawnComp = UPlayerRespawnComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HealthComp.bIsDead)
			return false;

		if(RespawnComp.bIsRespawning)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HealthComp.bIsDead)
			return true;

		if(RespawnComp.bIsRespawning)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SetViewPrioritizesOtherPlayer(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ShouldViewPrioritizeOtherPlayer())
			SetViewPrioritizesOtherPlayer(true);
	}

	bool ShouldViewPrioritizeOtherPlayer() const
	{
		if(ActiveDuration < 1)
			return false;

		if(Player.OtherPlayer.IsPlayerDead())
			return false;

		if(Player.OtherPlayer.IsPlayerRespawning())
			return false;

		return true;
	}

	void SetViewPrioritizesOtherPlayer(bool bValue)
	{
		if(bValue == bViewPrioritizesOtherPlayer)
			return;

		bViewPrioritizesOtherPlayer = bValue;

		if(bViewPrioritizesOtherPlayer)
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, EHazeViewPointBlendSpeed::Slow);
		else
			Player.ClearViewSizeOverride(this);
	}
};
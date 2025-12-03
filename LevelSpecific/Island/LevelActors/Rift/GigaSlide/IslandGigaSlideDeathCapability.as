class UIslandGigaSlideDeathCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandGigaSlidePlayerComponent GigaSlideComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GigaSlideComp = UIslandGigaSlidePlayerComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Player.IsPlayerDead())
			return false;

		TArray<FMovementHitResult> Impacts;

		if(MoveComp.HasGroundContact())
			Impacts.Add(MoveComp.GroundContact);

		if(MoveComp.HasWallContact())
			Impacts.Add(MoveComp.WallContact);

		if(MoveComp.HasCeilingContact())
			Impacts.Add(MoveComp.CeilingContact);

		for(FMovementHitResult Impact : Impacts)
		{
			if(GigaSlideComp.IsImpactRelevant(Impact))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FPlayerDeathDamageParams DeathParams;
		DeathParams.bApplyStaticCamera = true;
		Player.KillPlayer(DeathParams);
	}
}
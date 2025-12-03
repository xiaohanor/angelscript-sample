class UDentistBossToolDenturesSwitchTargetCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.bActive)
			return false;

		if(Dentures.bIsAttachedToJaw)
			return false;

		if(!Dentures.bHasLandedOnGround)
			return false;

		if(Dentures.HealthComp.IsDead())
			return false;

		if(!Dentures.TargetPlayer.IsSet())
			return false;

		if(Dentures.IsStandingOnDentures[Dentures.TargetPlayer.Value])
		{
			if(!Dentures.IsStandingOnDentures[Dentures.TargetPlayer.Value.OtherPlayer])
				return true;
		}

		if(Dentures.TargetPlayer.Value.IsPlayerDead())
		{
			// Both players are dead
			if(Dentures.TargetPlayer.Value.OtherPlayer.IsPlayerDead())
				return false;
			
			// Only target is dead, switch target
			return true;
		}

		if(Dentures.bHasHitTarget)
			return true;
			
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
		Dentures.TargetPlayer.Set(Dentures.TargetPlayer.Value.OtherPlayer);
		Dentures.bHasHitTarget = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}
};
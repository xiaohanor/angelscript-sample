class UPrisonBossPlayerDeadCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Boss.IsHacked())
			return false;

		if (!Game::Zoe.IsPlayerDead())
			return false;

		if (Boss.CurrentAttackType != EPrisonBossAttackType::None)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Boss.IsHacked())
			return true;

		if (!Game::Zoe.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.AnimationData.bIsIdling = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsIdling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpTo(Boss.ActorLocation, Boss.MiddlePoint.ActorLocation, DeltaTime, 0.75);
		Boss.SetActorLocation(Loc);
	}
}
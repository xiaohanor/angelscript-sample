class USkylineBallBossMioSpecialGravityFallIntoBallBossCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::Movement;

	ASkylineBallBoss BallBoss;
	UPlayerMovementComponent PlayerMoveComp;

	bool bHasActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		TListedActors<ASkylineBallBoss> BallBosses;
		BallBoss = BallBosses.Single;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bHasActivated)
			return false;

		if (!BallBoss.bInsideActivated)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerMoveComp.IsOnAnyGround())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasActivated = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearGravityDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.OverrideGravityDirection(-BallBoss.FakeRootComp.ForwardVector, this, EInstigatePriority::High);
	}
};
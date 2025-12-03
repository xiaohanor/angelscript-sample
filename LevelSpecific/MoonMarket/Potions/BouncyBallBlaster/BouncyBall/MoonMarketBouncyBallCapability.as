class UMoonMarketBouncyBallCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UHazeMovementComponent MoveComp;

	const float MinVelocity = 10;
	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration < 1)
			return false;
		
		if(MoveComp.Velocity.Size() < MinVelocity)
			return true;

		if(ActiveDuration > 10)
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
		Niagara::SpawnOneShotNiagaraSystemAtLocation(Cast<AMoonMarketBouncyBall>(Owner).DespawnPoof, Owner.ActorLocation);
		Owner.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};
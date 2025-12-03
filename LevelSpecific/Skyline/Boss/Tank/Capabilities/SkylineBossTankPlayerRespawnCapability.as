class USkylineBossTankPlayerRespawnCapability : USkylineBossTankChildCapability
{
	TPerPlayer<UPlayerRespawnComponent> PlayerRespawnComp;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BossTank.IsActorDisabled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BossTank.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		for (auto Player : Game::Players)
			PlayerRespawnComp[Player] = UPlayerRespawnComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto RespawnComp : PlayerRespawnComp)
		{
			FOnRespawnOverride Delegate;
			Delegate.BindUFunction(this, n"GetRespawnPoint");
			RespawnComp.ApplyRespawnOverrideDelegate(this, Delegate, EInstigatePriority::High);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto RespawnComp : PlayerRespawnComp)
		{
			RespawnComp.ClearRespawnOverride(this);
		}
	}

	UFUNCTION()
	private bool GetRespawnPoint(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		if(BossTank.RespawnSpline == nullptr)
			return false;

		auto Boss = ASkylineBossTank::Get();
		if(Boss == nullptr)
			return false;

		FSplinePosition SplinePosition = BossTank.RespawnSpline.Spline.GetClosestSplinePositionToWorldLocation(Boss.ActorLocation);
		
		// Move half the length of the spline to end up on the other side
		SplinePosition.Move(BossTank.RespawnSpline.Spline.SplineLength * 0.5);
		const FTransform SplineTransform = SplinePosition.WorldTransform;

		const FVector ToBoss = Boss.ActorLocation - SplineTransform.Location;
		FQuat ToBossRotation = FQuat::MakeFromZX(FVector::UpVector, ToBoss);
		OutLocation.RespawnTransform = FTransform(ToBossRotation, SplineTransform.Location);
		OutLocation.bRecalculateOnRespawnTriggered = false;
		return true;
	}
}
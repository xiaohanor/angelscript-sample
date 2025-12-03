class UGameShowArenaBombCaughtCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;

	AGameShowArenaBomb Bomb;
	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	float MoveDuration = 0.15;

	FVector StartLocation;

	FVector ControlPoint;
	FVector InitialVelocity;

	float FillAlpha;
	FVector FillColor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bomb = Cast<AGameShowArenaBomb>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
		// MoveComp.AddMovementIgnoresActor(Game::Mio, Game::Mio);
		// MoveComp.AddMovementIgnoresActor(Game::Zoe, Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Bomb.State.Get() != EGameShowArenaBombState::Caught)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Bomb.State.Get() != EGameShowArenaBombState::Caught)
			return true;

		if (ActiveDuration > MoveDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Bomb.SetActorControlSide(Bomb.Holder);
		StartLocation = Bomb.ActorLocation;
		Bomb.bIsCaught = true;
		FVector TargetPoint = Bomb.Holder.Mesh.GetSocketLocation(n"Backpack");
		FVector HalfWayPoint = (TargetPoint + StartLocation) * 0.5;
		ControlPoint = HalfWayPoint - Bomb.Holder.ActorForwardVector * 50;
		InitialVelocity = Bomb.ActorVelocity;
		MoveComp.Reset(true);
		Bomb.SetActorEnableCollision(false);
		Bomb.BlockCapabilities(n"BombContactExplosion", this);

		Bomb.TimeUntilExplosion = Bomb.GetMaxExplodeTimerDuration();
		Bomb.AirborneHazeSphere.SetVisibility(false);
		FillAlpha = Bomb.GetFillAlpha();
		FillColor = Bomb.GetFillColor();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HasControl())
			Bomb.CrumbStartHolding();

		Bomb.UnblockCapabilities(n"BombContactExplosion", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float Alpha = Math::Saturate(ActiveDuration / MoveDuration);
				FVector TargetPoint = Bomb.Holder.Mesh.GetSocketLocation(n"Backpack");
				FVector NewLocation = BezierCurve::GetLocation_1CP(StartLocation, ControlPoint, TargetPoint, Alpha);
				FVector Delta = NewLocation - Bomb.ActorLocation;
				Movement.AddDelta(Delta);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			float CurrentFillAlpha = Math::Lerp(FillAlpha, 0, ActiveDuration / MoveDuration);
			FVector CurrentFillColor = Math::Lerp(FillColor, FVector::ZeroVector, ActiveDuration / MoveDuration);
			Bomb.UpdateFillMaterial(CurrentFillAlpha, CurrentFillColor);
			MoveComp.ApplyMove(Movement);
		}
	}
};
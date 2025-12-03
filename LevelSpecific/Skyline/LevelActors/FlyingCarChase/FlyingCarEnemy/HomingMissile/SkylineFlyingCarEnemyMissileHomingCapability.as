class USkylineFlyingCarEnemyMissileHomingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASkylineFlyingCarEnemyMissile Missile;

	float HomingDuration = 7;
	FVector InitialVelocity;
	float MaxDistance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Missile = Cast<ASkylineFlyingCarEnemyMissile>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Missile.bIsHoming)
			return false;
		if(Missile.bIsClosingIn)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Missile.bIsHoming)
			return true;
		if(Missile.bIsClosingIn)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialVelocity = Missile.Velocity;
		MaxDistance = (Missile.FlyingCar.ActorLocation - Missile.ActorLocation).Size();

		Missile.RotationPivotOffset = Missile.RotationPivot.RelativeLocation;
		Missile.MeshRootOffset = Missile.MeshRoot.RelativeLocation;
		Missile.StartHomingVelocity = Missile.Velocity;

		USkylineFlyingCarEnemyMissileEventHandler::Trigger_HomingIn(Game::Zoe, FSkylineEnemyMissileEventData(Missile));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float VelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(Missile.CloseInDistance, MaxDistance), FVector2D(0, 1), Missile.ToTarget.Size());
		float Speed = Math::Lerp(Missile.MinVelocity, Missile.MaxVelocity, VelocityAlpha);


		float DurationAlpha = Math::Clamp(ActiveDuration, 0, 1);
		Missile.Velocity = InitialVelocity.SlerpTowards(Missile.ToTarget, DurationAlpha).SafeNormal * Speed;

		if(ActiveDuration >= HomingDuration)
			Missile.bIsClosingIn = true;
	}
}
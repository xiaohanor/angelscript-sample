class UStormDragonTornadoCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStormDragonTornado Tornado;
	UCameraShakeBase CamShakeInstance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Tornado = Cast<AStormDragonTornado>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Tornado.bTornadoActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(Tornado.CameraShake, this, Tornado.ActorLocation + (FVector::UpVector * 12000), 4000.0, 10000.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Tornado.LargeDebrisRoot.RelativeRotation += FRotator(0.0, Tornado.LargeRotationSpeed * Tornado.Direction, 0.0) * DeltaTime;
		Tornado.LargeSlowDebrisRoot.RelativeRotation += FRotator(0.0, Tornado.LargeRotationSpeed * Tornado.Direction * 1.2, 0.0) * DeltaTime;
		Tornado.SmallDebrisRoot.RelativeRotation += FRotator(0.0, Tornado.SmallRotationSpeed * Tornado.Direction, 0.0) * DeltaTime;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector Delta = Player.ActorLocation - Tornado.ActorLocation;
			Delta = Delta.ConstrainToPlane(FVector::UpVector);
			if (Delta.Size() < Tornado.DamageRadius)
			{
				Player.DamagePlayerHealth(Tornado.Damage);
				Player.AddDamageInvulnerability(this, 1.5);
			}
		}
	}
};
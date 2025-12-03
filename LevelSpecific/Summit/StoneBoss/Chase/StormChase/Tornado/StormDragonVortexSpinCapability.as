class UStormDragonVortexSpinCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStormDragonVortex Vortex;
	UCameraShakeBase CamShakeInstance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Vortex = Cast<AStormDragonVortex>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Vortex.bTornadoActive)
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
			Player.PlayWorldCameraShake(Vortex.CameraShake, this, Vortex.ActorLocation + (FVector::UpVector * 12000), 4000.0, 10000.0);
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
		// Vortex.LargeDebrisRoot.RelativeRotation += FRotator(0.0, Vortex.LargeRotationSpeed * Vortex.Direction, 0.0) * DeltaTime;
		// Vortex.LargeSlowDebrisRoot.RelativeRotation += FRotator(0.0, Vortex.LargeRotationSpeed * Vortex.Direction * 1.2, 0.0) * DeltaTime;
		// Vortex.SmallDebrisRoot.RelativeRotation += FRotator(0.0, Vortex.SmallRotationSpeed * Vortex.Direction, 0.0) * DeltaTime;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector Delta = Player.ActorLocation - Vortex.ActorLocation;
			Delta = Delta.ConstrainToPlane(FVector::UpVector);
			if (Delta.Size() < Vortex.DamageRadius)
			{
				Player.DamagePlayerHealth(Vortex.Damage);
				Player.AddDamageInvulnerability(this, 1.5);
			}
		}
	}
};
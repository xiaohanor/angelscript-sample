class UTowerCubeRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ATowerCube TowerCube;
	UMovementImpactCallbackComponent ImpactComp;

	FHazeAcceleratedFloat AccelFloat;
	float RotSpeed = 360;

	float RotateMinTime = 1.0;
	float NewRotTime;
	bool bRotTimeSet;

	float CountdownCheck;
	float CountdownDuration = 0.75;

	FRotator OriginalRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TowerCube = Cast<ATowerCube>(Owner);
		ImpactComp = UMovementImpactCallbackComponent::Get(TowerCube);

		OriginalRotation = TowerCube.ActorRotation;
		CountdownCheck = CountdownDuration;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (TowerCube.bIsDefaultCube)
			return false;

		if (!TowerCube.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TowerCube.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CountdownCheck = CountdownDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ImpactComp.GetImpactingPlayers().Num() == 1)
		{
			CountdownCheck -= DeltaTime;

			float Sin = Math::Sin(Time::GameTimeSeconds * 25.0);
			TowerCube.MeshRoot.RelativeRotation = FRotator(0.0, 2.0, 0.0) * Sin;

			if (CountdownCheck <= 0.0)
			{
				// bRotTimeSet = true;
				// NewRotTime = Time::GameTimeSeconds + RotateMinTime;
				TowerCube.MeshRoot.RelativeRotation = FRotator(0.0);
				TowerCube.DeactivateCube();
				TowerCube.OnTowerCubeThrowPlayersOff.Broadcast();
				// CountdownCheck = CountdownDuration;
				// TowerCube.ActorRotation = Math::RInterpConstantTo(TowerCube.ActorRotation, OriginalRotation, DeltaTime, 360.0);
			}
		}
		// else
		// {
		// 	if (CountdownCheck != CountdownDuration)
		// 		CountdownCheck = CountdownDuration;
		// }

		// if (Time::GameTimeSeconds < NewRotTime)
		// {
		// 	TowerCube.AddActorLocalRotation(FRotator(0.0, 0, 1.0) * RotSpeed * DeltaTime);
		// 	for (AHazePlayerCharacter Player : ImpactComp.GetImpactingPlayers())
		// 	{
		// 		Player.AddMovementImpulse(TowerCube.ActorRightVector * 1000.0);
		// 		Player.AddMovementImpulse(FVector::UpVector * 1500.0);
		// 	} 
		// }
		// else
		// {
		// 	if (bRotTimeSet)
		// 	{
		// 		TowerCube.DeactivateCube();
		// 		TowerCube.OnTowerCubeThrowPlayersOff.Broadcast();
		// 		CountdownCheck = CountdownDuration;
		// 		TowerCube.ActorRotation = Math::RInterpConstantTo(TowerCube.ActorRotation, OriginalRotation, DeltaTime, 360.0);
		// 		// bRotTimeSet = false;
		// 	}

		// }
	}
};
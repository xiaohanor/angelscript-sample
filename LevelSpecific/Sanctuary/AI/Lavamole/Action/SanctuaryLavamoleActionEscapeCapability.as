struct FSanctuaryLavamoleActionEscapeData
{
}

class USanctuaryLavamoleActionEscapeCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryLavamoleActionEscapeData Params;
	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::Action);
	AAISanctuaryLavamole Mole;

	FVector StartLocation;
	float WiggleRotationTimer = 0.0;
	float DurationToEscape = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mole = Cast<AAISanctuaryLavamole>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FSanctuaryLavamoleActionEscapeData Parameters)
	{
		Params = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > DurationToEscape)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WiggleRotationTimer = 0.0;
		Mole.Bite1Comp.Disable(this);
		StartLocation = Mole.ActorLocation;
		FVector Diff = (Mole.OccupiedHole.ActorLocation - StartLocation);
		float SpeedPerSecond = Mole.Settings.EscapeSpeed;// 2500.0;
		DurationToEscape = Diff.Size() * (1.0 / SpeedPerSecond);
		Owner.BlockCapabilities(LavamoleTags::LavaMoleFacePlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mole.Bite1Comp.Enable(this);
		Mole.DisableAutoTargeting(false);
		Owner.SetActorLocation(Mole.OccupiedHole.ActorLocation);
		Owner.SetActorRotation(FRotator::MakeFromXZ(-Mole.ActorUpVector, FVector::UpVector));
		Owner.UnblockCapabilities(LavamoleTags::LavaMoleFacePlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		WiggleRotationTimer += DeltaTime * Mole.Settings.EscapeWiggleRotationSpeed;
		float WiggleDegrees = Math::Sin(WiggleRotationTimer) * Mole.Settings.EscapeWiggleRotationMax;
		FVector TowardsDigLocation = (Mole.OccupiedHole.ActorLocation - Mole.ActorLocation).GetSafeNormal();
		FVector NewDirection = FVector::UpVector.RotateAngleAxis(WiggleDegrees, TowardsDigLocation);
		Owner.SetActorRotation(FRotator::MakeFromXZ(NewDirection, TowardsDigLocation));

		float Alpha = Math::Clamp(ActiveDuration / DurationToEscape, 0.0, 1.0);
		float Interpolation = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
		FVector LerpedLocation = Math::Lerp(StartLocation, Mole.OccupiedHole.ActorLocation, Interpolation);
		LerpedLocation.Z = Mole.OccupiedHole.ActorLocation.Z;
		Owner.SetActorLocation(LerpedLocation);
	}
}
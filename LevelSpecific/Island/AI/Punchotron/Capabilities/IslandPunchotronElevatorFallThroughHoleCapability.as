class UIslandPunchotronElevatorFallThroughHoleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"FallThroughHole");

	UHazeActorRespawnableComponent RespawnComp;
	UIslandPunchotronAttackComponent AttackComp;
	UBasicAICharacterMovementComponent MoveComp;
	UIslandPunchotronElevatorFallComponent ElevatorFallComp;

	AAIIslandPunchotron Punchotron;
	UIslandPunchotronSettings Settings;

	TArray<AIslandRedBlueForceField> ForceFields;

	FVector FallDir;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		ElevatorFallComp = UIslandPunchotronElevatorFallComponent::GetOrCreate(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		Punchotron = Cast<AAIIslandPunchotron>(Owner);
	}


	UFUNCTION()
	private void Reset()
	{
		UIslandPunchotronSettings::ClearGroundFriction(Owner, this);
		UMovementGravitySettings::ClearGravityScale(Owner, this);
		UMovementSteppingSettings::ClearRedirectMovementOnWallImpacts(Owner, this);
		UMovementSteppingSettings::ClearStepUpSize(Owner, this);
		Cast<AHazeCharacter>(Owner).Mesh.SetRelativeRotation(FRotator::ZeroRotator);
		FindClosestForceFields();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MoveComp.IsInAir())
			return false;

		for (AIslandRedBlueForceField ForceField : ForceFields)
		{
			if (ForceField.IsMovementComponentIgnored(MoveComp))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		for (AIslandRedBlueForceField ForceField : ForceFields)
		{
			if (ForceField.IsMovementComponentIgnored(MoveComp))
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		float Friction = Settings.GroundFriction * 10.5;
		float FrictionFactor = Math::GetMappedRangeValueClamped(FVector2D(1000, 4000), FVector2D(1, 4), Owner.ActorVelocity.Size2D());
		Friction *= FrictionFactor;
		UIslandPunchotronSettings::SetGroundFriction(Owner, Friction, this);
		UMovementGravitySettings::SetGravityScale(Owner, 7.5, this);
		UMovementSteppingSettings::SetRedirectMovementOnWallImpacts(Owner, false, this);
		UMovementSteppingSettings::SetStepUpSize(Owner, FMovementSettingsValue::MakeValue(0.0), this);

		// Try find relative location to hole here
		for (AIslandRedBlueForceField ForceField : ForceFields)
		{
			if (!ForceField.IsMovementComponentIgnored(MoveComp))
				continue;

			TArray<FIslandForceFieldHoleData> HoleDataArray = ForceField.GetHoleData();
			for (FIslandForceFieldHoleData HoleData : HoleDataArray)
			{
				float Radius = HoleData.HoleRadius;					
				FVector HoleWorldLocation = ForceField.GetHoleWorldLocation(HoleData);
				if (Owner.ActorLocation.IsWithinDist2D(HoleWorldLocation, Radius))
				{
					if (!Owner.ActorLocation.IsWithinDist2D(HoleWorldLocation, 150) || Radius - 150 < 0)
					{
						// Tip towards center of hole from edges of hole or when hole is small.
						FallDir	= (HoleWorldLocation - Owner.ActorLocation).GetSafeNormal2D();
						FallDir = FallDir.RotateTowards(FVector::UpVector, 45);
						FRotator FallTargetRotation = FRotator::MakeFromZX(FallDir, Owner.ActorForwardVector);
						ElevatorFallComp.FallTargetRotation = FallTargetRotation;
					}
					else
					{
						// Maintain orientation
						ElevatorFallComp.FallTargetRotation = Owner.ActorRotation;
					}
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UIslandPunchotronSettings::ClearGroundFriction(Owner, this);
		UMovementGravitySettings::ClearGravityScale(Owner, this);
		UMovementSteppingSettings::ClearRedirectMovementOnWallImpacts(Owner, this);
		UMovementSteppingSettings::ClearStepUpSize(Owner, this);
		Owner.SetActorRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{		
		if (MoveComp.IsOnAnyGround())
		{
			for (AIslandRedBlueForceField ForceField : ForceFields)
			{
				ForceField.OnUnregisterMoveComp(MoveComp);
			}
		}
	}

	void FindClosestForceFields()
	{
		ForceFields.Empty();
		TListedActors<AIslandRedBlueForceField> LevelForceFields;
		AIslandRedBlueForceField ClosestBlue = nullptr;
		float ClosestBlueSqrDist = BIG_NUMBER;
		AIslandRedBlueForceField ClosestRed = nullptr;
		float ClosestRedSqrDist = BIG_NUMBER;

		for (AIslandRedBlueForceField ForceField : LevelForceFields)
		{
			float SqrDist = ForceField.GetSquaredHorizontalDistanceTo(Owner);
			if (ForceField.ForceFieldType == EIslandRedBlueShieldType::Red)
			{
				if (SqrDist < ClosestRedSqrDist)
				{
					ClosestRed = ForceField;
					ClosestRedSqrDist = SqrDist;
				}
			}
			else if (ForceField.ForceFieldType == EIslandRedBlueShieldType::Blue)
			{
				if (SqrDist < ClosestBlueSqrDist)
				{
					ClosestBlue = ForceField;
					ClosestBlueSqrDist = SqrDist;
				}
			}
		}

		if (ClosestBlue != nullptr)
			ForceFields.Add(ClosestBlue);
		if (ClosestRed != nullptr)
			ForceFields.Add(ClosestRed);
	}

}
class UTeenDragonRollCheckForObstacleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonJump);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UHazeMovementComponent MoveComp;

	UTeenDragonRollSettings RollSettings;

	UMovementStandardSettings MoveStandardSettings;

	const float VelocitySampleDurationForTraceLength = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
		MoveStandardSettings = UMovementStandardSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!RollComp.IsRolling())
			return false;

		if (!DragonComp.bIsInAirFromJumping)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!RollComp.IsRolling())
			return true;

		if (!DragonComp.bIsInAirFromJumping)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.bIsAboutToLandFromAirRoll = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.bIsAboutToLandFromAirRoll = true;
	}

	const float MinTraceLength = 500.0;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TraceForWalls();
		TraceForGround();
	}

	void TraceForGround()
	{
		float TraceLength;
		if (MoveComp.VerticalVelocity.Z > 0)
		{
			DragonComp.bIsAboutToLandFromAirRoll = MoveComp.HasGroundContact();
			return;
		}
		else
		{
			TraceLength = MoveComp.VerticalVelocity.Size() * 0.1;
			TraceLength = Math::Max(TraceLength, 500);
		}

		FHazeTraceSettings ObstacleTrace;
		ObstacleTrace.TraceWithPlayer(Player);
		FVector Start = Player.ActorCenterLocation;
		FVector End = Start + FVector::DownVector * TraceLength;
		FHazeTraceShape TraceShape = FHazeTraceShape::MakeCapsule(Player.CapsuleComponent.CapsuleRadius * 0.75, Player.CapsuleComponent.CapsuleHalfHeight * 0.75);
		ObstacleTrace.UseShape(TraceShape);
		auto Hit = ObstacleTrace.QueryTraceSingle(Start, End);
		auto TemporalLog = TEMPORAL_LOG(Player, "Roll Jump Ground Trace").HitResults("Ground Trace", Hit, TraceShape);
		if (!Hit.bBlockingHit)
		{
			DragonComp.bIsAboutToLandFromAirRoll = MoveComp.HasGroundContact();
			TemporalLog.Status("No hit", FLinearColor::Red);
		}
		else
		{
			DragonComp.bIsAboutToLandFromAirRoll = true;
			TemporalLog.Status("Hit", FLinearColor::Green);
		}
	}

	void TraceForWalls()
	{
		float TraceLength = MoveComp.HorizontalVelocity.Size() * VelocitySampleDurationForTraceLength;
		TraceLength = Math::Max(TraceLength, MinTraceLength);
		FHazeTraceSettings ObstacleTrace;
		ObstacleTrace.TraceWithPlayer(Player);
		FVector Start = Player.ActorCenterLocation;
		FVector End = Start + Player.ActorForwardVector * TraceLength;
		FHazeTraceShape TraceShape = FHazeTraceShape::MakeCapsule(Player.CapsuleComponent.CapsuleRadius * 0.75, Player.CapsuleComponent.CapsuleHalfHeight * 0.75);
		ObstacleTrace.UseShape(TraceShape);
		auto Hit = ObstacleTrace.QueryTraceSingle(Start, End);
		auto TemporalLog = TEMPORAL_LOG(Player, "Roll Jump Obstacle Trace").HitResults("Roll Jump Obstacle Trace", Hit, TraceShape);
		if (!Hit.bBlockingHit)
		{
			DragonComp.bWillHitObjectWhileRollJumping = false;
			TemporalLog.Status("No hit", FLinearColor::Red);
		}
		else
		{
			FVector Normal = Hit.Normal;
			float DegreesToNormal = Normal.GetAngleDegreesTo(FVector::UpVector);
			// Is Ground
			if (DegreesToNormal < MoveStandardSettings.WalkableSlopeAngle)
			{
				DragonComp.bWillHitObjectWhileRollJumping = false;
				TemporalLog.Status("Ground", FLinearColor::Purple);
				return;
			}
			// Is Ceiling
			if (DegreesToNormal > 180 - MoveStandardSettings.CeilingAngle)
			{
				DragonComp.bWillHitObjectWhileRollJumping = false;
				TemporalLog.Status("Ceiling", FLinearColor::LucBlue);
				return;
			}

			TemporalLog.Status("Wall", FLinearColor::Green);
			DragonComp.bWillHitObjectWhileRollJumping = true;
		}
	}
};
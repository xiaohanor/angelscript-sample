class UTeenDragonRollRailMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollRailComponent RollRailComp;
	UTeenDragonRollComponent RollComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UTeenDragonRollRailSettings RollRailSettings;

	const float OffsetInterpSpeed = 20.0;
	const float RotationInterpSpeed = 20.0;

	FSplinePosition CurrentSplinePos;
	float CurrentSpeed = 0.0;
	bool bHasReachedEnd = false;
	FVector RailOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollRailComp = UTeenDragonRollRailComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		RollRailSettings = UTeenDragonRollRailSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonRollRailActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		// So we don't go into it again after leaving it
		if(DeactiveDuration < 0.2)
			return false;
		
		auto RailSplineComp = RollRailComp.GetFirstValidRollRailInRange();
		if(RailSplineComp.IsSet())
		{
			if(!RailSplineComp.Value.bIsEnabled)
				return false;
			
			if(RailSplineComp.Value.bRequireRollToStart)
			{
				if(!RollComp.IsRolling())
					return false;
			}

			Params.EnteredRollRail = RailSplineComp.Value;
			Params.StartSplinePos = RailSplineComp.Value.SplineComp.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
			bool bStartedForwardsOnSpline = Params.StartSplinePos.WorldRotation.ForwardVector.DotProduct(Player.ActorForwardVector) > 0;
			if(!bStartedForwardsOnSpline)
				Params.StartSplinePos.ReverseFacing();
			Params.SpeedAtActivation = Player.ActorVelocity.Size();
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(bHasReachedEnd)
			return true;

		if(!RollRailComp.CurrentRollRail.Value.bIsEnabled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonRollRailActivationParams Params)
	{
		RollRailComp.CurrentRollRail.Set(Params.EnteredRollRail);
		CurrentSplinePos = Params.StartSplinePos;
		CurrentSpeed = Params.SpeedAtActivation;

		RailOffset = Player.ActorLocation - CurrentSplinePos.WorldLocation;
		bHasReachedEnd = false;
		RollRailComp.RollRailInstigators.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RollRailComp.RollRailInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				InterpDownOffset(DeltaTime);

				UpdateSlopeSpeed(DeltaTime);
				CurrentSpeed = Math::Clamp(CurrentSpeed, RollRailSettings.MinSpeed, RollRailSettings.MaxSpeed);
				float RemainingDistance = 0.0;
				bHasReachedEnd = !CurrentSplinePos.Move(CurrentSpeed * DeltaTime, RemainingDistance);

				FRotator NewRotation = Math::RInterpTo(Player.ActorRotation, CurrentSplinePos.WorldRotation.Rotator(), DeltaTime, RotationInterpSpeed);
				Movement.SetRotation(NewRotation);

				float DistanceToEndOfRail = CurrentSplinePos.IsForwardOnSpline()
					? CurrentSplinePos.CurrentSpline.SplineLength - CurrentSplinePos.CurrentSplineDistance
					: CurrentSplinePos.CurrentSplineDistance;

				if(DistanceToEndOfRail <= CurrentSpeed * DeltaTime)
					Movement.AddVelocity(Player.ActorForwardVector * (CurrentSpeed + RemainingDistance));
				else
					Movement.AddDeltaFromMoveToPositionWithCustomVelocity(CurrentSplinePos.WorldLocation + RailOffset, CurrentSplinePos.WorldForwardVector * CurrentSpeed);
			
				TEMPORAL_LOG(DragonComp)
					.Value("Roll Rail Current speed", CurrentSpeed)
					.Value("Distance To End Of Rail", DistanceToEndOfRail)
					.Value("Remaining Distance", RemainingDistance)
				;
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
			MoveComp.ApplyMove(Movement);
		}
	}

	private void InterpDownOffset(float DeltaTime)
	{
		RailOffset = Math::VInterpTo(RailOffset, FVector::ZeroVector, DeltaTime, OffsetInterpSpeed);
	}

	private void UpdateSlopeSpeed(float DeltaTime)
	{
		FVector VelocityDirection = MoveComp.Velocity.GetSafeNormal();

		float SlopeMultiplier = -FVector::UpVector.DotProduct(VelocityDirection);
		float SlopeSpeedChange = (SlopeMultiplier * (SlopeMultiplier < 0.0 ? RollRailSettings.GravityUpSlopeMultiplier : RollRailSettings.GravityDownSlopeMultiplier) * MoveComp.GetGravityForce() * DeltaTime);

		// Going down the rail again
		if(VelocityDirection.DotProduct(CurrentSplinePos.WorldForwardVector) < 0)
			SlopeSpeedChange *= -1;

		CurrentSpeed += SlopeSpeedChange;
	}
};

struct FTeenDragonRollRailActivationParams
{
	USummitTeenDragonRollRailSplineComponent EnteredRollRail;
	FSplinePosition StartSplinePos;
	float SpeedAtActivation = 0.0;
}
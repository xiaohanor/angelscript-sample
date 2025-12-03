class UTundraPlayerFairyWindCurrentMovementCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 3;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::Fairy);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	UTundraPlayerFairyComponent FairyComp;
	USteppingMovementData Movement;
	UTundraPlayerFairySettings Settings;
	UTundraWindCurrentSplineContainer WindCurrentContainer;

	float CurrentDistanceFromPlayer;
	FVector CurrentSplineDirection;
	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
		WindCurrentContainer = UTundraWindCurrentSplineContainer::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraFairyWindCurrentMovementActivatedParams& Params) const
	{
		if(!FairyComp.bIsActive)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(WindCurrentContainer == nullptr)
			return false;

		for(auto Current : WindCurrentContainer.WindCurrents)
		{
			if(Current.IsLocationInWindCurrent(Player.ActorCenterLocation))
			{
				Params.WindCurrent = Current;
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!FairyComp.bIsActive)
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		if(WindCurrentContainer == nullptr)
			return true;

		if(FairyComp.CurrentWindCurrent == nullptr)
			return true;

		float Distance = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorCenterLocation);
		if(!FairyComp.CurrentWindCurrent.IsLocationInWindCurrent(Player.ActorCenterLocation) && (Math::IsNearlyEqual(Distance, 0.0) || Math::IsNearlyEqual(Distance, Spline.GetSplineLength())))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraFairyWindCurrentMovementActivatedParams Params)
	{
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		FairyComp.CurrentWindCurrent = Params.WindCurrent;
		Spline = FairyComp.CurrentWindCurrent.Spline;

		float Dist = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		CurrentSplineDirection = Spline.GetWorldRotationAtSplineDistance(Dist).ForwardVector;

		FVector Vel = MoveComp.GetVelocity();
		CurrentDistanceFromPlayer = CurrentSplineDirection.DotProduct(Vel);
		FairyComp.ResetLeap();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		FairyComp.CurrentWindCurrent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				HandleMoveInput(DeltaTime);
				Movement.AddVelocity(GetSplineVelocity(DeltaTime));
				Movement.AddDelta(GetCorrectionalDelta(DeltaTime));
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	}

	void HandleMoveInput(float DeltaTime)
	{
		FTransform ClosestSplineTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorCenterLocation);
		FVector RightVector = ClosestSplineTransform.Rotation.RightVector;
		FVector UpVector = ClosestSplineTransform.Rotation.UpVector;

		FVector VectorToCenter = (ClosestSplineTransform.Location - Player.ActorCenterLocation).GetSafeNormal() * Math::Min(Player.ActorCenterLocation.Distance(ClosestSplineTransform.Location) / WindCurrentRadius, 1.0);
		FVector MoveInput = MoveComp.MovementInput;

		float RightInput = RightVector.DotProduct(MoveInput);
		float UpInput = UpVector.DotProduct(MoveInput);
		float ToCenterOnRight = RightVector.DotProduct(VectorToCenter);
		float ToCenterOnUp = UpVector.DotProduct(VectorToCenter);

		if(Math::Sign(RightInput) != Math::Sign(ToCenterOnRight))
		{
			if(Math::Abs(RightInput) - Math::Abs(ToCenterOnRight) > 0)
				MoveInput += RightVector * ToCenterOnRight;
			else
				MoveInput -= RightVector * RightInput;
		}

		if(Math::Sign(UpInput) != Math::Sign(ToCenterOnUp))
		{
			if(Math::Abs(UpInput) - Math::Abs(ToCenterOnUp) > 0)
				MoveInput += UpVector * ToCenterOnUp;
			else
				MoveInput -= UpVector * UpInput;
		}

		FVector DeltaToAdd = MoveInput * SteeringMaxSpeed;

		Movement.AddVelocity(DeltaToAdd);
	}

	FVector GetSplineVelocity(float DeltaTime)
	{
		CurrentDistanceFromPlayer += Acceleration * DeltaTime * (FairyComp.CurrentWindCurrent.bFlipWindDirection ? -1 : 1);
		CurrentDistanceFromPlayer = Math::Clamp(CurrentDistanceFromPlayer, -TargetDistance, TargetDistance);
		float ClosestSplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorCenterLocation);
		FVector ClosestLocation = Spline.GetWorldLocationAtSplineDistance(ClosestSplineDistance);

		PrintToScreen(f"{CurrentDistanceFromPlayer=}");
		PrintToScreen(f"{MoveComp.Velocity.Size()=}");

		FVector TargetLoc;
		if((ClosestSplineDistance + CurrentDistanceFromPlayer) < Spline.SplineLength)
		{
			FTransform SplineTransform = Spline.GetWorldTransformAtSplineDistance(ClosestSplineDistance + CurrentDistanceFromPlayer);
			TargetLoc = SplineTransform.Location;
			CurrentSplineDirection = SplineTransform.Rotation.ForwardVector * (FairyComp.CurrentWindCurrent.bFlipWindDirection ? -1 : 1);
		}
		else
		{
			TargetLoc = ClosestLocation + (CurrentSplineDirection * CurrentDistanceFromPlayer);
		}
		FairyComp.WindCurrentTargetLocation = TargetLoc;

		return TargetLoc - ClosestLocation;
	}

	FVector GetCorrectionalDelta(float DeltaTime)
	{
		FTransform ClosestSplineTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorCenterLocation);

		FVector RawCorrectionalDelta = (ClosestSplineTransform.Location - Player.ActorCenterLocation);
		RawCorrectionalDelta -= ClosestSplineTransform.Rotation.ForwardVector * RawCorrectionalDelta.DotProduct(ClosestSplineTransform.Rotation.ForwardVector);
		float MaxCorrectionalDistance = RawCorrectionalDelta.Size(); // This is the max allowed correctional distnace, if the current delta is above this, the player would overshoot if not clamping

		FVector MultipliedCorrectionalDelta = RawCorrectionalDelta * (CorrectionalSpeedMultiplier * DeltaTime);
		float CurrentCorrectionalDistance = MultipliedCorrectionalDelta.Size();

		return MultipliedCorrectionalDelta.GetSafeNormal() * Math::Min(MaxCorrectionalDistance, CurrentCorrectionalDistance);
	}

	float GetTargetDistance() property
	{
		return FairyComp.CurrentWindCurrent.TargetSpeed;
	}

	float GetAcceleration() property
	{
		return FairyComp.CurrentWindCurrent.Acceleration;
	}

	float GetSteeringMaxSpeed() property
	{
		return FairyComp.CurrentWindCurrent.SteeringMaxSpeed;
	}

	float GetWindCurrentRadius() property
	{
		return FairyComp.CurrentWindCurrent.WindCurrentRadius;
	}

	float GetCorrectionalSpeedMultiplier() property
	{
		return FairyComp.CurrentWindCurrent.CorrectionalSpeedMultiplier;
	}
}

struct FTundraFairyWindCurrentMovementActivatedParams
{
	ATundraWindCurrentSpline WindCurrent;
}
struct FTeenDragonTailGeckoClimbMovementDeactivationParams
{
	bool bWalkedOffWall = false;
}

class UTeenDragonTailGeckoClimbMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 78;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;
	UTeenDragonTailGeckoClimbOrientationComponent OrientationComp;
	UCameraUserComponent UserComp;
	UCritterLatchOnComponent AnnoyingCrittersComp;

	UTeenDragonTailClimbableComponent CurrentClimbComp;

	UTeenDragonTailGeckoClimbSettings ClimbSettings;

	FHazeAcceleratedRotator AccMeshRotation;
	float CurrentSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		OrientationComp = UTeenDragonTailGeckoClimbOrientationComponent::Get(Player);

		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
		UserComp = UCameraUserComponent::Get(Player);
		AnnoyingCrittersComp = UCritterLatchOnComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if((!GeckoClimbComp.bIsJumpingOntoWall || GeckoClimbComp.JumpOntoWallAlpha < 1.0)
		&& !GeckoClimbComp.bHasLandedOnWall)
		 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTeenDragonTailGeckoClimbMovementDeactivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!GeckoClimbComp.IsOnClimbableWall())
			return true;

		if(ShouldFall())
		{
			Params.bWalkedOffWall = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TailDragonComp.ClimbingInstigators.Add(this);

		GeckoClimbComp.bHasLandedOnWall = false;
		
		AccMeshRotation.SnapTo(Player.Mesh.WorldRotation);

		TailDragonComp.AnimationState.Apply(ETeenDragonAnimationState::TailClimb, this);

		float StartSpeed = Player.ActorVelocity.DotProduct(Player.ActorForwardVector);
		StartSpeed = Math::Clamp(StartSpeed, ClimbSettings.MinimumSpeed, ClimbSettings.MaximumSpeed);
		CurrentSpeed = StartSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTeenDragonTailGeckoClimbMovementDeactivationParams Params)
	{
		TailDragonComp.ClimbingInstigators.RemoveSingleSwap(this);

		if(!TailDragonComp.bTopDownMode)
			Player.StopCameraShakeByInstigator(this);

		if(Params.bWalkedOffWall)
			GeckoClimbComp.TimeLastWalkedOffWall = Time::GameTimeSeconds;

		TailDragonComp.AnimationState.Clear(this);
		Player.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				// TODO: (FL) Fix this nonsense
				Player.ClearMovementInput(this);
				float InputDeadzone = KINDA_SMALL_NUMBER;
				if(GeckoClimbComp.bRestrictClimbToVertical)
				{
					InputDeadzone = 0.2;
				}

				FVector TargetDirection = MoveComp.MovementInput;

				float InputSize = MoveComp.MovementInput.Size();

				// TODO: (FL) Fix this nonsense
				if(InputSize < InputDeadzone)
				{
					Player.ApplyMovementInput(FVector::ZeroVector, this, EInstigatePriority::High);
				}

				
				// While on edges, we force the player of them.
				if (TargetDirection.IsNearlyZero(InputDeadzone))
				{
					TargetDirection = Player.ActorForwardVector;
				}

				// Have to do the interp in walls local space because quaternion fuckery?
				// Otherwise it interps over the wrong axis
				FVector LocalTargetDirection = OrientationComp.WorldTransform.InverseTransformVector(TargetDirection);
				if(GeckoClimbComp.bRestrictClimbToVertical)
				{
					LocalTargetDirection = LocalTargetDirection.ProjectOnToNormal(OrientationComp.WorldTransform.InverseTransformVector(FVector::UpVector));
				}
				FVector LocalDirection = OrientationComp.WorldTransform.InverseTransformVector(Player.ActorForwardVector);

				// So dragon has time to land before being able to rotate
				if(ActiveDuration > 0.5)
					LocalDirection =  Math::QInterpConstantTo(LocalDirection.ToOrientationQuat(), LocalTargetDirection.ToOrientationQuat(), DeltaTime, ClimbSettings.ClimbTurnSpeed).ForwardVector;

				FVector Direction = OrientationComp.WorldTransform.TransformVector(LocalDirection);

				float SpeedAlpha = Math::Clamp((InputSize - ClimbSettings.MinimumInput) / (1.0 - ClimbSettings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(ClimbSettings.MinimumSpeed, ClimbSettings.MaximumSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;

				if(InputSize < InputDeadzone)
					TargetSpeed = 0.0;
				
				TargetSpeed *= AnnoyingCrittersComp.GetLatchedOnCrittersSpeedFactor();	

				// Update new velocity
				float SpeedAcceleration = ClimbSettings.AccelerationSpeed;
				if (InputSize <= 0.01)
					SpeedAcceleration = ClimbSettings.SlowDownInterpSpeed;
	
				// if (ActiveDuration > 0.4)
					CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, TargetSpeed, DeltaTime, SpeedAcceleration);
				
				FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;

				TEMPORAL_LOG(GeckoClimbComp)
					.DirectionalArrow("Horizontal Velocity", Player.ActorLocation, HorizontalVelocity * 10 , 20, 40, FLinearColor::Teal)
					.DirectionalArrow("Orientation Up", Player.ActorLocation, OrientationComp.UpVector * 500 , 20, 40, FLinearColor::Blue)
					.DirectionalArrow("Orientation Forward", Player.ActorLocation, OrientationComp.ForwardVector * 500, 20, 40, FLinearColor::Red)
					.DirectionalArrow("Orientation Right", Player.ActorLocation, OrientationComp.RightVector * 500, 20 ,40 , FLinearColor::Green)
				;
				
				// if (ActiveDuration > 0.4)
					Movement.AddHorizontalVelocity(HorizontalVelocity);
				
				Movement.StopMovementWhenLeavingEdgeThisFrame();
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();

				if(MoveComp.HasUnstableGroundContactEdge())
				{
					GeckoClimbComp.bWantsToFall = true;
				}
				

				FRotator Rotation = FRotator::MakeFromXZ(Direction, MoveComp.WorldUp);
				Movement.SetRotation(Rotation);
			}
			// Remove update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			TailDragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TailTeenClimb);
		}
	}

	bool ShouldFall() const
	{
		auto TemporalLog = TEMPORAL_LOG(Player, "Wall Climb");

		FHazeTraceSettings ForwardTrace;
		ForwardTrace.TraceWithPlayerProfile(Player);
		ForwardTrace.UseLine();
		ForwardTrace.IgnorePlayers();

		FVector Start = Player.ActorLocation
			+ Player.ActorUpVector * 50;
		FVector End = Start
			+ Player.ActorForwardVector * 300.0;

		auto ForwardHit = ForwardTrace.QueryTraceSingle(Start, End);
		TemporalLog.HitResults("Forward Trace", ForwardHit, FHazeTraceShape::MakeLine());
		if(ForwardHit.bBlockingHit)
			return false;

		FHazeTraceSettings LedgeTrace;
		LedgeTrace.TraceWithPlayerProfile(Player);
		LedgeTrace.UseLine();

		LedgeTrace.IgnorePlayers();

		Start = Player.ActorLocation
			+ Player.ActorForwardVector * 100.0
			+ Player.ActorUpVector * 100.0;
		End = Start
			- Player.ActorUpVector * 200.0;

		auto TraceHits = LedgeTrace.QueryTraceMulti(Start, End);
		TemporalLog.HitResults("Down Trace", TraceHits, Start, End, FHazeTraceShape::MakeLine());
		for(auto Hit : TraceHits)
		{
			if(Hit.bBlockingHit)
			{
				auto ClimbComp = UTeenDragonTailClimbableComponent::Get(Hit.Actor);
				if(ClimbComp != nullptr
				&& ClimbComp.ClimbDirectionIsAllowed(Hit.Normal))
					return false;
			}
		}

		return true;
	}
}
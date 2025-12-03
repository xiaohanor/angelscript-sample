struct FTundraPlayerSnowMonkeyAirborneGroundSlamDeactivatedParams
{
	bool bShouldResetAnimTag = false;
}

class UPlayerSnowMonkeyAirborneGroundSlamCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkey);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyAirborneGroundSlam);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 43;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTundraPlayerShapeshiftingComponent ShapeShiftComponent;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UTundraPlayerSnowMonkeySettings GorillaSettings;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerTargetablesComponent TargetablesComp;
	USteppingMovementData Movement;

	UPlayerSnowMonkeyGroundSlamTargetableComponent CurrentTargetable;
	float LandedGameTime = 0;
	bool bHasLanded = false;
	bool bHasStartedFalling = false;
	bool bShapeshiftBlocked = false;
	bool bWithinCenter = false;
	uint LandedFrame = 0;
	float CurrentSpeed;
	FVector Direction;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		ShapeShiftComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		GorillaSettings = UTundraPlayerSnowMonkeySettings ::GetSettings(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ShapeShiftComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return false;

		if(Time::GetGameTimeSeconds() - SnowMonkeyComp.TimeOfLastGroundSlam < GorillaSettings.GroundSlamCooldown)
			return false;

		if (!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.2))
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerSnowMonkeyAirborneGroundSlamDeactivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!bHasLanded)
			return false;

		if(Time::GetGameTimeSince(LandedGameTime) < GorillaSettings.RemainOnGroundTime)
			return false;

		Params.bShouldResetAnimTag = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentTargetable = TargetablesComp.GetPrimaryTarget(UPlayerSnowMonkeyGroundSlamTargetableComponent);
		bWithinCenter = CurrentTargetable != nullptr && CurrentTargetable.WorldLocation.DistXY(Player.ActorLocation) < 40.0;

		SnowMonkeyComp.bCurrentGroundSlamIsGrounded = false;
		UMovementGravitySettings::SetGravityScale(Player, GorillaSettings.GroundSlamGravityMultiplier, this);
		UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnGroundSlamActivated(SnowMonkeyComp.SnowMonkeyActor);
		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyGroundedGroundSlam, this);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerSnowMonkeyAirborneGroundSlamDeactivatedParams Params)
	{
		MoveComp.ClearMovementInput(this);
		UMovementGravitySettings::ClearGravityScale(Player, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyGroundedGroundSlam, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		LandedGameTime = 0;
		bHasLanded = false;
		bHasStartedFalling = false;

		if(bShapeshiftBlocked)
		{
			ShapeShiftComponent.RemoveShapeTypeBlockerInstigator(this);
			bShapeshiftBlocked = false;
		}

		if(Params.bShouldResetAnimTag && Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"Movement", this);
		SnowMonkeyComp.TimeOfLastGroundSlam = Time::GetGameTimeSeconds();
		SnowMonkeyComp.FrameOfStopGroundSlam = Time::FrameNumber;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.HasGroundContact() && !bShapeshiftBlocked)
		{
			ShapeShiftComponent.AddShapeTypeBlocker(ETundraShapeshiftShape::Player, this);
			bShapeshiftBlocked = true;
		}

		bool bShouldLockMovement;

		if(!bHasLanded)
			bShouldLockMovement = GorillaSettings.bLockMovementInAirborneGroundSlamInAir;
		else
			bShouldLockMovement = GorillaSettings.bLockMovementInAirborneGroundSlamAfterLanded;

		if(HasControl() && !bHasLanded && MoveComp.IsOnAnyGround())
		{
			MoveComp.ClearMovementInput(this);
			bHasLanded = true;
			LandedFrame = Time::FrameNumber;
			LandedGameTime = Time::GameTimeSeconds;

			SnowMonkeyComp.GroundSlamZoe();
			TArray<UTundraPlayerSnowMonkeyGroundSlamResponseComponent> ResponseComponents;
			SnowMonkeyComp.NotifyGroundSlamResponseComponent(ETundraPlayerSnowMonkeyGroundSlamType::Airborne, ResponseComponents);

			bool bShouldPlayEffect = true;

			for(auto Response : ResponseComponents)
			{
				if(!Response.bWithGroundSlamEffect)
				{
					bShouldPlayEffect = false;
					break;
				}
			}

			if(bShouldPlayEffect)
				CrumbTriggerGroundSlamLandEvent();
		}

		if(HasControl() && !bHasLanded)
		{
			FVector VelocityToAdd = GetFrameRateIndependentDrag(MoveComp.HorizontalVelocity, 3.0, DeltaTime);
			Player.SetActorHorizontalVelocity(MoveComp.HorizontalVelocity + VelocityToAdd);

			if(CurrentTargetable != nullptr)
			{
				if(bWithinCenter)
				{
					MoveComp.ApplyMovementInput(FVector::ZeroVector, this, EInstigatePriority::High);
				}
				else
				{
					FVector Dir = (CurrentTargetable.WorldLocation - Player.ActorLocation).GetSafeNormal2D();
					float Dist = CurrentTargetable.WorldLocation.DistXY(Player.ActorLocation);
					FVector Vector = Dir * Math::GetMappedRangeValueClamped(FVector2D(50.0, 0.0), FVector2D(1.0, 0.0), Dist);
					MoveComp.ApplyMovementInput(Vector, this, EInstigatePriority::High);
				}
			}
		}

		if(HasControl() && bHasLanded && Time::GetGameTimeSince(LandedGameTime) < 0.2)
		{
			FVector VelocityToAdd = GetFrameRateIndependentDrag(MoveComp.Velocity, 8.0, DeltaTime);
			Player.SetActorHorizontalVelocity(MoveComp.HorizontalVelocity + VelocityToAdd);
		}

		if(bHasLanded)
		{
			if(LandedFrame == Time::FrameNumber)
			{
				CurrentSpeed = MoveComp.HorizontalVelocity.Size();
				Direction = Player.ActorForwardVector;
			}

			if(MoveComp.PrepareMove(Movement))
			{
				if(HasControl())
				{
					CopyOfFloorMotion(DeltaTime);
				}
				else
				{
					if(MoveComp.HasGroundContact())
						Movement.ApplyCrumbSyncedGroundMovement();
					else
						Movement.ApplyCrumbSyncedAirMovement();
				}

				if(MoveComp.HasGroundContact())
					Movement.RequestFallingForThisFrame();

				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SnowMonkeyGroundSlam");
				return;
			}
		}

		if(ActiveDuration > GorillaSettings.GroundSlamAirFloatTime && !bHasStartedFalling)
		{
			bHasStartedFalling = true;
			UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnGroundSlamStartedFalling(SnowMonkeyComp.SnowMonkeyActor);
		}

		if(bShouldLockMovement)
		{
			if(MoveComp.PrepareMove(Movement))
			{
				if(HasControl())
				{
					if(ActiveDuration > GorillaSettings.GroundSlamAirFloatTime)
					{
						Movement.AddGravityAcceleration();
						Movement.AddOwnerVelocity();
					}	
				}
				else
				{
					if(MoveComp.HasGroundContact())
						Movement.ApplyCrumbSyncedGroundMovement();
					else
						Movement.ApplyCrumbSyncedAirMovement();
				}

				if(MoveComp.HasGroundContact())
					Movement.RequestFallingForThisFrame();

				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SnowMonkeyGroundSlam");
			}
		}
		else
		{
			if(Player.Mesh.CanRequestLocomotion())
			{
				Player.Mesh.RequestLocomotion(n"SnowMonkeyGroundSlam", this);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerGroundSlamLandEvent()
	{
		FTundraPlayerSnowMonkeyGroundSlamEffectParams Params;
		Params.bIsInSidescroller = Player.IsPlayerMovementLockedToSpline();
		if (SnowMonkeyComp.IsFarAwayInView())
			UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnGroundSlamLandedFarFromView(SnowMonkeyComp.SnowMonkeyActor, Params);
		else
			UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnGroundSlamLanded(SnowMonkeyComp.SnowMonkeyActor, Params);
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}

	void CopyOfFloorMotion(float DeltaTime)
	{
		FVector TargetDirection = MoveComp.MovementInput;
		float InputSize = MoveComp.MovementInput.Size();
		InputSize = Math::Saturate(Direction.DotProduct(MoveComp.MovementInput));
		//Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

		float SpeedAlpha = Math::Clamp((InputSize - FloorMotionComp.Settings.MinimumInput) / (1.0 - FloorMotionComp.Settings.MinimumInput), 0.0, 1.0);
		float TargetSpeed = FloorMotionComp.GetMovementTargetSpeed(SpeedAlpha);

		// Calculate the target speed
		TargetSpeed *= MoveComp.MovementSpeedMultiplier;

		if(InputSize < KINDA_SMALL_NUMBER)
			TargetSpeed = 0.0;
	
		// Update new velocity
		float InterpSpeed = FloorMotionComp.Settings.Acceleration * MoveComp.MovementSpeedMultiplier;
		if(TargetSpeed < CurrentSpeed)
			InterpSpeed = FloorMotionComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier;
		CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
		FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;

		// While on edges, we force the player of them.
		// if they have moved to far out on the edge,
		// and are not steering out from the edge
		if(MoveComp.HasUnstableGroundContactEdge())
		{
			const FMovementEdge EdgeData = MoveComp.GroundContact.EdgeResult;
			const FVector Normal = EdgeData.EdgeNormal;
			float MoveAgainstNormal = 1 - HorizontalVelocity.GetSafeNormal().DotProduct(Normal);
			MoveAgainstNormal *= Direction.DotProductNormalized(Normal);
			float PushSpeed = Math::Clamp(HorizontalVelocity.Size(), FloorMotionComp.Settings.MinimumSpeed, FloorMotionComp.Settings.MaximumSpeed);
			HorizontalVelocity = Math::Lerp(HorizontalVelocity, Normal * PushSpeed, MoveAgainstNormal);
		}

		Movement.AddOwnerVerticalVelocity();
		Movement.AddPendingImpulses();
		Movement.AddGravityAcceleration();
		Movement.AddHorizontalVelocity(HorizontalVelocity);
		Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0.5));
	}
};
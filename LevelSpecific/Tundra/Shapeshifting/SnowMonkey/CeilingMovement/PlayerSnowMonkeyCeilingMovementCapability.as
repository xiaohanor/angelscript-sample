/** This capability activates when the monkey is walking the ceiling */

struct FTundraPlayerSnowMonkeyCeilingMovementActivation
{
	UTundraPlayerSnowMonkeyCeilingClimbComponent CurrentCeilingComponent;
}

class UTundraPlayerSnowMonkeyCeilingMovementCapability: UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyCeilingClimb);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkey);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 23;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTundraPlayerSnowMonkeyCeilingMovementData Movement;
	UTundraPlayerShapeshiftingComponent ShapeShiftComp;
	UPlayerTargetablesComponent TargetablesComp;
	UTundraPlayerSnowMonkeyComponent GorillaComp;
	UTundraPlayerSnowMonkeySettings GorillaSettings;
	USceneComponent CurrentFollowComponent;
	bool bEnteredCeilingThroughCoyote;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UTundraPlayerSnowMonkeyCeilingMovementData);
		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		GorillaComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		GorillaSettings = UTundraPlayerSnowMonkeySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerSnowMonkeyCeilingMovementActivation& Params) const
	{			
		if(DeactiveDuration < 0.5)
		{
			TemporalLogActivation("Capability Has To Be Deactive For At Least 0.5 Secs");
			return false;
		}

		if(ShapeShiftComp.CurrentShapeType != ETundraShapeshiftShape::Big)
		{
			TemporalLogActivation("Player Is Not In Monkey Shape");
			return false;
		}

		if(MoveComp.HasMovedThisFrame())
		{
			TemporalLogActivation("Moved This Frame");
			return false;
		}

		if(!MoveComp.HasCeilingContact())
		{
			TemporalLogActivation("No Ceiling Contact");
			return false;
		}

		if(!MoveComp.CeilingContact.bIsWalkable)
		{
			TemporalLogActivation("Ceiling Contact Is Not Walkable");
			return false;
		}
		
		auto CeilingComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(MoveComp.CeilingContact.Actor);
		if(CeilingComp == nullptr)
		{
			TemporalLogActivation("Ceiling Contact Does Not Have A Climb Component");
			return false;
		}

		if(CeilingComp.IsDisabled())
		{
			TemporalLogActivation("Ceiling Contact Climb Component is Disabled");
			return false;
		}

		if(!CeilingComp.ComponentIsClimbable(Cast<UPrimitiveComponent>(MoveComp.CeilingContact.Component)))
		{
			TemporalLogActivation("Specific Ceiling Contact Component Is Not Climbable");
			return false;
		}

		FVector ConstrainedPoint;
		if(CeilingComp.GetCeilingData().ConstrainToCeiling(Player.ActorLocation, ConstrainedPoint))
		{
#if !RELEASE
			TEMPORAL_LOG(this).Point("Player Location", Player.ActorLocation, Color = FLinearColor::Red);
			TEMPORAL_LOG(this).Point("Constrained Point", ConstrainedPoint, Color = FLinearColor::Green);
#endif
			TemporalLogActivation("Point Is Not Within Ceiling");
			return false;
		}

		Params.CurrentCeilingComponent = CeilingComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerSnowMonkeyCeilingMovementDeactivatedParams& Params) const
	{	
		if(ShapeShiftComp.CurrentShapeType != ETundraShapeshiftShape::Big)
		{
			TemporalLogDeactivation("Shapeshifted From Monkey");
			return true;
		}

		if(MoveComp.HasMovedThisFrame())
		{
			TemporalLogDeactivation("Moved This Frame");
			return true;
		}

		if(WasActionStarted(ActionNames::Cancel))
		{
			TemporalLogDeactivation("Pressed Cancel");
			return true;
		}

		const float GroundSlamDelay = bEnteredCeilingThroughCoyote ? 0.6 : 0.3;
		if(ActiveDuration > GroundSlamDelay && WasActionStarted(ActionNames::PrimaryLevelAbility))
		{
			TemporalLogDeactivation("Ground Slammed");
			return true;
		}

		if(ActiveDuration > 0.5 && WasActionStarted(ActionNames::MovementJump))
		{
			TemporalLogDeactivation("Jumped");
			Params.bWithJumpOffForce = true;
			return true;
		}

		if(CurrentCeilingComponent.bLetGoWhenOutsideClimbZone && !IsMonkeyWithinCeilingBounds())
			return true;

		if(!MoveComp.HasCeilingContact())
		{
			TemporalLogDeactivation("Lost Ceiling Contact");
			return true;
		}

		if(!MoveComp.CeilingContact.bIsWalkable)
		{
			TemporalLogDeactivation("Ceiling Non Walkable");
			return true;
		}
		
		auto CeilingComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(MoveComp.CeilingContact.Actor);
		// Commented this out since we want the monkey to walk on collision that might be sticking out of the ceiling
		// if(CeilingComp == nullptr)
		// 	return true;

		if(CeilingComp != nullptr)
		{
			if(CeilingComp.IsDisabled())
			{
				TemporalLogDeactivation("Ceiling Was Disabled");
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerSnowMonkeyCeilingMovementActivation Params)
	{
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		MoveComp.ApplyCustomMovementStatus(n"CeilingWalk", this);
		bEnteredCeilingThroughCoyote = GorillaComp.bIsInCeilingCoyoteSuckup;
#if EDITOR
		TEMPORAL_LOG(this).Value("Entered Ceiling Through Coyote", bEnteredCeilingThroughCoyote);
#endif

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		if(GorillaComp.FrameOfEndSuckUp == Time::FrameNumber)
		{
			Player.SetActorVelocity(GorillaComp.SuckUpVelocity.GetClampedToMaxSize(GorillaSettings.CeilingMovementSpeed));
		}

		GorillaComp.TrySetCurrentCeilingComponent(Params.CurrentCeilingComponent);

		GorillaComp.CustomWalkingMode = ETundraPlayerSnowMonkeyTraversalPointType::Ceiling;

		Player.ShowCancelPrompt(this);

		UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnHangClimb_Start(GorillaComp.SnowMonkeyActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerSnowMonkeyCeilingMovementDeactivatedParams Params)
	{
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		MoveComp.ClearCustomMovementStatus(this);

		MoveComp.UnFollowComponentMovement(this);
		CurrentFollowComponent = nullptr;

		GorillaComp.TrySetCurrentCeilingComponent(nullptr);
		GorillaComp.bForceEnteredCurrentCeilingComp = false;

		GorillaComp.bJustCeilingClimbed = true;

		GorillaComp.bCeilingMovementWasConstrained = false;
		
		Player.RemoveCancelPromptByInstigator(this);

		if(HasControl())
		{
			// Apply the force if you jump of it.
			if(Params.bWithJumpOffForce)
			{
				FVector JumpDirection = MoveComp.GetMovementInput();
				if(JumpDirection.IsNearlyZero())
				{
					JumpDirection = Player.ActorForwardVector;

					if(MoveComp.HasCeilingContact())
					{
						JumpDirection = JumpDirection.VectorPlaneProject(MoveComp.CeilingContact.Normal);
						JumpDirection.Normalize();
					}
				}
				else
				{
					JumpDirection.Normalize();
				}

				Player.AddMovementImpulse(JumpDirection * GorillaSettings.CeilingMovementJumpOffForceSpeed);
			}
		}

		UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnHangClimb_Stop(GorillaComp.SnowMonkeyActor);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(MoveComp.CeilingContact.Component != CurrentFollowComponent)
				{
					auto CeilingComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(MoveComp.CeilingContact.Actor);
					
					if(CeilingComp == nullptr || CeilingComp.bFollowCeilingMovement)
						CrumbFollowComponentMovement(MoveComp.CeilingContact.Component);
					CurrentFollowComponent = MoveComp.CeilingContact.Component;
				}

				FVector MovementDirection = MoveComp.MovementInput;
				FVector Target = MovementDirection * GorillaSettings.CeilingMovementSpeed;

				FVector Velocity = Math::VInterpConstantTo(MoveComp.HorizontalVelocity, Target, DeltaTime, GorillaSettings.CeilingVelocityInterpSpeed);
				Movement.AddHorizontalVelocity(Velocity);
	
				FVector Direction = MoveComp.Velocity;
				if(Direction.IsNearlyZero())
					Direction = Player.ActorForwardVector;

				FQuat TargetFacingQuat = Math::QInterpConstantTo(Player.GetActorQuat(), Direction.ToOrientationQuat(), DeltaTime, 8);

				if(!MovementDirection.IsNearlyZero())
					Movement.SetRotation(TargetFacingQuat);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}	

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SnowMonkeyCeiling");	
		}
	}

	void TemporalLogActivation(FString Reason) const
	{
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("Not Activated Reason", Reason)
		;
#endif
	}

	void TemporalLogDeactivation(FString Reason) const
	{
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("Deactivation Reason", Reason)
		;
#endif
	}

	UTundraPlayerSnowMonkeyCeilingClimbComponent GetCurrentCeilingComponent() const property
	{
		return GorillaComp.CurrentCeilingComponent;
	}

	bool IsMonkeyWithinCeilingBounds() const
	{
		FTundraPlayerSnowMonkeyCeilingData CeilingData = CurrentCeilingComponent.GetCeilingData();
		FVector ClosestPoint;
		FVector PlayerPos = Player.ActorLocation;// + FVector::UpVector * TundraShapeshiftingStatics::SnowMonkeyCollisionSize.Y * 2.0;
		float HorizontalDistance = CeilingData.GetHorizontalDistanceToCeiling(PlayerPos, ClosestPoint);
		bool bIsWithinBounds = HorizontalDistance < 30.0;

#if EDITOR
		if(!bIsWithinBounds)
		{
			TEMPORAL_LOG(this)
				.Value("Deactivation Reason", "Outside Climbing Zone")
				.Point("Player Location", PlayerPos)
				.Point("Closest Constrained Point", ClosestPoint, Color = FLinearColor::Green)
				.Value("Horizontal Distance", HorizontalDistance)
			;
		}
#endif

		return bIsWithinBounds;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFollowComponentMovement(USceneComponent Component)
	{
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.FollowComponentMovement(Component, this);
	}
};

struct FTundraPlayerSnowMonkeyCeilingMovementDeactivatedParams
{
	bool bWithJumpOffForce = false;
}
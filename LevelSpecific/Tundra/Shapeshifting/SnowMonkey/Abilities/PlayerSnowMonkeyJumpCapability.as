
class UTundraPlayerSnowMonkeyJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkey);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerMovementTags::GroundJump);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::Perch);

	default BlockExclusionTags.Add(TundraShapeshiftingTags::SnowMonkeyMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 45;
	default TickGroupSubPlacement = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerJumpComponent JumpComp;
	UPlayerSprintComponent SprintComp;
	UTundraPlayerShapeshiftingComponent ShapeShiftComponent;
	USteppingMovementData Movement;
	UTundraPlayerSnowMonkeySettings GorillaSettings;
	UPlayerFloorMotionSettings FloorMotionSettings;
	UPlayerAirMotionSettings AirMotionSettings;

	float HorizontalMoveSpeed;
	float HorizontalVelocityInterpSpeed;

	bool bIsAddingJumpForce = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		ShapeShiftComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		GorillaSettings = UTundraPlayerSnowMonkeySettings ::GetSettings(Player);
		FloorMotionSettings = UPlayerFloorMotionSettings::GetSettings(Player);
		AirMotionSettings = UPlayerAirMotionSettings::GetSettings(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ShapeShiftComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return false;

		if (!WasActionStartedDuringTime(ActionNames::MovementJump, JumpComp.Settings.InputBufferWindow) && !JumpComp.IsJumpBuffered() && !JumpComp.IsDevAutoJumpToggled())
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround() && !JumpComp.IsInJumpGracePeriod())
			return false;
		
		if (MoveComp.IsOnWalkableGround() && JumpComp.IsJumpOnCooldown())
			return false;

		if(MoveComp.HasImpulse())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ShapeShiftComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasGroundContact())
			return true;

		if (MoveComp.HasCeilingContact())
			return true;

		if (MoveComp.HasImpulse())
			return true;

		if (MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < -KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Jump, this);
		JumpComp.ConsumeBufferedJump();

		// We are no longer in jump grace, since we just jumped
		JumpComp.StopJumpGracePeriod();
		JumpComp.StartJump();

		Player.ConsumeAirJumpUsage();
		Player.ConsumeAirDashUsage();
		
		HorizontalMoveSpeed = FloorMotionSettings.MaximumSpeed + (FloorMotionSettings.MaximumSpeed * GorillaSettings.InitialHorizontalJumpVelocityMultiplier);
		
		// Add jump impulse
		FVector VerticalVelocity = MoveComp.WorldUp * GorillaSettings.JumpImpulse;
		FVector HorizontalVelocity = MoveComp.HorizontalVelocity.GetClampedToMaxSize(HorizontalMoveSpeed);
		bIsAddingJumpForce = true;

		//If we find a follow velocity component on the object we are jumping from

		if(MoveComp.GroundContact.IsValidBlockingHit())
		{
			if(MoveComp.GroundContact.Actor != nullptr)
			{
				UPlayerInheritVelocityComponent VelocityComp = Cast<UPlayerInheritVelocityComponent>(MoveComp.GroundContact.Actor.GetComponent(UPlayerInheritVelocityComponent));
				if(VelocityComp != nullptr)
					HorizontalVelocity += MoveComp.GetFollowVelocity();	
			}
		}
		
		GetGroundAlignedAdjustedVelocity(HorizontalVelocity, VerticalVelocity);
		Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.StopJump();
		Player.UnblockCapabilities(BlockedWhileIn::Jump, this);	
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector TargetSpeed = MoveComp.MovementInput * HorizontalMoveSpeed;
				FVector HorizontalVelocity = Math::VInterpConstantTo(MoveComp.HorizontalVelocity, TargetSpeed, DeltaTime, AirMotionSettings.HorizontalVelocityInterpSpeed);
				Movement.AddHorizontalVelocity(HorizontalVelocity);

				FVector VerticalVelocity = MoveComp.GetVerticalVelocity();
				
				Movement.AddGravityAcceleration();
				Movement.AddVerticalVelocity(VerticalVelocity);
				Movement.InterpRotationToTargetFacingRotation(JumpComp.Settings.FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");
		}

		// Buffer an air jump if we press it during jumping
		if (WasActionStarted(ActionNames::MovementJump) && ActiveDuration > 0.0)
			JumpComp.BufferJumpInput();
	}

	void GetGroundAlignedAdjustedVelocity(FVector& HorizontalVelocity, FVector& VerticalVelocity) const
	{
		if(!MoveComp.IsOnWalkableGround())
			return;

		FVector GroundNormal = MoveComp.GetCurrentGroundNormal();
		float SlopeDot = GroundNormal.DotProduct(Owner.ActorForwardVector);
		float SlopeAngle = Math::RadiansToDegrees(SlopeDot);
		float Alpha = Math::Abs(SlopeAngle) / MoveComp.WalkableSlopeAngle;

		// Downhill
		if (SlopeDot > KINDA_SMALL_NUMBER)
		{
			// align the horizontal velocity with the world up, 
			//making us leave the ground and not follow the slope down
			FVector HorizontalAlignedVelocity = HorizontalVelocity.VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal() * HorizontalVelocity.Size();	
			Alpha = Math::EaseOut(0.0, 1.0, Alpha, 2.0);
			HorizontalVelocity = Math::Lerp(HorizontalVelocity, HorizontalAlignedVelocity, Alpha);
		}
		// Uphill
		else if(SlopeDot < -KINDA_SMALL_NUMBER)
		{
			// reduce the velocity so we are going in a vertical direction
			// more than a horizontal direction, making us not
			// fly of edges in a high speed
			float Mul = Math::Lerp(1.0, .85	, Alpha);
			HorizontalVelocity *= Mul;
			VerticalVelocity *= Mul;
		}
	}
}
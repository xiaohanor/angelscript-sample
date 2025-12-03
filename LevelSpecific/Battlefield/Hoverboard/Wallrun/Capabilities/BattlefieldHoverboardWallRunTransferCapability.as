
class UBattlefieldHoverboardWallRunTransferCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunJump);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UBattlefieldHoverboardWallRunComponent WallRunComp;
	UBattlefieldHoverboardJumpComponent JumpComp;

	FPlayerWallRunData PreviousWallData;
	bool bAirJumpBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		WallRunComp = UBattlefieldHoverboardWallRunComponent::GetOrCreate(Owner);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (WallRunComp.State != EPlayerWallRunState::WallRun && WallRunComp.State != EPlayerWallRunState::WallRunLedge)
        	return false;

		if (WallRunComp.Settings.JumpOverride == EPlayerWallRunJumpOverride::ForceJump)
			return false;

		if (WallRunComp.Settings.JumpOverride == EPlayerWallRunJumpOverride::ForceForwardJump)
			return false;

		if (WallRunComp.Settings.JumpOverride == EPlayerWallRunJumpOverride::ForceTransfer)
			return true;

		if (!WallRunComp.ShouldTransfer(Player))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerWallRunData& DeactivationWallRunData) const
	{	
		if (MoveComp.HasMovedThisFrame())
        	return true;

		if (MoveComp.IsOnWalkableGround())
        	return true;

		FPlayerWallRunData WallRunData = WallRunComp.TraceForWallRun(Player, MoveComp.HorizontalVelocity.GetSafeNormal());
		if (WallRunData.HasValidData())
		{
			float AngularDistance = Math::RadiansToDegrees(PreviousWallData.WallNormal.AngularDistance(WallRunData.WallNormal));
			if (Math::IsNearlyEqual(AngularDistance, 180.0, WallRunComp.TransferSettings.WallRunEnterAcceptanceAngle))
			{
				DeactivationWallRunData = WallRunData;
				return true;
			}
		}

		if (ActiveDuration >= WallRunComp.TransferSettings.Duration)
        	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::WallRun, this);
		PreviousWallData = WallRunComp.ActiveData;

		WallRunComp.SetState(EPlayerWallRunState::Transfer);
		WallRunComp.ActiveData.Reset();

		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector NewVelocity = HorizontalVelocity + (MoveComp.WorldUp * WallRunComp.TransferSettings.VerticalImpulse) + (PreviousWallData.WallNormal * WallRunComp.TransferSettings.HorizontalImpulse);
		Player.SetActorVelocity(NewVelocity);

		if (WallRunComp.TransferSettings.BlockAirJumpWindowTime > 0.0)
		{
			Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
			bAirJumpBlocked = true;
		}

		JumpComp.ConsumeJumpInput();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerWallRunData DeactivationWallRunData)
	{
		Player.UnblockCapabilities(BlockedWhileIn::WallRun, this);
		WallRunComp.StateCompleted(EPlayerWallRunState::Transfer);

		if (DeactivationWallRunData.HasValidData())			
		{
			WallRunComp.StartWallRun(DeactivationWallRunData);
		}
		else
		{
			// The transfer jump was cancelled by something (air jump or the like),
			// clamp horizontal velocity so we can't use this to boost.
			// FVector HorizVelocity = Player.ActorHorizontalVelocity;
			// Player.SetActorHorizontalVelocity(HorizVelocity.GetClampedToMaxSize(
			// 	AirMotionComp.Settings.MaximumHorizontalMoveSpeedBeforeDrag
			// ));
		}

		// If we cancelled with the air jump still blocked, unblock
		if (bAirJumpBlocked)
		{
			Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
			bAirJumpBlocked = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
				FVector VerticalVelocity = MoveComp.Velocity.ConstrainToDirection(MoveComp.WorldUp);

				VerticalVelocity -= MoveComp.WorldUp * WallRunComp.TransferSettings.Gravity * DeltaTime;
				HorizontalVelocity -= HorizontalVelocity * WallRunComp.TransferSettings.HorizontalDrag * DeltaTime;

				Movement.AddVerticalVelocity(VerticalVelocity);

				const float InputScale = Math::Clamp((ActiveDuration - WallRunComp.TransferSettings.NoInputTime) / WallRunComp.TransferSettings.InputLerpTime, 0.0, 1.0);
				Movement.AddHorizontalVelocity(MoveComp.GetInputAdjustedHorizontalVelocity(HorizontalVelocity, WallRunComp.Settings.MaximumSpeed, 1800.0 * InputScale, DeltaTime));

				FVector TargetFacingDirection = MoveComp.MovementInput.GetSafeNormal();
				if (TargetFacingDirection.IsNearlyZero())
					TargetFacingDirection = Owner.ActorForwardVector;

				FRotator TargetRotation = FRotator::MakeFromXZ(TargetFacingDirection, MoveComp.WorldUp);
				TargetRotation.Pitch = 0.0;

				const float FacingDirectionScale = Math::Clamp((ActiveDuration - WallRunComp.TransferSettings.NoRotationTime) / WallRunComp.TransferSettings.RotationLerpTime, SMALL_NUMBER, 1.0);
				Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, 360.0 * FacingDirectionScale));
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"HoverboardWallSliding");
		}
		
		// Unblock air jump after our initial window runs out
		if (bAirJumpBlocked && WallRunComp.TransferSettings.BlockAirJumpWindowTime < ActiveDuration)
		{
			Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
			bAirJumpBlocked = false;
		}
	}
}
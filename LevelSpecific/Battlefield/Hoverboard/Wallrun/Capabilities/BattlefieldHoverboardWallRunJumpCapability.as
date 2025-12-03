
class UBattlefieldHoverboardWallRunJumpCapability : UHazePlayerCapability
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
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 31);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardWallRunComponent WallRunComp;
	UBattlefieldHoverboardJumpComponent JumpComp;

	bool bAdjustForwardInput = true;
	float HorizontalEntrySpeed = 0.0;

	FPlayerWallRunData PreviousWallData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		WallRunComp = UBattlefieldHoverboardWallRunComponent::GetOrCreate(Owner);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
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

		if (WallRunComp.Settings.JumpOverride == EPlayerWallRunJumpOverride::ForceTransfer)
			return false;
	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
        	return true;

		if (MoveComp.IsOnWalkableGround())
        	return true;

		if (ActiveDuration >= WallRunComp.JumpSettings.Duration)
        	return true;

		/*
		 * TODO:
		 * If you are doing a forward jump you should trace using the previous wall run data so that you can reattach in the same direction
		 */

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::WallRun, this);

		PreviousWallData = WallRunComp.ActiveData;

		WallRunComp.SetState(EPlayerWallRunState::Jump);
		WallRunComp.ActiveData.Reset();

		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);

		/*
		 * TODO:
		 * Right now the forward jump is only activated if you FORCE it.
		 * You should check camera direction to the normal of the wall run to see if you should do a forward jump (assume 2D)
		 * Otherwise you can use the wall run volume to force the 2D jump rather than it being assumed
		 */

		float HorizontalImpulse = WallRunComp.Settings.JumpOverride == EPlayerWallRunJumpOverride::ForceForwardJump ? 0.0 : WallRunComp.JumpSettings.HorizontalImpulse;
		FVector NewVelocity = HorizontalVelocity + (MoveComp.WorldUp * WallRunComp.JumpSettings.VerticalImpulse) + (PreviousWallData.WallNormal * HorizontalImpulse);
		Player.SetActorVelocity(NewVelocity);

		HorizontalEntrySpeed = HorizontalVelocity.Size();
		bAdjustForwardInput = true;
		JumpComp.ConsumeJumpInput();	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{ 
		Player.UnblockCapabilities(BlockedWhileIn::WallRun, this);

		WallRunComp.StateCompleted(EPlayerWallRunState::Jump);

		HoverboardComp.ResetWantedRotationToCurrentRotation();
		HoverboardComp.SetCameraWantedRotationToWantedRotation();
		HoverboardComp.AccRotation.SnapTo(HoverboardComp.WantedRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				// FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
				// FVector VerticalVelocity = MoveComp.Velocity.ConstrainToDirection(MoveComp.WorldUp);

				// // Gravity
				// const float GravityLerp = Math::Min(ActiveDuration / WallRunComp.JumpSettings.GravityLerpTime, 1.0);
				// const float GravityStrength = Math::Lerp(WallRunComp.JumpSettings.GravityStart, WallRunComp.JumpSettings.GravityEnd, GravityLerp);
				// VerticalVelocity -= MoveComp.WorldUp * (GravityStrength * MoveComp.GravityMultiplier) * DeltaTime;

				// Movement.AddVerticalVelocity(VerticalVelocity);

				// const float InputScale = Math::Clamp((ActiveDuration - WallRunComp.JumpSettings.NoInputTime) / WallRunComp.JumpSettings.InputLerpTime, SMALL_NUMBER, 1.0);
				// FVector MoveInput = Player.ActorRotation.RotateVector(MoveComp.MovementInput);			
				// if (bAdjustForwardInput && !Math::IsNearlyZero(InputScale) && !MoveInput.IsNearlyZero())
				// {
				// 	// Remove input towards the wall within a threshold. Only need to do this if you actually have input
				// 	FVector AlongWall = PreviousWallData.WallRight * Math::Sign(PreviousWallData.WallRight.DotProduct(MoveComp.Velocity));
				// 	const float AngleDifference = Math::RadiansToDegrees(AlongWall.AngularDistanceForNormals(MoveInput.GetSafeNormal()) * Math::Sign(PreviousWallData.GetWallNormal().DotProduct(MoveInput)));

				// 		if (IsDebugActive())
				// 		{
				// 			PrintToScreenScaled("Angle From Forward: " + AngleDifference);
				// 			Debug::DrawDebugLine(Owner.ActorCenterLocation, Owner.ActorCenterLocation + AlongWall * 200.0, FLinearColor::Green);
				// 		}

				// 	if (AngleDifference > WallRunComp.JumpSettings.InputCorrectionAngleMinimum && AngleDifference < WallRunComp.JumpSettings.InputCorrectionAngleMaximum)
				// 		MoveInput = HorizontalVelocity.GetSafeNormal();				
				// }

				// // HorizontalVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
				// // 	MoveInput,
				// // 	HorizontalVelocity,
				// // 	DeltaTime,
				// // 	AirControlMultiplier = InputScale,
				// // );
				// Movement.AddHorizontalVelocity(HorizontalVelocity);

				// if (!Math::IsNearlyZero(MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).AngularDistance(HorizontalVelocity), 0.1))
				// 	bAdjustForwardInput = false;

				// FVector TargetFacingDirection = MoveInput.GetSafeNormal();
				// if (TargetFacingDirection.IsNearlyZero())
				// 	TargetFacingDirection = Owner.ActorForwardVector;

				// FRotator TargetRotation = FRotator::MakeFromXZ(TargetFacingDirection, MoveComp.WorldUp);
				// TargetRotation.Pitch = 0.0;
			
				// const float FacingDirectionScale = Math::Clamp((ActiveDuration - WallRunComp.JumpSettings.NoFacingRotationTime) / WallRunComp.JumpSettings.NoFacingRotationTime, SMALL_NUMBER, 1.0);
				// Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, WallRunComp.JumpSettings.FacingRotationInterpSpeed * FacingDirectionScale));

				// #if !RELEASE	
				// 	TEMPORAL_LOG(this)
				// 	.Value("Gravity Strength Lerp", GravityLerp)
				// 	.Value("Gravity Strength", GravityStrength)
				// 	.Value("Input Scale", InputScale);
				// #endif

				// if (IsDebugActive())
				// {
				// 	PrintToScreenScaled("Gravity: " + GravityLerp + " | " + GravityStrength);
				// 	Debug::DrawDebugLine(Owner.ActorCenterLocation, Owner.ActorCenterLocation + Owner.ActorForwardVector * 200.0);
				// 	Debug::DrawDebugLine(Owner.ActorCenterLocation, Owner.ActorCenterLocation + MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * 200.0, FLinearColor::Red);
				// 	Debug::DrawDebugLine(Owner.ActorCenterLocation, Owner.ActorCenterLocation + MoveComp.MovementInput.GetSafeNormal() * 200.0, FLinearColor::Blue);
				// 	Debug::DrawDebugLine(Owner.ActorCenterLocation, Owner.ActorCenterLocation + MoveInput.GetSafeNormal() * 200.0, FLinearColor::LucBlue);
				// }
				Movement.AddOwnerVelocity();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"HoverboardAirMovement");
		}
	}
}
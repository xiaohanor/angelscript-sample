
class UPerchJumpOffCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerPerchPointTags::PerchPointJumpOff);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludePerch);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 44;
	default TickGroupSubPlacement = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPerchComponent PerchComp;
	UPlayerJumpComponent JumpComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPerchOnPointActivationParams& ActivationParams) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!PerchComp.IsCurrentlyPerching())
			return false;

		if (PerchComp.Data.bInPerchSpline)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, 0.3))
			return false;

		ActivationParams.ActivatedOnData = PerchComp.Data;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		if(MoveComp.HasCeilingContact())
			return true;

		if(MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < -KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPerchOnPointActivationParams ActivationParams)
	{
		Player.BlockCapabilitiesExcluding(BlockedWhileIn::Perch, n"ExcludeAirJumpAndDash", this);
		
		//Make sure our data is replicated
		FPerchData PerchData = ActivationParams.ActivatedOnData;

		//Make sure we dont get stopped by the actor we are leaving (for example an angled pole actor)
		MoveComp.AddMovementIgnoresActor(this, PerchData.ActivePerchPoint.Owner);

		PerchData.bJumpingOff = true;
		PerchComp.LastJumpOffTime = Time::GameTimeSeconds;

		FVector MoveInput = MoveComp.MovementInput;

		float FollowVerticalVelocity = PerchData.ActivePerchPoint.bInheritUpwardsVelocity ? (Math::Max(0, MoveComp.WorldUp.DotProduct(MoveComp.GetFollowVelocity()))) : 0;
		FVector VerticalVelocity = MoveComp.WorldUp * (JumpComp.Settings.PerchImpulse + FollowVerticalVelocity);

		Player.SetActorVerticalVelocity(VerticalVelocity);
		Player.SetActorHorizontalVelocity(MoveInput * JumpComp.Settings.PerchImpulse * JumpComp.Settings.HorizontalPerchImpulseMultiplier);

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			Player.ApplyCameraSettings(PerchComp.PerchPointJumpOffCamSetting, 2.5, this, SubPriority = 41);
			Player.PlayCameraShake(PerchComp.PerchJumpOffCamShake, this, 1.0);

			FHazeCameraImpulse CamImpulse;
			CamImpulse.AngularImpulse = FRotator(20.0, 0.0, 0.0);
			CamImpulse.CameraSpaceImpulse = FVector(0.0, 0.0, 425.0);
			CamImpulse.ExpirationForce = 15.5;
			CamImpulse.Dampening = 0.8;
			Player.ApplyCameraImpulse(CamImpulse, this);
		}

		//Assign our modified data back to component
		PerchComp.Data = PerchData;

		if(PerchData.State != EPlayerPerchState::PerchingOnPoint && PerchData.State != EPlayerPerchState::PerchingOnSpline)
			PerchData.ActivePerchPoint.OnPlayerStartedPerchingEvent.Broadcast(Player, PerchData.ActivePerchPoint);

		PerchData.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchData.ActivePerchPoint);

		PerchComp.StopPerching(false);
		JumpComp.StopJumpGracePeriod();

		UPlayerCoreMovementEffectHandler::Trigger_Perch_JumpOff(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Perch, this);
		MoveComp.RemoveMovementIgnoresActor(this);

		PerchComp.Data.bJumpingOff = false;
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
					MoveComp.MovementInput,
					MoveComp.HorizontalVelocity,
					DeltaTime,
				);
				Movement.AddHorizontalVelocity(AirControlVelocity);
				Movement.AddPendingImpulses();

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				Movement.RequestFallingForThisFrame();

				Movement.InterpRotationToTargetFacingRotation(7.0 * MoveComp.MovementInput.Size());
				Movement.IgnoreSplineLockConstraint();
			}
			else
				Movement.ApplyCrumbSyncedAirMovement();

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Perch");
		}
	}
}
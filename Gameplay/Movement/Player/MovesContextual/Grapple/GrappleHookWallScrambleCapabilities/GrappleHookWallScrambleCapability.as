struct FPlayerGrappleWallScrambleActivationParams
{
	FPlayerGrappleData Data;
}

class UPlayerGrappleHookWallScrambleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerMovementTags::Slide);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleSlide);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerGrappleComponent GrappleComp;
	UPlayerWallScrambleComponent WallScrambleComp;
	UGrappleWallScramblePointComponent WallScramblePointComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		WallScrambleComp = UPlayerWallScrambleComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerGrappleWallScrambleActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		if (!GrappleComp.Data.bEnterFinished || GrappleComp.Data.CurrentGrapplePoint.GrappleType != EGrapplePointVariations::WallScramblePoint)
			return false;
		
		Params.Data = GrappleComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if ((Player.ActorLocation.ConstrainToPlane(MoveComp.WorldUp) - WallScramblePointComp.WorldLocation.ConstrainToPlane(MoveComp.WorldUp)).Size() < 50.0)
			return true;

		if (GrappleComp.Data.CurrentGrapplePoint.IsDisabledForPlayer(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerGrappleWallScrambleActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		Player.ResetWallScrambleUsage();

		GrappleComp.Data = Params.Data;

		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleWallScramble;

		WallScramblePointComp = Cast<UGrappleWallScramblePointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		GrappleComp.CalculateHeightOffset();
		
		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
			Player.ApplyCameraSettings(GrappleComp.GrappleCamSetting, 1.35, this, SubPriority = 53);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);

		//Make sure we are in the same state as when started (nothing interrupted) and cleanup / reset)
		if (GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleWallScramble)
		{
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);

			//Broadcast finished grappling event
			if (IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			//Reset Component Data
			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();

			WallScrambleComp.bForceScramble = true;

			if (WallScramblePointComp.Settings != nullptr)
			{
				Player.ApplySettings(WallScramblePointComp.Settings, this);
				Timer::SetTimer(this, n"ResetWallScrambleSettings", 2.0);
			}
		}
		else
		{
			// Our state was interrupted
			if (IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			GrappleComp.AnimData.bWallScrambleGrappling = false;
		}

		Player.ClearCameraSettingsByInstigator(this, 2.5);

		WallScramblePointComp.ClearPointForPlayer(Player);
		WallScramblePointComp = nullptr;
	}

	// SUPER HACKY
	UFUNCTION()
	void ResetWallScrambleSettings()
	{
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{		
				float Speed = Math::Lerp(0, GrappleComp.Settings.GrappleToPointTopVelocity	, GrappleComp.AccelerationCurve.GetFloatValue(ActiveDuration / GrappleComp.Settings.GrappleToPointAccelerationDuration));

				FVector Direction = GrappleComp.Data.GrappleToPointWorldTargetLocation - Player.ActorLocation;
				Direction = Direction.GetSafeNormal();

				FVector FrameDeltaMove = Direction * Speed * DeltaTime;

				if(FrameDeltaMove.Size() > (GrappleComp.Data.GrappleToPointWorldTargetLocation - Player.ActorLocation).Size() || (GrappleComp.Data.GrappleToPointWorldTargetLocation - Player.ActorLocation).Size() <= 10)
				{
					FrameDeltaMove = (GrappleComp.Data.GrappleToPointWorldTargetLocation - Player.ActorLocation);
					GrappleComp.Data.bGrappleToPointFinished = true;
				}

				Movement.OverrideStepUpAmountForThisFrame(50);
				Movement.SetRotation(Player.ActorRotation);
				Movement.AddDeltaWithCustomVelocity(FrameDeltaMove, FrameDeltaMove.GetSafeNormal() * Speed);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"Grapple", this);
		}

		float Alpha = ActiveDuration / GrappleComp.Settings.GrappleDuration;
		float BlendFraction = Math::Lerp(1.0, 0.0, Alpha);
		BlendFraction = Math::Clamp(BlendFraction, 0, 1);

		Player.ApplyManualFractionToCameraSettings(BlendFraction, this);
		
		GrappleComp.RetractGrapple(ActiveDuration);
	}
};


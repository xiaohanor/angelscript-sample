/*
 * This capability activates whenever the player is considered climbing (Enter/Climb/Dash) on the pole and currently:
 * Handles overall capability blocking
 * Follows pole movement
 * Resets Contextual moves
 */

class UPlayerPoleClimbCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::PoleClimb);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UCameraUserComponent CameraUserComp;

	float NoCameraInputTime = 0.0;

	APoleClimbActor CurrentPole;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		
		//Setup Remaining references in Component once we know all capabilities/Components have been added
		PoleClimbComp.Initialize();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PoleClimbComp.IsClimbing())
			return true;
			
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerPoleClimbDeactivationParams& Params) const
	{
		if (!PoleClimbComp.IsClimbing())
			return true;

		if ((PoleClimbComp.Data.ActivePole != nullptr && PoleClimbComp.Data.ActivePole.bDetachOnFollowImpact) && VerifyHorizontalImpactInterrupt())
		{
			if (!Player.IsCapabilityTagBlocked(n"PoleClimbExit"))
			{
				Params.DeactivationType = EPlayerPoleClimbDeactivationType::StopOnImpact;
				return true;
			}
		}

		if ((PoleClimbComp.Data.State != EPlayerPoleClimbState::Enter && PoleClimbComp.Data.State != EPlayerPoleClimbState::EnterFromPerch) && !PoleClimbComp.IsWithinValidClimbHeight())
		{
			if (!Player.IsCapabilityTagBlocked(n"PoleClimbExit"))
			{
				Params.DeactivationType = EPlayerPoleClimbDeactivationType::OutsideValidHeight;
				return true;
			}
		}

		return false;
	}

	bool VerifyHorizontalImpactInterrupt() const
	{
		if(MoveComp.HasImpactedWall())
		{
			TArray<FHitResult> WallImpacts = MoveComp.GetAllWallImpacts();

			for (auto WallImpact : WallImpacts)
			{
				if (WallImpact.Component != nullptr && CurrentPole != nullptr && WallImpact.Component.IsAttachedTo(CurrentPole))
					continue;
				if (MoveComp.GetFollowVelocity().ConstrainToPlane(MoveComp.WorldUp).DotProduct((WallImpact.ImpactPoint - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp)) > KINDA_SMALL_NUMBER)
					return true;
			}
		}

		if(MoveComp.HasImpactedCeiling())
		{
			TArray<FHitResult> CeilingImpacts = MoveComp.GetAllCeilingImpacts();

			for (auto CeilingImpact : CeilingImpacts)
			{
				if (CeilingImpact.Component != nullptr && CurrentPole != nullptr && CeilingImpact.Component.IsAttachedTo(CurrentPole))
					continue;
				if (MoveComp.GetFollowVelocity().ConstrainToPlane(MoveComp.WorldUp).DotProduct((CeilingImpact.ImpactPoint - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp)) > KINDA_SMALL_NUMBER)
					return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::PoleClimb, this);

		CurrentPole = PoleClimbComp.Data.ActivePole;

		MoveComp.FollowComponentMovement(CurrentPole.RootComp, this, Priority = EInstigatePriority::Interaction);
		CurrentPole.PerchPointComp.DisableForPlayer(Player, this);

		Player.ResetWallScrambleUsage();
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		UPlayerCoreMovementEffectHandler::Trigger_Pole_StartPoleClimb(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerPoleClimbDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::PoleClimb, this);

		if(CurrentPole != nullptr)
			CurrentPole.PerchPointComp.EnableForPlayer(Player, this);

		if(Params.DeactivationType == EPlayerPoleClimbDeactivationType::StopOnImpact
			|| Params.DeactivationType == EPlayerPoleClimbDeactivationType::OutsideValidHeight)
		{
			PoleClimbComp.StopClimbing();
		}

		MoveComp.UnFollowComponentMovement(this);
		CurrentPole = nullptr;

		UPlayerCoreMovementEffectHandler::Trigger_Pole_StopPoleClimb(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D CameraInput = Player.GetCameraInput();
		if (CameraInput.IsNearlyZero())
			NoCameraInputTime += DeltaTime;
		else
			NoCameraInputTime = 0.0;

		if (NoCameraInputTime > 1.0)
		{
			if (PerspectiveModeComp.IsCameraBehaviorEnabled())
				NudgeCameraAwayFromTransferPole(DeltaTime);
		}

		//Check if pole data has changed (pole was modified)
		PoleClimbComp.UpdatePoleData();
	}

	void NudgeCameraAwayFromTransferPole(float DeltaTime)
	{
		FVector CameraDirection = Player.ViewRotation.ForwardVector;
		CameraDirection = CameraDirection.ConstrainToPlane(MoveComp.WorldUp);

		float CurrentHeight = PoleClimbComp.Data.CurrentHeight;
		FVector DirToPlayer = Player.ActorLocation - (CurrentPole.ActorLocation + (CurrentPole.ActorUpVector * CurrentHeight));
		DirToPlayer = DirToPlayer.ConstrainToPlane(MoveComp.WorldUp);
		DirToPlayer = DirToPlayer.GetSafeNormal();

		FVector WantedJumpDirection = DirToPlayer;
		auto TargetPole = PoleClimbComp.GetPoleClimbTransferAssistTarget(WantedJumpDirection, MoveComp.MovementInput);

		// auto TargetPole = PoleClimbComp.GetPoleClimbTransferAssistTarget(CameraDirection, CameraDirection);
		if (TargetPole == nullptr)
			return;

		if (!TargetPole.bNudgeCameraAwayFromPoleTransfer)
			return;

		FVector DirectionToCurrentPole = CurrentPole.ActorLocation - Player.ViewLocation;
		DirectionToCurrentPole = DirectionToCurrentPole.ConstrainToPlane(MoveComp.WorldUp);

		FVector DirectionToTargetPole = TargetPole.ActorLocation - Player.ViewLocation;
		DirectionToTargetPole = DirectionToTargetPole.ConstrainToPlane(MoveComp.WorldUp);

		float Angle = DirectionToTargetPole.GetAngleDegreesTo(DirectionToCurrentPole);
		if (Angle < Math::Abs(TargetPole.NudgeCameraAngle))
		{
			float NudgeAmount = -10.0;

			UCameraSettings CameraSettings = UCameraSettings::GetSettings(Player);
			if (CameraSettings.CameraOffset.Value.Y < 0.0)
				NudgeAmount *= -1.0;

			CameraUserComp.AddDesiredRotation(
				FRotator(0.0, NudgeAmount * DeltaTime * Math::Sign(TargetPole.NudgeCameraAngle), 0.0),
				this
			);
		}
	}
};
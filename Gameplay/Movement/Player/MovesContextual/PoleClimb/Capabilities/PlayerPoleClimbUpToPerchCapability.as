class UPlayerPoleClimbUpToPerchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::PoleClimb);
	default CapabilityTags.Add(PlayerPoleClimbTags::PoleClimbExitToPerch);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 22;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerPerchComponent PerchComp;

	bool bTranslationFinished;

	FVector PoleRelativeTargetLocation;
	FVector PoleRelativeStartLocation;
	FRotator StartRot;
	FRotator TargetRot;
	UPerchPointComponent PerchPointComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		PoleClimbComp = UPlayerPoleClimbComponent::GetOrCreate(Player);
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (PoleClimbComp.Data.ActivePole == nullptr)
			return false;

		if (!PoleClimbComp.Data.ActivePole.bAllowPerchOnTop)
			return false;

		if(!Player.IsSelectedBy(PoleClimbComp.Data.ActivePole.PerchPointComp.UsableByPlayers))
			return false;

		if (PoleClimbComp.GetState() != EPlayerPoleClimbState::Climbing)
			return false;

		if (PoleClimbComp.Data.bPerformingTurnaround)
			return false;

		if(MoveComp.WorldUp.DotProduct(PoleClimbComp.Data.ActivePole.PerchPointComp.UpVector) <= 0)
			return false;

		FVector CameraUp = Player.ViewRotation.UpVector;
		FVector CameraRight = Player.ViewRotation.RightVector;
		FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		FVector ViewAlignedInput = CameraUp * RawInput.Y + CameraRight * RawInput.X;

		if(ViewAlignedInput.DotProduct(PoleClimbComp.Data.ActivePole.PerchPointComp.UpVector) <= PoleClimbComp.Settings.VerticalDeadZone)
			return false;

		if (PoleClimbComp.Data.CurrentHeight <= PoleClimbComp.Data.MaxHeight - 10.0)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPoleClimbToPerchDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (PoleClimbComp.Data.ActivePole.IsActorDisabled() || PoleClimbComp.Data.ActivePole.IsPoleDisabled())
			return true;

		if (bTranslationFinished)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::PoleClimb, this);


		PoleClimbComp.SetState(EPlayerPoleClimbState::ExitToPerch);
		PoleClimbComp.AnimData.bClimbingToPerchPoint = true;

		PerchPointComp = PoleClimbComp.Data.ActivePole.PerchPointComp;

		MoveComp.FollowComponentMovement(PerchPointComp, this, Priority = EInstigatePriority::Interaction);

		bTranslationFinished = false;

		PoleRelativeStartLocation = PoleClimbComp.Data.ActivePole.ActorTransform.InverseTransformPosition(Player.ActorLocation);
		PoleRelativeTargetLocation = PoleClimbComp.Data.ActivePole.ActorTransform.InverseTransformPosition(PerchPointComp.WorldLocation);

		PerchComp.Data.TargetedPerchPoint = PerchPointComp;

		// The delay before the camera blended from pole camera to default was really awkward. Maybe not the right way/place to do it though //Zodiac
		Player.ClearCameraSettingsByInstigator(PoleClimbComp, 1.5);

		UPlayerCoreMovementEffectHandler::Trigger_Pole_ClimbUpToPerchStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPoleClimbToPerchDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::PoleClimb, this);

		MoveComp.UnFollowComponentMovement(this);

		if(PoleClimbComp.Data.ActivePole != nullptr)
			PoleClimbComp.Data.ActivePole.OnExitToPerch.Broadcast(Player, PoleClimbComp.Data.ActivePole);

		PoleClimbComp.StopClimbing();
		PoleClimbComp.ResetCooldown();

		if(!Params.bMoveCompleted)
		{
			PerchComp.Data.ResetData();
			return;
		}

		//Start Perching on Point
		PerchComp.StartPerching(PerchComp.Data.TargetedPerchPoint, true);

		Player.PlayForceFeedback(PoleClimbComp.PerchFF, false, true, this);

		UPlayerCoreMovementEffectHandler::Trigger_Pole_ClimbUpToPerchFinished(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TransformedTargetLocation = PoleClimbComp.Data.ActivePole.ActorTransform.TransformPosition(PoleRelativeTargetLocation);
		FVector TransformedStartPosition = PoleClimbComp.Data.ActivePole.ActorTransform.TransformPosition(PoleRelativeStartLocation);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{	
				float Alpha = ActiveDuration / PoleClimbComp.Settings.ClimbUpToPerchDuration;
				FVector NewLoc = Math::Lerp(TransformedStartPosition, TransformedTargetLocation, Alpha);
				FVector DeltaMove = NewLoc - Player.ActorLocation;
				FRotator NewRot = Player.ActorRotation;

				if(Alpha >= 1)
					bTranslationFinished = true;
				
				Movement.AddDeltaWithCustomVelocity(DeltaMove, FVector::ZeroVector);
				Movement.SetRotation(NewRot);
				Movement.IgnoreSplineLockConstraint();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"PoleClimb", this);
		}
	}
};

struct FPoleClimbToPerchDeactivationParams
{
	bool bMoveCompleted = false;
}


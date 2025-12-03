class UTundraPlayerFairyJumpCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 3;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::GroundJump);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::Fairy);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	UTundraPlayerFairySettings Settings;
	USteppingMovementData Movement;
	UTundraPlayerFairyComponent FairyComp;
	UTundraMushroomPlayerBounceComponent MushroomComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		MushroomComp = UTundraMushroomPlayerBounceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!FairyComp.bIsActive)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, Settings.JumpInputQueuingDuration))
			return false;

		if(!MoveComp.HasGroundContact())
			return false;

		if(MushroomComp != nullptr && MushroomComp.HasBouncedRecently())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.PlayForceFeedback(FairyComp.JumpForceFeedback, false, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
				Movement.AddVelocity(MoveComp.WorldUp * Settings.JumpVerticalImpulse);

				Movement.AddPendingImpulses();
				Movement.AddOwnerVelocity();
				Movement.AddGravityAcceleration();
				ApplyFriction(DeltaTime);
				RotateMesh();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");
			UTundraPlayerFairyEffectHandler::Trigger_OnJumped(FairyComp.FairyActor);
		}
	}

	void ApplyFriction(float DeltaTime)
	{
		FVector DragVeloctyDelta = FairyComp.GetFrameRateIndependentDrag(MoveComp.HorizontalVelocity, Settings.HorizontalGroundFriction, DeltaTime);
		Movement.AddHorizontalVelocity(DragVeloctyDelta);
	}

	void RotateMesh()
	{
		if(!MoveComp.HorizontalVelocity.IsNearlyZero())
			Movement.InterpRotationTo(MoveComp.HorizontalVelocity.ToOrientationQuat(), Settings.FairyRotationInterpSpeed);
	}
}
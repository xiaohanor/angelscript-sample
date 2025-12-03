class UTeenDragonTailGeckoClimbExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 39;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;

	UTeenDragonTailClimbableComponent CurrentClimbComp;

	UTeenDragonTailGeckoClimbSettings ClimbSettings;

	FVector StartWorldUp;
	FVector CurrentWorldUp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();

		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!TailDragonComp.IsClimbing())
			return false;

		if(GeckoClimbComp.ExitVolumesInside.Num() == 0)
			return false;
		
		if(WasActionStarted(ActionNames::Cancel))
			return true;

		if(TailDragonComp.bWantToJump)
		{
			TailDragonComp.ConsumeJumpInput();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration >= ClimbSettings.ExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GeckoClimbComp.SetCameraTransitionAlphaTarget(0, ClimbSettings.CameraTransitionExitWallSpeed);
		GeckoClimbComp.StopClimbing();
		StartWorldUp = GeckoClimbComp.GetClimbUpVector();
		CurrentWorldUp = StartWorldUp;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / ClimbSettings.ExitDuration;
		CurrentWorldUp = FQuat::Slerp(StartWorldUp.ToOrientationQuat(), FVector::UpVector.ToOrientationQuat(), Alpha).ForwardVector;

		// Debug::DrawDebugDirectionArrow(TeenDragon.ActorLocation, CurrentWorldUp, 500, 50, FLinearColor::Red, 20);

		if (MoveComp.PrepareMove(Movement, CurrentWorldUp))
		{
			if (HasControl())
			{
				Movement.AddVelocity(GeckoClimbComp.GetClimbUpVector() * ClimbSettings.ExitSpeed);
				Movement.AddGravityAcceleration();

				Movement.SetRotation(Player.ActorRotation);
				// Movement.InterpRotationToTargetFacingRotation(TeenDragonJumpSettings::FacingDirectionInterpSpeed);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			TailDragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::AirMovement);
		}
	}
};
class UIslandOverloadJumpPadIdleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AIslandOverloadJumpPad JumpPad;

	FVector PlatformStartLocation;
	FVector PlatformRetractedLocation;

	const float RetractInterpSpeed = 20.0;
	FVector LastFrameMeshLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpPad = Cast<AIslandOverloadJumpPad>(Owner);

		devCheck(JumpPad.Panel != nullptr, f"{this} does not have a reference to an overload panel");

		if(JumpPad.bRequireSecondPanel)
			devCheck(JumpPad.SecondPanel != nullptr, f"{this} does not have a reference to a second overload panel, but RequireSecondPanel is ticked");
		
		PlatformStartLocation = JumpPad.PadMesh.RelativeLocation;
		PlatformRetractedLocation = JumpPad.PadMesh.RelativeLocation - FVector::UpVector * JumpPad.PadRetractAmount;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(JumpPad.Panel == nullptr)
			return false;

		if(JumpPad.bIsLaunching)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(JumpPad.Panel == nullptr)
			return true;

		if(JumpPad.bIsLaunching)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		LastFrameMeshLocation = JumpPad.PadMesh.WorldLocation; 
		JumpPad.CurrentState = EIslandOverloadJumpPadMovementState::Idle;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float PanelAlpha = JumpPad.GetPanelAlpha();

		FVector TargetLocation = Math::Lerp(PlatformStartLocation, PlatformRetractedLocation, PanelAlpha);

		JumpPad.PadMesh.RelativeLocation = Math::VInterpTo(JumpPad.PadMesh.RelativeLocation, TargetLocation, DeltaTime, RetractInterpSpeed);

		HandleAudioStates();
	}

	private void HandleAudioStates()
	{
		FVector RetractionDir = (PlatformRetractedLocation - PlatformStartLocation).GetSafeNormal();
		FVector MeshDelta = JumpPad.PadMesh.RelativeLocation - LastFrameMeshLocation;
		float RetractionDirDotMeshDelta = RetractionDir.DotProduct(MeshDelta);

		bool bMeshInSameLocation = MeshDelta.IsNearlyZero();
		bool bMeshIsFurtherDown = RetractionDirDotMeshDelta > 0;
		bool bMeshIsFurtherUp = RetractionDirDotMeshDelta < 0;

		auto TemporalLog = TEMPORAL_LOG(JumpPad);

		if(JumpPad.CurrentState == EIslandOverloadJumpPadMovementState::Idle)
		{
			if(bMeshIsFurtherDown)
			{
				UIslandOverloadJumpPadEventHandler::Trigger_Retract(JumpPad);
				TemporalLog.Event("Retract Start");
				JumpPad.CurrentState = EIslandOverloadJumpPadMovementState::GoingDown;
			}
			if(bMeshIsFurtherUp)
			{
				UIslandOverloadJumpPadEventHandler::Trigger_ResetStart(JumpPad);
				TemporalLog.Event("Reset Start");
				JumpPad.CurrentState = EIslandOverloadJumpPadMovementState::Resetting;
			}
		}
		else if (JumpPad.CurrentState == EIslandOverloadJumpPadMovementState::GoingDown)
		{
			if(bMeshInSameLocation)
			{
				UIslandOverloadJumpPadEventHandler::Trigger_RetractStop(JumpPad);
				TemporalLog.Event("Retract Stop");
				JumpPad.CurrentState = EIslandOverloadJumpPadMovementState::Idle;
			}
			else if(bMeshIsFurtherUp)
			{
				UIslandOverloadJumpPadEventHandler::Trigger_RetractStop(JumpPad);
				TemporalLog.Event("Retract Stop");

				UIslandOverloadJumpPadEventHandler::Trigger_ResetStart(JumpPad);
				TemporalLog.Event("Reset Start");
				JumpPad.CurrentState = EIslandOverloadJumpPadMovementState::Resetting;
			}
		}
		else if(JumpPad.CurrentState == EIslandOverloadJumpPadMovementState::Resetting)
		{
			if(bMeshInSameLocation)
			{
				UIslandOverloadJumpPadEventHandler::Trigger_ResetStop(JumpPad);
				TemporalLog.Event("Reset Stop");
				JumpPad.CurrentState = EIslandOverloadJumpPadMovementState::Idle;
			}
			else if(bMeshIsFurtherDown)
			{
				UIslandOverloadJumpPadEventHandler::Trigger_ResetStop(JumpPad);
				TemporalLog.Event("Reset Stop");

				UIslandOverloadJumpPadEventHandler::Trigger_Retract(JumpPad);
				TemporalLog.Event("Retract Start");
				JumpPad.CurrentState = EIslandOverloadJumpPadMovementState::GoingDown;
			}
		}

		LastFrameMeshLocation = JumpPad.PadMesh.RelativeLocation;
	}
};
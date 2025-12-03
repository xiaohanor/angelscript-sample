enum EDesertGrappleFishPlayerState
{
	None,
	Grappling,
	Riding,
	Launched,
	FinalJump
}

event void FGrappleFishPlayerStateChange(EDesertGrappleFishPlayerState NewState);

class UDesertGrappleFishPlayerComponent : UActorComponent
{
	UPROPERTY()
	UHazeLocomotionFeatureBase ZoeFeatureBase;

	UPROPERTY()
	UHazeLocomotionFeatureBase MioFeatureBase;

	//Temp playing the anim as a slot animation so I can test properly /Zodiac
	UPROPERTY()
	UAnimSequence TempEndJumpAnim;

	access ExternalReadOnly = private, *(readonly);

	access: ExternalReadOnly EDesertGrappleFishPlayerState State;

	ADesertGrappleFish GrappleFish;

	AHazePlayerCharacter Player;

	TArray<FInstigator> RidingCameraInstigators;

	FGrappleFishPlayerStateChange OnStateChange;

	ESandSharkLandscapeLevel LandscapeLevel = ESandSharkLandscapeLevel::Upper;

	bool bTutorialStarted = false;
	bool bTutorialCompleted = false;
	bool bTriggerEndJump = false;
	bool bShouldDetachFromShark = false;

	float JumpPoIForwardOffset = 2600.0;
	float JumpPoIVerticalOffset = 400.0;

	FVector2D TurnBS;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void TriggerEndJump()
	{
		bTriggerEndJump = true;
		GrappleFish.DetachRopeFromPlayer();
		GrappleFish.SharkMesh.AddTag(ComponentTags::HideOnCameraOverlap);
	}

	UFUNCTION()
	void TriggerEndJumpDetach()
	{
		bShouldDetachFromShark = true;
		//Player.AddMovementImpulse((Player.ActorForwardVector * GrappleFishPlayer::EndJumpMovementImpulseMagnitude) + (FVector::UpVector * 500.0));
	}

	void MakePlayerUnstable()
	{
		TurnBS.Y = 1;
	}

	void AddLocomotionFeature(UObject Instigator)
	{
		if (Player.IsMio())
			Player.AddLocomotionFeature(MioFeatureBase, Instigator, 500);
		else
			Player.AddLocomotionFeature(ZoeFeatureBase, Instigator, 500);
	}

	void RemoveLocomotionFeature(UObject Instigator)
	{
		if (Player.IsMio())
			Player.RemoveLocomotionFeature(MioFeatureBase, Instigator);
		else
			Player.RemoveLocomotionFeature(ZoeFeatureBase, Instigator);
	}

	void RequestLocomotion(FInstigator Instigator)
	{
		if (Player.Mesh.CanRequestLocomotion())
		{
			Player.Mesh.RequestLocomotion(n"PlayerGrappleFish", Instigator);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		auto Log = TEMPORAL_LOG(this);
		Log.Value("State", State);
		for (int i = 0; i < RidingCameraInstigators.Num(); i++)
			Log.Value(f"RideCameraInstigators;Instigator{i}", RidingCameraInstigators[i]);

#endif
	}

	void ChangeState(EDesertGrappleFishPlayerState NewState)
	{
		Player.ClearPointOfInterestByInstigator(GrappleFish);
		State = NewState;
		OnStateChange.Broadcast(NewState);

		switch (State)
		{
			case EDesertGrappleFishPlayerState::None:
				break;
			case EDesertGrappleFishPlayerState::Grappling:
				UDesertGrappleFishPlayerEventHandler::Trigger_OnStartGrappleToFish(Player);
				break;
			case EDesertGrappleFishPlayerState::Riding:
				UDesertGrappleFishPlayerEventHandler::Trigger_OnStartRidingFish(Player);
				break;
			case EDesertGrappleFishPlayerState::Launched:
				UDesertGrappleFishPlayerEventHandler::Trigger_OnLaunchFromGrappleFish(Player);
				break;
			case EDesertGrappleFishPlayerState::FinalJump:
				UDesertGrappleFishPlayerEventHandler::Trigger_OnFinalJumpDetachFromFish(Player);
			break;
		}
	}

	void LaunchFromGrappleFish(bool bApplyLaunchPOI = false)
	{
		ChangeState(EDesertGrappleFishPlayerState::Launched);
		FPlayerLaunchToParameters Params;
		Params.Type = EPlayerLaunchToType::LaunchWithImpulse;
		Params.Duration = 0.0;
		Params.LaunchImpulse = FVector::UpVector * GrappleFishPlayer::LaunchUpwardsImpulse + (GrappleFish.Velocity * GrappleFishPlayer::LaunchForwardImpulseSpeedFraction);
		Player.LaunchPlayerTo(this, Params);
		GrappleFish.HandleDismount();

		if (bApplyLaunchPOI)
		{
			FApplyPointOfInterestSettings LaunchPOISettings;
			LaunchPOISettings.Duration = -1;
			LaunchPOISettings.RegainInputTime = 0.25;
			LaunchPOISettings.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Medium;
			LaunchPOISettings.ClearOnInput = GrappleFishDismountPOIClearOnInput;
			FHazePointOfInterestFocusTargetInfo LaunchPOIFocusInfo;
			LaunchPOIFocusInfo.SetFocusToComponent(GrappleFish.SharkRoot);
			LaunchPOIFocusInfo.LocalOffset = FVector::ForwardVector * JumpPoIForwardOffset;
			LaunchPOIFocusInfo.WorldOffset = FVector::UpVector * JumpPoIVerticalOffset;
			Player.ApplyPointOfInterest(GrappleFish, LaunchPOIFocusInfo, LaunchPOISettings, 2, EHazeCameraPriority::High);
		}

		Player.PlayForceFeedback(GrappleFish.LaunchFF, false, true, this);
		Player.PlayCameraShake(GrappleFish.LaunchCamShake, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Timer::SetTimer(this, n"UnblockAirMoves", 1.0);
	}

	UFUNCTION()
	private void UnblockAirMoves()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
	}
};
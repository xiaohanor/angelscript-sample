class UHackablePinballCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 110;	// After FlipLeft/FlipRight

	default CapabilityTags.Add(Pinball::Tags::Pinball);

	AHackablePinball HackablePinball;
	AHazePlayerCharacter MagnetPlayer;
	UMagnetDroneComponent MagnetDroneComp;
	UPinballMagnetDroneRailComponent RailComp;
	APinballFocusTarget FocusTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HackablePinball = Cast<AHackablePinball>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HackablePinball.HijackableTarget.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (!HackablePinball.HijackableTarget.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HackablePinball.bIsHacked = true;

        MagnetPlayer = Drone::GetMagnetDronePlayer();
		MagnetDroneComp = UMagnetDroneComponent::Get(MagnetPlayer);
		RailComp = UPinballMagnetDroneRailComponent::Get(MagnetPlayer);

		if(HackablePinball.CameraActor != nullptr)
		{
			auto FocusCamera = Cast<AFocusCameraActor>(HackablePinball.CameraActor);
			if(FocusCamera != nullptr)
			{
				FHazeCameraWeightedFocusTargetInfo TargetInfo;
				FocusTarget = SpawnActor(APinballFocusTarget, MagnetPlayer.ActorLocation);
				TargetInfo.SetFocusToActor(FocusTarget);
				FocusCamera.FocusTargetComponent.AddFocusTarget(TargetInfo, this);
			}

			MagnetPlayer.ActivateCamera(HackablePinball.CameraActor, 0, this);
			MagnetPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant, EHazeViewPointPriority::Override);
		}

		CapabilityInput::LinkActorToPlayerInput(HackablePinball, HackablePinball.HijackableTarget.GetHijackPlayer());

		if(Pinball::Prediction::IsPredictedGame())
		{
			auto PredictionManager = Pinball::Prediction::GetManager();
			PredictionManager.bUseCrumbSyncedMovement.Apply(false, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HackablePinball.bIsHacked = false;

		if(HackablePinball.CameraActor != nullptr)
		{
			auto FocusCamera = Cast<AFocusCameraActor>(HackablePinball.CameraActor);
			if(FocusCamera != nullptr)
			{
				FocusTarget.DestroyActor();
				FocusCamera.FocusTargetComponent.RemoveAllAddFocusTargetsByInstigator(this);
			}

			MagnetPlayer.DeactivateCamera(HackablePinball.CameraActor, 0);
			MagnetPlayer.ClearViewSizeOverride(this);
		}

		MagnetPlayer.SnapCameraBehindPlayer();

		CapabilityInput::LinkActorToPlayerInput(HackablePinball, nullptr);

		if(Pinball::Prediction::IsPredictedGame())
		{
			auto PredictionManager = Pinball::Prediction::GetManager();
			PredictionManager.bUseCrumbSyncedMovement.Clear(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(auto Paddle : Pinball::GetPaddles())
		{
			Paddle.TickPaddle(DeltaTime);
		}

		if(FocusTarget != nullptr)
		{
			FVector FocusLocation = MagnetDroneComp.DroneMesh.WorldLocation;
			
			if(!RailComp.IsInAnyRail())
				FocusLocation.X = 0;

			FocusTarget.SetActorLocation(FocusLocation);
		}
	}
}
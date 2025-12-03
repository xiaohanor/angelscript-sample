class ASolarFlareHoverPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent LeftRightInteractComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent UpDownInteractComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EngineRoot;
	UPROPERTY(DefaultComponent, Attach = EngineRoot)
	UNiagaraComponent LeftThruster;
	default LeftThruster.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = EngineRoot)
	UNiagaraComponent RightThruster;
	default RightThruster.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = EngineRoot)
	UNiagaraComponent UpThruster;
	default UpThruster.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = EngineRoot)
	UNiagaraComponent DownThruster;
	default DownThruster.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = EngineRoot)
	UNiagaraComponent MainThruster1;
	default MainThruster1.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = EngineRoot)
	UNiagaraComponent MainThruster2;
	default MainThruster2.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareHoverPlatformMoveCapability");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	UHazeCapabilitySheet CapabilitySheet;

	FVector TargetVelocity;

	int ActivatedCount;

	bool bIsActive = false;

	//TODO Checkpoints setup

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftRightInteractComp.OnInteractionStarted.AddUFunction(this, n"OnLeftRightInteractionStarted");
		LeftRightInteractComp.OnInteractionStopped.AddUFunction(this, n"OnLeftRightInteractionStopped");
		UpDownInteractComp.OnInteractionStarted.AddUFunction(this, n"OnUpDownInteractionStarted");
		UpDownInteractComp.OnInteractionStopped.AddUFunction(this, n"OnUpDownInteractionStopped");
	}

	void CheckThrusterActivations()
	{	
		//These checks are based on world direction, not relative.
		//If players move in a direction that is not world forward, these checks will need to change
		if (!UpThruster.IsActive() && TargetVelocity.Z < 0.0)
			UpThruster.Activate();
		else if (UpThruster.IsActive() && TargetVelocity.Z == 0.0)
			UpThruster.Deactivate();

		if (!DownThruster.IsActive() && TargetVelocity.Z > 0.0)
			DownThruster.Activate();
		else if (DownThruster.IsActive() && TargetVelocity.Z == 0.0)
			DownThruster.Deactivate();

		if (!RightThruster.IsActive() && TargetVelocity.Y < 0.0)
			RightThruster.Activate();
		else if (RightThruster.IsActive() && TargetVelocity.Y == 0.0)
			RightThruster.Deactivate();

		if (!LeftThruster.IsActive() && TargetVelocity.Y > 0.0)
			LeftThruster.Activate();
		else if (LeftThruster.IsActive() && TargetVelocity.Y == 0.0)
			LeftThruster.Deactivate();

		if (!MainThruster1.IsActive() && TargetVelocity.X > 0.0)
		{
			MainThruster1.Activate();
			MainThruster2.Activate();
		}
		else if (MainThruster1.IsActive() && TargetVelocity.X == 0.0)
		{
			MainThruster1.Deactivate();
			MainThruster2.Deactivate();
		}
	}

	UFUNCTION()
	private void OnUpDownInteractionStarted(UInteractionComponent Interaction,
	                                         AHazePlayerCharacter Player)
	{
		USolarFlareHoverPlatformComponent UserComp = USolarFlareHoverPlatformComponent::GetOrCreate(Player);
		UserComp.Platform = this;
		UserComp.MovementMode = ESolarFlareHoverPlatformMovementMode::UpDown;
		Player.StartCapabilitySheet(CapabilitySheet, this);
		Player.ActivateCamera(CameraComp, 1.0, this, EHazeCameraPriority::VeryHigh);
		Player.AttachToComponent(Interaction, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void OnUpDownInteractionStopped(UInteractionComponent Interaction,
	                                         AHazePlayerCharacter Player)
	{
		Player.StopCapabilitySheet(CapabilitySheet, this);
		Player.DeactivateCamera(CameraComp, 1.0);
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void OnLeftRightInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		USolarFlareHoverPlatformComponent UserComp = USolarFlareHoverPlatformComponent::GetOrCreate(Player);
		UserComp.Platform = this;
		UserComp.MovementMode = ESolarFlareHoverPlatformMovementMode::LeftRight;
		Player.StartCapabilitySheet(CapabilitySheet, this);
		Player.ActivateCamera(CameraComp, 1.0, this, EHazeCameraPriority::VeryHigh);
		Player.AttachToComponent(Interaction, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void OnLeftRightInteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		Player.StopCapabilitySheet(CapabilitySheet, this);
		Player.DeactivateCamera(CameraComp, 1.0);
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
	}

	void ActivatePlatform(AHazePlayerCharacter ActivatePlayer)
	{
		ActivatedCount++;
		ActivatedCount = Math::Clamp(ActivatedCount, 0, 2);

		if (ActivatedCount == 2)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				USolarFlareHoverPlatformComponent UserComp = USolarFlareHoverPlatformComponent::GetOrCreate(Player);
				UserComp.bActivated = true;
			}

			bIsActive = true;
			Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);

			UpDownInteractComp.bPlayerCanCancelInteraction = false;
			LeftRightInteractComp.bPlayerCanCancelInteraction = false;
		}
	}

	void ReduceActivateCount(AHazePlayerCharacter Player)
	{
		//If already active, don't reduce count
		if (bIsActive)
			return;

		ActivatedCount--;
		ActivatedCount = Math::Clamp(ActivatedCount, 0, 2);
	}
}
event void FOnSolarFlareSpaceLiftCubeStageChange(int StageIndex);

asset SolarFlareSpaceLiftCameraBlend of UCameraDefaultBlend
{
	bIncludeLocationVelocity = true;
}

class ASolarFlareSpaceLiftMain : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareSpaceLiftCubeStageChange OnSolarFlareSpaceLiftCubeStageChange;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent OutsideRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UPlayerInheritMovementComponent InheritMovementComp;
	
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent LeftRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent RightRoot;

	UPROPERTY(DefaultComponent, Attach = RightRoot)
	USceneComponent PoleAnchor;

	UPROPERTY(DefaultComponent, Attach = OutsideRoot)
	USceneComponent FirstLaunchPointRoot;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USolarFlareSplineMoveComponent SplineMoveComp;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent ReactionComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestPlayerComp;
	default RequestPlayerComp.InitialStoppedPlayerCapabilities.Add(n"PlayerMovementJohnDirectionInputCapability");

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SpaceLiftRotationCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SpaceLiftHalfSplitCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SpaceLiftPhaseOneCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SpaceLiftPhaseTwoCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SpaceLiftPhaseThreeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SpaceLiftPhaseFourCapability");

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASolarFlareSun Sun;

	UPROPERTY(EditAnywhere, Category = "Stage1")
	ARespawnPoint RespawnPoint1;

	UPROPERTY(EditAnywhere, Category = "Stage1")
	AStaticCameraActor CameraStage1;

	UPROPERTY(EditAnywhere, Category = "Stage1")
	TArray<ASolarFlareSpaceLiftOuterCover> OuterCoversStage1;
	
	UPROPERTY(EditAnywhere, Category = "Stage2")
	ARespawnPoint RespawnPoint2;

	UPROPERTY(EditAnywhere, Category = "Stage2")
	AStaticCameraActor CameraStage2;

	UPROPERTY(EditAnywhere, Category = "Stage2")
	TArray<ASolarFlareSpaceLiftBreakingCover> BreakingCovers;

	UPROPERTY(EditAnywhere, Category = "Stage2")
	TArray<ASolarFlareSpaceLiftOuterCover> OuterCoversStage2;

	UPROPERTY(EditAnywhere, Category = "Stage2")
	TArray<APoleClimbActor> PoleClimbs;

	UPROPERTY(EditAnywhere, Category = "Stage2")
	ASplineActor LockSplineStage2;
	
	UPROPERTY(EditAnywhere, Category = "Stage3")
	ARespawnPoint RespawnPoint3;

	UPROPERTY(EditAnywhere, Category = "Stage3")
	AStaticCameraActor CameraStage3;

	UPROPERTY(EditAnywhere, Category = "Stage3")
	ASplineActor LockSplineStage3;

	UPROPERTY(EditAnywhere, Category = "Stage3")
	ASolarFlareSpaceLiftSpinningCover SpinningCover; 

	UPROPERTY(EditAnywhere, Category = "Stage4")
	ARespawnPoint RespawnPoint4;

	UPROPERTY(EditAnywhere, Category = "Stage4")
	ASplineFollowCameraActor TrackerCam;

	UPROPERTY(EditAnywhere, Category = "Stage4")
	TArray<AGrappleLaunchPoint> LaunchPoints1;

	UPROPERTY(EditAnywhere, Category = "Stage4")
	TArray<AButtonGrapplePoint> ButtonGrapplePoints1;

	UPROPERTY(EditAnywhere, Category = "Stage4")
	TArray<AGrappleLaunchPoint> LaunchPoints2;

	UPROPERTY(EditAnywhere, Category = "Stage4")
	TArray<AButtonGrapplePoint> ButtonGrapplePoints2;

	FRotator TargetRot;
	FRotator TargetRotPoleAnchor;
	float TargetSplitOffsetY;

	int CurrentHits = 0;

	bool bLiftActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ReactionComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
		TargetRot = MeshRoot.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// PrintToScreen("GAMEPLAYH MODE: " + UPlayerTargetablesComponent::Get(Game::Mio).TargetingMode.Get());
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		StageImpactCheck();
	}

	UFUNCTION()
	void ActivateSpaceLiftCube(float BlendTime = 2.5)
	{
		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCamera(CameraStage1, BlendTime, this);
			Player.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::SideScroller, this);
		}
		
		bLiftActive = true;
		SplineMoveComp.ActivateSplineMovement();
		Sun.ManualActivateSunFlareSequence();
	}

	UFUNCTION()
	void Dev_SpaceLiftCubePhase4()
	{
		CurrentHits = SolarFlareSpaceLiftData::Stage4;
		bLiftActive = true;
		SplineMoveComp.ActivateSplineMovement();
		Sun.ManualActivateSunFlareSequence();
		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
	
		TargetSplitOffsetY = 600.0;

		TargetRot += FRotator(0.0, 0.0, 90);
		TargetRot += FRotator(0.0, 0.0, 90);
		MeshRoot.RelativeRotation = TargetRot;
	}

	UFUNCTION()
	void StageImpactCheck()
	{
		if (!bLiftActive)
			return;
		
		//Set next activate time for delay
		CurrentHits++;
	}
}
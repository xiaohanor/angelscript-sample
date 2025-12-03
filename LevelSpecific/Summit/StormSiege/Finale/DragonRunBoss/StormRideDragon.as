struct FDragonRunPlayerDragonSplineSelection
{
	UPROPERTY(EditAnywhere)
	ASplineActor AcidSpline;
	UPROPERTY(EditAnywhere)
	ASplineActor TailSpline;
	UPROPERTY(EditAnywhere)
	float AcidAttackDelay;
	UPROPERTY(EditAnywhere)
	float TailAttackDelay;
}

UCLASS(Abstract)
class AStormRideDragon : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UStormRideDragonAttackBoxComponent Stage1;
	default InitializeBoxComp(Stage1);
	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UStormRideDragonAttackBoxComponent Stage2;
	default InitializeBoxComp(Stage2);
	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UStormRideDragonAttackBoxComponent Stage3;
	default InitializeBoxComp(Stage3);
	// UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	// UBoxComponent SlideStartComp;
	// default InitializeBoxComp(SlideStartComp);
	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UBoxComponent SlideFinishComp;
	default InitializeBoxComp(SlideFinishComp);

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UInteractionComponent InteractCompMio2;
	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UInteractionComponent InteractCompZoe2;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormRideDragonSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StormRideDragonMeshRotationCapability");

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(EditAnywhere, Category = "Setup | Basic")
	ASplineActor Spline;
	UPROPERTY(EditAnywhere, Category = "Setup | Basic")
	ADragonRunAcidDragon AcidDragon;
	UPROPERTY(EditAnywhere, Category = "Setup | Basic")
	ADragonRunTailDragon TailDragon;

	UPROPERTY(EditAnywhere, Category = "Setup | Weakpoints")
	ADoubleInteractionActor DoubleInteract1;
	UPROPERTY(EditAnywhere, Category = "Setup | Weakpoints")
	ADoubleInteractionActor DoubleInteract2;
	UPROPERTY(EditAnywhere, Category = "Setup | Weakpoints")
	ADoubleInteractionActor DoubleInteract3;
	UPROPERTY(EditAnywhere, Category = "Setup | Weakpoints")
	ADoubleInteractionActor DoubleInteract4;
	UPROPERTY(EditAnywhere, Category = "Setup | Weakpoints")
	AStormRideDragonWeakpoint InteractWeakPoint1;
	UPROPERTY(EditAnywhere, Category = "Setup | Weakpoints")
	AStormRideDragonWeakpoint InteractWeakPoint2;
	UPROPERTY(EditAnywhere, Category = "Setup | Weakpoints")
	AStormRideDragonWeakpoint InteractWeakPoint3;
	UPROPERTY(EditAnywhere, Category = "Setup | Weakpoints")
	AStormRideDragonWeakpoint InteractWeakPoint4;

	UPROPERTY(EditAnywhere, Category = "Setup | Cameras")
	ASplineFollowFocusTrackerCameraActor SplineCamera;
	UPROPERTY(EditAnywhere, Category = "Setup | Cameras")
	ASplineFollowFocusTrackerCameraActor SplineCameraVertical;  
	UPROPERTY(EditAnywhere, Category = "Setup | Cameras")
	ASplineFollowFocusTrackerCameraActor SplineCamera2;
	
	//TArray<AStormRideDragonFin> Fins;
	//TArray<AStormRideSlideFin> Spikes;
	UPROPERTY(EditAnywhere, Category = "Setup | VerticalClimb")
	ASplineActor VerticalLockSpline;

	UPROPERTY(EditAnywhere, Category = "Setup | PlayerDragonSettings")
	TArray<FDragonRunPlayerDragonSplineSelection> PlayerDragonSplines;
	UPROPERTY(EditAnywhere, Category = "Setup | PlayerDragonSettings")
	TArray<AActor> AcidTargets;

	int StageIndex = 0;
	TArray<UStormRideDragonAttackBoxComponent> CompletedOverlapComps;

	bool bSlideCompleted;
	bool bSlideActive;
	
	bool bClimbCompleted;

	UPROPERTY()
	float MoveSpeed = 1000.0;

	FVector OffsetMovement;
	FVector TargetOffset;

	FRotator RelativeMeshRotTarget;

	float QInterp = 0.4;

	bool bAttachedForSlide;
	bool bRunningVerticalTransition;
	bool bRunningVerticalToHorizontalTransition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<UStormRideDragonAttackBoxComponent> BoxComps;
		GetComponentsByClass(BoxComps);

		for (UStormRideDragonAttackBoxComponent BoxComp : BoxComps)
		{
			BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentAttackBeginOverlap");
			InitializeBoxComp(BoxComp);
		}	

		SlideFinishComp.OnComponentBeginOverlap.AddUFunction(this, n"SlideFinishCompBeginOverlap");

		DoubleInteract1.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted1");
		DoubleInteract2.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted2");
		DoubleInteract3.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted3");
		DoubleInteract4.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted4");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bAttachedForSlide)
		{
			Game::Mio.ActorLocation = DoubleInteract1.LeftInteraction.WorldLocation;
			Game::Zoe.ActorLocation = DoubleInteract1.RightInteraction.WorldLocation;
			Game::Mio.ActorRotation = DoubleInteract1.LeftInteraction.WorldRotation;
			Game::Zoe.ActorRotation = DoubleInteract1.RightInteraction.WorldRotation;
		}

		if (bRunningVerticalTransition)
		{
			Game::Mio.ActorLocation = DoubleInteract2.LeftInteraction.WorldLocation;
			Game::Zoe.ActorLocation = DoubleInteract2.RightInteraction.WorldLocation;
		}

		if (bRunningVerticalToHorizontalTransition)
		{
			Game::Mio.ActorLocation = DoubleInteract3.LeftInteraction.WorldLocation;
			Game::Zoe.ActorLocation = DoubleInteract3.RightInteraction.WorldLocation;		
		}
	}

	UFUNCTION()
	void InitiateSplineCamera1()
	{
		Game::Mio.ActivateCamera(SplineCamera, 0.0, this, EHazeCameraPriority::VeryHigh);
		Game::Zoe.ActivateCamera(SplineCamera, 0.0, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION()
	void InitiateSplineCameraVertical()
	{
		Game::Mio.ActivateCamera(SplineCameraVertical, 0.0, this, EHazeCameraPriority::VeryHigh);
		Game::Zoe.ActivateCamera(SplineCameraVertical, 0.0, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION()
	void InitiateSplineCamera2()
	{
		Game::Mio.ActivateCamera(SplineCamera2, 0.0, this, EHazeCameraPriority::VeryHigh);
		Game::Zoe.ActivateCamera(SplineCamera2, 0.0, this, EHazeCameraPriority::VeryHigh);
	}

//-------------------------------------------------------------------//
	//*** SLIDE SECTION ***//
//-------------------------------------------------------------------//

	UFUNCTION()
	private void OnDoubleInteractionCompleted1()
	{
		InteractWeakPoint1.ActivateWeakpointDestruction();
		DoubleInteract1.DisableDoubleInteraction(this);
		Timer::SetTimer(this, n"Interact1DelayedReaction", 1.0, false);

		TListedActors<AStormRideSlideFin> Spikes;
		for (AStormRideSlideFin SlideFin : Spikes)
		{
			SlideFin.ActivateSlideFin();
		}

		bAttachedForSlide = true;
	}

	UFUNCTION()
	void Interact1DelayedReaction()
	{
		if (bSlideCompleted)
			return;

		bSlideActive = true;
		RelativeMeshRotTarget = FRotator(-25.0, 0.0, 0.0);
		FSlideParameters SlideParams;
		SlideParams.SlideType = ESlideType::Freeform;
		Game::Mio.ForcePlayerSlide(this, SlideParams);
		Game::Zoe.ForcePlayerSlide(this, SlideParams);
		QInterp = 0.4;

		bAttachedForSlide = false;
	}

	UFUNCTION()
	private void SlideFinishCompBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                         UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                         bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (bSlideCompleted)
			return;
		
		TListedActors<AStormRideSlideFin> Spikes;
		for (AStormRideSlideFin SlideFin : Spikes)
		{
			SlideFin.DeactivateSlideFin();
		}

		bSlideCompleted = true;
		bSlideActive = false;
		RelativeMeshRotTarget = FRotator(0.0, 0.0, 0.0);

		Game::Mio.ClearForcePlayerSlide(this);
		Game::Zoe.ClearForcePlayerSlide(this);
		QInterp = 0.9;
	}

//-------------------------------------------------------------------//
	//*** VERTICAL START SECTION ***//
//-------------------------------------------------------------------//

	UFUNCTION()
	private void OnDoubleInteractionCompleted2()
	{
		Game::Mio.BlockCapabilities(CapabilityTags::Movement, this);
		Game::Zoe.BlockCapabilities(CapabilityTags::Movement, this);
		//Attaches don't work for rotations for some reason
		// Game::Mio.AttachToComponent(VerticalAttachPointMio, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, true);
		// Game::Zoe.AttachToComponent(VerticalAttachPointZoe, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, true);
		InteractWeakPoint2.ActivateWeakpointDestruction();
		DoubleInteract2.DisableDoubleInteraction(this);
		Timer::SetTimer(this, n"Interact2DelayedReaction", 1.0, false);
		bRunningVerticalTransition = true;

		TListedActors<AStormRideSlideFin> Spikes;
		for (AStormRideSlideFin SlideFin : Spikes)
		{
			SlideFin.ActivateSlideFin();
		}
	}

	UFUNCTION()
	private void Interact2DelayedReaction()
	{
		Game::Zoe.ActivateCamera(SplineCameraVertical, 3.0, this);
		Game::Mio.ActivateCamera(SplineCameraVertical, 3.0, this);

		Game::Mio.DeactivateCamera(SplineCamera);
		Game::Zoe.DeactivateCamera(SplineCamera);

		//Start vertical climb
		RelativeMeshRotTarget = FRotator(90.0, 0.0, 0.0);
		QInterp = 1.0;

		TListedActors<AStormRideDragonFin> Fins;
		for (AStormRideDragonFin Fin : Fins)
		{
			Fin.ActivateDragonFin();
		}

		Timer::SetTimer(this, n"Interact2DelayedCompletion", 3.0, false);
	}

	UFUNCTION()
	void Interact2DelayedCompletion()
	{
		Game::Mio.UnblockCapabilities(CapabilityTags::Movement, this);
		Game::Zoe.UnblockCapabilities(CapabilityTags::Movement, this);
		Game::Mio.DetachFromActor();
		Game::Zoe.DetachFromActor();
		bRunningVerticalTransition = false;

		FPlayerMovementSplineLockProperties SplineLockParams;
		SplineLockParams.bCanLeaveSplineAtEnd = false;
		SplineLockParams.bRedirectMovementInput = true;
		SplineLockParams.AllowedHorizontalDeviation = 75.0;

		UPlayerSplineLockEnterSettings  Settings = UPlayerSplineLockEnterSettings();
		Settings.EnterType = EPlayerSplineLockEnterType::SmoothLerp;

		Game::Mio.LockPlayerMovementToSpline(VerticalLockSpline, this, EInstigatePriority::High, SplineLockParams, EnterSettings = Settings);
		Game::Zoe.LockPlayerMovementToSpline(VerticalLockSpline, this, EInstigatePriority::High, SplineLockParams);
	}

//-------------------------------------------------------------------//
	//*** VERTICAL END SECTION ***//
//-------------------------------------------------------------------//

	UFUNCTION()
	private void OnDoubleInteractionCompleted3()
	{
		Game::Mio.BlockCapabilities(CapabilityTags::Movement, this);
		Game::Zoe.BlockCapabilities(CapabilityTags::Movement, this);
		InteractWeakPoint3.ActivateWeakpointDestruction();
		DoubleInteract3.DisableDoubleInteraction(this);
		Game::Mio.UnlockPlayerMovementFromSpline(this);
		Game::Zoe.UnlockPlayerMovementFromSpline(this);

		bRunningVerticalToHorizontalTransition = true;
		Timer::SetTimer(this, n"Interact3DelayedReaction", 1.0, false);

		TListedActors<AStormRideSlideFin> Spikes;
		for (AStormRideSlideFin SlideFin : Spikes)
		{
			SlideFin.DeactivateSlideFin();
		}

		TListedActors<AStormRideDragonFin> Fins;
		for (AStormRideDragonFin Fin : Fins)
		{
			Fin.DeactivateDragonFin();
		}
	}

	UFUNCTION()
	private void Interact3DelayedReaction()
	{
		Game::Mio.ActivateCamera(SplineCamera2, 6.0, this);
		Game::Zoe.ActivateCamera(SplineCamera2, 6.0, this);

		Game::Mio.DeactivateCamera(SplineCameraVertical);
		Game::Zoe.DeactivateCamera(SplineCameraVertical);
	
		RelativeMeshRotTarget = FRotator(0.0, 0.0, 0.0);
		QInterp = 0.85;
		Timer::SetTimer(this, n"Interact3DelayedCompletion", 3.0, false);
	}

	UFUNCTION()
	void Interact3DelayedCompletion()
	{
		Game::Mio.UnblockCapabilities(CapabilityTags::Movement, this);
		Game::Zoe.UnblockCapabilities(CapabilityTags::Movement, this);
		bRunningVerticalToHorizontalTransition = false;
	}

//-------------------------------------------------------------------//
	//*** HEAD TRANSITION SECTION ***//
//-------------------------------------------------------------------//

	UFUNCTION()
	private void OnDoubleInteractionCompleted4()
	{
		InteractWeakPoint4.ActivateWeakpointDestruction();
		DoubleInteract4.DisableDoubleInteraction(this);	
		//Players are suppose to jump off the dragon as it crashes into a mountain
		//They grapple to their dragons in slow motion
	}

//-------------------------------------------------------------------//
	//*** ATTACKS ***//
//-------------------------------------------------------------------//

	UFUNCTION()
	private void OnComponentAttackBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (Cast<AHazePlayerCharacter>(OtherActor) == nullptr)
			return;
		
		for (UStormRideDragonAttackBoxComponent Comp : CompletedOverlapComps)
		{
			if (Comp == OverlappedComponent)
				return;
		}
		
		CompletedOverlapComps.Add(Cast<UStormRideDragonAttackBoxComponent>(OverlappedComponent));

		AcidDragon.ActivateSplineMove(PlayerDragonSplines[StageIndex].AcidSpline, PlayerDragonSplines[StageIndex].AcidAttackDelay, AcidTargets[StageIndex]);
		TailDragon.ActivateSplineMove(PlayerDragonSplines[StageIndex].TailSpline, PlayerDragonSplines[StageIndex].TailAttackDelay);

		StageIndex++;
	}

//-------------------------------------------------------------------//
	//*** OTHER ***//
//-------------------------------------------------------------------//

	UFUNCTION()
	void InitializeBoxComp(UBoxComponent Box)
	{
		Box.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
		Box.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
		Box.SetWorldScale3D(FVector(10.0, 35.0, 35.0));		
	}

	void MoveOffset(FVector NewTargetOffset)
	{
		TargetOffset = NewTargetOffset;
		PrintToScreen("MoveOffset");
	}

	UFUNCTION()
	void SetStageIndex(int NewIndex)
	{
		StageIndex = NewIndex;
	}
}
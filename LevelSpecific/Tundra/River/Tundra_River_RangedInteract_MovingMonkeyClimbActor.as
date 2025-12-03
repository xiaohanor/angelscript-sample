event void FOnReachedEnd();
event void FOnLeaveEnd();

class ATundra_River_RangedInteract_MovingMonkeyClimbActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
#if EDITOR
	default SkeletalMesh.bUpdateAnimationInEditor = true;
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoveRoot;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh1Comp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh2Comp;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	UStaticMeshComponent MonkeyClimbMeshComp;

	UPROPERTY(DefaultComponent, Attach = MonkeyClimbMeshComp)
	UTundraPlayerSnowMonkeyCeilingClimbSelectorComponent MonkeyClimbSelectionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent SplineComp;
	default SplineComp.SplinePoints[1].RelativeLocation = FVector(0, 0, 200);

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyCeilingClimbComponent MonkeyClimbComp;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeComp;

	UPROPERTY(EditInstanceOnly)
	ATundraRangedLifeGivingActor LifeGivingActor;

	UPROPERTY(EditAnywhere)
	bool bDebug = false;

	UPROPERTY(EditAnywhere)
	bool bStartFromEndPoint = false;

	UPROPERTY(EditAnywhere)
	float Speed = 400;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset InteractCamSettings;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ReachedEndCameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ReachedEndFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> MoveCameraShake;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedVector;

	UPROPERTY(EditInstanceOnly)
	AActor MeshGroupActor;

	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<AActor> EditorActorToSnapSkeletalMeshTo;

	UPROPERTY(EditInstanceOnly)
	FVector BoneLocalLocationOffset = FVector(0.0, 200.0, -500.0);

	UPROPERTY(EditInstanceOnly)
	FRotator BoneLocalRotationOffset = FRotator(90.0, -90.0, 45.0);

	UPROPERTY()
	FOnReachedEnd OnReachedEnd;

	UPROPERTY()
	FOnLeaveEnd OnLeaveEnd;

	float Input;
	bool bIsAtEnd = false;
	uint FrameOfReachedEnd;
	bool bMoveCamShakePlaying = false;
	UPlayerHealthComponent ZoeHealthComp;
	AHazePlayerCharacter ZoeRef;
	AHazePlayerCharacter MioRef;
	UCameraShakeBase ZoeMoveCameraShakeRef;
	UCameraShakeBase MioMoveCameraShakeRef;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MoveRoot.SetRelativeLocation(bStartFromEndPoint ? SplineComp.SplinePoints[1].RelativeLocation : SplineComp.SplinePoints[0].RelativeLocation);
		MeshGroupActor.SetActorLocation(MoveRoot.GetWorldTransform().InverseTransformPosition(MoveRoot.RelativeLocation));
	}

	UFUNCTION(CallInEditor)
	void SnapSkeletalMeshToStaticMesh()
	{
		if(EditorActorToSnapSkeletalMeshTo == nullptr)
			return;

		SkeletalMesh.WorldLocation = EditorActorToSnapSkeletalMeshTo.Get().ActorLocation;
		SkeletalMesh.WorldRotation = EditorActorToSnapSkeletalMeshTo.Get().ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(LifeGivingActor != nullptr)
		{
			LifeComp = UTundraLifeReceivingComponent::Get(LifeGivingActor);
			LifeComp.OnInteractStart.AddUFunction(this, n"LifeGivingStarted");
			LifeComp.OnInteractStop.AddUFunction(this, n"LifeGivingStopped");
		}

		SetActorControlSide(Game::GetZoe());
		ZoeRef = Game::GetZoe();
		MioRef = Game::GetMio();
		ZoeHealthComp = UPlayerHealthComponent::Get(ZoeRef);
		ZoeHealthComp.OnStartDying.AddUFunction(this, n"ZoeDied");


		
		SyncedVector.Value = bStartFromEndPoint ? SplineComp.SplinePoints[1].RelativeLocation : SplineComp.SplinePoints[0].RelativeLocation;
		MoveRoot.SetRelativeLocation(SyncedVector.Value);
		//MeshGroupActor.SetActorLocation(MoveRoot.GetWorldTransform().InverseTransformPosition(SyncedVector.Value));
	}

	UFUNCTION()
	private void ZoeDied()
	{
		ZoeRef.ClearPointOfInterestByInstigator(this);
		ZoeRef.ClearCameraSettingsByInstigator(this, 3);
	}

	UFUNCTION()
	private void LifeGivingStopped(bool bForced)
	{
		ZoeRef.ClearPointOfInterestByInstigator(this);
		ZoeRef.ClearCameraSettingsByInstigator(this, 3);

		UTundra_River_RangedInteract_MovingMonkeyClimbActorEffectHandler::Trigger_OnStopInteracting(this);
	}

	UFUNCTION()
	private void LifeGivingStarted(bool bForced)
	{
		FHazePointOfInterestFocusTargetInfo POI;
		FApplyPointOfInterestSettings Settings;
		Settings.TurnScaling = FRotator(0.25, 0.25, 0.25);
		POI.SetFocusToComponent(MoveRoot);
		ZoeRef.ApplyPointOfInterest(this, POI, Settings);
		ZoeRef.ApplyCameraSettings(InteractCamSettings, 4, this, EHazeCameraPriority::VeryHigh);

		UTundra_River_RangedInteract_MovingMonkeyClimbActorEffectHandler::Trigger_OnStartInteracting(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(LifeGivingActor != nullptr)
		{
			MoveActor(DeltaSeconds);
		}
	}

	private void MoveActor(float DeltaSeconds)
	{	
		if(HasControl())
		{
			Input = LifeComp.RawVerticalInput;
			float InternalInput = 0;

			if(Input == 0)
			{
				InternalInput = bStartFromEndPoint ? 1 : -1;
			}
			else
			{
				InternalInput = Input;
			}

			FVector TargetLocation = InternalInput > 0 ? SplineComp.SplinePoints[1].RelativeLocation : SplineComp.SplinePoints[0].RelativeLocation;

			FVector ToTargetDelta = (TargetLocation - MoveRoot.RelativeLocation);
			FVector ToTargetDirection = ToTargetDelta.GetSafeNormal();

			FVector MoveDelta = (ToTargetDirection * Speed * DeltaSeconds * Math::Abs(InternalInput));

			if(bDebug)
				PrintToScreen(" " + MoveDelta.Size(), 1);

			if(MoveDelta.Size() > ToTargetDelta.Size())
			{
				MoveDelta = ToTargetDelta;
				bool bReachedStartingPosition = InternalInput > 0;
				if(!bStartFromEndPoint)
					bReachedStartingPosition = !bReachedStartingPosition;

				CrumbHasReachedEnd(bReachedStartingPosition);
			}

			if(MoveDelta.Size() > 0)
			{
				if(bIsAtEnd && Time::FrameNumber != FrameOfReachedEnd)
				{
					OnLeaveEnd.Broadcast();
					// Print("ONLEAVEEND", 3);
					bIsAtEnd = false;
				}

				if(!bMoveCamShakePlaying)
				{
					bMoveCamShakePlaying = true;
					CrumbPlayMoveCameraShake();
				}
			}
			else if(bMoveCamShakePlaying)
			{
				bMoveCamShakePlaying = false;
				CrumbStopPlayingCameraShake();
			}

			SyncedVector.Value = MoveRoot.RelativeLocation + MoveDelta;
			MoveRoot.SetRelativeLocation(SyncedVector.Value);
			//MeshGroupActor.SetActorLocation(ActorLocation + MoveDelta);
		}

		else
		{
			MoveRoot.SetRelativeLocation(SyncedVector.Value);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHasReachedEnd(bool bReachedStartingPosition)
	{
		ZoeRef.PlayWorldCameraShake(ReachedEndCameraShake, this, MoveRoot.WorldLocation, 2000, 7000);
		MioRef.PlayWorldCameraShake(ReachedEndCameraShake, this, MoveRoot.WorldLocation, 2000, 7000);
		ZoeRef.PlayForceFeedback(ReachedEndFF, false, false, this);
		MioRef.PlayForceFeedback(ReachedEndFF, false, false, this);

		FrameOfReachedEnd = Time::FrameNumber;

		if(bReachedStartingPosition)
		{
			UTundra_River_RangedInteract_MovingMonkeyClimbActorEffectHandler::Trigger_OnReachMin(this);
		}
		else
		{
			OnReachedEnd.Broadcast();
			// Print("ONREACHEDEND", 3);
			bIsAtEnd = true;
			UTundra_River_RangedInteract_MovingMonkeyClimbActorEffectHandler::Trigger_OnReachMax(this);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayMoveCameraShake()
	{
		ZoeMoveCameraShakeRef = ZoeRef.PlayWorldCameraShake(MoveCameraShake, this, MoveRoot.WorldLocation, 2000, 7000);
		MioMoveCameraShakeRef = MioRef.PlayWorldCameraShake(MoveCameraShake, this, MoveRoot.WorldLocation, 2000, 7000);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStopPlayingCameraShake()
	{
		ZoeRef.StopCameraShakeInstance(ZoeMoveCameraShakeRef);
		MioRef.StopCameraShakeInstance(MioMoveCameraShakeRef);
	}

	/* Will return value between 0-1, 0 is when moving climb is at default position, 1 is when it is at moved position */
	UFUNCTION(BlueprintPure)
	float AudioGetCurrentMoveAlpha() const
	{
		float SplineLength = (SplineComp.SplinePoints[0].RelativeLocation - SplineComp.SplinePoints[1].RelativeLocation).Size();
		float CurrentDistance = (MoveRoot.RelativeLocation - SplineComp.SplinePoints[0].RelativeLocation).Size();
		float Alpha = CurrentDistance / SplineLength;
		if(bStartFromEndPoint)
			Alpha = 1.0 - Alpha;

		return Alpha;
	}
};
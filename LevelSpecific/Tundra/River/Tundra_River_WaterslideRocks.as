class UTundra_River_WaterSlideRocksEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnStartMoving() {};

	UFUNCTION(BlueprintEvent)
	void OnStopMoving() {};

	UFUNCTION(BlueprintEvent)
	void OnHitConstraint() {};
}

UCLASS(Abstract)
class ATundra_River_WaterslideRocks : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoveRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Move2Root;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	USceneComponent Mesh1Root;

	UPROPERTY(DefaultComponent, Attach = Move2Root)
	USceneComponent Mesh2Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase LeftRootsMesh;
#if EDITOR
	default LeftRootsMesh.bUpdateAnimationInEditor = true;
#endif

	UPROPERTY(DefaultComponent, Attach = Mesh1Root)
	USceneComponent LeftRootsMeshTipPoint;
	default LeftRootsMeshTipPoint.RelativeLocation = FVector(-1914.222892, -1898.629112, 1015.305952);

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase RightRootsMesh;
#if EDITOR
	default RightRootsMesh.bUpdateAnimationInEditor = true;
#endif

	UPROPERTY(DefaultComponent, Attach = Mesh2Root)
	USceneComponent RightRootsMeshTipPoint;
	default RightRootsMeshTipPoint.RelativeLocation = FVector(-199.553328, -638.666563, 239.474706);
	default RightRootsMeshTipPoint.RelativeRotation = FRotator(-45.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedVector;

	UPROPERTY(EditInstanceOnly)
	ATundraRangedLifeGivingActor LifeGivingActor;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Editor")
	TSoftObjectPtr<AActor> LeftRoot;

	UPROPERTY(EditInstanceOnly, Category = "Editor")
	TSoftObjectPtr<AActor> RightRoot;
#endif

	UPROPERTY(EditAnywhere)
	float Speed = 1400;

	UPROPERTY(EditAnywhere)
	float MoveDistance = 600;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ReachedEndCameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ReachedEndFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> MoveCameraShake;

	FHazeAcceleratedVector GateAccelVector;
	float Input;
	bool bMoveCamShakePlaying = false;
	AHazePlayerCharacter ZoeRef;
	AHazePlayerCharacter MioRef;
	UCameraShakeBase ZoeMoveCameraShakeRef;
	UCameraShakeBase MioMoveCameraShakeRef;
	FVector PreviousTargetLocation;
	FVector RootsTargetRelativeLocation;

	// Audio
	private FVector PreviousSyncedLocation;
	private FVector SyncedVelo;

#if EDITOR
	// UFUNCTION(CallInEditor)
	// void SnapRootsToRootActors()
	// {
	// 	if(LeftRoot == nullptr)
	// 		return;

	// 	if(RightRoot == nullptr)
	// 		return;

	// 	LeftRootsMesh.WorldTransform = LeftRoot.Get().ActorTransform;
	// 	RightRootsMesh.WorldTransform = RightRoot.Get().ActorTransform;

	// 	LeftRootsMesh.WorldRotation = FRotator::MakeFromXZ(LeftRootsMesh.ForwardVector.RotateAngleAxis(25.0, FVector::UpVector), FVector::UpVector);
	// 	RightRootsMesh.WorldRotation = FRotator::MakeFromXZ(RightRootsMesh.ForwardVector.RotateAngleAxis(25.0, FVector::UpVector), FVector::UpVector);

	// 	LeftRoot.Get().SetActorHiddenInGame(true);
	// 	RightRoot.Get().SetActorHiddenInGame(true);
	// }

	// UFUNCTION(CallInEditor)
	// void SnapTipPointsToBones()
	// {
	// 	LeftRootsMeshTipPoint.WorldLocation = LeftRootsMesh.GetSocketLocation(n"LeftBranch11");
	// 	RightRootsMeshTipPoint.WorldLocation = RightRootsMesh.GetSocketLocation(n"RightBranch13");
	// }

	UFUNCTION(CallInEditor, DisplayName = "Select Right Root Mesh")
	void ASelectRightRootMesh()
	{
		Editor::SelectComponent(RightRootsMesh);
	}

	UFUNCTION(CallInEditor, DisplayName = "Select Left Root Mesh")
	void BSelectLeftRootMesh()
	{
		Editor::SelectComponent(LeftRootsMesh);
	}

	UFUNCTION(CallInEditor, DisplayName = "Select Right Root Tip Point")
	void CSelectRightRootTipPoint()
	{
		Editor::SelectComponent(RightRootsMeshTipPoint);
	}

	UFUNCTION(CallInEditor, DisplayName = "Select Left Root Tip Point")
	void DSelectLeftRootTipPoint()
	{
		Editor::SelectComponent(LeftRootsMeshTipPoint);
	}
#endif

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

		RootsTargetRelativeLocation = MoveRoot.RelativeLocation;
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
			// Input = LifeComp.HorizontalAlpha;
			Input = LifeComp.bCurrentlyInteractingDuringLifeGive ? 1 : 0;

			FVector TargetLocation;

			// if(Input == 0)
			// {
			// 	// TargetLocation = FVector::ZeroVector;
			// }
			// else if(Input < 0)
			// {
			// 	TargetLocation = FVector(0, MoveDistance, 0);
			// }
			// else
			// {
			// 	TargetLocation = FVector(0, -MoveDistance, 0);
			// }

			if(Input == 0)
			{
				TargetLocation = FVector::ZeroVector;
			}
			else
			{
				TargetLocation = FVector(0, MoveDistance, 0);
			}

			// TargetLocation = FVector(0, Math::GetMappedRangeValueClamped(FVector2D(-1, 1), FVector2D(-MoveDistance, MoveDistance), Input), 0);

			FVector ToTargetDelta = (TargetLocation - RootsTargetRelativeLocation);
			FVector ToTargetDirection = ToTargetDelta.GetSafeNormal();

			if(!TargetLocation.Equals(PreviousTargetLocation))
			{
				// if(!SyncedVelo.IsNearlyZero())
				// {
				// 	CrumbStopMoving();
				// }

				CrumbStartMoving();
			}

			PreviousTargetLocation = TargetLocation;

			FVector MoveDelta = (ToTargetDirection * Speed * DeltaSeconds);

			if(MoveDelta.Size() > ToTargetDelta.Size())
			{
				MoveDelta = ToTargetDelta;
				CrumbStopMoving();
				CrumbHasReachedEnd();
			}

			if(MoveDelta.Size() > 0)
			{
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

			SyncedVector.Value = RootsTargetRelativeLocation + MoveDelta;
			RootsTargetRelativeLocation = SyncedVector.Value;
			//MeshGroupActor.SetActorLocation(ActorLocation + MoveDelta);
		}

		GateAccelVector.AccelerateTo(SyncedVector.Value, 0.2, DeltaSeconds);
		MoveRoot.SetRelativeLocation(GateAccelVector.Value);
		Move2Root.SetRelativeLocation(-GateAccelVector.Value);

		SyncedVelo = GateAccelVector.Value - PreviousSyncedLocation;
		PreviousSyncedLocation = GateAccelVector.Value;
	}
	
	UFUNCTION(CrumbFunction)
	private void CrumbHasReachedEnd()
	{
		ZoeRef.PlayWorldCameraShake(ReachedEndCameraShake, this, MoveRoot.WorldLocation, 2000, 7000);
		MioRef.PlayWorldCameraShake(ReachedEndCameraShake, this, MoveRoot.WorldLocation, 2000, 7000);
		ZoeRef.PlayForceFeedback(ReachedEndFF, false, false, this);
		MioRef.PlayForceFeedback(ReachedEndFF, false, false, this);
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

	UFUNCTION()
	private void LifeGivingStopped(bool bForced)
	{
	}

	UFUNCTION()
	private void LifeGivingStarted(bool bForced)
	{
	}

	UFUNCTION(BlueprintPure)
	float GetSyncedMovementSpeed()
	{
		return SyncedVelo.Size();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartMoving()
	{
		// Print("Start Moving", 3);
		UTundra_River_WaterSlideRocksEffectHandler::Trigger_OnStartMoving(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStopMoving()
	{
		// Print("Stop Moving", 3);
		UTundra_River_WaterSlideRocksEffectHandler::Trigger_OnStopMoving(this);
	}
};

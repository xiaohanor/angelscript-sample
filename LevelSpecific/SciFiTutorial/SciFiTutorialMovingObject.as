event void FSciFiTutorialMovingObjectFinishedMovingEvent();

UCLASS(Abstract)
class ASciFiTutorialMovingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ObjectRoot;

	UPROPERTY(DefaultComponent, Attach = ObjectRoot)
	UStaticMeshComponent ObjectMesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(Meta = (MakeEditWidget), EditAnywhere)
	FTransform TargetTransform;

	UPROPERTY(EditAnywhere)
	bool bPreviewTarget = false;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveTimeLike;
	default MoveTimeLike.Duration = 1.0;

	UPROPERTY(EditAnywhere)
	float PlayRate = 1.0;

	UPROPERTY(EditAnywhere)
	float MoveDelay = 0.0;

	UPROPERTY(EditAnywhere)
	TArray<ASciFiTutorialMovingObject> LinkedObjects;

	UPROPERTY()
	FSciFiTutorialMovingObjectFinishedMovingEvent OnFinishedMoving;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewTarget)
			ObjectRoot.SetRelativeLocationAndRotation(TargetTransform.Location, TargetTransform.Rotator());
		else
			ObjectRoot.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			Actor.AttachToComponent(ObjectRoot, AttachmentRule = EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ObjectRoot.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);

		MoveTimeLike.SetPlayRate(PlayRate);

		MoveTimeLike.BindUpdate(this, n"UpdateMove");
		MoveTimeLike.BindFinished(this, n"FinishMove");
	}

	UFUNCTION()
	void StartMoving()
	{
		if (bActivated)
			return;

		bActivated = true;

		if (MoveDelay != 0.0)
			Timer::SetTimer(this, n"Move", MoveDelay);
		else
			Move();
	}

	UFUNCTION(NotBlueprintCallable)
	void Move()
	{
		MoveTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMove(float CurValue)
	{
		FVector Loc = Math::Lerp(FVector::ZeroVector, TargetTransform.Location, CurValue);
		FRotator Rot = Math::LerpShortestPath(FRotator::ZeroRotator, TargetTransform.Rotator(), CurValue);

		ObjectRoot.SetRelativeLocationAndRotation(Loc, Rot);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMove()
	{
		OnFinishedMoving.Broadcast();

		for (ASciFiTutorialMovingObject Object : LinkedObjects)
		{
			Object.StartMoving();
		}
	}
}

class ASciFiTutorialMovingObjectManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(3.0);

	bool bPreviewing = false;

#if EDITOR
	UFUNCTION(CallInEditor)
	void TogglePreviewTransforms()
	{
		bPreviewing = !bPreviewing;

		TListedActors<ASciFiTutorialMovingObject> Objects;
		for (ASciFiTutorialMovingObject Object : Objects)
		{
			Object.bPreviewTarget = bPreviewing;
			Object.RerunConstructionScripts();
		}
	}
#endif
}
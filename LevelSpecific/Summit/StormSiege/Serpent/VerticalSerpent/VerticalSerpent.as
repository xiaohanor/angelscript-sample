event void FOnVerticalSerpentClose();

class AVerticalSerpent : AHazeActor
{
	UPROPERTY()
	FOnVerticalSerpentClose OnVerticalSerpentClose;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	UStaticMeshComponent Eye1;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	UStaticMeshComponent Eye2;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	ASplineActor AcidSpline;
	UPROPERTY(EditAnywhere)
	ASplineActor TailSpline;

	UPROPERTY(EditAnywhere)
	float TailAttackDelay = 1.0;
	UPROPERTY(EditAnywhere)
	float AcidAttackDelay = 1.0;

	UPROPERTY()
	float RightMoveAmount = 1500.0;
	UPROPERTY()
	float UpMoveAmount = -1900.0;

	float FallSpeed = 6500;
	float SaveDistance = 11000.0;

	ADragonRunAcidDragon AcidDragon;
	ADragonRunTailDragon TailDragon;

	bool bFiredCloseEvent;
	bool bIsActive = false;
	bool bVerticalAllowed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidDragon = TListedActors<ADragonRunAcidDragon>().GetSingle();
		TailDragon = TListedActors<ADragonRunTailDragon>().GetSingle();
		SetActorTickEnabled(false);
		// Eye1.AttachToComponent(SkelMesh, n"Jaw", EAttachmentRule::KeepRelative);
		// Eye2.AttachToComponent(SkelMesh, n"Jaw", EAttachmentRule::KeepRelative);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation += -FVector::UpVector * FallSpeed * DeltaSeconds;
		
		PrintToScreen("Distance: " + (ActorLocation - Game::Mio.ActorLocation).Size());

		if ((ActorLocation - Game::Mio.ActorLocation).Size() < SaveDistance && !bFiredCloseEvent)
		{
			bFiredCloseEvent = true;
			DragonsAttack();
			Timer::SetTimer(this, n"DragonsHit", 1.5, false);
			OnVerticalSerpentClose.Broadcast();
		}

		PrintToScreen("TimeDilation: " + Time::WorldTimeDilation);
	}

	UFUNCTION()
	void ActivateVerticalSerpent()
	{
		bIsActive = true;
		bVerticalAllowed = true;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DragonsAttack()
	{
		AcidDragon.ActivateSplineMove(AcidSpline, AcidAttackDelay, this);
		TailDragon.ActivateSplineMove(TailSpline, TailAttackDelay, this);
	}

	UFUNCTION()
	void DragonsHit()
	{
		BP_SerpentHit();
		bVerticalAllowed = false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_SerpentHit() {}
}
struct FBattlefieldMoveObjectParams
{
	UPROPERTY()
	ABattlefieldTriggerableObjectMove ObjectTarget;
	UPROPERTY()
	float DelayMoveTime = 0.0;
	UPROPERTY()
	float RotationSpeed = 10.0;
	UPROPERTY()
	float MoveSpeed = 4000.0;
}

event void FOnBattlefieldObjectMoveStarted();
event void FOnBattlefieldObjectMoveToNext();
event void FOnBattlefieldObjectMoveFinished();

class ABattlefieldTriggerableObjectMove : AHazeActor
{
	UPROPERTY()
	FOnBattlefieldObjectMoveStarted OnBattlefieldObjectMoveStarted;

	UPROPERTY()
	FOnBattlefieldObjectMoveFinished OnBattlefieldObjectMoveFinished;

	UPROPERTY()
	FOnBattlefieldObjectMoveToNext OnBattlefieldObjectMoveToNext;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(EditAnywhere)
	bool bIsDud = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bIsDud", EditConditionHides))
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "!bIsDud", EditConditionHides))
	TArray<FBattlefieldMoveObjectParams> MoveObjectTargets;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bIsDud", EditConditionHides))
	bool bActivateOnce = true;

	bool bWasOneTimeActivated;

	int Index;

	float WaitTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		if (bIsDud)
		{
			TArray<UStaticMeshComponent> MeshComps;
			GetComponentsByClass(MeshComps);

			for (UStaticMeshComponent Comp : MeshComps)
			{
				Comp.SetHiddenInGame(true);
				Comp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			}
		}
		else
		{
			if (PlayerTrigger != nullptr)
				PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < WaitTime)
			return;

		FVector TargetLoc = MoveObjectTargets[Index].ObjectTarget.ActorLocation;
		FRotator TargetRot = MoveObjectTargets[Index].ObjectTarget.ActorRotation;
		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLoc, DeltaSeconds, MoveObjectTargets[Index].MoveSpeed);
		ActorRotation = Math::RInterpConstantTo(ActorRotation, TargetRot, DeltaSeconds, MoveObjectTargets[Index].RotationSpeed);

		float Size = (ActorLocation - TargetLoc).Size();

		if ((ActorLocation - TargetLoc).Size() <= 0.25 /* && ActorRotation.Vector().DotProduct(TargetRot.Vector()) >= 0.999 */)
		{
			Index++;

			if (Index > MoveObjectTargets.Num() - 1)
			{
				SetActorTickEnabled(false);
				OnBattlefieldObjectMoveFinished.Broadcast();
				return;
			}

			WaitTime = Time::GameTimeSeconds + MoveObjectTargets[Index].DelayMoveTime;
			OnBattlefieldObjectMoveToNext.Broadcast();
			OnBattlefieldObjectMoveFinished.Broadcast();
		}
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		ActivateMovingObject();
	}

	UFUNCTION()
	void ActivateMovingObject()
	{
		if (bActivateOnce)
		{
			if (bWasOneTimeActivated)
				return;
			else
				bWasOneTimeActivated = true;
		}

		Index = 0;
		WaitTime = Time::GameTimeSeconds + MoveObjectTargets[Index].DelayMoveTime;
		BP_EventTrigger();
		SetActorTickEnabled(true);
		OnBattlefieldObjectMoveStarted.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_EventTrigger() {}
}
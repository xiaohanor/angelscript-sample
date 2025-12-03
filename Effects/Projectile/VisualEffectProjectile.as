event void FVisualEffectProjectileActivated();
event void FVisualEffectProjectileReachedEnd();

class AVisualEffectProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	USceneComponent AttachChildrenComponent;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	float TriggerDelay = 0.0;

	UPROPERTY(EditAnywhere)
	float Speed = 5000.0;
	
	UPROPERTY(EditAnywhere)
	bool StartHidden = true;

	UPROPERTY()
	FVisualEffectProjectileActivated OnActivated;

	UPROPERTY()
	FVisualEffectProjectileReachedEnd OnReachedEnd;

	bool bActivated = false;
	bool bReachedEnd = false;

	float SplineDistance = 0;
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FVector Loc = SplineComp.GetWorldLocationAtSplineFraction(0);
		FRotator Rot = SplineComp.GetWorldRotationAtSplineFraction(0).Rotator();
		ProjectileRoot.SetWorldLocationAndRotation(Loc, Rot);
		AttachChildrenComponent = Cast<USceneComponent>(GetComponent(USceneComponent, n"AttachChildrenComp"));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileRoot.SetHiddenInGame(StartHidden, true);

		SplineDistance = SplineComp.SplineLength;
		ProjectileRoot.SetWorldLocationAndRotation(SplineComp.GetWorldLocationAtSplineFraction(1.0), SplineComp.GetWorldRotationAtSplineFraction(1.0));

		if (PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");

		if(AttachChildrenComponent != nullptr)
		{
			TArray<AActor> AttachedActors;
			GetAttachedActors(AttachedActors);
			for (int i = 0; i < AttachedActors.Num(); i++)
			{
				AActor Actor = Cast<AActor>(AttachedActors[i]);
				if(Actor != nullptr)
				{
					Actor.AttachToComponent(AttachChildrenComponent, NAME_None, EAttachmentRule::KeepWorld);
				}
			}
		}

	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		Activate();
	}

	UFUNCTION()
	void Activate()
	{
		if (bActivated)
			return;

		bActivated = true;

		if (TriggerDelay > 0)
			Timer::SetTimer(this, n"ActuallyActivate", TriggerDelay);
		else
			ActuallyActivate();

		OnActivated.Broadcast();
	}

	UFUNCTION()
	private void ActuallyActivate()
	{
		SetActorTickEnabled(true);
		ProjectileRoot.SetHiddenInGame(false, true);

		BP_Activated();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activated() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActivated)
			return;

		if (bReachedEnd)
			return;

		SplineDistance -= Speed * DeltaTime;
		FVector Loc = SplineComp.GetWorldLocationAtSplineDistance(SplineDistance);
		FRotator Rot = SplineComp.GetWorldRotationAtSplineDistance(SplineDistance).Rotator();

		ProjectileRoot.SetWorldLocationAndRotation(Loc, Rot);

		if (SplineDistance <= 0)
		{
			bReachedEnd = true;
			SetActorTickEnabled(false);
			OnReachedEnd.Broadcast();
			BP_ReachedEnd();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_ReachedEnd() {}
}
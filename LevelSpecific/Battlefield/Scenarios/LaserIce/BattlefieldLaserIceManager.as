class ABattlefieldLaserIceManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(EditAnywhere)
	ABattlefieldAttackFollowSpline AttackFollowSplineActor;

	UPROPERTY(EditAnywhere)
	TArray<AActor> IceActors;

	int Count = 0;
	UStaticMeshComponent CurrentMeshComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = AttackFollowSplineActor.GetAlphaAlongSplineProgress();

		UBattlefieldLaserIceEventHandler::Trigger_UpdateIceDestruction(this, FBattlefieldLaserIceData(Alpha, CurrentMeshComp));

		if (Alpha == 1)
		{
			SetActorTickEnabled(false);
			UBattlefieldLaserIceEventHandler::Trigger_StopIceDestruction(this, FBattlefieldLaserIceData(Alpha, CurrentMeshComp));

			if (Count < IceActors.Num() - 1)
				Count++;
		}
	}

	UFUNCTION()
	void SetIceStart()
	{
		SetActorTickEnabled(true);
		CurrentMeshComp = UStaticMeshComponent::Get(IceActors[Count]);
		UBattlefieldLaserIceEventHandler::Trigger_StartIceDestruction(this, FBattlefieldLaserIceData(0.0, CurrentMeshComp));
	}
};
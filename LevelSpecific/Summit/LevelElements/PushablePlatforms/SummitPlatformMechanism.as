class ASummitPlatformMechanism : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetEndLoc;
	UPROPERTY(DefaultComponent, Attach = TargetEndLoc)
	UBillboardComponent EndVisual;
	default EndVisual.SetWorldScale3D(FVector(3.0));

	UPROPERTY()
	FRotator StartRotation;

	UPROPERTY()
	FRotator TargetRotation = FRotator(90, 0 ,0);

	bool bGoingToEnd;

	UPROPERTY(EditAnywhere)
	ASummitHittableBell HittableBell;

	UPROPERTY(EditAnywhere)
	ASummitHittableBell WrongBell01;

	UPROPERTY(EditAnywhere)
	ASummitHittableBell WrongBell02;
	
	UPROPERTY(EditAnywhere)
	float ForwardSpeed = 1800.0;

	UPROPERTY(EditAnywhere)
	float ReverseSpeed = 100.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRotation = MeshRoot.RelativeRotation;
		if (HittableBell != nullptr)
		{
		HittableBell.TailAttackComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		WrongBell01.TailAttackComp.OnHitByRoll.AddUFunction(this, n"WrongBellOne");
		WrongBell02.TailAttackComp.OnHitByRoll.AddUFunction(this, n"WrongBellTwo");
		}
	}



	UFUNCTION()
	private void WrongBellOne(FRollParams Params)
	{
		BP_ResetPlatform();
	}

	UFUNCTION()
	private void WrongBellTwo(FRollParams Params)
	{
		BP_ResetPlatform();
	}
/*
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bGoingToEnd)
		{
			MeshRoot.RelativeRotation = Math::LerpShortestPath(StartRotation,TargetRotation)
			
			//MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, TargetEndLoc.RelativeLocation, DeltaTime, ForwardSpeed);

			if (Dist < 0.1)
				bGoingToEnd = false;
		}
		else
		{
			MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, StartRotation, DeltaTime, ReverseSpeed);
		}
	}
*/
	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		BP_MovePlatform();
	}

	UFUNCTION(BlueprintEvent)
	void BP_MovePlatform() {}

	UFUNCTION(BlueprintEvent)
	void BP_ResetPlatform() {}
}
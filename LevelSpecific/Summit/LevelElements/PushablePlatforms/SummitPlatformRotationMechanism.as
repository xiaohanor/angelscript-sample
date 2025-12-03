class ASummitPlatformRotationMechanism : AHazeActor
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
	USceneComponent TargetEndRotation;
	UPROPERTY(DefaultComponent, Attach = TargetEndRotation)
	UStaticMeshComponent RotVisualMeshComp;

	FRotator StartRotation;
	bool bGoingToEnd;

	UPROPERTY(EditAnywhere)
	ASummitTailHittablePlankActor HittablePlank;
	
	UPROPERTY(EditAnywhere)
	float ForwardSpeed = 1.7;

	UPROPERTY(EditAnywhere)
	float ReverseSpeed = 0.075;

	float DelayFallDuration = 0.25;
	float DelayFallTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRotation = MeshRoot.RelativeRotation;
		HittablePlank.TailResponse.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bGoingToEnd)
		{
			MeshRoot.RelativeRotation = Math::QInterpConstantTo
			(MeshRoot.RelativeRotation.Quaternion(), TargetEndRotation.RelativeRotation.Quaternion(), DeltaTime, ForwardSpeed).Rotator();

			float Dot = MeshRoot.ForwardVector.DotProduct(TargetEndRotation.ForwardVector);

			if (Dot > 0.99)
			{
				bGoingToEnd = false;
				DelayFallTime = Time::GameTimeSeconds + DelayFallDuration;
			}
		}
		else
		{
			if (Time::GameTimeSeconds < DelayFallTime)
				return;

			MeshRoot.RelativeRotation = Math::QInterpConstantTo
			(MeshRoot.RelativeRotation.Quaternion(), StartRotation.Quaternion(), DeltaTime, ReverseSpeed).Rotator();
		}
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		bGoingToEnd = true;
	}
}
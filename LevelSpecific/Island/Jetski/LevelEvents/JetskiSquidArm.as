event void FOnSquidSwingComplete();

class AJetskiSquidArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;
	
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh01;

	UPROPERTY(DefaultComponent, Attach = Mesh01)
	UStaticMeshComponent Mesh02;

	UPROPERTY(DefaultComponent, Attach = Mesh02)
	UStaticMeshComponent Mesh03;

	UPROPERTY(DefaultComponent, Attach = Mesh03)
	UStaticMeshComponent Mesh04;

	UPROPERTY()
	FOnSquidSwingComplete OnSquidSwingComplete;

	UPROPERTY(EditAnywhere)
	float ArmSwingDuration = 1.0;

	UPROPERTY(EditAnywhere)
	float RetractDuration = 1.0;

	UPROPERTY(EditAnywhere)
	float RetractLength = 14000.0;

	UPROPERTY(EditAnywhere)
	bool bShouldRetractArmAfterSwing = false;

	UPROPERTY(EditAnywhere)
	float DelayBeforeRetraction = 1.0;

	UPROPERTY(EditAnywhere)
	bool bShouldBeHiddenBeforeSwing = false;

	UPROPERTY(EditAnywhere)
	bool bShouldBeHiddenAfterSwing = false;

	float InterpSpeed = 12.0;

	FQuat Mesh02RotLastTick;
	FQuat Mesh03RotLastTick;
	FQuat Mesh04RotLastTick;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh02RotLastTick = Mesh02.WorldRotation.Quaternion();
		Mesh03RotLastTick = Mesh03.WorldRotation.Quaternion();
		Mesh04RotLastTick = Mesh04.WorldRotation.Quaternion();

		if(bShouldBeHiddenBeforeSwing)
			SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Mesh02.SetWorldRotation(Math::QInterpTo(Mesh02RotLastTick, Mesh01.WorldRotation.Quaternion(), DeltaSeconds, InterpSpeed));
		Mesh03.SetWorldRotation(Math::QInterpTo(Mesh03RotLastTick, Mesh02.WorldRotation.Quaternion(), DeltaSeconds, InterpSpeed));
		Mesh04.SetWorldRotation(Math::QInterpTo(Mesh04RotLastTick, Mesh03.WorldRotation.Quaternion(), DeltaSeconds, InterpSpeed));

		Mesh02RotLastTick = Mesh02.WorldRotation.Quaternion();
		Mesh03RotLastTick = Mesh03.WorldRotation.Quaternion();
		Mesh04RotLastTick = Mesh04.WorldRotation.Quaternion();
	}

	UFUNCTION(BlueprintCallable)
	void StartMovingArm()
	{
		if(bShouldBeHiddenBeforeSwing)
			SetActorHiddenInGame(false);
		
		OnArmsStartedMoving();
	}

	UFUNCTION(BlueprintEvent)
	void OnArmsStartedMoving(){}
}
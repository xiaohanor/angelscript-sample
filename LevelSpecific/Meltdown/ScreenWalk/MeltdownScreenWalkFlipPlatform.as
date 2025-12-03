class AMeltdownScreenWalkFlipPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Rotate)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent Rotate;	

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent Platform;
	
	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformImpact;

	UPROPERTY(DefaultComponent)
	USceneComponent PlatformTargetRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformTargetRoot)
	UStaticMeshComponent PlatformTarget;

	FRotator StartRot;
	FRotator TargetRot;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect SlamFF;

	bool bForceLeft;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike RotatePlatform;
	default RotatePlatform.Duration = 0.5;
	default RotatePlatform.UseLinearCurveZeroToOne();

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRot = PlatformRoot.RelativeRotation;

		TargetRot = PlatformTargetRoot.RelativeRotation;

		RotatePlatform.BindUpdate(this, n"OnUpdate");

		RotatePlatform.BindFinished(this, n"OnFinished");
		
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		PlatformRoot.SetRelativeRotation(Math::LerpShortestPath(StartRot, TargetRot, CurrentValue));
	}

	UFUNCTION()
	private void OnFinished()
	{
		Finished();
	}

	UFUNCTION(BlueprintEvent)
	void Finished()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bForceLeft)
			Rotate.ApplyForce(GetActorLocation() + ActorRightVector * 500, ActorForwardVector * 1900);
		else
			Rotate.ApplyForce(GetActorLocation() + ActorRightVector * 500, ActorForwardVector * -1900);
	}

	UFUNCTION(BlueprintCallable)
	void GoLeft()
	{
		bForceLeft = true;
		Rotate.ApplyImpulse(GetActorLocation() + ActorRightVector * 500, ActorForwardVector * 1500);
	//	RotatePlatform.Play();
		Impact();
	}


	UFUNCTION(BlueprintCallable)
	void GoRight()
	{
		bForceLeft = false;
		Rotate.ApplyImpulse(GetActorLocation() + ActorRightVector * 500, ActorForwardVector * -1500);
	//	RotatePlatform.Reverse();
		Impact();

	}

	UFUNCTION()
	void Impact()
	{
		UMeltdownScreenWalkFlipPlatformEventHandler::Trigger_Impact(this, FMeltdownFlipPlatformImpactLocation(PlatformImpact));
		Game::Mio.PlayForceFeedback(SlamFF, false, false, this);
	}
};
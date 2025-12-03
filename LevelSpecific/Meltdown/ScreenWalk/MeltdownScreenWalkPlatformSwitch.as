class AMeltdownScreenWalkPlatformSwitch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent Platform;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformTarget;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.SpringStrength = 10.0;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	FVector StartLocation;
	FVector EndLocation;

	UPROPERTY(EditAnywhere)
	FVector Impulse;

	UPROPERTY()
	FHazeTimeLike PlatformLike;
	default PlatformLike.Duration = 2.0;
	default PlatformLike.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = Platform.RelativeLocation;
		EndLocation = PlatformTarget.RelativeLocation;

		PlatformLike.BindUpdate(this, n"OnUpdate");

		ResponseComp.OnJumpTrigger.AddUFunction(this, n"OnActivated");
	}

	UFUNCTION()
	private void OnActivated()
	{
		PlatformLike.Play();
		OnJumped();
		TranslateComp.ApplyImpulse(
		ActorLocation, FVector(Impulse)
		);
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Platform.SetRelativeLocation(Math::Lerp(StartLocation, EndLocation, CurrentValue));
	}

	UFUNCTION(BlueprintEvent)
	void OnJumped()
	{

	}
};
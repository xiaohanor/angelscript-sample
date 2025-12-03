class AMeltdownScreenWalkAlternatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent Platform;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformTarget;

	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkButtonActor Button;

	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	FVector EndLocation;

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

		Button.JumpedOn.AddUFunction(this, n"ButtonHit");

	}

	UFUNCTION()
	private void ButtonHit()
	{
		SendButton();
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Platform.SetRelativeLocation(Math::Lerp(StartLocation, EndLocation, CurrentValue));
	}

	UFUNCTION(BlueprintEvent)
	void SendButton()
	{

	}

	UFUNCTION()
	void MovePlatform()
	{
		PlatformLike.Play();
		PlatformLike.PlayRate = 1.0;
	}

	UFUNCTION()
	void RecedePlatform()
	{
		PlatformLike.Reverse();
		PlatformLike.PlayRate = 0.25;
	}
};
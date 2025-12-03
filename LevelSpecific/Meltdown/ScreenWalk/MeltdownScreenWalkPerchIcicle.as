class AMeltdownScreenWalkPerchIcicle : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Icicle;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent IcicleTarget;
	default IcicleTarget.bHiddenInGame = true;
	default IcicleTarget.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	FVector IcicleStart;
	FVector IcicleEnd;

	FHazeTimeLike MoveIcicle;
	default MoveIcicle.Duration = 1.0;
	default MoveIcicle.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		IcicleStart = Icicle.RelativeLocation;
		IcicleEnd = IcicleTarget.RelativeLocation;

		MoveIcicle.BindUpdate(this, n"OnUpdate");

		MoveIcicle.BindFinished(this, n"OnFinished");
	}


	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Icicle.SetRelativeLocation(Math::Lerp(IcicleStart,IcicleEnd, CurrentValue));
	}

	UFUNCTION()
	private void OnFinished()
	{
		OnLanded();
	}

	UFUNCTION(BlueprintEvent)
	void OnLanded()
	{
	}

	UFUNCTION(BlueprintCallable)
	void PlayIcicle()
	{
		MoveIcicle.PlayFromStart();
	}
};
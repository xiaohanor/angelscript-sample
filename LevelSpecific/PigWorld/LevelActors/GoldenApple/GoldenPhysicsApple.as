event void FGoldenPhysicsAppleSwallowedEvent();

UCLASS(Abstract)
class AGoldenPhysicsApple : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent AppleRoot;

	UPROPERTY(DefaultComponent, Attach = AppleRoot)
	UStaticMeshComponent AppleMesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SwallowTimeLike;

	UPROPERTY()
	FGoldenPhysicsAppleSwallowedEvent OnSwallowed;

	FVector StartLoc;
	FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwallowTimeLike.BindUpdate(this, n"UpdateSwallow");
		SwallowTimeLike.BindFinished(this, n"FinishSwallow");
	}

	void GetSwallowed(FVector Target)
	{
		StartLoc = AppleRoot.WorldLocation;
		TargetLoc = Target;

		AppleRoot.SetSimulatePhysics(false);
		SetActorEnableCollision(false);

		SwallowTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateSwallow(float CurValue)
	{
		FVector Loc = Math::Lerp(StartLoc, TargetLoc, CurValue);
		AppleRoot.SetWorldLocation(Loc);
	}

	UFUNCTION()
	private void FinishSwallow()
	{
		OnSwallowed.Broadcast();
		AddActorDisable(this);
	}
}
event void FOnPlayerTeleport();

class AMeltdownBossPhaseThreeWorldGrenade : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Worldmesh;
	default Worldmesh.SetHiddenInGame(true);


	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UHazeSplineComponent SplineComp;

	float CurrentSplineDistance;

	float GrenadeStartLocation;

	FVector StartScale;
	UPROPERTY()
	FVector EndScale;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike GrenadeAnim;
	default GrenadeAnim.Duration = 2.0;
	default GrenadeAnim.UseLinearCurveZeroToOne(); 

	UPROPERTY(EditAnywhere)
	FHazeTimeLike OpenPortal;
	default OpenPortal.Duration = 2.0;
	default OpenPortal.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FOnPlayerTeleport PlayerTeleport;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrenadeAnim.BindFinished(this, n"OnFinishedGrenade");
		GrenadeAnim.BindUpdate(this, n"OnUpdateGrenade");

		OpenPortal.BindUpdate(this, n"PortalUpdate");

		StartScale = Worldmesh.RelativeScale3D;

		SplineComp = Spline.Spline;
	}

	UFUNCTION()
	private void PortalUpdate(float CurrentValue)
	{
		Worldmesh.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION(BlueprintCallable)
	void StartGrenade()
	{
		GrenadeAnim.Play();
		Worldmesh.SetHiddenInGame(false);
	}

	UFUNCTION()
	private void OnUpdateGrenade(float CurrentValue)
	{
		CurrentSplineDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(Math::Lerp(GrenadeStartLocation,SplineComp.SplineLength, CurrentValue));

	}

	UFUNCTION()
	private void OnFinishedGrenade()
	{
		OpenPortal.Play();
		Timer::SetTimer(this, n"Teleport", 0.5);
	}

	UFUNCTION()
	private void Teleport()
	{
		PlayerTeleport.Broadcast();
	}
};
class ASummitBreakingGap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DistanceLocationCheck;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent Explosion;
	default Explosion.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitBreakingGapCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent CrumbLocation;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator EventActivator;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor MioSplineFollowCamera;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor ZoeSplineFollowCamera;

	UPROPERTY(EditAnywhere)
	bool bDebug = false;

	FVector OffsetTarget;

	float RightOffset;

	bool bIsActive;

	// UPROPERTY(EditAnywhere)
	float TotalDistance;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugLine(DistanceLocationCheck.WorldLocation, DistanceLocationCheck.WorldLocation + ActorForwardVector * TotalDistance, FLinearColor::DPink, 100, 0, true);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RightOffset = MeshRoot.RelativeLocation.Y;
		EventActivator.OnSerpentEventTriggered.AddUFunction(this, n"OnSerpentEventTriggered");
		OffsetTarget = MeshRoot.RelativeLocation;
		
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnSerpentEventTriggered()
	{
		FVector AverageLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		FVector Delta = AverageLocation - DistanceLocationCheck.WorldLocation;
		TotalDistance = ActorForwardVector.DotProduct(Delta);
		Explosion.Activate();
		bIsActive = true;
		USummitBreakingGapEventHandler::Trigger_StartGapBreaking(this, FSummitBreakingGapParams(ActorLocation));
	}
};
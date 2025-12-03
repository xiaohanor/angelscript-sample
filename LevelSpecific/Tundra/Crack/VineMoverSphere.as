class AVineMoverSphere : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraPlayerSnowMonkeyCeilingClimbExclusiveComponent CeilingExclusiveComp;
	default CeilingExclusiveComp.SphereRadius = Radius * SphereRadiusMultiplier;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditInstanceOnly)
	TArray<AStaticMeshActor> Vines;

	UPROPERTY(EditInstanceOnly)
	APropLine CeilingSpline;

	UPROPERTY(EditAnywhere)
	float Radius = 1800.0;

	UHazeSplineComponent Spline;
	UTundraPlayerSnowMonkeyCeilingClimbComponent ClimbComp;

	const float SphereRadiusMultiplier = 0.85;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		CeilingExclusiveComp.SphereRadius = Radius * SphereRadiusMultiplier;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = Spline::GetGameplaySpline(CeilingSpline);
		ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(CeilingSpline);
		ClimbComp.OnAttach.AddUFunction(this, n"OnStartClimbing");
		ClimbComp.OnDeatch.AddUFunction(this, n"OnStopClimbing");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Vine : Vines)
		{
			UStaticMeshComponent MeshComp = Vine.StaticMeshComponent;
			MeshComp.SetVectorParameterValueOnMaterials(n"VineMoverCubeLocation", ActorLocation);
			MeshComp.SetScalarParameterValueOnMaterials(n"VineMoverCubeRadius", Radius);
		}
	}

	UFUNCTION()
	private void OnStartClimbing()
	{
		Game::Mio.LockPlayerMovementToSplineComponent(Spline, this);
	}

	UFUNCTION()
	private void OnStopClimbing()
	{
		Game::Mio.UnlockPlayerMovementFromSpline(this);
	}
}
class ASkylineSentryBladeDrone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BladeGrappleSurface;

	UPROPERTY(DefaultComponent, Attach = BladeGrappleSurface)
	UGravityBladeGrappleComponent BladeGrappleComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeGravityShiftComponent GravityShiftComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeGrappleResponseComponent BladeResponseComp;

	UPROPERTY()
	UNiagaraSystem ExplosionNiagara;

	bool bBladePull;
	float SelfDestructTime = 5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BladeResponseComp.OnPullEnd.AddUFunction(this, n"OnPullEnd");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bBladePull)
			return;

		if(SelfDestructTime > Time::GameTimeSeconds)
			return;

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionNiagara, ActorLocation, ActorRotation);
		DestroyActor();
	}

	UFUNCTION()
	private void OnPullEnd(UGravityBladeGrappleUserComponent GrappleComp)
	{
		SelfDestructTime += Time::GameTimeSeconds;
		bBladePull = true;
	}

	
}
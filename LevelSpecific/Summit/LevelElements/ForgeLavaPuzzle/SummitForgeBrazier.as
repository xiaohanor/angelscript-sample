class ASummitForgeBrazier : AHazeActor

{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponse; 

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsConeRotateComponent FauxCone;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent MyFireEffect;

	UPROPERTY(DefaultComponent, Attach = FauxCone)
	UBillboardComponent FireFX;	
	
	/*
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponse.OnAcidHit.AddUFunction(this, n"OnHitByAcid");
	}

	UFUNCTION()
	private void OnHitByAcid(FAcidHit Hit)
	{
		Niagara::SpawnLoopingNiagaraSystemAttached(UNiagaraSystem MyFireEffect , FireFX); 
	}
	*/
}
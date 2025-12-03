class ALightningConductor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LightningLoopComp;
	default LightningLoopComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"LightningConductorCapability");

	UPROPERTY()
	float BeamWidth = 2.5;

	UPROPERTY()
	float JitterWidth = 2.5;

	bool bIsLightningStarter;
	ALightningConductor OtherConductor;
	FVector EndLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bIsLightningStarter)
			return;

		FStormSiegeLightningLoopParams Params;
		Params.StartPoint = LightningLoopComp.WorldLocation;
		Params.EndPoint = OtherConductor.LightningLoopComp.WorldLocation;
		UStormSiegeLightningEffectsHandler::Trigger_StartLightningLoop(this, Params);
		LightningLoopComp.Activate();
		LightningLoopComp.SetNiagaraVariableFloat("BeamWidth", 3.0);
		LightningLoopComp.SetNiagaraVariableFloat("JitterWidth", 5.5);

		SetActorTickEnabled(false);
	}
}
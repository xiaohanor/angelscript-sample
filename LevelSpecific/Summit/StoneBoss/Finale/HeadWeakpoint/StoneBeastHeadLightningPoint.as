class AStoneBeastHeadLightningPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.SetWorldScale3D(FVector(3.5));
	default BillboardComp.SpriteName = "SkullAndBones";
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LightningComp;
	default LightningComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalComponent DecalComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DecalComp.SetHiddenInGame(true);
		//Set start and end params
		//LightningStrikeComp
	}

	void ActivateLightning()
	{
		DecalComp.SetHiddenInGame(false);
		Timer::SetTimer(this, n"FireLightningStrike", 1.0, false);
	}

	UFUNCTION()
	void FireLightningStrike()
	{
		FStormSiegeLightningStrikeParams Params;
		Params.Start = LightningComp.WorldLocation;
		Params.End = ActorLocation;
		Params.BeamWidth = 1.5;
		Params.NoiseStrength = 2.0;
		Params.AttachComp = LightningComp;
		UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(this, Params);

		Print(f"{Params.End=}");

		DecalComp.SetHiddenInGame(true);
		// LightningComp.SetFloatParameter(n"BeamWidth",  1.5);
		// LightningComp.SetFloatParameter(n"JitterWidth", 2);
		// LightningComp.SetNiagaraVariableVec3("Start", LightningComp.WorldLocation);
		// LightningComp.SetNiagaraVariableVec3("End", ActorLocation);
		// LightningComp.Activate();

		Debug::DrawDebugLine(LightningComp.WorldLocation, ActorLocation, FLinearColor::Teal, 15.0, 1.0, false);
	}
};
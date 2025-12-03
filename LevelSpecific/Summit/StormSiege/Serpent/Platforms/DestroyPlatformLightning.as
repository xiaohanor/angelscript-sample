class ADestroyPlatformLightning : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	AActor Start;
	UPROPERTY(EditAnywhere)
	AActor End;
	UPROPERTY(EditAnywhere)
	float Width = 3.0;

	UPROPERTY()
	UNiagaraSystem LightningImpact;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void FireLightning()
	{
		FStormSiegeLightningStrikeParams Params;
		Params.Start = Start.ActorLocation;
		Params.End = End.ActorLocation;
		Params.BeamWidth = Width;
		UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(this, Params);

		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayCameraShake(CameraShake, this);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(LightningImpact, ActorLocation, WorldScale = FVector(0.5));
	}
};
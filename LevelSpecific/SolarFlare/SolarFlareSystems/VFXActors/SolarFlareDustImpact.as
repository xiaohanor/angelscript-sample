class ASolarFlareDustImpact : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(3.0));
#endif

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = Root)
	UNiagaraComponent ImpactEffect;
	default ImpactEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent ReactionComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ReactionComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		ImpactEffect.Activate();
	}
}
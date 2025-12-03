class AJetskiBreakingWindow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SplashFX;
	default SplashFX.RelativeLocation = FVector(500, -10, 700);
	default SplashFX.RelativeRotation = FRotator(0, -90, 0);
	default SplashFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FlowFX;
	default FlowFX.RelativeLocation = FVector(490, -100, 680);
	default FlowFX.RelativeRotation = FRotator(0, -90, 0);
	default FlowFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CamShake;

	UFUNCTION()
	void BreakWindow()
	{
		SplashFX.Activate();
		FlowFX.Activate();		
	}

	UFUNCTION()
	void DeactivateEffects()
	{
		SplashFX.DeactivateImmediate();
		FlowFX.DeactivateImmediately();
	}
}
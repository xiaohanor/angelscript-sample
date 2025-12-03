event void FSplitTraversalCableCutSignature();

class ASplitTraversalCutableCable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FantasyRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SciFiRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent FantasyExplosionRoot;

	UPROPERTY(DefaultComponent, Attach = SciFiRoot)
	USceneComponent SciFiExplosionRoot;

	UPROPERTY()
	UNiagaraSystem CableExplosionSystem;

	UPROPERTY()
	UNiagaraSystem RootExplosionSystem;

	UPROPERTY()
	FSplitTraversalCableCutSignature OnCableCut;

	bool bCableCut = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void CutCable()
	{
		bCableCut = true;

		Niagara::SpawnOneShotNiagaraSystemAtLocation(RootExplosionSystem, FantasyExplosionRoot.WorldLocation);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(CableExplosionSystem, FantasyExplosionRoot.WorldLocation + FVector::ForwardVector * 500000.0);

		FantasyExplosionRoot.SetHiddenInGame(true, true);
		SciFiExplosionRoot.SetHiddenInGame(true, true);

		OnCableCut.Broadcast();
	}
};
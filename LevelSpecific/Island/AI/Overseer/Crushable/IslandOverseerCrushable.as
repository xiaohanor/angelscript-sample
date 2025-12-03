class AIslandOverseerCrushable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem CrushedFx;

	UPROPERTY(Category = Audio)
	FSoundDefReference CrushSoundDef;

	UPROPERTY(DefaultComponent)
	USceneComponent FX_Loc;

	void Crush()
	{
		//FVector Origin;
		//FVector Extents;
		FVector SpawnLocation = FX_Loc.GetWorldLocation();
		FVector SpawnRotation = FX_Loc.GetForwardVector();
		//GetActorBounds(false, Origin, Extents, true);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(CrushedFx, SpawnLocation, FRotator::MakeFromX(SpawnRotation));
		AddActorDisable(this);

		if(CrushSoundDef.SoundDef.IsValid())
		{
			CrushSoundDef.SpawnSoundDefOneshot(this, ActorTransform);
		}
	}
}
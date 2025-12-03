class AIslandSidescrollerBossDoorResistEffect : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(5.0);
#endif

	UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagaraComp;
	default NiagaraComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
}
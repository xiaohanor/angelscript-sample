class ASolarFlareEffectActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	USolarFireStaticMesh Flame;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;
	default ListComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;
}
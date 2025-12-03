class ASolarFlareRotatingCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USolarFlareCoverOverlapComponent CoverOverlapComp;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;
}
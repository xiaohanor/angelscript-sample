class ASolarFlareBasicCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot, ShowOnActor)
	USolarFlarePlayerCoverComponent CoverPlayerComp;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent WaveReactComp;
}
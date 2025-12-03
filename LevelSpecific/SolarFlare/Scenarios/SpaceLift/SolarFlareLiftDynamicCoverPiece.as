//Maybe redundant - possibly delete later
class ASolarFlareLiftDynamicCoverPiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USolarFlareCoverOverlapComponent CoverComp;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;
}
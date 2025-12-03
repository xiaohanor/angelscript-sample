class AAISummitSmasherTelegraphDecal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTelegraphDecalComponent DecalComp;
};
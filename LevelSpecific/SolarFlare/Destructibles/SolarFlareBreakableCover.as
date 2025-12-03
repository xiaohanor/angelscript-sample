class ASolarFlareBreakableCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazePropComponent PropComp1;
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazePropComponent PropComp2;
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazePropComponent PropComp3;
}
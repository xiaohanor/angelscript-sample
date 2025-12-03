class ATundraBossSetupIceBreachActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase PreviewSkelMesh;
	default PreviewSkelMesh.bIsEditorOnly = true;
	default PreviewSkelMesh.bHiddenInGame = true;
}
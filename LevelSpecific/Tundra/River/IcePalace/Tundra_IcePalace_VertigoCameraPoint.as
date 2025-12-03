class ATundra_IcePalace_VertigoCameraPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Point;

	UPROPERTY(DefaultComponent, Attach = Point)
	UHazeSkeletalMeshComponentBase PreviewMesh;
	default PreviewMesh.bHiddenInGame = true;
	default PreviewMesh.bIsEditorOnly = true;

	UPROPERTY(EditInstanceOnly)
	int Index = 0;

	int opCmp(ATundra_IcePalace_VertigoCameraPoint Other) const
	{
		if(Game::Mio.GetDistanceTo(this) > Game::Mio.GetDistanceTo(Other))
			return 1;
		else
			return -1;
	}
};
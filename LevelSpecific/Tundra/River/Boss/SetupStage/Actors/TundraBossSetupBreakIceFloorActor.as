class ATundraBossSetupBreakIceFloorActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase PreviewMesh;
	default PreviewMesh.bIsEditorOnly = true;
	default PreviewMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditInstanceOnly)
	int IceBreakIteration = 0;

	default PrimaryActorTick.bStartWithTickEnabled = false;
	default ActorHiddenInGame = true;
}

namespace TundraBossSetupBreakIceFloorActor
{
	UFUNCTION()
	TArray<ATundraBossSetupBreakIceFloorActor> GetAllBreakIceFloorActors()
	{
		return TListedActors<ATundraBossSetupBreakIceFloorActor>().GetArray();
	}
};
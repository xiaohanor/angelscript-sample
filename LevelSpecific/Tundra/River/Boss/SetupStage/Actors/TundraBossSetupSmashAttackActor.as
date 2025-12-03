struct FTundraBossPhase01AttackEventData
{
	UPROPERTY()
	ETundraBossSetupAttackAnim AttackType;
}
class ATundraBossSetupSmashAttackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase PreviewSkelMesh;
	default PreviewSkelMesh.bIsEditorOnly = true;
	default PreviewSkelMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	default PrimaryActorTick.bStartWithTickEnabled = false;
	default ActorHiddenInGame = true;

	UPROPERTY(EditInstanceOnly)
	TArray<int> ValidBreakIceIterations;

	UPROPERTY(EditInstanceOnly)
	int PlatformIndex = 0;
};
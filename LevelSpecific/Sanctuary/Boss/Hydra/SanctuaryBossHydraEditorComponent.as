#if EDITOR
class USanctuaryBossHydraEditorComponent : UActorComponent
{
	default bIsEditorOnly = true;
	default bTickInEditor = true;
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_LastDemotable;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		auto Head = Cast<ASanctuaryBossHydraHead>(Owner);
		Head.UpdateMeshSpline();
		Head.SkeletalMesh.HazeForceUpdateAnimation(true);
	}
}
#endif
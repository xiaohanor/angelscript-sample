namespace ASkylineBossRocketBarrageCutsceneTargetActor
{
	ASkylineBossRocketBarrageCutsceneTargetActor Get()
	{
		return TListedActors<ASkylineBossRocketBarrageCutsceneTargetActor>().Single;
	}
}

UCLASS(NotBlueprintable)
class ASkylineBossRocketBarrageCutsceneTargetActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SetWorldScale3D(FVector(15));
#endif
};
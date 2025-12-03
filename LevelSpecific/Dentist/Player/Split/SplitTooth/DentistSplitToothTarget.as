UCLASS(NotBlueprintable)
class ADentistSplitToothTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PlayerTargetLocation;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = PlayerTargetLocation)
	UEditorBillboardComponent PlayerIcon;
	default PlayerIcon.SpriteName = "S_Player";
#endif

	UPROPERTY(DefaultComponent)
	USceneComponent AITargetLocation;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = AITargetLocation)
	UEditorBillboardComponent AIIcon;
	default PlayerIcon.SpriteName = "Ai_Spawnpoint";
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
};

namespace ADentistSplitToothTarget
{
	ADentistSplitToothTarget Get()
	{
		return TListedActors<ADentistSplitToothTarget>().Single;
	}
}
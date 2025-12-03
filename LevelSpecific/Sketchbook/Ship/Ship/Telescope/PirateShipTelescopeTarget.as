UCLASS(NotBlueprintable)
class APirateShipTelescopeTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
};

namespace Pirate
{
	APirateShipTelescopeTarget GetTelescopeTarget()
	{
		return TListedActors<APirateShipTelescopeTarget>().Single;
	}
}
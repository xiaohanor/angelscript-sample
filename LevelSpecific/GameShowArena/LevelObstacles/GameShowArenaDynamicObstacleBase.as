UCLASS(NotBlueprintable, NotPlaceable)
class AGameShowArenaDynamicObstacleBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditInstanceOnly, meta = (Bitmask, BitmaskEnum = "/Script/Angelscript.EBombTossChallenges"))
	int BombTossChallengeUses = 0;
};
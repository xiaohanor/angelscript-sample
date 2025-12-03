/**
 * Hack to allow animatable values without using the Jetski actor in sequences.
 * Sue me 😈
 */
UCLASS(NotBlueprintable)
class AJetskiSequenceSettingsActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere, Interp)
	bool bPlaceMioJetskiOnWater = false;

	UPROPERTY(EditAnywhere, Interp)
	bool bPlaceZoeJetskiOnWater = false;
};

namespace AJetskiSequenceSettingsActor
{
	AJetskiSequenceSettingsActor Get()
	{
		return TListedActors<AJetskiSequenceSettingsActor>().Single;
	}
};
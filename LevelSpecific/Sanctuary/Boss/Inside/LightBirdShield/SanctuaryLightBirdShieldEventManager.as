event void FSanctuaryLightBirdShieldEvent(AHazePlayerCharacter Player);

class ASanctuaryLightBirdShieldEventManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	FSanctuaryLightBirdShieldEvent OnPlayerEnterShield;

	UPROPERTY()
	FSanctuaryLightBirdShieldEvent OnPlayerLeaveShield;

	UPROPERTY()
	bool bBroadcastEvents = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
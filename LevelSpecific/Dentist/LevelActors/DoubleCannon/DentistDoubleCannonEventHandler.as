struct FDentistDoubleCannonOnFirstPlayerEnterSpringEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
};

struct FDentistDoubleCannonOnAllPlayersExitedSpringEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
};

struct FDentistDoubleCannonOnPlayerJumplandEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
};

struct FDentistDoubleCannonOnPlayerGroundPoundLandEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	FHitResult Impact;
};

/**
 * Events on the double cannon actor (not player)
 */
UCLASS(Abstract)
class UDentistDoubleCannonEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ADentistDoubleCannon Cannon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cannon = Cast<ADentistDoubleCannon>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFirstPlayerEnterSpring(FDentistDoubleCannonOnFirstPlayerEnterSpringEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAllPlayersExitedSpring(FDentistDoubleCannonOnAllPlayersExitedSpringEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerJumpLand(FDentistDoubleCannonOnPlayerJumplandEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerGroundPoundLand(FDentistDoubleCannonOnPlayerGroundPoundLandEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBothPlayerSuccess() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchPlayers() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayersDetached() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartResetting() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedResetting() {}
};
struct FCrackBirdPlayerStuckOnBecomeStuckInBirdEventData
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ABigCrackBird CrackBird;
};

struct FCrackBirdPlayerStuckOnExplodeBirdEventData
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ABigCrackBird CrackBird;
};

/**
 * Events for the player getting stuck in the CrackBird, and blowing it up from inside
 * Placed on the Player, not the bird.
 */
UCLASS(Abstract)
class UCrackBirdPlayerStuckEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBecomeStuckInBird(FCrackBirdPlayerStuckOnBecomeStuckInBirdEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplodeBird(FCrackBirdPlayerStuckOnExplodeBirdEventData EventData) {}
};
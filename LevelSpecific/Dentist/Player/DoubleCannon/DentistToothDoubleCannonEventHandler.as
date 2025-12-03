/**
 * Player events for being launched out of the two player cannon.
 */
UCLASS(Abstract)
class UDentistToothDoubleCannonEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	UDentistToothPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
	}

	/**
	 * Both players have entered and are now locked into the cannon
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterCannon() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched() {}

	/**
	 * Detaching means that the players let go of each others hands and start to divert 💔
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetached() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLanding() {}
};
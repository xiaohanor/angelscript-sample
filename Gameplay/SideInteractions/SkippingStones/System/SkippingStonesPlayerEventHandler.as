UCLASS(Abstract)
class USkippingStonesPlayerEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintProtected, NotEditable)
	AHazePlayerCharacter Player;

	private USkippingStonesPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USkippingStonesPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnter() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrow(FSkippingStoneOnThrowEventData EventData) {}

	/**
	 * When we get 5 or more bounces
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrowManyBounces() {}

	/**
	 * When we get 1-4 bounces
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrowFewBounces() {}

	/**
	 * When we get zero bounces
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrowPladask() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrowHitPlayer() {}

	UFUNCTION(BlueprintPure)
	ASkippingStones GetSkippingStones() const
	{
		return PlayerComp.SkippingStonesInteraction;
	}
};
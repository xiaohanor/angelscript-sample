struct FDentistSplitToothOnLungeEventData
{
	UPROPERTY()
	FVector Impulse;
};

struct FDentistSplitToothOnLandingEventData
{
	UPROPERTY()
	FHitResult Impact;
}

/**
 * Shared events on the player and AI while being split (tooth halves)
 */
UCLASS(Abstract)
class UDentistSplitToothEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	UDentistSplitToothComponent SplitToothComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothComp = UDentistSplitToothComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLunge(FDentistSplitToothOnLungeEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLanding(FDentistSplitToothOnLandingEventData EventData) {}
};
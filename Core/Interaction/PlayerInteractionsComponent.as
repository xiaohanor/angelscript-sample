
class UPlayerInteractionsComponent : UActorComponent
{
	access ExternalReadOnly = private, UInteractionEnterCapability, UInteractionExitCapability, UInteractionCancelCapability, * (readonly);

	// Widget class used for interactions that don't override it
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	TSubclassOf<UInteractionWidget> InteractionWidgetClass;
	// Default sheet used for interactions that don't specify a sheet
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Interaction")
	UHazeCapabilitySheet DefaultInteractionSheet;
	// Default sheet used for the player while they are waiting for interaction validation
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Interaction")
	UHazeCapabilitySheet DefaultValidationSheet;

	// The current interaction the player is in
	access:ExternalReadOnly
	UInteractionComponent ActiveInteraction;

	// Whether the player is near any interactions
	bool bIsNearInteraction = false;
	float DistanceToNearestInteraction = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void KickPlayerOutOfInteraction(UInteractionComponent Interaction)
	{
		if (!HasControl())
			return;
		if (ActiveInteraction == Interaction)
			ActiveInteraction = nullptr;
	}

	void KickPlayerOutOfAnyInteraction()
	{
		KickPlayerOutOfInteraction(ActiveInteraction);
	}
};
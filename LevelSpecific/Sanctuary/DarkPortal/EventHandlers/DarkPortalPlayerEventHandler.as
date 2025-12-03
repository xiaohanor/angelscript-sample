UCLASS(Abstract, Meta = (RequireActorType = "AHazePlayerCharacter"))
class UDarkPortalPlayerEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDarkPortalUserComponent UserComp;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	ADarkPortalActor DarkPortal;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserComp = UDarkPortalUserComponent::Get(Owner);
		DarkPortal = UserComp.Portal;
	}

	// Called when aiming is started.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AimingStarted() { }

	// Called when aiming is stopped.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AimingStopped() { }

	// Called when the portal's grabbing functionality is activated.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabActivated() { }

	// Called when the portal's grabbing functionality is deactivated.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabDeactivated() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DarkPortalAttach() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DarkPortalRecall() {}

}
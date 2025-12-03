struct FDarkPortalGrabEventData
{
	UPROPERTY()
	UDarkPortalTargetComponent TargetComp;

	FDarkPortalGrabEventData() {}

	FDarkPortalGrabEventData(UDarkPortalTargetComponent InTargetComponent)
	{
		TargetComp = InTargetComponent;
	}
}

struct FDarkPortalSettledEventData
{
	UPROPERTY()
	FTransform PortalTransform;
}

struct FDarkPortalRecallEventData
{
	UPROPERTY()
	FTransform PortalTransform;
}

UCLASS(Abstract)
class UDarkPortalEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	ADarkPortalActor DarkPortal;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDarkPortalUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DarkPortal = Cast<ADarkPortalActor>(Owner);
		if (DarkPortal == nullptr)
			DarkPortal = USanctuaryDarkPortalCompanionComponent::Get(Owner).Portal;
		Player = DarkPortal.Player;
		UserComp = UDarkPortalUserComponent::Get(Player);
	}

	// Called when the portal is absorbed/attached to the player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Absorbed() { }

	// Called when the portal is launched.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launched() { }

	// Called when the portal has reached a valid target after launching.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Settled(FDarkPortalSettledEventData Params) { }

	// Called when the portal has reached an invalid target after launching.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SettleFailed() { }

	// Called when the portal is recalled.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Recalled(FDarkPortalRecallEventData Params) { }

	// Called when the portal grabs a component.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Grabbed() { }

	// Called when the portal releases a component.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Released() { }

	// Called when the portal pushes targets away.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pushed() { }

	// Called when the portal explodes, caused by the light bird attaching to the portal.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Exploded() { }

	// Called when the portal's grabbing functionality is activated.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabActivated() { }

	// Called when the portal's grabbing functionality is deactivated.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabDeactivated() { }

	// Called when the portal starts grabbing a specific object, not triggered for subsequent grabs
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartGrabbingObject(FDarkPortalGrabEventData GrabData) { }

	// Called when the portal stops grabbing an object
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopGrabbingObject() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionLaunchAnticipationStarted() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionLaunchAnticipationStopped() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionLaunchStarted() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionLaunchStopped() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionReachPortal() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionLeavePortal() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionFailedToOpenPortal() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionRecallStarted() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionRecallStopped() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionRecallReturned() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompanionWatsonTeleport() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionIntroStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionIntroReachedPlayer() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionInvestigateStarted() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionInvestigateStopped() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionInvestigateAttachStarted() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionInvestigateAttachStopped() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionFollowSlidingDiscStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionFollowSlidingDiscStop() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionFollowCentipedeStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionFollowCentipedeStop() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerAimStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerAimStop() { }

	UFUNCTION(BlueprintPure)
	float GetSpawnDelay() const
	{
		return DarkPortal::Timings::SpawnDelay;
	}
}
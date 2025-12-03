UCLASS(Abstract)
class USpaceWalkZeroGEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintPure)
	ASpaceWalkHookActor GetHookActor() const
	{
		auto SpaceComp = USpaceWalkPlayerComponent::Get(Player);
		return SpaceComp.Hook;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	// Player started thrusting in a particular direction
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedThrusting()
	{
	}

	// Player stopped thrusting, might still be moving from the hook or from inertia
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedThrusting()
	{
	}

	// Player launched the grappling hook towards something
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHookLaunched()
	{
	}

	// Grappling hook hit a grapple point and attached to it
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHookAttached()
	{
	}

	// Grappling hook detached from its current grapple point and started retracting
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHookDetached()
	{
	}

	// Grappling hook has finished retracting and is now hidden
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHookFinishedRetracting()
	{
	}
};
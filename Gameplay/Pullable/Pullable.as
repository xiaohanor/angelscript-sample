
/**
 * Standard implementation of a pullable actor that one or both players can move along a spline.
 */
class APullable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UPullableComponent PullableComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent PullInteraction;
	default PullInteraction.MovementSettings = FMoveToParams::SmoothTeleport();
	default PullInteraction.InteractionSheet = Pullable::PullSheet;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"PullablePullBackCapability");

	// Called when the pullable reaches the end of the spline and bCompleteAtEndOfSpline is on
	UPROPERTY()
	FOnPullableCompleted OnPullableCompleted;

	// Called when a player starts pulling the pullable
	UPROPERTY()
	FOnPullableEvent OnStartedPulling;

	// Called when a player stops pulling the pullable
	UPROPERTY()
	FOnPullableEvent OnStoppedPulling;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PullableComponent.OnPullableCompleted.AddUFunction(this, n"TriggerCompletePullable");
		PullableComponent.OnStartedPulling.AddUFunction(this, n"TriggerStartedPulling");
		PullableComponent.OnStoppedPulling.AddUFunction(this, n"TriggerStoppedPulling");
	}

	UFUNCTION()
	private void TriggerCompletePullable(AHazePlayerCharacter Player)
	{
		OnPullableCompleted.Broadcast(Player);
	}

	UFUNCTION()
	private void TriggerStartedPulling(AHazePlayerCharacter Player)
	{
		OnStartedPulling.Broadcast(Player);
	}

	UFUNCTION()
	private void TriggerStoppedPulling(AHazePlayerCharacter Player)
	{
		OnStoppedPulling.Broadcast(Player);
	}

	UFUNCTION(BlueprintCallable, Category = "Pullable")
	void DisablePullable(FInstigator Instigator)
	{
		PullInteraction.Disable(Instigator);
		PullInteraction.KickAnyPlayerOutOfInteraction();
	}

	UFUNCTION(BlueprintCallable, Category = "Pullable")
	void EnablePullable(FInstigator Instigator)
	{
		PullInteraction.Enable(Instigator);
	}

	/**
	 * Get the current distance on the spline that we've pulled.
	 * 
	 * WARNING: Network sync of this value is unreliable, so if you trigger
	 * gameplay based on this, make sure to sync it yourself!
	 */
	UFUNCTION(BlueprintPure)
	float GetPulledDistanceOnSpline() const
	{
		return PullableComponent.GetPulledDistanceOnSpline();
	}
};
UCLASS(Abstract)
class ASwingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USwingPointComponent SwingPointComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USwingPointDrawComponent DrawComp;	
#endif

	UPROPERTY()
	FOnPlayerAttachedToSwingPointSignature OnPlayerAttachedToSwingPointEvent;

	UPROPERTY()
	FOnPlayerDetachedFromSwingPointSignature OnPlayerDetachedFromSwingPointEvent;

	UPROPERTY()
	FOnGrappleHookReachedSwingPointSignature OnGrappleHookReachedSwingPointEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"OnPlayerAttached");
		SwingPointComp.OnPlayerDetachedEvent.AddUFunction(this, n"OnPlayerDetached");
		SwingPointComp.OnGrappleHookReachedSwingPointEvent.AddUFunction(this, n"OnGrappleHookReachedPoint");
	}

	UFUNCTION(BlueprintEvent, Category = Events)
	void OnPlayerAttached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		OnPlayerAttachedToSwingPointEvent.Broadcast(Player, SwingPoint);
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerDetached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		OnPlayerDetachedFromSwingPointEvent.Broadcast(Player, SwingPoint);
	}
	
	UFUNCTION()
	private void OnGrappleHookReachedPoint(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		OnGrappleHookReachedSwingPointEvent.Broadcast(Player, SwingPoint);
	}
}


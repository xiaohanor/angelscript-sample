event void FSkylineAllySocketActivatedSignature();
event void FSkylineAllySocketDeactivatedSignature();

class ASkylineAllySocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityWhipTargetComponent WhipTargetComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;

	UPROPERTY()
	FSkylineAllySocketActivatedSignature OnActivated;

	UPROPERTY()
	FSkylineAllySocketDeactivatedSignature OnDeactivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleWhipGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"HandleWhipReleased");
	}

	UFUNCTION()
	private void HandleWhipGrabbed(UGravityWhipUserComponent UserComponent,
	                           UGravityWhipTargetComponent TargetComponent,
	                           TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		Activate();
	}

	UFUNCTION()
	private void HandleWhipReleased(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		Deactivate();
	}

	UFUNCTION()
	void Activate()
	{
		OnActivated.Broadcast();
		BPActivated();
	}

	UFUNCTION()
	void Deactivate()
	{
		OnDeactivated.Broadcast();
		BPDeactivated();
	}

	UFUNCTION(BlueprintEvent)
	private void BPActivated()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void BPDeactivated()
	{
	}
}
UCLASS(Abstract)
class USkylineAllyGravityPanelGateEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGateBeginOpen() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGateFinishOpen() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGateBeginClose() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGateFinishedClose() {}
}

event void FSkylineGravityPanelGateSignature();

class ASkylineAllyGravityPanelGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Gate1PivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Gate2PivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathTriggerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CheckPointTriggerComp;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditInstanceOnly)
	ASkylineGravityPanel GravityPanel;

	UPROPERTY()
	FHazeTimeLike GateTimeLike;
	default GateTimeLike.UseLinearCurveZeroToOne();
	default GateTimeLike.Duration = 0.1;

	UPROPERTY()
	FSkylineGravityPanelGateSignature OnReachedSafety;

	UPROPERTY()
	FSkylineGravityPanelGateSignature OnPoweredOn;
	UPROPERTY()
	FSkylineGravityPanelGateSignature OnPoweredOff;

	bool bClosed;

	bool bPulling = false;

	bool bActivated = false;

	bool bCorrectGravity = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");
		GateTimeLike.BindUpdate(this, n"GateTimeLikeUpdate");
		GateTimeLike.BindFinished(this, n"GateTimeLikeFinished");
		GravityPanel.GravityBladeGrappleResponseComponent.OnPullStart.AddUFunction(this, n"HandlePullStart");
		GravityPanel.GravityBladeGrappleResponseComponent.OnPullEnd.AddUFunction(this, n"HandlePullEnd");
		CheckPointTriggerComp.OnComponentEndOverlap.AddUFunction(this, n"HandleCheckPointEndOverlap");
	}

	UFUNCTION()
	private void HandleCheckPointEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (bCorrectGravity)
			OnReachedSafety.Broadcast();
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		bActivated = true;
		OnPoweredOn.Broadcast();
		OpenGate();
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		bActivated = false;
		OnPoweredOff.Broadcast();
		
		if (bPulling)
			return;
		
		
		CloseGate();
	}

	

	UFUNCTION()
	private void HandlePullStart(UGravityBladeGrappleUserComponent GrappleComp)
	{
		bPulling = true;
	}

	UFUNCTION()
	private void HandlePullEnd(UGravityBladeGrappleUserComponent GrappleComp)
	{
		bPulling = false;

		if (!bActivated)
			CloseGate();
		else
			bCorrectGravity = true;
	}

	UFUNCTION()
	private void OpenGate()
	{
		BPActivated();
		bClosed = false;
		GateTimeLike.Play();
		
		USkylineAllyGravityPanelGateEventHandler::Trigger_OnGateBeginOpen(this);
	}

	UFUNCTION()
	private void CloseGate()
	{
		BPDeactivated();
		GateTimeLike.Reverse();
		
		USkylineAllyGravityPanelGateEventHandler::Trigger_OnGateBeginClose(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BPActivated(){}

	UFUNCTION(BlueprintEvent)
	private void BPDeactivated(){}

	UFUNCTION()
	private void GateTimeLikeFinished()
	{
		if (GateTimeLike.IsReversed())
		{
			bClosed = true;

			if (DeathTriggerComp.IsOverlappingActor(Game::Mio))
			{
				Game::Mio.KillPlayer();
				bCorrectGravity = false;
			}

			USkylineAllyGravityPanelGateEventHandler::Trigger_OnGateFinishedClose(this);
		}

		else
			USkylineAllyGravityPanelGateEventHandler::Trigger_OnGateFinishOpen(this);
	}

	UFUNCTION()
	private void GateTimeLikeUpdate(float CurrentValue)
	{
		FVector NewScale = FVector(4.0, 0.1, 2.0 - (1.9 * CurrentValue));
		FVector Location = FVector::ForwardVector * 200.0 * CurrentValue;
		//FRotator NewRotation = FRotator(0.0, Math::Lerp(0.0, 90.0, CurrentValue), 0.0);


		Gate1PivotComp.SetRelativeLocation(Location);
		Gate2PivotComp.SetRelativeLocation(-Location);
	}
}
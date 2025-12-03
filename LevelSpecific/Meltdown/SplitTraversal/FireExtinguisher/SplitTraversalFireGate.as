event void FSplitTraversalFireGateOpened();

UCLASS(Abstract)
class USplitTraversalFireGateEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireDistinguished() {}
}

class ASplitTraversalFireGate : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UFauxPhysicsTranslateComponent DoorTranslateComp;

	UPROPERTY(DefaultComponent, Attach = DoorTranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UNiagaraComponent FireVFXComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USpotLightComponent FireLightComp;
	float FireLightIntensity;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USpotLightComponent FireLightComp2;

	UPROPERTY(DefaultComponent, Attach = FireVFXComp)
	UDeathTriggerComponent DeathTriggerComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	float TargetRadius = 500.0;

	UPROPERTY(EditAnywhere)
	float MaxForce = 3000.0;

	UPROPERTY(EditAnywhere)
	int RequiredHits = 3;
	int Hits = 0;

	UPROPERTY()
	FSplitTraversalFireGateOpened OnGateOpened;

	bool bOpen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		FireLightIntensity = FireLightComp.Intensity;
	}

	UFUNCTION(CrumbFunction)
	void CrumbWatered()
	{
		if (bOpen)
			return;

		Hits++;

		float Progress = float(Hits) / RequiredHits;

		ForceComp.Force = FVector::UpVector * -MaxForce * Progress;

		PrintToScreen("Triggered" + ForceComp.Force, 2.0);

		if (Hits >= RequiredHits)
			Open();

		QueueComp.Duration(0.2, this, n"DecreaseFireUpdate");
	}

	UFUNCTION()
	private void DecreaseFireUpdate(float Alpha)
	{
		FireLightComp.SetIntensity(Math::Lerp(FireLightIntensity, 0.0, Alpha));
		FireLightComp2.SetIntensity(Math::Lerp(FireLightIntensity, 0.0, Alpha));
	}

	private void Open()
	{
		bOpen = true;
		DoorTranslateComp.SpringStrength = 0.0;
		//FireVFXComp.Deactivate();
		DeathTriggerComp.DisableTrigger(this);
		OnGateOpened.Broadcast();

		USplitTraversalFireGateEventHandler::Trigger_OnFireDistinguished(this);

		BP_FireExtinguished();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_FireExtinguished(){}
};
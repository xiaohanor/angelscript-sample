event void FOnPulseArrived();
class ASkylineInnerCityCableSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	AHazeActor ActorWithSpline;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditInstanceOnly)
	AHazeActor DisabledSpline;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SparkVFXComp;

	UPROPERTY(DefaultComponent)
	USceneComponent EffectLocation;

	UPROPERTY()
	UNiagaraSystem SparkEffect;
	
	UPROPERTY()
	FOnPulseArrived OnPulseArrived;

	UPROPERTY(EditAnywhere)
	float PulseSpeed = 500.0;

	UPROPERTY()
	float ActivationDuration = 1.0;

	float ProgressAlongCable = 0.0;

	float LockCounter;

	bool bDoOnce = true;

	UPROPERTY(EditAnywhere)
	float MaxLocks;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisabledSpline.AddActorDisable(this);
		LockCounter = 0.0;
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		SetActorTickEnabled(false);
		SplineComp = UHazeSplineComponent::Get(ActorWithSpline);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		SparkVFXComp.SetHiddenInGame(false);
		SparkVFXComp.Activate();
		ProgressAlongCable = 0.0;	
		SetActorTickEnabled(true);	
				
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		ProgressAlongCable += DeltaSeconds * PulseSpeed;

		if (ProgressAlongCable >= SplineComp.SplineLength)
		{
			OnPulseArrive();
			return;
		}

		FVector NewPulseWorldLocation = SplineComp.GetWorldLocationAtSplineDistance(ProgressAlongCable);

		SparkVFXComp.SetWorldLocation(NewPulseWorldLocation);

		PrintToScreen("PulseLocation" + NewPulseWorldLocation);
	}

	void OnPulseArrive()
	{
		
		if(bDoOnce)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkEffect, EffectLocation.GetWorldLocation());
			OnPulseArrived.Broadcast();
			SparkVFXComp.Deactivate();
			SparkVFXComp.SetHiddenInGame(true);
			SetActorTickEnabled(false);
			BPActivated();
			InterfaceComp.TriggerActivate();
			bDoOnce=false;
			ActorWithSpline.AddActorDisable(this);
			DisabledSpline.RemoveActorDisable(this);
		}
	
	}

	UFUNCTION(BlueprintEvent)
	void BPDeActivated()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BPActivated()
	{
	}
};
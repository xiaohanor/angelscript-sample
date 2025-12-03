event void FOnAcidActivatorStarted(AAcidActivator Activator);
event void FOnAcidActivatorStopped(AAcidActivator Activator);

struct FAcidActivatorSettings
{
	UPROPERTY(EditAnywhere)
	float DecayRate = 0.2;

	UPROPERTY(EditAnywhere)
	float IncreaseRate = 0.5;

	UPROPERTY(EditAnywhere)
	float TurnOffBuffer = 0.7;
}

class AAcidActivator : AHazeActor
{
	UPROPERTY()
	FOnAcidActivatorStarted OnAcidActivatorStarted;
	UPROPERTY()
	FOnAcidActivatorStopped OnAcidActivatorStopped;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AcidCollision;
	default AcidCollision.SetHiddenInGame(true);
	
	UPROPERTY(DefaultComponent, Attach = AcidCollision)
	UAcidResponseComponent AcidResponseComp;
	default AcidResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = AcidCollision)
	UTeenDragonAcidAutoAimComponent AutoAim;
	default AutoAim.AutoAimMaxAngle = 20.0;
	default AutoAim.MaximumDistance = 5000.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"AcidFillCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AcidActivatedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AcidActivatorMaterialCapability");

	UPROPERTY(EditAnywhere)
	FAcidActivatorSettings Settings;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "!bWaitForActionCompleted", EditConditionHides))
	float ActivateDuration = 3.0;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsAlternating", EditConditionHides))
	float ActivationBuffer = 1.0;

	UPROPERTY(EditAnywhere)
	bool bIsReactivatable = false;

	float ReactivatableTimer;

	//Does the activator actor want/need a curve for the fill behaviour?
	UPROPERTY(EditAnywhere)
	ASummitAcidActivatorActor ActivatorActor;

	UPROPERTY(EditAnywhere)
	float AutoAimDistance = 5000.0;

	UPROPERTY(EditInstanceOnly)
	bool bWaitForActionCompleted = false;

	FHazeAcceleratedFloat AcidAlpha;

	float TimeStampDeactivation;
	float TimeSinceLastHit;
	float TimeSinceHitBuffer = 0.15;

	bool bIsActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		ActivatorActor.SetActivator(this);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (bIsActive)
		{
			if(bIsReactivatable)
			{
				TimeSinceLastHit -= Hit.Damage * 2.0;
				TimeSinceLastHit = Math::Clamp(TimeSinceLastHit, 0.0, ActivateDuration);
			}

			return;
		}
		
		TimeSinceLastHit = 0.0;
	}

	// Needs to be crumbed because it't called from tick in a capability
	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbStartActivator()
	{
		if (Time::GameTimeSeconds < TimeStampDeactivation + Settings.TurnOffBuffer && !bIsReactivatable)
			return;

		bIsActive = true;
		OnAcidActivatorStarted.Broadcast(this);
	}

	// Doesn't need to be crumbed because it's called from on deactivated on a crumbed capability
	void StopActivator()
	{
		bIsActive = false;
		TimeStampDeactivation = Time::GameTimeSeconds;
		OnAcidActivatorStopped.Broadcast(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, AutoAimDistance, 20, FLinearColor::Green, 10.0);
	}
#endif

};
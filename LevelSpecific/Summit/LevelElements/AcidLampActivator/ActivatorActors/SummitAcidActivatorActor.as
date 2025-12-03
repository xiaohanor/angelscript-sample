event void FOnSummitActivatorActorCompletedAction();
event void FSummitAcidActivatorEvent();

class ASummitAcidActivatorActor : AHazeActor
{
	UPROPERTY()
	FOnSummitActivatorActorCompletedAction OnSummitActivatorActorCompletedAction;

	UPROPERTY()
	FSummitAcidActivatorEvent OnAcidActorActivated;

	UPROPERTY()
	FSummitAcidActivatorEvent OnAcidActorDeactivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(EditAnywhere)
	bool bWaitForActionCompleted;

	UPROPERTY(EditAnywhere)
	bool bIsReactivatable = false;

	UPROPERTY(EditAnywhere)
	FAcidActivatorSettings Settings;
	default Settings.IncreaseRate = 2.0;

	//How long it is active for
	UPROPERTY(EditAnywhere)
	float ActivateDuration = 3.0;

	UPROPERTY(EditAnywhere)
	float AutoAimDistance = 5000.0;

	private float InternalStartActivationTime;

	UPROPERTY()
	TSubclassOf<AAcidActivator> AcidActivatorClass;

	TArray<AAcidActivator> AcidActivators;
	TArray<USummitAcidActivatorAttachComponent> AttachComps; 

	protected bool bIsActivatorActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		GetComponentsByClass(AttachComps);
		SpawnAcidActivators();
	}
	
	private void SpawnAcidActivators()
	{
		int Index = 0;
		for (USummitAcidActivatorAttachComponent AttachComp : AttachComps)
		{
			Index++;
			AAcidActivator AcidActivator = Cast<AAcidActivator>(SpawnActor(AcidActivatorClass, AttachComp.WorldLocation, AttachComp.WorldRotation, bDeferredSpawn = true));
			AcidActivator.MakeNetworked(this, Index);
			AcidActivator.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld);
			AcidActivator.bWaitForActionCompleted = bWaitForActionCompleted;
			AcidActivator.ActivatorActor = this;
			AcidActivator.ActivateDuration = ActivateDuration;
			AcidActivator.Settings = Settings;
			AcidActivator.bIsReactivatable = bIsReactivatable;
			AcidActivator.AutoAim.MaximumDistance = AutoAimDistance;
			AcidActivator.OnAcidActivatorStarted.AddUFunction(this, n"OnAcidActivatorStarted");
			AcidActivator.OnAcidActivatorStopped.AddUFunction(this, n"OnAcidActivatorStopped");
			FinishSpawningActor(AcidActivator);
			AcidActivators.AddUnique(AcidActivator);
		}
	}

	void SetActivator(AAcidActivator NewActivator)
	{
		AcidActivators.AddUnique(NewActivator);
		NewActivator.OnAcidActivatorStarted.AddUFunction(this, n"OnAcidActivatorStarted");
	}

	UFUNCTION()
	protected void OnAcidActivatorStarted(AAcidActivator Activator) 
	{
		bIsActivatorActive = true;
		InternalStartActivationTime = Time::GameTimeSeconds;

		if (!bIsReactivatable)
			Activator.AutoAim.Disable(this);

		OnAcidActorActivated.Broadcast();
	}

	UFUNCTION()
	protected void OnAcidActivatorStopped(AAcidActivator Activator)
	{
		bIsActivatorActive = false;

		if (!bIsReactivatable)
			Activator.AutoAim.Enable(this);
		
		OnAcidActorDeactivated.Broadcast();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	protected void CrumbFireCompletedAction()
	{
		OnSummitActivatorActorCompletedAction.Broadcast();
	}

	bool IsActivatorActive() const
	{
		return bIsActivatorActive;
	}

	float GetAlphaProgress() const
	{
		if (!bIsActivatorActive)	
			return 0.0;

		if (bIsReactivatable)
		{
			AAcidActivator ActivatedAcid;

			for (AAcidActivator Activator : AcidActivators)
			{
				if (Activator.bIsActive)
					ActivatedAcid = Activator;
			}

			if (ActivatedAcid != nullptr)
			{
				if (ActivatedAcid.TimeSinceLastHit > 0.0)
					return ActivatedAcid.TimeSinceLastHit / ActivateDuration;
			}

			return 0.0;
		}

		float TimePassed = Time::GameTimeSeconds - InternalStartActivationTime;
		
		if (TimePassed <= 0.0)
			return 0.0;

		return Math::Saturate(TimePassed / ActivateDuration);
	}

	AAcidActivator GetActiveAcidActivator() const
	{
		AAcidActivator ActivatedAcid;

		for (AAcidActivator Activator : AcidActivators)
		{
			if (Activator.bIsActive)
				ActivatedAcid = Activator;
		}

		return ActivatedAcid;
	}

	AAcidActivator GetProgressingAcidActivator() const
	{
		AAcidActivator ActivatedAcid;

		for (AAcidActivator Activator : AcidActivators)
		{
			if (Activator.AcidAlpha.Value < 1.0)
				ActivatedAcid = Activator;
		}

		return ActivatedAcid;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, AutoAimDistance, 20, FLinearColor::Green, 10.0);
	}
#endif
};
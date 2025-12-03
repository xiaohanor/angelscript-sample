class ASanctuaryLightBirdNova : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent RotationPivot1;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent RotationPivot2;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent RotationPivot3;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;
	default LightBirdResponseComp.bExclusiveAttachedIllumination = true;

	UPROPERTY(DefaultComponent)
	ULightBirdChargeComponent LightBirdChargeComp;
	default LightBirdChargeComp.ChargeDuration = 0.5;
	default LightBirdChargeComp.DecayMultiplier = 0.25;
	default LightBirdChargeComp.DecayDelay = 0.0;

	UPROPERTY(DefaultComponent)
	USanctuaryInterfaceComponent InterfaceComp;

	FHazeAcceleratedFloat AcceleratedFloat;
	FHazeAcceleratedFloat AcceleratedScale;

	UPROPERTY(EditAnywhere)
	float TransitionSpeed = 1.0;

	UPROPERTY(EditAnywhere)
	float IdleRotationSpeed = 120.0;

	UPROPERTY(EditAnywhere)
	float ActiveRotationSpeed = 720.0;

	UPROPERTY(EditAnywhere)
	bool bExitOnActiviation = false;

	UPROPERTY(EditAnywhere)
	float ActiveDuration = 6.0;
	bool bIsActivated = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird Response")
	bool bListenToParentLightBirdResponse = true;

	float DeactivationTime = 0.0;

	ASanctuaryLightBirdNovaParticle SourceNovaParticle;

	TArray<ASanctuaryLightBirdNovaParticle> NovaParticles;
	int GetNumNovaParticles() const property
	{
		return NovaParticles.Num();
	}

	void GetNovaParticlesLocations(TArray<FVector>& outLocations)
	{
		outLocations.Empty();
		for(auto Particle : NovaParticles)
		{
			outLocations.Add(Particle.ActorLocation);
		}
	}	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bListenToParentLightBirdResponse && AttachParentActor != nullptr)
			LightBirdResponseComp.AddListenToResponseActor(AttachParentActor);

		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
		LightBirdChargeComp.OnFullyCharged.AddUFunction(this, n"HandleFullyCharged");
		LightBirdChargeComp.OnChargeDepleted.AddUFunction(this, n"HandleChargeDepleted");
	
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true);
		for (auto AttachedActor : AttachedActors)
		{
			auto NovaParticle = Cast<ASanctuaryLightBirdNovaParticle>(AttachedActor);
			if (NovaParticle != nullptr)
			{
				NovaParticles.Add(NovaParticle);
			}
		}

		SourceNovaParticle = GetLinkSourceNovaParticle();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		Debug::DrawDebugSphere(SourceNovaParticle.ActorLocation, 400.0, 12, FLinearColor::Green, 5.0, 0.0);
//		PrintToScreen("Charge: " + LightBirdChargeComp.ChargeFraction, 0.0, FLinearColor::Green);

		AcceleratedFloat.AccelerateTo((LightBirdResponseComp.IsIlluminated() ? 1.0 : 0.0), TransitionSpeed, DeltaSeconds);
		float RotationSpeed = Math::Lerp(IdleRotationSpeed, ActiveRotationSpeed, AcceleratedFloat.Value);

		RotationPivot1.AddLocalRotation(FRotator(0.0, RotationSpeed * 0.8 * DeltaSeconds, 0.0));
		RotationPivot2.AddLocalRotation(FRotator(RotationSpeed * 0.8 * DeltaSeconds, RotationSpeed * 0.6 * DeltaSeconds, 0.0));
		RotationPivot3.AddLocalRotation(FRotator(RotationSpeed * DeltaSeconds, 0.0, 0.0));	
	
		AcceleratedScale.AccelerateTo((bIsActivated ? 0.0 : 1.0), 1.0, DeltaSeconds);
//		float Scale = 1.0 - LightBirdChargeComp.ChargeFraction;
		float Scale = AcceleratedScale.Value;
		RotationPivot1.SetRelativeScale3D(FVector::OneVector * Scale);
		RotationPivot2.SetRelativeScale3D(FVector::OneVector * Scale);
		RotationPivot3.SetRelativeScale3D(FVector::OneVector * Scale);

		for (auto NovaParticle : NovaParticles)
			NovaParticle.AcceleratedScale.SnapTo(LightBirdChargeComp.ChargeFraction);
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
	}

	UFUNCTION()
	private void HandleFullyCharged()
	{
		if (bExitOnActiviation)
		{
			auto UserComp = ULightBirdUserComponent::Get(Game::Mio);
			UserComp.Hover();
			UserComp.Companion.CompanionComp.State = ELightBirdCompanionState::Obstructed;
		}

		InterfaceComp.TriggerActivate();

		Activate();
	}

	UFUNCTION()
	private void HandleChargeDepleted()
	{
		InterfaceComp.TriggerDeactivate();

		Deactivate();
	}

	UFUNCTION()
	void Activate()
	{
//		LightBirdTargetComp.Disable(this);
		bIsActivated = true;

		for (auto NovaParticle : NovaParticles)
		{
			NovaParticle.Activate();
		}

//		SourceNovaParticle.ActivateLinkRay();

		Timer::SetTimer(SourceNovaParticle, n"ActivateLinkRay", SourceNovaParticle.ActivationDuration * 0.4);


//		Timer::SetTimer(this, n"Deactivate", ActiveDuration);
	
		BP_Activate();

		USanctuaryLightBirdNovaEffectEventHandler::Trigger_OnNovaIlluminated(this);
	}

	UFUNCTION()
	void Deactivate()
	{
		Timer::ClearTimer(SourceNovaParticle, n"ActivateLinkRay");

//		LightBirdTargetComp.Enable(this);
		bIsActivated = false;

		for (auto NovaParticle : NovaParticles)
		{
			NovaParticle.Deactivate();
		}
	
		BP_Deactivate();

		USanctuaryLightBirdNovaEffectEventHandler::Trigger_OnNovaDelluminated(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate()
	{
	}

	ASanctuaryLightBirdNovaParticle GetLinkSourceNovaParticle()
	{
		ASanctuaryLightBirdNovaParticle EndParticle;
		for (auto NovaParticle : NovaParticles)
		{
			if (NovaParticle.LinkedParticles.Num() == 0)
			{
				EndParticle = NovaParticle;
				break;
			}
		}

		bool bHasFoundSource = false;
		while (!bHasFoundSource)
		{
			bool bFoundLink = false;
			for (auto NovaParticle : NovaParticles)
			{
				if (NovaParticle.LinkedParticles.Contains(EndParticle))
				{
					EndParticle = NovaParticle;
					bFoundLink = true;
					break;
				}
			}

			if (!bFoundLink)
				bHasFoundSource = true;
		}
	
		return EndParticle;
	}
};
class USanctuaryLightBirdNovaParticleVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryLightBirdNovaParticleVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto NovaParticle = Cast<ASanctuaryLightBirdNovaParticle>(InComponent.Owner);
	}
}

class USanctuaryLightBirdNovaParticleVisualizerComponent : UHazeEditorRenderedComponent
{
	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		auto NovaParticle = Cast<ASanctuaryLightBirdNovaParticle>(Owner);
		if (NovaParticle == nullptr)
			return;

		float Thickness = 20.0;
		FLinearColor Color = FLinearColor::Green;

		for (auto LinkedParticle : NovaParticle.LinkedParticles)
		{
			DrawLine(NovaParticle.ActorLocation, LinkedParticle.ActorLocation, Color, Thickness);
		}

#endif
	}
}

class ASanctuaryLightBirdNovaParticle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UPerchPointComponent PerchPointComp;
	default PerchPointComp.bAllowGrappleToPoint = false;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchEnterByZoneComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLightBirdNovaParticleVisualizerComponent VisualizerComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.0;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryLightBirdNovaParticle> LinkedParticles;

	float LinkWidth = 0.075;

	UPROPERTY(EditAnywhere)
	float BobbingHeight = 50.0;

	UPROPERTY(EditAnywhere)
	TSubclassOf<USanctuaryDynamicLightRayMeshComponent> DynamicLightRayMeshCompClass;
	TArray<USanctuaryDynamicLightRayMeshComponent> DynamicLightRayMeshComps;

	FHazeAcceleratedFloat AcceleratedFloat;
	FHazeAcceleratedFloat AcceleratedScale;
	FHazeAcceleratedFloat AcceleratedPerchEffect;
	
	float Target = 0.0;
	float Duration = 1.0;
	float ActivationDuration = 1.5;
	float DeactivationDuration = 4.0;

	FTransform InitialRelativeTransform;

	AActor RootActor;

	bool bIsActive = false;

	UPROPERTY(EditAnywhere)
	bool bOnlyJumpUp = false;

	float LinkActivationDelay = 0.1; // 0.2
	float NextLinkActivationTime = 0.0;

	bool bLinkRayActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPointComp.Disable(this);
		InitialRelativeTransform = RootComponent.RelativeTransform;

		PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartPerching");
		PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStopPerching");

		if (bOnlyJumpUp)
		{
			PerchPointComp.HeightActivationSettings = EHeightActivationSettings::ActivateOnlyBelow;
			PerchPointComp.HeightActivationMargin = 0.0;
		}

		for (int i = 0; i < LinkedParticles.Num(); i++)
		{
			auto DynamicLightRayMeshComp = CreateComponent(DynamicLightRayMeshCompClass);
			DynamicLightRayMeshComp.AttachToComponent(TranslateComp);
			DynamicLightRayMeshComp.Width = LinkWidth;
			DynamicLightRayMeshComp.MID.SetScalarParameterValue(n"VertexStrength", 0.0);
			DynamicLightRayMeshComps.Add(DynamicLightRayMeshComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedPerchEffect.AccelerateTo((IsAnyPlayerPerching() ? 1.0 : 0.0), 1.0, DeltaSeconds);
		AcceleratedFloat.AccelerateTo(Target, Duration, DeltaSeconds);

		FTransform ParentTransformZeroScale = Root.AttachParent.WorldTransform;
		ParentTransformZeroScale.Scale3D = FVector::ZeroVector;

		FTransform Bobbing;
		Bobbing.Scale3D = FVector::OneVector * AcceleratedScale.Value;
		Bobbing.Location = FVector::UpVector * Math::Sin(Time::PredictedGlobalCrumbTrailTime + InitialRelativeTransform.Location.Size() * 1.0) * BobbingHeight;

		ActorTransform = LerpTransform(ParentTransformZeroScale, Bobbing * InitialRelativeTransform * Root.AttachParent.WorldTransform, AcceleratedFloat.Value);

		for (int i = 0; i < LinkedParticles.Num(); i++)
		{
			if (bLinkRayActivated && Time::GameTimeSeconds > NextLinkActivationTime)
				LinkedParticles[i].ActivateLinkRay();

			FVector ToParticle = LinkedParticles[i].TranslateComp.WorldLocation - TranslateComp.WorldLocation;
			DynamicLightRayMeshComps[i].SetWorldScale3D(FVector(
				DynamicLightRayMeshComps[i].GetWorldScale().X,
				DynamicLightRayMeshComps[i].GetWorldScale().Y,
				ToParticle.Size() * 0.01 * (1.0 - ((Math::Max(0.0, NextLinkActivationTime - Time::GameTimeSeconds)) / LinkActivationDelay)) + SMALL_NUMBER
				));
			DynamicLightRayMeshComps[i].ComponentQuat = FQuat::MakeFromZ(ToParticle);
		
			DynamicLightRayMeshComps[i].Width = AcceleratedScale.Value * LinkWidth;
		}
	}

	void Activate()
	{
		PerchPointComp.Enable(this);
		bIsActive = true;
		Target = 1.0;
		Duration = ActivationDuration;
		BP_Activate();

//		for (auto DynamicLightRayMeshComp : DynamicLightRayMeshComps)
//			DynamicLightRayMeshComp.Enable();
	}

	void Deactivate()
	{
		PerchPointComp.Disable(this);
		bIsActive = false;
		Target = 0.0;
		AcceleratedFloat.SnapTo(0.0);
		Duration = DeactivationDuration;
		BP_Deactivate();


	DeactivateLinkRay();
//		for (auto DynamicLightRayMeshComp : DynamicLightRayMeshComps)
//			DynamicLightRayMeshComp.Disable();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate()
	{
	}

	UFUNCTION()
	void ActivateLinkRay()
	{
		if (bLinkRayActivated)
			return;

		for (auto DynamicLightRayMeshComp : DynamicLightRayMeshComps)
			DynamicLightRayMeshComp.Enable();

		NextLinkActivationTime = Time::GameTimeSeconds + LinkActivationDelay;
	
		bLinkRayActivated = true;
	}

	UFUNCTION()
	void DeactivateLinkRay()
	{
		for (auto DynamicLightRayMeshComp : DynamicLightRayMeshComps)
			DynamicLightRayMeshComp.Disable();
	
		bLinkRayActivated = false;
	}

	FTransform LerpTransform(FTransform A, FTransform B, float Alpha)
	{
		FTransform LerpedTransform;
		LerpedTransform.Location = Math::Lerp(A.Location, B.Location, Alpha);
		LerpedTransform.Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		LerpedTransform.Scale3D = Math::Lerp(A.Scale3D, B.Scale3D, Alpha);

		return LerpedTransform;
	}

	UFUNCTION(BlueprintPure)
	float GetIntensityAlphaValue() property
	{
		return AcceleratedPerchEffect.Value * AcceleratedScale.Value;
	}

	UFUNCTION(BlueprintPure)
	float GetAlphaValue() property
	{
		return AcceleratedFloat.Value;
	}

	UFUNCTION()
	void OnPlayerStartPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint) 
	{
		FLightBirdNovaParticlePerchEventData Data;
		Data.Particle = this;
		Data.Player = Player;

		USanctuaryLightBirdNovaEffectEventHandler::Trigger_OnPlayerStartPerchOnParticle(Cast<AHazeActor>(AttachParentActor), Data);
	}

	UFUNCTION()
	void OnPlayerStopPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint) 
	{
		FLightBirdNovaParticlePerchEventData Data;
		Data.Particle = this;
		Data.Player = Player;

		USanctuaryLightBirdNovaEffectEventHandler::Trigger_OnPlayerStopPerchOnParticle(Cast<AHazeActor>(AttachParentActor), Data);
	}

	UFUNCTION(BlueprintPure)
	float GetPerchEffectAlphaValue() property
	{
		return AcceleratedPerchEffect.Value;
	}

	bool IsAnyPlayerPerching()
	{
		for (auto Player : Game::Players)
		{
			if (PerchPointComp.IsPlayerOnPerchPoint[Player])
				return true;
		}
	
		return false;
	}
}
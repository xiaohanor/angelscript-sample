class ASkylineTorLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach=LightMesh)
	USpotLightComponent SpotLightComp;
	default SpotLightComp.Mobility = EComponentMobility::Movable;
	default SpotLightComp.CastShadows = false;
	default SpotLightComp.SetIntensityUnits(ELightUnits::Unitless);
	default SpotLightComp.SetIntensity(5);
	default SpotLightComp.AttenuationRadius = 15000;
	default SpotLightComp.OuterConeAngle = 3;
	default SpotLightComp.UseInverseSquaredFalloff = false;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LightMesh;

	UPROPERTY(EditInstanceOnly)
	ESkylineTorLightTarget LightTarget;

	AHazeActor Target;
	FHazeAcceleratedRotator AccRot;
	USkylineTorTelegraphLightComponent TelegraphLightComp;
	TArray<AGodray> Godrays;
	bool bEnabled;
	float OriginalIntensity;
	FHazeAcceleratedFloat AccIntensity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ASkylineTor Tor = TListedActors<ASkylineTor>().Single;
		TelegraphLightComp = USkylineTorTelegraphLightComponent::GetOrCreate(Tor);
		TelegraphLightComp.OnStart.AddUFunction(this, n"StartTelegraphing");
		TelegraphLightComp.OnStop.AddUFunction(this, n"StopTelegraphing");
		USkylineTorPhaseComponent::GetOrCreate(Tor).OnPhaseChange.AddUFunction(this, n"PhaseChange");

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for(AActor Att : AttachedActors)
		{
			AGodray Godray = Cast<AGodray>(Att);
			if(Godray == nullptr)
				continue;
			Godray.AttachToComponent(LightMesh, NAME_None, EAttachmentRule::KeepWorld);
			Godrays.Add(Godray);
		}

		if(LightTarget == ESkylineTorLightTarget::Mio)
			Target = Game::Mio;
		if(LightTarget == ESkylineTorLightTarget::Zoe)
			Target = Game::Zoe;
		if(LightTarget == ESkylineTorLightTarget::Tor)
			Target = TListedActors<ASkylineTor>().Single;
		if(LightTarget == ESkylineTorLightTarget::Telegraphing)
			StopTelegraphing();

		LightMesh.SetColorParameterValueOnMaterials(n"EmissiveTint", SpotLightComp.LightColor * 2);
		OriginalIntensity = SpotLightComp.Intensity;
		DisableLight();
	}

	UFUNCTION()
	private void StartTelegraphing()
	{
		if(!bEnabled)
			return;

		bool bTelegraphing = LightTarget == ESkylineTorLightTarget::Telegraphing;
		SpotLightComp.SetVisibility(bTelegraphing);

		for(AGodray Ray : Godrays)
			Ray.Component.SetVisibility(bTelegraphing);
	}

	UFUNCTION()
	private void StopTelegraphing()
	{
		if(!bEnabled)
			return;

		bool bTelegraphing = LightTarget != ESkylineTorLightTarget::Telegraphing;
		SpotLightComp.SetVisibility(bTelegraphing);

		for(AGodray Ray : Godrays)
			Ray.Component.SetVisibility(bTelegraphing);
	}

	UFUNCTION()
	private void PhaseChange(ESkylineTorPhase NewPhase, ESkylineTorPhase OldPhase,
	                         ESkylineTorSubPhase NewSubPhase, ESkylineTorSubPhase OldSubPhase)
	{
		
		if(NewPhase == ESkylineTorPhase::Dead)
			DisableLight();

		if(NewPhase == ESkylineTorPhase::Grounded || NewPhase == ESkylineTorPhase::Hovering)
			EnableLight();
	}

	private void EnableLight()
	{
		bEnabled = true;
		StopTelegraphing();
	}

	private void DisableLight()
	{
		bEnabled = false;
		SpotLightComp.SetVisibility(false);
		for(AGodray Ray : Godrays)
			Ray.Component.SetVisibility(false);
		SpotLightComp.SetIntensity(0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bEnabled)
			return;

		if(LightTarget == ESkylineTorLightTarget::Telegraphing)
		{
			AccRot.AccelerateTo((TelegraphLightComp.TelegraphLocation - LightMesh.WorldLocation).Rotation(), 0.25, DeltaSeconds);
			LightMesh.WorldRotation = AccRot.Value;
		}
		else
		{
			AccRot.AccelerateTo((Target.ActorLocation - LightMesh.WorldLocation).Rotation(), 0.5, DeltaSeconds);
			LightMesh.WorldRotation = AccRot.Value;
		}

		if(SpotLightComp.Intensity < OriginalIntensity - SMALL_NUMBER)
		{
			AccIntensity.AccelerateTo(OriginalIntensity, 2, DeltaSeconds);
			SpotLightComp.SetIntensity(AccIntensity.Value);
		}
	}
}

enum ESkylineTorLightTarget
{
	Mio,
	Zoe,
	Tor,
	Telegraphing
}
class ASkylineGravityZoneGenerator : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponseComp;

	UPROPERTY(DefaultComponent, NotVisible, BlueprintHidden)
	UDummyVisualizationComponent DummyVisualizer;
	default DummyVisualizer.Color = FLinearColor::Yellow;

	UPROPERTY(EditAnywhere, Category = "Generator")
	TArray<ASkylineGravityZone> GravityZones;

	UPROPERTY(EditAnywhere, Category = "Generator")
	float ActiveDuration = 5.0;

	private float DeactivationTimestamp;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		DummyVisualizer.ConnectedActors.Empty();
		for (int i = 0; i < GravityZones.Num(); ++i)
		{
			if (GravityZones[i] != nullptr)
				DummyVisualizer.ConnectedActors.Add(GravityZones[i]);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BladeResponseComp.OnHit.AddUFunction(this, n"HandleSwordHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (DeactivationTimestamp < Time::GameTimeSeconds)
		{
			DeactivateLinkedZones();
			SetActorTickEnabled(false);
		}
	}

	private void ActivateLinkedZones()
	{
		for (int i = GravityZones.Num() - 1; i >= 0; --i)
		{
			auto GravityZone = GravityZones[i];
			if (GravityZone == nullptr)
				continue;

			GravityZone.Activate(this);
		}
	}

	private void DeactivateLinkedZones()
	{
		for (int i = GravityZones.Num() - 1; i >= 0; --i)
		{
			auto GravityZone = GravityZones[i];
			if (GravityZone == nullptr)
				continue;

			GravityZone.Deactivate(this);
		}
	}

	UFUNCTION()
	private void HandleSwordHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		// FB TODO: This was previously GroundPound, then GroundCharged.
		// Now that charge is removed, do we still want this behaviour for some attack?
		
		// if(HitData.AttackType == EGravityBladeCombatAttackType::GroundCharged)
		// {
		// 	ActivateLinkedZones();
		// 	SetActorTickEnabled(true);

		// 	DeactivationTimestamp = Time::GameTimeSeconds + ActiveDuration;
		// }
	}

	UFUNCTION(DevFunction)
	void ForceActivate()
	{
		ActivateLinkedZones();
		SetActorTickEnabled(true);

		DeactivationTimestamp = Time::GameTimeSeconds + ActiveDuration;
	}
	
	UFUNCTION(DevFunction)
	void ForceDeactivate()
	{
		DeactivateLinkedZones();
		SetActorTickEnabled(false);
	}
}
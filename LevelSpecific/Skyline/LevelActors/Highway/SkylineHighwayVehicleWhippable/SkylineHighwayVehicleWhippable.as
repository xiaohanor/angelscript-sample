event void SkylineHighwayVehicleWhippableOnTurretDie(ASkylineHighwayVehicleWhippable Vehicle);

UCLASS(Abstract)
class ASkylineHighwayVehicleWhippable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayVehicleWhippableCrashCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayVehicleWhippableScanCapability");

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent RotateComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Drag;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent WhipImpactComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipSlingAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach = AutoAimComp)
	UTargetableOutlineComponent WhipSlingOutlineComp;

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent, Attach=RotateComp)
	UStaticMeshComponent TurretDummy;
	default TurretDummy.CollisionProfileName = n"NoCollision";
	default TurretDummy.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
	USkylineHighwayVehicleWhippableScanComponent ScanComp;

	UPROPERTY(EditAnywhere)
	ASkylineHighwayVehicleWhippableBoundsVolume BoundsVolume;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AAISkylineTurret> TurretClass;

	UPROPERTY(EditAnywhere)
	bool bExcludeTurret;

	UPROPERTY()
	AAISkylineTurret Turret;

	UPROPERTY()
	SkylineHighwayVehicleWhippableOnTurretDie OnTurretDie;

	UPROPERTY()
	UNiagaraSystem ExplodeFX;

	UGravityWhipUserComponent WhipUser;
	bool bWhipped;
	bool bReachedOriginal = true;
	FHazeAcceleratedVector AccLocation;
	FVector OriginalLocation;
	float WhipDuration = 1.5;
	bool bTurretDied;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnReleased.AddUFunction(this, n"OnReleased");

		// Not whip target or grapple points for now
		WhipTarget.Disable(this);

		TArray<UGrapplePointComponent> GrapplePoints;
		GetComponentsByClass(GrapplePoints);
		for(auto Point : GrapplePoints)
			Point.Disable(this);

		// if(!bExcludeTurret)
		// {
		// 	//WhipTarget.Disable(this);
		// 	Turret = SpawnActor(TurretClass);
		// 	Turret.AttachToActor(this);
		// 	Turret.ActorLocation = TurretDummy.WorldLocation;
		// 	Turret.ActorRotation = TurretDummy.WorldRotation;
		// 	Turret.OnAIDie.AddUFunction(this, n"TurretDie");
		// 	Turret.BlockCapabilities(n"Behaviour", this);
		// 	UBasicAISettings::SetRangedAttackRequireVisibility(Turret, false, this);

		// 	if(IsActorDisabled())
		// 		Turret.AddActorDisable(this);
		// }
		// else
		// {
		// 	TArray<UGrapplePointComponent> GrapplePoints;
		// 	GetComponentsByClass(GrapplePoints);
		// 	for(auto Point : GrapplePoints)
		// 		Point.Disable(this);
		// }

		WhipImpactComp.OnImpact.AddUFunction(this, n"OnImpact");
		WhipImpactComp.OnRadialImpact.AddUFunction(this, n"OnRadialImpact");
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if(Turret == nullptr)
			return;
		Turret.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if(Turret == nullptr)
			return;
		Turret.AddActorDisable(this);
	}

	UFUNCTION()
	private void OnRadialImpact(FGravityWhipRadialImpactData ImpactData)
	{
		if(Turret == nullptr)
			return;
		UGravityWhipImpactResponseComponent::Get(Turret).OnRadialImpact.Broadcast(ImpactData);
	}

	UFUNCTION()
	protected void OnImpact(FGravityWhipImpactData ImpactData)
	{
		if(Turret == nullptr)
			return;
		UGravityWhipImpactResponseComponent::Get(Turret).OnImpact.Broadcast(ImpactData);
	}

	UFUNCTION()
	private void TurretDie()
	{
		RotateComp.ApplyImpulse(ActorLocation + FVector(0, 100, 0), FVector::DownVector * 5000);

		WhipTarget.Disable(this);
		TArray<FGravityWhipResponseGrab> Grabs = WhipResponse.Grabs;
		for(FGravityWhipResponseGrab Grab : Grabs)
			WhipResponse.Release(Grab.UserComponent, Grab.TargetComponent, FVector::ZeroVector);

		bTurretDied = true;
		OnTurretDie.Broadcast(this);
	}

	UFUNCTION()
	void EnableTurret()
	{
		Turret.UnblockCapabilities(n"Behaviour", this);
	}

	UFUNCTION()
	void EnableScan()
	{
		ScanComp.EnableScan();
	}

	void Explode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplodeFX, ActorLocation);
		DestroyActor();
	}

	UFUNCTION()
	private void OnReleased(UGravityWhipUserComponent UserComponent,
	                        UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		bWhipped = false;
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
	                       UGravityWhipTargetComponent TargetComponent,
	                       TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if(bWhipped)
			return;
		WhipUser = UserComponent;

		if(bReachedOriginal)
		{
			OriginalLocation = ActorLocation;
			AccLocation.Value = OriginalLocation;
		}

		bWhipped = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bTurretDied)
			return;

		if(!bWhipped)
		{
			if(OriginalLocation == FVector::ZeroVector)
				return;

			bReachedOriginal = ActorLocation.IsWithinDist(OriginalLocation, 25);
			AccLocation.AccelerateTo(OriginalLocation, WhipDuration, DeltaSeconds);
			ActorLocation = AccLocation.Value;
			return;
		}

		FVector Dir = (OriginalLocation - WhipUser.Owner.ActorLocation).GetSafeNormal2D();
		FVector TargetLocation = WhipUser.Owner.ActorLocation + (FVector::UpVector * 100) + (Dir * 900);

		if(BoundsVolume != nullptr)
		{
			TargetLocation.X = Math::Clamp(TargetLocation.X, BoundsVolume.ActorLocation.X - BoundsVolume.Bounds.BoxExtent.X, BoundsVolume.ActorLocation.X + BoundsVolume.Bounds.BoxExtent.X);
			TargetLocation.Y = Math::Clamp(TargetLocation.Y, BoundsVolume.ActorLocation.Y - BoundsVolume.Bounds.BoxExtent.Y, BoundsVolume.ActorLocation.Y + BoundsVolume.Bounds.BoxExtent.Y);
			TargetLocation.Z = Math::Clamp(TargetLocation.Z, BoundsVolume.ActorLocation.Z - BoundsVolume.Bounds.BoxExtent.Z, BoundsVolume.ActorLocation.Z + BoundsVolume.Bounds.BoxExtent.Z);
		}

		AccLocation.AccelerateTo(TargetLocation, WhipDuration, DeltaSeconds);
		ActorLocation = AccLocation.Value;
	}
}
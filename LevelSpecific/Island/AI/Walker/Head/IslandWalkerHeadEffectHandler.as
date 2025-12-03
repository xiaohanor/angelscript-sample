UCLASS(Abstract)
class UIslandWalkerHeadEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, Transient)
	TArray<UNiagaraComponent> Thrusters;

	UPROPERTY(BlueprintReadOnly, Transient)
	UHazeDecalComponent FireSwoopTelegraphDecal;

	UPROPERTY(BlueprintReadOnly, Transient)
	UHazeDecalComponent AcidPoolDecal;

	UIslandWalkerHeadComponent HeadComp;
	FHazeAcceleratedFloat AcidPoolGrowth;
	default AcidPoolGrowth.PrecisionLambertNominator = 5.0;

	UFUNCTION(BlueprintPure)
	FVector GetFireSwoopTargetLocation() const
	{
		return HeadComp.FireSwoopTargetLoc;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TArray<UActorComponent> Comps = Owner.GetComponentsByTag(UNiagaraComponent, n"Thruster");
		for (UActorComponent Comp : Comps)
		{
			UNiagaraComponent Thruster = Cast<UNiagaraComponent>(Comp);
			if (Thruster == nullptr)
				continue;
			Thrusters.Add(Thruster);
			Thruster.DeactivateImmediate();
		}

		FireSwoopTelegraphDecal = UHazeDecalComponent::Get(Owner, n"FireSwoopTelegraphDecal");
		if (FireSwoopTelegraphDecal != nullptr)
			FireSwoopTelegraphDecal.DetachFromParent(true);

		AcidPoolDecal = UHazeDecalComponent::Get(Owner, n"AcidPoolDecal");
		if (AcidPoolDecal != nullptr)
			AcidPoolDecal.SetWorldScale3D(FVector::OneVector * 0.01);

		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
	}

	UFUNCTION(BlueprintCallable)
	void ActivateThrusters()
	{
		for (UNiagaraComponent Thruster : Thrusters)
		{
			Thruster.Activate(true);
		}
	}

	UFUNCTION(BlueprintCallable)
	void DeactivateThrusters()
	{
		for (UNiagaraComponent Thruster : Thrusters)
		{
			Thruster.Deactivate();
		}
	}

	UFUNCTION(BlueprintCallable)
	void GrowAcidPool(float Duration, float DeltaTime)
	{
		if (AcidPoolDecal.AttachParent == nullptr)
		{
			AcidPoolDecal.AttachTo(Owner.RootComponent);
			AcidPoolDecal.RelativeLocation = FVector(0.0, 0.0, -300.0);
		}

		AcidPoolGrowth.AccelerateTo(1.0, Duration, DeltaTime);
		FVector Scale = FVector::OneVector * AcidPoolGrowth.Value; 
		Scale.X = 1.0;
		AcidPoolDecal.SetWorldScale3D(Scale);
	}

	UFUNCTION(BlueprintCallable)
	void ShrinkAcidPool(float Duration, float DeltaTime)
	{
		if (AcidPoolDecal.AttachParent != nullptr)
			AcidPoolDecal.DetachFromParent(true);

		AcidPoolGrowth.AccelerateTo(0.0, Duration, DeltaTime);
		FVector Scale = FVector::OneVector * AcidPoolGrowth.Value; 
		Scale.X = 1.0;
		AcidPoolDecal.SetWorldScale3D(Scale);
	}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDestruction() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChaseAttackGroundedStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChaseAttackGroundedStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireBurstTelegraph(FIslandWalkerSprayFireParams Params){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireBurstStart(FIslandWalkerSprayFireParams Params){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireBurstStop(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFirewallSprayFuelTelegraph(FIslandWalkerSprayFireParams Params){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFirewallSprayFuelStart(FIslandWalkerSprayFireParams Params){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFirewallSprayFuelStop(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFirewallTelegraphIgnition(FIslandWalkerSprayFireParams Params){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFirewallIgnitionStart(FIslandWalkerSprayFireParams Params){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFirewallIgnitionStop(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHeadChaseTelegraphFire(FIslandWalkerSprayFireParams Params){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHeadChaseSprayFireStart(FIslandWalkerSprayFireParams Params){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHeadChaseSprayFireStop(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireSwoopTelegraphStart(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireSwoopTelegraphStop(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIntroFallIntoPool(FIslandWalkerPoolSurfaceParams Params){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIntroRiseOutOfPool(FIslandWalkerPoolSurfaceParams Params){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeHitLock(FIslandWalkerGrenadeLockParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeTriggerLock(FIslandWalkerGrenadeLockParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeRemovedFromLock(FIslandWalkerGrenadeLockParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartedFlying() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStoppedFlying() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnForceFieldDepleted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldRecover() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnForceFieldPowerUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnForceFieldPowerDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldSwapColor() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartCrashing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCrashLanding() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnHeadShockwave() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartRecoveringFromCrash() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCrashThroughAcidSurface(FIslandWalkerPoolSurfaceParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnOpenHeadHatch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCloseHeadHatch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDestroyHatch(FIslandWalkerDestroyHatchParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnIgniteThruster(FIslandWalkerThrusterParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExtinguishThruster(FIslandWalkerThrusterParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartSplineRunToSwimmingPhase() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnEndSplineRunToSwimmingPhase() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartFinalSplineRunToDestruction() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCancelFinalSplineRunToDestruction() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnEndFinalSplineRunToDestruction() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchButtonMash(FIslandWalkerPlayerHatchParams Params) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootingInToHatch(FIslandWalkerPlayerHatchParams Params) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSneakyHeadSurfacing() {};
}

struct FIslandWalkerPoolSurfaceParams
{
	UPROPERTY(BlueprintReadOnly)
	FVector SurfaceLocation;

	FIslandWalkerPoolSurfaceParams(FVector SurfaceLoc)
	{
		SurfaceLocation = SurfaceLoc;
	}
}

struct FIslandWalkerSprayFireParams
{
	UPROPERTY(BlueprintReadOnly)
	UIslandWalkerFlameThrowerComponent FlameThrower;

	FIslandWalkerSprayFireParams(UIslandWalkerFlameThrowerComponent GasOrifice)
	{
		FlameThrower = GasOrifice;
	}
}

struct FIslandWalkerGrenadeLockParams
{
	UPROPERTY(BlueprintReadOnly)
	AIslandGrenadeLock GrenadeLock;

	FIslandWalkerGrenadeLockParams(AIslandGrenadeLock Lock)
	{
		GrenadeLock = Lock;
	}
}

struct FIslandWalkerDestroyHatchParams
{
	UPROPERTY(BlueprintReadOnly)
	UPrimitiveComponent Hatch;

	FIslandWalkerDestroyHatchParams(UPrimitiveComponent _Hatch)
	{
		Hatch = _Hatch;
	}
}

struct FIslandWalkerThrusterParams
{
	UPROPERTY(BlueprintReadOnly)
	UIslandWalkerHeadThruster Thruster;

	FIslandWalkerThrusterParams(UIslandWalkerHeadThruster _Thruster)
	{
		Thruster = _Thruster;
	}
}

struct FIslandWalkerPlayerHatchParams
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	FIslandWalkerPlayerHatchParams(AHazePlayerCharacter _Player)
	{
		Player = _Player;
	}
}


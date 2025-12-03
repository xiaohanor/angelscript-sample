UCLASS(Abstract)
class ASideCashMachine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoneySpawnLocation;

	UPROPERTY(DefaultComponent, Attach = MoneySpawnLocation)
	UNiagaraComponent VFX_Hit;

	UPROPERTY(DefaultComponent, Attach = MoneySpawnLocation)
	UNiagaraComponent VFX_Cash;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeCombatResponseComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000;

	bool bIsBorked = false;
	float TimestampBorked = -1.0;

	UPROPERTY()
	FHazeAcceleratedVector CashLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BladeCombatResponseComp.OnHit.AddUFunction(this, n"HandleBladeHit");
		CashLocation.SnapTo(MoneySpawnLocation.GetWorldLocation());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsBorked)
			return;

		float TimeSinceBorked = Time::GetGameTimeSince(TimestampBorked);
		if(TimeSinceBorked > 12.0)
		{
			// SetActorTickEnabled(false);
			return;
		}

		ReplicateNiagaraParticleMovement(DeltaSeconds);

		// Debug::DrawDebugPoint(CashLocation.Value, 20.0, FLinearColor::Red);
	}

	void ReplicateNiagaraParticleMovement(const float Dt)
	{
		// gravity
		const float Gravity = -100.0;
		CashLocation.Velocity += (FVector(0.0, 0.0, Gravity)*Dt);

		// drag
		const float Drag = 1.5;
		CashLocation.Velocity /= (Drag*Dt+1.0);

		// Update Location
		CashLocation.Value += CashLocation.Velocity*Dt;

		// Floor collision; constrain to CashMachine.Z
		CashLocation.Value.Z = Math::Max(CashLocation.Value.Z, GetActorLocation().Z);
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (bIsBorked)
			return;

		bIsBorked = true;
		TimestampBorked = Time::GetGameTimeSeconds();

		FVector ImpulseDirection = MoneySpawnLocation.GetForwardVector();
		ImpulseDirection += MoneySpawnLocation.GetUpVector()*0.25;
		ImpulseDirection.Normalize();

		CashLocation.SnapTo(MoneySpawnLocation.GetWorldLocation(), ImpulseDirection*1400.0);

		USideCashMachineEventHandler::Trigger_OnBreak(this);
	}

	UFUNCTION(BlueprintPure)
	FVector GetCashCenterLocation()
	{
		return CashLocation.Value;
	}

	UFUNCTION(BlueprintPure)
	FVector GetCashStartLocation()
	{
		return MoneySpawnLocation.GetWorldLocation();
	}

};
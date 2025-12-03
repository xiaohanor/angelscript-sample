
class UIslandOverseerRollerSweepAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerForceFieldComponent ForceFieldComp;
	UIslandOverseerRollerSweepComponent SweepComp;
	UIslandRedBlueStickyGrenadeTargetable Targetable;
	UIslandOverseerRollerComponent RollerComp;

	AIslandOverseerRoller Roller;
	TArray<AHazePlayerCharacter> HitPlayers;
	bool bBlueShield;
	float PauseTime;
	FHazeAcceleratedFloat AccRotationSpeed;
	FHazeAcceleratedFloat AccMoveSpeed;
	float TelegraphTimer = 0;
	float Distance;
	int Activations;
	int Reverses;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Roller = Cast<AIslandOverseerRoller>(Owner);
		ForceFieldComp = UIslandOverseerForceFieldComponent::Get(Owner);
		SweepComp = UIslandOverseerRollerSweepComponent::GetOrCreate(Owner);
		Targetable = UIslandRedBlueStickyGrenadeTargetable::GetOrCreate(Owner);
		RollerComp = UIslandOverseerRollerComponent::GetOrCreate(Owner);
		Settings = UIslandOverseerSettings::GetSettings(RollerComp.OwningActor);
		Targetable.Disable(Owner);
		ForceFieldComp.TakeDamage(100, FVector::ZeroVector);

		UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner).OnImpactEvent.AddUFunction(this, n"OnImpact");
		UIslandOverseerRedBlueDamageComponent::GetOrCreate(Owner).OnDamage.AddUFunction(this, n"Damage");
	}

	UFUNCTION()
	private void Damage(float Damage, AHazeActor Instigator)
	{
		if(!CanDamage(Instigator))
			return;

		float FinalDamage = Damage * Settings.RollerSweepRedBlueDamagePerSecond;
		if(RollerComp.Color != EIslandForceFieldType::Both)
			FinalDamage *= 2;
		Roller.HealthComp.TakeDamage(FinalDamage, EDamageType::Default, Instigator);
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if(!CanDamage(Data.Player))
			return;

		PauseTime = Time::GameTimeSeconds;
		FIslandOverseerRollerSweepComponentOnCancelHitParams Params;
		Params.ImpactLocation = Data.ImpactLocation;
		SweepComp.OnCancelHit.Broadcast(Params);
		Roller.HideDamageMesh();
	}

	private bool CanDamage(AHazeActor Instigator)
	{
		if(!IsActive())
			return false;
		if(!ForceFieldComp.IsDepleted())
			return false;
		if(RollerComp.Color == EIslandForceFieldType::Blue && Instigator == Game::Mio)
			return false;
		if(RollerComp.Color == EIslandForceFieldType::Red && Instigator == Game::Zoe)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(RollerComp.bDestroyed)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		HitPlayers.Empty();

		SweepComp.bInterrupted = false;
		Distance = 0;
		if(SweepComp.bReverse)
			Distance = SweepComp.Spline.SplineLength;
		Reverses = 0;
		RollerComp.ResetDamage();
		Roller.HealthComp.Reset();
		TelegraphTimer = 0;
		AccRotationSpeed.SnapTo(0);
		AccMoveSpeed.SnapTo(Settings.RollerSweepInitialMoveSpeed);

		FVector TelegraphLocation = Owner.ActorLocation + FVector::DownVector * 200;
		TelegraphLocation.Y = Game::Mio.ActorLocation.Y;
		UIslandOverseerEventHandler::Trigger_OnSwipeTelegraphStart(RollerComp.OwningActor, FIslandOverseerSwipeAttackData(TelegraphLocation));

		FIslandOverseerRollerEventHandlerOnSweepAttackStartData Data;
		Data.RightFxContainer = Roller.RightFxContainer;
		Data.LeftFxContainer = Roller.LeftFxContainer;
		Data.UpFxContainer = Roller.UpFxContainer;
		Data.DownFxContainer = Roller.DownFxContainer;
		UIslandOverseerRollerEventHandler::Trigger_OnSweepAttackStart(Owner, Data);
		RollerComp.StartSpin();
		Roller.HealthBarComp.SetHealthBarEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Targetable.Disable(Owner);
		ForceFieldComp.TakeDamage(100, FVector::ZeroVector);
		if(RollerComp.OwningActor != nullptr)
			UIslandOverseerEventHandler::Trigger_OnSwipeTelegraphStop(RollerComp.OwningActor, FIslandOverseerSwipeAttackData());
		UIslandOverseerRollerEventHandler::Trigger_OnSweepAttackEnd(Owner);
		RollerComp.StopSpin();
		Roller.HideDamageMesh();
		Roller.HealthBarComp.SetHealthBarEnabled(false);
		Activations++;
		Roller.MeshOffset.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Roller.HealthComp.IsDead())
		{
			RollerComp.DestroyRoller();
			DeactivateBehaviour();
			return;
		}

		if(TelegraphTimer < Settings.RollerSweepTelegraphDuration)
		{
			TelegraphTimer += DeltaTime;
			return;
		}

		AccMoveSpeed.AccelerateTo(Settings.RollerSweepMoveSpeed, Settings.RollerSweepMoveAccelerationDuration, DeltaTime);
		AccRotationSpeed.AccelerateTo(Settings.RollerSweepRotationSpeed, Settings.RollerSweepTelegraphDuration, DeltaTime);
		Roller.LastAttackMoveSpeed = AccMoveSpeed.Value;

		float SlowdownFactor = 1.0;
		if(PauseTime != 0 && Time::GetGameTimeSince(PauseTime) < Settings.RollerSweepCancelHitPauseDuration)
		{
			Roller.MeshOffset.AddLocalRotation(FRotator(0, AccRotationSpeed.Value * SlowdownFactor, 0) * DeltaTime);
			SlowdownFactor = 0.6;
		}
		else
		{
			if(PauseTime > 0)
			{
				PauseTime = 0;
				Roller.ShowDamageMesh();
			}
			Roller.MeshOffset.AddLocalRotation(FRotator(0, AccRotationSpeed.Value, 0) * DeltaTime);
		}

		float Delta = DeltaTime * AccMoveSpeed.Value * SlowdownFactor;
		if(SweepComp.bReverse)
			Delta *= -1;
		Distance += Delta;

	 	FVector NewLocation = SweepComp.Spline.GetWorldLocationAtSplineDistance(Distance);
		Owner.SetActorLocation(NewLocation);

		RollerComp.DealDamage();
		RollerComp.Knockback();

		if(Distance >= SweepComp.Spline.SplineLength || Distance <= 0)
		{
			if(!SweepComp.bReverse)
			{
				SweepComp.bReverse = true;
				Distance = SweepComp.Spline.SplineLength;
			}
			else
			{
				SweepComp.bReverse = false;
				Distance = 0;	
			}
			AccMoveSpeed.SnapTo(0);
			AccRotationSpeed.SnapTo(0);
			Reverses++;

			bool UseShield = Activations >= SweepComp.ShieldActivationsLimit;
			if(UseShield && Reverses % 2 == 0)
			{
				bool RecentBurst = Roller.ForceFieldComp.BurstTime > 0 && Time::GetGameTimeSince(Roller.ForceFieldComp.BurstTime) < 1;
				if(Roller.ForceFieldComp.IsDepleted() && !RecentBurst)
					Roller.InitializeForceField();
			}

			UIslandOverseerRollerEventHandler::Trigger_OnSweepReverse(Owner);
		}
	}

	
}

struct FIslandOverseerSwipeAttackData
{
	UPROPERTY(BlueprintReadOnly)
	FVector TelegraphLocation;

	FIslandOverseerSwipeAttackData(FVector InTelegraphLocation)
	{
		TelegraphLocation = InTelegraphLocation;
	}
}
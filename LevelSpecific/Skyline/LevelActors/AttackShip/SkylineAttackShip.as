event void FSkylineAttackShipSignature();

class ASkylineAttackShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent LaserPointer;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxTrigger;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USkylineAttackShipShieldComponent Shield;

	UPROPERTY(DefaultComponent, Attach = Shield)
	UNiagaraComponent FX_Shield;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UGravityBladeGrappleComponent GravityBladeGrappleComponent;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USphereComponent GravityBladeHitCollision;
	default GravityBladeHitCollision.SphereRadius = 50.0;

	UPROPERTY(DefaultComponent, Attach = GravityBladeHitCollision)
	UGravityBladeCombatTargetComponent GravityBladeCombatTargetComponent;

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent PlayerInheritMovementComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeGravityShiftComponent GravityBladeGravityShiftComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeGrappleResponseComponent GravityBladeGrappleResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeCombatResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent GravityWhipImpactResponseComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineAttackShipCompoundCapability");

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditDefaultsOnly)
	USkylineAttackShipSettings DefaultSettings;

	UPROPERTY(EditAnywhere)
	TArray<AActor> SplineOwningActors;

	UPROPERTY(EditAnywhere)
	AActor CrashSplineActor;
	UHazeSplineComponent CrashSpline;

	UHazeSplineComponent Spline;

	UPROPERTY(EditAnywhere)
	ASplineActor MioEjectPOISpline;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = true;

	UPROPERTY(EditAnywhere)
	FName EnragePatternTag = n"Enrage";
	
	UPROPERTY(DefaultComponent)
	UFocusTargetCamera Camera;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent CrumbSyncedVectorComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent CrumbSyncedRotatorComponent;

	UPROPERTY()
	FSkylineAttackShipSignature OnExplode;

	UPROPERTY()
	FSkylineAttackShipSignature OnPlayerEjected;

	UPROPERTY()
	FSkylineAttackShipSignature OnPlayerFinishedEjected;

	UPROPERTY()
	FSkylineAttackShipSignature OnEntryComplete;

	UPROPERTY()
	FSkylineAttackShipSignature OnLastShipCrash;

	UPROPERTY()
	FSkylineAttackShipSignature OnLastShipExplode;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineMallChaseEnemyShipProjectile> ShipProjectileClass;

	TInstigated<AHazeActor> AttackTarget;
	TInstigated<FVector> MoveToTarget;
	TInstigated<FVector> TargetDirection;

	FVector Velocity;
	FVector Acceleration;
	FVector Impulse;
	FVector AngularVelocity;
	FVector AngularAcceleration;
	FVector AngularImpulse;

	float SpeedScale = 1.0;

	TArray<AHazeActorSpawnerBase> AttachedSpawners;
	USkylineAttackShipSettings Settings;

	float PreparingAttackReadyDelay = 8.0;
	float AttackReadyTime = 0.0;
	bool bPreparingAttackReady = false;

	bool bAttackReady = false;
	bool bActivateHitCamera = false;
	
	UPROPERTY(BlueprintReadOnly)
	bool bIsCrashing = false;

	bool bFireFromLeftLauncher = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector::ForwardVector * 100.0, this);
		UBasicAIHealthBarSettings::SetHealthBarAttachComponentName(this, n"GravityBladeHitCollision", this);	

		SetActorControlSide(Game::Mio);
		Settings = USkylineAttackShipSettings::GetSettings(this);

		JoinTeam(n"SkylineAttackShips");

		
		ApplyDefaultSettings(DefaultSettings);

		Shield.Health = Settings.ShieldHP;

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (auto AttachedActor : AttachedActors)
		{
			auto Spawner = Cast<AHazeActorSpawnerBase>(AttachedActor);
			if (Spawner != nullptr)
				AttachedSpawners.Add(Spawner);
		}

		if (SplineOwningActors.Num() > 0)
		{
			Spline = UHazeSplineComponent::Get(SplineOwningActors[0]);
		}
	
		CrashSpline = UHazeSplineComponent::Get(CrashSplineActor);

	//	AddLookAtTarget(ActorForwardVector, this);

		GravityWhipImpactResponseComponent.OnImpact.AddUFunction(this, n"HandleImpact");
		GravityBladeCombatResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");
		Shield.OnShieldBreak.AddUFunction(this, n"HandleShieldBreak");
		Shield.OnShieldRegenerate.AddUFunction(this, n"HandleShieldRegenerate");
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");		

		BoxTrigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleEnterOverlap");
		BoxTrigger.OnComponentEndOverlap.AddUFunction(this, n"HandleLeaveOverlap");
		

		if (!bStartActivated)
			AddActorDisable(this);
	}

	UFUNCTION()
	private void HandleLeaveOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
			if(OtherActor==Game::Mio)
		{
			bActivateHitCamera = false;
		}
	}

	UFUNCTION()
	private void HandleEnterOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		if(OtherActor==Game::Mio)
		{
			bActivateHitCamera = true;
		}
	}

	UFUNCTION()
	private void HandleEjectPlayer()
	{
		OnPlayerEjected.Broadcast();
		Timer::SetTimer(this, n"HandleFinishedEjected", 3.0, false);
	}

	UFUNCTION()
	private void HandleFinishedEjected()
	{
		OnPlayerFinishedEjected.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(n"SkylineAttackShips");	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bPreparingAttackReady && Time::GameTimeSeconds > AttackReadyTime)
		{
			bPreparingAttackReady = false;
			AttackReady();
		}

		if (AttackTarget.Get() != nullptr)
		{
			PrintToScreenScaled("AttackTarget", 0.0, FLinearColor::Green, 1.0);
			FVector ToTarget = AttackTarget.Get().ActorLocation - ActorLocation;
			FVector Direction = ToTarget.VectorPlaneProject(FVector::UpVector).SafeNormal;
			AddLookAtTarget(Direction, this);
		}


		//Camera Align to hitthingy
		/*
		if(Game::Mio.IsAnyCapabilityActive(n"GravityBladeCombatAttackState") && bActivateHitCamera)
		{
			Game::Mio.ActivateCamera(Camera, 2, this, EHazeCameraPriority::VeryHigh);
		}else{
			Game::Mio.DeactivateCamera(Camera, 2.0);		
		}
		*/
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false, true);
		for(auto AttachedActor : AttachedActors)
		{
			AttachedActor.RemoveActorDisable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false, true);
		for(auto AttachedActor : AttachedActors)
		{
			AttachedActor.AddActorDisable(this);
		}
	}

	UFUNCTION()
	private void HandleShieldBreak()
	{
		PrintToScreenScaled("Shield Break!", 2.0, FLinearColor::Green, 3.0);
	}

	UFUNCTION()
	private void HandleShieldRegenerate()
	{
		PrintToScreenScaled("Shield Regenerate!", 2.0, FLinearColor::Green, 3.0);
	}

	UFUNCTION()
	void Activate(FVector InitialVelocity = FVector::ZeroVector)
	{
		Velocity = InitialVelocity;
		RemoveActorDisable(this);
	}

	UFUNCTION()
	private void HandleImpact(FGravityWhipImpactData ImpactData)
	{
		if(ImpactData.ThrownActor != nullptr && ImpactData.ThrownActor.IsA(ABasicAICharacter))
			return;

		if (ImpactData.HitResult.Component == Shield)
		{
			Shield.DamageShield(ImpactData.HitResult.ImpactPoint, 0.4);
			FX_Shield.Deactivate();
		}

		FVector ToImpactPoint = ActorLocation - ImpactData.HitResult.ImpactPoint;

		AngularImpulse += ActorTransform.InverseTransformVectorNoScale(ImpactData.ImpactVelocity.SafeNormal.CrossProduct(ToImpactPoint.SafeNormal * 1.0));
		Impulse += ImpactData.ImpactVelocity.SafeNormal * 500.0;

		BP_OnDamaged();
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (HitData.Component != GravityBladeHitCollision)
			return;

		auto Instigator = Cast<AHazeActor>(CombatComp.Owner);
		HealthComponent.TakeDamage(0.2, EDamageType::Default, Instigator);

		USkylineAttackShipEventHandler::Trigger_OnWeakPointHit(this);
		BP_OnWeakPointDamaged();

		if (HealthComponent.CurrentHealth <= 0.0)
			Crash();

		PrintToScreenScaled("Health: " + HealthComponent.CurrentHealth, 2.0, FLinearColor::Green, 3.0);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Enrage();
	}

	UFUNCTION()
	void Crash()
	{
		if (bIsCrashing)
			return;
		
		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, ActorLocation, false, this, 15000, 18000, 1.0, 2.0, EHazeSelectPlayer::Both);
		HandleEjectPlayer();

		for (auto AttachedSpawner : AttachedSpawners)
			AttachedSpawner.DeactivateSpawner();

		PlayerInheritMovementComponent.DisableTrigger(this);

		BP_OnCrash();
		USkylineAttackShipEventHandler::Trigger_OnCrash(this);

		//UXR TEMP
		SetActorEnableCollision(false);
		

		if (TListedActors<ASkylineAttackShip>().Num() == 1)
		{
			Spline = CrashSpline;
			PrintToScreenScaled("LastAttackShip: " + Name, 2.0, FLinearColor::Green, 3.0);
			OnLastShipCrash.Broadcast();
		}
		
		bIsCrashing = true;
	}

	UFUNCTION()
	void Explode()
	{	
		
		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, ActorLocation, false, this, 10000, 18000, 1.0, 2.0, EHazeSelectPlayer::Both);
		BP_OnExplode();
		OnExplode.Broadcast();
	
		if (TListedActors<ASkylineAttackShip>().Num() == 1)
		{
			OnLastShipExplode.Broadcast();
			InterfaceComp.TriggerActivate();
		}

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto AttachedActor : AttachedActors)
			AttachedActor.AddActorDisable(this);

		AddActorDisable(this);
		LeaveTeam(n"SkylineAttackShips");		
	}

	UFUNCTION()
	void SetMoveToTarget(FVector TargetLocation)
	{
		MoveToTarget.Empty();
		MoveToTarget.Apply(TargetLocation, this);
	}

	UFUNCTION()
	void AddMoveToTarget(FVector TargetLocation, FInstigator Instigator)
	{
		MoveToTarget.Apply(TargetLocation, Instigator);
	}

	UFUNCTION()
	void ClearMoveToTarget(FInstigator Instigator)
	{
		MoveToTarget.Clear(Instigator);
	}

	UFUNCTION()
	void SetLookAtDirection(FVector Direction)
	{
		TargetDirection.Empty();
		TargetDirection.Apply(Direction, this);
	}

	UFUNCTION()
	void AddLookAtTarget(FVector Direction, FInstigator Instigator)
	{
		TargetDirection.Apply(Direction, Instigator);
	}

	UFUNCTION()
	void ClearLookAtTarget(FInstigator Instigator)
	{
		TargetDirection.Clear(Instigator);
	}

	UFUNCTION()
	void PrepareAttackReady()
	{
		AttackTarget.Apply(Game::Zoe, this); // TEMP
	
		bPreparingAttackReady = true;
		AttackReadyTime = Time::GameTimeSeconds + PreparingAttackReadyDelay;
	}

	UFUNCTION()
	void AttackReady()
	{
		if (HasControl())
			NetActivateSpawners();
	
		bAttackReady = true;

		AttackTarget.Apply(Game::Zoe, this); // TEMP

		PrintToScreenScaled("Attack Ready!", 2.0, FLinearColor::Green, 3.0);
	}

	UFUNCTION(NetFunction)
	void NetActivateSpawners()
	{
		for (auto AttachedSpawner : AttachedSpawners)
			AttachedSpawner.ActivateSpawner();
	}

	UFUNCTION()
	void Enrage()
	{
		for (auto AttachedSpawner : AttachedSpawners)
		{
			TArray<UActorComponent> ActorComponents = AttachedSpawner.GetComponentsByTag(UHazeActorSpawnPattern, EnragePatternTag);
			for (auto ActorComponent : ActorComponents)
			{
				auto SpawnPattern = Cast<UHazeActorSpawnPattern>(ActorComponent);
				if (SpawnPattern != nullptr)
					SpawnPattern.ActivatePattern(this);
			}
		}
	}

	void LaunchMissileAtTarget(AActor TargetActor = nullptr, FTransform WorldTransform = FTransform::Identity)
	{
		auto BrigeSegment = Cast<ASkylineInnerCityExplodingBridgeSegment>(TargetActor);
		if (BrigeSegment == nullptr)
			return;

		auto ProjectileLaunchers = GetComponentsByClass(USkylineAttackShipProjectileLauncherComponent);
		for (auto ProjectileLauncher : ProjectileLaunchers)
		{
			if (ProjectileLauncher.bLeftLauncher == bFireFromLeftLauncher)
			{
				auto Missile = SpawnActor(ShipProjectileClass, bDeferredSpawn = true);
				Missile.SplineMissileComp.OnImpact.AddUFunction(BrigeSegment, n"Explode");
				Missile.Target = BrigeSegment.ImpactTargetPivot.WorldTransform;
				Missile.TimeToImpact = BrigeSegment.ProjectileTimeToImpact;
				FTransform SpawnTransform;
				SpawnTransform.Location = ProjectileLauncher.WorldLocation;
				SpawnTransform.Rotation = ProjectileLauncher.ComponentQuat;
				FinishSpawningActor(Missile, SpawnTransform);

				BP_LaunchMissile(SpawnTransform.GetRelativeTransform(ActorTransform));
			}
		}

		bFireFromLeftLauncher = !bFireFromLeftLauncher;
	}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchMissile(FTransform LaunchTransform)
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnWeakPointDamaged()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnDamaged()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnCrash()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnExplode()
	{

	}

	UFUNCTION(DevFunction)
	void BreakShield()
	{
		Shield.DamageShield(Shield.WorldLocation, 100.0);
	}
	
	UFUNCTION(DevFunction)
	void ForceCrash()
	{
		Crash();
	}
};
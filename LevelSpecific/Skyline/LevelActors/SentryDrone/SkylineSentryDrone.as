class ASkylineSentryDrone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SetCollisionProfileName(n"BlockAllDynamic");
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);
	default Collision.SphereRadius = 50.0;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;
	default GravityBladeOutlineComponent.bAllowOutlineWhenNotPossibleTarget = false;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent AIHealthComponent;
	default AIHealthComponent.MaxHealth = 1.0;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::Drag;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneHoverCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneWhipDragCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneFallingCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneImpactCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneLookAtCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneMoveToCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneSplineFollowCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneStabilizeCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneDeathCapability");
//	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneAvoidanceCapability");

	// Turret Capabilities
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneTurretFireCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryDroneTurretTargetingCapability");

//	UPROPERTY(DefaultComponent)
//	UGravityWhipDebugComponent GravityWhipDebugComponent;

	UPROPERTY(EditAnywhere)
	bool bStartDisabled;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UHazeSplineComponent Spline;

	FVector AngularVelocity;

	TInstigated<AHazeActor> LookAtTarget;
	TInstigated<FVector> FollowTarget;

	bool bIsThrown;
	bool bHadImpact;
	bool bShouldStabilize;

	float DisableTime = 0.0;

	FVector Avoidance;

	TArray<UContextualMovesTargetableComponent> ContextualMoves;

	UPROPERTY(EditAnywhere)
	USkylineSentryDroneSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplyDefaultSettings(Settings);

		Settings = USkylineSentryDroneSettings::GetSettings(this);

		FollowTarget.Apply(ActorLocation, this, EInstigatePriority::Low);

		if (SplineActor != nullptr)
			Spline = SplineActor.Spline;

		SetupMovement();

		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"OnReleased");
		GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"OnThrown");

		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"OnBladeHit");

		AIHealthComponent.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		AIHealthComponent.OnDie.AddUFunction(this, n"OnDie");

		GravityWhipResponseComponent.GrabMode = Settings.GrabMode;
	//	LookAt(Game::Mio, this);

		// Get All ContextualMovesTargetableComponent
		GetComponentsByClass(ContextualMoves);

		if (!Settings.bContextualMoves)
			DisableContextualMoves(this);
	
		// Join BasicAITeam TEMP
		this.JoinTeam(n"BasicAITeam");
	
		if (bStartDisabled)
			Disable();
	}

	UFUNCTION()
	void Enable()
	{
		RemoveActorDisable(this);	
	}

	UFUNCTION()
	void Disable()
	{
		AddActorDisable(this);		
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		AIHealthComponent.TakeDamage(0.5, EDamageType::Default, this);
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		PrintToScreen("OnTakeDamage! " + AIHealthComponent.CurrentHealth, 1.0, FLinearColor::Green);
		// AIHealthComponent.IsDead();
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		PrintToScreen("OnDie! " + AIHealthComponent.CurrentHealth, 1.0, FLinearColor::Green);
		Explode();
	}

	UFUNCTION()
	void Explode()
	{
		USkylineSentryDroneEventHandler::Trigger_Explode(this);
		DestroyActor();
	}

	void DisableContextualMoves(FInstigator Instigator)
	{
		for (auto ContextualMove : ContextualMoves)
			ContextualMove.Disable(Instigator);		
	}

	void EnableContextualMoves(FInstigator Instigator)
	{
		for (auto ContextualMove : ContextualMoves)
			ContextualMove.Enable(Instigator);		
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		bIsThrown = false;
		bShouldStabilize = false;

		PrintToScreen("Grabbed!" + bShouldStabilize, 1.0, FLinearColor::Green);
	}

	UFUNCTION()
	private void OnReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
	//	GravityWhipTargetComponent.Disable(this);
	
		AngularVelocity += ActorTransform.InverseTransformVectorNoScale(FVector(0.0, 1.0, 0.5) * 30.0);

		SetActorVelocity(Impulse.GetSafeNormal() * Settings.SlingModeThrowSpeed);

		bIsThrown = true;
	}

	void LookAt(AHazeActor Target, FInstigator Instigator)
	{
		LookAtTarget.Apply(Target, Instigator);
	}

	void ClearLookAt(FInstigator Instigator)
	{
		LookAtTarget.Clear(Instigator);
	}

	void MoveToTarget(FVector Target, FInstigator Instigator)
	{
		FollowTarget.Apply(Target, Instigator);
	}

	void ClearMoveToTarget(FInstigator Instigator)
	{
		FollowTarget.Clear(Instigator);
	}

	void SetupMovement()
	{
		// Setup the resolver
		{
			UMovementResolverSettings::SetMaxRedirectIterations(this, 3, this, EHazeSettingsPriority::Defaults);
			UMovementResolverSettings::SetMaxDepenetrationIterations(this, 2, this, EHazeSettingsPriority::Defaults);
		}

		// Everything is sliding
		{
			UMovementStandardSettings::SetWalkableSlopeAngle(this, 0.0, this, EHazeSettingsPriority::Defaults);
		}

		// Set up ground trace
		// {
		// 	UMovementSweepingSettings::SetGroundedTraceDistance(this, FMovementSettingsValue::MakeValue(1.0), this, EHazeSettingsPriority::Defaults);
		// }
	}

	FQuat GetMovementRotation(float DeltaTime)
	{
		return ActorQuat * FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaTime);
	}

}
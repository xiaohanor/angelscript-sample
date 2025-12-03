event void FSkylineBossTankSignature();

enum ESkylineBossTankState
{
	Idle,
	Stunned,
	Spinning,
	Center
}

namespace ASkylineBossTank
{
	ASkylineBossTank Get()
	{
		return TListedActors<ASkylineBossTank>().Single;
	}
};

UCLASS(Abstract)
class ASkylineBossTank : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USkylineBossTankCrusherComponent CrusherComp;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USkylineBossTankTurretComponent TurretComp;

	UPROPERTY(DefaultComponent, Attach = TurretComp)
	USceneComponent TargetSpotlightPivot;

	UPROPERTY(DefaultComponent, Attach = TargetSpotlightPivot)
	USceneComponent TargetSpotlightVisualPivot;

	UPROPERTY(DefaultComponent)
	USkylineBossTankExhaustBeamComponent ExhaustBeamComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent CrusherCollision;
	default CrusherCollision.CollisionEnabled = ECollisionEnabled::NoCollision;
	default CrusherCollision.bGenerateOverlapEvents = false;
	FCollisionShape CrusherCollisionShape;

	UPROPERTY(DefaultComponent)
	UBoxComponent WeakPointCollision;
	default WeakPointCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default WeakPointCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default WeakPointCollision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponTargetableComponent WeaponTargetableComp;

	UPROPERTY(DefaultComponent, Attach = WeaponTargetableComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent ProjectileResponseComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;
	default HealthComp.MaxHealth = 280.0; // 220.0 // 120.0

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)	
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USkylineBossTankCompoundCapability);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::Standard;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	USkylineBossTankCenterViewTargetComponent CenterViewTargetComp;

	UPROPERTY(DefaultComponent)
	UDecalComponent TargetDecal;

	UPROPERTY(DefaultComponent)
	USpotLightComponent TargetSpotLight;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(DefaultComponent)
	USkylineBossTankDeathDamageComponent DeathDamageComp;

	UPROPERTY(EditInstanceOnly)
	AActor FollowSpline;

	UPROPERTY(EditInstanceOnly)
	ASkylineBossSplineHub Hub;

	UPROPERTY(EditInstanceOnly)
	ASkylineBossTankRespawnSpline RespawnSpline;

	UPROPERTY(EditAnywhere)
	float Speed = 3500.0;
	TInstigated<float> InstigatedSpeed;

	FVector Force;
	FVector Torque;

	FVector Velocity;
	FVector AngularVelocity;

	float Drag = 4.0;
	float AngularDrag = 4.0;

	UPROPERTY(EditAnywhere)
	float MaxTurnRate = 12.0; // 6.0

	UPROPERTY(EditAnywhere)
	AActor ConstraintRadiusOrigin;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UHazeUserWidget> DangerWidgetClass;

	UPROPERTY(EditAnywhere)
	UMaterialInterface DangerDecalMaterial;

	UPROPERTY(EditAnywhere)
	float ConstraintRadius = 12000.0;

	bool bIsDefeated = false;

	UPROPERTY(EditAnywhere)
	UMaterialInterface HealthLightMaterial;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	UMaterialInstanceDynamic HealthLightMID;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor MaxHealthColor = FLinearColor::Green;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor MinHealthColor = FLinearColor::Red;

	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer StartTarget = EHazeSelectPlayer::Mio;

	UPROPERTY(EditAnywhere)
	float StunDuration = 0.0; // 6.0

	UPROPERTY()
	FSkylineBossTankSignature OnDie;

	UPROPERTY()
	FSkylineBossTankSignature OnAssemble;

	UPROPERTY()
	FSkylineBossTankSignature OnStun;

	UPROPERTY()
	FSkylineBossTankSignature OnHeroAttack;

	UPROPERTY()
	FSkylineBossTankSignature OnEnrage;

	UPROPERTY()
	FSkylineBossTankSignature OnChase;

	UPROPERTY()
	FSkylineBossTankSignature OnEngineStart;

	UPROPERTY()
	FSkylineBossTankSignature OnEngineStop;

	UPROPERTY()
	FSkylineBossTankSignature OnProgressPointReached;

	UPROPERTY(EditAnywhere)
	UMaterialParameterCollection GlobalParametersVFX;

	UPROPERTY(EditInstanceOnly)
	ASkylineBikeTowerEnemyShip SupportShipMio;

	UPROPERTY(EditInstanceOnly)
	ASkylineBikeTowerEnemyShip SupportShipZoe;

	private AHazeActor AttackTarget;

	bool bCrusherActive = false;
	float CrusherTargetSpeed = 400.0;
	FHazeAcceleratedFloat CrusherSpeed;

	bool bProgressPointReached = false;

	//	Exhaust Attack
	UPROPERTY(BlueprintReadOnly)
	float SpinningAlpha = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float ExhaustBeamLength = 0.0;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	USceneComponent ExhaustBeamImpact;

	UPROPERTY(DefaultComponent)
	USkylineBossTankLightComponent LightComp;

	UPROPERTY(DefaultComponent)
	USkylineBossTankLightComponent ExhaustLightComp;

	UPROPERTY(DefaultComponent)
	USkylineBossTankLightComponent SensorLightComp;

	UPROPERTY(DefaultComponent)
	USkylineBossTankSplineFollowComponent SplineFollowComp;

	UPROPERTY(DefaultComponent)
	USkylineBossTankFollowTargetComponent FollowTargetComp;

	UPROPERTY(DefaultComponent)
	USkylineBossTankTracksComponent LeftTracksComp;

	UPROPERTY(DefaultComponent)
	USkylineBossTankTracksComponent RightTracksComp;

	float ChangeTargetDamagePercentage = 0.33; // 0.25
	float DamageThreshold = 0.0;

	TInstigated<ESkylineBossTankState> State;
	default State.DefaultValue = ESkylineBossTankState::Idle;

	TInstigated<float> MainAttackInterval;
	default MainAttackInterval.DefaultValue = 0.8; // 2.5

	TInstigated<bool> MainAttackAlternateTarget;
	default MainAttackAlternateTarget.DefaultValue = false;

	AHazeActor LatestDamageInstigator;

	float TargetChangeTime = 0.0;
	AHazeActor TargetToChangeTo;

	private float TutorialStartTime = 0;
	private AGravityBikeFree CenterViewTutorialTarget = nullptr;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SetActorEnableCollision(false);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		InstigatedSpeed.Apply(Speed, this);

		Material::SetVectorParameterValue(GlobalParametersVFX, n"SphereMaskOffsetTank", FLinearColor(ConstraintRadiusOrigin.ActorLocation.X, ConstraintRadiusOrigin.ActorLocation.Y, ConstraintRadiusOrigin.ActorLocation.Z, 1.0));
		AddActorDisable(this);

		DamageThreshold = 1.0 - ChangeTargetDamagePercentage;

		TArray<UPrimitiveComponent> PrimitiveComps;
		GetComponentsByClass(PrimitiveComps);

		for (auto PrimitiveComp : PrimitiveComps)
			PrimitiveComp.SetReceivesDecals(false);

		SetActorEnableCollision(true);

		CrusherCollisionShape = CrusherCollision.GetCollisionShape();
		HealthLightMID = Material::CreateDynamicMaterialInstance(this, HealthLightMaterial);

		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);
	
		ProjectileResponseComp.OnImpact.AddUFunction(this, n"HandleProjectileImpact");

		TutorialStartTime = Time::GameTimeSeconds + 2;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreen("Speed: " + InstigatedSpeed.Get(), 0.0, FLinearColor::LucBlue);
//		Debug::DrawDebugSphere(ActorLocation, 8000.0, 24, FLinearColor::Red, 10.0, 0.0);

		UpdateHealthLight();

		CrusherSpeed.AccelerateTo((bCrusherActive ? CrusherTargetSpeed : 0.0), 3.0, DeltaSeconds);

		CrusherComp.Spin += CrusherSpeed.Value * DeltaSeconds;

//		CrusherComp.AddLocalRotation(FRotator(-CrusherSpeed.Value * DeltaSeconds, 0.0, 0.0));

		for (auto Player : Game::Players)
		{
			if (Shape::IsPointInside(CrusherCollisionShape, CrusherCollision.WorldTransform, Player.ActorCenterLocation))
			{
				FVector Direction = (Player.ActorLocation - ActorLocation).GetSafeNormal();
				Player.KillPlayer(FPlayerDeathDamageParams(Direction, 10.0, bCanUseDeathCamera = false), DeathDamageComp.LargeObjectDeathEffect);
			}	
		}

		if(CenterView::bShowTutorialDuringTankBoss && Time::GameTimeSeconds > TutorialStartTime)
		{
			auto BikeTarget = Cast<AGravityBikeFree>(GetAttackTarget());
			if(CenterViewTutorialTarget != BikeTarget)
			{
				if(CenterViewTutorialTarget != nullptr)
					CenterView::RemoveCenterViewTargetTutorial(CenterViewTutorialTarget.GetDriver(), this);
				
				CenterView::ShowCenterViewTargetTutorial(BikeTarget.GetDriver(), this);

				CenterViewTutorialTarget = BikeTarget;
			}
		}
	}

	void UpdateHealthLight()
	{
		if (HealthComp.GetHealthFraction() <= 0.0)
		{
			HealthLightMID.SetVectorParameterValue(n"EmissiveColor", FLinearColor::Black);
			return;
		}

		float Alpha = HealthComp.GetHealthFraction();
		FLinearColor HealthLightColor = Math::Lerp(MinHealthColor, MaxHealthColor, Alpha);
		HealthLightColor *= ((Math::Sin(Time::GameTimeSeconds * 16.0 * (1.0 - Alpha)) + 1.0) * 0.5) * 10.0;
		HealthLightMID.SetVectorParameterValue(n"EmissiveColor", HealthLightColor);
	}

	UFUNCTION()
	void ActivateBossTank()
	{
		RemoveActorDisable(this);
	}

	UFUNCTION()
	void SetTankProgressPointState()
	{
		bProgressPointReached = true;
		HealthComp.SetCurrentHealth(HealthComp.MaxHealth * 0.5);
		DamageThreshold = ChangeTargetDamagePercentage;
	}

	UFUNCTION()
	private void HandleProjectileImpact(FGravityBikeWeaponImpactData ImpactData)
	{
		if (bIsDefeated || State.Get() == ESkylineBossTankState::Stunned)
			return;

//		if (ImpactData.HitComponent == WeakPointCollision)
			HealthComp.TakeDamage(ImpactData.Damage, EDamageType::Default, ImpactData.Instigator);

		if(HasControl())
		{
			if (!bIsDefeated && HealthComp.CurrentHealth <= 0.0)
				CrumbDie();

			if (!bProgressPointReached && HealthComp.GetHealthFraction() <= 0.5)
				CrumbReachProgressPoint();

			if (State.Get() != ESkylineBossTankState::Center && HealthComp.GetHealthFraction() < 0.25)
				CrumbChangeStateToCenter();
		}
/*
		else if ((State.Get() != ESkylineBossTankState::Center) && HealthComp.GetHealthFraction() < DamageThreshold)
		{
			State.Apply(ESkylineBossTankState::Stunned, this);
			DamageThreshold = HealthComp.GetHealthFraction() - ChangeTargetDamagePercentage;
		}
*/
		auto DamagingPlayer = Cast<AHazePlayerCharacter>(ImpactData.Instigator);
		if (DamagingPlayer != nullptr)
		{
			FSkylineBossTankEventData Data;
			Data.Player = DamagingPlayer;
			USkylineBossTankEventHandler::Trigger_DamagingTank(this, Data);
		}

		LatestDamageInstigator = ImpactData.Instigator;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDie()
	{
		Die();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReachProgressPoint()
	{
		bProgressPointReached = true;
		OnProgressPointReached.Broadcast();
		ActivateSupportShipForPlayer(SupportShipMio, Game::Mio);
		ActivateSupportShipForPlayer(SupportShipZoe, Game::Zoe);
		USkylineBossTankEventHandler::Trigger_AttackShipArrive(this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbChangeStateToCenter()
	{
		State.Apply(ESkylineBossTankState::Center, this, EInstigatePriority::High);
	}

	UFUNCTION()
	private void HandleMortarBallImpact(FVector Location, FVector Normal)
	{
		auto ClosestPlayer = Game::GetClosestPlayer(Location);

		float DistanceThreshold = 4000.0;

		if (ClosestPlayer.ActorLocation.Distance(Location) > DistanceThreshold)
			return;

		PrintToScreen("MortarJump", 1.0);

		FSkylineBossTankEventData Data;
		Data.Player = ClosestPlayer;
		USkylineBossTankEventHandler::Trigger_OnTankMortarBallImpact(this, Data);
	}

	void SetTargetChange(AHazeActor Target, float Delay)
	{
		TargetChangeTime = Time::GameTimeSeconds + Delay;
		TargetToChangeTo = Target;
	}

	UFUNCTION(DevFunction)
	void Die()
	{
		if(!ensure(!bIsDefeated))
			return;

		bIsDefeated = true;
		
		WeaponTargetableComp.Disable(this);
		USkylineBossTankEventHandler::Trigger_OnDie(this);
		OnDie.Broadcast();

		for(auto Player : Game::Players)
			CenterView::RemoveCenterViewTargetTutorial(Player, this);
	}

	UFUNCTION()
	void ClearFire()
	{
		auto MortarBallComp = USkylineBossTankMortarBallComponent::Get(this);
		if (MortarBallComp != nullptr)
			MortarBallComp.ClearFire();
	}

	UFUNCTION()
	void EnableWeakPoint()
	{
		WeaponTargetableComp.Enable(this);
		BP_OnWeakPointEnabled();
	}

	UFUNCTION()
	void DisableWeakPoint()
	{
		WeaponTargetableComp.Disable(this);
		BP_OnWeakPointDisabled();
	}

	UFUNCTION()
	void SetCrusherActive(bool bActive)
	{
		bCrusherActive = bActive;

		if (bCrusherActive)
			BP_OnCrusherStart();
		else
			BP_OnCrusherStop();
	}

	bool HasAttackTarget() const
	{
		if(!IsValid(AttackTarget))
			return false;

		return true;
	}

	AHazeActor GetAttackTarget() const
	{
		return AttackTarget;
	}

	UFUNCTION(BlueprintCallable)
	void SetTarget(AHazeActor Target)
	{
		if(!HasControl())
			return;

		if(Target == GetAttackTarget())
			return;

		CrumbSetTarget(Target);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetTarget(AHazeActor Target)
	{
		AGravityBikeFree BikeTarget = GetBikeFromTarget(Target);
		AttackTarget = BikeTarget;
	}

	UFUNCTION()
	void ActivateSupportShipForPlayer(ASkylineBikeTowerEnemyShip Ship, AHazePlayerCharacter Player)
	{
		if (Ship == nullptr)
			return;

		Ship.OnDieFromInstigator.AddUFunction(this, n"HandleSupportShipDeath");

		FTransform TargetTransform;

		FVector ViewDirection = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).SafeNormal;

		FVector Origin = ConstraintRadiusOrigin.ActorLocation;
		FVector Start = FVector(Player.ViewLocation.X, Player.ViewLocation.Y, Origin.Z);

		auto Points = Math::GetLineSegmentSphereIntersectionPoints(Start, Start + ViewDirection * 1000000.0, Origin, 35000.0);

		FVector Location = Points.MinIntersection;

		TargetTransform.Location = Location - FVector::UpVector * 2000.0;
		TargetTransform.Rotation = (Player.ViewLocation - Location).ToOrientationQuat();

		Ship.Velocity += (FVector::UpVector * 5000.0) - (TargetTransform.Rotation.ForwardVector * 5000);

		Ship.TeleportToTransform(TargetTransform);
	}

	UFUNCTION()
	private void HandleSupportShipDeath(AHazeActor Instigator)
	{
		auto Player = Cast<AHazePlayerCharacter>(Instigator);
		if (Player == nullptr)
			return;
	
		FSkylineBossTankEventData Data;
		Data.Player = Player;
		USkylineBossTankEventHandler::Trigger_AttackShipDestroyed(this, Data);
	}

	AGravityBikeFree GetBikeFromTarget(AHazeActor Target)
	{
		auto GravityBikeFree = Cast<AGravityBikeFree>(Target);
		if (GravityBikeFree != nullptr)
			return GravityBikeFree;

		auto DriverComp = UGravityBikeFreeDriverComponent::Get(Target);
		if (DriverComp != nullptr)
		{
			return DriverComp.GetGravityBike();
		}

		return nullptr;
	}

	AGravityBikeFree GetOtherBike(AHazeActor Target)
	{
		auto GravityBikeFree = Cast<AGravityBikeFree>(Target);
		if (GravityBikeFree == nullptr)
			return nullptr;

		auto DriverComp = UGravityBikeFreeDriverComponent::Get(GravityBikeFree.GetDriver().OtherPlayer);
		if (DriverComp != nullptr)
		{
			return DriverComp.GetGravityBike();
		}

		return nullptr;
	}

	bool HasValidTargetPlayer()
	{
		if (!HasAttackTarget())
			return false;

		auto GravityBikeFree = Cast<AGravityBikeFree>(GetAttackTarget());
		if (GravityBikeFree != nullptr)
			return !GravityBikeFree.GetDriver().IsPlayerDead();

		auto Player = Cast<AHazePlayerCharacter>(GetAttackTarget());
		if (Player != nullptr)
			return !Player.IsPlayerDead();

		return false;
	}

	UFUNCTION(DevFunction)
	void DevStun()
	{
		State.Apply(ESkylineBossTankState::Stunned, this);
	}

	UFUNCTION(DevFunction)
	void DevCenter()
	{
		State.Apply(ESkylineBossTankState::Center, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnWeakPointEnabled() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnWeakPointDisabled() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnEngineStart() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnEngineStop() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnCrusherStart() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnCrusherStop() {}

	FVector ConsumeForce()
	{
		FVector _Force = Force;
		Force = FVector::ZeroVector;

		return _Force;
	}

	FVector ConsumeTorque()
	{
		FVector _Torque = Torque;
		Torque = FVector::ZeroVector;

		return _Torque;
	}

	float GetMaxSpeed() property
	{
		return InstigatedSpeed.Get() * Drag;
	}

	float GetMaxTurnSpeed() property
	{
		return MaxTurnRate;
	}
};
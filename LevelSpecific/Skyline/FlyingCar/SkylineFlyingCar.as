event void FSkylineFlyingCarCollisionEvent(FSkylineFlyingCarCollision Collision);

UCLASS(Abstract)
class ASkylineFlyingCar : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	access Resolver = private, USkylineFlyingCarMovementResolver;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeOffsetComponent MeshOffset;
	default	MeshOffset.SetRelativeLocation(-FVector::UpVector * 110); // Add offset for proper roll

	UPROPERTY(DefaultComponent, Attach = MeshOffset)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent VFXRoot;

	UPROPERTY(DefaultComponent, Attach = VFXRoot)
	USceneComponent GroundSparksRoot;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent PilotSeat;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent PassengerSeat;


	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FakeCar;

	UPROPERTY(DefaultComponent, Attach = FakeCar)
	UHazeSkeletalMeshComponentBase FakeZoe;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "Base")
	UHazeSkeletalMeshComponentBase FakeMio;

	UPROPERTY(DefaultComponent, Attach = FakeCar)
	USkylineFlyingCarGunPivotComponent GunPivot;

	UPROPERTY(DefaultComponent, Attach = GunPivot) 
	USkylineFlyingCarGunRootComponent GunRoot;

	UPROPERTY(DefaultComponent, Attach = GunRoot)
	USceneComponent GunnerSeat;


	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent PlayerCapabilityComponent;

	UPROPERTY(DefaultComponent) 
	UHazeMovementComponent MovementComponent;
	default MovementComponent.bConstrainRotationToHorizontalPlane = false;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalScrubComp;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarHealthComponent HealthComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncedPositionComponent;
	default CrumbSyncedPositionComponent.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;
	default CrumbSyncedPositionComponent.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent CrumbedMeshRotation;
	default CrumbedMeshRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);


	UPROPERTY(DefaultComponent)
	UFlyingCarOfficeAssistedJumpComponent OfficeAssistedJumpComponent;

	UPROPERTY(DefaultComponent)
	UFlyingCarOfficeCrashComponent OfficeCrashComponent;


	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComponent;


#if EDITOR
	UHazeImmediateDrawer DebugDrawer;
	FString DebugCameraSettingsText = "";
#endif
	
	UPROPERTY(Category=Gunner)
	TSubclassOf<ASkylineFlyingCarGun> GunClass;

	UPROPERTY(EditInstanceOnly)
	ASkylineFlyingHighway StartHighway;

	UPROPERTY(EditAnywhere)
	USkylineFlyingCarGotySettings DefaultSettings;


	UPROPERTY(EditAnywhere, Category = "Camera")
	TSubclassOf<UCameraShakeBase> LightCollisionCameraShake;

	UPROPERTY(EditAnywhere, Category = "Camera")
	TSubclassOf<UCameraShakeBase> FatalCollisionCameraShake;

	UPROPERTY(EditAnywhere, Category = "Camera")
	TSubclassOf<UCameraShakeBase> GroundMovementCameraShake;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect ImpactForceFeedback;


	UPROPERTY(Category = "VFX")
	UNiagaraSystem CameraWeatherEffect;


	UPROPERTY()
	FSkylineFlyingCarCollisionEvent OnCollision;


	ASkylineFlyingHighway InternalHighway;
	bool bSelectNewHighwayIsblockedUntilCurrentIsReached = false;
	float TimeSinceLastHighwaySwitch = 0;

	AHazePlayerCharacter CurrentPilot;
	AHazePlayerCharacter CurrentGunner;
	ASkylineFlyingCarGun Gun;

	private TInstigated<bool> InstigatedCanManeuver;
	default InstigatedCanManeuver.SetDefaultValue(true);

	bool bHasHouseConnection = false;

	access FreeMovement = private, USkylineFlyingCarGotyFreeMovementCapability;
	access : FreeMovement
	bool bIsFreeFyling = false;

	access Dash = private, USkylineFlyingCarGotyDashCapability;
	access : Dash
	bool bIsSplineDashing = false;

	access Hop = private, USkylineFlyingCarGotySplineHopCapability, USkylineFlyingCarGotySplineRampJumpCapability;
	access : Hop
	bool bIsSplineHopping = false;
	bool bJustSplineHopped = false;

	access SplineMovement = private, USkylineFlyingCarGotySplineMovementCapability;
	access : SplineMovement
	bool bCloseToSplineEdge = false;

	access SplineRamp = private, USkylineFlyingCarGotySplineRampMovementCapability, USkylineFlyingCarGotySplineRampJumpCapability;
	access : SplineRamp bool bInSplineRamp;
	access : SplineRamp bool bSplineRampJump;

	float YawInput = 0;
	float PitchInput = 0;
	float BoostAcceleration = 0;
	bool bWasJumpActionStarted = false;

	float FakeRotationValue = 0.2;

	private bool bCarExploding = false;

	bool bTunnelHopRoll = false;

	FHazeAcceleratedRotator AccFakeRot;
	FQuat MeshRootRotationOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		
		#if EDITOR
		DebugDrawer = DevMenu::RequestImmediateDevMenu(n"FlyingCar", "???");
		#endif

		UMovementResolverSettings::SetMaxRedirectIterations(this, 5, this);
		UMovementResolverSettings::SetMaxDepenetrationIterations(this, 2, this);

		MovementComponent.SetupShapeComponent(SphereCollision);

		if(StartHighway != nullptr)
		{	
			SetActiveHighway(StartHighway);
		}

		if(DefaultSettings != nullptr)
		{
			ApplySettings(DefaultSettings, this, EHazeSettingsPriority::Defaults);
		}

		//UMovementSweepingSettings::SetGroundedTraceDistance(this, FMovementSettingsValue::MakeValue(10.0), this, EHazeSettingsPriority::Defaults);

		// Eman TOOD: Pwn this! We are using player instead
		Gun = SpawnActor(GunClass, bDeferredSpawn = true, Level = this.Level);
		Gun.CarOwner = this;
		GunRoot.Gun = Gun;
		FinishSpawningActor(Gun, FTransform(GunRoot.GetWorldRotation(), GunRoot.GetWorldLocation()));

		HealthComponent.OnCarExplosion.AddUFunction(this, n"OnCarExploded");
		HealthComponent.OnCarRespawn.AddUFunction(this, n"OnCarRespawn");

		//Hide FakeCar for Zoe
		FakeCar.SetRenderedForPlayer(Game::Zoe, false);
		FakeZoe.SetRenderedForPlayer(Game::Zoe, false);
		FakeMio.SetRenderedForPlayer(Game::Mio, false);

		AccFakeRot.SnapTo(Mesh.WorldRotation);
	}

	UFUNCTION()
	void SetActiveHighway(ASkylineFlyingHighway NewHighway)
	{
		if(InternalHighway != nullptr && NewHighway == nullptr)
			USkylineFlyingCarEventHandler::Trigger_OnCarExitHighway(this);

		else if(InternalHighway == nullptr && NewHighway != nullptr)
			USkylineFlyingCarEventHandler::Trigger_OnCarEnterHighway(this);

		InternalHighway = NewHighway; 
		if (InternalHighway != nullptr)
		{
			bSelectNewHighwayIsblockedUntilCurrentIsReached = true;
			TimeSinceLastHighwaySwitch = 0;
		}
		else
		{
			bSelectNewHighwayIsblockedUntilCurrentIsReached = false;
		}
	}

	UFUNCTION()
	void GunnerPopIn()
	{
		if (Gunner != nullptr)
		{
			USkylineFlyingCarGunnerComponent GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Gunner);
			if (GunnerComponent != nullptr)
			{
				GunnerComponent.PopIn();
			}
		}
	}

	UFUNCTION()
	void GunnerPopOut(EFlyingCarGunnerState Weapon = EFlyingCarGunnerState::Rifle)
	{
		if (Gunner != nullptr)
		{
			USkylineFlyingCarGunnerComponent GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Gunner);
			if (GunnerComponent != nullptr)
			{
				GunnerComponent.PopOut(Weapon);
			}
		}
	}

	UFUNCTION()
	void SwitchWeaponToBazooka()
	{
		if (Gunner != nullptr)
		{
			USkylineFlyingCarGunnerComponent GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Gunner);
			if (GunnerComponent != nullptr)
			{
				GunnerComponent.SetGunnerState(EFlyingCarGunnerState::Bazooka);
			}
		}
	}

	UFUNCTION(BlueprintPure)
	ASkylineFlyingHighway GetActiveHighway() const property
	{
		return InternalHighway;
	}

	bool CanLeaveHighway() const
	{
		if (ActiveHighway == nullptr)
			return false;

		if (!ActiveHighway.bCanBoostAwayFromHighway)
			return false;

		FSkylineFlyingCarSplineParams SplineParams;
		if (!GetSplineDataAtPosition(ActorLocation, SplineParams))
			return false;

		// Can only exit when close to the edge
		// if (SplineParams.SplineVerticalDistanceAlphaUnclamped < DefaultSettings.SplineHoppingFraction)
		// 	return false;

		// Can only exit when on top of highway
		// float AngularDistance = Math::RadiansToDegrees(SplineParams.DirToSpline.AngularDistanceForNormals(-MovementWorldUp));
		// if (AngularDistance > DefaultSettings.SplineHoppingAngle)
		// 	return false;

		return true;
	}

	FRotator TurnTowards(FVector Direction, float Speed, float DeltaTime)
	{
		FQuat TargetRotation = FQuat::MakeFromX(Direction);
		FQuat CurrentRotation = ActorQuat;
		return FQuat::Slerp(CurrentRotation, TargetRotation, Speed * DeltaTime).Rotator();
	}

	float RotateAxisTowardTargetWithDelta(float Current, float Desired, float DeltaRate)	
	{
		if (DeltaRate == 0.0)
		{
			return FRotator::ClampAxis(Current);
		}

		if (DeltaRate >= 360.0)
		{
			return FRotator::ClampAxis(Desired);
		}

		float Result = FRotator::ClampAxis(Current);
		const float InCurrent = Result;
		const float InDesired = FRotator::ClampAxis(Desired);

		if (InCurrent > InDesired)
		{
			if (InCurrent - InDesired < 180.0)
				Result -= Math::Min((InCurrent - InDesired), Math::Abs(DeltaRate));
			else
				Result += Math::Min((InDesired + 360.0 - InCurrent), Math::Abs(DeltaRate));
		}
		else
		{
			if (InDesired - InCurrent < 180.0)
				Result += Math::Min((InDesired - InCurrent), Math::Abs(DeltaRate));
			else
				Result -= Math::Min((InCurrent + 360.0 - InDesired), Math::Abs(DeltaRate));
		}
		return FRotator::ClampAxis(Result);
	}

	bool GetSplineDataAtPosition(FVector Location, FSkylineFlyingCarSplineParams& Out) const
	{
		if(ActiveHighway == nullptr || ActiveHighway.HighwaySpline == nullptr)
			return false;

		UHazeSplineComponent CurrentSpline = ActiveHighway.HighwaySpline;
		FSplinePosition SplinePosition = CurrentSpline.GetClosestSplinePositionToWorldLocation(Location);

		FVector DirToPosition = (SplinePosition.WorldLocation - Location);

		FSplinePosition TryEndOfSplineSplinePosition = SplinePosition;

		FSkylineFlyingCarSplineParams SplineParams;
		SplineParams.HighWay = ActiveHighway;
		SplineParams.SplinePosition = SplinePosition;
		SplineParams.SplineCenterDistance = SplinePosition.WorldLocation.Distance(Location);
		SplineParams.DirToSpline = DirToPosition.VectorPlaneProject(SplinePosition.WorldForwardVector).GetSafeNormal();
		SplineParams.bHasReachedEndOfSpline = !TryEndOfSplineSplinePosition.Move(10.0);

		if (ActiveHighway.MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Tunnel)
		{
			SplineParams.SplineHorizontalDistanceAlphaUnclamped = SplineParams.SplineCenterDistance / ActiveHighway.TunnelRadius;
			SplineParams.SplineVerticalDistanceAlphaUnclamped = SplineParams.SplineHorizontalDistanceAlphaUnclamped;
		}
		else if (ActiveHighway.MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Corridor)
		{
			SplineParams.SplineHorizontalDistanceAlphaUnclamped = DirToPosition.ConstrainToDirection(SplinePosition.WorldRightVector).Size() / ActiveHighway.CorridorWidth;
			SplineParams.SplineVerticalDistanceAlphaUnclamped = DirToPosition.ConstrainToDirection(SplinePosition.WorldUpVector).Size() / ActiveHighway.CorridorHeight;
		}

		Out = SplineParams;
		return true;
	}

	UFUNCTION()
	void ExplodeCar(FHitResult Collision)
	{
		if (bCarExploding)
			return;

		// Max damage to car, ignoring invincibility
		FSkylineFlyingCarDamage Damage;
		Damage.Amount = BIG_NUMBER;
		HealthComponent.TakeDamage(Damage, true);

		// Activate special death camera
		if (Collision.Actor != nullptr)
			SetupAndApplyDeathCamera(Collision);
	}

	/**@LerpSpeed; higher value == faster applied settings */
	UFUNCTION()
	void ApplyPilotCameraSettings(USkylineFylingCarPilotCameraComposableSettings SplineCameraSettings, 
		ESkylineFlyingCarMovementMode Type, 
		FInstigator Instigator, 
		float LerpSpeed = 5.0,
		EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		if(SplineCameraSettings == nullptr)
		{
			devError("ApplyPilotCameraSettings was called with a nullptr for SplineCameraSettings. If you want to clear the settings, use, ClearPilotCameraSettings");
			return;
		}

		if(CurrentPilot == nullptr)
		{
			devError("ApplyPilotCameraSettings was called with a nullptr as pilot. You need to apply a pilot first");
			return;
		}

		auto PilotComp = USkylineFlyingCarPilotComponent::Get(CurrentPilot);
		if(Type == ESkylineFlyingCarMovementMode::Free)
		{
			PilotComp.FreeFlyCameraSettingsData.PreviousCameraSettings = PilotComp.FreeFlyCameraSettings.Get();
			PilotComp.FreeFlyCameraSettingsData.ActiveAlpha = 0.0;
			PilotComp.FreeFlyCameraSettingsData.AlphaIncreaseSpeed = LerpSpeed;
			PilotComp.FreeFlyCameraSettings.Apply(SplineCameraSettings, Instigator, Priority);
		}
		else if(Type == ESkylineFlyingCarMovementMode::Spline)
		{
			PilotComp.SplineFollowCameraSettingsData.PreviousCameraSettings = PilotComp.SplineFollowCameraSettings.Get();
			PilotComp.SplineFollowCameraSettingsData.ActiveAlpha = 0.0;
			PilotComp.SplineFollowCameraSettingsData.AlphaIncreaseSpeed = LerpSpeed;
			PilotComp.SplineFollowCameraSettings.Apply(SplineCameraSettings, Instigator, Priority);
		}
		else if(Type == ESkylineFlyingCarMovementMode::Tunnel)
		{
			PilotComp.SplineTunnelCameraSettingsSettingsData.PreviousCameraSettings = PilotComp.SplineTunnelCameraSettings.Get();
			PilotComp.SplineTunnelCameraSettingsSettingsData.ActiveAlpha = 0.0;
			PilotComp.SplineTunnelCameraSettingsSettingsData.AlphaIncreaseSpeed = LerpSpeed;
			PilotComp.SplineTunnelCameraSettings.Apply(SplineCameraSettings, Instigator, Priority);
		}
	}

	UFUNCTION()
	void ClearPilotCameraSettings(ESkylineFlyingCarMovementMode Type, FInstigator Instigator)
	{
		if(CurrentPilot == nullptr)
			return;

		auto PilotComp = USkylineFlyingCarPilotComponent::Get(CurrentPilot);
		if(Type == ESkylineFlyingCarMovementMode::Free)
			PilotComp.FreeFlyCameraSettings.Clear(Instigator);
		else if(Type == ESkylineFlyingCarMovementMode::Spline)
			PilotComp.SplineFollowCameraSettings.Clear(Instigator);
		else if(Type == ESkylineFlyingCarMovementMode::Tunnel)
			PilotComp.SplineTunnelCameraSettings.Clear(Instigator);
	}

	// Attaches camera if car collided with something moving its way
	private void SetupAndApplyDeathCamera(FHitResult Collision)
	{
		AHazeActor Actor = Cast<AHazeActor>(Collision.Actor);
		if (Actor != nullptr)
		{
			FVector Velocity;
			if (Actor.TryGetRawLastFrameTranslationVelocity(Velocity))
			{
				if (!ActorVelocity.IsNearlyZero() && ActorVelocity.DotProductNormalized(Velocity) < 0)
				{
					UHazeCameraComponent DeathCamera = UHazeCameraComponent::GetOrCreate(Actor, n"MovingCollisionDeathCamera");

					for (auto Player : Game::Players)
					{
						float IdealDistance = UCameraSettings::GetSettings(Player).IdealDistance.Value;
						FVector CameraLocation = Collision.ImpactPoint + Collision.ImpactNormal * IdealDistance * 0.5;
						DeathCamera.SetWorldLocation(CameraLocation);

						DeathCamera.SetWorldRotation((ActorLocation - Collision.Location).Rotation());

						Player.ActivateCamera(DeathCamera, 3, this, EHazeCameraPriority::High);
					}
				}
			}
		}
	}

	// Block special moveset, i.e. dash and spline hopping
	UFUNCTION()
	void ApplyManeuverBlock(FInstigator Instigator)
	{
		InstigatedCanManeuver.Apply(false, Instigator);
	}

	UFUNCTION()
	void ClearManeuverBlock(FInstigator Instigator)
	{
		InstigatedCanManeuver.Clear(Instigator);
	}

	// Can execute special moveset, i.e. dash and spline hopping
	UFUNCTION()
	bool CanManeuver() const
	{
		return InstigatedCanManeuver.Get();
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetPilot() const property
	{
		return CurrentPilot;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetGunner() const property
	{
		return CurrentGunner;
	}

	UFUNCTION(BlueprintPure)
	ASkylineFlyingCarGun GetGun() const
	{
		return Gun;
	}

	UFUNCTION(BlueprintPure)
	bool IsFreeFlying() const
	{
		return bIsFreeFyling;
	}

	UFUNCTION(BlueprintPure)
	bool IsSplineDashing() const
	{
		return bIsSplineDashing;
	}

	UFUNCTION(BlueprintPure)
	bool IsSplineHopping() const
	{
		return bIsSplineHopping;
	}

	UFUNCTION(BlueprintPure)
	bool IsInSplineRamp() const
	{
		return bInSplineRamp;
	}

	UFUNCTION(BlueprintPure)
	bool IsJumpingFromSplineRamp() const
	{
		return bSplineRampJump;
	}

	UFUNCTION(BlueprintPure)
	bool IsInSplineTunnel() const
	{
		if (ActiveHighway == nullptr)
			return false;

		return ActiveHighway.MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Tunnel;
	}

	UFUNCTION(BlueprintPure)
	bool IsCloseToSplineEdge() const
	{
		return bCloseToSplineEdge;
	}

	UFUNCTION(BlueprintPure)
	bool IsCarExploding()
	{
		return bCarExploding;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnCarExploded()
	{
		if (bCarExploding)
			return;

		bCarExploding = true;

		USkylineFlyingCarEventHandler::Trigger_OnCarExploded(this);

		Pilot.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Pilot.BlockCapabilities(CapabilityTags::Movement, this);
		Pilot.BlockCapabilities(CapabilityTags::Visibility, this);

		Gunner.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Gunner.BlockCapabilities(CapabilityTags::Movement, this);
		Gunner.BlockCapabilities(CapabilityTags::Visibility, this);

		// Explicitely kill players to get death effect
		FPlayerDeathDamageParams Params;
		// Params.ImpactDirection = -ActorVelocity;
		// Params.ForceScale = ActorVelocity.Size();
		Pilot.KillPlayer(Params);

		// No respawning in level, force game over
		PlayerHealth::TriggerGameOver();

		FakeCar.SetHiddenInGame(true);
		FakeZoe.SetHiddenInGame(true);
		FakeMio.SetHiddenInGame(true);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnCarRespawn()
	{
		bCarExploding = false;
	}

	// Explode car in case a player dies for whatever reason (e.g. player death volumes)
	UFUNCTION(CrumbFunction)
	private void Crumb_OnPlayerDying()
	{
		ExplodeCar(FHitResult());
	}

	UFUNCTION(BlueprintCallable)
	void TakeDamage(FSkylineFlyingCarDamage CarDamage)
	{
		HealthComponent.TakeDamage(CarDamage);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TimeSinceLastHighwaySwitch += DeltaSeconds;

		#if EDITOR
		if (DebugDrawer.IsVisible())
		{
			FString Debug = "";

			if(bIsFreeFyling)
				Debug += "FreeFyling ";
			
			if(bIsSplineDashing)
				Debug += "Boosting";

			if(ActiveHighway != nullptr)
				Debug += "\n" + ActiveHighway.GetName();

			Debug += "\n" + DebugCameraSettingsText;
			Debug::DrawDebugString(ActorLocation, Debug, FLinearColor::White * 0.95, ScreenSpaceOffset = FVector2D(-260, 200));
		}
		#endif

		//New FakeCar Rotation Stuff
		FVector FlattenCarVector = MovementComponent.Velocity.VectorPlaneProject(FVector::UpVector);
		FRotator FakeCarRotation = FRotator::MakeFromXZ(FlattenCarVector, FVector::UpVector);

		if (FakeCarRotation.IsNearlyZero())
			AccFakeRot.SnapTo(Mesh.WorldRotation);
		else
			AccFakeRot.AccelerateTo(FakeCarRotation, 2.0, DeltaSeconds);

		//Add Some Extra FakeRotation
		FRotator ExtraFakeCarRotation = Math::LerpShortestPath(AccFakeRot.Value, Mesh.WorldRotation, FakeRotationValue);
		FakeCar.SetWorldRotation(ExtraFakeCarRotation);
	}

	access:Resolver
	void OnResolverCollisions(TArray<FSkylineFlyingCarCollision> Collisions)
	{
		if(!ensure(HasControl()))
			return;
		
		CrumbOnResolverCollisions(Collisions);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnResolverCollisions(TArray<FSkylineFlyingCarCollision> Collisions)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "OnResolverCollisions");
		TemporalLog.Event(f"{Collisions.Num()} Collisions");
#endif

		for(int i = 0; i < Collisions.Num(); i++)
		{
			const FSkylineFlyingCarCollision& Collision = Collisions[i];

#if !RELEASE
			TemporalLog.Section(f"Collision {i+1}")
				.Value("Type", Collision.Type)
				.HitResults("HitResult", Collision.HitResult, MovementComponent.CollisionShape, ActorTransform.InverseTransformPosition(MovementComponent.ShapeComponent.WorldLocation))
				.Value("Direction", Collision.Direction)
			;
#endif

			OnCollision.Broadcast(Collision);
			USkylineFlyingCarEventHandler::Trigger_OnCollision(this, Collision);

			if(Collision.Type == ESkylineFlyingCarCollisionType::TotalLoss)
			{
				ExplodeCar(Collision.HitResult);
			}
		}
	}

	access:Resolver
	void OnResponseComponentImpacts(TArray<FSkylineFlyingCarImpactDataAndResponseComponent> ResponseComponentImpacts)
	{
		if(!ensure(HasControl()))
			return;

		CrumbOnResponseComponentImpacts(ResponseComponentImpacts);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnResponseComponentImpacts(TArray<FSkylineFlyingCarImpactDataAndResponseComponent> ResponseComponentImpacts)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "OnResponseComponentImpacts");
		TemporalLog.Event(f"{ResponseComponentImpacts.Num()} Response Component Impacts");
#endif

		for(int i = 0; i < ResponseComponentImpacts.Num(); i++)
		{
			const FSkylineFlyingCarImpactDataAndResponseComponent& Impact = ResponseComponentImpacts[i];

#if !RELEASE
			TemporalLog.Section(f"Impact {i+1}")
				.Value("ResponseComp", Impact.ResponseComp)
				.HitResults("HitResult", Impact.HitResult, MovementComponent.CollisionShape, ActorTransform.InverseTransformPosition(MovementComponent.ShapeComponent.WorldLocation))
				.DirectionalArrow("Velocity", ActorLocation, Impact.Velocity)
			;
#endif

			Impact.ResponseComp.OnImpactedByFlyingCar.Broadcast(
				this,
				FFlyingCarOnImpactData(Impact.Velocity, Impact.HitResult)
			);
		}
	}

	access:Resolver
	void ApplyBounceDeltaRotation(FQuat InBounceDeltaRotation)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "ApplyBounceDeltaRotation");
		TemporalLog.Rotation("BounceDeltaRotation (Relative)", InBounceDeltaRotation, ActorLocation, 1000);
		TemporalLog.Rotation("BounceDeltaRotation (World)", MeshOffset.WorldTransform.TransformRotation(InBounceDeltaRotation), ActorLocation, 1000);
#endif
	}

	UFUNCTION(DevFunction)
	void ToggleTunnelHopRoll()
	{
		bTunnelHopRoll = !bTunnelHopRoll;
		PrintScaled("Tunnel hop roll " + (bTunnelHopRoll ? "on" : "off"), 1, FLinearColor::Green);
	}
}

UCLASS(Abstract)
class ASkylineFlyingCarStarter : AHazeActor
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeRequestCapabilityOnPlayerComponent PilotRequestComponent;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeRequestCapabilityOnPlayerComponent GunnerRequestComponent;

	UPROPERTY()
	TSubclassOf<ASkylineFlyingCar> FlyingCarClass;

	private ASkylineFlyingCar FlyingCar;

	UFUNCTION()
	ASkylineFlyingCar SpawnAndSetUpSkylineFlyingCar(FTransform WorldTransform, EHazePlayer Pilot = EHazePlayer::Zoe)
	{
		auto PilotPlayer = Game::GetPlayer(Pilot);
		auto GunnerPlayer = PilotPlayer.OtherPlayer;

		FlyingCar = SpawnActor(FlyingCarClass, WorldTransform.Location, WorldTransform.Rotator(), bDeferredSpawn = true, Level = this.Level);
		FlyingCar.MakeNetworked(PilotPlayer);
		FlyingCar.SetActorControlSide(PilotPlayer);
		FinishSpawningActor(FlyingCar);
		
		SetupPilot(PilotPlayer);
		SetupGunner(GunnerPlayer);

		return FlyingCar;
	}

	UFUNCTION()
	void SetupPilot(AHazePlayerCharacter PilotPlayer)
	{
		if (!devEnsure(PilotPlayer != nullptr, "Setup pilot was called without a pilot"))
			return;

		if(!devEnsure(FlyingCar != nullptr, "No Flying Car found. Make sure you call 'SpawnAndSetUpSkylineFlyingCar' first"))
			return;
	
		PilotRequestComponent.StartInitialSheetsAndCapabilities(PilotPlayer, this);

		auto PilotComp = USkylineFlyingCarPilotComponent::Get(PilotPlayer);
		check(PilotComp != nullptr);
		PilotComp.Car = FlyingCar;
		FlyingCar.CurrentPilot = PilotPlayer;

		// Spawn moody vfx
		if (FlyingCar.CameraWeatherEffect != nullptr)
			PostProcessing::ApplyCameraParticles(PilotPlayer, FlyingCar.CameraWeatherEffect, this, EInstigatePriority::Level);

		if (PilotPlayer.HasControl())
		{
			UPlayerHealthComponent PlayerHealthComponent = UPlayerHealthComponent::Get(PilotPlayer);
			PlayerHealthComponent.OnStartDying.AddUFunction(FlyingCar, n"Crumb_OnPlayerDying");
		}

		// Players never respawn in chase sequence, only game overs
		UPlayerHealthSettings::SetEnableRespawnTimer(PilotPlayer, true, this);
		UPlayerHealthSettings::SetRespawnTimer(PilotPlayer, BIG_NUMBER, this);
	}

	UFUNCTION()
	void SetupGunner(AHazePlayerCharacter GunnerPlayer)
	{
		if (!devEnsure(GunnerPlayer != nullptr, "Setup gunner was called without a gunner"))
			return;

		if(!devEnsure(FlyingCar != nullptr, "No Flying Car found. Make sure you call 'SpawnAndSetUpSkylineFlyingCar' first"))
			return;

		GunnerRequestComponent.StartInitialSheetsAndCapabilities(GunnerPlayer, this);

		USkylineFlyingCarGunnerComponent GunnerComponent = USkylineFlyingCarGunnerComponent::Get(GunnerPlayer);
		check(GunnerComponent != nullptr);
		GunnerComponent.Car = FlyingCar;
		GunnerComponent.Gun = FlyingCar.Gun;
		FlyingCar.CurrentGunner = GunnerPlayer;

		GunnerComponent.SetupWeapons();

		if (GunnerPlayer.HasControl())
		{
			UPlayerHealthComponent PlayerHealthComponent = UPlayerHealthComponent::Get(GunnerPlayer);
			PlayerHealthComponent.OnStartDying.AddUFunction(FlyingCar, n"Crumb_OnPlayerDying");
		}

		// Players never respawn in chase sequence, only game overs
		UPlayerHealthSettings::SetEnableRespawnTimer(GunnerPlayer, true, this);
		UPlayerHealthSettings::SetRespawnTimer(GunnerPlayer, BIG_NUMBER, this);
	}
}


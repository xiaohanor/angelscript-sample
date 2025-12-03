event void FBallBossWeakpointBecomeWeak();
event void FBallBossWeakpointRecoverFromWeak();
event void FBallBossWeakpointTornOff();

enum EBallBossWeakPointState
{
	Normal,
	Extruding,
	Retracting,
	Extruded,
	Tearing,
	TornOff,
}

class ASkylineBallBossChargeLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RootOffset;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent, Attach = RootOffset)
	USceneComponent Locks1;
	UPROPERTY(DefaultComponent, Attach = RootOffset)
	USceneComponent Locks2;
	UPROPERTY(DefaultComponent, Attach = RootOffset)
	USceneComponent Locks3;

	UPROPERTY(DefaultComponent, Attach = RootOffset)
	UStaticMeshComponent LaserMeshComp;

	UPROPERTY(DefaultComponent, Attach = RootOffset)
	UStaticMeshComponent MeshPanelComp;

	UPROPERTY(DefaultComponent, Attach = MeshPanelComp)
	USkylineBallBossChargeLaserProgressComponent InteractionLightMesh;

	UPROPERTY(DefaultComponent, Attach = InteractionLightMesh)
	USceneComponent InteractionMashUILocation;

	UPROPERTY(DefaultComponent, Attach = MeshPanelComp)
	UStaticMeshComponent LaserBaseMesh;

	UPROPERTY(DefaultComponent, Attach = LaserBaseMesh)
	USceneComponent HatchRoot;

	UPROPERTY(DefaultComponent, Attach = LaserBaseMesh)
	UStaticMeshComponent ExtrudingMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshPanelComp)
	UGravityBladeCombatTargetComponent BladeTargetComp;

	UPROPERTY(DefaultComponent, Attach = BladeTargetComp)
	UTargetableOutlineComponent BladeOutlineComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent POITargetComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent BladeInteractionResponseComp;

	UPROPERTY(DefaultComponent, Attach = LaserBaseMesh)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent WhipOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::Drag;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent DebugActionComp;

	UPROPERTY(EditDefaultsOnly)
	float TeleportLocationZOffset = 15.0;
	UPROPERTY(EditDefaultsOnly)
	float TeleportLocationRadiusOffset = 180.0;
	UPROPERTY(EditDefaultsOnly)
	int TeleportLocationNumber = 1;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBallBossChargeLaserInteractLocation> LaserInteractionLocationClass;

	TArray<ASkylineBallBossChargeLaserInteractLocation> InteractionTeleportLocations;
	TArray<USkylineBallBossChargeLaserProgressComponent> LaserProgressComponents;

	UPROPERTY()
	UNiagaraSystem LockBreakVFXSystem;

	UPROPERTY()
	UNiagaraSystem TornOffVFXSystem;

	UPROPERTY()
	UNiagaraSystem DestroyedVFXSystem;

	UPROPERTY()
	UNiagaraSystem HitVFXSystem;

	FHazeTimeLike ActivateLaserTimelike;
	default ActivateLaserTimelike.UseLinearCurveZeroToOne();
	default ActivateLaserTimelike.Duration = 0.2;

	FHazeTimeLike ExtrudeTimelike;
	default ExtrudeTimelike.UseSmoothCurveZeroToOne();
	default ExtrudeTimelike.Duration = 0.5;

	ASkylineBallBossBigLaser BigLaser;
	ASkylineBallBoss BallBoss;

	const float OrdinaryLaserScale = 0.5;
	UPROPERTY(BlueprintReadOnly)
	float LaserScale = OrdinaryLaserScale;

	float ExtrudingStartZ = 50.0;
	const float ExtrudingTargetZ = -250.0;
	bool bBroken = false;
	bool bIsLaserActive = false;
	bool bBossPhaseAllowsBladeHit = true;

	float ExtrudedYaw = 0.0;
	FHazeAcceleratedFloat YawSpeed;

	// ------------------
	UPROPERTY(BlueprintReadWrite)
	FBallBossWeakpointBecomeWeak OnBecomeWeak;
	UPROPERTY(BlueprintReadWrite)
	FBallBossWeakpointRecoverFromWeak OnRecoverFromWeak;
	UPROPERTY(BlueprintReadWrite)
	FBallBossWeakpointTornOff OnTornOff;

	FVector StartPanelRelativeLoc;
	UPROPERTY(EditDefaultsOnly, Category = "Tear")
	FVector AddedPanelRelativeLoc;
	default AddedPanelRelativeLoc.Z = 300.0;

	UPROPERTY(EditDefaultsOnly, Category = "Tear")
	FHazeTimeLike PanelTearLocationTimelike;

	FHazeAcceleratedFloat AccAlphaHit;
	float TargetAlphaHit = 0.0;
	const float IncreaseAlphaPerHit = 0.40;
	private EBallBossWeakPointState State = EBallBossWeakPointState::Normal;
	float RecentlyHitCooldown = 0.0;
	float AutoRetractTimer = -1.0;

	bool bZoeTearingFF = false;
	bool bMioIsInteracting = false;
	
	UPROPERTY(EditAnywhere)
	bool bButtonMashExtrude = true;

	UPROPERTY(EditAnywhere)
	bool bButtonMashExtrudeAfterHits = true;

	UPROPERTY(EditInstanceOnly)
	int ChargeLaserIndex = 0;

	UPROPERTY(EditDefaultsOnly)
	int NumLampies = 7;

	UPROPERTY(BlueprintReadOnly)
	int RequiredHits = 3;
	UPROPERTY(BlueprintReadOnly)
	int Hits = 0;

	UPROPERTY()
	float ChargeLaserLength = 400.0;

	UPROPERTY()
	FApplyPointOfInterestSettings POISettings;
	default POISettings.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Fast;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY()
	FRotator POIRelativeRotation = FRotator(-25.0, -45.0, 0.0);

	UPROPERTY()
	FHazeTimeLike OpenHatchTimeLike;
	default OpenHatchTimeLike.UseSmoothCurveZeroToOne();

	float GravityForce = 0.0;
	FVector FallOffDirection;
	FVector FallOffRightVector;

	bool bFullyExtruded = false;

	ASkylineBallBossSurfaceAttacker AssociatedSurfaceAttacker;

	// ------------------

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SkylineBallBossDevToggles::ChargeLasersAutoExtrude.MakeVisible();

		BigLaser = Cast<ASkylineBallBossBigLaser>(AttachParentActor);
		BallBoss = Cast<ASkylineBallBoss>(BigLaser.AttachParentActor);

		TArray<AActor> Attacheds;
		GetAttachedActors(Attacheds, false, true);
		for (AActor Attached : Attacheds)
		{
			ASkylineBallBossSurfaceAttacker Attacker = Cast<ASkylineBallBossSurfaceAttacker>(Attached);
			if (Attacker != nullptr)
			{
				AssociatedSurfaceAttacker = Attacker;
				break;
			}
		}

		BallBoss.ChargeLasers.Add(this);

		BigLaser.OnLaserEnabled.AddUFunction(this, n"HandleLaserEnabled");

		ActivateLaserTimelike.BindUpdate(this, n"ActivateLaserTimelikeUpdate");
		ExtrudeTimelike.BindUpdate(this, n"ExtrudeTimelikeUpdate");
		ExtrudeTimelike.BindFinished(this, n"ExtrudeTimelikeFinished");
		OpenHatchTimeLike.BindUpdate(this, n"OpenHatchTimeLikeUpdate");
		BladeInteractionResponseComp.OnHit.AddUFunction(this, n"HandleHit");
		
		LaserMeshComp.SetHiddenInGame(true);
		ExtrudingStartZ = LaserBaseMesh.RelativeLocation.Z;

		GetComponentsByClass(USkylineBallBossChargeLaserProgressComponent, LaserProgressComponents);

		if (BallBoss.GetPhase() != ESkylineBallBossPhase::TopMioIn)
		{
			bBossPhaseAllowsBladeHit = false;
			BladeInteractionResponseComp.AddResponseComponentDisable(this, true);
			BallBoss.OnPhaseChanged.AddUFunction(this, n"EnableBladeTargeting");
		}

		float AngleStep = 360.0 / TeleportLocationNumber;
		for (int i = 0; i < TeleportLocationNumber; ++i)
		{
			FString LocationName = "" + GetName() + " TP location " + i;
			const float MagicRadius = TeleportLocationRadiusOffset;
			float RadAngle = Math::DegreesToRadians(AngleStep * i + 45.0 - 90.0);
			FVector LocalOffset = FQuat(FVector::UpVector, RadAngle).ForwardVector * MagicRadius;
			FVector WorldLocationWithoutZ = LaserBaseMesh.WorldTransform.TransformPosition(LocalOffset);
			LocalOffset.Z += TeleportLocationZOffset;
			FVector WorldLocation = LaserBaseMesh.WorldTransform.TransformPosition(LocalOffset);

			FVector WorldForward = (LaserBaseMesh.WorldLocation - WorldLocationWithoutZ).GetSafeNormal();
			FRotator WorldRotation = FRotator::MakeFromXZ(WorldForward, LaserBaseMesh.WorldRotation.UpVector);
			ASkylineBallBossChargeLaserInteractLocation SpawnedActor;
			if (LaserInteractionLocationClass != nullptr)
				SpawnedActor = SpawnActor(LaserInteractionLocationClass, WorldLocation, WorldRotation, FName(LocationName), true);
			else 
				SpawnedActor = SpawnActor(ASkylineBallBossChargeLaserInteractLocation, WorldLocation, WorldRotation, FName(LocationName), true);
			SpawnedActor.MakeNetworked(this, InteractionTeleportLocations.Num());
			SpawnedActor.SetActorControlSide(Game::Zoe);
			FinishSpawningActor(SpawnedActor);

			SpawnedActor.AttachToComponent(BallBoss.FakeRootComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

			InteractionTeleportLocations.Add(SpawnedActor);
			BladeInteractionResponseComp.PossibleSmoothTeleportLocations.Add(SpawnedActor);
		}

		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"OnReleased");
		PanelTearLocationTimelike.BindUpdate(this, n"UpdateTearLocationTimelike");
		PanelTearLocationTimelike.BindFinished(this, n"TearLocationTimelikeFinished");
		GravityWhipTargetComponent.Disable(this);
		OnDestroyed.AddUFunction(this, n"HandleChargeLaserDestroyed");

		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION()
	private void HandleChargeLaserDestroyed(AActor DestroyedActor)
	{
		BallBoss.RemoveRotationTarget(LaserBaseMesh);
	}

	UFUNCTION(BlueprintPure)
	EBallBossWeakPointState GetState() const
	{
		return State;
	}

	void SetState(EBallBossWeakPointState NewState)
	{
		if (State != NewState)
		{
			FSkylineBallBossChargeLaserChangedStateEventHandlerParams Params;
			Params.NewState = NewState;
			USkylineBallBossChargeLaserEventHandler::Trigger_ChangedState(this, Params);
		}
		State = NewState;
	}

	UFUNCTION()
	private void EnableBladeTargeting(ESkylineBallBossPhase NewPhase)
	{
		bBossPhaseAllowsBladeHit = NewPhase == ESkylineBallBossPhase::TopMioIn;
		if (NewPhase == ESkylineBallBossPhase::TopMioIn)
			BladeInteractionResponseComp.RemoveResponseComponentDisable(this, true);
	}

	UFUNCTION()
	private void HandleWeakpointDestroyed(AActor DestroyedActor)
	{
		DetachFromActor();
		SetActorHiddenInGame(true);
		SetAutoDestroyWhenFinished(true);
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (State == EBallBossWeakPointState::Extruded)
			AutoRetractTimer = SkylineBallBossDevToggles::LongerGrabScrewWindow.IsEnabled() ? 10.0 : Settings.ExtrudeDuration;

		if (bButtonMashExtrude)
		{
			auto ExtrderComp = USkylineBallBossChargeLaserButtonMashExtrudePlayerComponent::GetOrCreate(CombatComp.Owner);
			ExtrderComp.MashedLaser = this;
			
			ActivateFrameChargeLaserCamera();

			USkylineBallBossMiscVOEventHandler::Trigger_ChargerEnterInteract(BallBoss);
		}

		if (bButtonMashExtrudeAfterHits)
		{
			Hits ++;
			BP_Hit();
			ProceedLampFlicker();
			ProceedLock();

			USkylineBallBossMiscVOEventHandler::Trigger_ChargeLaserHit(BallBoss);
			USkylineBallBossChargeLaserEventHandler::Trigger_MioBladeHit(this);

			if (Hits >= RequiredHits)
			{
				OpenHatchTimeLike.Play();
				bButtonMashExtrude = true;
				BladeInteractionResponseComp.bSmoothTeleportOnHit = true;
				BladeInteractionResponseComp.InteractionType = EGravityBladeCombatInteractionType::LadderKick;
			}

			return;
		}

		if (State != EBallBossWeakPointState::Normal && State != EBallBossWeakPointState::Extruding)
			return;
		
		if (AccAlphaHit.Value > 0.7)
		{
			LaserScale = 0.01;
			StartExtrude();
			LaserMeshComp.SetRelativeScale3D(FVector(LaserScale, LaserScale, LaserMeshComp.WorldScale.Z));
		}
		else
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(HitVFXSystem, BladeTargetComp.WorldLocation);
			TargetAlphaHit += IncreaseAlphaPerHit;
			RecentlyHitCooldown = Settings.ExtrudeRetractGraceTime;
		}
	}

	void ActivateFrameChargeLaserCamera()
	{
		auto Player = Game::Mio;
		Player.ActivateCamera(CameraComp, 0.5, this, EHazeCameraPriority::VeryHigh);
	}

	void DeactivateFrameChargeLaserCamera()
	{
		auto Player = Game::Mio;
		Player.DeactivateCameraByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Hit()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_ToggleLight(bool bFlicker, int Index)
	{}

	private void ProceedLampFlicker()
	{
		// Note: lamps go from 1-7 because of material slot names
		if (Hits == 1)
		{
			BP_ToggleLight(false, 1);
			BP_ToggleLight(true, 2);
			BP_ToggleLight(true, 3);
		}
		else if (Hits >= RequiredHits +1)
		{
			for (int iLamp = 1; iLamp <= NumLampies; ++iLamp)
				BP_ToggleLight(false, iLamp);
		}
		else
		{
			int LampIndex = Hits;
			BP_ToggleLight(false, LampIndex);
			if (Math::IntegerDivisionTrunc(RequiredHits, NumLampies) >= 1)
				BP_ToggleLight(true, LampIndex +1);
			else
			{
				BP_ToggleLight(false, LampIndex +1);
				BP_ToggleLight(true, LampIndex +2);
				BP_ToggleLight(true, LampIndex +3);
			}
		}
	}

	private void ToggleLight(int Index, bool bFlicker)
	{
		if (Index <= NumLampies)
			BP_ToggleLight(bFlicker, Index);
	}

	private void ProceedLock()
	{
		if (Hits == 1)
			OpenLock(Locks1);
		if (Hits == 2)
			OpenLock(Locks2);
		if (Hits == 3)
			OpenLock(Locks3);
	}

	private void OpenLock(USceneComponent LockParent)
	{
		if (LockBreakVFXSystem != nullptr)
		{
			TArray<USceneComponent> Children;
			LockParent.GetChildrenComponents(false, Children);
			for (auto Child : Children)
				Niagara::SpawnOneShotNiagaraSystemAtLocation(LockBreakVFXSystem, Child.WorldLocation);
		}
		LockParent.SetVisibility(false, true);
	}

	UFUNCTION()
	private void OpenHatchTimeLikeUpdate(float CurrentValue)
	{
		HatchRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(0.0, -140.0, CurrentValue));
	}

	void StartExtrude()
	{
		if (State != EBallBossWeakPointState::Normal)
			return;

		SetState(EBallBossWeakPointState::Extruding);
		ExtrudeTimelike.PlayFromStart();

		AlignPartToZoe();
	}

	UFUNCTION(CrumbFunction)
	void CrumbReverseExtrude()
	{
		ReverseExtrude();
	}

	UFUNCTION()
	private void ReverseExtrude()
	{
		if (State != EBallBossWeakPointState::Extruded)
			return;

		ExtrudeTimelike.Reverse();
		SetState(EBallBossWeakPointState::Retracting);
		BallBoss.RemoveRotationTarget(LaserBaseMesh);
		SetWeak(false);
	}

	UFUNCTION()
	private void ExtrudeTimelikeUpdate(float CurrentValue)
	{
		float HeightStartValue = ExtrudingStartZ - ExtrudingTargetZ * AccAlphaHit.Value;
		float HeightEndValue = ExtrudingStartZ - ExtrudingTargetZ;
		// PrintToScreen("Used Alpha " + CurrentValue);
		FVector RelativeLocation = LaserBaseMesh.RelativeLocation;
		RelativeLocation.Z = Math::Lerp(HeightStartValue, HeightEndValue, CurrentValue);
		LaserBaseMesh.SetRelativeLocation(RelativeLocation);
	}
	
	UFUNCTION()
	private void ExtrudeTimelikeFinished()
	{
		if (State == EBallBossWeakPointState::Extruding)
		{
			SetState(EBallBossWeakPointState::Extruded);
			AutoRetractTimer = SkylineBallBossDevToggles::LongerGrabScrewWindow.IsEnabled() ? 10.0 : Settings.ExtrudeDuration;
			SetWeak(true);
		}
		if (State == EBallBossWeakPointState::Retracting)
			SetState(EBallBossWeakPointState::Normal);
	}

	UFUNCTION()
	private void Break()
	{
		if (bBroken)
			return;

		bBroken = true;
		BladeTargetComp.Disable(this);
		LaserMeshComp.SetVisibility(false);
	}

	UFUNCTION()
	private void Unbreak()
	{
		if (!bBroken)
			return;

		bBroken = false;
		BladeTargetComp.Enable(this);
		LaserMeshComp.SetVisibility(true);
	}

	UFUNCTION()
	private void TearLocationTimelikeFinished()
	{
		if (!HasControl())
			return;

		if (State == EBallBossWeakPointState::Tearing)
			CrumbTorn();
		else if (State == EBallBossWeakPointState::Extruded)
			CrumbReverseExtrude();
	}

	UFUNCTION(CrumbFunction)
	void CrumbTorn()
	{
		TornOff();
	}

	UFUNCTION()
	private void TornOff()
	{
		GravityWhipTargetComponent.Disable(this);
		SetState(EBallBossWeakPointState::TornOff);
		Timer::SetTimer(this, n"Explode", 2.0);

		BallBoss.bRecentlyLostWeakpoint = true;
		BallBoss.RemoveRotationTarget(LaserBaseMesh);

		ExtrudeTimelike.Reverse();

		LaserMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ExtrudingMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		float Damage = BallBoss.Settings.ChargeLaserDamage;
		bool bStartWeakpointPhase = BallBoss.HealthComp.GetCurrentHealth() - Damage <= BallBoss.Settings.WeakpointHealth + 0.01;
		if (bStartWeakpointPhase)
		{
			float DesiredHealth = BallBoss.HealthComp.MaxHealth * BallBoss.Settings.WeakpointHealth;
			float LessDamage = BallBoss.HealthComp.GetCurrentHealth() - DesiredHealth;
			BallBoss.HealthComp.TakeDamage(LessDamage, EDamageType::Default, this);
		}
		else
		{
			BallBoss.HealthComp.TakeDamage(Damage, EDamageType::Default, this);
		}
		
		BallBoss.OnBallBossLostChargeLaser.Broadcast(ChargeLaserIndex);

		if (BallBoss.ZoeTornOffWeakpointFF != nullptr)
            Game::Zoe.PlayForceFeedback(BallBoss.ZoeTornOffWeakpointFF, false, false, this);

		if (bStartWeakpointPhase && HasControl() && BallBoss.GetPhase() != ESkylineBallBossPhase::TopMioInKillWeakpoint)
			CrumbStartKillWeakpoint();

		if (TornOffVFXSystem != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(TornOffVFXSystem, MeshPanelComp.WorldLocation);

		OnTornOff.Broadcast();
		BP_TornOff();
		BallBoss.ChargeLasers.Remove(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_TornOff(){}

	UFUNCTION(CrumbFunction)
	void CrumbStartKillWeakpoint()
	{
		BallBoss.ChangePhase(ESkylineBallBossPhase::TopMioInKillWeakpoint);
	}

	UFUNCTION()
	private void HandleLaserEnabled(bool bEnabled)
	{
		if (bEnabled)
			ActivateLaser();
		else
			DeactivateLaser();
	}

	UFUNCTION()
	private void ActivateLaserTimelikeUpdate(float CurrentValue)
	{
		LaserScale = Math::Lerp(SMALL_NUMBER, OrdinaryLaserScale, CurrentValue);
		if (LaserScale < KINDA_SMALL_NUMBER)
			LaserScale = SMALL_NUMBER;
		LaserMeshComp.SetRelativeScale3D(FVector(LaserScale, LaserScale, LaserMeshComp.WorldScale.Z));
		if (LaserScale < KINDA_SMALL_NUMBER)
			LaserMeshComp.SetVisibility(false, true);
		if (LaserScale > KINDA_SMALL_NUMBER && !LaserMeshComp.IsVisible())
			LaserMeshComp.SetVisibility(true, true);
	}

	UFUNCTION()
	void ActivateLaser()
	{
		if (State == EBallBossWeakPointState::TornOff)
			return;

		bIsLaserActive = true;
		LaserMeshComp.SetHiddenInGame(false);
		ActivateLaserTimelike.Play();
		if (State == EBallBossWeakPointState::Normal)
			BladeTargetComp.Enable(this);
	}

	UFUNCTION()
	void DeactivateLaser()
	{
		bIsLaserActive = false;
		ActivateLaserTimelike.Reverse();
		if (State == EBallBossWeakPointState::Normal)
			BladeTargetComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (State == EBallBossWeakPointState::Normal && SkylineBallBossDevToggles::ChargeLasersAutoExtrude.IsEnabled())
			StartExtrude();

		if (bBossPhaseAllowsBladeHit && State == EBallBossWeakPointState::Normal && BladeTargetComp.IsDisabled())
			BladeTargetComp.Enable(this);

		bool bShouldAutoRetract = AutoRetractTimer > 0.0 && AutoRetractTimer - DeltaSeconds < 0.0;
		AutoRetractTimer -= DeltaSeconds;
		if (bShouldAutoRetract)
			ReverseExtrude();

		UpdateExtrusion(DeltaSeconds);

		if (bButtonMashExtrude)
			UpdateStateIfUsingButtonMash();

		UpdateMeshRotatation(DeltaSeconds);

		Debugging();

		if (State == EBallBossWeakPointState::TornOff)
		{
			if (bFullyExtruded)
			{
				GravityForce += DeltaSeconds * 2000.0;

				FVector DeltaWorldOffset = (FallOffDirection * 1500.0 + FVector::DownVector * GravityForce) * DeltaSeconds;
				FQuat DeltaRotation = FQuat(FallOffRightVector, Math::DegreesToRadians(50.0 * DeltaSeconds));
				MeshPanelComp.AddWorldRotation(DeltaRotation);

				// sweep with delta to see if we hit anything?
				FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
				Trace.UseCapsuleShape(110, 200, MeshPanelComp.WorldRotation.Quaternion());
				Trace.IgnoreActor(this);
				FHitResult EnvHit = Trace.QueryTraceSingle(MeshPanelComp.WorldLocation, MeshPanelComp.WorldLocation + DeltaWorldOffset);
				if (EnvHit.IsValidBlockingHit())
				{
					FVector ToHitDelta = EnvHit.ImpactPoint - MeshPanelComp.WorldLocation;
					MeshPanelComp.AddWorldOffset(ToHitDelta);
					Explode();
				}
				else
				{
					MeshPanelComp.AddWorldOffset(DeltaWorldOffset);
				}

			}
			else
			{
				RootOffset.AddRelativeLocation(FVector::UpVector * -1500.0 * DeltaSeconds);

				if (RootOffset.RelativeLocation.Z < -ChargeLaserLength && !bFullyExtruded)
					FullyExtruded();
			}
			
		}
	}

	private void FullyExtruded()
	{
		bFullyExtruded = true;

		DetachFromActor(EDetachmentRule::KeepWorld);
		FallOffDirection = -ActorUpVector;
		if (FallOffDirection.GetSafeNormal().DotProduct(FVector::UpVector) >= 1.0 - KINDA_SMALL_NUMBER)
			FallOffRightVector = FRotator::MakeFromXZ(FallOffDirection, FVector::RightVector).RightVector;
		else
			FallOffRightVector = FRotator::MakeFromXZ(FallOffDirection, FVector::UpVector).RightVector;
	}

	private void Debugging()
	{
		if (SkylineBallBossDevToggles::DrawLaser.IsEnabled()) 
		{
			for (auto Loc : InteractionTeleportLocations)
			{
				// Debug::DrawDebugSphere(Loc.ActorLocation, 10.0, 12, ColorDebug::Bubblegum, 5.0, 0.0, true);
				Debug::DrawDebugCoordinateSystem(Loc.ActorLocation, Loc.ActorRotation, 60.0);
				FString LocName = "" + Loc.GetName();
				LocName = LocName.Right(13);
				Debug::DrawDebugString(Loc.ActorLocation, LocName, FLinearColor::White, 0.0, 1.5);
			}
			FString LaserName = "" + GetName();
			Debug::DrawDebugString(MeshPanelComp.WorldLocation, LaserName, FLinearColor::White, 0.0, 1.5);
			Debug::DrawDebugSphere(MeshPanelComp.WorldLocation, 10.0, 12, ColorDebug::Leaf, 5.0, 0.0, true);
		}

		if (SkylineBallBossDevToggles::ChargeLasersComeOff.IsEnabled() && DebugActionComp.IsEmpty() && BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioIn) 
		{
			DebugActionComp.Idle(Math::RandRange(1.0, 4.0));
			DebugActionComp.Event(this, n"TornOff");
		}

#if EDITOR
		for (auto InteractLocation : InteractionTeleportLocations)
		{
			if (SkylineBallBossDevToggles::DrawMioInteractTPLocations.IsEnabled())
				Debug::DrawDebugSphere(InteractLocation.ActorLocation, 10.0, 12, ColorDebug::White);
			FString LocName = "" + InteractLocation.GetName();
			LocName = LocName.Right(13);
			auto TemporalLog = TEMPORAL_LOG(this, LocName);
			TemporalLog.Sphere("Location", InteractLocation.ActorLocation, 10.0, ColorDebug::White);
			const float CoordLength = 100.0;
			const float CoordSize = 3.0;
			const float CoordArrowSize = 20.0;
			TemporalLog.Arrow("Up", InteractLocation.ActorLocation, InteractLocation.ActorLocation + InteractLocation.ActorUpVector * CoordLength, CoordSize, CoordArrowSize, ColorDebug::Blue);
			TemporalLog.Arrow("Forward", InteractLocation.ActorLocation, InteractLocation.ActorLocation + InteractLocation.ActorForwardVector * CoordLength, CoordSize, CoordArrowSize, ColorDebug::Red);
			TemporalLog.Arrow("Right", InteractLocation.ActorLocation, InteractLocation.ActorLocation + InteractLocation.ActorRightVector * CoordLength, CoordSize, CoordArrowSize, ColorDebug::Green);
		}
#endif
	}

	private void UpdateExtrusion(float DeltaSeconds)
	{
		RecentlyHitCooldown -= DeltaSeconds;
		if (RecentlyHitCooldown < 0.0)
			TargetAlphaHit -= DeltaSeconds * 0.5;
		TargetAlphaHit = Math::Clamp(TargetAlphaHit, 0.0, 1.0);
		AccAlphaHit.AccelerateTo(TargetAlphaHit, 0.5, DeltaSeconds);
		if (InHandledAutoExtrudeRetractState())
		{
			FVector RelativeLocation = LaserBaseMesh.RelativeLocation;
			RelativeLocation.Z = ExtrudingStartZ - ExtrudingTargetZ * AccAlphaHit.Value;
			LaserBaseMesh.SetRelativeLocation(RelativeLocation);
			LaserScale = OrdinaryLaserScale * 1.0 - AccAlphaHit.Value;
			LaserScale = Math::Clamp(LaserScale, 0.1, OrdinaryLaserScale);
			LaserMeshComp.SetRelativeScale3D(FVector(LaserScale, LaserScale, LaserMeshComp.WorldScale.Z));
		}
	}

	private bool InHandledAutoExtrudeRetractState()
	{
		if (!bButtonMashExtrude && State == EBallBossWeakPointState::Normal)
			return true;
		if (bButtonMashExtrude && State == EBallBossWeakPointState::Extruding)
			return true;
		if (bButtonMashExtrude && State == EBallBossWeakPointState::Retracting)
			return true;
		return false;
	}

	private void UpdateMeshRotatation(float DeltaSeoncds)
	{
		float DesiredYawSpeed = 45.0;
		float DesiredDuration = 4.0;

		bool bNoRotation = State == EBallBossWeakPointState::Tearing || State == EBallBossWeakPointState::TornOff;
		bool bSlowRotation = State == EBallBossWeakPointState::Extruding || State == EBallBossWeakPointState::Retracting || State == EBallBossWeakPointState::Extruded;
		if (bNoRotation)
		{
			DesiredDuration = 2.0;
			DesiredYawSpeed = 0.0;
		}
		else if (bSlowRotation)
		{
			DesiredDuration = 8.0;
			DesiredYawSpeed = 10.0;
		}
		else if (bIsLaserActive)
			DesiredYawSpeed = 360.0;

		YawSpeed.AccelerateTo(DesiredYawSpeed, DesiredDuration, DeltaSeoncds);
		ExtrudedYaw += YawSpeed.Value * DeltaSeoncds;
		if (ExtrudedYaw > 360.0)
			ExtrudedYaw -= 360;
		ExtrudingMeshComp.SetRelativeRotation(FRotator(0.0, ExtrudedYaw, 0.0));
	}

	void UpdateStateIfUsingButtonMash()
	{
		if (!bButtonMashExtrude)
			return;
		// bool bInHandledSetState(State == EBallBossWeakPointState::Extruding || State == EBallBossWeakPointState::Extruding || State == EBallBossWeakPointState::Extruded);
		// if (!bInHandledState)
		// 	return;

		if (State == EBallBossWeakPointState::Extruding && AccAlphaHit.Value > 0.7)//1.0 - KINDA_SMALL_NUMBER)
		{
			SetState(EBallBossWeakPointState::Extruded);
			//AlignPartToBallBoss();
			SetWeak(true);
		}
		else if (State == EBallBossWeakPointState::Extruded && AccAlphaHit.Value < 0.7)
		{
			SetState(EBallBossWeakPointState::Extruding);
			SetWeak(false);
		}
		else if (State == EBallBossWeakPointState::Retracting && AccAlphaHit.Value <= KINDA_SMALL_NUMBER)
		{
			auto ExtrderComp = USkylineBallBossChargeLaserButtonMashExtrudePlayerComponent::Get(Game::Mio);
			if (ExtrderComp.MashedLaser == this)
				SetState(EBallBossWeakPointState::Extruding);
			else
				SetState(EBallBossWeakPointState::Normal);
			SetWeak(false);
		}
	}

	private void AlignPartToZoe()
	{
		{
			FBallBossAlignRotationData AlignData;
			AlignData.PartComp = LaserBaseMesh;
			AlignData.OverrideTargetComp = Game::Zoe.RootComponent;
			AlignData.bUseRandomOffset = true;
			AlignData.Priority = EBallBossAlignRotationDataPrio::Medium;
			BallBoss.AddRotationTarget(AlignData);
		}
	}

	USkylineBallBossSettings GetSettings() const property
	{
		return Cast<USkylineBallBossSettings>(
			BallBoss.GetSettings(USkylineBallBossSettings)
		);
	}

	// Weakpoint
	void SetWeak(bool bIsWeak)
	{
		if (bIsWeak)
		{
			GravityWhipTargetComponent.Enable(this);
			OnBecomeWeak.Broadcast();
			HatchRoot.SetHiddenInGame(true, true);
			
			USkylineBallBossMiscVOEventHandler::Trigger_ChargeLaserExtruded(BallBoss);
		}
		else
		{
			GravityWhipTargetComponent.Disable(this);
			OnRecoverFromWeak.Broadcast();
		}
	}

	UFUNCTION()
	void OnGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		BladeTargetComp.Disable(this);
		StartPanelRelativeLoc = LaserBaseMesh.RelativeLocation;
		PanelTearLocationTimelike.Play();
		SetState(EBallBossWeakPointState::Tearing);

		//I added this because I removed the commented out the rotate align from extrude
		AlignPartToZoe();
		
		for (int i = 0; i < BallBoss.AlignTowardsStageDatas.Num(); ++i) 
		{
			bool bHasPartComp = BallBoss.AlignTowardsStageDatas[i].PartComp != nullptr;
			if (bHasPartComp && BallBoss.AlignTowardsStageDatas[i].PartComp.Owner == this)
			{
				BallBoss.AlignTowardsStageDatas[i].bUseRandomOffset = false;
				break;
			}
		}
		DeactivateLaser();
		Break();
	}

	UFUNCTION()
	void OnReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		if (State == EBallBossWeakPointState::Tearing)
		{
			SetState(EBallBossWeakPointState::Extruded);
			if (bButtonMashExtrude)
			{
				BallBoss.RemoveRotationTarget(LaserBaseMesh);
				SetState(EBallBossWeakPointState::Retracting);
			}
			PanelTearLocationTimelike.Reverse();
			ActivateLaser();
			Unbreak();
		}
	}

	UFUNCTION()
	void UpdateTearLocationTimelike(float NewAlpha)
	{
		FVector TargetTotal = StartPanelRelativeLoc + AddedPanelRelativeLoc;
		FVector NewRelativeLoc = Math::Lerp(StartPanelRelativeLoc, TargetTotal, NewAlpha);
		FRotator NewRot = FRotator(LaserBaseMesh.RelativeRotation.Pitch, Math::Lerp(0.0, 180.0, NewAlpha), LaserBaseMesh.RelativeRotation.Roll);
		LaserBaseMesh.SetRelativeLocationAndRotation(NewRelativeLoc, NewRot);
		if (State == EBallBossWeakPointState::Tearing && BallBoss.ZoeTearingWeakpointFF != nullptr)
            Game::Zoe.PlayForceFeedback(BallBoss.ZoeTearingWeakpointFF, true, false, this, NewAlpha);
	}

	UFUNCTION()
	void Explode()
	{
		if (this == nullptr)
			return;
		if (DestroyedVFXSystem != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DestroyedVFXSystem, MeshPanelComp.WorldLocation);
		if (AssociatedSurfaceAttacker != nullptr)
			AssociatedSurfaceAttacker.ParentChargeLaserDestroyed();
		DestroyActor();
	}
};
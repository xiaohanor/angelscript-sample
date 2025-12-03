class ASkylineBallBossWeakpoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WeakpointShellMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WeakpointMeshComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent WeakpointOverlapComp;

	UPROPERTY(DefaultComponent, Attach = WeakpointMeshComp)
	UGravityBladeCombatTargetComponent BladeTargetComp;

	UPROPERTY(DefaultComponent, Attach = WeakpointMeshComp)
	UTargetableOutlineComponent BladeOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent BladeInteractionResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent WeakpointFeedbackComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent DebugQueueComp;

	UPROPERTY()
	UNiagaraSystem ShieldHitVFXSystem;

	UPROPERTY()
	UNiagaraSystem ShieldPowerDownVFXSystem;

	UPROPERTY()
	UNiagaraSystem WeakpointHitVFXSystem;

	UNiagaraComponent WeakpointVFX;

	private bool bHasEmerged = false;
	ASkylineBallBoss BallBoss;
	private bool bWeakpointJiggle = false;

	FVector ShieldScale;
	FVector WeakpointScale;

	UPROPERTY(EditDefaultsOnly)
	private float TeleportLocationZOffset = -10.0;
	UPROPERTY(EditDefaultsOnly)
	private float TeleportLocationRadiusOffset = 150.0;
	UPROPERTY(EditDefaultsOnly)
	private int TeleportLocationNumber = 8;
	UPROPERTY(EditDefaultsOnly)
	private TSubclassOf<ASkylineBallBossChargeLaserInteractLocation> LaserInteractionLocationClass;
	private TArray<ASkylineBallBossChargeLaserInteractLocation> InteractionTeleportLocations;

	private int WeakpointHits = 0;
	private int ChargeLasersUnscrewed = 0;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor FrameWeakpointCamera;

	UPROPERTY()
	private UMaterialInstance Weakpoint1Material;
	UPROPERTY()
	private UMaterialInstance Weakpoint2Material;
	UPROPERTY()
	private UMaterialInstance Weakpoint3Material;

	UPROPERTY()
	UNiagaraSystem StartEmergeSystem;
	UPROPERTY()
	UNiagaraSystem ExplosionSystem;

	FVector OGRelativeLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		OGRelativeLoc = GetActorRelativeLocation();
		BallBoss = Cast<ASkylineBallBoss>(AttachParentActor);
		WeakpointMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		WeakpointMeshComp.SetVisibility(false);
		
		BladeInteractionResponseComp.AddResponseComponentDisable(this, true);
		BladeInteractionResponseComp.OnHit.AddUFunction(this, n"HandleHit");

		WeakpointScale = WeakpointMeshComp.GetWorldScale();

		BallBoss.Weakpoint = this;
		WeakpointVFX = UNiagaraComponent::Get(this);
		if (WeakpointVFX != nullptr)
			WeakpointVFX.Deactivate();

		BallBoss.OnBallBossLostChargeLaser.AddUFunction(this, n"OnChargeLaserUnscrewed");

		WeakpointOverlapComp.OnComponentEndOverlap.AddUFunction(this, n"PlayerLeftWeakpointZone");
		CreateInteractLocations();

		if (SkylineBallBossDevToggles::InsideWeakpointAutoplay.IsEnabled())
			Emerge();
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (bHasEmerged)
			TakeWeakpointHit();
		else 
			Niagara::SpawnOneShotNiagaraSystemAttachedAtLocation(ShieldHitVFXSystem, RootComp, BladeTargetComp.WorldLocation);
	}

	UFUNCTION()
	private void PlayerLeftWeakpointZone(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		bool bWantsToEmerge = BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioInKillWeakpoint;
		if (bWantsToEmerge && !bHasEmerged)
		{
			Emerge();

			if (SkylineBallBossDevToggles::InsideWeakpointAutoplay.IsEnabled())
			{
				DebugQueueComp.Idle(2.0);
				DebugQueueComp.Event(this, n"OnChargeLaserUnscrewed", 0);
				DebugQueueComp.Idle(1.0);
				DebugQueueComp.Event(this, n"OnChargeLaserUnscrewed", 1);
				DebugQueueComp.Idle(1.0);
				DebugQueueComp.Event(this, n"OnChargeLaserUnscrewed", 2);

				// DebugQueueComp.ActionQueue.Idle(3.0);
				// DebugQueueComp.ActionQueue.Event(this, n"TakeWeakpointHit");
				// DebugQueueComp.ActionQueue.Idle(2.0);
				// DebugQueueComp.ActionQueue.Event(this, n"TakeWeakpointHit");
				// DebugQueueComp.ActionQueue.Idle(2.0);
				// DebugQueueComp.ActionQueue.Event(this, n"TakeWeakpointHit");
			}
		}
	}

	UFUNCTION()
	void TakeWeakpointHit()
	{
		if (HasControl())
			CrumbTakeWeakpointHit();
	}

	UFUNCTION(CrumbFunction)
	void CrumbTakeWeakpointHit()
	{
		++WeakpointHits;
		if (WeakpointHits > BallBoss.Settings.WeakpointNumHits)
			return;

		float Damage = BallBoss.Settings.WeakpointHealth / float(BallBoss.Settings.WeakpointNumHits);
		BallBoss.HealthComp.TakeDamage(Damage, EDamageType::Default, this);

		switch (WeakpointHits)
		{
			case 1: 
			{
				WeakpointMeshComp.SetMaterial(0, Weakpoint1Material); 
				WeakpointFeedbackComp.Duration(0.5, this, n"ScaleJiggleWeakpoint");
				WeakpointFeedbackComp.Event(this, n"QueueWeakpointInstability");
				break; 
			}
			case 2: 
			{
				WeakpointMeshComp.SetMaterial(0, Weakpoint2Material); 
				WeakpointFeedbackComp.Duration(0.3, this, n"ScaleJiggleWeakpoint");
				WeakpointFeedbackComp.Event(this, n"QueueWeakpointInstability");
				break; 
			}
			case 3: 
			{
				WeakpointMeshComp.SetMaterial(0, Weakpoint3Material); 
				WeakpointFeedbackComp.Empty();
				WeakpointFeedbackComp.SetLooping(false);
				WeakpointFeedbackComp.Duration(0.2, this, n"ScaleJiggleWeakpoint");
				break; 
			}
		}

		if (WeakpointHitVFXSystem != nullptr)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(WeakpointHitVFXSystem, BladeTargetComp.WorldLocation);
			USkylineBallBossWeakpointEventHandler::Trigger_MioBladeHit(this);
		}

		if (WeakpointHits == BallBoss.Settings.WeakpointNumHits)
		{
			if (ExplosionSystem != nullptr)
				Niagara::SpawnOneShotNiagaraSystemAttachedAtLocation(ExplosionSystem, WeakpointMeshComp, WeakpointMeshComp.WorldLocation);
			BallBoss.HealthComp.TakeDamage(999, EDamageType::Default, this);
			if (WeakpointVFX != nullptr)
				WeakpointVFX.Deactivate();
			BladeInteractionResponseComp.AddResponseComponentDisable(this);
			//QueueComp.ActionQueue.Duration(2.0, this, n"ScaleDownWeakpoint");
			QueueComp.Event(this, n"ProceedToTopDeath");
		}
	}

	UFUNCTION()
	private void QueueWeakpointInstability()
	{
		WeakpointFeedbackComp.Empty();
		if (WeakpointHits == 1)
			WeakpointFeedbackComp.Duration(0.7, this, n"ScaleInstabilityWeakpoint");
		else
			WeakpointFeedbackComp.Duration(0.3, this, n"ScaleInstabilityWeakpoint");
		WeakpointFeedbackComp.SetLooping(true);
	}

	UFUNCTION()
	private void ProceedToTopDeath()
	{
		BallBoss.ChangePhase(ESkylineBallBossPhase::TopSmallBoss);
		AddActorDisable(this);
	}

	UFUNCTION()
	void OnChargeLaserUnscrewed(int Index)
	{
		ChargeLasersUnscrewed++;
		if (ShieldPowerDownVFXSystem != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ShieldPowerDownVFXSystem, BladeTargetComp.WorldLocation);
		
		if (ChargeLasersUnscrewed >= 3)
			Emerge();

		// PreviousShieldAlpha = ShieldAlpha;
		// ShieldAlpha -= 1.0 / 3.0;
		// ShieldAlpha = Math::Clamp(ShieldAlpha, SMALL_NUMBER, 1.0);
		// if (ShieldAlpha <= KINDA_SMALL_NUMBER)
		// 	RemoveShield();
		// else
		// 	QueueComp.ActionQueue.Duration(0.2, this, n"ScaleDownShield");
	}

	UFUNCTION()
	private void Emerge()
	{
		if (!bHasEmerged)
		{
			QueueComp.Idle(1.5);
			QueueComp.Event(this, n"StartEmergeVfx");
			QueueComp.Duration(2.0, this, n"UpdateEmerge");
			QueueComp.Event(this, n"ToggleHitResponse");
			QueueComp.Duration(0.3, this, n"ScaleUpWeakpoint");
			QueueComp.Event(this, n"EnableWeakpoint");
			QueueComp.Event(this, n"ActivateVFX");
		}
		bHasEmerged = true;
	}

	UFUNCTION()
	private void StartEmergeVfx()
	{
		if (StartEmergeSystem != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAttachedAtLocation(StartEmergeSystem, WeakpointMeshComp, WeakpointMeshComp.WorldLocation);
	}

	UFUNCTION()
	private void UpdateEmerge(float Alpha)
	{
		FVector NewRelativeLoc = OGRelativeLoc + FVector::ForwardVector * 210.0;
		SetActorRelativeLocation(Math::EaseIn(OGRelativeLoc, NewRelativeLoc, Alpha, 2.0));
	}

	UFUNCTION()
	private void ScaleUpWeakpoint(float Alpha)
	{
		WeakpointMeshComp.SetVisibility(true);
		FVector WeakpointScaling = WeakpointScale;
		WeakpointScaling.Z *= Math::Max(SkylineBallBossCurveScaleInWeakpoint.GetFloatValue(Alpha), 0.01);
		WeakpointMeshComp.SetWorldScale3D(WeakpointScaling);
	}

	UFUNCTION()
	private void ScaleDownWeakpoint(float Alpha)
	{
		FVector WeakpointScaling = WeakpointScale;
		WeakpointScaling *= Math::Max(1.0 - Alpha, 0.01);
		WeakpointMeshComp.SetWorldScale3D(WeakpointScaling);
	}

	UFUNCTION()
	private void ScaleJiggleWeakpoint(float Alpha)
	{
		FVector WeakpointScaling = WeakpointScale;
		WeakpointScaling *= Math::Max(SkylineBallBossCurveScaleJiggleHitWeakpoint.GetFloatValue(Alpha), 0.01);
		WeakpointMeshComp.SetWorldScale3D(WeakpointScaling);
	}

	UFUNCTION()
	private void ScaleInstabilityWeakpoint(float Alpha)
	{
		FVector WeakpointScaling = WeakpointScale;
		WeakpointScaling *= Math::Max(SkylineBallBossCurveScaleInstableWeakpoint.GetFloatValue(Alpha), 0.01);
		WeakpointMeshComp.SetWorldScale3D(WeakpointScaling);
	}

	UFUNCTION()
	private void EnableWeakpoint()
	{
		WeakpointMeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		WeakpointVFX.Activate();
	}

	UFUNCTION()
	private void ActivateVFX()
	{
		WeakpointVFX.Activate();
	}

	UFUNCTION()
	private void ToggleHitResponse()
	{
		{
			BladeInteractionResponseComp.RemoveResponseComponentDisable(this, true);
			BladeInteractionResponseComp.bSmoothTeleportOnHit = true;
		}
	}

	// -----------------------------------------------

	private void CreateInteractLocations()
	{
		float AngleStep = 360.0 / TeleportLocationNumber;
		for (int i = 0; i < TeleportLocationNumber; ++i)
		{
			FString LocationName = "" + GetName() + " TP location " + i;
			const float MagicRadius = TeleportLocationRadiusOffset;
			float RadAngle = Math::DegreesToRadians(AngleStep * i);
			FVector LocalOffset = FQuat(FVector::UpVector, RadAngle).ForwardVector * MagicRadius;
			FVector WorldLocationWithoutZ = ActorTransform.TransformPosition(LocalOffset);
			LocalOffset.Z += TeleportLocationZOffset;
			FVector WorldLocation = ActorTransform.TransformPosition(LocalOffset);
			FVector WorldForward = (ActorLocation - WorldLocationWithoutZ).GetSafeNormal();
			FRotator WorldRotation = FRotator::MakeFromXZ(WorldForward, ActorUpVector);
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
	}

	UFUNCTION()
	void AlignWeakPointCameraWithMioView()
	{
		auto CameraComp = UHazeCameraUserComponent::Get(Game::Mio);
		FTransform MioViewTransform = CameraComp.GetViewTransform();
		FrameWeakpointCamera.SetActorTransform(MioViewTransform);
	}
};

class USkylineBallBossWeakpointEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MioBladeHit() {}

}


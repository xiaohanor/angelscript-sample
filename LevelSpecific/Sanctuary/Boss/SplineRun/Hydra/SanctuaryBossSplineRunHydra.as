enum ESanctuaryBossSplineRunHydraPhase
{
	Appear,
	AttackLoop,
	LastPlatform,
	Crossbow,
	CutsceneDive,
}

enum ESanctuaryBossSplineRunHydraAnimation
{
	None,
	Idle,
	Projectile,
	Wave,
	Dive,
	PlayersEngageCrossbow,
	HitByArrow,
}

enum ESanctuaryBossSplineRunHydraID
{
	Left,
	Center,
	Right,
}

asset SanctuaryBossSplineRunHydraSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USanctuaryBossSplineRunHydraAnimationCapability);
	Capabilities.Add(USanctuaryBossSplineRunHydraFadeInEmissiveFaceCapability);
	Capabilities.Add(USanctuaryBossSplineRunHydraFadeOutEmissiveFaceCapability);
};

class ASanctuaryBossSplineRunHydra : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh)
	USceneComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(SanctuaryBossSplineRunHydraActionSheet);
	default CapabilityComponent.DefaultSheets.Add(SanctuaryBossSplineRunHydraSheet);

	private TArray<ASanctuaryBossSplineRunHydra> OtherHydras;

	UPROPERTY(DefaultComponent)
	USanctuaryBossSplineRunHydraActionComponent BossComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossArenaDecapitatedHead DecapitatedHead = nullptr;

	UPROPERTY(EditAnywhere)
	USkeletalMesh DecapitatedSkeletalMesh;

	UPROPERTY(EditInstanceOnly)
	ESanctuaryBossSplineRunHydraID HeadID;

	// -- 

	UPROPERTY(EditAnywhere, Category = "Ghost Projectile")
	float SpawnInterval = 2.0;
	
	UPROPERTY(EditAnywhere, Category = "Ghost Projectile")
	float StartDelay = 0.5;

	UPROPERTY(EditAnywhere, Category = "Ghost Projectile")
	float DelayResumeAttackingAfterArrow = 2.0;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossSplineRun PlatformSpline;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASanctuaryBossSplineRunHydraProjectile> ProjectileClass;

	UPROPERTY(EditAnywhere)
	UAnimSequence IdleAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence SpitBallAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence WaveAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence DiveAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence PlayersEngageCrossbowAnimation;
	
	UPROPERTY(EditAnywhere)
	UAnimSequence HitByArrowAnimation;

	UPROPERTY(EditAnywhere)
	FName TargetCompAttachSocketName = n"Spine43";

	ESanctuaryBossSplineRunHydraPhase Phase;
	ESanctuaryBossSplineRunHydraAnimation DesiredAnimation = ESanctuaryBossSplineRunHydraAnimation::Idle;

	bool bDoAttackLoop = false;

	UPROPERTY(EditInstanceOnly)
	bool bTargetZoe = false;

	UPROPERTY(EditAnywhere)
	bool bBurstProjectiles = false;

	UPROPERTY(EditAnywhere)
	TArray<UMaterialInstance> DecapMaterials;

	UMaterialInstanceDynamic EmissiveFaceDynamicMaterial = nullptr;
	FHazeAcceleratedFloat AccEmissiveFace;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve EmissiveFaceFadeInCurve; 
	default EmissiveFaceFadeInCurve.AddDefaultKey(0.0, 0.0);
	default EmissiveFaceFadeInCurve.AddDefaultKey(0.5, 1.0);
	default EmissiveFaceFadeInCurve.AddDefaultKey(2.0, 5.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve EmissiveFaceFadeOutCurve; 
	default EmissiveFaceFadeOutCurve.AddDefaultKey(0.0, 5.0);
	default EmissiveFaceFadeOutCurve.AddDefaultKey(0.1, 0.9);
	default EmissiveFaceFadeOutCurve.AddDefaultKey(2.0, 0.0);

	// -- 
	bool bDidLateSetup = false;
	bool bDidLateActivate = false;
	float ActiveDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetComp.AttachToComponent(SkeletalMesh, TargetCompAttachSocketName, EAttachmentRule::SnapToTarget);
		SetupEmissiveFaceMaterial();
		if (DecapitatedHead != nullptr)
		{
			DecapitatedHead.AddActorDisable(this);
			DecapitatedHead.SetActorHiddenInGame(true);
		}
	}

	private void SetupEmissiveFaceMaterial()
	{
		if (SkeletalMesh.NumMaterials == 0)
			return;
		EmissiveFaceDynamicMaterial = Material::CreateDynamicMaterialInstance(this, SkeletalMesh.GetMaterial(0));
		SkeletalMesh.SetMaterial(0, EmissiveFaceDynamicMaterial);
		EmissiveFaceDynamicMaterial.SetVectorParameterValue(n"EmissiveTintMaw", FLinearColor::White * EmissiveFaceFadeInCurve.GetFloatValue(0.0));
	}

	private void LateSetup()
	{
		TListedActors<AInfuseEssenceSplineRunManager> SplineRunManagers;
		SplineRunManagers.Single.OnSanctuarySplineRunOnReachedEnd.AddUFunction(this, n"LastPlatform");
		Phase = ESanctuaryBossSplineRunHydraPhase::Appear;
		bDoAttackLoop = true;

		TListedActors<ASanctuaryBossSplineRunHydra> AllHydras;
		for (int iHydra = 0; iHydra < AllHydras.Num(); ++iHydra)
		{
			if (AllHydras[iHydra] == this)
				continue;
			OtherHydras.Add(AllHydras[iHydra]);
		}

		TListedActors<ASanctuaryHydraKillerBallista> Ballistas;
		for (auto Ballista : Ballistas)
		{
			Ballista.OnBothPlayersInteracting.AddUFunction(this, n"PlayersEngageCrossbow");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bDidLateSetup)
		{
			TListedActors<AInfuseEssenceSplineRunManager> SplineRunManagers;
			if (SplineRunManagers.Num() == 0) // level streaming
				return;
			bDidLateSetup = true;
			LateSetup();
		}

		if (bDidLateSetup && !bDidLateActivate)
		{
			ActiveDuration += DeltaSeconds;
			if (ActiveDuration > StartDelay)
			{
				bDidLateActivate = true;
				DelayedActivate();
			}
		}
	}

	bool ShouldHaveEmissiveFace() const
	{
		if (DesiredAnimation == ESanctuaryBossSplineRunHydraAnimation::Projectile)
			return true;
		return false;
	}

	UFUNCTION()
	private void LastPlatform()
	{
		if (HasControl())
			CrumbLastPlatform();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLastPlatform()
	{
		bDoAttackLoop = false;
		CutsceneDive();
		Phase = ESanctuaryBossSplineRunHydraPhase::LastPlatform;
	}

	UFUNCTION()
	void CutsceneDive()
	{
		if (HasControl())
			CrumbCutsceneDive();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbCutsceneDive()
	{
		bDoAttackLoop = false;
		Phase = ESanctuaryBossSplineRunHydraPhase::CutsceneDive;
		DesiredAnimation = ESanctuaryBossSplineRunHydraAnimation::Dive;
	}

	UFUNCTION()
	void PlayersEngageCrossbow(AHazePlayerCharacter LastInteractingPlayer)
	{
		Phase = ESanctuaryBossSplineRunHydraPhase::Crossbow;
		DesiredAnimation = ESanctuaryBossSplineRunHydraAnimation::PlayersEngageCrossbow;
		BossComp.Queue.Reset();
	}

	void HitByArrow()
	{
		DesiredAnimation = ESanctuaryBossSplineRunHydraAnimation::Dive;
		KillHydra();

		Timer::SetTimer(this, n"KillHydra", 2.0);
		for (int iHydra = 0; iHydra < OtherHydras.Num(); ++iHydra)
		{
			USanctuaryBossSplineRunHydraEventHandler::Trigger_FriendGotHit(OtherHydras[iHydra]);
			Timer::SetTimer(OtherHydras[iHydra], n"DelayedActivate", DelayResumeAttackingAfterArrow + OtherHydras[iHydra].StartDelay);
		}
	}

	UFUNCTION()
	private void KillHydra()
	{
		Timer::SetTimer(this, n"DelayedDisable", 2.0);
		if (DecapitatedHead != nullptr)
		{
			SwitchToDecapNeck();
			DecapitatedHead.RemoveActorDisable(this);
			DecapitatedHead.SetActorHiddenInGame(false);
			DecapitatedHead.PlayDecapitationAnimation(this);
		}
	}

	private void SwitchToDecapNeck()
	{
		if (DecapitatedHead == nullptr)
			return;
		if (DecapitatedSkeletalMesh != nullptr)
		{
			SkeletalMesh.SkeletalMeshAsset = DecapitatedSkeletalMesh;
			for (int iMaterial = 0; iMaterial < DecapMaterials.Num(); ++iMaterial)
				SkeletalMesh.SetMaterial(iMaterial, DecapMaterials[iMaterial]);
		}
	}

	UFUNCTION()
	private void DelayedDisable()
	{
		this.AddActorDisable(this);
		DecapitatedHead.AddActorDisable(this);
	}

	UFUNCTION()
	private void DelayedActivate()
	{
		if (HasControl())
		{
			TListedActors<AInfuseEssenceSplineRunManager> SplineRunManagers;
			if (SplineRunManagers.Num() == 0) // level streaming
				return;
			CrumbDelayedActivate(SplineRunManagers.Single.bHasStopped);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDelayedActivate(bool bHasStopped)
	{
		if (bHasStopped)
			bDoAttackLoop = false;
		else
			Phase = ESanctuaryBossSplineRunHydraPhase::AttackLoop;
	}

	UFUNCTION()
	void StopAttacking()
	{
		bDoAttackLoop = false;
	}

	UFUNCTION(BlueprintCallable)
	void NewProjectileInterval(float NewShootDelay)
	{
		SpawnInterval = NewShootDelay;
	}
};
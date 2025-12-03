enum EMedallionHydra
{
	MioLeft,
	MioRight,
	MioBack,
	ZoeLeft,
	ZoeRight,
	ZoeBack
}

namespace MedallionHydraTags
{
	const FName HydraVisibilityDeathBlocker = n"HydraVisibilityDeathBlocker";
}

event void FMedallionHydraFlyingLaserSignature();

class ASanctuaryBossMedallionHydra : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent OffsetComponent;

	UPROPERTY(DefaultComponent, Attach = OffsetComponent)
	USceneComponent BasePivot;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	USceneComponent HeadPivot;
	float HeadPivotLookAlpha = 0.0;

	UPROPERTY(DefaultComponent, Attach = HeadPivot)
	USceneComponent LaunchPivot;

	UPROPERTY(DefaultComponent, Attach = BasePivot) 
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	default SkeletalMesh.RelativeScale3D = FVector::OneVector * 0.5;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh) 
	USceneComponent TargetComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBossMedallionHydraAnimComponent AnimationComponent;
	
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(SanctuaryBossMedallionHydraSheet);

	UPROPERTY(DefaultComponent)
	private UHazeActionQueueComponent AnimationQueue;
	bool bBlockQueueIdle = false;
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent AttackQueue;
	UPROPERTY(DefaultComponent)
	USanctuaryBossMedallionHydraEmissiveFaceComponent FaceComp;
	UPROPERTY(DefaultComponent)
	USanctuaryBossMedallionHydraMovePivotComponent MoveHeadPivotComp;
	UPROPERTY(DefaultComponent)
	USanctuaryBossMedallionHydraMoveActorComponent MoveActorComp;

	UPROPERTY(EditAnywhere)
	USkeletalMesh DecapitatedSkeletalMesh;
	USkeletalMesh NormalSkeletalMesh;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	ULocomotionFeatureBossMedallionHydra LocomotionFeature;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASanctuaryBossArenaHydraProjectile> BasicProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMedallionHydraSplittingProjectile> SplittingProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMedallionHydraSplittingProjectile> QuadSplittingProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMedallionHydraFlyingProjectile> FlyingProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMedallionHydraRainProjectile> RainProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMedallionHydraBallistaProjectile> BallistaProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMedallionHydraSidescrollerSpamProjectile> SpamProjectileClass;

	UPROPERTY(EditAnywhere)
	EHazePlayer PrimaryPlayer;
	AHazePlayerCharacter TargetPlayer;

	UPROPERTY(EditAnywhere)
	FName SpitProjectileName = n"ProjectileSocket";

	UPROPERTY(EditInstanceOnly)
	EMedallionHydra HydraType;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraGhostLaser LaserActor;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraGhostLaser AboveLaserActor;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossArenaDecapitatedHead DecapitatedHead = nullptr;

	UPROPERTY(EditAnywhere)
	TArray<UMaterialInstance> DecapMaterials;

	UPROPERTY(EditAnywhere)
	UMaterialInstance NormalNeckMaterial;

	UPROPERTY()
	FMedallionHydraFlyingLaserSignature OnFlyingLaserActivated;

	float MinimumTargetableDistance = 500.0;

	ASanctuaryBossMedallionHydraReferences Refs;
	UBallistaHydraActorReferencesComponent BallistaRefs;
	bool bIsBallistaAttacked = false;

	UPROPERTY(EditInstanceOnly)
	FLinearColor DebugColor = ColorDebug::Black;

	private TInstigated<bool> bBlockLaunchProjectiles;

	TArray<FInstigator> HeadPivotBlockers;
	TArray<FInstigator> AttackedTransformOverride;
	FQuat AttackedTransformStartRotation;

	access ReadOnly = private, * (readonly);
	access:ReadOnly bool bMedallionKilled = false;
	access:ReadOnly bool bDead = false;

	bool bSubmerged = false;
	float AnimPlayerFlyingCloserAlpha = 0.0;
	bool bAllowCinematicHeadPivot = false;
	bool bIsStrangleAttacked = false;

	FString SaneName;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SanctuaryMedallionHydraDevToggles::SanctuaryMedallionHydraCategory.MakeVisible();
		TargetComp.AttachToComponent(SkeletalMesh, n"Spine41", EAttachmentRule::SnapToTarget);

		if (HydraType == EMedallionHydra::ZoeBack)
		{
			AddActorDisable(this);
			AddActorVisualsBlock(this);
		}

		FString Unused;
		String::Split(ActorNameOrLabel, "_", Unused, SaneName, ESearchCase::IgnoreCase, ESearchDir::FromEnd);

		CacheRefs();

		LaserActor.OwningHydra = this;
		AboveLaserActor.OwningHydra = this;

		TargetPlayer = Game::GetPlayer(PrimaryPlayer);
		if (DebugColor.IsAlmostBlack())
		{
			uint NameHash = Name.ToString().Hash;
			DebugColor = FLinearColor::MakeFromHSV8(uint8(NameHash % 255), 128, 255);
		}

		NormalSkeletalMesh = SkeletalMesh.SkeletalMeshAsset;
#if EDITOR
		if (SanctuaryMedallionHydraDevToggles::Hydra::AddDebugMeshComp.IsEnabled())
		{
			UHazeMeshPoseDebugComponent Comp = UHazeMeshPoseDebugComponent::GetOrCreate(this);
		}
#endif
	}

	void SetIsNotMedallionKilled()
	{
		bMedallionKilled = false;
		bDead = false;
	}

	void SetIsMedallionKilled()
	{
		bMedallionKilled = true;
	}

	void SetIsDead()
	{
		bDead = true;
		bIsStrangleAttacked = false;
	}

	UFUNCTION(BlueprintPure)
	USceneComponent GetTargetComponent() const
	{
		return TargetComp;
	}

	FTransform GetCutBoneTransform() const
	{
		return TargetComp.WorldTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Refs == nullptr)
			CacheRefs();

		if (!bIsControlledByCutscene)
			bAllowCinematicHeadPivot = false;

		TEMPORAL_LOG(this, "Hydra").Value("Animation Tag", AnimationComponent.GetFeatureTag());
		TEMPORAL_LOG(this, "Hydra").Value("Animation SubTag", AnimationComponent.GetSubFeatureTag());
		TEMPORAL_LOG(this, "Hydra").Value("Killed", bMedallionKilled);
		TEMPORAL_LOG(this, "Hydra").Value("Hidden", this.IsHidden());
		TEMPORAL_LOG(this, "Hydra").Text("Name", HeadPivot.WorldLocation, SaneName, DebugColor, 3.0);
		TEMPORAL_LOG(this, "Transforms").Value("Location", ActorLocation);
		TEMPORAL_LOG(this, "Transforms").Value("Base Pivot", BasePivot.WorldLocation);
		TEMPORAL_LOG(this, "Transforms").Value("Head Pivot", HeadPivot.WorldLocation);

		TEMPORAL_LOG(this, "Visibility").Value("Is Hidden", this.IsHidden());
		TEMPORAL_LOG(this, "Visibility").Value("Mesh Visibility", SkeletalMesh.IsVisible());

		for (int i = 0; i < HeadPivotBlockers.Num(); i++)
			TEMPORAL_LOG(this, "Hydra").Value("Pivot Blocker: " + i, HeadPivotBlockers[i]);

		if (SanctuaryMedallionHydraDevToggles::Draw::HydraTransformActor.IsEnabled() && !this.IsHidden())
		{
			ColorDebug::DrawTintedTransform(ActorLocation, ActorRotation, DebugColor, 1000);
		}
		if (SanctuaryMedallionHydraDevToggles::Draw::HydraNumberName.IsEnabled())
		{
			FLinearColor Colory = bMedallionKilled ? ColorDebug::Red : DebugColor;
			FVector NameLocation = bDead ? BasePivot.WorldLocation : HeadPivot.WorldLocation + FVector::UpVector * 500;
			FString FeatureTag = GetSaneName(FString() + AnimationComponent.GetFeatureTag(), ":");
			FString SubFeatureTag = GetSaneName(FString() + AnimationComponent.GetSubFeatureTag(), ":");
			Debug::DrawDebugString(NameLocation, SaneName + "\n\n\n" + FeatureTag + " / " + SubFeatureTag, Colory);
			if (HeadPivotBlockers.Num() > 0)
				Debug::DrawDebugString(NameLocation, "\n\n\nBlocked head pivot", ColorDebug::Red);
		}
		if (SanctuaryMedallionHydraDevToggles::Draw::HydraCutBoneTransform.IsEnabled())
		{
			FTransform CutoffBoneTransform = GetCutBoneTransform();
			ColorDebug::DrawTintedTransform(CutoffBoneTransform.Location, CutoffBoneTransform.Rotator(), FLinearColor::White, 1000);
		}
	}

	private FString GetSaneName(FString EnumName, FString Separator) const
	{
		FString Unused;
		FString Used;
		String::Split(EnumName, Separator, Unused, Used, ESearchCase::IgnoreCase, ESearchDir::FromEnd);
		return Used;
	}

	void StartAggroInbeforeDying()
	{
		OneshotAnimation(EFeatureTagMedallionHydra::BallistaAggroDeath);
	}

	void StartBallistaKillSequence()
	{
		AHazeLevelSequenceActor KillSequence = GetBallistaKillSequence();
		if (KillSequence != nullptr)
		{
			FTransform MeshTransform = SkeletalMesh.WorldTransform;
			MeshTransform.Scale3D = FVector::OneVector;
			KillSequence.SetActorTransform(MeshTransform);
			BallistaRefs.Refs.OnStartKillSequence.Broadcast(GetBallistaKillSequenceEnum(), this);
		}
	}

	void HitByArrow()
	{
		SetIsDead();
		
		DeactivateLaser();
		AttackQueue.Empty();
		AttackQueue.Idle(2.0);
		AttackQueue.Event(this, n"TriggerNextBallistaPhase");
		AttackQueue.Idle(4.0);

		AHazeLevelSequenceActor KillSequence = GetBallistaKillSequence();
		if (KillSequence == nullptr)
		{
			SwitchToDecapNeck();
			OneshotAnimation(EFeatureTagMedallionHydra::Death);
			DecapitatedHead.SetActorHiddenInGame(false);
			DecapitatedHead.PlayDecapitationAnimation(this);
			AttackQueue.Event(this, n"HideDecapHead");
		}

		USanctuaryBossMedallionHydraEventHandler::Trigger_OnDecapitation(this);
		FSanctuaryBossMedallionManagerHydraData Data;
		Data.Hydra = this;
		UMedallionHydraAttackManagerEventHandler::Trigger_OnDecapitation(Refs.HydraAttackManager, Data);
	}

	UFUNCTION(BlueprintCallable)
	void KillSequenceDone()
	{
		if (Refs.HydraAttackManager.Phase > EMedallionPhase::BallistaNearBallista3)
		{
			AddActorVisualsBlock(this);
			AddActorDisable(this);
		}
		else
		{
			SetIsDead();
			SwitchToDecapNeck();
			ClearAnimationDoIdle();
		}
	}

	private AHazeLevelSequenceActor GetBallistaKillSequence() const
	{
		if (Refs.HydraAttackManager.Phase < EMedallionPhase::Ballista1)
			return nullptr;
		if (Refs.HydraAttackManager.Phase < EMedallionPhase::Ballista2)
			return BallistaRefs.Refs.SequenceKillHydra1;
		if (Refs.HydraAttackManager.Phase < EMedallionPhase::Ballista3)
			return BallistaRefs.Refs.SequenceKillHydra2;
		else
			return BallistaRefs.Refs.SequenceKillHydra3;		
	}

	private EMedallionBallistaKillSequence GetBallistaKillSequenceEnum() const
	{
		if (Refs.HydraAttackManager.Phase < EMedallionPhase::Ballista2)
			return EMedallionBallistaKillSequence::One;
		if (Refs.HydraAttackManager.Phase < EMedallionPhase::Ballista3)
			return EMedallionBallistaKillSequence::Two;
		else
			return EMedallionBallistaKillSequence::Three;
	}

	UFUNCTION()
	private void TriggerNextBallistaPhase()
	{
		if (Refs.HydraAttackManager.Phase >= EMedallionPhase::Ballista3)
			Refs.HydraAttackManager.SetPhase(EMedallionPhase::Skydive);
		else if (Refs.HydraAttackManager.Phase >= EMedallionPhase::Ballista2)
			Refs.HydraAttackManager.SetPhase(EMedallionPhase::Ballista3);
		else if (Refs.HydraAttackManager.Phase >= EMedallionPhase::Ballista1)
			Refs.HydraAttackManager.SetPhase(EMedallionPhase::Ballista2);
	}

	UFUNCTION()
	private void HideDecapHead()
	{
		DecapitatedHead.SetActorHiddenInGame(true);
	}

	UFUNCTION()
	void BlockLaunchProjectiles(FInstigator Instigator, bool bValue = true, EInstigatePriority Priority = EInstigatePriority::Low)
	{
		bBlockLaunchProjectiles.Apply(bValue, Instigator, Priority);
	}

	UFUNCTION()
	void ClearBlockLaunchProjectiles(FInstigator Instigator)
	{
		bBlockLaunchProjectiles.Clear(Instigator);
	}

	UFUNCTION()
	bool LaunchProjectileSingle(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		if (bBlockLaunchProjectiles.Get())
		 	return false;

		OneshotAnimation(EFeatureTagMedallionHydra::ProjectileSingle, 2);
		//AttackQueue.Idle(0.25);
		AttackQueue.Event(this, n"FaceEmissiveLaunchProjectileSingle");
		AttackQueue.Idle(0.3);
		LaunchProjectileBasic(ProjectileTargetPlayer);
		return true;
	}

	UFUNCTION()
	bool LaunchProjectileTriple(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		if (bBlockLaunchProjectiles.Get())
		 	return false;

		OneshotAnimation(EFeatureTagMedallionHydra::ProjectileTripple);
		AttackQueue.Idle(0.25);

		AttackQueue.Event(this, n"FaceEmissiveLaunchProjectileTriple");
		AttackQueue.Idle(0.25);
		LaunchProjectileBasic(ProjectileTargetPlayer, -1000.0);
		AttackQueue.Idle(0.2);
		LaunchProjectileBasic(ProjectileTargetPlayer);
		AttackQueue.Idle(0.2);
		LaunchProjectileBasic(ProjectileTargetPlayer, 1000.0);
		return true;
	}

	UFUNCTION()
	bool LaunchSplittingProjectile2(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		if (bBlockLaunchProjectiles.Get())
		 	return false;
		
		OneshotAnimation(EFeatureTagMedallionHydra::ProjectileSingle, 2);
		AttackQueue.Idle(0.25);

		AttackQueue.Event(this, n"FaceEmissiveLaunchProjectileSingle");
		AttackQueue.Idle(0.25);
		LaunchProjectileSplitting(ProjectileTargetPlayer);
		return true;
	}

	UFUNCTION()
	bool LaunchSplittingProjectileSetOffset(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		if (bBlockLaunchProjectiles.Get())
		 	return false;
		
		OneshotAnimation(EFeatureTagMedallionHydra::ProjectileSingle, 2);
		AttackQueue.Idle(0.25);

		AttackQueue.Event(this, n"FaceEmissiveLaunchProjectileSingle");
		AttackQueue.Idle(0.25);
		LaunchProjectileSplittingSetOffset(ProjectileTargetPlayer);
		return true;
	}

	UFUNCTION()
	bool LaunchSplittingProjectileQuad(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		if (bBlockLaunchProjectiles.Get())
		 	return false;
		
		OneshotAnimation(EFeatureTagMedallionHydra::ProjectileSingle, 2);
		AttackQueue.Idle(0.25);

		AttackQueue.Event(this, n"FaceEmissiveLaunchProjectileSingle");
		AttackQueue.Idle(0.25);
		LaunchProjectileSplittingQuad(ProjectileTargetPlayer);
		return true;
	}

	UFUNCTION()
	bool LaunchSplittingProjectileTriple(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		if (bBlockLaunchProjectiles.Get())
		 	return false;
		
		OneshotAnimation(EFeatureTagMedallionHydra::ProjectileTripple, 5.0);
		AttackQueue.Idle(0.25);

		AttackQueue.Event(this, n"FaceEmissiveLaunchProjectileTriple");
		AttackQueue.Idle(0.25);
		LaunchProjectileSplitting(ProjectileTargetPlayer, -800.0);
		AttackQueue.Idle(1.0);
		LaunchProjectileSplitting(ProjectileTargetPlayer);
		AttackQueue.Idle(1.0);
		LaunchProjectileSplitting(ProjectileTargetPlayer, 800.0);
		return true;
	}

	UFUNCTION()
	bool LaunchProjectileFlyingSingle(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		if (bBlockLaunchProjectiles.Get())
		 	return false;
		
		OneshotAnimation(EFeatureTagMedallionHydra::ProjectileFlying, 2);
		//AttackQueue.Idle(0.25);
		AttackQueue.Event(this, n"FaceEmissiveLaunchProjectileSingle");
		AttackQueue.Idle(0.3);
		LaunchProjectileFlying(ProjectileTargetPlayer);
		return true;
	}

	UFUNCTION()
	void CallLaunchProjectileSpam(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		AttackQueue.Event(this, n"FaceEmissiveLaunchProjectileSingle");
		LaunchProjectileSpam(ProjectileTargetPlayer);
	}

	UFUNCTION()
	bool RainAttack(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		if (bBlockLaunchProjectiles.Get())
		 	return false;
		
		OneshotAnimation(EFeatureTagMedallionHydra::RainAttack, AnimationDuration = 5.5);
		AttackQueue.Idle(0.25);
		AttackQueue.Idle(0.15);
		AttackQueue.Event(this, n"FaceEmissiveLaunchProjectileSingle");
		for (int i = 0; i < 20; i++)
		{
			LaunchProjectileRain(ProjectileTargetPlayer, i * 0.1 + 1.0);
			AttackQueue.Idle(0.05);
		}

		FSanctuaryBossMedallionManagerEventPlayerAttackData Params;
		Params.AttackType = EMedallionHydraAttack::RainAttack;
		Params.Hydra = this;
		Params.TargetPlayer = ProjectileTargetPlayer;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnStartRainAttack(Refs.HydraAttackManager ,Params);
		return true;
	}

	UFUNCTION()
	void FlyingSlashLaser(AHazePlayerCharacter LaserTargetPlayer)
	{	
		ActivateFlyingLaser();
	}

	UFUNCTION()
	bool BallistaProjectiles(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		if (bBlockLaunchProjectiles.Get())
		 	return false;
		
		OneshotAnimation(EFeatureTagMedallionHydra::ProjectileTripple, AnimationDuration = 4.5);
		AttackQueue.Idle(0.32);
		AttackQueue.Event(this, n"FaceEmissiveLaunchProjectileTriple");
		AttackQueue.Idle(0.5);

		for (int i = 0; i < 3; i++)
		{
			LaunchBallistaTargetingProjectile(ProjectileTargetPlayer);
			AttackQueue.Idle(0.2);
			LaunchBallistaTargetingProjectile(ProjectileTargetPlayer.OtherPlayer);
			AttackQueue.Idle(0.2);
		}

		LaunchBallistaTargetingProjectileOnPlayer(ProjectileTargetPlayer);
		AttackQueue.Idle(0.2);
		LaunchBallistaTargetingProjectileOnPlayer(ProjectileTargetPlayer.OtherPlayer);
		return true;
	}

	private void LaunchProjectileBasic(AHazePlayerCharacter ProjectileTargetPlayer, float Offset = 0.0)
	{
		FMedallionHydraLaunchProjectileParams ParamsParams;
		ParamsParams.PredictedLocationOffset = Offset;
		ParamsParams.TargetPlayer = ProjectileTargetPlayer;

		FMedallionHydraMultipleLaunchProjectileParams Params;
		Params.LaunchProjectileParams.Add(ParamsParams);
		AttackQueue.Capability(UMedallionHydraLaunchProjectileCapability, Params);
	}

	private void LaunchProjectileSplitting(AHazePlayerCharacter ProjectileTargetPlayer, float Offset = 0.0)
	{
		FMedallionHydraLaunchProjectileParams ParamsParams;
		ParamsParams.Type = EMedallionHydraProjectileType::Splitting;
		ParamsParams.PredictedLocationOffset = Offset;
		ParamsParams.TargetPlayer = ProjectileTargetPlayer;

		FMedallionHydraMultipleLaunchProjectileParams Params;
		Params.LaunchProjectileParams.Add(ParamsParams);
		AttackQueue.Capability(UMedallionHydraLaunchProjectileCapability, Params);
	}

	private void LaunchProjectileSplittingSetOffset(AHazePlayerCharacter ProjectileTargetPlayer, float Offset = 2200.0)
	{
		FMedallionHydraLaunchProjectileParams ParamsParams;
		ParamsParams.Type = EMedallionHydraProjectileType::SplittingSetOffset;
		ParamsParams.PredictedLocationOffset = Offset;
		ParamsParams.TargetPlayer = ProjectileTargetPlayer;

		FMedallionHydraMultipleLaunchProjectileParams Params;
		Params.LaunchProjectileParams.Add(ParamsParams);
		AttackQueue.Capability(UMedallionHydraLaunchProjectileCapability, Params);
	}

	private void LaunchProjectileSplittingQuad(AHazePlayerCharacter ProjectileTargetPlayer, float Offset = 0.0)
	{
		FMedallionHydraLaunchProjectileParams ParamsParams;
		ParamsParams.Type = EMedallionHydraProjectileType::SplittingQuad;
		ParamsParams.PredictedLocationOffset = Offset;
		ParamsParams.TargetPlayer = ProjectileTargetPlayer;

		FMedallionHydraMultipleLaunchProjectileParams Params;
		Params.LaunchProjectileParams.Add(ParamsParams);
		AttackQueue.Capability(UMedallionHydraLaunchProjectileCapability, Params);
	}

	private void LaunchProjectileFlying(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		FMedallionHydraLaunchProjectileParams ParamsParams;
		ParamsParams.Type = EMedallionHydraProjectileType::Flying;
		ParamsParams.TargetPlayer = ProjectileTargetPlayer;

		FMedallionHydraMultipleLaunchProjectileParams Params;
		Params.LaunchProjectileParams.Add(ParamsParams);
		AttackQueue.Capability(UMedallionHydraLaunchProjectileCapability, Params);
	}

	private void LaunchProjectileRain(AHazePlayerCharacter ProjectileTargetPlayer, float WaitDuration)
	{
		FMedallionHydraLaunchProjectileParams ParamsParams;
		ParamsParams.Type = EMedallionHydraProjectileType::Rain;
		ParamsParams.TargetPlayer = ProjectileTargetPlayer;
		ParamsParams.PredictedLocationOffset = WaitDuration;

		FMedallionHydraMultipleLaunchProjectileParams Params;
		Params.LaunchProjectileParams.Add(ParamsParams);
		AttackQueue.Capability(UMedallionHydraLaunchProjectileCapability, Params);
	}

	private void LaunchProjectileSpam(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		FMedallionHydraLaunchProjectileParams ParamsParams;
		ParamsParams.Type = EMedallionHydraProjectileType::Spam;
		ParamsParams.TargetPlayer = ProjectileTargetPlayer;

		FMedallionHydraMultipleLaunchProjectileParams Params;
		Params.LaunchProjectileParams.Add(ParamsParams);
		AttackQueue.Capability(UMedallionHydraLaunchProjectileCapability, Params);
	}

	private void LaunchBallistaTargetingProjectile(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		FMedallionHydraLaunchProjectileParams ParamsParams;
		ParamsParams.Type = EMedallionHydraProjectileType::BallistaRain;
		ParamsParams.TargetPlayer = ProjectileTargetPlayer;
		ParamsParams.PredictedLocationOffset = 2000.0;

		FMedallionHydraMultipleLaunchProjectileParams Params;
		Params.LaunchProjectileParams.Add(ParamsParams);
		AttackQueue.Capability(UMedallionHydraLaunchProjectileCapability, Params);
	}

	private void LaunchBallistaTargetingProjectileOnPlayer(AHazePlayerCharacter ProjectileTargetPlayer)
	{
		FMedallionHydraLaunchProjectileParams ParamsParams;
		ParamsParams.Type = EMedallionHydraProjectileType::BallistaRainOnPlayer;
		ParamsParams.TargetPlayer = ProjectileTargetPlayer;

		FMedallionHydraMultipleLaunchProjectileParams Params;
		Params.LaunchProjectileParams.Add(ParamsParams);
		AttackQueue.Capability(UMedallionHydraLaunchProjectileCapability, Params);
	}

	void ActivateLaser(float TelegraphDuration = -1.0, bool bKnockback = false, EMedallionHydraLaserType LaserType = EMedallionHydraLaserType::None)
	{	
		LaserActor.AttachToComponent(SkeletalMesh, n"LaserSocket", EAttachmentRule::SnapToTarget);
		LaserActor.ActivateLaser(TelegraphDuration, bKnockback, LaserType);
	}

	void DeactivateLaser()
	{
		LaserActor.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		LaserActor.DeactivateLaser();
	}

	void ActivateAboveLaser(float TelegraphDuration = -1.0, bool bKnockback = false)
	{	
		AboveLaserActor.AttachToComponent(SkeletalMesh, n"LaserSocket", EAttachmentRule::SnapToTarget);
		AboveLaserActor.ActivateLaser(TelegraphDuration, bKnockback, EMedallionHydraLaserType::SidescrollerAbove);
	}

	void DeactivateAboveLaser()
	{
		AboveLaserActor.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		AboveLaserActor.DeactivateLaser();
	}

	private void ActivateFlyingLaser()
	{
		OnFlyingLaserActivated.Broadcast();
	}

	UFUNCTION()
	private void FaceEmissiveLaunchProjectileSingle()
	{
		FaceComp.RequestEmissiveFace(this, SanctuaryBossMedallionHydraEmissiveFaceCurve_LaunchProjectileSingle);
	}

	UFUNCTION()
	private void FaceEmissiveLaunchProjectileTriple()
	{
		FaceComp.RequestEmissiveFace(this, SanctuaryBossMedallionHydraEmissiveFaceCurve_LaunchProjectileTriple);
	}

	bool ShouldIdle() const
	{
		return AnimationQueue.Num() <= 1 && !bBlockQueueIdle;
	}

	UFUNCTION(NotBlueprintCallable)
	void ClearAnimationDoIdle()
	{
		AnimationQueue.Empty();
		AppendIdleAnimation();
	}

	UFUNCTION(NotBlueprintCallable)
	void AppendIdleAnimation()
	{
		// DONT empty queue
		FSanctuaryMedallionHydraAnimationActionParams AnimationParams;
		AnimationParams.Tag = EFeatureTagMedallionHydra::None_Idling;
		AnimationParams.SubTag = EFeatureSubTagMedallionHydra::Action;
		AnimationParams.CustomDuration = -1.0;
		AnimationQueue.Capability(USanctuaryMedallionHydraAnimationCapability, AnimationParams);
		AnimationQueue.Idle(100000000000000000000000000000.0);
	}

	UFUNCTION(NotBlueprintCallable)
	void AppendAnimation(EFeatureTagMedallionHydra Tag, EFeatureSubTagMedallionHydra SubTag, bool bEmptyQueue = false, bool bThenIdle = false, float AnimationDuration = -1.0)
	{
		bBlockQueueIdle = true;
		if (bEmptyQueue)
			AnimationQueue.Empty();
		FSanctuaryMedallionHydraAnimationActionParams AnimationParams;
		AnimationParams.Tag = Tag;
		AnimationParams.SubTag = SubTag;
		AnimationParams.CustomDuration = AnimationDuration;
		AnimationQueue.Capability(USanctuaryMedallionHydraAnimationCapability, AnimationParams);
		bBlockQueueIdle = false;
		if (bThenIdle)
			AnimationQueue.Idle(100000000000000000000000000000.0);
	}

	UFUNCTION(NotBlueprintCallable)
	void OneshotAnimation(EFeatureTagMedallionHydra Tag, float AnimationDuration = -1.0)
	{
		bBlockQueueIdle = true;
		AnimationQueue.Empty();
		FSanctuaryMedallionHydraAnimationActionParams AnimationParams;
		AnimationParams.Tag = Tag;
		AnimationParams.SubTag = EFeatureSubTagMedallionHydra::Action;
		AnimationParams.CustomDuration = AnimationDuration;
		AnimationQueue.Capability(USanctuaryMedallionHydraAnimationCapability, AnimationParams);
		bBlockQueueIdle = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void OneshotAnimationThenWait(EFeatureTagMedallionHydra Tag, float AnimationDuration = -1.0)
	{
		OneshotAnimation(Tag, AnimationDuration);
		AnimationQueue.Idle(100000000000000000000000000000.0);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterMhAnimation(EFeatureTagMedallionHydra Tag, float AnimationEnterDuration = -1.0, float AnimationMhDuration = -1.0)
	{
		bBlockQueueIdle = true;
		AnimationQueue.Empty();
		{
			FSanctuaryMedallionHydraAnimationActionParams AnimationParams;
			AnimationParams.Tag = Tag;
			AnimationParams.SubTag = EFeatureSubTagMedallionHydra::Start;
			AnimationParams.CustomDuration = AnimationEnterDuration;
			AnimationQueue.Capability(USanctuaryMedallionHydraAnimationCapability, AnimationParams);
		}
		{
			FSanctuaryMedallionHydraAnimationActionParams AnimationParams;
			AnimationParams.Tag = Tag;
			AnimationParams.SubTag = EFeatureSubTagMedallionHydra::Mh;
			AnimationParams.CustomDuration = AnimationMhDuration;
			AnimationQueue.Capability(USanctuaryMedallionHydraAnimationCapability, AnimationParams);
			AnimationQueue.Idle(100000000000000000000000000000.0);
		}
		bBlockQueueIdle = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitMhAnimation(EFeatureTagMedallionHydra Tag, float AnimationDuration = -1.0)
	{
		bBlockQueueIdle = true;
		AnimationQueue.Empty();
		FSanctuaryMedallionHydraAnimationActionParams AnimationParams;
		AnimationParams.Tag = Tag;
		AnimationParams.SubTag = EFeatureSubTagMedallionHydra::End;
		AnimationParams.CustomDuration = AnimationDuration;
		AnimationQueue.Capability(USanctuaryMedallionHydraAnimationCapability, AnimationParams);
		bBlockQueueIdle = false;
	}

	private void CacheRefs()
	{
		BallistaRefs = UBallistaHydraActorReferencesComponent::GetOrCreate(Game::Mio);
		TListedActors<ASanctuaryBossMedallionHydraReferences> ListedRefs;
		Refs = ListedRefs.Single;

		if (Refs != nullptr)
			Refs.HydraAttackManager.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");
	}

	UFUNCTION()
	private void HandlePhaseChanged(EMedallionPhase Phase, bool bNaturalProgression)
	{
		if (Phase == EMedallionPhase::Merge1 ||
			Phase == EMedallionPhase::Merge2 ||
			Phase == EMedallionPhase::Merge3 ||
			Phase == EMedallionPhase::BallistaPlayersAiming1 ||
			Phase == EMedallionPhase::BallistaPlayersAiming2 ||
			Phase == EMedallionPhase::BallistaPlayersAiming3
			)
		{
			AttackQueue.Empty();
		}
		if (Phase == EMedallionPhase::Ballista1 && !bDead)
			HeadPivotBlockers.Remove(MedallionConstants::Tags::StrangleBlockHeadPivot);

		FSanctuaryBossMedallionHydraEventPhaseData Data;
		Data.Phase = Phase;
		USanctuaryBossMedallionHydraEventHandler::Trigger_OnBossPhaseChanged(this, Data);
	}

	UFUNCTION()
	void SetSubmerged(bool bNewSubmerged)
	{
		bSubmerged = bNewSubmerged;

		if (bSubmerged)
			BlockLaunchProjectiles(this);
		else
			ClearBlockLaunchProjectiles(this);
	}
	
	UFUNCTION()
	void SwitchToDecapNeck()
	{
		HeadPivotBlockers.AddUnique(MedallionConstants::Tags::StrangleBlockHeadPivot);
		
		if (DecapitatedSkeletalMesh != nullptr)
		{
			SkeletalMesh.SkeletalMeshAsset = DecapitatedSkeletalMesh;
			for (int iMaterial = 0; iMaterial < DecapMaterials.Num(); ++iMaterial)
				SkeletalMesh.SetMaterial(iMaterial, DecapMaterials[iMaterial]);
		}
	}

	UFUNCTION()
	void ResetDecapNeck()
	{
		if (NormalSkeletalMesh != nullptr)
			SkeletalMesh.SkeletalMeshAsset = NormalSkeletalMesh;
		if (NormalNeckMaterial != nullptr && FaceComp.EmissiveFaceDynamicMaterial != nullptr)
		{
			SkeletalMesh.SetMaterial(0, FaceComp.EmissiveFaceDynamicMaterial);
			SkeletalMesh.SetMaterial(1, NormalNeckMaterial);
		}
	}
};
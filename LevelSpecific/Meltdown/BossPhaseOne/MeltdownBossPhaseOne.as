enum EMeltdownPhaseOneAttack
{
	None,

	// Stage 1 Attack 1 - Drop
	Drop,
	// Stage 1 Attack 2 - Cylinder
	Cylinder,
	// Stage 1 Attack 3 - ShockwaveArrow
	ShockwaveArrow,

	// Stage 3 Attack 1 - Line
	Line,
	// Stage 3 Attack 2 - Slam
	Slam,
	// Stage 3 Attack 3 - Seek Slam
	SeekSlam,
}

struct FArenaBlocksColumn
{
	UPROPERTY()
	TArray<AMeltdownBossCubeGrid> Blocks;
}

class AMeltdownBossPhaseOne : AMeltdownBoss
{
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseOneDropAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseOneCylinderAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseOneShockwaveArrowAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseOneLineAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseOneSlamCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseOneSeekSlamCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseOneIdleCapability);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	EMeltdownPhaseOneAttack CurrentAttack;

	UPROPERTY(EditInstanceOnly)
	AHazeActor ArenaRoot;
	UPROPERTY(EditInstanceOnly)
	TArray<FArenaBlocksColumn> ArenaBlocks;
	UPROPERTY()
	FVector2D ArenaExtent(2000.0, 2000.0);

	UPROPERTY(EditInstanceOnly)
	AMeltdownBossPhaseOneCubeGridPositioner SeekSlamGridPositioner;
	UPROPERTY(EditInstanceOnly)
	AMeltdownBossPhaseOneCubeGridPositioner SlamGridPositioner;
	UPROPERTY(EditInstanceOnly)
	AMeltdownBossPhaseOneCubeGridPositioner ShockwaveArrowGridPositioner;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseOneSmashAttack> SmashAttackClass;

	UPROPERTY(EditInstanceOnly)
	AMeltdownBossBattleGridSpinner SpinnerAttack;
	UPROPERTY(EditInstanceOnly)
	TArray<UAnimSequence> BendAnimations;
	UPROPERTY(EditInstanceOnly)
	TArray<UAnimSequence> UnbendAnimations;

	UPROPERTY(EditInstanceOnly)
	TArray<AMeltdownBossPhaseOneMissileAttack> ShockwaveArrowAttacks;

	UPROPERTY(EditInstanceOnly)
	TArray<AMeltdownBossPhaseOneLineAttack> LineAttacks;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UHazeSoundDefBase> ShockwaveSoundDef;

	uint32 LastSlamFrame = 0;
	uint32 LastSlamAnticipateFrame = 0;
	float LeftHandTrackingValue = 0.0;
	float RightHandTrackingValue = 0.0;

	float PlatformMoveAlpha = 0.0;
	int PlatformMoveIndex = 0;

	uint32 LastShootLeftHandFrame = 0;
	uint32 LastShootRightHandFrame = 0;
	float LateralVelocity = 0.0;

	bool bLineAttacksCauseChasms = false;

	uint LastSlideAttackFrame = 0;
	bool bSlideMoving = false;
	float SlideLeanValue = 0.0;

	FTransform OriginalTransform;
	FName IdleFeature;
	TPerPlayer<float> StuckTimer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalTransform = ActorTransform;
		Super::BeginPlay();
	}

	UFUNCTION()
	void StartAttack(EMeltdownPhaseOneAttack Attack)
	{
		CurrentAttack = Attack;
	}

	UFUNCTION()
	void SetLineAttacksCauseChasms(bool bCauseChasms)
	{
		bLineAttacksCauseChasms = bCauseChasms;
	}

	UFUNCTION()
	void StopAttacking()
	{
		CurrentAttack = EMeltdownPhaseOneAttack::None;
	}

	FVector2D GetPositionWithinArena(FVector Location) const
	{
		FVector RelativeLocation = ArenaRoot.ActorTransform.InverseTransformPosition(Location);
		return FVector2D(
			Math::Clamp(RelativeLocation.X / ArenaExtent.X, -1, 1),
			Math::Clamp(RelativeLocation.Y / ArenaExtent.Y, -1, 1));
	}

	FVector GetRaderLocationAtArenaOffset(float LateralOffset) const
	{
		FVector LocalPosition = ArenaRoot.ActorTransform.InverseTransformPosition(OriginalTransform.Location);
		LocalPosition.X += LateralOffset * ArenaExtent.X;
		return ArenaRoot.ActorTransform.TransformPosition(LocalPosition);
	}

	UFUNCTION()
	void DisableAllShockwaves()
	{
		for (auto ShockWave : TListedActors<AMeltdownBossPhaseOneShockwave>().CopyAndInvalidate())
			ShockWave.DestroyActor();
		for (auto Missile : TListedActors<AMeltdownBossPhaseOneShockwaveMissile>().CopyAndInvalidate())
			Missile.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		// Check if the player is overlapping with something blocked (ie stuck in geometry)
		// This can happen sometimes if a bonanza split closes around them
		// If the player is stuck for a little while, just kill them
		for (auto Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;

			FHazeTraceSettings Trace;
			Trace.TraceWithPlayer(Player);
			FOverlapResultArray Overlaps = Trace.QueryOverlaps(Player.ActorLocation);

			bool bIsInsideCubeGrid = false;
			for (auto Overlap : Overlaps)
			{
				if (Overlap.bBlockingHit && Overlap.Actor != nullptr && Overlap.Actor.IsA(AMeltdownBossCubeGrid))
				{
					bIsInsideCubeGrid = true;
				}
			}

			if (bIsInsideCubeGrid && !Player.bIsControlledByCutscene && !Player.IsPlayerDead())
			{
				StuckTimer[Player] += DeltaSeconds;
				if (StuckTimer[Player] > 1.0)
					Player.KillPlayer();
			}
			else
			{
				StuckTimer[Player] = 0.0;
			}
		}
	}
}
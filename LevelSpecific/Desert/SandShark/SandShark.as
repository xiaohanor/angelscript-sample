UCLASS(Abstract)
class ASandShark : AHazeActor
{
	access AnimationInternal = private, USandSharkAnimationComponent, USandSharkHeightCapability;
	access ExternalReadOnly = private, *(readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SharkRoot;

	UPROPERTY(DefaultComponent, BlueprintReadOnly, Attach = SharkRoot)
	access:AnimationInternal UHazeCharacterSkeletalMeshComponent SharkMesh;

	UPROPERTY(DefaultComponent, Attach = SharkMesh, AttachSocket = "Head")
	USphereComponent SphereComp;
	default SphereComp.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = SharkRoot)
	UNiagaraComponent TrailComp;
	default TrailComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	USandSharkMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UPathfollowingMoveToComponent MoveToComp;

	UPROPERTY(DefaultComponent)
	UBasicAIDestinationComponent DestinationComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SandSharkPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SandSharkIdleDestinationCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SandSharkHeightCapability");

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditDefaultsOnly, Category = "Sand Shark")
	TSubclassOf<UDeathEffect> CatchPlayerDeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Sand Shark")
	ESandSharkLandscapeLevel LandscapeLevel;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bDrawDisableRange = true;
	default DisableComp.AutoDisableRange = 20000;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedRootLocationComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedMeshLocationComp;

	// Chase
	bool bIsChasing;
	private AHazePlayerCharacter TargetPlayer_Internal;

	AHazePlayerCharacter PreviouslySwingingPlayer;

	float TimeWhenActivatedRockAvoidanceSettings = 0;

	float TimeWhenStartedChasing = 0;
	TPerPlayer<float> TimeWhenChasedTarget;

	FHazeRuntimeSpline AnimationSpline;

	UPROPERTY(EditInstanceOnly)
	USandSharkSettings SharkDefaultSettingsOverride;

	USandSharkSettings SharkSettings;

	bool bCanAttack = false;
	bool bIsDistractedByGroundPounder = false;

	access: ExternalReadOnly TArray<FSandSharkThumperDistractionParams> QueuedThumperDistractionParams;

	UPROPERTY(EditInstanceOnly)
	ASandSharkTerritorySpline TerritorySpline;

	UPathfollowingSettings PathFollowSettings;
	UGroundPathfollowingSettings GroundSettings;

	FHazeAcceleratedFloat AccMeshForwardOffset;

	bool bIsAvoidingObstacles;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccMeshForwardOffset.SnapTo(-530);
		ApplyDefaultSettings(SandShark::PathFollowSettings);
		ApplyDefaultSettings(SandShark::GroundPathFollowSettings);
		PathFollowSettings = UPathfollowingSettings::GetSettings(this);
		GroundSettings = UGroundPathfollowingSettings::GetSettings(this);
		devCheck(TerritorySpline != nullptr, f"{Name} has no assigned territory!");

		if (SharkDefaultSettingsOverride != nullptr)
			ApplyDefaultSettings(SharkDefaultSettingsOverride);

		SharkSettings = USandSharkSettings::GetSettings(this);

		FHazeDevToggleBool ShouldBeDisabled = FHazeDevToggleBool(FHazeDevToggleCategory(FName(f"SandShark")), FName(f"{ActorNameOrLabel} ShouldBeDisabled"));
		ShouldBeDisabled.MakeVisible();
		ShouldBeDisabled.BindOnChanged(this, n"OnShouldBeDisabledChanged");
		if (ShouldBeDisabled.IsEnabled())
		{
			AddActorDisable(this);
		}
	}

	UFUNCTION()
	private void OnShouldBeDisabledChanged(bool bNewState)
	{
		if (bNewState)
		{
			AddActorDisable(this);
		}
		else
		{
			RemoveActorDisable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		auto ThumperSection = TEMPORAL_LOG(this).Section("Thumper");
		ThumperSection.Value("bIsDistractedByGroundPounder", bIsDistractedByGroundPounder);

		auto ChaseSection = TEMPORAL_LOG(this).Section("Chase");
		ChaseSection.Value("TargetPlayer", TargetPlayer_Internal);
		ChaseSection.Value("Territory", TerritorySpline);

		auto AnimationSection = TEMPORAL_LOG(this).Section("Animation");
		AnimationSection.RuntimeSpline("AnimationSpline", AnimationSpline, FLinearColor::LucBlue);
		AnimationSection.Sphere("HeadLocation", HeadLocation, SphereComp.SphereRadius, FLinearColor::LucBlue, 5);
		AnimationSection.Sphere("HeadBoneLocation", SharkMesh.GetSocketLocation(n"Head"), SphereComp.SphereRadius, FLinearColor::Purple, 5);
		AnimationSection.Value("AccMeshForwardOffset", AccMeshForwardOffset.Value);

		auto NavigationSection = TemporalLog.Section("Navigation");
		NavigationSection.Value("FollowSpline", DestinationComp.FollowSpline);
		NavigationSection.Value("Speed", DestinationComp.Speed);
		if (MoveToComp.Path.IsValid())
		{
			FHazeRuntimeSpline PathSpline;
			PathSpline.Points = MoveToComp.Path.Points;
			NavigationSection.RuntimeSpline("Path", PathSpline);
		}
#endif
	}

	void QueueDistractionParams(FSandSharkThumperDistractionParams Params)
	{
		QueuedThumperDistractionParams.AddUnique(Params);
	}

	void RemoveDistractionParamsFromQueue(FSandSharkThumperDistractionParams Params)
	{
		if (QueuedThumperDistractionParams.Contains(Params))
			QueuedThumperDistractionParams.Remove(Params);
	}

	bool GetQueuedDistractionParams(FSandSharkThumperDistractionParams& OutDistractionParams) const
	{
		if (QueuedThumperDistractionParams.Num() == 0)
			return false;

		OutDistractionParams = QueuedThumperDistractionParams[0];
		return true;
	}

	TArray<FSandSharkThumperDistractionParams> GetQueuedDistractionSplines() const
	{
		return QueuedThumperDistractionParams;
	}

	bool IsAffectedByThumpers() const
	{
		return QueuedThumperDistractionParams.Num() > 0;
	}

	bool CheckPlayerInsideTerritory(AHazePlayerCharacter Player) const
	{
		return TerritorySpline.CheckPlayerInsideSpline(Player) && TerritorySpline.PlayerIgnoreTriggerOverlapCount[Player] <= 0;
	}

	FHazeTraceSettings GetTraceSettings(float SphereRadius) const
	{
		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic, n"SandShark");
		Settings.UseSphereShape(SphereRadius);
		Settings.IgnoreActor(Desert::GetLandscapeActor(LandscapeLevel));
		Settings.IgnoreActor(this);
		Settings.IgnorePlayers();
		// Settings.DebugDraw(1);
		return Settings;
	}

	FVector GetHeadLocation() const property
	{
		return SphereComp.WorldLocation;
	}

	bool IsHeadAboveLandscape() const
	{
		auto SandHeight = Desert::GetLandscapeHeightByLevel(HeadLocation, ESandSharkLandscapeLevel::Lower);
		return HeadLocation.Z - SandHeight > 0;
	}

	bool AttemptKillPlayersAtMouth(TArray<AHazePlayerCharacter>&out OutKilledPlayers)
	{
		for (auto Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			if (Player.IsPlayerRespawning())
				continue;

			const float Distance = SphereComp.WorldLocation.Distance(Player.ActorCenterLocation);
			if (Distance < SphereComp.ScaledSphereRadius)
			{
				CrumbKillPlayer(Player);
				OutKilledPlayers.Add(Player);
			}
		}
		return OutKilledPlayers.Num() > 0;
	}

	bool IsPlayerAtHead(AHazePlayerCharacter Player)
	{
		return SphereComp.WorldLocation.Distance(Player.ActorCenterLocation) < SphereComp.ScaledSphereRadius;
	}

	bool AttemptKillPlayersInBox(FVector Location, FQuat Rotation, FVector Extents, TArray<AHazePlayerCharacter>&out OutKilledPlayers)
	{
		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		Settings.IgnoreActor(this);
		Settings.UseBoxShape(Extents, Rotation);
		// Settings.DebugDraw(1);

		auto Overlaps = Settings.QueryOverlaps(Location);
		for (auto Overlap : Overlaps)
		{
			if (Overlap.Actor.IsA(AHazePlayerCharacter))
			{
				auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
				if (Player.IsPlayerDead())
					continue;

				if (Player.IsPlayerRespawning())
					continue;

				CrumbKillPlayer(Player);
				OutKilledPlayers.Add(Player);
			}
		}
		return OutKilledPlayers.Num() > 0;
	}

	UFUNCTION(CrumbFunction)
	void CrumbKillPlayer(AHazePlayerCharacter Player)
	{
		Player.KillPlayer(FPlayerDeathDamageParams(FVector::DownVector, 5.0), CatchPlayerDeathEffect);
	}

	bool IsPlayerAttackable(AHazePlayerCharacter Player) const
	{
		auto PlayerComp = USandSharkPlayerComponent::Get(Player);

		if (Player.IsPlayerDead() || Player.IsPlayerRespawning())
			return false;

		auto PlayerMoveComp = UPlayerMovementComponent::Get(GetTargetPlayer());

		if (!PlayerComp.bHasTouchedSand && PlayerMoveComp.HasGroundContact())
			return false;

		if (PlayerComp.bIsPerching)
			return false;

		if (PlayerComp.bOnSafePoint)
			return false;

		return true;
	}

	bool IsTargetPlayerAttackable() const
	{
		check(HasTargetPlayer());
		return IsPlayerAttackable(GetTargetPlayer());
	}

	AHazePlayerCharacter GetTargetPlayer() const
	{
		check(HasTargetPlayer());
		return TargetPlayer_Internal;
	}

	bool IsTargetPlayer(AHazePlayerCharacter Player) const
	{
		return Player == TargetPlayer_Internal;
	}

	bool HasTargetPlayer() const
	{
		return TargetPlayer_Internal != nullptr;
	}

	FVector GetTargetPlayerLocationOnLandscape() const
	{
		check(HasTargetPlayer());
		return Desert::GetLandscapeLocation(GetTargetPlayer().ActorLocation);
	}

	FVector GetTargetPlayerLocationOnLandscapeByLevel(ESandSharkLandscapeLevel InLandscapeLevel) const
	{
		check(HasTargetPlayer());
		return Desert::GetLandscapeLocationByLevel(GetTargetPlayer().ActorLocation, InLandscapeLevel);
	}

	USandSharkPlayerComponent GetTargetPlayerComponent() const
	{
		check(HasTargetPlayer());
		return USandSharkPlayerComponent::Get(GetTargetPlayer());
	}

	ASandSharkSpline GetTargetPlayerSafePointSpline() const
	{
		auto PlayerComp = GetTargetPlayerComponent();
		if (PlayerComp == nullptr)
			return nullptr;

		if (PlayerComp.LastSafePoint == nullptr)
			return nullptr;

		return PlayerComp.LastSafePoint.Spline;
	}

	void SetTargetPlayer(AHazePlayerCharacter Player)
	{
		TargetPlayer_Internal = Player;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetTargetPlayer(AHazePlayerCharacter NewTargetPlayer)
	{
		SetTargetPlayer(NewTargetPlayer);
		USandSharkPlayerComponent::Get(NewTargetPlayer).AddHuntedInstigator(this);
	}

	UFUNCTION(BlueprintPure)
	ASandSharkSpline GetCurrentSpline() const
	{
		return MoveComp.CurrentSpline.Get();
	}

	UFUNCTION(BlueprintCallable)
	void BlockChase(FInstigator Instigator)
	{
		BlockCapabilities(SandSharkTags::SandSharkChase, Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void UnblockChase(FInstigator Instigator)
	{
		UnblockCapabilities(SandSharkTags::SandSharkChase, Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void BlockAttacks(FInstigator Instigator)
	{
		BlockCapabilities(SandSharkTags::SandSharkAttackFromBelow, Instigator);
		BlockCapabilities(SandSharkTags::SandSharkLunge, Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void UnblockAttacks(FInstigator Instigator)
	{
		UnblockCapabilities(SandSharkTags::SandSharkAttackFromBelow, Instigator);
		UnblockCapabilities(SandSharkTags::SandSharkLunge, Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void SetActiveTerritory(ASandSharkTerritorySpline NewTerritory)
	{
		TerritorySpline = NewTerritory;
	}

	UFUNCTION(BlueprintCallable)
	void GoToSpline(ASandSharkSpline InSpline)
	{
		MoveComp.CurrentSpline.Empty();
		MoveComp.CurrentSpline.Apply(InSpline, this, EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintCallable)
	void WarpToSpline(ASandSharkSpline InSpline)
	{
		MoveComp.CurrentSpline.Empty();
		MoveComp.CurrentSpline.Apply(InSpline, this, EInstigatePriority::Normal);
		SetActorLocation(InSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation));
	}

	UFUNCTION(BlueprintCallable)
	void GoToSplineAroundSafePoint(ASandSharkSafePoint SafePoint)
	{
		MoveComp.CurrentSpline.Empty();
		MoveComp.CurrentSpline.Apply(SafePoint.Spline, this, EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintCallable)
	void WarpToSplineAroundSafePoint(ASandSharkSafePoint SafePoint)
	{
		MoveComp.CurrentSpline.Empty();
		MoveComp.CurrentSpline.Apply(SafePoint.Spline, this, EInstigatePriority::Normal);
		SetActorLocation(SafePoint.Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation));
	}
};
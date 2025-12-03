enum EIslandDroidZiplineState
{
	Static,
	Patrolling,
	Ziplining
}

UCLASS(Abstract)
class AIslandDroidZipline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach=Root)
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent, Attach=Mesh)
	UIslandDroidZiplineAttachTargetable AttachTargetable;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandDroidZiplinePatrolMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandDroidZiplineZiplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandDroidZiplineAttachResponseCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SidewaysDistance;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent CurrentTiltValue;
	
	UPROPERTY(DefaultComponent)
	UNetworkLockComponent NetworkLock;

	UPROPERTY()
	UIslandDroidZiplineSettings DefaultSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	EIslandDroidZiplineState CurrentDroidState = EIslandDroidZiplineState::Static;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	AIslandDroidZiplineZiplineSpline ZiplineSpline;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	bool bRespawnOnSpline = false;

	AIslandDroidZiplinePatrolSpline PatrolSpline;
	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	AIslandDroidZiplineManager Manager;

	AHazePlayerCharacter AttachedPlayer;
	bool bOccupied = false;

	float CurrentSplineDistance = 0.0;
	float CurrentSplineSpeed;
	FVector PreviousSidewaysWorldOffset;
	bool bRespawnSystemIsActive = false;
	AHazePlayerCharacter RespawnSystemPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(DefaultSettings != nullptr)
			ApplyDefaultSettings(DefaultSettings);

		if(ZiplineSpline == nullptr)
			AddActorDisable(this);
	}

	void OnSpawnDroid(AIslandDroidZiplinePatrolSpline In_PatrolSpline, AIslandDroidZiplineZiplineSpline In_ZiplineSpline, UHazeActorNetworkedSpawnPoolComponent In_SpawnPool, AIslandDroidZiplineManager In_Manager)
	{
		PatrolSpline = In_PatrolSpline;
		ZiplineSpline = In_ZiplineSpline;
		SpawnPool = In_SpawnPool;
		Manager = In_Manager;
		CurrentDroidState = EIslandDroidZiplineState::Patrolling;
		RemoveActorDisable(this);
	}

	void LockToPlayer(UIslandDroidZiplinePlayerComponent ZiplineComp)
	{
		ZiplineComp.CurrentDroidZipline = this;
		ZiplineComp.CurrentTargetable = AttachTargetable;
		bOccupied = true;
	}

	bool MoveWillResultInFatalImpact(FVector WorldDeltaToApply)
	{
		FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(Collision);
		Trace.IgnoreActor(this);
		Trace.IgnorePlayers();
		FHitResult Hit = Trace.QueryTraceSingle(Collision.WorldLocation, Collision.WorldLocation + WorldDeltaToApply);
		return Hit.bBlockingHit;
	}

	/* Despawns droid */
	UFUNCTION()
	void DespawnDroid()
	{
		CrumbDespawnDroid();
	}

	/* Plays explosion effect and despawns droid */
	UFUNCTION()
	void KillDroid()
	{
		CrumbKillDroid();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbKillDroid()
	{
		FIslandDroidZiplineOnImpactParams EffectParams;
		EffectParams.DroidLocation = ActorLocation;
		UIslandDroidZiplineEffectHandler::Trigger_OnDeathImpact(this, EffectParams);

		InternalDespawnDroid();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDespawnDroid()
	{
		InternalDespawnDroid();
	}

	private void InternalDespawnDroid()
	{
		BlockCapabilities(n"DroidZipline", this);
		UnblockCapabilities(n"DroidZipline", this);

		AddActorDisable(this);
		SidewaysDistance.Value = 0.0;
		CurrentTiltValue.Value = 0.0;
		PreviousSidewaysWorldOffset = FVector::ZeroVector;
		CurrentSplineSpeed = UIslandDroidZiplineSettings::GetSettings(this).PatrolSpeed;
		CurrentSplineDistance = 0.0;

		if(SpawnPool != nullptr && SpawnPool.HasControl())
			SpawnPool.UnSpawn(this);

		DisengageRespawnSystem();
	}

	UFUNCTION()
	private bool OnRespawnOverride(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		if(Player.OtherPlayer.IsPlayerDead())
			return false;

		auto DroidZiplineComp = UIslandDroidZiplinePlayerComponent::Get(Player);
		DroidZiplineComp.CurrentDroidZipline = this;
		DroidZiplineComp.bAttached = true;
		DroidZiplineComp.CurrentTargetable = AttachTargetable;
		DroidZiplineComp.CurrentTargetable.Disable(DroidZiplineComp);
		Player.BlockCapabilities(IslandRedBlueWeapon::IslandRedBlueWeapon, DroidZiplineComp);
		Player.BlockCapabilities(IslandRedBlueWeapon::IslandTargeting, DroidZiplineComp);
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, DroidZiplineComp);
		Player.BlockCapabilities(n"Knockdown", DroidZiplineComp);
		Player.BlockCapabilities(IslandRedBlueStickyGrenade::IslandRedBlueStickyGrenade, DroidZiplineComp);
		BlockCapabilities(CapabilityTags::Movement, DroidZiplineComp);
		SidewaysDistance.OverrideControlSide(Player);
		CurrentTiltValue.OverrideControlSide(Player);
		bOccupied = true;
		RemoveActorDisable(this);

		float SplineDist = ZiplineSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.OtherPlayer.ActorLocation);
		CurrentSplineDistance = SplineDist;

		FTransform ClosestTransform = ZiplineSpline.Spline.GetWorldTransformAtSplineDistance(SplineDist);
		ActorLocation = ClosestTransform.Location;
		ActorRotation = ClosestTransform.Rotator();

		auto Settings = UIslandDroidZiplinePlayerSettings::GetSettings(Player);
		FVector PlayerLocation = ActorLocation - ActorUpVector * (Player.CapsuleComponent.CapsuleHalfHeight * 2.0) + Settings.CapsuleRelativeOffset;
		FTransform PlayerTransform = FTransform(ClosestTransform.Rotation, PlayerLocation);
		OutLocation.RespawnRelativeTo = RootComponent;
		OutLocation.RespawnTransform = PlayerTransform.GetRelativeTransform(ActorTransform);
		return true;
	}

	void Internal_OnPlayerAttach(AHazePlayerCharacter Player)
	{
		OnPlayerAttach(Player);
		
		if(!bRespawnSystemIsActive && bRespawnOnSpline)
		{
			auto RespawnComp = UPlayerRespawnComponent::Get(Player);
			RespawnComp.ApplyRespawnOverrideDelegate(this, FOnRespawnOverride(this, n"OnRespawnOverride"), EInstigatePriority::Normal);
			bRespawnSystemIsActive = true;
			RespawnSystemPlayer = Player;
		}
	}

	UFUNCTION()
	void DisengageRespawnSystem()
	{
		if(!bRespawnSystemIsActive)
			return;

		auto RespawnComp = UPlayerRespawnComponent::Get(RespawnSystemPlayer);
		RespawnComp.ClearRespawnOverride(this);
		RespawnSystemPlayer = nullptr;
		bRespawnSystemIsActive = false;
	}

	void Internal_OnPlayerDetach(AHazePlayerCharacter Player)
	{
		OnPlayerDetach(Player);
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerAttach(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void OnPlayerDetach(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bOccupied)
		{
			// Update the network lock so it tries to be owned by the closest player
			for (auto Player : Game::Players)
				NetworkLock.ApplyOwnerHint(Player, this, -Player.ActorLocation.DistSquared(ActorLocation), false);
			NetworkLock.UpdateHintValues();
		}
	}
}
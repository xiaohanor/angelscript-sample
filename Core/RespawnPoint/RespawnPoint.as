#if EDITOR
#endif

event void FOnRespawnedAtRespawnPoint(AHazePlayerCharacter RespawningPlayer);
event void FOnPlayerTeleportToRespawnPoint(AHazePlayerCharacter TeleportingPlayer);
delegate void FOnRespawnPointEnabled(AHazePlayerCharacter EnablingPlayer);
delegate void FOnRespawnPointDisabled(AHazePlayerCharacter DisablingPlayer);

enum ERespawnPointPriority
{
    NoRespawn,
    Lowest,
    Low,
    Normal,
    High,
    Highest,
};

struct FRespawnPointPlayerState
{
    UPROPERTY()
	TArray<FInstigator> EnableInstigators;
};

/**
 * RespawnPoints are used to respawn players in the world when dying.
 *
 * When a player dies, it checks all respawn points that are enabled in the
 * world, and respawns at the highest priority one. If multiple
 * respawn points have the highest priority, it chooses the closest one.
 */
UCLASS(HideCategories = "Rendering Input Actor LOD StoredPosition Cooking Collision Debug WorldPartition HLOD DataLayers", Meta = (HighlightPlacement))
class ARespawnPoint : AHazeActor
{
	default bRunConstructionScriptOnDrag = true;

    /* Priority of the respawn point. The highest priority respawn point will always be chosen. */
    UPROPERTY(EditAnywhere, Category = "Respawn Point")
    ERespawnPointPriority RespawnPriority = ERespawnPointPriority::Normal;

    /* Whether the respawn point is valid for the cody player to use. */
    UPROPERTY(EditAnywhere, Category = "Respawn Point")
    bool bCanZoeUse = true;

    /* Whether the respawn point is valid for the may player to use. */
    UPROPERTY(EditAnywhere, Category = "Respawn Point")
    bool bCanMioUse = true;

    /* If set, this will be used as the spawn point for the level when starting play. */
    UPROPERTY(EditAnywhere, Category = "Spawn Point")
    bool bIsLevelSpawnPoint = false;

    /* Whether positions should automatically trace to the ground. */
    UPROPERTY(EditAnywhere, Category = "Respawn Point", AdvancedDisplay)
	bool bSnapToGround = true;

	/**
	 * Whether positions should automatically snap to a spline.
	 * NOTE: We snap to a horizontal plane formed by the spline right axis, which we calculate as the orthagonal axis to the spline forward and RespawnPoint actor up.
	 */
    UPROPERTY(EditAnywhere, Category = "Respawn Point", AdvancedDisplay)
	bool bSnapToSpline = false;

	UPROPERTY(EditAnywhere, Category = "Respawn Point", AdvancedDisplay, Meta = (EditCondition = "bSnapToSpline", EditConditionHides))
	TSoftObjectPtr<ASplineActor> SplineActor = nullptr;

    UPROPERTY(EditAnywhere, Category = "Respawn Point", meta = (MakeEditWidget, EditCondition = "bCanZoeUse && bCanMioUse"), AdvancedDisplay)
    FTransform SecondPosition = FTransform(FVector(0, 100, 0));

    UPROPERTY(EditAnywhere, EditConst, Category = "StoredPosition")
    FTransform StoredSecondPosition;

    UPROPERTY(EditAnywhere, EditConst, Category = "StoredPosition")
    bool bIsSecondHidden = false;

	// Add an extra rotation to the camera when the player is spawned
    UPROPERTY(EditAnywhere, Category = "Respawn Camera")
	bool bRotatedCamera = false;

    UPROPERTY(EditAnywhere, Category = "Respawn Camera", Meta = (EditCondition = "bRotatedCamera", EditConditionHides))
	FRotator SpawnCameraRotation;

    UPROPERTY(Meta = (BPCannotCallEvent))
    FOnRespawnedAtRespawnPoint OnRespawnAtRespawnPoint;

	UPROPERTY(Meta = (BPCannotCallEvent))
	FOnPlayerTeleportToRespawnPoint OnPlayerTeleportToRespawnPoint;

	UPROPERTY(Meta = (BPCannotCallEvent))
	FOnRespawnPointEnabled OnRespawnPointEnabled;

	UPROPERTY(Meta = (BPCannotCallEvent))
	FOnRespawnPointDisabled OnRespawnPointDisabled;

	UPROPERTY(BlueprintHidden, EditInstanceOnly, AdvancedDisplay, Category = "StoredPosition")
	TPerPlayer<FTransform> FinalSpawnPositions;

    /* Per-player respawn point state. */
    TPerPlayer<FRespawnPointPlayerState> State;

    /* Scene root for placement. */
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

    UFUNCTION(Category = "Respawn Point")
    bool IsEnabledForPlayer(AHazePlayerCharacter Player) const
    {
        if (Player.Player == EHazePlayer::Zoe && !bCanZoeUse)
            return false;
        if (Player.Player == EHazePlayer::Mio && !bCanMioUse)
            return false;
        return State[Player].EnableInstigators.Num() != 0;
    }

    UFUNCTION(Category = "Respawn Point", BlueprintPure)
    FTransform GetPositionForPlayer(AHazePlayerCharacter Player) const
    {
		return FinalSpawnPositions[Player] * Root.WorldTransform;
    }

    FTransform GetRelativePositionForPlayer(AHazePlayerCharacter Player) const
    {
		return FinalSpawnPositions[Player];
    }

    FTransform GetStoredSpawnPosition(EHazePlayer Player) const
    {
		return FinalSpawnPositions[Player] * Root.WorldTransform;
    }

    UFUNCTION(Category = "Respawn Point")
    void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
    {
		bool bWasEnabled = IsEnabledForPlayer(Player);

		FRespawnPointPlayerState& PlayerState = State[Player];
		PlayerState.EnableInstigators.AddUnique(Instigator);

		if (!bWasEnabled && IsEnabledForPlayer(Player))
			OnEnabledForPlayer(Player);
    }

	void OnEnabledForPlayer(AHazePlayerCharacter Player)
	{
		OnRespawnPointEnabled.ExecuteIfBound(Player);
	}

    UFUNCTION(Category = "Respawn Point")
    void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
    {
		bool bWasEnabled = IsEnabledForPlayer(Player);

		FRespawnPointPlayerState& PlayerState = State[Player];
		PlayerState.EnableInstigators.Remove(Instigator);

		if (bWasEnabled && !IsEnabledForPlayer(Player))
			OnDisabledForPlayer(Player);
    }

	void OnDisabledForPlayer(AHazePlayerCharacter Player)
	{
		OnRespawnPointDisabled.ExecuteIfBound(Player);
	}

	bool IsValidToRespawn(AHazePlayerCharacter Player) const
	{
		return true;
	}

	bool ShouldRecalculateOnRespawnTriggered() const
	{
		return false;
	}

	// Snap all respawn points in visible levels to the ground
	UFUNCTION(CallInEditor)
	void SnapAllRespawnPointsToGround()
	{
	#if EDITOR
		auto AllRespawnPoints = Editor::GetAllEditorWorldActorsOfClass(ARespawnPoint);
		for (auto It : AllRespawnPoints)
		{
			auto OtherRespawnPoint = Cast<ARespawnPoint>(It);
			OtherRespawnPoint.UpdatePlayerSpawnLocation();
			OtherRespawnPoint.Modify();
			OtherRespawnPoint.RerunConstructionScripts();
		}
	#endif
	}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        // Hide the second position if not relevant
        bool bShouldHideSecond = !bCanMioUse || !bCanZoeUse;
        if (bShouldHideSecond != bIsSecondHidden)
        {
            if (bShouldHideSecond)
            {
                StoredSecondPosition = SecondPosition;
                SecondPosition = FTransform(FVector(99999, 99999, 99999));
            }
            else
            {
                SecondPosition = StoredSecondPosition;
            }
            bIsSecondHidden = bShouldHideSecond;
        }

        // Classify the main and secondary transform
#if EDITOR
		const bool bShouldSnap = bSnapToGround || bSnapToSpline;
		if (!bShouldSnap)
			ResetPlayerSpawnLocation();
		else if (!Editor::IsCooking() && Level.IsVisible() && Editor::IsSelected(this))
			UpdatePlayerSpawnLocation();
#endif

        // Make editor visualizers
        if (bCanMioUse)
            CreateForPlayer(EHazePlayer::Mio, FinalSpawnPositions[EHazePlayer::Mio]);
        if (bCanZoeUse)
            CreateForPlayer(EHazePlayer::Zoe, FinalSpawnPositions[EHazePlayer::Zoe]);
    }

	void ResetPlayerSpawnLocation()
	{
		if (bCanMioUse)
		{
			FinalSpawnPositions[EHazePlayer::Mio] = FTransform::Identity;
			FinalSpawnPositions[EHazePlayer::Zoe] = SecondPosition;
		}
		else
		{
			FinalSpawnPositions[EHazePlayer::Mio] = FTransform::Identity;
			FinalSpawnPositions[EHazePlayer::Zoe] = FTransform::Identity;
		}
	}

	void UpdatePlayerSpawnLocation()
	{
		ResetPlayerSpawnLocation();

		// Snap to a selected spline
		if(bSnapToSpline && SplineActor.IsValid())
		{
			if (bCanMioUse)
				SnapTransformToSpline(FinalSpawnPositions[EHazePlayer::Mio]);
			if (bCanZoeUse)
				SnapTransformToSpline(FinalSpawnPositions[EHazePlayer::Zoe]);
		}

		// Trace the transforms to the ground if needed
		//   We don't do the trace while cooking, because other levels may not be streamed in
		if (bSnapToGround)
		{
			if (bCanMioUse)
				TraceTransformToGround(FinalSpawnPositions[EHazePlayer::Mio]);
			if (bCanZoeUse)
				TraceTransformToGround(FinalSpawnPositions[EHazePlayer::Zoe]);
		}
	}

	void SnapTransformToSpline(FTransform& InOutRelativeTransform)
	{
		const FTransform WorldTransform = InOutRelativeTransform * Root.WorldTransform;

		const FTransform SplineTransform = SplineActor.Get().Spline.GetClosestSplineWorldTransformToWorldLocation(WorldTransform.Location);
		const FVector SplineLocation = SplineTransform.Location;

		// We calculate the SplineRight as an orthagonal vector to the spline forward and the actor up
		// The reason for this is to support shifting WorldUps, where in this case we assume that the respawn points up
		// is the world up.
		const FVector SplineRight = SplineTransform.Rotation.ForwardVector.CrossProduct(Root.UpVector).GetSafeNormal();

		const FVector SplineRespawnLocation = WorldTransform.Location.PointPlaneProject(SplineLocation, SplineRight);

		InOutRelativeTransform.Location = Root.WorldTransform.InverseTransformPosition(SplineRespawnLocation);
	}

	void TraceTransformToGround(FTransform& InOutRelativeTransform)
	{
		FTransform WorldTransform = InOutRelativeTransform * Root.WorldTransform;

		auto GroundTrace = Trace::InitProfile(n"PlayerCharacter");
		GroundTrace.UseCapsuleShape(30.0, 88.0, ActorQuat);

		FHitResultArray Hits = GroundTrace.QueryTraceMulti(
			WorldTransform.Location + ActorUpVector * 150.0,
			WorldTransform.Location - ActorUpVector * 150.0,
		);

		for (FHitResult Hit : Hits)
		{
			if (!Hit.bBlockingHit)
				continue;
			if (Hit.bStartPenetrating)
				continue;

			InOutRelativeTransform.Location = Root.WorldTransform.InverseTransformPosition(Hit.ImpactPoint);
			break;
		}
	}

    void CreateForPlayer(EHazePlayer Player, const FTransform& RelativeTransform)
    {
        // Add spawn point components that the player spawner will use for positioning
        if (bIsLevelSpawnPoint)
        {
            auto SpawnPoint = UHazePlayerSpawnPointComponent::Create(this);
            SpawnPoint.RelativeTransform = RelativeTransform;
            SpawnPoint.SpawnForPlayer = Player;
        }

#if EDITOR
		if (!Editor::IsCooking() && !World.IsGameWorld())
		{
			// Add an editor billboard indicating this is a respawn point
			FTransform BillboardTransform = RelativeTransform;
			BillboardTransform.AddToTranslation(FVector(0, 0, 100));

			UEditorBillboardComponent Billboard = UEditorBillboardComponent::Create(this);
			Billboard.RelativeTransform = BillboardTransform;

			if (bIsLevelSpawnPoint)
			{
				Billboard.SpriteName = "S_Player";
				BillboardTransform.Scale3D = FVector(1);
			}
			else
			{
				Billboard.SpriteName = "Ai_Spawnpoint";
				BillboardTransform.Scale3D = FVector(0.6);
			}

			// Create an editor visualizer mesh for the player
			CreatePlayerEditorVisualizer(Root, Player, RelativeTransform);
		}
#endif
    }

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if (bRotatedCamera)
		{
			if (bCanMioUse)
				DrawCameraRotation(EHazePlayer::Mio);
			if (bCanZoeUse)
				DrawCameraRotation(EHazePlayer::Zoe);
		}
	}

	void DrawCameraRotation(EHazePlayer Player) const
	{
		FRotator Rotation = SpawnCameraRotation + FRotator(-10, 0, 0);
		FTransform Transform = GetStoredSpawnPosition(Player);

		FVector Center = Transform.Location + Transform.Rotation.UpVector * 100;
		FVector Forward = Transform.TransformVector(Rotation.ForwardVector);
		Debug::DrawDebugLine(
			Center,
			Center + Forward * 500,
			GetColorForPlayer(Player), 5
			);
		Debug::DrawDebugLine(
			Center,
			Center + FQuat(Rotation.UpVector, -Math::DegreesToRadians(35)) * Forward * 500,
			GetColorForPlayer(Player), 5
			);
		Debug::DrawDebugLine(
			Center,
			Center + FQuat(Rotation.UpVector, Math::DegreesToRadians(35)) * Forward * 500,
			GetColorForPlayer(Player), 5
			);
	}
#endif

	UFUNCTION(NotBlueprintCallable)
	void OnRespawnTriggered(AHazePlayerCharacter Player)
	{
		OnRespawnAtRespawnPoint.Broadcast(Player);
	}
};
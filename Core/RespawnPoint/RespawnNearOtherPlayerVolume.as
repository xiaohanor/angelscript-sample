UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class ARespawnNearOtherPlayerVolume : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

    /* Respawn points that can be used. The respawn point closest to the _other_ player will be chosen. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "RespawnPoints")
    TArray<ARespawnPoint> UsableRespawnPoints;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
    }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;

		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"HandleRespawn");
		Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverride);
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;

		Player.ClearRespawnPointOverride(this);
    }

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutResult)
	{
		// Find the closest respawn point we've marked to the _other_ player
		float ClosestDistance = MAX_flt;
		ERespawnPointPriority Priority = ERespawnPointPriority::Lowest;
		ARespawnPoint ClosestRespawnPoint = nullptr;
		FTransform ClosestPosition;

		FVector OtherPlayerLocation = Player.OtherPlayer.ActorLocation;
		for (ARespawnPoint RespawnPoint : UsableRespawnPoints)
		{
			if (int(RespawnPoint.RespawnPriority) < int(Priority))
				continue;

			if (Player.IsMio() && !RespawnPoint.bCanMioUse)
				continue;
			if (Player.IsZoe() && !RespawnPoint.bCanZoeUse)
				continue;
			if (!RespawnPoint.IsValidToRespawn(Player))
				continue;

			if (int(RespawnPoint.RespawnPriority) > int(Priority))
			{
				// Higher priority checkpoint, reset the current
				Priority = RespawnPoint.RespawnPriority;
				ClosestRespawnPoint = nullptr;
				ClosestDistance = MAX_flt;
			}

			FTransform Position = RespawnPoint.GetPositionForPlayer(Player);
			float Distance = Position.GetLocation().DistSquared(OtherPlayerLocation);
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestRespawnPoint = RespawnPoint;
				ClosestPosition = Position;
			}
		}

		if (ClosestRespawnPoint != nullptr)
		{
			OutResult.RespawnPoint = ClosestRespawnPoint;
			OutResult.RespawnRelativeTo = ClosestRespawnPoint.RootComponent;
			OutResult.RespawnTransform = ClosestRespawnPoint.GetRelativePositionForPlayer(Player);
			return true;
		}

		return false;
	}
};

UCLASS(Abstract)
class UCharacter_Boss_Island_Overseer_WallBombManager_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UIslandOverseerWallBombAudioManager Manager;
	TArray<FAkSoundPosition> WallBombSegmentsSoundPositions;
	default WallBombSegmentsSoundPositions.SetNum(2);
	private TPerPlayer<FVector> TrackedPlayerWallBombPositons;
	float CachedClosestPlayerWallBombDistance = MAX_flt;
	
	UPROPERTY(BlueprintReadOnly)
	FVector CachedClosestPosition;
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Manager = IslandOverseerWallBomb::GetAudioManager();
		CachedClosestPlayerWallBombDistance = MAX_flt;
		
		for(auto Player : Game::GetPlayers())
		{
			TrackedPlayerWallBombPositons[Player] = FVector();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Manager.HasActiveWallBombs();
	}

	// Needed due to actor disable
	UFUNCTION(BlueprintOverride)
	bool CanActivate() const
	{
		return Manager.HasActiveWallBombs();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !Manager.HasActiveWallBombs();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Number of Deployed WallBombs"))
	int NumDeployedWallBombs()
	{
		return Manager.GetWallBombs().Num();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Closest Player Wall Bomb Distance"))
	float ClosestPlayerWallBombDistance()
	{
		return CachedClosestPlayerWallBombDistance;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		float ClosestPlayerWallBombDistance = MAX_flt;

		for(auto Player : Game::GetPlayers())
		{
			float ClosestWallBombDistanceSqrd = MAX_flt;
			AIslandOverseerWallBomb ClosestWallBomb = nullptr;

			for(auto Bomb : Manager.GetWallBombs())
			{
				const float DistToPlayerSqrd = Bomb.GetSquaredDistanceTo(Player);
				if(ClosestWallBomb == nullptr || DistToPlayerSqrd < ClosestWallBombDistanceSqrd)
				{
					ClosestWallBomb = Bomb;
					ClosestWallBombDistanceSqrd = DistToPlayerSqrd;
				}
			}

			FVector PlayerClosestWallBombPos;
			const float PlayerWallBombDistance = ClosestWallBomb.WallDamage.GetClosestPointOnCollision(Player.ActorCenterLocation, PlayerClosestWallBombPos);

			const FVector PreviousPlayerClosestWallBombPos = TrackedPlayerWallBombPositons[Player];
			if(!PreviousPlayerClosestWallBombPos.IsZero())
			{
				PlayerClosestWallBombPos = Math::VInterpTo(PreviousPlayerClosestWallBombPos, PlayerClosestWallBombPos, DeltaSeconds, 20.f);
			}
			
			WallBombSegmentsSoundPositions[int(Player.Player)].SetPosition(PlayerClosestWallBombPos);
			TrackedPlayerWallBombPositons[Player] = PlayerClosestWallBombPos;

			if(PlayerWallBombDistance < ClosestPlayerWallBombDistance)
			{
				ClosestPlayerWallBombDistance = PlayerWallBombDistance;
				CachedClosestPosition = PlayerClosestWallBombPos;
			}
		}

		CachedClosestPlayerWallBombDistance = ClosestPlayerWallBombDistance;
		DefaultEmitter.SetMultiplePositions(WallBombSegmentsSoundPositions);
	}
}
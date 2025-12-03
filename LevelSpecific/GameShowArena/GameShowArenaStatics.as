namespace GameShowArena
{
	const FName DebugCategory = n"GameShowArena";
	const FName BombVisualBlockerInstigator = n"GameShowBombVisualBlocker";

#if EDITOR
	const FHazeDevToggleBool DisableExplosionTimer;
#endif
	UFUNCTION(BlueprintPure)
	AGameShowArenaPlatformManager GetGameShowArenaPlatformManager()
	{
		return TListedActors<AGameShowArenaPlatformManager>().Single;
	}

	UFUNCTION(BlueprintPure)
	AGameShowArenaBomb GetClosestEnabledBombToLocation(FVector Location)
	{
		TListedActors<AGameShowArenaBomb> ListedBombs;
		AGameShowArenaBomb ClosestBomb;
		float ClosestDistance = MAX_flt;
		for (auto Bomb : ListedBombs)
		{
			if (Bomb.IsActorDisabled())
				continue;
			
			float SquaredDist = Bomb.ActorLocation.DistSquared(Location);
			if (SquaredDist < ClosestDistance)
			{
				ClosestBomb = Bomb;
				ClosestDistance = SquaredDist;
			}
		}
		return ClosestBomb;
	}

	TArray<FLinearColor> GetPlatformLightColors()
	{
		TArray<FLinearColor> Colors;
		Colors.SetNum(EBombTossPlatformLightColor::Num);
		Colors[EBombTossPlatformLightColor::None] = FLinearColor(0, 0, 0);
		Colors[EBombTossPlatformLightColor::Green] = FLinearColor(0, 60, 0);
		Colors[EBombTossPlatformLightColor::Red] = FLinearColor(60, 0, 0);
		Colors[EBombTossPlatformLightColor::White] = FLinearColor(20, 20, 20);
		return Colors;
	}
}

namespace GameShowArenaBombAutoAim
{
	const float TargetShapeSphereRadius = 100;
	const float MaximumDistance = 6500;
	const bool bUseVariableAutoAimMaxAngle = true;
	const float AutoAimMaxAngleMinDistance = 35.0;
	const float AutoAimMaxAngleAtMaxDistance = 35.0;
	const float AutoAimAngleBuffer = 16.0;
}
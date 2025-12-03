
const FConsoleVariable CVar_DebugRespawnPoints("Haze.DebugRespawnPoints", 0, "Debug enabled checkpoints. 1=Both, 2=Mio, 3=Zoe");

delegate bool FOnRespawnOverride(AHazePlayerCharacter Player, FRespawnLocation& OutLocation);
event void FOnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer);

struct FRespawnLocation
{
	FTransform RespawnTransform;
	USceneComponent RespawnRelativeTo;
	ARespawnPoint RespawnPoint;
	FVector RespawnWithVelocity;
	bool bRecalculateOnRespawnTriggered = false;
	bool bOffsetSpawnCameraRotation = false;
	FRotator CameraRotationOffset;
};

struct FActiveRespawnOverride
{
	FInstigator Instigator;
	EInstigatePriority Priority;
	FOnRespawnOverride Delegate;
};

class UPlayerRespawnComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	UPlayerHealthSettings HealthSettings;

	bool bIsRespawning = false;
	bool bIsRespawnMashActive = false;

	ARespawnPointVolume StickyRespawnPointVolume;
	ARespawnPoint StickyRespawnPoint;
	FOnPlayerRespawned OnPlayerRespawned;

	TInstigated<FRespawnLocation> RespawnOverrideLocations;
	TArray<FActiveRespawnOverride> RespawnOverrideDelegates;

	UPlayerRespawnMashOverlayWidget OverlayWidget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Player);
		DevTogglesPlayerHealth::DrawRespawnPoint.MakeVisible();
	}

	void ResetStickyRespawnPoints()
	{
		if (StickyRespawnPointVolume != nullptr)
		{
			StickyRespawnPointVolume.DisableRespawnPoints(Cast<AHazePlayerCharacter>(Owner));
			StickyRespawnPointVolume = nullptr;
		}
		if (StickyRespawnPoint != nullptr)
		{
			StickyRespawnPoint.DisableForPlayer(Cast<AHazePlayerCharacter>(Owner), this);
			StickyRespawnPoint = nullptr;
		}
	}

	void TriggerStickyVolume(ARespawnPointVolume Volume)
	{
		ResetStickyRespawnPoints();
		StickyRespawnPointVolume = Volume;
		Volume.EnableRespawnPoints(Cast<AHazePlayerCharacter>(Owner));
	}

	void ClearStickyVolume(ARespawnPointVolume Volume)
	{
		if (Volume == StickyRespawnPointVolume)
			ResetStickyRespawnPoints();
	}

	void TriggerStickyRespawnPoint(ARespawnPoint Point)
	{
		ResetStickyRespawnPoints();
		StickyRespawnPoint = Point;
		Point.EnableForPlayer(Player, this);
	}

	void ClearStickyRespawnPoint(ARespawnPoint Point)
	{
		if (Point == StickyRespawnPoint)
			ResetStickyRespawnPoints();
	}

	void ApplyRespawnOverrideLocation(FInstigator Instigator, FRespawnLocation Override, EInstigatePriority Priority)
	{
		ClearRespawnOverride(Instigator);
		RespawnOverrideLocations.Apply(Override, Instigator, Priority);
	}

	void ApplyRespawnOverrideDelegate(FInstigator Instigator, FOnRespawnOverride Delegate, EInstigatePriority Priority)
	{
		ClearRespawnOverride(Instigator);

		FActiveRespawnOverride Override;
		Override.Instigator = Instigator;
		Override.Priority = Priority;
		Override.Delegate = Delegate;
		RespawnOverrideDelegates.Add(Override);
	}

	void ClearRespawnOverride(FInstigator Instigator)
	{
		RespawnOverrideLocations.Clear(Instigator);

		for (int i = RespawnOverrideDelegates.Num() - 1; i >= 0; --i)
		{
			if (RespawnOverrideDelegates[i].Instigator == Instigator)
				RespawnOverrideDelegates.RemoveAt(i);
		}
	}

	bool PrepareRespawnLocation(FRespawnLocation& OutResult)
	{
		EInstigatePriority OverridePriority = EInstigatePriority::Level;
		FRespawnLocation OverrideLocation;
		bool bHasOverrideLocation = false;

		if (!RespawnOverrideLocations.IsDefaultValue())
		{
			OverridePriority = RespawnOverrideLocations.GetCurrentPriority();
			OverrideLocation = RespawnOverrideLocations.Get();
			bHasOverrideLocation = true;
		}

		for (int i = 0, Count = RespawnOverrideDelegates.Num(); i < Count; ++i)
		{
			FActiveRespawnOverride& Override = RespawnOverrideDelegates[i];
			if (Override.Priority < OverridePriority)
				continue;
			if (!Override.Delegate.IsBound())
				continue;

			FRespawnLocation DelegateLocation;
			if (Override.Delegate.ExecuteIfBound(Player, DelegateLocation))
			{
				OverrideLocation = DelegateLocation;
				OverridePriority = Override.Priority;
				bHasOverrideLocation = true;
			}
		}

		if (bHasOverrideLocation)
		{
			OutResult = OverrideLocation;
			return true;
		}

		TListedActors<ARespawnPoint> AllRespawnPoints;

		float ClosestDistance = MAX_flt;
		ERespawnPointPriority Priority = ERespawnPointPriority::Lowest;
		ARespawnPoint ClosestRespawnPoint = nullptr;
		FTransform ClosestPosition;

		FVector PlayerLocation = Player.ActorLocation;

		for (ARespawnPoint RespawnPoint : AllRespawnPoints)
		{
			if (int(RespawnPoint.RespawnPriority) < int(Priority))
				continue;

			if (!RespawnPoint.IsEnabledForPlayer(Player))
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
			float Distance = Position.GetLocation().DistSquared(PlayerLocation);
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
			OutResult.bRecalculateOnRespawnTriggered = ClosestRespawnPoint.ShouldRecalculateOnRespawnTriggered();

			if (ClosestRespawnPoint.bRotatedCamera)
			{
				OutResult.bOffsetSpawnCameraRotation = true;
				OutResult.CameraRotationOffset = ClosestRespawnPoint.SpawnCameraRotation;
			}

			return true;
		}

		if (HealthSettings.bBlockRespawnWhenNoRespawnPointsEnabled)
			return false;

		// Fallback respawn at the current location if no respawn point was found, and emit warning
		OutResult.RespawnTransform = Player.ActorTransform;
		PrintError(f"Player {Player} attempted to respawn without a respawn point. Respawning at the current actor location.", 15.0);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		bool bDevToggled = DevTogglesPlayerHealth::DrawRespawnPoint.IsEnabled(Player);
		if (CVar_DebugRespawnPoints.GetInt() != 0 || bDevToggled)
		{
			if (CVar_DebugRespawnPoints.GetInt() == 1
				|| (Player.IsMio() && CVar_DebugRespawnPoints.GetInt() == 2)
				|| (Player.IsZoe() && CVar_DebugRespawnPoints.GetInt() == 3)
				|| bDevToggled)
			{
				DebugDrawRespawnPoints(Player);
			}
		}

		TEMPORAL_LOG(Owner, "Health")
			.Value("Respawn;Sticky Respawn Volume", StickyRespawnPointVolume)
			.Value("Respawn;Sticky Respawn Point", StickyRespawnPoint)
		;

		for (int i = RespawnOverrideDelegates.Num() - 1; i >= 0; --i)
		{
			FActiveRespawnOverride RespawnOverride = RespawnOverrideDelegates[i];
			TEMPORAL_LOG(Owner, "Health")
				.Value("Respawn;Override Respawn Point instigators " + i, RespawnOverride.Instigator)
			;
		}

		if (!RespawnOverrideLocations.IsDefaultValue())
		{
			auto OverridePriority = RespawnOverrideLocations.GetCurrentPriority();
			auto OverrideLocation = RespawnOverrideLocations.Get();
			TEMPORAL_LOG(Owner, "Health")
				.Value("Respawn;Override Respawn Location;Priority", OverridePriority)
				.Struct("Respawn;Override Respawn Location;Location", OverrideLocation)
			;
		}

		TEMPORAL_LOG(Owner, "Health")
			.Value("Health Settings;Game Over When Players Dead", HealthSettings.bGameOverWhenBothPlayersDead)
		;
#endif
	}

	void DebugDrawRespawnPoints(AHazePlayerCharacter DrawPlayer)
	{
		FString List;
		List += "RespawnPoints Enabled For "+DrawPlayer.Name;
		if (StickyRespawnPointVolume != nullptr)
			List += "\n   Sticky Volume: "+StickyRespawnPointVolume.ActorNameOrLabel;
		if (StickyRespawnPoint != nullptr)
			List += "\n   Sticky RespawnPoint: "+StickyRespawnPoint.ActorNameOrLabel;
		List += "\n";

		TListedActors<ARespawnPoint> AllRespawnPoints;

		float ClosestDistance = MAX_flt;
		ERespawnPointPriority Priority = ERespawnPointPriority::Lowest;
		ARespawnPoint ClosestRespawnPoint = nullptr;
		FTransform ClosestPosition;

		FVector PlayerLocation = DrawPlayer.ActorLocation;

		TArray<ARespawnPoint> EnabledRespawnPoints;
		bool bDevToggled = DevTogglesPlayerHealth::DrawRespawnPoint.IsEnabled(Player);

		for (ARespawnPoint RespawnPoint : AllRespawnPoints)
		{
			if (int(RespawnPoint.RespawnPriority) < int(Priority))
				continue;

			if (bDevToggled)
			{
				Debug::DrawDebugCapsule(RespawnPoint.ActorCenterLocation, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius, RespawnPoint.ActorRotation, Player.GetPlayerUIColor() * 0.5, 3.0, 0.0, true);
				Debug::DrawDebugString(RespawnPoint.ActorCenterLocation, "" + RespawnPoint.ActorNameOrLabel);
			}

			if (!RespawnPoint.IsEnabledForPlayer(DrawPlayer))
				continue;
			if (!RespawnPoint.IsValidToRespawn(DrawPlayer))
				continue;

			EnabledRespawnPoints.Add(RespawnPoint);

			if (int(RespawnPoint.RespawnPriority) > int(Priority))
			{
				// Higher priority checkpoint, reset the current
				Priority = RespawnPoint.RespawnPriority;
				ClosestRespawnPoint = nullptr;
				ClosestDistance = MAX_flt;
			}

			FTransform Position = RespawnPoint.GetPositionForPlayer(DrawPlayer);
			float Distance = Position.GetLocation().DistSquared(PlayerLocation);
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestRespawnPoint = RespawnPoint;
				ClosestPosition = Position;
			}
		}

		FLinearColor ActiveColor = DrawPlayer.GetPlayerUIColor();
		FLinearColor AvailableColor = Math::Lerp(ActiveColor, FLinearColor::White, 0.2);

		if (!RespawnOverrideLocations.IsDefaultValue() || RespawnOverrideDelegates.Num() > 0)
		{
			EInstigatePriority OverridePriority = RespawnOverrideLocations.GetCurrentPriority();
			for (int i = RespawnOverrideDelegates.Num() - 1; i >= 0; --i)
			{
				FActiveRespawnOverride RespawnOverride = RespawnOverrideDelegates[i];
				FString RespawnPointLine = RespawnOverride.Instigator.ToString()+" (Priority: "+int(RespawnOverride.Priority)+")";
				if (RespawnOverride.Priority == OverridePriority)
					List += "\n  ==> "+RespawnPointLine;
				else 
					List += "\n      "+RespawnPointLine;
			}
			FRespawnLocation OverrideLocation = RespawnOverrideLocations.Get();
			FVector ToRespawnPoint = OverrideLocation.RespawnTransform.Location - DrawPlayer.ActorLocation;
			if (bDevToggled && OverrideLocation.RespawnTransform.Location.Size() > KINDA_SMALL_NUMBER && ToRespawnPoint.Size() > KINDA_SMALL_NUMBER)
			{
				Debug::DrawDebugArrow(DrawPlayer.ActorLocation, DrawPlayer.ActorLocation + ToRespawnPoint.GetSafeNormal() * 100.0, 12.0, ColorDebug::White, 7.0, 0.0, true);
				Debug::DrawDebugArrow(DrawPlayer.ActorLocation, DrawPlayer.ActorLocation + ToRespawnPoint.GetSafeNormal() * 100.0, 10.0, ActiveColor, 5.0, 0.0, true);
			}
		}
		else
		{
			for (ARespawnPoint RespawnPoint : EnabledRespawnPoints)
			{
				FString RespawnPointLine = RespawnPoint.ActorNameOrLabel+" (Priority: "+int(RespawnPoint.RespawnPriority)+")";

				FTransform Position = RespawnPoint.GetPositionForPlayer(DrawPlayer);
				FVector DebugLocation = Position.Location + (Position.Rotation.UpVector * 100.0);

				if (RespawnPoint == ClosestRespawnPoint)
				{
					Debug::DrawDebugCapsule(DebugLocation,
						100.0, 50.0, Position.Rotation.Rotator(),
						ActiveColor, Thickness = 16.0, bDrawInForeground = true);

					List += "\n  ==> "+RespawnPointLine;
					FVector ToRespawnPoint =  DebugLocation - DrawPlayer.ActorLocation;
					if (bDevToggled && ToRespawnPoint.Size() > KINDA_SMALL_NUMBER)
					{
						Debug::DrawDebugArrow(DrawPlayer.ActorLocation, DrawPlayer.ActorLocation + ToRespawnPoint.GetSafeNormal() * 100.0, 12.0, ColorDebug::White, 7.0, 0.0, true);
						Debug::DrawDebugArrow(DrawPlayer.ActorLocation, DrawPlayer.ActorLocation + ToRespawnPoint.GetSafeNormal() * 100.0, 10.0, ActiveColor, 5.0, 0.0, true);
					}
				}
				else
				{
					Debug::DrawDebugCapsule(DebugLocation,
						100.0, 50.0, Position.Rotation.Rotator(), AvailableColor, bDrawInForeground = true);

					List += "\n      "+RespawnPointLine;
				}
			}
		}
		PrintToScreen(List, Color = DrawPlayer.GetPlayerUIColor());
	}
};

void ApplyRemoveRespawnPointVolumeSticky(AHazePlayerCharacter Player, ARespawnPointVolume Volume)
{
	auto RespawnComp = UPlayerRespawnComponent::Get(Player);
	RespawnComp.ClearStickyVolume(Volume);
}

void ApplyEnterStickyRespawnPointVolume(AHazePlayerCharacter Player, ARespawnPointVolume Volume)
{
	auto RespawnComp = UPlayerRespawnComponent::Get(Player);
	RespawnComp.TriggerStickyVolume(Volume);
}
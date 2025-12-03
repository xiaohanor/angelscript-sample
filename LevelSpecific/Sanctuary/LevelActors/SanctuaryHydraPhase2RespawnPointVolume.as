struct FSanctuaryHydraPhase2RespawnPointData
{
	FSanctuaryHydraPhase2RespawnPointData(ARespawnPoint Respawn)
	{
		RespawnPoint = Respawn;
	}

	ARespawnPoint RespawnPoint = nullptr;
	TPerPlayer<bool> Enabled;
}

class ASanctuaryHydraPhase2RespawnPointVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryHydraPhase2RespawnPointVolumeComponent Box;

	TArray<FSanctuaryHydraPhase2RespawnPointData> LevelRespawnPoints;

	float UpdateCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SanctuaryHydraDevToggles::Drawing::DrawSplineRunRespawn.IsEnabled())
			DebugDraw();

		UpdateCooldown -= DeltaSeconds;
		if (UpdateCooldown > 0.0)
			return; 
		UpdateCooldown = 0.3;

		if (LevelRespawnPoints.IsEmpty())
		{
			TListedActors<ARespawnPoint> Respawnings;
			for (ARespawnPoint Respawn : Respawnings)
			{
				if (Respawn != nullptr)
					LevelRespawnPoints.Add(FSanctuaryHydraPhase2RespawnPointData(Respawn));
			}
		}

		FBox TempBox = FBox(-Box.BoxExtent, Box.BoxExtent);
		TArray<int> ToRemove;
		bool bFirst = true;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			for (int i = LevelRespawnPoints.Num() - 1; i >= 0; i--)
			{
				FSanctuaryHydraPhase2RespawnPointData RespawnData = LevelRespawnPoints[i];
				if (RespawnData.RespawnPoint == nullptr)
				{
					if (bFirst)
						ToRemove.Add(i);
					continue;
				}

				FVector RelativeLocation = Box.WorldTransform.InverseTransformPosition(RespawnData.RespawnPoint.ActorLocation);
				bool bHasSplineParent = RespawnData.RespawnPoint.AttachParentActor != nullptr && Cast<ASanctuaryBossSplineRunPlatform>(RespawnData.RespawnPoint.AttachParentActor) != nullptr;
				bool bInside = bHasSplineParent && TempBox.IsInsideOrOnXY(RelativeLocation);
				bool bInRangeOfOtherPlayer = Player.OtherPlayer.ActorLocation.X + 500.0 > RespawnData.RespawnPoint.ActorLocation.X;
				bool bShouldBeEnabled = bInside && bInRangeOfOtherPlayer;
				if (!RespawnData.Enabled[Player] && bShouldBeEnabled)
				{
					LevelRespawnPoints[i].Enabled[Player] = true;
					RespawnData.RespawnPoint.EnableForPlayer(Player, this);
					// if (SanctuaryHydraDevToggles::Drawing::DrawSplineRunRespawn.IsEnabled())
					// 	PrintToScreen("Enabled " + RespawnData.RespawnPoint.GetName(), 3.0);
				}
				else if (RespawnData.Enabled[Player] && !bShouldBeEnabled)
				{
					LevelRespawnPoints[i].Enabled[Player] = false;
					RespawnData.RespawnPoint.DisableForPlayer(Player, this);
					// if (SanctuaryHydraDevToggles::Drawing::DrawSplineRunRespawn.IsEnabled())
					// 	PrintToScreen("Disabled " + RespawnData.RespawnPoint.GetName(), 3.0);
				}
			}
			bFirst = false;
		}

		for (int i = 0; i < ToRemove.Num(); ++i)
		{
			LevelRespawnPoints.RemoveAt(ToRemove[i]);
		}
	}

	private FString BoolToString(bool bBool)
	{
		return bBool ? "true" : "false";
	}

	private void DebugDraw()
	{
		{
			for (auto Structy : LevelRespawnPoints)
			{
				if (Structy.RespawnPoint == nullptr)
					continue;
				for (AHazePlayerCharacter Player : Game::Players)
				{
					// FString Temp = Player.GetName() + " " + Structy.RespawnPoint.GetName() + " " + BoolToString(Structy.Enabled[Player]);
					// PrintToScreen(Temp);
					bool bEnabled = Structy.Enabled[Player] && Structy.RespawnPoint.IsEnabledForPlayer(Player);
					FLinearColor DebugColor = bEnabled ? Player.GetPlayerUIColor() : ColorDebug::Gray;
					float RadiusMod =  Player.IsMio() ? 1.0 : 0.9;
					Debug::DrawDebugSphere(Structy.RespawnPoint.ActorLocation, 50.0 * RadiusMod, 12, DebugColor, 3.0, 0.0, true);
					if (bEnabled)
						Debug::DrawDebugString(Structy.RespawnPoint.ActorLocation, "" + Structy.RespawnPoint.GetName());
				}
			}
			Debug::DrawDebugBox(Box.WorldLocation, Box.BoxExtent, Box.WorldRotation, ColorDebug::Pumpkin, 0.0);
		}
	}
};


class USanctuaryHydraPhase2RespawnPointVolumeComponent : UBoxComponent
{
	default CollisionEnabled = ECollisionEnabled::NoCollision;
	default BoxExtent = FVector::OneVector * 1000.0;
}

#if EDITOR
class USanctuaryHydraPhase2RespawnPointVolumeVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryHydraPhase2RespawnPointVolumeComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ExtentsComp = Cast<USanctuaryHydraPhase2RespawnPointVolumeComponent>(Component);
		SetRenderForeground(true);
		DrawWireBox(ExtentsComp.WorldLocation, ExtentsComp.BoxExtent, FQuat());
	}
}
#endif
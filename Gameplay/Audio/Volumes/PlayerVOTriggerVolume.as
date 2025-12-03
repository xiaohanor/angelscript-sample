event void FOnPlayerDiedInsideVOVolume(AHazePlayerCharacter Player);
event void FOnPlayerRespawnedInsideVOVolume(AHazePlayerCharacter Player);

struct FPlayerVOTriggerVolumePlayerData
{
	bool bIsInVolume = false;
	bool bHasEverEntered = false;
	float CurrentTimeInVolume = 0.0;
	float TotalTimeInVolume = 0.0;
	float EnterTimestamp = 0.0;
}

namespace PlayerVOTriggerVolume
{
	// The PlayerVOTrigger-volume used to spawn this VO-SoundDef
	UFUNCTION(BlueprintPure, Meta = (DefaultToSelf = SoundDef, HidePin = "SoundDef", CompactNodeTitle = "Get SoundDef VO Trigger"))
	APlayerVOTriggerVolume GetSoundDefVOTrigger(UHazeVOSoundDef SoundDef)
	{
		AActor Instigator = SoundDef.ActorInstigator.Get();
		if (Instigator != nullptr)
			return Cast<APlayerVOTriggerVolume>(Instigator);

		return nullptr;
	}
}

class APlayerVOTriggerEventHandlerActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
}

UCLASS(HideCategories = "EditorRendering Physics PathTracing Collision Rendering Debug Cooking", Meta = (DisplayName = "Player VO Trigger"))
class APlayerVOTriggerVolume : AHazeVOPlayerTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(0.61, 0.00, 0.50));
	default BrushComponent.LineThickness = 6.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default SetActorTickEnabled(false);

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(NotEditable, Transient)
	private AHazeActor EventHandlerTargetActor = nullptr;

	UPROPERTY(EditInstanceOnly, Category = "Sound Defs")
	TArray<FSoundDefReference> SoundDefs;

	UPROPERTY(EditInstanceOnly, Category = "Override Actor Owner")
	TSoftObjectPtr<AHazeActor> OverrideActorOwner;

	UPROPERTY(EditInstanceOnly, Category = "Triggering", Meta = (ForceInlineRow))
	TPerPlayer<bool> TriggerForPlayer;
	default TriggerForPlayer[0] = true;
	default TriggerForPlayer[1] = true;

	UPROPERTY(EditInstanceOnly, Category = "Triggering")
	bool bTriggerOnlyOnce = true;

	UPROPERTY(EditInstanceOnly, Category = "Triggering", Meta = (EditCondition = "bTriggerOnlyOnce", EditConditionHides))
	bool bLinkBothPlayersEventHandlers = false;

	UPROPERTY(EditInstanceOnly, Category = "Triggering", Meta = (ForceUnits = "cm"))
	float DeactivationDistanceRange = 0.0;

	UPROPERTY(EditInstanceOnly, Category = "Settings Override")
	UPlayerBreathingAudioSettings BreathingSettings;

	UPROPERTY()
	TPerPlayer<FPlayerVOTriggerVolumePlayerData> PlayerTriggerDatas;

	private TArray<AHazePlayerCharacter> PendingPlayerRemovals;

	private bool bWasEverTriggered = false;

	UPROPERTY()
	FOnPlayerDiedInsideVOVolume OnPlayerDied;

	UPROPERTY()
	FOnPlayerRespawnedInsideVOVolume OnPlayerRespawned;

	TPerPlayer<UPlayerHealthComponent> PlayerHealthComps;

	private int NumSpawnedEventHandleActors = 0;

#if EDITOR
	UPROPERTY(DefaultComponent, NotEditable)
	UPlayerVOTriggerVolumeEditorComponent EditorComp;
#endif

	private bool bAnyPlayerInside = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Players = Game::GetPlayers();
		PlayerHealthComps[0] = UPlayerHealthComponent::Get(Players[0]);
		PlayerHealthComps[1] = UPlayerHealthComponent::Get(Players[1]);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnEventHandleTargetActor(FName ActorName, int NetworkId)
	{
		AActor NewEventHandleTargetActor = SpawnActor(APlayerVOTriggerEventHandlerActor,
													  GetActorLocation(),
													  GetActorRotation(),
													  ActorName,
													  bDeferredSpawn = true);

		NewEventHandleTargetActor.MakeNetworked(this, NetworkId);
		NewEventHandleTargetActor.SetActorControlSide(this);

		FinishSpawningActor(NewEventHandleTargetActor);

		EventHandlerTargetActor = Cast<APlayerVOTriggerEventHandlerActor>(NewEventHandleTargetActor);
	}

	UFUNCTION(CrumbFunction)
	void CrumbAttachSoundDefs(AHazePlayerCharacter Player, AHazeActor TargetActor)
	{
		auto& PlayerTriggerData = PlayerTriggerDatas[Player];
		PlayerTriggerData.bHasEverEntered = true;
		PlayerTriggerData.bIsInVolume = true;
		PlayerTriggerData.EnterTimestamp = Time::GetAudioTimeSeconds();

		for (auto SoundDef : SoundDefs)
		{
			if (!SoundDef.IsValid())
				continue;

			SoundDef.SpawnSoundDefAttached(TargetActor, InInstigator = this);

			for (auto Pair : SoundDef.ActorRefs)
			{
				AHazeActor LinkedHazeActor = Cast<AHazeActor>(Pair.Value.Get());

				if (LinkedHazeActor == nullptr)
					continue;
				
				if (LinkedHazeActor == TargetActor)
					continue;

				EffectEvent::LinkActorToReceiveEffectEventsFrom(TargetActor, LinkedHazeActor);

				auto Spawner = Cast<AHazeActorSpawnerBase>(LinkedHazeActor);
				if(Spawner != nullptr)
				{
					const FName PlayerSpawnerCallbackFunctionName = Player.IsMio() ? n"OnPostSpawnerSpawnMio" : n"OnPostSpawnerSpawnZoe";
					Spawner.OnPostSpawn.AddUFunction(this, PlayerSpawnerCallbackFunctionName);
				}
			}
		}

		if (bTriggerOnlyOnce && bLinkBothPlayersEventHandlers)
		{
			EffectEvent::LinkActorToReceiveEffectEventsFrom(TargetActor, Player);
			EffectEvent::LinkActorToReceiveEffectEventsFrom(TargetActor, Player.OtherPlayer);
		}

		if (BreathingSettings != nullptr)
		{
			Player.ApplySettings(BreathingSettings, this);
		}

		if (!bAnyPlayerInside)
		{
			if (Player.IsMio())
			{
				PlayerHealthComps[Player].OnDeathTriggered.AddUFunction(this, n"OnMioDied");
				PlayerHealthComps[Player.OtherPlayer].OnDeathTriggered.AddUFunction(this, n"OnZoeDied");
				PlayerHealthComps[Player].OnReviveTriggered.AddUFunction(this, n"OnMioRespawned");
				PlayerHealthComps[Player.OtherPlayer].OnReviveTriggered.AddUFunction(this, n"OnZoeRespawned");
			}
			else
			{
				PlayerHealthComps[Player].OnDeathTriggered.AddUFunction(this, n"OnZoeDied");
				PlayerHealthComps[Player.OtherPlayer].OnDeathTriggered.AddUFunction(this, n"OnMioDied");
				PlayerHealthComps[Player].OnReviveTriggered.AddUFunction(this, n"OnZoeRespawned");
				PlayerHealthComps[Player.OtherPlayer].OnReviveTriggered.AddUFunction(this, n"OnMioRespawned");
			}
		}

		bAnyPlayerInside = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbRemoveSoundDefs(AHazePlayerCharacter Player, AHazeActor TargetActor)
	{
		auto& PlayerTriggerData = PlayerTriggerDatas[Player];
		PlayerTriggerData.bIsInVolume = false;
		PlayerTriggerData.TotalTimeInVolume = Time::GetAudioTimeSince(PlayerTriggerData.EnterTimestamp);
		PlayerTriggerData.CurrentTimeInVolume = 0.0;

		for (auto SoundDef : SoundDefs)
		{
			TargetActor.RemoveSoundDef(SoundDef);

			for (auto Pair : SoundDef.ActorRefs)
			{
				auto Spawner = Cast<AHazeActorSingleSpawner>(Pair.Value.Get());
				if (Spawner != nullptr)
				{					
					const FName PlayerSpawnerCallbackFunctionName = Player.IsMio() ? n"OnPostSpawnerSpawnMio" : n"OnPostSpawnerSpawnZoe";
					Spawner.OnPostSpawn.Unbind(this, PlayerSpawnerCallbackFunctionName);					
				}
			}
		}

		if (BreathingSettings != nullptr)
			Player.ClearSettingsOfClass(UPlayerBreathingAudioSettings, this);

		auto HealthComp = UPlayerHealthComponent::Get(Player);
		if (HealthComp != nullptr)
		{
			HealthComp.OnDeathTriggered.UnbindObject(this);
		}

		bAnyPlayerInside = PlayerTriggerDatas[Player.OtherPlayer].bIsInVolume;
		if (!bAnyPlayerInside)
		{
			auto Players = Game::GetPlayers();

			PlayerHealthComps[Players[0]].OnDeathTriggered.UnbindObject(this);
			PlayerHealthComps[Players[1]].OnDeathTriggered.UnbindObject(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		// Only do overlaps on control side
		if (!HasControl())
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!TriggerForPlayer[Player])
			return;

		if (bWasEverTriggered && bTriggerOnlyOnce)
			return;

		// We're already tracking a distance based removal for this player
		if (PendingPlayerRemovals.Contains(Player))
			return;

		bWasEverTriggered = true;

		AHazeActor TargetActor;

		// Special case handling for linking both player event handlers to flow into the same SoundDef - Likely used with a "manager" type VO SoundDef
		if (bTriggerOnlyOnce && bLinkBothPlayersEventHandlers)
		{
			if (EventHandlerTargetActor == nullptr)
			{
				const FName ActorName = FName(f"{GetName()}_EventHandlerActor");
				CrumbSpawnEventHandleTargetActor(ActorName, NumSpawnedEventHandleActors);
				NumSpawnedEventHandleActors++;
			}
			TargetActor = EventHandlerTargetActor;
		}
		else
		{
			TargetActor = OverrideActorOwner.IsValid() ? OverrideActorOwner.Get() : Player;
		}

		CrumbAttachSoundDefs(Player, TargetActor);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		// Only do overlaps on control side
		if (!HasControl())
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!TriggerForPlayer[Player])
			return;

		auto& PlayerTriggerData = PlayerTriggerDatas[Player];
		if (!PlayerTriggerData.bIsInVolume)
			return;

		// We're already tracking a distance based removal for this player
		if (PendingPlayerRemovals.Contains(Player))
			return;

		// Check for removing SoundDefs immediately or based on distance from volume
		if (DeactivationDistanceRange <= 0)
		{
			AHazeActor TargetActor;
			if (bTriggerOnlyOnce && bLinkBothPlayersEventHandlers)
			{
				TargetActor = EventHandlerTargetActor;
			}
			else
			{
				TargetActor = OverrideActorOwner.IsValid() ? OverrideActorOwner.Get() : Player;
			}
			CrumbRemoveSoundDefs(Player, TargetActor);
		}
		else
		{
			// Start ticking so that we can track distance for SoundDef removal
			PendingPlayerRemovals.Add(Player);
			SetActorTickEnabled(true);
		}
	}

	
	UFUNCTION(BlueprintPure)
	bool GetAnyPlayerInVolume(AHazePlayerCharacter&out InPlayer)
	{
		for (auto Player : Game::Players)
		{
			if (PlayerTriggerDatas[Player].bIsInVolume)
			{
				InPlayer = Player;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsOtherPlayerInVolume(const AHazePlayerCharacter InPlayer)
	{
		return PlayerTriggerDatas[InPlayer.OtherPlayer].bIsInVolume;
	}

	UFUNCTION(BlueprintPure)
	bool HasOtherPlayerBeenInVolume(const AHazePlayerCharacter InPlayer)
	{
		return PlayerTriggerDatas[InPlayer.OtherPlayer].bHasEverEntered;
	}

	UFUNCTION(BlueprintPure)
	float GetOtherPlayerDistanceToVolume(const AHazePlayerCharacter InPlayer)
	{
		FVector _;
		return BrushComponent.GetClosestPointOnCollision(InPlayer.OtherPlayer.ActorLocation, _);
	}

	UFUNCTION(BlueprintPure)
	float GetPlayerTotalTimeInVolume(const AHazePlayerCharacter InPlayer)
	{
		const float CurrTime = Time::GetAudioTimeSince(PlayerTriggerDatas[InPlayer].EnterTimestamp);
		return CurrTime + PlayerTriggerDatas[InPlayer].TotalTimeInVolume;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Will only tick on control side

		// Check if we should deactivate pending removals
		for (int i = PendingPlayerRemovals.Num() - 1; i >= 0; --i)
		{
			auto Player = PendingPlayerRemovals[i];
			FVector _;

			const float Dist = BrushComponent.GetClosestPointOnCollision(Player.ActorLocation, _);

			if (Dist > DeactivationDistanceRange)
			{
				AHazeActor TargetActor;
				if (bTriggerOnlyOnce && bLinkBothPlayersEventHandlers)
				{
					TargetActor = EventHandlerTargetActor;
				}
				else
				{
					TargetActor = OverrideActorOwner.IsValid() ? OverrideActorOwner.Get() : Player;
				}
				CrumbRemoveSoundDefs(Player, TargetActor);

				PendingPlayerRemovals.RemoveAt(i);
			}
		}

		// No more pending removals, we can stop ticking
		if (PendingPlayerRemovals.Num() == 0)
			SetActorTickEnabled(false);
	}

	UFUNCTION()
	void OnPostSpawnerSpawnMio(AHazeActor SpawnedActor)
	{	
		EffectEvent::LinkActorToReceiveEffectEventsFrom(Game::GetMio(), SpawnedActor);
	}

	UFUNCTION()
	void OnPostSpawnerSpawnZoe(AHazeActor SpawnedActor)
	{		
		EffectEvent::LinkActorToReceiveEffectEventsFrom(Game::GetZoe(), SpawnedActor);
	}	

	UFUNCTION()
	void OnMioDied()
	{
		OnPlayerDied.Broadcast(Game::GetMio());
	}

	UFUNCTION()
	void OnZoeDied()
	{
		OnPlayerDied.Broadcast(Game::GetZoe());
	}

	UFUNCTION()
	void OnMioRespawned()
	{
		OnPlayerRespawned.Broadcast(Game::GetMio());
	}

	UFUNCTION()
	void OnZoeRespawned()
	{
		OnPlayerRespawned.Broadcast(Game::GetZoe());
	}
};

#if EDITOR
class UPlayerVOTriggerVolumeDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = APlayerVOTriggerVolume;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		AddAllCategoryDefaultProperties(n"SettingsOverride");
		// HideCategory(n"BrushSettings");
		//  EditCategory(n"VolumeSettings");

		// AddDefaultPropertiesFromOtherCategory(n"VolumeSettings", n"BrushSettings");
	}
}

// Dummy component for editor visualizations
class UPlayerVOTriggerVolumeEditorComponent : USceneComponent
{

}

class UPlayerVOTriggerVolumeComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPlayerVOTriggerVolumeEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto EditorComp = Cast<UPlayerVOTriggerVolumeEditorComponent>(Component);
		if (EditorComp == nullptr)
			return;

		APlayerVOTriggerVolume Volume = Cast<APlayerVOTriggerVolume>(Component.Owner);
		if (Volume == nullptr)
			return;

		if (Volume.DeactivationDistanceRange > 0.0)
		{
			FVector Extent = Volume.BrushComponent.BoundsExtent;
			FCollisionShape Shape = Volume.BrushComponent.GetCollisionShape();
			if (Shape.IsBox())
			{
				FVector OuterBoxExtents;
				OuterBoxExtents.X = Extent.X + Volume.DeactivationDistanceRange;
				OuterBoxExtents.Y = Extent.Y + Volume.DeactivationDistanceRange;
				OuterBoxExtents.Z = Extent.Z + Volume.DeactivationDistanceRange;

				DrawWireBox(Volume.BrushComponent.BoundsOrigin, OuterBoxExtents, Volume.BrushComponent.ComponentQuat, FLinearColor(0.23, 0.65, 0.93), 90.0);
			}
			else
			{
				DrawWireSphere(Volume.BrushComponent.WorldLocation, Extent.Size(), FLinearColor(0.23, 0.65, 0.93), 3.f);
			}
		}
	}
}
#endif

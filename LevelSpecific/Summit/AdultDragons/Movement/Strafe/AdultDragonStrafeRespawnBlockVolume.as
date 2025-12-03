#if EDITOR
class UAdultDragonStrafeRespawnBlockVisualizerComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UAdultDragonRespawnBlockVisualizerDudComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		UAdultDragonRespawnBlockVisualizerDudComponent Comp = Cast<UAdultDragonRespawnBlockVisualizerDudComponent>(Component);

		if (Comp == nullptr)
			return;

		AAdultDragonStrafeRespawnBlockVolume RespawnBlockVolume = Cast<AAdultDragonStrafeRespawnBlockVolume>(Comp.Owner);

		if (RespawnBlockVolume == nullptr)
			return;

		for (FAdultDragonRespawnObstacleData Data : RespawnBlockVolume.ObstacleData)
		{
			for (AHazeActor Actor : Data.ObjectPairings)
			{
				DrawLine(Comp.Owner.ActorLocation, Actor.ActorLocation, FLinearColor::Purple, 100.0);
			}
		}
	}
}

#endif

enum EAdultDragonRespawnBlockType
{
	Default,
	BlockOtherOnly,
	BlockBoth
}

enum EAdultDragonRespawnUnblockCondition
{
	AllRemoved,
	AnyRemoved
}

class UAdultDragonRespawnBlockVisualizerDudComponent : USceneComponent
{

}

struct FAdultDragonRespawnObstacleData
{
	UPROPERTY(EditAnywhere)
	TArray<AHazeActor> ObjectPairings;
}

class AAdultDragonStrafeRespawnBlockVolume : APlayerTrigger
{
	default BrushComponent.SetMobility(EComponentMobility::Movable);
	default SetBrushColor(FLinearColor::DPink);
	default BrushComponent.LineThickness = 3.0;

	UPROPERTY(EditAnywhere)
	TArray<FAdultDragonRespawnObstacleData> ObstacleData;

	UPROPERTY(DefaultComponent)
	UAdultDragonRespawnBlockVisualizerDudComponent VisualizerComp;

	UPROPERTY(EditAnywhere)
	EAdultDragonRespawnBlockType BlockType;

	bool bPathWasCleared;

	TPerPlayer<bool> RespawnBlockedPlayers;

	UPlayerHealthComponent MioHealthComp;
	UPlayerHealthComponent ZoeHealthComp;

	UPROPERTY(EditAnywhere)
	EAdultDragonRespawnUnblockCondition UnblockCondition = EAdultDragonRespawnUnblockCondition::AllRemoved;

	TSet<AStormChaseGrowingMetalVines> MeltedVines;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
		MioHealthComp = UPlayerHealthComponent::Get(Game::Mio);
		ZoeHealthComp = UPlayerHealthComponent::Get(Game::Zoe);
		MioHealthComp.OnReviveTriggered.AddUFunction(this, n"OnReviveTriggered");
		MioHealthComp.OnDeathTriggered.AddUFunction(this, n"OnDeathTriggered");
		ZoeHealthComp.OnReviveTriggered.AddUFunction(this, n"OnReviveTriggered");
		ZoeHealthComp.OnDeathTriggered.AddUFunction(this, n"OnDeathTriggered");

		for (FAdultDragonRespawnObstacleData Data : ObstacleData)
		{
			for (AHazeActor Obstacle : Data.ObjectPairings)
			{
				auto MetalVine = Cast<AStormChaseGrowingMetalVines>(Obstacle);
				if (MetalVine != nullptr)
				{
					MetalVine.OnStormChaseMetalVineMelted.AddUFunction(this, n"OnMetalVineMelted");
				}
			}
		}
	}

	UFUNCTION()
	private void OnMetalVineMelted(AStormChaseGrowingMetalVines Vine)
	{
		MeltedVines.Add(Vine);
	}

	UFUNCTION()
	private void OnDeathTriggered()
	{
		// if (MioHealthComp.bIsDead && ZoeHealthComp.bIsDead)
		// {
		// 	CrumbClearStrafeRespawnOverride(Game::Mio);
		// 	CrumbClearStrafeRespawnOverride(Game::Zoe);
		// }
	}

	UFUNCTION()
	private void OnReviveTriggered()
	{
	}

	bool CheckAnyRemoved()
	{
		for (FAdultDragonRespawnObstacleData Data : ObstacleData)
		{
			for (AHazeActor Obstacle : Data.ObjectPairings)
			{
				if (Obstacle != nullptr)
				{
					if (Obstacle.IsActorDisabled())
						return true;

					auto MetalVine = Cast<AStormChaseGrowingMetalVines>(Obstacle);
					bool bIsMeltedVine = MetalVine != nullptr && MeltedVines.Contains(MetalVine);
					if (bIsMeltedVine)
						return true;
				}
			}
		}
		return false;
	}

	bool CheckAllRemoved()
	{
		for (FAdultDragonRespawnObstacleData Data : ObstacleData)
		{
			for (AHazeActor Obstacle : Data.ObjectPairings)
			{
				if (Obstacle != nullptr)
				{
					auto MetalVine = Cast<AStormChaseGrowingMetalVines>(Obstacle);
					bool bIsMeltedVine = MetalVine != nullptr && MeltedVines.Contains(MetalVine);
					if (bIsMeltedVine)
						continue;

					//if we are not a vine, check if we're still active
					if (!Obstacle.IsActorDisabled())
						return false;
				}
			}
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bPathWasCleared)
			return;

		if (ObstacleData.Num() == 0)
			return;

		bool bShouldUnblock = false;

		switch (UnblockCondition)
		{
			case EAdultDragonRespawnUnblockCondition::AllRemoved:
				bShouldUnblock = CheckAllRemoved();
				break;
			case EAdultDragonRespawnUnblockCondition::AnyRemoved:
				bShouldUnblock = CheckAnyRemoved();
				break;
		}

		if (bShouldUnblock && HasControl())
		{
			for (AHazePlayerCharacter Player : Game::Players)
				CrumbClearStrafeRespawnOverride(Player);

			bPathWasCleared = true;
			SetActorTickEnabled(false);
		}
	}

	// If entering, block respawn for current player
	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (!HasControl())
			return;

		if (bPathWasCleared)
			return;

		switch (BlockType)
		{
			case EAdultDragonRespawnBlockType::Default:
				CrumbApplyStrafeRespawnOverride(Player);
				break;

			case EAdultDragonRespawnBlockType::BlockOtherOnly:
				CrumbApplyStrafeRespawnOverride(Player.OtherPlayer);
				break;

			case EAdultDragonRespawnBlockType::BlockBoth:
				CrumbApplyStrafeRespawnOverride(Player);
				CrumbApplyStrafeRespawnOverride(Player.OtherPlayer);
				break;
		}
	}

	// If exiting, unblock respawn for current player
	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if (!HasControl())
			return;

		if (Player.IsPlayerDead())
			return;
		
		if (bPathWasCleared)
			return;

		switch (BlockType)
		{
			case EAdultDragonRespawnBlockType::Default:
				CrumbClearStrafeRespawnOverride(Player);
				break;

			case EAdultDragonRespawnBlockType::BlockOtherOnly:
				CrumbClearStrafeRespawnOverride(Player.OtherPlayer);
				break;

			case EAdultDragonRespawnBlockType::BlockBoth:
				CrumbClearStrafeRespawnOverride(Player);
				CrumbClearStrafeRespawnOverride(Player.OtherPlayer);
				break;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbApplyStrafeRespawnOverride(AHazePlayerCharacter Player)
	{
		if (RespawnBlockedPlayers[Player])
			return;

		RespawnBlockedPlayers[Player] = true;

		Player.BlockCapabilities(AdultDragonCapabilityTags::AdultDragonStrafeRespawn, this);
		Player.BlockCapabilities(n"Respawn", this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbClearStrafeRespawnOverride(AHazePlayerCharacter Player)
	{
		if (!RespawnBlockedPlayers[Player])
			return;

		RespawnBlockedPlayers[Player] = false;
		Player.UnblockCapabilities(AdultDragonCapabilityTags::AdultDragonStrafeRespawn, this);
		Player.UnblockCapabilities(n"Respawn", this);
	}
}
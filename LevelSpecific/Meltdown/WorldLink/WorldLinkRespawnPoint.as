class AWorldLinkRespawnPoint : ARespawnPoint
{
	private AHazeWorldLinkAnchor BaseAnchor;
	private AHazeWorldLinkAnchor OppositeAnchor;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		BaseAnchor = WorldLink::GetClosestAnchor(ActorLocation);
		OppositeAnchor = WorldLink::GetOppositeAnchor(BaseAnchor);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BaseAnchor = WorldLink::GetClosestAnchor(ActorLocation);
		OppositeAnchor = WorldLink::GetOppositeAnchor(BaseAnchor);
	}

    FTransform GetPositionForPlayer(AHazePlayerCharacter Player) const override
    {
		FTransform Position = FinalSpawnPositions[Player] * Root.WorldTransform;
		if (Player.IsMio() != (BaseAnchor.AnchorLevel == EHazeWorldLinkLevel::SciFi))
			Position.Location = Position.Location - BaseAnchor.ActorLocation + OppositeAnchor.ActorLocation;
		return Position;
    }

    FTransform GetRelativePositionForPlayer(AHazePlayerCharacter Player) const override
    {
		FTransform RootTransform = Root.WorldTransform;
		FTransform Position = FinalSpawnPositions[Player];
		if (Player.IsMio() != (BaseAnchor.AnchorLevel == EHazeWorldLinkLevel::SciFi))
			Position.Location = Position.Location + RootTransform.InverseTransformVector(OppositeAnchor.ActorLocation - BaseAnchor.ActorLocation);
		return Position;
    }

    FTransform GetStoredSpawnPosition(EHazePlayer Player) const override
    {
		FTransform Position = FinalSpawnPositions[Player] * Root.WorldTransform;
		if ((Player == EHazePlayer::Mio) != (BaseAnchor.AnchorLevel == EHazeWorldLinkLevel::SciFi))
			Position.Location = Position.Location - BaseAnchor.ActorLocation + OppositeAnchor.ActorLocation;
		return Position;
    }

    void CreateForPlayer(EHazePlayer Player, const FTransform& RelativeTransform) override
    {
		Super::CreateForPlayer(Player, RelativeTransform);

#if EDITOR
		if (!Editor::IsCooking() && !World.IsGameWorld())
		{
			BaseAnchor = WorldLink::GetClosestAnchor(ActorLocation);
			OppositeAnchor = WorldLink::GetOppositeAnchor(BaseAnchor);

			FTransform OtherWorldTransform = RelativeTransform;
			OtherWorldTransform.Location = OtherWorldTransform.Location + ActorTransform.InverseTransformVector(OppositeAnchor.ActorLocation - BaseAnchor.ActorLocation);

			// Add an editor billboard indicating this is a respawn point
			FTransform BillboardTransform = OtherWorldTransform;
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
			CreatePlayerEditorVisualizer(Root, Player, OtherWorldTransform);
		}
#endif
	}
};
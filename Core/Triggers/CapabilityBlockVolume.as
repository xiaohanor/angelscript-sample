
class ACapabilityBlockVolume : APlayerTrigger
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(1.0, 0.5, 0.5, 1.0));

	UPROPERTY(EditAnywhere, Category = "Capability Block")
	TArray<FName> BlockTags;

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		for (auto Tag : BlockTags)
			Player.BlockCapabilities(Tag, this);

		Super::TriggerOnPlayerEnter(Player);
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		for (auto Tag : BlockTags)
			Player.UnblockCapabilities(Tag, this);

		Super::TriggerOnPlayerLeave(Player);
	}
};
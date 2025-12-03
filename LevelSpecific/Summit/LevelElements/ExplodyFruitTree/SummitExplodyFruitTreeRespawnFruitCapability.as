struct FSummitExplodyFruitTreeRespawnFruitActivationParams
{
	TArray<USummitExplodyFruitTreeAttachment> Attachments;
	TArray<ASummitExplodyFruit> RespawnableFruit;
}

class USummitExplodyFruitTreeRespawnFruitCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitExplodyFruitTree Tree;

	bool bIsInitialSpawn = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Tree = Cast<ASummitExplodyFruitTree>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitExplodyFruitTreeRespawnFruitActivationParams& Params) const
	{
		TArray<USummitExplodyFruitTreeAttachment> AttachmentsToSpawn;
		TArray<ASummitExplodyFruit> RespawnableFruit = Tree.DisabledFruits;

		for(int i = RespawnableFruit.Num() - 1; i >= 0; i--)
		{
			auto Fruit = RespawnableFruit[i];
			if(Time::GetGameTimeSince(Fruit.TimeLastExploded) < Tree.FruitGrowDelay)
				RespawnableFruit.RemoveSingleSwap(Fruit);
		}

		for(auto FruitAttachment : Tree.FruitAttachments)
		{
			// No fruit attached
			if(!FruitAttachment.AttachedFruit.IsSet())
			{
				if(RespawnableFruit.Num() <= AttachmentsToSpawn.Num())
					continue;

				// float TimeSinceExploded = Time::GetGameTimeSince(FruitAttachment.TimeLastDetached);
				// if(TimeSinceExploded >= Tree.FruitGrowDelay)
				AttachmentsToSpawn.Add(FruitAttachment);
			}
		}
		if(!AttachmentsToSpawn.IsEmpty())
		{
			Params.Attachments = AttachmentsToSpawn;
			Params.RespawnableFruit = RespawnableFruit;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitExplodyFruitTreeRespawnFruitActivationParams Params)
	{
		auto RespawnableFruit = Params.RespawnableFruit;

		for(auto Attachment : Params.Attachments)
		{
			int DisabledFruitIndex = RespawnableFruit.Num() - 1;
			auto Fruit = RespawnableFruit[DisabledFruitIndex];

			RespawnableFruit.RemoveAt(DisabledFruitIndex);
			Tree.DisabledFruits.RemoveSingleSwap(Fruit);
			Tree.EnabledFruits.Add(Fruit);

			Fruit.ActorLocation = Attachment.WorldLocation;
			Fruit.SyncedActorComp.TransitionSync(Attachment);
			Fruit.CurrentAttachment.Set(Attachment);
			Fruit.TimeLastSpawned = Time::GameTimeSeconds;
			Fruit.bIsEnabled = true;
			Fruit.bIsInitialFruit = bIsInitialSpawn;
			Fruit.Reset();

			Attachment.AttachFruit(Fruit);
			Tree.CurrentlyAttachedFruitAttachments.Add(Attachment);
		}

		bIsInitialSpawn = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}
};
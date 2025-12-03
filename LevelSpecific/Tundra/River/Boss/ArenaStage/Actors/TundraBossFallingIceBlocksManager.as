class ATundraBossFallingIceBlocksManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundraBossFallingIceBlock> IceBlocksLeftGroup;
	UPROPERTY(EditInstanceOnly)
	TArray<ATundraBossFallingIceBlock> IceBlocksRightGroup;

	int CurrentIceBlockIndex = 0;

	float IceBlockTimer = 0;
	float IceBlockTimerDuration = 0.12;
	bool bShouldTickIceBlockTimer = false;

	int Counter = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bShouldTickIceBlockTimer)
			return;

		IceBlockTimer += DeltaSeconds;
		if(IceBlockTimer >= IceBlockTimerDuration)
		{
			IceBlockTimer = 0;
			DropIceBlock();
			CurrentIceBlockIndex++;

			if(CurrentIceBlockIndex == IceBlocksLeftGroup.Num())
				bShouldTickIceBlockTimer = false;
		}
	}

	//Returns how long it takes to for the last IceBlock to initiate a drop.
	float StartDroppingIceBlocks()
	{
		CurrentIceBlockIndex = 0;
		bShouldTickIceBlockTimer = true;

		return IceBlockTimerDuration * (IceBlocksLeftGroup.Num() - 1); //-1 cause the first iteration is instant.
	}

	void DropIceBlock()
	{
		IceBlocksLeftGroup[CurrentIceBlockIndex].DropIceBlock();
		IceBlocksRightGroup[CurrentIceBlockIndex].DropIceBlock();
	}

	UFUNCTION(CallInEditor)
	void FillIceBlockArray()
	{
		TArray<ATundraBossFallingIceBlock> Blocks;
		TArray<ATundraBossFallingIceBlock> UnsortedBlocksLeft;
		TArray<ATundraBossFallingIceBlock> UnsortedBlocksRight;
		TArray<ATundraBossFallingIceBlock> SortedBlocksLeft;
		TArray<ATundraBossFallingIceBlock> SortedBlocksRight;

		TListedActors<ATundraBossFallingIceBlock> ListedIceBlocks;
		for (ATundraBossFallingIceBlock IceBlock : ListedIceBlocks)
		{
			Blocks.Add(IceBlock);
		}

		for(auto Block : Blocks)
		{
			float XDelta = Block.ActorLocation.X - ActorLocation.X;
			if(XDelta > 0)
				UnsortedBlocksLeft.Add(Block);
			else
				UnsortedBlocksRight.Add(Block);
		}

		while(UnsortedBlocksLeft.Num() > 0)
		{
			float HighestValue = SMALL_NUMBER;
			int CurrentIndex = 0;

			for (int i = 0; i < UnsortedBlocksLeft.Num(); i++)
			{
				if (UnsortedBlocksLeft[i].GetHorizontalDistanceTo(this) > HighestValue)
				{
					HighestValue = UnsortedBlocksLeft[i].GetHorizontalDistanceTo(this);
					CurrentIndex = i;
				}
			}
			
			SortedBlocksLeft.Add(UnsortedBlocksLeft[CurrentIndex]);
			UnsortedBlocksLeft.RemoveAt(CurrentIndex);
		}

		while(UnsortedBlocksRight.Num() > 0)
		{
			float HighestValue = SMALL_NUMBER;
			int CurrentIndex = 0;

			for (int i = 0; i < UnsortedBlocksRight.Num(); i++)
			{
				if (UnsortedBlocksRight[i].GetHorizontalDistanceTo(this) > HighestValue)
				{
					HighestValue = UnsortedBlocksRight[i].GetHorizontalDistanceTo(this);
					CurrentIndex = i;
				}
			}
			
			SortedBlocksRight.Add(UnsortedBlocksRight[CurrentIndex]);
			UnsortedBlocksRight.RemoveAt(CurrentIndex);
		}

		IceBlocksLeftGroup = SortedBlocksLeft;
		IceBlocksRightGroup = SortedBlocksRight;
	}
};
class UTurnSegmentsMioTurnCapability : UHazePlayerCapability
{
    UTurnSegmentsMioComponent PlayerComp;
    UTurnSegmentsMioDataComponent PlayerData;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UTurnSegmentsMioComponent::Get(Player);
        PlayerData = UTurnSegmentsMioDataComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        // Create chains from all the response components to allow for creating constraints between them later
        TArray<FTurnSegmentResponseChain> ResponseCompChains = CreateResponseCompChains();

        for(int i = 0; i < ResponseCompChains.Num(); i++)
        {
            // For each ResponseComp chain, create a chain of constraints
            FTurnSegmentConstraintChain ConstraintChain = CreateConstraintChain(ResponseCompChains[i]);
            PlayerComp.ConstraintChains.Add(ConstraintChain);
        }
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        PlayerComp.ConstraintChains.Empty();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        const FVector2D InputVector = MioFullScreen::GetStickInput(this);

		Print("Input: " + InputVector.ToString(), 0.0);

        const AHazePlayerCharacter Zoe = Game::GetZoe();
        const FVector ZoeLocation = Zoe.ActorLocation;
        const FVector ZoeCameraDirection = Game::GetZoe().ViewRotation.ForwardVector;

        const FVector Location = ZoeLocation + (ZoeCameraDirection * PlayerData.Settings.DistanceAhead);
        Debug::DrawDebugSphere(Location, 100.0, 24, FLinearColor::Red, 1.0);

        // Start the constraint chain at the closest turn segment to the player (with a slight forward offset)
        UTurnSegmentResponseComponent TurnSegment = GetClosestTurnSegment(Location);

        // Turn that segment
        TurnSegment.OnPlayerTurnSegment(InputVector.X * PlayerData.Settings.TurnSpeed * DeltaTime);

		if(PlayerData.Settings.bUseSoftConstraintToo)
		{
			for(auto Neighbor : TurnSegment.Neighbors)
				SolveSoftConstraintRecursive(TurnSegment, Neighbor);
		}

		int ConstraintChainIndex = -1;
		int ConstraintToPrevious = -1;
		int ConstraintToNext = -1;

		// Find the response component we turned in the constraint chain
		// Note: We only update the constraints on the touched constraint chain. Might cause issues, but at the moment it is a nice unintentional culling method
		FindResponseCompConstraints(TurnSegment, ConstraintChainIndex, ConstraintToPrevious, ConstraintToNext);

		if(ConstraintChainIndex < 0)
			return; // Invalid chain, probably a chain of just one response comp

		// Solve contraints down the chain
		SolveHardConstraintRecursive(ConstraintChainIndex, ConstraintToPrevious, ETurnSegmentConstraintIndex::Second);

		// Solve constraints up the chain
		SolveHardConstraintRecursive(ConstraintChainIndex, ConstraintToNext, ETurnSegmentConstraintIndex::First);
    }

    /**
     * Create chains of linked UTurnSegmentResponseComponents
     */
    private TArray<FTurnSegmentResponseChain> CreateResponseCompChains()
    {
        TArray<FTurnSegmentResponseChain> ResponseCompChains;
        for(int i = 0; i < PlayerComp.ResponseComponents.Num(); i++)
        {
            UTurnSegmentResponseComponent First = PlayerComp.ResponseComponents[i];
            if(!First.IsEdge())
            {
                continue;   // We only want to find response components that are edges, since we will then traverse through the chain
            }
            else
            {
                // But if it is an edge, check if it has already been added, since there are 2 edges in each chain
                bool bEdgeHasAlreadyBeenAddedToChain = false;
                for(int j = 0; j < ResponseCompChains.Num(); j++)
                {
                    for(int k = 0; k < ResponseCompChains[j].Links.Num(); k++)
                    {
                        if(ResponseCompChains[j].Links[k] == First)
                            bEdgeHasAlreadyBeenAddedToChain = true;
                    }
                }

                if(bEdgeHasAlreadyBeenAddedToChain)
                    continue;
            }

            // Add the edge as the first link in the chain
            FTurnSegmentResponseChain ResponseCompChain;
            ResponseCompChain.Links.Add(First);

            // Find the only neighbor. The definition of an edge is that it only has one neighbor
            UTurnSegmentResponseComponent Neighbor = First.Neighbors[0];
            AddToResponseCompChainRecursive(ResponseCompChain, Neighbor, First);

            ResponseCompChains.Add(ResponseCompChain);
        }

        return ResponseCompChains;
    }

    /**
     * Recursively travel through the response component chain to add all linked resposne components to the chain
     */
    void AddToResponseCompChainRecursive(FTurnSegmentResponseChain& Chain, UTurnSegmentResponseComponent Current, UTurnSegmentResponseComponent Previous)
    {
        Chain.Links.Add(Current);
        if(!Current.IsEdge())
        {
            // We have not reached the end of the chain, traverse to the next neighbor
            if(Current.Neighbors[0] == Previous)
                AddToResponseCompChainRecursive(Chain, Current.Neighbors[1], Current);
            else
                AddToResponseCompChainRecursive(Chain, Current.Neighbors[0], Current);
        }
    }

    /**
     * Create constraints between all the response components in ResponseCompChain, and make those into a constraint chain
     */
    private FTurnSegmentConstraintChain CreateConstraintChain(FTurnSegmentResponseChain ResponseCompChain)
    {
        FTurnSegmentConstraintChain Chain;
        Chain.Links.Reserve(ResponseCompChain.Links.Num() - 1);

        for(int i = 0; i < ResponseCompChain.Links.Num() - 1; i++)
        {
            UTurnSegmentResponseComponent First = ResponseCompChain.Links[i];
            UTurnSegmentResponseComponent Second = ResponseCompChain.Links[i + 1];
            FTurnSegmentConstraint Constraint = FTurnSegmentConstraint(First, Second, PlayerData.Settings.ConstrainAngle);
            Chain.Links.Add(Constraint);
        }

        return Chain;
    }

    /**
     * Find what constraints are active for ResponseComp
     * Previous will be negative if invalid
     * Next will be > Num() if invalid
     */
    private void FindResponseCompConstraints(UTurnSegmentResponseComponent ResponseComp, int& OutConstraintChainIndex, int& OutConstraintToPrevious, int& OutConstraintToNext)
    {
        for(int i = 0; i < PlayerComp.ConstraintChains.Num(); i++)
        {
            for(int j = 0; j < PlayerComp.ConstraintChains[i].Links.Num(); j++)
            {
                ETurnSegmentConstraintIndex Index = PlayerComp.ConstraintChains[i].Links[j].IsConstraining(ResponseComp);
                if(Index == ETurnSegmentConstraintIndex::None)
                    continue;

                // This constraint is constraining the current ResponseComp

                OutConstraintChainIndex = i;

                if(Index == ETurnSegmentConstraintIndex::First)
                {
                    OutConstraintToPrevious = j - 1;
                    OutConstraintToNext = j;
                }
                else
                {
                    OutConstraintToPrevious = j;
                    OutConstraintToNext = j + 1;
                }

                return;
            }
        }
    }

    /**
     * Traverse through the constraint chain in one direction and update the constraints
     */
    private void SolveHardConstraintRecursive(int ConstrtaintChainIndex, int Current, ETurnSegmentConstraintIndex Origin)
    {
        FTurnSegmentConstraintChain Chain = PlayerComp.ConstraintChains[ConstrtaintChainIndex];

        // If Current is not within the chain range, we have reached the end
        if(Current < 0 || Current >= Chain.Links.Num())
            return;

        Chain.Links[Current].UpdateConstraint(Origin);

        // Get the index of the next constraint
        int Next = Origin == ETurnSegmentConstraintIndex::First ? Current + 1 : Current - 1;
        SolveHardConstraintRecursive(ConstrtaintChainIndex, Next, Origin);
    }

	private void SolveSoftConstraintRecursive(UTurnSegmentResponseComponent Previous, UTurnSegmentResponseComponent Current)
	{
		if(Current.Neighbors.Num() > 1)
			Current.Velocity = (Current.Neighbors[0].Velocity + Current.Neighbors[1].Velocity) * 0.5;

		for(auto Neighbor : Current.Neighbors)
		{
			if(Neighbor == Previous)
				continue;

			SolveSoftConstraintRecursive(Current, Neighbor);
		}
	}

    private UTurnSegmentResponseComponent GetClosestTurnSegment(FVector Location)
    {
        int ClosestIndex = -1;
        float ClosestDistanceSquared = 0;

        for(int i = 0; i < PlayerComp.ResponseComponents.Num(); i++)
        {
            const float DistanceSquared = Location.DistSquared(PlayerComp.ResponseComponents[i].Owner.ActorLocation);

            if(ClosestIndex < 0 || DistanceSquared < ClosestDistanceSquared)
            {
                ClosestIndex = i;
                ClosestDistanceSquared = DistanceSquared;

            }
        }

        if(ClosestIndex < 0)
            return nullptr;

        return PlayerComp.ResponseComponents[ClosestIndex];
    }
}
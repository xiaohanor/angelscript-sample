namespace StoneBeastTail
{
	void GetAllTailSegmentsWithTag(EStoneBeastTailSegmentChainID ChainID, TArray<AStoneBeastTailSegment>& OutTailSegments)
	{
		for (auto TailSegment : TListedActors<AStoneBeastTailSegment>().Array)
		{
			if (TailSegment.HasChainID(ChainID))
				OutTailSegments.Add(TailSegment);
		}
	}
	UFUNCTION()
	void StopAllTailSegmentsWithID(float StopDuration, EStoneBeastTailSegmentChainID ChainID)
	{
		TArray<AStoneBeastTailSegment> TailSegments;
		StoneBeastTail::GetAllTailSegmentsWithTag(ChainID, TailSegments);
		for (auto TailSegment : TailSegments)
		{
			TailSegment.StopMoving(StopDuration);
		}
	}

	UFUNCTION()
	void StartAllTailSegmentsWithID(EStoneBeastTailSegmentChainID ChainID)
	{
		TArray<AStoneBeastTailSegment> TailSegments;
		StoneBeastTail::GetAllTailSegmentsWithTag(ChainID, TailSegments);
		for (auto TailSegment : TailSegments)
		{
			TailSegment.StartMoving();
		}
	}

	UFUNCTION()
	void StartAllTailSegmentsExcluding(EStoneBeastTailSegmentChainID ChainID, TSet<EStoneBeastTailSegmentChainID> ExclusionIDs = TSet<EStoneBeastTailSegmentChainID>())
	{
		TArray<AStoneBeastTailSegment> TailSegments;
		StoneBeastTail::GetAllTailSegmentsWithTag(ChainID, TailSegments);
		for (auto TailSegment : TailSegments)
		{
			bool bFoundExclusionID = false;
			for (auto ExclusionID : ExclusionIDs)
			{
				if (TailSegment.HasChainID(ExclusionID))
				{
					bFoundExclusionID = true;
					break;
				}
			}

			if (bFoundExclusionID)
				continue;
			TailSegment.StartMoving();
		}
	}
}
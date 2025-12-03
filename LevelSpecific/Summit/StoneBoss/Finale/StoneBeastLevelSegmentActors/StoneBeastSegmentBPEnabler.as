class AStoneBeastSegmentBPEnabler : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	int ID = -1;

	TArray<AStoneBeastSegmentActor> Segments;
	AStoneBeastSegmentActor TargetSegment;

	UFUNCTION()
	void EnableTargetSegment()
	{
		Segments = TListedActors<AStoneBeastSegmentActor>().Array;

		for (AStoneBeastSegmentActor Segment : Segments)
		{
			if (Segment.BPEnablerID < 0)
				continue;

			if (Segment.BPEnablerID == ID)
				TargetSegment = Segment;
		}

		if (devEnsure(TargetSegment == nullptr, "TargetSegment has not been set. Ensure that IDs match."))
			return;
		
		TargetSegment.EnableFromStartDisabled();
	}
};
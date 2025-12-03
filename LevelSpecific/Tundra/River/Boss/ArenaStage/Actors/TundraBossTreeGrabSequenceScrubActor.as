class ATundraBossTreeGrabSequenceScrubActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	AHazeLevelSequenceActor TreeScrubSequence;
	float CurrentTime = 0;

	bool bMashCompleted = false;
	bool bProgressHasStarted = false;

	UFUNCTION()
	void StartTreeGrabSeqScrub(AHazeLevelSequenceActor Sequence)
	{
		TreeScrubSequence = Sequence;
		TreeScrubSequence.SetupForScrubbing(3);
		bMashCompleted = false;
		CurrentTime = 3;
		bProgressHasStarted = false;
		SetActorTickEnabled(true);
	}

	void ScrubSeqBasedOnMashProgress(float Progress)
	{
		if(TreeScrubSequence == nullptr)	
			return;

		if(bMashCompleted)
			return;

		bProgressHasStarted = true;
		CurrentTime = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(0, 6), Progress);
		ScrubTreeGrabSequence();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bProgressHasStarted && TreeScrubSequence != nullptr)
		{
			CurrentTime = 3;
			ScrubTreeGrabSequence();
		}

		if(!bMashCompleted)
			return;

		CurrentTime += DeltaSeconds;
		ScrubTreeGrabSequence();

		if(CurrentTime >= TreeScrubSequence.DurationAsSeconds)
			SetActorTickEnabled(false);
	}

	void MashWasSuccessful()
	{
		bMashCompleted = true;
		CurrentTime = 6;
	}

	void ScrubTreeGrabSequence()
	{
		FMovieSceneSequencePlaybackParams Params;
		Params.Time = CurrentTime;
		Params.PositionType = EMovieScenePositionType::Time;
		Params.UpdateMethod = EUpdatePositionMethod::Scrub;
		TreeScrubSequence.GetSequencePlayer().SetPlaybackPosition(Params);
	}
};
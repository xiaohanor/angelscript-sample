struct FSketchbookPencilDrawSentenceActivateParams
{
	USketchbookDrawableSentenceComponent DrawableSentence;
};

struct FSketchbookPencilDrawSentenceDeactivateParams
{
	bool bNatural = false;
	bool bFinished = false;
};

struct FSketchbookPencilDrawSentenceEnqueueStartDrawWordParams
{
	FSketchbookWord Word;
	bool bIsLastWord;
};

struct FSketchbookPencilDrawSentenceEnqueueTravelToNextWordParams
{
	FSketchbookWord PreviousWord;
	FSketchbookWord NextWord;
};

class USketchbookPencilDrawSentenceCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASketchbookPencil Pencil;
	USketchbookPencilSentenceComponent SentenceComp;

	float DrawSpeedMultiplier;
	USketchbookDrawableSentenceComponent DrawableSentence;
	
	FHazeActionQueue ActionQueue;
	float DrawDuration;

	bool bIsFastForwarding = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
		SentenceComp = USketchbookPencilSentenceComponent::Get(Owner);

		ActionQueue.Initialize(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSketchbookPencilDrawSentenceActivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return false;

		if(!Pencil.CurrentRequest.IsSet())
			return false;

		FSketchbookPencilRequest Request = Pencil.CurrentRequest.GetValue();

		if(Request.bErase)
			return false;

		// Wait until the pencil has turned around
		if(Pencil.GetPivotState() != ESketchbookPencilPivotState::Drawing)
			return false;

		auto Drawable = Cast<USketchbookDrawableSentenceComponent>(Request.Drawable);
		if(Drawable == nullptr)
			return false;

		Params.DrawableSentence = Drawable;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSketchbookPencilDrawSentenceDeactivateParams& Params) const
	{
		if(!Pencil.bIsActive)
		{
			Params.bNatural = true;
			return true;
		}

		if(!Pencil.CurrentRequest.IsSet())
		{
			Params.bNatural = true;
			return true;
		}

		if(Pencil.CurrentRequest.Value.WasInterrupted())
		{
			Params.bNatural = true;
			return true;
		}

		if(ActionQueue.IsEmpty())
		{
			Params.bNatural = true;
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookPencilDrawSentenceActivateParams Params)
	{
		DrawableSentence = Params.DrawableSentence;

		// Prepare the action queue with all the words we want to draw
		SetupActionQueue();

		DrawableSentence.OnLanguageChanged.AddUFunction(this, n"OnLanguageChanged");

		Pencil.OnStartDrawing(DrawableSentence);

		ASketchbookSentence Sentence = Cast<ASketchbookSentence>(DrawableSentence.Owner);
		if(Sentence != nullptr)
			Sketchbook::GetNarrator().PlayNarratorVox(Sentence);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSketchbookPencilDrawSentenceDeactivateParams Params)
	{
		DrawableSentence.OnLanguageChanged.Unbind(this, n"OnLanguageChanged");

		if(Params.bNatural)
		{
			if(Params.bFinished)
			{
				if(!ActionQueue.IsEmpty())
				{
					// Make sure we finish the queue
					bIsFastForwarding = true;
					ActionQueue.Update(DrawableSentence.GetSentenceDrawDuration(true));
					bIsFastForwarding = false;
				}

				Pencil.OnFinishedDrawing(DrawableSentence);
			}
			else
			{
				Pencil.OnInterrupted(DrawableSentence);
			}
		}

		ActionQueue.Empty();
		DrawableSentence = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ActionQueue.Update(DeltaTime * DrawSpeedMultiplier);

#if !RELEASE
		if(DevTogglesSketchbook::DrawWordBounds.IsEnabled())
			DrawableSentence.DebugDrawBounds();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("ActionQueue", ActionQueue);
	}

	UFUNCTION()
	private void OnLanguageChanged()
	{
		bIsFastForwarding = true;

		// Update our action queue with the new language
		SetupActionQueue();

		// Scrub to our current position
		ActionQueue.Update(ActiveDuration * DrawSpeedMultiplier);
		bIsFastForwarding = false;
	}

	float GetDeltaTime() const
	{
		return Time::GetActorDeltaSeconds(Owner);
	}

	void SetupActionQueue()
	{
		ActionQueue.Empty();

		// We may need to speed up our drawing compared to the english duration
		const float EnglishSentenceDrawDuration = DrawableSentence.GetSentenceDrawDuration(false);
		const float LocalizedSentenceDrawDuration = DrawableSentence.GetSentenceDrawDuration(true);
		DrawSpeedMultiplier = LocalizedSentenceDrawDuration / EnglishSentenceDrawDuration;

		for(int i = 0; i < DrawableSentence.GetWords().Num(); i++)
		{
			FSketchbookWord Word = DrawableSentence.GetWords()[i];

			if(Word.PreDelay > 0)
				EnqueuePreDelay(Word);

			const bool bIsLastWord = i == DrawableSentence.GetWords().Num() - 1;
			EnqueueStartDrawWord(Word, bIsLastWord);

			switch(Word.WordType)
			{
				case ESketchbookWordType::Word:
					EnqueueDrawWord(Word);
					break;

				case ESketchbookWordType::Line:
					EnqueueDrawLine(Word);
					break;

				case ESketchbookWordType::Dots:
					EnqueueDrawDots(Word);
					break;

				case ESketchbookWordType::Exclamations:
					EnqueueDrawExclamations(Word);
					break;
			}

			EnqueueFinishDrawWord();

			if(Word.PostDelay > 0)
				EnqueuePostDelay(Word);

			if(!bIsLastWord)
			{
				FSketchbookWord NextWord = DrawableSentence.GetWords()[i + 1];
				EnqueueTravelToNextWord(Word, NextWord);
			}
		}
	}

	void EnqueuePreDelay(FSketchbookWord Word)
	{
		ActionQueue.Duration(Word.PreDelay, this, n"PreDelay", Word);
	}

	void EnqueueStartDrawWord(FSketchbookWord Word, bool bIsLastWord)
	{
		FSketchbookPencilDrawSentenceEnqueueStartDrawWordParams Params;
		Params.Word = Word;
		Params.bIsLastWord = bIsLastWord;
		ActionQueue.Event(this, n"StartDrawWord", Params);
	}

	void EnqueueDrawWord(FSketchbookWord Word)
	{
		const float WordDrawDuration = Word.GetDrawDuration(DrawableSentence, false);
		ActionQueue.Duration(WordDrawDuration, this, n"DrawWord", Word);
	}

	void EnqueueDrawLine(FSketchbookWord Word)
	{
		const float WordDrawDuration = Word.GetDrawDuration(DrawableSentence, false);
		ActionQueue.Duration(WordDrawDuration, this, n"DrawLine", Word);
	}

	void EnqueueDrawDots(FSketchbookWord Word)
	{
		const float WordDrawDuration = Word.GetDrawDuration(DrawableSentence, false);
		ActionQueue.Duration(WordDrawDuration, this, n"DrawDots", Word);
	}

	void EnqueueDrawExclamations(FSketchbookWord Word)
	{
		const float WordDrawDuration = Word.GetDrawDuration(DrawableSentence, false);
		ActionQueue.Duration(WordDrawDuration, this, n"DrawExclamations", Word);
	}

	void EnqueueFinishDrawWord()
	{
		ActionQueue.Event(this, n"FinishDrawWord");
	}

	void EnqueuePostDelay(FSketchbookWord Word)
	{
		ActionQueue.Duration(Word.PostDelay, this, n"PostDelay", Word);
	}

	void EnqueueTravelToNextWord(FSketchbookWord PreviousWord, FSketchbookWord NextWord)
	{
		ActionQueue.Event(this, n"GoToNextWord", PreviousWord);

		const float TravelToNextWordDuration = DrawableSentence.GetTravelToNextWordDuration();
		FSketchbookPencilDrawSentenceEnqueueTravelToNextWordParams Params;
		Params.PreviousWord = PreviousWord;
		Params.NextWord = NextWord;
		ActionQueue.Duration(TravelToNextWordDuration, this, n"TravelToNextWord", Params);
	}

	UFUNCTION()
	private void PreDelay(float Alpha, FSketchbookWord Word)
	{
		if(bIsFastForwarding)
			return;

		const float DeltaTime = GetDeltaTime();

		const FVector Location = Word.GetDrawStartLocation(DrawableSentence);

		Pencil.MoveAccelerateTo(Location, 1, DeltaTime, this);

		// Some offset to frame it better
		FVector TipOffset = Sketchbook::Sentence::DrawWaitingOffset;

		// Add some perlin noise to it
		const float Time = Time::GameTimeSeconds;
		TipOffset += FVector(
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingPerlinFrequency.X) * Sketchbook::Sentence::DrawWaitingPerlinAmplitude.X,
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingPerlinFrequency.Y) * Sketchbook::Sentence::DrawWaitingPerlinAmplitude.Y,
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingPerlinFrequency.Z) * Sketchbook::Sentence::DrawWaitingPerlinAmplitude.Z
		);

		Pencil.MoveTipOffsetAccelerateTo(TipOffset, 0.5, DeltaTime, this);

		FRotator TipRotationOffset = FRotator::ZeroRotator;
		TipRotationOffset += FRotator(
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingRotationPerlinFrequency.Pitch) * Sketchbook::Sentence::DrawWaitingRotationPerlinAmplitude.Pitch,
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingRotationPerlinFrequency.Yaw) * Sketchbook::Sentence::DrawWaitingRotationPerlinAmplitude.Yaw,
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingRotationPerlinFrequency.Roll) * Sketchbook::Sentence::DrawWaitingRotationPerlinAmplitude.Roll
		);

		Pencil.RotateTipOffsetTowards(TipRotationOffset, 0.4, DeltaTime, this);

#if !RELEASE
		TEMPORAL_LOG(this).Page("States")
			.Status("PreDelay", FLinearColor::White)
			.Value("Alpha", Alpha)
			.Struct("Word;", Word)
		;
#endif
	}

	UFUNCTION()
	private void StartDrawWord(FSketchbookPencilDrawSentenceEnqueueStartDrawWordParams Params)
	{
		if(bIsFastForwarding)
			return;

		FSketchbookPencilDrawWordParams EventData = FSketchbookPencilDrawWordParams(
			DrawableSentence,
			Params.Word,
			Params.bIsLastWord
		);

		USketchbookPencilEventHandler::Trigger_OnStartDrawingWord(Pencil, EventData);

#if !RELEASE
		TEMPORAL_LOG(this).Page("States")
			.Event("StartDrawWord")
			.Struct("Word;", Params.Word)
			.Value("bIsLastWord", Params.bIsLastWord)
		;
#endif
	}

	UFUNCTION()
	private void DrawWord(float Alpha, FSketchbookWord Word)
	{
		const float DistanceWithinWord = Word.GetWordWidth() * Alpha;
		const float TotalDistance = Word.Origin.X + DistanceWithinWord;

		float SentenceMin;
		float SentenceMax;
		DrawableSentence.GetSentenceXMinMax(SentenceMin, SentenceMax);

		float RevealFraction = Math::NormalizeToRange(TotalDistance, SentenceMin, SentenceMax);

		if(bIsFastForwarding)
		{
			// Don't update drawn fraction, that makes noises
			DrawableSentence.SetTextRevealRatio(RevealFraction, false);
		}
		else
		{
			DrawableSentence.UpdateDrawnFraction(RevealFraction, false);
		}

		if(bIsFastForwarding)
			return;

		const float DeltaTime = GetDeltaTime();
		DrawDuration += DeltaTime;

		FVector PenLocation = Word.GetWordWorldTransform(DrawableSentence).TransformPosition(FVector(0, -DistanceWithinWord, DrawableSentence.DrawHeightOffset));
		Pencil.MoveAccelerateTo(PenLocation, 0.05, DeltaTime, this);

		FVector TipOffset = GetTargetTipOffset(Word);
		Pencil.MoveTipOffsetAccelerateTo(TipOffset, 0.1, DeltaTime, this);

		FRotator Rotation = GetDrawWordTargetTipRotationOffset();
		Pencil.RotateTipOffsetTowards(Rotation, 0.01, DeltaTime, this);

#if !RELEASE
		TEMPORAL_LOG(this).Page("States")
			.Status("DrawWord", FLinearColor::Blue)
			.Value("Alpha", Alpha)
			.Struct("Word;", Word)
		;
#endif
	}

	UFUNCTION()
	private void DrawLine(float Alpha, FSketchbookWord Word)
	{
		const float DistanceWithinWord = Word.GetWordWidth() * Alpha;
		const float TotalDistance = Word.Origin.X + DistanceWithinWord;

		float SentenceMin;
		float SentenceMax;
		DrawableSentence.GetSentenceXMinMax(SentenceMin, SentenceMax);

		float RevealFraction = Math::NormalizeToRange(TotalDistance, SentenceMin, SentenceMax);
		DrawableSentence.UpdateDrawnFraction(RevealFraction, false);

		if(bIsFastForwarding)
			return;

		const float DeltaTime = GetDeltaTime();

		FVector PenLocation = Word.GetWordWorldTransform(DrawableSentence).TransformPosition(FVector(0, -DistanceWithinWord, -Word.Bounds.Y));
		Pencil.MoveAccelerateTo(PenLocation, 0.05, DeltaTime, this);

		Pencil.MoveTipOffsetAccelerateTo(FVector::ZeroVector, 0.05, DeltaTime, this);
		Pencil.RotateTipOffsetTowards(FRotator::ZeroRotator, 0.05, DeltaTime, this);
	}

	UFUNCTION()
	private void DrawDots(float Alpha, FSketchbookWord Word)
	{
		const float DistanceWithinWord = Word.GetWordWidth() * Alpha;
		const float TotalDistance = Word.Origin.X + DistanceWithinWord;

		float SentenceMin;
		float SentenceMax;
		DrawableSentence.GetSentenceXMinMax(SentenceMin, SentenceMax);

		float RevealFraction = Math::NormalizeToRange(TotalDistance, SentenceMin, SentenceMax);
		DrawableSentence.UpdateDrawnFraction(RevealFraction, false);

		if(bIsFastForwarding)
			return;

		const float DeltaTime = GetDeltaTime();

		FVector PenLocation = Word.GetWordWorldTransform(DrawableSentence).TransformPosition(FVector(0, -DistanceWithinWord, -Word.Bounds.Y));
		Pencil.MoveAccelerateTo(PenLocation, 0.05, DeltaTime, this);

		Pencil.MoveTipOffsetAccelerateTo(FVector::ZeroVector, 0.05, DeltaTime, this);
		Pencil.RotateTipOffsetTowards(FRotator::ZeroRotator, 0.05, DeltaTime, this);
	}

	UFUNCTION()
	private void DrawExclamations(float Alpha, FSketchbookWord Word)
	{
		const float DistanceWithinWord = Word.GetWordWidth() * Alpha;
		const float TotalDistance = Word.Origin.X + DistanceWithinWord;

		float SentenceMin;
		float SentenceMax;
		DrawableSentence.GetSentenceXMinMax(SentenceMin, SentenceMax);

		float RevealFraction = Math::NormalizeToRange(TotalDistance, SentenceMin, SentenceMax);
		DrawableSentence.UpdateDrawnFraction(RevealFraction, false);

		if(bIsFastForwarding)
			return;

		const float DeltaTime = GetDeltaTime();

		FVector PenLocation = Word.GetWordWorldTransform(DrawableSentence).TransformPosition(FVector(0, -DistanceWithinWord, -Word.Bounds.Y));
		Pencil.MoveAccelerateTo(PenLocation, 0.05, DeltaTime, this);

		Pencil.MoveTipOffsetAccelerateTo(FVector::ZeroVector, 0.05, DeltaTime, this);
		Pencil.RotateTipOffsetTowards(FRotator::ZeroRotator, 0.05, DeltaTime, this);
	}

	UFUNCTION()
	private void FinishDrawWord()
	{
		if(bIsFastForwarding)
			return;

		USketchbookPencilEventHandler::Trigger_OnFinishedDrawingWord(Pencil);

#if !RELEASE
		TEMPORAL_LOG(this).Page("States")
			.Event("FinishDrawWord")
		;
#endif
	}

	UFUNCTION()
	private void PostDelay(float Alpha, FSketchbookWord Word)
	{
		if(bIsFastForwarding)
			return;

		const float DeltaTime = GetDeltaTime();

		const FVector Location = Word.GetDrawEndLocation(DrawableSentence);

		Pencil.MoveAccelerateTo(Location, 1, DeltaTime, this);

		// Some offset to frame it better
		FVector TipOffset = Sketchbook::Sentence::DrawWaitingOffset;

		// Add some perlin noise to it
		const float Time = Time::GameTimeSeconds;
		TipOffset += FVector(
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingPerlinFrequency.X) * Sketchbook::Sentence::DrawWaitingPerlinAmplitude.X,
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingPerlinFrequency.Y) * Sketchbook::Sentence::DrawWaitingPerlinAmplitude.Y,
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingPerlinFrequency.Z) * Sketchbook::Sentence::DrawWaitingPerlinAmplitude.Z
		);

		Pencil.MoveTipOffsetAccelerateTo(TipOffset, 0.5, DeltaTime, this);

		FRotator TipRotationOffset = FRotator::ZeroRotator;
		TipRotationOffset += FRotator(
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingRotationPerlinFrequency.Pitch) * Sketchbook::Sentence::DrawWaitingRotationPerlinAmplitude.Pitch,
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingRotationPerlinFrequency.Yaw) * Sketchbook::Sentence::DrawWaitingRotationPerlinAmplitude.Yaw,
			Math::PerlinNoise1D(Time * Sketchbook::Sentence::DrawWaitingRotationPerlinFrequency.Roll) * Sketchbook::Sentence::DrawWaitingRotationPerlinAmplitude.Roll
		);

		Pencil.RotateTipOffsetTowards(TipRotationOffset, 0.4, DeltaTime, this);

#if !RELEASE
		TEMPORAL_LOG(this).Page("States")
			.Status("PostDelay", FLinearColor::DPink)
			.Value("Alpha", Alpha)
			.Struct("Word;", Word)
		;
#endif
	}

	UFUNCTION()
	private void GoToNextWord(FSketchbookWord PreviousWord)
	{
		float EndOfWordDistance = PreviousWord.Origin.X + PreviousWord.GetWordWidth();
	
		// Adjust the word if centered
		// Ugly hack but hey we gotta ship soon
		if(DrawableSentence.GetTextRenderComponent().HorizontalAlignment == EHorizTextAligment::EHTA_Center)
		{
			const FBoxSphereBounds FullSentenceBounds = DrawableSentence.GetTextRenderComponent().PreviewCalcBounds(DrawableSentence.GetTextRenderComponent().Text.ToString(), FTransform::Identity);
			EndOfWordDistance += FullSentenceBounds.BoxExtent.Y;
		}
		
		float RevealFraction = EndOfWordDistance / DrawableSentence.GetSentenceWidth();
		DrawableSentence.UpdateDrawnFraction(RevealFraction, false);

#if !RELEASE
		TEMPORAL_LOG(this).Page("States")
			.Event("GoToNextWord")
			.Struct("Word;", PreviousWord)
		;
#endif
	}

	UFUNCTION()
	private void TravelToNextWord(float Alpha, FSketchbookPencilDrawSentenceEnqueueTravelToNextWordParams Params)
	{
		if(bIsFastForwarding)
			return;

		const float DeltaTime = GetDeltaTime();

		const FVector StartLocation = Params.PreviousWord.GetDrawEndLocation(DrawableSentence);
		const FVector EndLocation = Params.NextWord.GetDrawStartLocation(DrawableSentence);

		const FVector Location = Math::Lerp(StartLocation, EndLocation, Alpha);
		const FVector Velocity = (Location - Pencil.ActorLocation) / DeltaTime;
		Pencil.SnapPencilTo(Location, Velocity, this);

		const FVector TipOffset = GetTargetTipOffset(Params.NextWord);
		Pencil.MoveTipOffsetAccelerateTo(TipOffset + FVector(-10, 0, 5), 0.2, DeltaTime, this);

#if !RELEASE
		TEMPORAL_LOG(this).Page("States")
			.Status("TravelToNextWord", FLinearColor::Green)
			.Value("Alpha", Alpha)
			.Struct("PreviousWord;", Params.PreviousWord)
			.Struct("NextWord;", Params.NextWord)
		;
#endif
	}
	
	FRotator GetDrawWordTargetTipRotationOffset() const
	{
		return FRotator(
			Math::PerlinNoise1D(DrawDuration * DrawableSentence.GetDrawPitchFrequency()) * Sketchbook::Sentence::DrawPitchAmplitude,
			0,
			Math::PerlinNoise1D(DrawDuration * DrawableSentence.GetDrawYawFrequency()) * Sketchbook::Sentence::DrawYawAmplitude
		);
	}

	FVector GetTargetTipOffset(FSketchbookWord Word, float TimeOffset = 0) const
	{
		const float Time = (DrawDuration + TimeOffset);
		float HorizontalOffset = (Math::PerlinNoise1D(Time * DrawableSentence.GetDrawHorizontalFrequency()) * Sketchbook::Sentence::DrawHorizontalAmplitude);
		float VerticalOffset = (Math::PerlinNoise1D(Time * DrawableSentence.GetDrawVerticalFrequency()) * Word.Bounds.Y);

		return FVector(0, HorizontalOffset, VerticalOffset);
	}
};
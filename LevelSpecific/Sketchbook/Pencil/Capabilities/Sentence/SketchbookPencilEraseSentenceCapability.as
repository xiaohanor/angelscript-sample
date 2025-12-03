struct FSketchbookPencilEraseSentenceActivateParams
{
	USketchbookDrawableSentenceComponent DrawableSentence;
};

struct FSketchbookPencilEraseSentenceDeactivateParams
{
	bool bFinished = false;
};

class USketchbookPencilEraseSentenceCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASketchbookPencil Pencil;
	USketchbookPencilSentenceComponent SentenceComp;

	USketchbookDrawableSentenceComponent DrawableSentence;

	float EraseTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
		SentenceComp = USketchbookPencilSentenceComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSketchbookPencilEraseSentenceActivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return false;

		if(!Pencil.CurrentRequest.IsSet())
			return false;

		FSketchbookPencilRequest Request = Pencil.CurrentRequest.GetValue();

		if(!Request.bErase)
			return false;

		// Wait until the pencil has turned around
		if(Pencil.GetPivotState() != ESketchbookPencilPivotState::Erasing)
			return false;

		auto Drawable = Cast<USketchbookDrawableSentenceComponent>(Request.Drawable);
		if(Drawable == nullptr)
			return false;

		Params.DrawableSentence = Drawable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSketchbookPencilEraseSentenceDeactivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return true;

		if(!Pencil.CurrentRequest.IsSet())
			return true;

		if(Pencil.CurrentRequest.Value.WasInterrupted())
			return true;

		if(ActiveDuration > EraseTime)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookPencilEraseSentenceActivateParams Params)
	{
		DrawableSentence = Params.DrawableSentence;

		Pencil.OnStartErasing(DrawableSentence);

		EraseTime = DrawableSentence.GetSentenceEraseDuration();

		USketchbookPencilEventHandler::Trigger_OnStartErasingSentence(Pencil, FSketchbookPencilEraseSentenceParams(DrawableSentence));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSketchbookPencilEraseSentenceDeactivateParams Params)
	{
		USketchbookPencilEventHandler::Trigger_OnFinishedErasingSentence(Pencil);
		
		if(Params.bFinished)
			Pencil.OnFinishedErasing(DrawableSentence);
		else
			Pencil.OnInterrupted(DrawableSentence);

		DrawableSentence = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float EraseAlpha = Math::Saturate(ActiveDuration / EraseTime);
		EraseAlpha = Math::EaseInOut(0, 1, EraseAlpha, 1.5);

		DrawableSentence.UpdateDrawnFraction(EraseAlpha, true);

		const FVector StartLocation = DrawableSentence.GetStartLocation(DrawableSentence.EraseDirection);
		const FVector EndLocation = DrawableSentence.GetEndLocation(DrawableSentence.EraseDirection);

		const FVector PenTipLocation = Math::Lerp(StartLocation, EndLocation, EraseAlpha);

		Pencil.MoveAccelerateTo(PenTipLocation, 0.05, DeltaTime, this);

		const float VerticalOffset = (Math::Sin(ActiveDuration * DrawableSentence.GetEraseVerticalFrequency()) * DrawableSentence.GetSentenceHeight()) + DrawableSentence.DrawHeightOffset;

		const FVector TipOffset = FVector(0, 0, VerticalOffset);
		Pencil.MoveTipOffsetAccelerateTo(TipOffset, 0.01, DeltaTime, this);

#if !RELEASE
		if(DevTogglesSketchbook::DrawWordBounds.IsEnabled())
			DrawableSentence.DebugDrawBounds();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
#if !RELEASE
		TemporalLog.Value("EraseTime", EraseTime);
#endif
	}
};
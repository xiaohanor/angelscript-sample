
UCLASS(Abstract)
class UMoonGuardianHarpWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	float BarStartAngle;

	UPROPERTY(BlueprintReadOnly)
	float BarEndAngle;

	UPROPERTY(BlueprintReadWrite)
	bool bFadingOut = false;

	UMoonGuardianHarpPlayingComponent HarpComp;

	int LastFinishedMeasure = -1;


	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		HarpComp = UMoonGuardianHarpPlayingComponent::Get(Player);

		//const float DiffToStart = HarpComp.GetStartOfSuccessBarProgress() - CongaLine::StrikePoseAlpha;
		//const float DiffToEnd = HarpComp.GetEndOfSuccessBarProgress() - CongaLine::StrikePoseAlpha;

		//BarStartAngle = 0.5 + (DiffToStart + CongaLine::HiddenExtraMargin);
		//BarEndAngle = 0.5 + (DiffToEnd - CongaLine::HiddenExtraMargin);

		HarpComp.Harp.OnSucceess.AddUFunction(this, n"OnSuccess");
		HarpComp.Harp.OnFail.AddUFunction(this, n"OnFail");

		PlayBeatAnimation(true);
	}

	UFUNCTION()
	private void OnSuccess()
	{
		PlaySuccessAnimation();
	}

	UFUNCTION()
	private void OnFail()
	{
		PlayFailAnimation();
	}

	UFUNCTION(BlueprintPure)
	FName GetActionNameFromNote() const
	{
		if(Player == nullptr)
			return NAME_None;
		
		switch(HarpComp.NoteToPlay)
		{
			case EMoonGuardianHarpNote::Up:
				return ActionNames::RhythmGameUp;

			case EMoonGuardianHarpNote::Down:
			{
				if(Player.IsUsingGamepad())
					return ActionNames::RhythmGameDown;

				return ActionNames::RhythmGameRight;
			}

			case EMoonGuardianHarpNote::Left:
				return ActionNames::RhythmGameLeft;
		}
	}

	UFUNCTION(BlueprintPure)
	float GetBeatProgress() const
	{
		return HarpComp.GetNoteProgress();
	}

	UFUNCTION(BlueprintEvent)
	void PlayBeatAnimation(bool bFirst)
	{
	}

	UFUNCTION(BlueprintEvent)
	void PlayFadeInAnimation()
	{
	}

	UFUNCTION(BlueprintEvent)
	void PlaySuccessAnimation()
	{
	}

	UFUNCTION(BlueprintEvent)
	void PlayFailAnimation()
	{
	}

	UFUNCTION(BlueprintEvent)
	void SetNewNoteToPlay(EMoonGuardianHarpNote NoteToPlay)
	{
	}

	UFUNCTION(BlueprintEvent)
	void FadeOut()
	{
	}
};
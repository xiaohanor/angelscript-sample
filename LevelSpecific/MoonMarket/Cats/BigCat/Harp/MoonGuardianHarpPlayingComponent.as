enum EMoonGuardianHarpNote
{
	Up = 0,
	Down = 1,
	Left = 2
}


class UMoonGuardianHarpPlayingComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UMoonGuardianHarpWidget> HarpWidgetClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	private UMoonGuardianHarpWidget HarpWidget;

	UPROPERTY(BlueprintReadOnly)
	EMoonGuardianHarpNote NoteToPlay;

	AMoonGuardianHarp Harp;

	UPROPERTY(EditAnywhere)
	const float MinNoteDuration = 1.4;

	UPROPERTY(EditAnywhere)
	const float MaxNoteDuration = 1.6;

	UPROPERTY(EditAnywhere)
	const float MaxSpeedMultiplier = 1.5;

	AMoonGuardianCat GuardianCat;
	float MaxDistance;

	float StartedPlayingTime = 0;
	float NoteTimer = 0;
	float CurrentNoteDuration = 1.5;

	bool bIsFirstNote = true;
	bool bNoteSucceeded = false;
	bool bNoteFailed = false;
	bool bLastNoteSucceeded = true;
	bool bIsActive = false;
	bool bShouldExit = false;

	float HarpSuccessTime = 0;

	float ExitDuration = 0;

	//How many notes you need to play successfully in a row to put the cat back to sleep
	const int NotesToSucceedInARow = 3;

	AHazePlayerCharacter OwningPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		GuardianCat = TListedActors<AMoonGuardianCat>().Single;
	}

	void StartPlaying(AMoonGuardianHarp HarpToPlay)
	{
		StartedPlayingTime = Time::GameTimeSeconds;
		Harp = HarpToPlay;
		MaxDistance = GuardianCat.ActorLocation.Distance(Harp.ActorLocation);
		bIsFirstNote = true;
		bIsActive = true;
		NoteTimer = 0;
		bShouldExit = false;
		HarpWidget = OwningPlayer.AddWidget(HarpWidgetClass);
	}

	void StopPlaying()
	{
		Harp = nullptr;
		bIsActive = false;

		if(!bShouldExit)
			HarpWidget.FadeOut();
	}

	void SetExitDuration(float InExitDuration)
	{
		ExitDuration = InExitDuration;
		HarpWidget.FadeOut();
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsActive)
			return;

		if(bShouldExit)
			return;

		float Distance = GuardianCat.ActorLocation.Distance(OwningPlayer.OtherPlayer.ActorLocation);
		const float Alpha = 1 - Math::Saturate(Distance / MaxDistance);
		const float SpeedMultiplier = Math::Lerp(1, MaxSpeedMultiplier, Alpha);
		NoteTimer += DeltaSeconds * SpeedMultiplier;

		if(HasControl())
		{
			if(NoteTimer >= CurrentNoteDuration)
			{
				NewNote();
			}
		}

		Owner.SetActorRotation(Harp.InteractComp.WorldRotation);
		//Owner.SetActorLocation(Math::VInterpConstantTo(Owner.ActorLocation, Harp.InteractComp.WorldLocation, DeltaSeconds, 100));
	}

	void PlayNote(EMoonGuardianHarpNote Note)
	{
		if(bNoteSucceeded || bNoteFailed || bIsFirstNote)
			return;

		if(Note != NoteToPlay)
		{
			NetFail();
		}
		else
		{
			if(WithinGraceWindow())
			{
				NetSuccess();
			}
			else
			{
				NetFail();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetFail()
	{
		bNoteFailed = true;
		HarpSuccessTime = 0;
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if(HasControl())
		{
			Player.PlayCameraShake(CameraShakeClass, this);
			Player.PlayForceFeedback(ForceFeedback, false, false, this);
		}

		TListedActors<AMoonGuardianCat>().Single.WakeUp(EMoonGuardianCatWakeUpReason::WrongNote, Player);
		Harp.OnFail.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetSuccess()
	{
		bNoteSucceeded = true;
		Harp.OnSucceess.Broadcast();
		HarpSuccessTime = Time::GameTimeSeconds;
		TListedActors<AMoonGuardianCat>().Single.IncreaseSleepiness(OwningPlayer);
	}

	bool WithinGraceWindow() const
	{
		//return true;
		return NoteTimer > (CurrentNoteDuration / 2);
	}

	void NewNote()
	{
		if(bIsFirstNote)
		{
			bIsFirstNote = false;
		}
		else
		{
			if(!bNoteSucceeded && !bNoteFailed)
			{
				NetFail();
			}
		}

		bLastNoteSucceeded = bNoteSucceeded;

		const EMoonGuardianHarpNote NewNote = GenerateNewNote();
		const float NewDuration = Math::RandRange(MinNoteDuration, MaxNoteDuration);
		NetSetNextNote(NewNote, NewDuration);
	}

	UFUNCTION(NetFunction)
	void NetSetNextNote(EMoonGuardianHarpNote Note, float Duration)
	{
		bNoteFailed = false;
		bNoteSucceeded = false;
		NoteTimer = 0;
		CurrentNoteDuration = Duration;
		NoteToPlay = Note;
		HarpWidget.SetNewNoteToPlay(NoteToPlay);
		HarpWidget.PlayFadeInAnimation();
	}

	float GetNoteProgress() const
	{
		return Math::Clamp(NoteTimer, 0, CurrentNoteDuration) / CurrentNoteDuration;
	}

	EMoonGuardianHarpNote GenerateNewNote() const
	{
		EMoonGuardianHarpNote NewNote = EMoonGuardianHarpNote(Math::RandRange(0, 2));

		// Make sure we don't play the same pose twice in a row
		while(NoteToPlay == NewNote)
		{
			NewNote = EMoonGuardianHarpNote(Math::RandRange(0, 2));
		}

		return NewNote;
	}
};
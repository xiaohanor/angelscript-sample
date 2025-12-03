
// 😎
namespace VoxOldPlayerColor
{
	const FLinearColor Mio = FLinearColor(0.86, 0.21, 0.22);
	const FLinearColor Zoe = FLinearColor(0.45, 0.86, 0.21);
}

enum ERuntimeVoiceLineState
{
	Stopped,
	PreDelay,
	Playing,
	PostDelay,
	TailingOut
}

const float SmallOffsetTime = 0.01;
const float PauseFadeoutMS = 100.0;
const float PauseSeekMS = -150.0;
const float PauseEndCutoffTime = 0.4;

class UVoxVoiceLine
{
	UHazeVoxAsset VoxAsset;
	const int VoiceLineIndex;
	ERuntimeVoiceLineState State = ERuntimeVoiceLineState::Stopped;

	// Pause is a bool and not part of the enum so we can resume right from where we were
	bool bPaused = false;

	AHazeActor Actor;
	UHazeAudioEmitter AudioEmitter;

	private float Playtime;

	private bool bCutoffEarly = false;
	private float PlaytimeLimit = 0.0;

	private float CalculatedPreDelay = 0.0;
	private float CalculatedPostDelay = 0.0;

	private float PreDelayTimer = 0.0;
	private float PostDelayTimer = 0.0;

	private bool bTriggerNext = false;

	private int PlayingID = 0;

	private float FaceAnimationPauseTime = 0.0;

	private UVoxSubtitles Subtitles;

	UVoxVoiceLine(UHazeVoxAsset InVoxAsset, int InVoiceLineIndex, AHazeActor InActor)
	{
		Actor = InActor;
		VoxAsset = InVoxAsset;
		VoiceLineIndex = InVoiceLineIndex;

		Subtitles = UVoxSubtitles(VoxAsset.Lane);
	}

	void Init()
	{
		FHazeAudioEmitterAttachmentParams EmitterParams;
		EmitterParams.Owner = Actor;
		EmitterParams.Instigator = this;
		EmitterParams.Attachment = USkeletalMeshComponent::Get(Actor);
		EmitterParams.BoneName = VoxAsset.VoiceLines[VoiceLineIndex].CharacterTemplate.AttachmentBoneName;
		EmitterParams.EmitterName = Audio::Names::DefaultVoiceLineEmitterName;
		// Ensures unique VO voice object for the actor
		AudioEmitter = Audio::GetPooledEmitter(EmitterParams);
	}

	void Tick(float DeltaTime)
	{
		if (bPaused)
			return;

		switch (State)
		{
			case ERuntimeVoiceLineState::Stopped:
			{
				return;
			}
			case ERuntimeVoiceLineState::PreDelay:
			{
				PreDelayTimer -= DeltaTime;
				if (PreDelayTimer <= 0.0)
				{
					// Transition to Playing
					StartPlaying();
				}
				break;
			}
			case ERuntimeVoiceLineState::Playing:
			{
				UpdatePlaying(DeltaTime);
				break;
			}
			case ERuntimeVoiceLineState::PostDelay:
			{
				PostDelayTimer -= DeltaTime;
				if (PostDelayTimer <= 0.0)
				{
					bTriggerNext = true;
					Stop();
				}
				break;
			}
			case ERuntimeVoiceLineState::TailingOut:
			{
				UpdateTailingOut(DeltaTime);
				break;
			}
		}
	}

	void Stop()
	{
		if (PlayingID != 0 && AudioEmitter != nullptr)
		{
			AudioEmitter.StopPlayingEvent(PlayingID, VoxAsset.Fadeout);
			Audio::ReturnPooledEmitter(this, AudioEmitter);
			AudioEmitter = nullptr;
		}

		UAnimSequence FaceAnimation = UHazeVoxAsset::GetVoiceLineFaceAnimation(VoxAsset.VoiceLines[VoiceLineIndex]);
		if (FaceAnimation != nullptr && IsValid(Actor))
		{
			Actor.StopFaceAnimation(FaceAnimation);
		}

		StopRtpcs();

		PlayingID = 0;
		Subtitles.ClearSubtitles();
		StopRtpcs();
		State = ERuntimeVoiceLineState::Stopped;
	}

	void Play(bool bFromQueue)
	{
		if (State == ERuntimeVoiceLineState::Playing)
			Stop();

		// Reset
		Playtime = 0.0;
		PreDelayTimer = 0.0;
		PostDelayTimer = 0.0;

		// If dialogue, only apply Asset PreDelay on first line
		if (VoxAsset.Type == EHazeVoxAssetType::Dialogue && VoiceLineIndex != 0)
		{
			CalculatedPreDelay = VoxAsset.VoiceLines[VoiceLineIndex].PreDelay;
		}
		else
		{
			CalculatedPreDelay = VoxAsset.PreDelay + VoxAsset.VoiceLines[VoiceLineIndex].PreDelay;
		}

		if (bFromQueue)
		{
			CalculatedPreDelay += VoxAsset.QueuePreDelay;
		}

		if (CalculatedPreDelay > SmallOffsetTime)
		{
			PreDelayTimer = CalculatedPreDelay;
			State = ERuntimeVoiceLineState::PreDelay;
			return;
		}

		StartPlaying();
	}

	void Pause()
	{
		if (bPaused || State == ERuntimeVoiceLineState::Stopped)
			return;

		bPaused = true;

		// Remove subtitles during pause
		Subtitles.ClearSubtitles();

		if (PlayingID != 0 && AudioEmitter != nullptr)
		{
			float Diff = PlaytimeLimit - Playtime;
			if (Diff > PauseEndCutoffTime)
			{
				AudioEmitter.ExecuteActionOnPlayingID(uint(PlayingID), AkActionOnEventType::Pause, PauseFadeoutMS);
			}
			else
			{
				Stop();
				bTriggerNext = true;
			}
		}

		UAnimSequence FaceAnimation = UHazeVoxAsset::GetVoiceLineFaceAnimation(VoxAsset.VoiceLines[VoiceLineIndex]);
		if (FaceAnimation != nullptr)
		{
			FaceAnimationPauseTime = Actor.GetFaceAnimationPosition(FaceAnimation);
			Actor.StopFaceAnimation(FaceAnimation);
		}
	}

	void ResumeWithSeek()
	{
		if (!bPaused || State == ERuntimeVoiceLineState::Stopped)
			return;

		bPaused = false;

		if (PlayingID != 0 && AudioEmitter != nullptr)
		{
			AudioEmitter.SeekPlayingEvent(PlayingID, PauseSeekMS);
			AudioEmitter.ExecuteActionOnPlayingID(uint(PlayingID), AkActionOnEventType::Resume, PauseFadeoutMS);
		}

		UAnimSequence FaceAnimation = UHazeVoxAsset::GetVoiceLineFaceAnimation(VoxAsset.VoiceLines[VoiceLineIndex]);
		if (FaceAnimation != nullptr)
		{
			const float StartTime = Math::Max(FaceAnimationPauseTime - PauseSeekMS, 0.0);

			FHazePlayFaceAnimationParams FaceParams;
			FaceParams.Animation = FaceAnimation;
			FaceParams.StartTime = StartTime;

			Actor.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);
		}

		// Restart subtitles
		DisplaySubtitles(VoxAsset.VoiceLines[VoiceLineIndex]);
	}

	void HardPause()
	{
		// Don't double pause
		if (bPaused || State == ERuntimeVoiceLineState::Stopped)
			return;

		if (PlayingID != 0 && AudioEmitter != nullptr)
		{
			AudioEmitter.ExecuteActionOnPlayingID(uint(PlayingID), AkActionOnEventType::Pause, 0.0f);
		}
	}

	void HardResume()
	{
		// Don't double pause
		if (bPaused || State == ERuntimeVoiceLineState::Stopped)
			return;

		if (PlayingID != 0 && AudioEmitter != nullptr)
		{
			AudioEmitter.ExecuteActionOnPlayingID(uint(PlayingID), AkActionOnEventType::Resume, 0.0f);
		}
	}

	bool IsPlaying()
	{
		switch (State)
		{
			case ERuntimeVoiceLineState::PreDelay:
			case ERuntimeVoiceLineState::Playing:
			case ERuntimeVoiceLineState::PostDelay:
				return true;
			case ERuntimeVoiceLineState::Stopped:
			case ERuntimeVoiceLineState::TailingOut:
				return false;
		}
	}

	bool ConsumeTriggerNext()
	{
		bool bTemp = bTriggerNext;
		bTriggerNext = false;
		return bTemp;
	}

	private float CalculateOverlapOffset() const
	{
		float AssetOffset = 0.0;
		if (VoxAsset.Type == EHazeVoxAssetType::Dialogue)
		{
			// If dialogue, only apply Asset PostDelay/OverlapOffset on last line
			if (VoiceLineIndex == VoxAsset.VoiceLines.Num() - 1)
			{
				AssetOffset = VoxAsset.PostDelay - VoxAsset.OverlapOffset;
			}
		}
		else
		{
			AssetOffset = VoxAsset.PostDelay - VoxAsset.OverlapOffset;
		}

		float VoiceLineOffset = VoxAsset.VoiceLines[VoiceLineIndex].PostDelay - VoxAsset.VoiceLines[VoiceLineIndex].OverlapOffset;
		UHazeAudioVOEvent AudioVOEvent = Cast<UHazeAudioVOEvent>(VoxAsset.VoiceLines[VoiceLineIndex].AudioEvent);
		if (AudioVOEvent != nullptr)
		{
			VoiceLineOffset -= AudioVOEvent.ReverbTailDuration;
		}

		return AssetOffset + VoiceLineOffset;
	}

	private void StartPlaying()
	{
		FHazeVoxVoiceLine VoiceLine = VoxAsset.VoiceLines[VoiceLineIndex];

		float CalculatedOffset = CalculateOverlapOffset();
		int32 CallbackFlags = VoiceLine.CallbackFlags;

		// Ignore very small offsets
		if (CalculatedOffset < -SmallOffsetTime)
		{
			bCutoffEarly = true;
			PlaytimeLimit = VoiceLine.AudioEvent.MaximumDuration + CalculatedOffset;
			// EAkCallbackType values are verified in static_assert in c++ backend as 1 << EAkCallbackType::*.
			CallbackFlags |= 1 << uint(EAkCallbackType::EnableGetSourcePlayPosition);
		}
		else if (CalculatedOffset > SmallOffsetTime)
		{
			bCutoffEarly = false;
			CalculatedPostDelay = CalculatedOffset;
		}

		// Always enable source play positions for pausable assets
		if (VoxAsset.bResumeAfterPause)
		{
			CallbackFlags |= 1 << uint(EAkCallbackType::EnableGetSourcePlayPosition);
			if (PlaytimeLimit == 0.0)
			{
				PlaytimeLimit = VoiceLine.AudioEvent.MaximumDuration;
			}
		}

		const FHazeAudioPostEventInstance& EventInstance = AudioEmitter.PostEvent(VoiceLine.AudioEvent, PostType = EHazeAudioEventPostType::VO, CallbackFlags = CallbackFlags);

		PlayingID = EventInstance.PlayingID;

		UAnimSequence FaceAnimation = UHazeVoxAsset::GetVoiceLineFaceAnimation(VoiceLine);
		if (FaceAnimation != nullptr)
		{
			FHazePlayFaceAnimationParams FaceParams;
			FaceParams.Animation = FaceAnimation;

			if (VoiceLine.bHaxForceFaceAnimPriority)
			{
				FaceParams.Priority = EHazeAnimPriority::AnimPrio_Cutscene;
			}

			Actor.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);
		}

		StartRtpcs();
		DisplaySubtitles(VoiceLine);

		Playtime = 0.0;
		State = ERuntimeVoiceLineState::Playing;
	}

	private void DisplaySubtitles(FHazeVoxVoiceLine VoiceLine)
	{
		if (VoxAsset.bHaxForceDisableSubtitles)
			return;

		if (VoiceLine.SubtitleAsset != nullptr)
		{
			Subtitles.DisplayAssetSubtitle(VoiceLine.SubtitleAsset, Actor);
		}
		else if (!VoiceLine.SubtitleSourceText.IsEmptyOrWhitespace())
		{
			TOptional<FString> SubtitleTempText;
#if TEST
			if (VoiceLine.NarrativeStatus == EHazeVoxNarrativeStatus::Temp)
			{
				SubtitleTempText = "T";
			}
			else if (VoiceLine.NarrativeStatus == EHazeVoxNarrativeStatus::Cut)
			{
				SubtitleTempText = "C";
			}
#endif
			Subtitles.DisplayTextSubtitle(VoiceLine.SubtitleSourceText, Actor, VoiceLine.AudioEvent.MaximumDuration, SubtitleTempText);
		}
	}

	private bool UpdatePlayingEvent()
	{
		const auto& EventInstance = AudioEmitter.GetEventInstance(PlayingID);
		// PlayingID of zero is an invalid ID
		if (EventInstance.PlayingID == 0)
			return false;

		// If we need to check for updated PlaytimeLimit
		// PlayRate can never be zero when updated from callbacks
		const bool bUpdatePlayDuration = bCutoffEarly || VoxAsset.bResumeAfterPause;
		if (bUpdatePlayDuration && EventInstance.PlayRate != 0)
		{
			float NewDuration = EventInstance.PlayDuration + CalculateOverlapOffset();
			if (!Math::IsNearlyEqual(NewDuration, PlaytimeLimit))
			{
				PlaytimeLimit = NewDuration;
			}
		}

		return true;
	}

	private void UpdatePlaying(float DeltaTime)
	{
		Playtime += DeltaTime;
		bool bPlaying = UpdatePlayingEvent();
		Subtitles.Tick(Playtime);

		if (bCutoffEarly)
		{
			if (Playtime > PlaytimeLimit)
			{
				bTriggerNext = true;
				Subtitles.ClearSubtitles();
				StopRtpcs();
				State = ERuntimeVoiceLineState::TailingOut;
				return;
			}
		}

		if (!bPlaying)
		{
			Subtitles.ClearSubtitles();
			StopRtpcs();
			if (CalculatedPostDelay > SmallOffsetTime)
			{
				PostDelayTimer = CalculatedPostDelay;
				State = ERuntimeVoiceLineState::PostDelay;
			}
			else
			{
				bTriggerNext = true;
				State = ERuntimeVoiceLineState::Stopped;
			}
		}
	}

	private void UpdateTailingOut(float DeltaTime)
	{
		Playtime += DeltaTime;
		bool bPlaying = UpdatePlayingEvent();

		if (!bPlaying)
		{
			State = ERuntimeVoiceLineState::Stopped;
		}
	}

	private void StartRtpcs()
	{
		if (VoxAsset.bMuteEfforts)
		{
			auto ActorAsPlayer = Cast<AHazePlayerCharacter>(Actor);
			if (ActorAsPlayer != nullptr)
			{
				if (ActorAsPlayer.IsMio())
				{
					UHazeVoxRunner::Get().StartVoxRtpc(HazeVoxRtpcs::MuteEffortsZoe, this);
				}
				else
				{
					UHazeVoxRunner::Get().StartVoxRtpc(HazeVoxRtpcs::MuteEffortsMio, this);
				}
			}
		}
	}

	private void StopRtpcs()
	{
		if (VoxAsset.bMuteEfforts)
		{
			UHazeVoxRunner::Get().StopVoxRtpc(HazeVoxRtpcs::MuteEffortsZoe, this);
			UHazeVoxRunner::Get().StopVoxRtpc(HazeVoxRtpcs::MuteEffortsMio, this);
		}
	}

#if TEST
	FLinearColor DebugStateColor() const
	{
		switch (State)
		{
			case ERuntimeVoiceLineState::Stopped:
				return FLinearColor::White;
			case ERuntimeVoiceLineState::PreDelay:
				return FLinearColor::Teal;
			case ERuntimeVoiceLineState::Playing:
				return FLinearColor::Green;
			case ERuntimeVoiceLineState::PostDelay:
				return FLinearColor::Teal;
			case ERuntimeVoiceLineState::TailingOut:
				return FLinearColor::Teal;
		}
	}

	FLinearColor DebugCharacterColor(const UHazeVoxCharacterTemplate CharacterTemplate)
	{
		if (CharacterTemplate.bIsPlayer)
		{
			return CharacterTemplate.Player == EHazePlayer::Mio ? VoxOldPlayerColor::Mio : VoxOldPlayerColor::Zoe;
		}

		uint NameHash = CharacterTemplate.Name.ToString().Hash;
		return FLinearColor::MakeFromHSV8(uint8(NameHash % 255), 128, 255);
	}

	FVoxDebugVoiceLine BuildDebugInfo()
	{
		if (!IsValid(VoxAsset))
			return FVoxDebugVoiceLine();

		FVoxDebugVoiceLine DebugVL;
		DebugVL.AssetName = VoxAsset.VoiceLines[VoiceLineIndex].AudioEvent.Name.ToString();
		DebugVL.Index = VoiceLineIndex;
		DebugVL.State = f"{State}";
		DebugVL.Color = DebugStateColor();
		DebugVL.ActorName = Actor.Name.ToString();

		const UHazeVoxCharacterTemplate CharacterTemplate = VoxAsset.VoiceLines[VoiceLineIndex].CharacterTemplate;
		DebugVL.CharacterName = CharacterTemplate.CharacterName;
		DebugVL.CharacterColor = DebugCharacterColor(CharacterTemplate);

		return DebugVL;
	}

	void DebugTemporalLog(FTemporalLog& TemporalLog, FString ParentPrefix)
	{
		FString Prefix = f"{ParentPrefix};VoiceLine_{VoiceLineIndex}";
		TemporalLog.CustomStatus(f"{Prefix};State", f"{State}", DebugStateColor());
		TemporalLog.Value(f"{Prefix};bPaused", bPaused);
		TemporalLog.Value(f"{Prefix};PreDelayTimer", PreDelayTimer);
		TemporalLog.Value(f"{Prefix};PostDelayTimer", PostDelayTimer);
		TemporalLog.Value(f"{Prefix};Playtime", Playtime);
		TemporalLog.Value(f"{Prefix};PlaytimeLimit", PlaytimeLimit);
		TemporalLog.Value(f"{Prefix};CalculatedPreDelay", CalculatedPreDelay);
		TemporalLog.Value(f"{Prefix};CalculatedPostDelay", CalculatedPostDelay);
		TemporalLog.Value(f"{Prefix};Asset", VoxAsset.VoiceLines[VoiceLineIndex].AudioEvent.Name.ToString());
		TemporalLog.Value(f"{Prefix};PlayingID", PlayingID);
		TemporalLog.Value(f"{Prefix};Actor", Actor);
		TemporalLog.Value(f"{Prefix};PresetType", VoxAsset.PresetType);
		TemporalLog.Value(f"{Prefix};Preset", VoxAsset.Preset);
	}
#endif
}
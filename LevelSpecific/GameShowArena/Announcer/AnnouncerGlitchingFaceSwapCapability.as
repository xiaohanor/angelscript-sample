

struct FGameShowArenaAnnouncerGlitchData
{
	FGameShowArenaAnnouncerGlitchData(FIntVector2 Range, int OddsFor, int SelectionOffset, float InMinTimeFace, float InMaxTimeFace)
	{
		FaceRange = Range;
		SelectionRange = FIntVector2(SelectionOffset, OddsFor - 1);
		MinTimeToDisplayFace = InMinTimeFace;
		MaxTimeToDisplayFace = InMaxTimeFace;
	}
	FIntVector2 FaceRange;
	FIntVector2 SelectionRange;
	float MinTimeToDisplayFace;
	float MaxTimeToDisplayFace;
}

class UGameShowArenaAnnouncerGlitchingFaceSwapCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Visibility);
	default TickGroup = EHazeTickGroup::Gameplay;
	AGameShowArenaAnnouncer Announcer;
	UGameShowArenaAnnouncerFaceComponent AnnouncerFaceComp;

	TPerPlayer<UGameShowArenaBombTossPlayerComponent> PlayerComps;

	AGameShowArenaBomb ActiveBomb;
	AHazePlayerCharacter PlayerHoldingBomb;
	float TimeWhenNextFaceChange = 0;

	float TimeWhenNextColorUpdate = 0;
	float MaxGlitchStrength = 0.5;

	float TimeWhenNextVOGlitch = 0;

	const float MinDurationGlitchVO = 0.5;
	const float MaxDurationGlitchVO = 0.7;

	const float MinDurationBetweenGlitchVO = 1.2;
	const float MaxDurationBetweenGlitchVO = 2.0;

	UHazeAudioComponent AudioComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(Owner);
		AnnouncerFaceComp = UGameShowArenaAnnouncerFaceComponent::Get(Announcer);
		AnnouncerFaceComp.InitializeGlitchData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Announcer.State.Get() != EGameShowArenaAnnouncerState::PermanentGlitching)
		{
			if (!Announcer.bIsSEQGlitching && Announcer.FaceState.Get() != EGameShowArenaAnnouncerFaceState::Glitching)
			{
				return false;
			}
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Announcer.State.Get() != EGameShowArenaAnnouncerState::PermanentGlitching)
		{
			if (!Announcer.bIsSEQGlitching && Announcer.FaceState.Get() != EGameShowArenaAnnouncerFaceState::Glitching)
			{
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// AudioComp = Uhazeaudioem::Get(Announcer);
		TimeWhenNextFaceChange = 0;
		TimeWhenNextColorUpdate = 0;
		TimeWhenNextVOGlitch = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnnouncerFaceComp.UpdateFaceMaterialColor(AnnouncerFaceComp.DefaultFaceColor);
		AnnouncerFaceComp.UpdateFaceXY();
		AnnouncerFaceComp.InstigatedFace.Clear(this);
		AnnouncerFaceComp.InstigatedGlitch.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Time = Time::PredictedGlobalCrumbTrailTime;

		if (Time > TimeWhenNextFaceChange)
		{
			int CurrentFace = AnnouncerFaceComp.GetFaceMaterialParam();
			FGameShowArenaAnnouncerGlitchData Data = AnnouncerFaceComp.GetRandomGlitchData();
			int NewFace = AnnouncerFaceComp.GetRandomNewFaceFromRange(Data.FaceRange, CurrentFace);

			AnnouncerFaceComp.ApplyFace(NewFace, this, EInstigatePriority::Normal);

			TimeWhenNextFaceChange = Time + Announcer.RandStream.RandRange(Data.MinTimeToDisplayFace, Data.MaxTimeToDisplayFace);
		}

		if (Time > TimeWhenNextColorUpdate)
		{
			FVector RandomVector = Announcer.RandStream.GetUnitVector();
			float R = RandomVector.X;
			float G = RandomVector.Y;
			float B = RandomVector.Z;
			FLinearColor Color = FLinearColor(R, G, B) * 15;
			AnnouncerFaceComp.UpdateFaceMaterialColor(Color);
			TimeWhenNextColorUpdate = Time + Announcer.RandStream.RandRange(0.2, 0.3);
		}
		float Noise = Math::PerlinNoise1D(Time);
		float PositiveNose = (1 + Noise) * 0.5;
		float GlitchAmount = Math::SmoothStep(0.3, 0.8, PositiveNose) * MaxGlitchStrength;
		AnnouncerFaceComp.ApplyGlitch(GlitchAmount, this, EInstigatePriority::Low);
		AnnouncerFaceComp.UpdateFaceXY(6.0 + Math::Clamp(Noise * 0.4, -0.2, 0.4), 6.0 + Math::Clamp(Noise * 0.1, 0, 0.1));
	}
};
UCLASS()
class UGameShowArenaAnnouncerFaceComponent : UActorComponent
{
	bool bWasControlledBySequence;
	AGameShowArenaAnnouncer Announcer;

	TArray<FGameShowArenaAnnouncerGlitchData> GlitchData;

	UPROPERTY(EditDefaultsOnly)
	FIntVector2 HappyFacesRange = FIntVector2(0, 2);

	UPROPERTY(EditDefaultsOnly)
	FIntVector2 AngryFacesRange = FIntVector2(6, 8);

	UPROPERTY(EditDefaultsOnly)
	FIntVector2 SadFacesRange = FIntVector2(12, 14);

	UPROPERTY(EditDefaultsOnly)
	FIntVector2 SymbolFacesRange = FIntVector2(30, 32);

	UPROPERTY(EditDefaultsOnly)
	FIntVector2 GlitchFacesRange = FIntVector2(29, 35);

	TInstigated<int> InstigatedFace;
	TInstigated<int> InstigatedEyes;
	default InstigatedEyes.DefaultValue = -1;
	TInstigated<int> InstigatedMouth;
	default InstigatedMouth.DefaultValue = -1;
	TInstigated<float> InstigatedGlitch;

	TArray<FGameShowArenaAnnouncerFaceOverrideData> FaceOverrideQueue;
	TArray<FGameShowArenaAnnouncerFaceStateOverrideData> FaceStateOverrideQueue;

	UMaterialInstanceDynamic DynamicMaterial;
	FLinearColor DefaultFaceColor;

	int PreviousEyes;
	int PreviousMouth;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(Owner);
		InitializeGlitchData();
		DynamicMaterial = Announcer.FaceMeshComp.CreateDynamicMaterialInstance(0);
		if (DynamicMaterial != nullptr)
			DefaultFaceColor = DynamicMaterial.GetVectorParameterValue(n"EmissiveTint");
	}
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(Owner);
		FaceOverrideQueue.Reserve(8);
		FaceStateOverrideQueue.Reserve(8);
		DynamicMaterial = Announcer.FaceMeshComp.CreateDynamicMaterialInstance(0);
		DefaultFaceColor = DynamicMaterial.GetVectorParameterValue(n"EmissiveTint");
	}

	void InitializeGlitchData()
	{
		GlitchData.Empty();
		AddGlitchData(HappyFacesRange, 3, 0.1, 0.5);
		AddGlitchData(AngryFacesRange, 12, 0.4, 1.4);
		AddGlitchData(SadFacesRange, 2, 0.2, 1.0);
		AddGlitchData(GlitchFacesRange, 8, 0.2, 0.6);
	}

	FGameShowArenaAnnouncerGlitchData GetRandomGlitchData()
	{
		int OutCome = Announcer.RandStream.RandRange(0, GlitchData.Last().SelectionRange.Y);
		for (auto Data : GlitchData)
		{
			if (OutCome >= Data.SelectionRange.X && OutCome <= Data.SelectionRange.Y)
				return Data;
		}
		return GlitchData[0];
	}

	void AddGlitchData(FIntVector2 FaceRange, int OddsFor, float MinTimeToDisplayFace, float MaxTimeToDisplayFace)
	{
		if (GlitchData.Num() > 0)
		{
			GlitchData.Add(FGameShowArenaAnnouncerGlitchData(FaceRange, OddsFor, GlitchData.Last().SelectionRange.Y, MinTimeToDisplayFace, MaxTimeToDisplayFace));
		}
		else
		{
			GlitchData.Add(FGameShowArenaAnnouncerGlitchData(FaceRange, OddsFor, 0, MinTimeToDisplayFace, MaxTimeToDisplayFace));
		}
	}

	void UpdateFace()
	{
		if (Announcer == nullptr)
			Announcer = Cast<AGameShowArenaAnnouncer>(Owner);

		if (Announcer.bIsPreviewedBySequencer)
			return;

		int FaceIndex = InstigatedFace.Get();
		int MouthIndex = InstigatedMouth.Get();
		int EyesIndex = InstigatedEyes.Get();
		float GlitchAmount = InstigatedGlitch.Get();

		if (!Announcer.bIsControlledByCutscene)
		{
			if (bWasControlledBySequence)
			{
				Announcer.SEQFaceMouthIndex = -1;
				Announcer.SEQFaceEyesIndex = -1;
			}

			if (MouthIndex == -1)
			{
				MouthIndex = InstigatedMouth.Get();
			}

			if (EyesIndex == -1)
			{
				EyesIndex = InstigatedEyes.Get();
			}

			Announcer.PreviousFace = FaceIndex;
		}
		else
		{
			if (!Announcer.bIsSEQGlitching)
			{
				FaceIndex = Announcer.SEQFaceIndex;
				EyesIndex = Announcer.SEQFaceEyesIndex;
				MouthIndex = Announcer.SEQFaceMouthIndex;
			}
			
			GlitchAmount = Announcer.GlitchEffectAlpha;
		}

		if (DynamicMaterial == nullptr)
		{
			DynamicMaterial = Announcer.FaceMeshComp.CreateDynamicMaterialInstance(0);
		}

		bWasControlledBySequence = Announcer.bIsControlledByCutscene;
		UpdateFaceMaterialParams(FaceIndex, EyesIndex, MouthIndex);
		UpdateGlitchStrength(GlitchAmount);
	}

	void UpdateFaceMaterialParams(int FaceIndex, int EyesIndex, int MouthIndex)
	{
		int Face = FaceIndex;
		if (EyesIndex > -1 || MouthIndex > -1)
		{
			Face = -1;
		}
		DynamicMaterial.SetScalarParameterValue(n"CurrentFace", float(Face));
		DynamicMaterial.SetScalarParameterValue(n"CurrentFaceEyes", float(EyesIndex));
		DynamicMaterial.SetScalarParameterValue(n"CurrentFaceMouth", float(MouthIndex));
	}
	
	void UpdateGlitchStrength(float GlitchAmount)
	{
		DynamicMaterial.SetScalarParameterValue(n"Glitch", GlitchAmount);
	}

	UFUNCTION()
	void ApplyFace(int NewFace, FInstigator Instigator, EInstigatePriority Priority)
	{
		InstigatedFace.Apply(NewFace, Instigator, Priority);
	}

	void ApplyMouth(int NewMouth, FInstigator Instigator, EInstigatePriority Priority)
	{
		InstigatedMouth.Apply(NewMouth, Instigator, Priority);
	}

	void ClearMouth(FInstigator Instigator)
	{
		InstigatedMouth.Clear(Instigator);
	}

	void ApplyEyes(int NewEyes, FInstigator Instigator, EInstigatePriority Priority)
	{
		InstigatedEyes.Apply(NewEyes, Instigator, Priority);
	}
	void ClearEyes(FInstigator Instigator)
	{
		InstigatedEyes.Clear(Instigator);
	}

	void ApplyGlitch(float GlitchAmount, FInstigator Instigator, EInstigatePriority Priority)
	{
		InstigatedGlitch.Apply(GlitchAmount, Instigator, Priority);
	}

	void ClearGlitch(FInstigator Instigator)
	{
		InstigatedGlitch.Clear(Instigator);
	}

	UFUNCTION()
	void UpdateFaceMaterialColor(FLinearColor Color)
	{
		DynamicMaterial.SetVectorParameterValue(n"EmissiveTint", Color);
	}

	UFUNCTION()
	void UpdateFaceXY(float X = 6.0, float Y = 6.0)
	{
		DynamicMaterial.SetScalarParameterValue(n"FacesX", X);
		DynamicMaterial.SetScalarParameterValue(n"FacesY", Y);
	}

	int GetFaceMaterialParam()
	{
		return int(DynamicMaterial.GetScalarParameterValue(n"CurrentFace"));
	}

	UFUNCTION()
	void AddFaceStateOverrideForDuration(EGameShowArenaAnnouncerFaceState NewState, float Duration)
	{
		FaceStateOverrideQueue.Add(FGameShowArenaAnnouncerFaceStateOverrideData(Duration, NewState, this));
	}

	UFUNCTION()
	void ApplyFaceStateOverride(EGameShowArenaAnnouncerFaceState NewState, FInstigator Instigator)
	{
		FaceStateOverrideQueue.Insert(FGameShowArenaAnnouncerFaceStateOverrideData(MAX_flt, NewState, Instigator));
	}

	UFUNCTION()
	void ClearFaceStateOverride(FInstigator Instigator)
	{
		for (int i = 0; i < FaceStateOverrideQueue.Num(); i++)
		{
			if (FaceStateOverrideQueue[i].Instigator == Instigator)
			{
				FaceStateOverrideQueue.RemoveAt(i);
			}
		}
	}

	UFUNCTION()
	void AddFaceOverrideForDuration(int FaceNr, float Duration)
	{
		FaceOverrideQueue.Add(FGameShowArenaAnnouncerFaceOverrideData(Duration, FaceNr, this));
	}

	UFUNCTION()
	void ApplyFaceOverride(int FaceNr, FInstigator Instigator)
	{
		FaceOverrideQueue.Insert(FGameShowArenaAnnouncerFaceOverrideData(MAX_flt, FaceNr, Instigator));
	}

	UFUNCTION()
	void ClearFaceOverride(FInstigator Instigator)
	{
		for (int i = 0; i < FaceOverrideQueue.Num(); i++)
		{
			if (FaceOverrideQueue[i].Instigator == Instigator)
			{
				FaceOverrideQueue.RemoveAt(i);
			}
		}
	}

	bool HasFaceFromRange(FIntVector2 Range, int CurrentFace)
	{
		return Math::IsWithinInclusive(CurrentFace, Range.X, Range.Y);
	}

	int GetRandomNewFaceFromRange(FIntVector2 Range, int CurrentFace)
	{
		devCheck(Range.Y - Range.X > 0, "Unable to get random value from range with only one value!");
		TArray<int> PossibleFaces;
		for (int i = Range.X; i <= Range.Y; i++)
		{
			if (i == CurrentFace)
				continue;

			PossibleFaces.Add(i);
		}

		int RandIndex = Announcer.RandStream.RandRange(0, PossibleFaces.Num() - 1);
		return PossibleFaces[RandIndex];
	}

#if EDITOR
	// Some time variables used for previewing glitching behavior
	float GlitchPreviewTimeWhenNextFaceChange;
	float GlitchPreviewTimeWhenNextColorChange;
	void InitializeSEQPreview()
	{
		GlitchPreviewTimeWhenNextColorChange = 0;
		GlitchPreviewTimeWhenNextFaceChange = 0;
	}
	void PreviewGlitching(float Time)
	{
		if (Time > GlitchPreviewTimeWhenNextFaceChange)
		{
			int CurrentFace = GetFaceMaterialParam();
			FGameShowArenaAnnouncerGlitchData Data = GetRandomGlitchData();
			int NewFace = GetRandomNewFaceFromRange(Data.FaceRange, CurrentFace);

			ApplyFace(NewFace, this, EInstigatePriority::Normal);

			GlitchPreviewTimeWhenNextFaceChange = Time + Announcer.RandStream.RandRange(Data.MinTimeToDisplayFace, Data.MaxTimeToDisplayFace);
		}

		if (Time > GlitchPreviewTimeWhenNextColorChange)
		{
			FVector RandomVector = Announcer.RandStream.GetUnitVector();
			float R = RandomVector.X;
			float G = RandomVector.Y;
			float B = RandomVector.Z;
			FLinearColor Color = FLinearColor(R, G, B) * 15;
			UpdateFaceMaterialColor(Color);
			GlitchPreviewTimeWhenNextColorChange = Time + Announcer.RandStream.RandRange(0.2, 0.3);
		}
		UpdateFaceXY(6.0 + Math::Clamp(Math::PerlinNoise1D(Time) * 0.4, -0.2, 0.4), 6.0 + Math::Clamp(Math::PerlinNoise1D(Time) * 0.1, 0, 0.1));
	}
#endif
};
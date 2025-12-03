class UAnimInstanceCoastBotSwarm : UHazeAnimInstanceBase
{
	TArray<FHazeModifyBoneData> BoneDatas;

	AWingSuitBots WingSuitBots;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float NoiseAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LastBotSpread;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector OffsetSpline22;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector OffsetSpline23;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector OffsetSpline24;

	FRotator LastThreeBotsRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		WingSuitBots = Cast<AWingSuitBots>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		// ClearModifyBonesData();
		// for (int i = 1; i < 24; ++i)
		// {
		// 	FName SplineName = FName(f"Spline{i}");
		// 	FHazeModifyBoneData& BoneData = GetOrAddModifyBoneData(SplineName);

		// 	BoneDatas.Add(BoneData);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (WingSuitBots == nullptr)
			return;

		NoiseAlpha = WingSuitBots.AnimNoiseAlpha;
		LastBotSpread = WingSuitBots.LastBotSpread;

		LastThreeBotsRotation.Roll += DeltaTime * 50;

		OffsetSpline22 = LastThreeBotsRotation.UnrotateVector(FVector(0, LastBotSpread, LastBotSpread / -2.0));
		OffsetSpline23 = LastThreeBotsRotation.UnrotateVector(FVector(0, -LastBotSpread, 0));
		OffsetSpline24 = LastThreeBotsRotation.UnrotateVector(FVector(0, LastBotSpread, LastBotSpread));

		// TODO: Move this to initliaze for optimization
		// for (int i = 1; i < BoneDatas.Num(); ++i)
		// {
		// auto& BoneData = BoneDatas[i];
		for (int i = 1; i < 24; ++i)
		{
			FName SplineName = FName(f"Spline{i}");
			FHazeModifyBoneData& BoneData = GetOrAddModifyBoneData(SplineName);

			BoneData.RotationMode = EHazeBoneModificationMode::Mode_Ignore;
			BoneData.ScaleMode = EHazeBoneModificationMode::Mode_Ignore;

			BoneData.Translation = FVector(WingSuitBots.BotSpacing * i, 0, 0);
			BoneData.TranslationMode = EHazeBoneModificationMode::Mode_Replace;
			BoneData.TranslationSpace = EBoneControlSpace::BCS_BoneSpace;
		}
	}
}
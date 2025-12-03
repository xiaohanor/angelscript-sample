struct FSkylineBossForceFieldData
{
	FVector Location;
	float Radius;
	float LifeSpan;
}

class USkylineBossForceFieldComponent : UStaticMeshComponent
{
	TArray<FSkylineBossForceFieldData> ForceFieldImpacts;
	int MaxImpacts = 10;
	UMaterialInstanceDynamic MID;

	TArray<FName> LocationParams;
	TArray<FName> RadiusParams;

	float ForceFieldOpacity = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MID = CreateDynamicMaterialInstance(0);
	
		for (int i = 0; i < MaxImpacts; i++)
		{
			LocationParams.Add(FName("Bubble" + i + n"Loc"));
			RadiusParams.Add(FName("Bubble" + i + n"Radius"));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MID.SetScalarParameterValue(n"MinOpacity", ForceFieldOpacity);
		ForceFieldOpacity = Math::Max(0.0, ForceFieldOpacity - 0.5 * DeltaSeconds);

		int NumOfFields = ForceFieldImpacts.Num();
		for (int i = NumOfFields - 1; i >= 0; i--)
		{
			auto& ForceFieldImpact = ForceFieldImpacts[i];
			
			ForceFieldImpact.LifeSpan -= DeltaSeconds;

			if (ForceFieldImpact.LifeSpan <= 0.0)
				ForceFieldImpacts.RemoveAt(i);
		}
	
		UpdateImpactMID();
	}

	void AddImpact(FVector ImpactWorldLocation, float Radius, float LifeSpan)
	{
		ForceFieldOpacity = Math::Min(ForceFieldOpacity + 0.5, 0.5);

		FSkylineBossForceFieldData ImpactData;
		ImpactData.Location = WorldTransform.InverseTransformPositionNoScale(ImpactWorldLocation);
		ImpactData.Radius = Radius;
		ImpactData.LifeSpan = LifeSpan;

		if (ForceFieldImpacts.Num() == 10)
			ForceFieldImpacts.RemoveAt(0);

		ForceFieldImpacts.Add(ImpactData);
	}

	/*
	void RemoveImpact(int Index)
	{
		ForceFieldImpacts.RemoveAt(Index);
		ClearMID(Index);	
	}

	void UpdateMID(int Index)
	{
		auto& ImpactData = ForceFieldImpacts[Index];

		FVector Location = WorldTransform.TransformPositionNoScale(ImpactData.Location);

		MID.SetVectorParameterValue(LocationParams[Index], FLinearColor(Location));
		MID.SetScalarParameterValue(RadiusParams[Index], ImpactData.Radius * ImpactData.LifeSpan);
	}

	void ClearMID(int Index)
	{
		PrintToScreen("Impact " + Index + " removed.", 2.0, FLinearColor::Green);
		MID.SetVectorParameterValue(LocationParams[Index], FLinearColor(FVector::ZeroVector));
		MID.SetScalarParameterValue(RadiusParams[Index], 0.0);
	}
	*/

	void UpdateImpactMID()
	{
		for (int i = 0; i < MaxImpacts; i++)
		{
			if (ForceFieldImpacts.IsValidIndex(i))
			{
				auto& ImpactData = ForceFieldImpacts[i];

				FVector Location = WorldTransform.TransformPositionNoScale(ImpactData.Location);

				MID.SetVectorParameterValue(LocationParams[i], FLinearColor(Location));
				MID.SetScalarParameterValue(RadiusParams[i], ImpactData.Radius * ImpactData.LifeSpan);
			}
			else
			{
				MID.SetVectorParameterValue(LocationParams[i], FLinearColor(FVector::ZeroVector));
				MID.SetScalarParameterValue(RadiusParams[i], 0.0);
			}
		}
	}
}
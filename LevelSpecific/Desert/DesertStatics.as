namespace Desert
{
	UDesertManagerComponent GetManager()
	{
		if (Game::Mio == nullptr)
			return nullptr;

		auto Manager = UDesertManagerComponent::Get(Game::Mio);

		if (Manager == nullptr)
		{
			Manager = UDesertManagerComponent::Create(Game::Mio);
			// Manager.MakeNetworked(Game::Mio, n"DesertManagerComponent");
		}

		return Manager;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Get Desert Manager")
	UDesertManagerComponent BP_GetDesertManager()
	{
		return GetManager();
	}

	UFUNCTION(BlueprintCallable)
	TArray<UDesertLandscapeComponent> GetLandscapeComponents()
	{
		auto Manager = Desert::GetManager();

#if EDITOR
		if (Manager == nullptr)
			return Desert::GetEditorLandscapeComponents();
#endif

		return Manager.Landscapes;
	}

	AActor GetLandscapeActor(ESandSharkLandscapeLevel Level)
	{
		return Desert::GetManager().LandscapesByLevel[Level].Landscape;
	}

	UFUNCTION(BlueprintCallable)
	float GetLandscapeHeight(FVector Location)
	{
		bool bHasFoundHeight = false;
		float32 BestHeight = 0;

		for (auto LandscapeComp : Desert::GetLandscapeComponents())
		{
			if (!IsValid(LandscapeComp) || !IsValid(LandscapeComp.Owner))
				continue;

			float32 Height = 0;
			if (!LandscapeComp.Landscape.GetHeightAtLocation(Location, Height))
				continue;

			// Skip if the difference is too large (special case because the hour glass has two stacked landscapes)
			if (Math::Abs(Height - Location.Z) > 5000)
				continue;

			if (!bHasFoundHeight || Height > BestHeight)
				BestHeight = Height;

			bHasFoundHeight = true;
		}

		if (!bHasFoundHeight)
			return Location.Z;

		return float(BestHeight);
	}

	UFUNCTION(BlueprintCallable)
	float GetLandscapeHeightByLevel(FVector Location, ESandSharkLandscapeLevel Level)
	{
		auto LandscapeComp = Desert::GetManager().LandscapesByLevel[Level];

		if (!IsValid(LandscapeComp) || !IsValid(LandscapeComp.Owner) || LandscapeComp.Level != Level)
			return Location.Z;

		float32 Height = 0;
		if (!LandscapeComp.Landscape.GetHeightAtLocation(Location, Height))
			return Location.Z;

		return float(Height);
	}
	UFUNCTION()
	FVector GetLandscapeNormal(FTransform WorldTransform, ESandSharkLandscapeLevel Level)
	{
		auto LandscapeComp = Desert::GetManager().LandscapesByLevel[Level];
		if (!IsValid(LandscapeComp) || !IsValid(LandscapeComp.Owner) || LandscapeComp.Level != Level)
			return FVector::UpVector;

		FVector PointA = WorldTransform.Location - WorldTransform.Rotator().ForwardVector * 100;
		FVector PointB = WorldTransform.Location + WorldTransform.Rotator().ForwardVector * 100;
		FVector PointC = WorldTransform.Location + WorldTransform.Rotator().RightVector * 100;
		FVector Normal = (PointB-PointA).GetSafeNormal().CrossProduct((PointC-PointA).GetSafeNormal()).GetSafeNormal();
		return Normal;
	}

	bool HasLandscapeForLevel(ESandSharkLandscapeLevel Level)
	{
		return Desert::GetManager().LandscapesByLevel.Contains(Level);
	}

	FVector GetLandscapeLocation(FVector Location)
	{
		float LandscapeHeight = GetLandscapeHeight(Location);
		return FVector(Location.X, Location.Y, LandscapeHeight);
	}

	FVector GetLandscapeLocationByLevel(FVector Location, ESandSharkLandscapeLevel Level)
	{
		float LandscapeHeight = GetLandscapeHeightByLevel(Location, Level);
		return FVector(Location.X, Location.Y, LandscapeHeight);
	}

	UFUNCTION(BlueprintCallable)
	void SetDesertLevelState(EDesertLevelState LevelState, bool bIsProgressPoint = false)
	{
		auto Manager = Desert::GetManager();
		Manager.SetLevelState(LevelState, bIsProgressPoint);
		if (LevelState == EDesertLevelState::Vortex)
			Manager.SetRelevantLandscapeLevel(ESandSharkLandscapeLevel::Upper);
	}

	UFUNCTION(BlueprintCallable)
	void SetActiveLandscapeLevel(ESandSharkLandscapeLevel LandscapeLevel)
	{
		auto Manager = Desert::GetManager();
		Manager.SetRelevantLandscapeLevel(LandscapeLevel);
	}

	UFUNCTION(BlueprintPure)
	EDesertLevelState GetDesertLevelState()
	{
		return Desert::GetManager().GetLevelState();
	}

	UFUNCTION(BlueprintPure)
	ESandSharkLandscapeLevel GetRelevantLandscapeLevel()
	{
		return Desert::GetManager().GetRelevantLandscapeLevel();
	}

	UFUNCTION(BlueprintPure)
	EDesertLevelState GetDesertProgressPointLevelState()
	{
		return Desert::GetManager().GetProgressPointLevelState();
	}

#if EDITOR
	TArray<UDesertLandscapeComponent> GetEditorLandscapeComponents()
	{
		TArray<ALandscape> Actors = Editor::GetAllEditorWorldActorsOfClass(ALandscape);
		TArray<ALandscape> Landscapes;
		TArray<UDesertLandscapeComponent> LandscapeComponents;

		for (auto Actor : Actors)
		{
			auto LandscapeComponent = UDesertLandscapeComponent::Get(Actor);
			if (LandscapeComponent != nullptr)
				LandscapeComponents.Add(LandscapeComponent);
		}

		return LandscapeComponents;
	}
#endif
}
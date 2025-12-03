enum EFakeSplitAreaType
{
	Split,
	Rectangle,
	CircleArc,
}

struct FFakeSplitLevelData
{
	int LevelIndex = 0;
	FName SplitName;
	TMap<UMaterialInterface, UMaterialInstanceDynamic> InstanceMap;

	FVector Origin;
	FQuat SplitRotation;

	EFakeSplitAreaType AreaType;
	FVector2D AreaSize;
	float SplitZOrder;

	TArray<ULevel> RenderedLevels;
	TArray<ECollisionChannel> IgnoreChannels;
	TArray<ECollisionChannel> BlockChannels;
	ECollisionChannel OverrideObjectType = ECollisionChannel::ECC_MAX;
	bool bRemoveCollision = false;

	TArray<UPrimitiveComponent> ToggleComponents;

	bool bAffectLightingChannels = false;
	FLightingChannels LightingChannelsForStatic;
	FLightingChannels LightingChannelsForMovable;
}

UCLASS(HideCategories = "Activation Tags Debug Cooking Collision")
class UFakeSplitRenderManagerComponent : UActorComponent
{

	UPROPERTY(EditDefaultsOnly)
	TMap<UMaterialInterface, UMaterialInterface> MeltdownMaterialReplaceMap;
	UPROPERTY(EditDefaultsOnly)
	UMaterialParameterCollection GlobalParameters;

	TArray<FFakeSplitLevelData> LevelData;

	bool bSplitsChanged = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownMode", FLinearColor(0.0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData0", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData1", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData2", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData3", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData4", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData5", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData6", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData7", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData8", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData9", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData10", FLinearColor(0, 0, 0, 0));
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownData11", FLinearColor(0, 0, 0, 0));
	}

	void ActivateMeltdownRendering()
	{
		Material::SetVectorParameterValue(GlobalParameters, n"MeltdownMode", FLinearColor(1.0, 0, 0, 0));
	}

	void AddSplitIgnoreCollisionChannel(FName SplitName, ECollisionChannel IgnoreChannel)
	{
		auto& Data = GetSplitData(SplitName);
		Data.IgnoreChannels.Add(IgnoreChannel);
	}

	void AddSplitBlockCollisionChannel(FName SplitName, ECollisionChannel IgnoreChannel)
	{
		auto& Data = GetSplitData(SplitName);
		Data.BlockChannels.Add(IgnoreChannel);
	}

	void SetSplitCollisionOverrideType(FName SplitName, ECollisionChannel ObjectType)
	{
		auto& Data = GetSplitData(SplitName);
		Data.OverrideObjectType = ObjectType;
	}

	void SetSplitRemoveCollision(FName SplitName, bool bRemoveCollision)
	{
		auto& Data = GetSplitData(SplitName);
		Data.bRemoveCollision = bRemoveCollision;
	}

	void SetSplitLightingChannels(FName SplitName, FLightingChannels LightingChannels)
	{
		auto& Data = GetSplitData(SplitName);
		Data.bAffectLightingChannels = true;
		Data.LightingChannelsForStatic = LightingChannels;
		Data.LightingChannelsForMovable = LightingChannels;
	}

	void SetSplitLightingChannels(FName SplitName, FLightingChannels LightingChannelsForStatic, FLightingChannels LightingChannelsForMovable)
	{
		auto& Data = GetSplitData(SplitName);
		Data.bAffectLightingChannels = true;
		Data.LightingChannelsForStatic = LightingChannelsForStatic;
		Data.LightingChannelsForMovable = LightingChannelsForMovable;
	}

	void AddLevelToSplit(TSoftObjectPtr<UWorld> LevelReference, FName SplitName)
	{
		auto& Data = GetSplitData(SplitName);
		ULevel Level = LevelReference.Get().PersistentLevel;
		Data.RenderedLevels.Add(Level);

		for (auto Actor : Level.Actors)
		{
			if (Actor != nullptr)
				AddActorToData(Data, Actor);
		}
	}

	int GetLevelIndexForLevel(ULevel Level)
	{
		for (int i = 0, Count = LevelData.Num(); i < Count; ++i)
		{
			if (LevelData[i].RenderedLevels.Contains(Level))
				return i;
		}
		return -1;
	}

	void AddActorToSplit(AActor Actor, FName SplitName)
	{
		AddActorToData(GetSplitData(SplitName), Actor);
	}

	void AddComponentToSplit(UPrimitiveComponent Component, FName SplitName)
	{
		AddComponentToData(GetSplitData(SplitName), Component);
	}

	void SetSplitConstraint(FName SplitName, FVector Origin, FQuat Rotation, EFakeSplitAreaType AreaType, FVector2D AreaSize, float SplitZOrder)
	{
		auto& Data = GetSplitData(SplitName);
		if (Data.Origin == Origin && Data.SplitRotation == Rotation && Data.AreaType == AreaType && Data.AreaSize == AreaSize && Data.SplitZOrder == SplitZOrder)
			return;

		FName OriginParamName;
		FName RotationParamName;
		switch (Data.LevelIndex)
		{
			case 0: OriginParamName = n"MeltdownData0"; RotationParamName = n"MeltdownData1"; break;
			case 1: OriginParamName = n"MeltdownData2"; RotationParamName = n"MeltdownData3"; break;
			case 2: OriginParamName = n"MeltdownData4"; RotationParamName = n"MeltdownData5"; break;
			case 3: OriginParamName = n"MeltdownData6"; RotationParamName = n"MeltdownData7"; break;
			case 4: OriginParamName = n"MeltdownData8"; RotationParamName = n"MeltdownData9"; break;
			case 5: OriginParamName = n"MeltdownData10"; RotationParamName = n"MeltdownData11"; break;
			default: devError("Too many meltdown splits active!"); break;
		}

		FLinearColor OriginData;
		OriginData.R = Origin.X;
		OriginData.G = Origin.Y;
		OriginData.B = Origin.Z;
		OriginData.A = AreaSize.X;

		FQuat NormalizedRotation = Rotation.GetNormalized();

		FLinearColor RotationData;
		RotationData.R = Rendering::PackTwoFloatsAsHalf(NormalizedRotation.X, NormalizedRotation.Y);
		RotationData.G = Rendering::PackTwoFloatsAsHalf(NormalizedRotation.Z, NormalizedRotation.W);
		RotationData.B = SplitZOrder;

		switch (AreaType)
		{
			case EFakeSplitAreaType::Split:
				RotationData.A = 0.0;
			break;
			case EFakeSplitAreaType::Rectangle:
				RotationData.A = -AreaSize.Y;
			break;
			case EFakeSplitAreaType::CircleArc:
				RotationData.A = AreaSize.Y;
			break;
		}

		Material::SetVectorParameterValue(
			GlobalParameters,
			OriginParamName,
			OriginData,
		);

		Material::SetVectorParameterValue(
			GlobalParameters,
			RotationParamName,
			RotationData,
		);

		Data.Origin = Origin;
		Data.SplitRotation = Rotation;
		Data.AreaType = AreaType;
		Data.AreaSize = AreaSize;
		Data.SplitZOrder = SplitZOrder;
		bSplitsChanged = true;
	}

	private FFakeSplitLevelData& GetSplitData(FName SplitName)
	{
		for (int i = 0, Count = LevelData.Num(); i < Count; ++i)
		{
			if (LevelData[i].SplitName == SplitName)
				return LevelData[i];
		}

		FFakeSplitLevelData NewData;
		NewData.SplitName = SplitName;
		NewData.LevelIndex = LevelData.Num();
		LevelData.Add(NewData);

		return LevelData.Last();
	}

	private UMaterialInterface FindReplacementMaterial(UMaterialInterface Original)
	{
		UMaterialInterface Replacement;
		UMaterialInstance Instance = Cast<UMaterialInstance>(Original);
		while (Instance != nullptr)
		{
			if (MeltdownMaterialReplaceMap.Find(Instance, Replacement))
				return Replacement;
			Instance = Cast<UMaterialInstance>(Instance.Parent);
		}

		if (MeltdownMaterialReplaceMap.Find(Original.BaseMaterial, Replacement))
			return Replacement;
		return nullptr;
	}

	private void AddActorToData(FFakeSplitLevelData& Data, AActor Actor)
	{
		TArray<UPrimitiveComponent> Primitives;
		Actor.GetComponentsByClass(Primitives);

		for (UPrimitiveComponent Primitive : Primitives)
			AddComponentToData(Data, Primitive);

		// Modify materials on decals as well
		auto Decal = Cast<ADecalActor>(Actor);
		if (Decal != nullptr)
			Decal.Decal.SetDecalMaterial(GetRebasedMaterial(Data, Decal.Decal.GetDecalMaterial()));
	}

	private UMaterialInterface GetRebasedMaterial(FFakeSplitLevelData& Data, UMaterialInterface SourceMaterial)
	{
		if (SourceMaterial == nullptr)
			return nullptr;

		UMaterialInstanceDynamic DynamicInstance;
		if (!Data.InstanceMap.Find(SourceMaterial, DynamicInstance))
		{
			UMaterialInterface NewBaseMaterial = FindReplacementMaterial(SourceMaterial);
			if (NewBaseMaterial == nullptr)
				return nullptr;

			DynamicInstance = Rendering::CreateRebasedDynamicMaterialInstance(SourceMaterial, NewBaseMaterial);

			uint Mask = uint(1) << uint(Data.LevelIndex);
			float32 FloatMask = Rendering::ReinterpretUIntToFloat(Mask);

			FLinearColor ColorData;
			ColorData.R = FloatMask;

			DynamicInstance.SetVectorParameterValue(n"Meltdown_MeltdownParameters", ColorData);
			Data.InstanceMap.Add(SourceMaterial, DynamicInstance);
		}

		return DynamicInstance;
	}

	private void AddComponentToData(FFakeSplitLevelData& Data, UPrimitiveComponent Primitive)
	{
		auto NiagaraComp = Cast<UNiagaraComponent>(Primitive);
		if (NiagaraComp != nullptr)
		{
			Data.ToggleComponents.Add(NiagaraComp);
			return;
		}

		auto Mesh = Cast<UMeshComponent>(Primitive);
		if (Mesh != nullptr)
		{
			int MaterialCount = Mesh.GetNumMaterials();
			for (int i = 0; i < MaterialCount; ++i)
			{
				UMaterialInterface SourceMaterial = Mesh.GetMaterial(i);
				if (SourceMaterial == nullptr)
					continue;
				Mesh.SetMaterial(i, GetRebasedMaterial(Data, SourceMaterial));
			}

			if (Mesh.OverlayMaterial != nullptr)
				Mesh.SetOverlayMaterial(GetRebasedMaterial(Data, Mesh.OverlayMaterial));
		}

		// If it has collision, needs to be managed to turn on or off
		if (Primitive.GetCollisionProfileName() != n"NoCollision"
			&& !Primitive.HasTag(n"MeltdownPermanentCollision"))
		{
			if (Primitive.GetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter) != ECollisionResponse::ECR_Ignore)
			{
				for (auto IgnoreChannel : Data.IgnoreChannels)
					Primitive.SetCollisionResponseToChannel(IgnoreChannel, ECollisionResponse::ECR_Ignore);
				for (auto BlockChannel : Data.BlockChannels)
					Primitive.SetCollisionResponseToChannel(BlockChannel, ECollisionResponse::ECR_Block);
			}

			if (Data.OverrideObjectType != ECollisionChannel::ECC_MAX)
				Primitive.SetCollisionObjectType(Data.OverrideObjectType);

			if (Data.bRemoveCollision)
				Primitive.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

		if (Data.bAffectLightingChannels)
		{
			if (Primitive.Mobility == EComponentMobility::Static || Primitive.LightmapType == ELightmapType::ForceSurface)
			{
				Primitive.SetLightingChannels(
					Data.LightingChannelsForStatic.bChannel0,
					Data.LightingChannelsForStatic.bChannel1,
					Data.LightingChannelsForStatic.bChannel2,
				);
			}
			else
			{
				Primitive.SetLightingChannels(
					Data.LightingChannelsForMovable.bChannel0,
					Data.LightingChannelsForMovable.bChannel1,
					Data.LightingChannelsForMovable.bChannel2,
				);
			}
		}
	}

	private bool IsPointWithinSplit(const FFakeSplitLevelData& SplitData, FVector Point) const
	{
		FVector CameraDirection = Point - Game::Mio.ViewLocation;
		FVector LocalPointInSplit = SplitData.SplitRotation.UnrotateVector(Point - SplitData.Origin);
		FVector LocalCameraDirectionInSplit = SplitData.SplitRotation.UnrotateVector(CameraDirection);

		if (LocalPointInSplit.Z != 0 && LocalCameraDirectionInSplit.Z != 0)
		{
			LocalPointInSplit -= LocalCameraDirectionInSplit * (LocalPointInSplit.Z / LocalCameraDirectionInSplit.Z);
			LocalPointInSplit.Z = 0;
		}

		switch (SplitData.AreaType)
		{

			case EFakeSplitAreaType::Split:
			{
				float SplitAngularSize = SplitData.AreaSize.X;
				float DeltaAngle = (Math::Atan2(LocalPointInSplit.Y, LocalPointInSplit.X) + TWO_PI) % TWO_PI;
				if (SplitAngularSize < 0)
				{
					if (DeltaAngle < 0.0 && DeltaAngle >= SplitAngularSize)
						return true;
				}
				else
				{
					if (DeltaAngle >= 0.0 && DeltaAngle <= SplitAngularSize)
						return true;
				}
			}
			break;
			case EFakeSplitAreaType::Rectangle:
			{
				if (LocalPointInSplit.X < 0.0)
					return false;
				if (LocalPointInSplit.X > SplitData.AreaSize.X)
					return false;
				if (LocalPointInSplit.Y < 0.0)
					return false;
				if (LocalPointInSplit.Y > SplitData.AreaSize.Y)
					return false;

				return true;
			}
			case EFakeSplitAreaType::CircleArc:
			{
				float Distance = LocalPointInSplit.Size2D();
				if (Distance > SplitData.AreaSize.Y)
					return false;

				float SplitAngularSize = SplitData.AreaSize.X;
				float DeltaAngle = (Math::Atan2(LocalPointInSplit.Y, LocalPointInSplit.X) + TWO_PI) % TWO_PI;
				if (SplitAngularSize < 0)
				{
					if (DeltaAngle < 0.0 && DeltaAngle >= SplitAngularSize)
						return true;
				}
				else
				{
					if (DeltaAngle >= 0.0 && DeltaAngle <= SplitAngularSize)
						return true;
				}
			}
			break;
		}

		return false;
	}

	int GetLevelIndexForPoint(FVector Point) const
	{
		int BestSplitIndex = -1;
		float BestZOrder = 0.0;

		for (int i = 0, Count = LevelData.Num(); i < Count; ++i)
		{
			if (IsPointWithinSplit(LevelData[i], Point))
			{
				if (LevelData[i].SplitZOrder >= BestZOrder)
				{
					BestSplitIndex = i;
					BestZOrder = LevelData[i].SplitZOrder;
				}
			}
		}

		return BestSplitIndex;
	}

	FName GetSplitNameForPoint(FVector Point) const
	{
		int LevelIndex = GetLevelIndexForPoint(Point);
		if (LevelIndex == -1)
			return NAME_None;
		return LevelData[LevelIndex].SplitName;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (int LevelIndex = 0, LevelCount = LevelData.Num(); LevelIndex < LevelCount; ++LevelIndex)
		{
			FFakeSplitLevelData& Data = LevelData[LevelIndex];
			for (UPrimitiveComponent NiagaraComp : Data.ToggleComponents)
			{
				if (GetLevelIndexForPoint(NiagaraComp.WorldLocation) == LevelIndex)
					NiagaraComp.RemoveComponentVisualsBlocker(this);
				else
					NiagaraComp.AddComponentVisualsBlocker(this);
			}
		}
	}
};
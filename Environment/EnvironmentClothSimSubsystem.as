
class UEnvironmentClothSimSubsystem : UScriptWorldSubsystem
{
	default bCreateForLevelEditorWorlds = true;

	TArray<TWeakObjectPtr<UEnvironmentClothSimComponent>> Cloths;
	int ClothCount = 0;
	int FirstPossibleEmptySlot = 0;

	UFUNCTION()
	int AddCloth(UEnvironmentClothSimComponent Cloth)
	{
		int EmptySlot = FirstPossibleEmptySlot;
		while (EmptySlot < Cloths.Num())
		{
			if (Cloths[EmptySlot] == nullptr)
				break;
			EmptySlot += 1;
		}

		if (Cloths.IsValidIndex(EmptySlot))
			Cloths[EmptySlot] = Cloth;
		else
			Cloths.Add(Cloth);

		ClothCount += 1;
		FirstPossibleEmptySlot = EmptySlot + 1;

		UpdateClothCount(Cloth);
		int Index = EmptySlot;
		int X = Index % ClothCountSideLength;
		int Y = Math::IntegerDivisionTrunc(Index, ClothCountSideLength);

		auto Texture = Cast<UMaterialInstanceConstant>(Cloth.MeshMaterialDynamic.Parent).GetTextureParameterValue(n"PinningMask");
		
		CopyTextureMaterialDynamic.SetTextureParameterValue(n"InputTexture", Texture);
		UCanvas Canvas;
		FDrawToRenderTargetContext Context;
		FVector2D A;
		Rendering::BeginDrawCanvasToRenderTarget(PinningMask, Canvas, A, Context);
		Canvas.DrawTexture(Texture, FVector2D(X*PerClothResolution,Y*PerClothResolution), FVector2D(PerClothResolution, PerClothResolution), FVector2D(0, 0), FVector2D(1, 1));
		//Canvas.DrawMaterial(CopyTextureMaterialDynamic, FVector2D(0, 0), FVector2D(256, 256), FVector2D(X, Y), FVector2D(16, 16), 0, FVector2D(0.5, 0.5));
		Rendering::EndDrawCanvasToRenderTarget(Context);

		Cloth.UpdateClothIndex(Index);
		return Index;
	}

	UFUNCTION()
	void RemoveCloth(UEnvironmentClothSimComponent Cloth)
	{
		int Index = Cloths.FindIndex(Cloth);
		if (Index == -1)
			return;

		Cloths[Index] = nullptr;
		
		FirstPossibleEmptySlot = Math::Min(Index, FirstPossibleEmptySlot);

		Cloth.ClothIndex = -1;
		ClothCount -= 1;
		UpdateClothCount(Cloth);
	}
	
	bool Enabled = false;
	bool LastEnabled = false;
	int LastClothCount = 0;
	void UpdateClothCount(UEnvironmentClothSimComponent Cloth)
	{
		devCheck(slots >= ClothCount, "Too many UEnvironmentClothSimComponent (BP_EnvironmentClothSim) components. " + ClothCount + " / " + (ClothCountSideLength*ClothCountSideLength));

		Enabled = ClothCount != 0;
		if(Enabled != LastEnabled)
		{
			LastEnabled = Enabled;
			if(Enabled) // Became enabled
			{
				int BigTargetResolution = PerClothResolution * ClothCountSideLength;
				Position0 = Rendering::CreateRenderTarget2D(BigTargetResolution, BigTargetResolution, ETextureRenderTargetFormat::RTF_RGBA16f);
				Position0.AddressX = TextureAddress::TA_Wrap;
				Position0.AddressY = TextureAddress::TA_Wrap;
				Position1 = Rendering::CreateRenderTarget2D(BigTargetResolution, BigTargetResolution, ETextureRenderTargetFormat::RTF_RGBA16f);
				Position1.AddressX = TextureAddress::TA_Wrap;
				Position1.AddressY = TextureAddress::TA_Wrap;
				Velocity0 = Rendering::CreateRenderTarget2D(BigTargetResolution, BigTargetResolution, ETextureRenderTargetFormat::RTF_RGBA16f);
				Velocity0.AddressX = TextureAddress::TA_Wrap;
				Velocity0.AddressY = TextureAddress::TA_Wrap;
				Velocity1 = Rendering::CreateRenderTarget2D(BigTargetResolution, BigTargetResolution, ETextureRenderTargetFormat::RTF_RGBA16f);
				Velocity1.AddressX = TextureAddress::TA_Wrap;
				Velocity1.AddressY = TextureAddress::TA_Wrap;
				PinningMask = Rendering::CreateRenderTarget2D(BigTargetResolution, BigTargetResolution, ETextureRenderTargetFormat::RTF_RGBA8);
				PinningMask.AddressX = TextureAddress::TA_Wrap;
				PinningMask.AddressY = TextureAddress::TA_Wrap;
				
				for (int i = 0; i < DataCount; i++)
				{
					Data.Add(Rendering::CreateTexture2D(ClothCountSideLength, ClothCountSideLength, TextureCompressionSettings::TC_HDR_F32));
				}

				ClothSimMaterialDynamic = Material::CreateDynamicMaterialInstance(this, Cloths[0].Get().ClothSimMaterial);
				CopyTextureMaterialDynamic = Material::CreateDynamicMaterialInstance(this, Cloths[0].Get().CopyTextureMaterial);

				ClothSimMaterialDynamic.SetTextureParameterValue(n"PinningMask", PinningMask);

			}
			else // Became disabled
			{
				ClothSimMaterialDynamic.SetTextureParameterValue(n"PinningMask", nullptr);
				ClothSimMaterialDynamic.SetTextureParameterValue(n"LastPosition", nullptr);
				ClothSimMaterialDynamic.SetTextureParameterValue(n"LastVelocity", nullptr);
				CopyTextureMaterialDynamic.SetTextureParameterValue(n"InputTexture", nullptr);

				Position0 = nullptr;
				Position1 = nullptr;
				Velocity0 = nullptr;
				Velocity1 = nullptr;
				PinningMask = nullptr;
				ClothSimMaterialDynamic = nullptr;
				CopyTextureMaterialDynamic = nullptr;
				CopyDataMaterialDynamic = nullptr;
				Data.Empty();
			}
			CurrentPosition = Position0;
		}
		// Cloth count changed!
		if(LastClothCount != ClothCount)
		{
			LastClothCount = ClothCount;
		}
		
	#if EDITOR
		if (Cloth != nullptr)
		{
			Cloth.DebugPosition = Position0;
			Cloth.DebugClothSimMaterialDynamic = ClothSimMaterialDynamic;
			Cloth.DebugCopyDataMaterialDynamic = CopyDataMaterialDynamic;
			Cloth.DebugData0 = PinningMask;
		}
	#endif
	}
	
	// Simulation
	UPROPERTY()
	UTextureRenderTarget2D CurrentPosition;
	UPROPERTY()
	UTextureRenderTarget2D Position0;
	UPROPERTY()
	UTextureRenderTarget2D Position1;
	UPROPERTY()
	UTextureRenderTarget2D Velocity0;
	UPROPERTY()
	UTextureRenderTarget2D Velocity1;
	UPROPERTY()
	UTextureRenderTarget2D PinningMask;

	UPROPERTY()
	TArray<UTexture2D> Data;
	UPROPERTY()
	int DataCount = 4;

	UPROPERTY()
	UMaterialInstanceDynamic ClothSimMaterialDynamic;

	UPROPERTY()
	UMaterialInstanceDynamic CopyTextureMaterialDynamic;

	UPROPERTY()
	UMaterialInstanceDynamic CopyDataMaterialDynamic;

	int ClothCountSideLength = 16;
	int PerClothResolution = 16;

	// Total number of avilable "cloth" slots. If cloth count ever exceeds this, there has been an error.
	int slots = ClothCountSideLength * ClothCountSideLength;

	bool Swap;
	
	void StepSimulation(float State, bool Pos = true, bool Vel = true)
	{
		Swap = !Swap;
		UTextureRenderTarget2D Position 	= Swap ? Position0 : Position1;
		UTextureRenderTarget2D LastPosition = Swap ? Position1 : Position0;
		UTextureRenderTarget2D Velocity 	= Swap ? Velocity0 : Velocity1;
		UTextureRenderTarget2D LastVelocity = Swap ? Velocity1 : Velocity0;
		ClothSimMaterialDynamic.SetTextureParameterValue(n"LastPosition", LastPosition);
		ClothSimMaterialDynamic.SetTextureParameterValue(n"LastVelocity", LastVelocity);
		
		for (int i = 0; i < Data.Num(); i++)
		{
			ClothSimMaterialDynamic.SetTextureParameterValue(FName("Data" + i), Data[i]);
		}

		ClothSimMaterialDynamic.SetScalarParameterValue(n"UpdateState", State);
		if(Pos)
		{
			ClothSimMaterialDynamic.SetScalarParameterValue(n"VelocityState", 0.0);
			Rendering::DrawMaterialToRenderTarget(Position, ClothSimMaterialDynamic);
		}
		if(Vel)
		{
			ClothSimMaterialDynamic.SetScalarParameterValue(n"VelocityState", 1.0);
			Rendering::DrawMaterialToRenderTarget(Velocity, ClothSimMaterialDynamic);
		}
	}

	void PruneDestroyedCloths()
	{
		bool bAnyPruned = false;
		for (int i = Cloths.Num() - 1; i >= 0; --i)
		{
			if (!Cloths[i].IsValid() && !Cloths[i].IsExplicitlyNull())
			{
				ClothCount -= 1;
				Cloths[i] = nullptr;
				bAnyPruned = true;
				FirstPossibleEmptySlot = Math::Min(i, FirstPossibleEmptySlot);
			}
		}
		
		if (bAnyPruned)
			UpdateClothCount(nullptr);
	}

	float TimeLeftToEat = 0;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Enabled)
			PruneDestroyedCloths();
		if(!Enabled)
			return;

#if EDITOR
		// There's no need to update the editor world's cloth sim while playing PIE,
		// it just takes extra performance.
		if (!World.IsGameWorld() && Editor::IsPlaying())
			return;
#endif

		AGameSky Sky = GetSky();
		if (Sky == nullptr)
			return;
		if (Cloths.Num() == 0)
			return;
		
		ClothSimMaterialDynamic.SetScalarParameterValue(n"ClothWindStrength", Sky.ClothWindStrength);
		ClothSimMaterialDynamic.SetScalarParameterValue(n"TilesSideLength", ClothCountSideLength);
		ClothSimMaterialDynamic.SetScalarParameterValue(n"ClothSideLength", PerClothResolution);
		ClothSimMaterialDynamic.SetScalarParameterValue(n"SimulationSideLength", ClothCountSideLength*PerClothResolution);

		TArray<FVector4f> DataArray = TArray<FVector4f>();
		DataArray.SetNum(slots);

		bool bAnyClothDataChanged = false;
		for (TWeakObjectPtr<UEnvironmentClothSimComponent> ClothPtr : Cloths)
		{
			UEnvironmentClothSimComponent ClothComp = ClothPtr.Get();
			if (!IsValid(ClothComp))
				continue;

			if (ClothComp.bClothStateDirty)
			{
				ClothComp.bClothStateDirty = false;
				bAnyClothDataChanged = true;
			}
		}

#if EDITOR
		if (World.WorldType == EWorldType::Editor)
			bAnyClothDataChanged = true;
#endif

		if (bAnyClothDataChanged)
		{
			for (int j = 0; j < Data.Num(); j++)
			{
				for (int i = 0; i < slots; i++)
				{
					if(Cloths.Num() <= i)
						break;
					
					UEnvironmentClothSimComponent ClothComp = Cloths[i].Get();
					if(ClothComp == nullptr)
						continue;

					switch (j)
					{
						case 0:
						{
							FVector Pos = ClothComp.GetWorldLocation();
							DataArray[i] = FVector4f(FVector3f(Pos), float32(ClothComp.Gravity));
						}
						break;
						case 1:
						{
							FVector Up = ClothComp.GetUpVector() * ClothComp.PlaneSizeY;
							DataArray[i] = FVector4f(FVector3f(Up), float32(ClothComp.WindStrength));
						}
						break;
						case 2:
						{
							FVector Forward = ClothComp.GetForwardVector() * ClothComp.PlaneSizeX;
							DataArray[i] = FVector4f(FVector3f(Forward), ClothComp.InitDelayCounter);
							if (ClothComp.InitDelayCounter > 0)
							{
								ClothComp.InitDelayCounter--;
								ClothComp.bClothStateDirty = true;
							}
						}
						break;
						case 3:
						{
							FVector Movement = FVector(0, 0, 0);
							if(ClothComp.LastPosition != ClothComp.GetWorldLocation())
							{
								Movement = ClothComp.GetWorldLocation() - ClothComp.LastPosition;
								ClothComp.LastPosition = ClothComp.GetWorldLocation();
							}
							DataArray[i] = FVector4f(FVector3f(Movement), float32((ClothComp.bWindIsLocalSpace ? 1 : -1) * Math::Abs(ClothComp.PinningStrength)));
						}
						break;
					}
				}

				Rendering::UpdateTexture2D(Data[j], DataArray);
			}
		}

		int SubstepCount = 3;
		ClothSimMaterialDynamic.SetScalarParameterValue(n"SubstepCount", SubstepCount);

		float Dt = 1.0 / 30.0;
		TimeLeftToEat += DeltaTime;
		if(TimeLeftToEat > Dt)
		{
			TimeLeftToEat -= Dt;
		}
		if(TimeLeftToEat > 1.0) // Skip frame
		{
			TimeLeftToEat = 0;
		}
		
		ClothSimMaterialDynamic.SetScalarParameterValue(n"DeltaTime", Dt);
		for (int i = 0; i < SubstepCount; i++)
		{
			StepSimulation(2.0);
		}
	}
}
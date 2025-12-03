namespace DynamicWaterEffect
{
	UFUNCTION()
	void DynamicWaterEffectImpulse(FVector WorldLocation, float Strength = 1.0, float Radius = 50)
	{
		AGameSky Sky = TListedActors<AGameSky>().GetSingle();
		if(Sky == nullptr)
			return;
		
		UCanvas Canvas;
		FDrawToRenderTargetContext Context;
		FVector2D A;
		Rendering::BeginDrawCanvasToRenderTarget(Sky.DynamicWaterEffectControllerComponent.Current, Canvas, A, Context);
		Sky.DynamicWaterEffectControllerComponent.ApplyDecalInternal(Canvas, EDynamicWaterEffectDecalType::Push, WorldLocation, Strength, 0, 0, 0, Radius, 1, 1, 0, false, 4);
		Rendering::EndDrawCanvasToRenderTarget(Context);
	}
}

UCLASS(HideCategories = "ComponentTick Debug Activation Cooking Disable Tags Collision")
class UDynamicWaterEffectControllerComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Target;

	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D TargetPersist;

	UPROPERTY()
	UTextureRenderTarget2D Current;

	UPROPERTY()
	UTextureRenderTarget2D Previous;
	
	UPROPERTY()
	UTextureRenderTarget2D CurrentPersist;

	UPROPERTY()
	UTextureRenderTarget2D PreviousPersist;
	
	UPROPERTY()
	UMaterialParameterCollection GlobalParameters;

	UPROPERTY()
	UMaterialInterface SimulationStep;
	UPROPERTY()
	UMaterialInterface SimulationStep_Turbulence;
	UPROPERTY()
	UMaterialInterface SimulationStepPersistent;
	
	UMaterialInstanceDynamic SimulationStepDynamic;
	
	UMaterialInstanceDynamic SimulationStepPersistentDynamic;

	UPROPERTY()
	UMaterialInterface Copy;
	UMaterialInstanceDynamic CopyDynamic;

	UPROPERTY()
	UMaterialInterface AddMaterial;
	UMaterialInstanceDynamic AddMaterialDynamic;

	UPROPERTY()
	UMaterialInterface MulMaterial;
	UMaterialInstanceDynamic MulMaterialDynamic;

	UPROPERTY()
	TArray<UDynamicWaterEffectDecalComponent> Decals;

	UPROPERTY(EditAnywhere)
	bool bEnabled = false;

	UPROPERTY(EditAnywhere)
	float SimulationSize = 5000;

	UPROPERTY(EditAnywhere)
	bool bSimulationSizeOverride = false;

	UPROPERTY(EditAnywhere)
	float SimulationSizeOverrideValue = 5000;

	UFUNCTION()
	float GetSimulationSize() const
	{
		float Result = 5000;
		
		if(bSimulationSizeOverride)
			Result = SimulationSizeOverrideValue;
		else
			Result = SimulationSize;

		if(Result == 0)
			Result = 5000;

		return Result;
	}
	
	UPROPERTY(EditAnywhere)
	float SpeedMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float Damping = 0.01;

	UPROPERTY(EditAnywhere)
	float Fade = 1.0;

	UPROPERTY(EditAnywhere)
	float Turbulence = 0.0;

	UPROPERTY(EditAnywhere)
	float Resolution = 512;
	
	UPROPERTY(EditAnywhere)
	bool bPersistentEnabled = false;

	UPROPERTY(EditAnywhere)
	float PersistentDamping = 0.05;

	UPROPERTY(EditAnywhere)
	float PersistentAccumulation = 0.01;

	UPROPERTY(EditAnywhere)
	float PersistentResolution = 512;

	UPROPERTY()
	bool bReset = false;

	UPROPERTY(EditAnywhere, Category = "Visualization")
	bool bVisualize = true;

	UPROPERTY(EditAnywhere, Category = "Visualization")
	float VisualizeHeight = 0;
	
	float TimeCounter;

	FVector LastPlanePos0;
	FVector LastPlanePos1;

	FVector Delta0;
	FVector Delta1;
	float LastWaterDecalAppliedTime = -1.0;

	default bTickInEditor = true;
	
	FVector GetPlanePosition(int i) const
	{
		FVector PlanePos = FVector::ZeroVector;

		#if EDITOR
		if(Editor::IsPlaying() && Game::Players.IsValidIndex(i))
		{
			if (Game::Players[i].bIsParticipatingInCutscene)
			{
				PlanePos = UCameraUserComponent::Get(Game::Players[i]).GetActiveCamera().GetWorldLocation();
			}
			else
			{
				PlanePos = Game::Players[i].GetActorLocation();
			}
		}
		else
		{
			PlanePos = Editor::GetEditorViewLocation();
		}
		#else
		if (Game::Players[i].bIsParticipatingInCutscene)
		{
			PlanePos = UCameraUserComponent::Get(Game::Players[i]).GetActiveCamera().GetWorldLocation();
		}
		else
		{
			PlanePos = Game::Players[i].GetActorLocation();
		}
		#endif

		// Snap the plane to a grid that's the same density as the texture to prevent juddering.
		// (same trick that's used for shadow maps that follow the camera)
		float WorldUnitsPerPixel = GetSimulationSize() / Resolution;
		PlanePos.X = Math::RoundToFloat(PlanePos.X / WorldUnitsPerPixel) * WorldUnitsPerPixel;
		PlanePos.Y = Math::RoundToFloat(PlanePos.Y / WorldUnitsPerPixel) * WorldUnitsPerPixel;
		
		return PlanePos;
	}
	
	void ApplyDecalInternal(UCanvas Canvas, EDynamicWaterEffectDecalType Type, 
		FVector WorldLocation, float Strength, float Speed, float Tiling, float Height, float Size, float ScaleX, float ScaleY, float Angle, bool bCircle, float Contrast)
	{
		LastWaterDecalAppliedTime = Time::GameTimeSeconds;

		for (int i = 0; i < 2; i++)
		{
			FVector PlanePos = FVector::ZeroVector;
			
			FLinearColor Opacity = FLinearColor(1, 1, 0, 0);
			FLinearColor TargetColor  = FLinearColor(1, 1, 0, 0);

			float OpacityF = 1.0;
			float TargetF = -Strength * 0.1 * Speed;
			if(Type == EDynamicWaterEffectDecalType::Barrier)
			{
				TargetF = -Height;
			}

			if(i == 0)
			{
				Opacity = FLinearColor(OpacityF, 0, 0, 0);
				TargetColor  = FLinearColor(TargetF, 0, 0, 0);
				PlanePos = LastPlanePos0;
			}
			else
			{
				Opacity = FLinearColor(0, OpacityF, 0, 0);
				TargetColor  = FLinearColor(0, TargetF, 0, 0);
				PlanePos = LastPlanePos1;
			}

			FVector LocalPos = (WorldLocation - PlanePos) / GetSimulationSize(); 
			FVector2D LocalSize = FVector2D(ScaleX, ScaleY) * Size;
			LocalSize /= GetSimulationSize();

			LocalPos = LocalPos + FVector(1.0) * FVector(0.5); // center on underlying plane
			
			// If the object is fully outside of the plane, skip it.
			float Buffer = Math::Max(LocalSize.X, LocalSize.Y);
			if(LocalPos.X < (0.0 - Buffer) ||LocalPos.X > (1.0 + Buffer) ||LocalPos.Y < (0.0 - Buffer) || LocalPos.Y > (1.0 + Buffer))
				continue;

			FVector2D pos = FVector2D(LocalPos.X, LocalPos.Y) * Resolution;
			FVector2D size = LocalSize * Resolution;

			pos -= size;
			size *= 2.0;
			if(Type == EDynamicWaterEffectDecalType::Barrier)
			{
				MulMaterialDynamic.SetVectorParameterValue(n"Opacity", Opacity);
				MulMaterialDynamic.SetVectorParameterValue(n"Target", TargetColor);
				MulMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_Speed", Speed);
				MulMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_Tiling", Tiling * 0.01);
				MulMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_Type", int(Type));
				MulMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_ScaleX", ScaleX * Size);
				MulMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_ScaleY", ScaleY * Size);
				MulMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_Circle", bCircle ? 1 : 0);
				MulMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_Contrast", Contrast);
				
				Canvas.DrawMaterial(MulMaterialDynamic, pos, size, FVector2D(0, 0), FVector2D(1, 1), Angle, FVector2D(0.5, 0.5));
			}
			AddMaterialDynamic.SetVectorParameterValue(n"Opacity", Opacity);
			AddMaterialDynamic.SetVectorParameterValue(n"Target", TargetColor);
			AddMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_Speed", Speed);
			AddMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_Tiling", Tiling * 0.01);
			AddMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_Type", int(Type));
			AddMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_ScaleX", ScaleX * Size);
			AddMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_ScaleY", ScaleY * Size);
			AddMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_Circle", bCircle ? 1 : 0);
			AddMaterialDynamic.SetScalarParameterValue(n"DynamicWaterDecal_Contrast", Contrast);
			Canvas.DrawMaterial(AddMaterialDynamic, pos, size, FVector2D(0, 0), FVector2D(1, 1), Angle, FVector2D(0.5, 0.5));
		}
	}

	void UpdateDecal(UCanvas Canvas, UDynamicWaterEffectDecalComponent Decal)
	{
		if(Decal == nullptr)
			return;

		if(!Decal.bEnabled)
			return;

		if (Decal.Strength <= 0)
			return;

		float Strength = Decal.Strength;
		if(Decal.Type == EDynamicWaterEffectDecalType::Barrier)
			Strength = 0;
		
		bool bInside = true;
		if(Decal.bOnlyActiveInSurfaceVolumes)
		{
			bInside = false;
			Decal.bCurrentlyInSurfaceVolume = false;
			// N^2, but N is pretty small
			TListedActors<ADynamicWaterEffectSurface> ListedSurfaces = TListedActors<ADynamicWaterEffectSurface>();
			for (ADynamicWaterEffectSurface ListedSurface : ListedSurfaces)
			{
				FVector WorldPos = Decal.WorldLocation;
				FVector Scale = Decal.GetWorldScale() * 100;
				Scale.Z = 0;
				FVector LocalPos = ListedSurface.BoxComponent.WorldTransform.InverseTransformPosition(WorldPos);
				FBox DecalBox = FBox(LocalPos-Scale, LocalPos+Scale);

				bInside = ListedSurface.BoxComponent.GetComponentLocalBoundingBox().Intersect(DecalBox);
				if(bInside)
				{
					Decal.bCurrentlyInSurfaceVolume = true;
					break;
				}
			}
			
			// N^2, but N is pretty small (again)
			TListedActors<ASwimmingVolume> ListedSwimmingVolume = TListedActors<ASwimmingVolume>();
			for (ASwimmingVolume SwimmingVolume : ListedSwimmingVolume)
			{
				FVector WorldPos = Decal.WorldLocation;
				FVector Scale = Decal.GetWorldScale() * 100;
				Scale.Z = 0;
				FVector LocalPos = SwimmingVolume.ActorTransform.InverseTransformPosition(WorldPos);
				FBox DecalBox = FBox(LocalPos-Scale, LocalPos+Scale);
				
				FVector Origin;
				FVector Extents;
				SwimmingVolume.GetActorLocalBounds(true, Origin, Extents);
				FBox ActorBox = FBox(Origin - Extents, Origin + Extents);
				bInside = ActorBox.Intersect(DecalBox);

				if(bInside)
				{
					Decal.bCurrentlyInSurfaceVolume = true;
					break;
				}
			}
		}

		if(Decal.bOnlyActiveInSurfaceVolumes)
		{
			if(Decal.bCurrentlyInSurfaceVolume)
			{
				// PrintToScreen(f"{Decal.Name} of {Decal.Owner} = {Decal.Strength}");
				ApplyDecalInternal(Canvas, Decal.Type, Decal.GetWorldLocation(), 
					Strength, Decal.Speed, Decal.Tiling, Decal.Height, 100, Decal.GetWorldScale().X, Decal.GetWorldScale().Y, Decal.GetWorldRotation().Yaw, Decal.bCircle, Decal.Contrast);
			}
		}
		else
		{

			// PrintToScreen(f"{Decal.Name} of {Decal.Owner} = {Decal.Strength}");
			ApplyDecalInternal(Canvas, Decal.Type, Decal.GetWorldLocation(), 
				Strength, Decal.Speed, Decal.Tiling, Decal.Height, 100, Decal.GetWorldScale().X, Decal.GetWorldScale().Y, Decal.GetWorldRotation().Yaw, Decal.bCircle, Decal.Contrast);
		}
	}

	void StepSimulation()
	{
		// swap
		UTextureRenderTarget2D Temp = Current;
		Current = Previous;
		Previous = Temp;
		
		UTextureRenderTarget2D TempPersist = CurrentPersist;
		CurrentPersist = PreviousPersist;
		PreviousPersist = TempPersist;
		
		for (int i = 0; i < 2; i++)
		{
			FVector PlanePos = GetPlanePosition(i);
			FVector LastPlanePos = FVector::ZeroVector;
			if(i == 0) 	LastPlanePos = LastPlanePos0;
			else 		LastPlanePos = LastPlanePos1;
			
			FVector WorldSpaceDelta = PlanePos - LastPlanePos;
			FVector UVSpaceDelta = (PlanePos - LastPlanePos) / GetSimulationSize();
			if(i == 0) 	Delta0 = UVSpaceDelta;
			else 		Delta1 = UVSpaceDelta;
				
			LastPlanePos = PlanePos;

			if(i == 0) 	LastPlanePos0 = LastPlanePos;
			else 		LastPlanePos1 = LastPlanePos;

			if(i == 0) Material::SetVectorParameterValue(GlobalParameters, n"DynamicWaterEffectPlayer0Pos", FLinearColor(LastPlanePos0));
			else 	   Material::SetVectorParameterValue(GlobalParameters, n"DynamicWaterEffectPlayer1Pos", FLinearColor(LastPlanePos1));
		}
		
		Material::SetScalarParameterValue(GlobalParameters, n"DynamicWaterEffectSize", GetSimulationSize());
		TListedActors<ADynamicWaterEffectDecal> ListedDecals = TListedActors<ADynamicWaterEffectDecal>();

		// Execute water ripple simulation
		SimulationStepDynamic.SetTextureParameterValue(n"Target", Previous);
		SimulationStepDynamic.SetScalarParameterValue(n"Resolution", Resolution);
		SimulationStepDynamic.SetScalarParameterValue(n"SpeedMultiplier", SpeedMultiplier);
		SimulationStepDynamic.SetScalarParameterValue(n"Damping", Damping);
		SimulationStepDynamic.SetScalarParameterValue(n"Fade", Fade);
		SimulationStepDynamic.SetScalarParameterValue(n"Turbulence", Turbulence);
		SimulationStepDynamic.SetVectorParameterValue(n"Delta", FLinearColor(Delta0.X, Delta0.Y, Delta1.X, Delta1.Y));
		Rendering::DrawMaterialToRenderTarget(Current, SimulationStepDynamic);

		if(bPersistentEnabled)
		{
			SimulationStepPersistentDynamic.SetTextureParameterValue(n"Target", PreviousPersist);
			SimulationStepPersistentDynamic.SetTextureParameterValue(n"Simulation", Previous);
			SimulationStepPersistentDynamic.SetScalarParameterValue(n"Resolution", PersistentResolution);
			SimulationStepPersistentDynamic.SetScalarParameterValue(n"Damping", PersistentDamping);
			SimulationStepPersistentDynamic.SetScalarParameterValue(n"Accumulation", PersistentAccumulation);
			SimulationStepPersistentDynamic.SetVectorParameterValue(n"Delta", FLinearColor(Delta0.X, Delta0.Y, Delta1.X, Delta1.Y));
			Rendering::DrawMaterialToRenderTarget(CurrentPersist, SimulationStepPersistentDynamic);
		}

		UCanvas Canvas;
		FDrawToRenderTargetContext Context;
		FVector2D A;
		Rendering::BeginDrawCanvasToRenderTarget(Current, Canvas, A, Context);

		#if EDITOR
		if(Editor::IsPlaying())
		{
			for (UDynamicWaterEffectDecalComponent Decal : Decals)
			{
				UpdateDecal(Canvas, Decal);
			}
		}
		else
		{
			for (ADynamicWaterEffectDecal DecalActor : ListedDecals)
			{
				UpdateDecal(Canvas, DecalActor.DynamicWaterEffectDecalComponent);
			}
		}
		#else

		for (UDynamicWaterEffectDecalComponent Decal : Decals)
		{
			UpdateDecal(Canvas, Decal);
		}
		#endif

		Rendering::EndDrawCanvasToRenderTarget(Context);

		if (LastWaterDecalAppliedTime >= 0.0 && Time::GetGameTimeSince(LastWaterDecalAppliedTime) < 20.0)
		{
			// Copy
			CopyDynamic.SetTextureParameterValue(n"InputTexture", Current);
			Rendering::DrawMaterialToRenderTarget(Target, CopyDynamic);
			CopyDynamic.SetTextureParameterValue(n"InputTexture", CurrentPersist);
			Rendering::DrawMaterialToRenderTarget(TargetPersist, CopyDynamic);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bEnabled)
			return;

		if(SimulationStepDynamic == nullptr)
			Init();

		if(bReset)
		{
			bReset = false;
			Init();
		}
		
		// Lower than 30 fps, execute every frame, running the water ripples in slow-motion
		// Higher than 30 fps, skip frames to maintain speed. So in the future when we have faster computers it will maybe not explode x'D

		float simulationFrameTime = 1.0 / 30.0;
		TimeCounter += DeltaSeconds;
		
		float BlendValue = 0.0;
		if(DeltaSeconds < simulationFrameTime) // Higher than 30 fps
		{
			if(TimeCounter > simulationFrameTime) // It's been more than 1/30 ms, execute the sim and reset the counter.
			{
				TimeCounter = Math::Min(TimeCounter - simulationFrameTime, simulationFrameTime);
				StepSimulation();
			}
			BlendValue = TimeCounter / simulationFrameTime;
			BlendValue = Math::Clamp(BlendValue, 0, 1);
		}
		else
		{
			StepSimulation();
			BlendValue = 0.0;
		}
		
		Material::SetScalarParameterValue(GlobalParameters, n"DynamicWaterEffectBlendTime", BlendValue);

	}
	
#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		Init();
	}
#endif

	UFUNCTION(CallInEditor)
	void Init()
	{
		SimulationStepDynamic = Material::CreateDynamicMaterialInstance(this, Turbulence> 0 ? SimulationStep_Turbulence : SimulationStep);
		SimulationStepPersistentDynamic = Material::CreateDynamicMaterialInstance(this, SimulationStepPersistent);

		CopyDynamic = Material::CreateDynamicMaterialInstance(this, Copy);
		AddMaterialDynamic = Material::CreateDynamicMaterialInstance(this, AddMaterial);
		MulMaterialDynamic = Material::CreateDynamicMaterialInstance(this, MulMaterial);

		Current  = Rendering::CreateRenderTarget2D(int(Resolution), int(Resolution));
		Previous = Rendering::CreateRenderTarget2D(int(Resolution), int(Resolution));
		CurrentPersist  = Rendering::CreateRenderTarget2D(int(PersistentResolution), int(PersistentResolution));
		PreviousPersist = Rendering::CreateRenderTarget2D(int(PersistentResolution), int(PersistentResolution));

		Current.AddressX = TextureAddress::TA_Clamp;
		Current.AddressY = TextureAddress::TA_Clamp;
		CurrentPersist.AddressX = TextureAddress::TA_Clamp;
		CurrentPersist.AddressY = TextureAddress::TA_Clamp;

		Previous.AddressX = TextureAddress::TA_Clamp;
		Previous.AddressY = TextureAddress::TA_Clamp;
		PreviousPersist.AddressX = TextureAddress::TA_Clamp;
		PreviousPersist.AddressY = TextureAddress::TA_Clamp;

		Rendering::ClearRenderTarget2D(Current, FLinearColor(0,0,0,0));
		Rendering::ClearRenderTarget2D(Previous, FLinearColor(0,0,0,0));
		Rendering::ClearRenderTarget2D(CurrentPersist, FLinearColor(0,0,0,0));
		Rendering::ClearRenderTarget2D(PreviousPersist, FLinearColor(0,0,0,0));
		Rendering::ClearRenderTarget2D(TargetPersist, FLinearColor(0,0,0,0));
		Rendering::ClearRenderTarget2D(Target, FLinearColor(0,0,0,0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Init();
	}
}

#if EDITOR
class UDynamicWaterEffectControllerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDynamicWaterEffectControllerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const auto Controller = Cast<UDynamicWaterEffectControllerComponent>(Component);
		if(Controller == nullptr)
			return;

		if(!Controller.bVisualize)
			return;

		FVector Location = Controller.GetPlanePosition(0);
		Location.Z = Controller.VisualizeHeight;
		
		FVector Extents = FVector(Controller.GetSimulationSize(), Controller.GetSimulationSize(), 0);
		DrawWireBox(Location, Extents, FQuat::Identity, FLinearColor::LucBlue, 3);
	}
}
#endif

enum EDynamicWaterEffectDecalType
{
	// Pushes the water surface down or pulls it up
	Push,

	// Sets the water height, acting as a wall
	Barrier,

	// Applies noise to the water surface, like near a waterfall.
	Noise,
}

UCLASS(HideCategories = "ComponentTick Rendering Disable Debug Activation Cooking Tags LOD Collision")
class UDynamicWaterEffectDecalComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	EDynamicWaterEffectDecalType Type;

	UPROPERTY(EditAnywhere, interp, Meta = (EditCondition="Type == EDynamicWaterEffectDecalType::Barrier", EditConditionHides))
	float Height = 0.0;

	UPROPERTY(EditAnywhere, interp)
	bool bEnabled = true;

	UPROPERTY(EditAnywhere, interp, Meta = (EditCondition="Type != EDynamicWaterEffectDecalType::Barrier", EditConditionHides))
	float Strength = 1;

	UPROPERTY(EditAnywhere, interp, Meta = (EditCondition="Type == EDynamicWaterEffectDecalType::Noise", EditConditionHides))
	float Speed = 1;

	UPROPERTY(EditAnywhere, interp, Meta = (EditCondition="Type == EDynamicWaterEffectDecalType::Noise", EditConditionHides))
	float Tiling = 1;

	UPROPERTY(EditAnywhere, interp, Category="Advanced")
	bool bCircle = false;

	UPROPERTY(EditAnywhere, interp, Category="Advanced")
	float Contrast = 4;

	UPROPERTY(EditAnywhere, interp, Category="Advanced")
	bool bOnlyActiveInSurfaceVolumes = false;
	
	UPROPERTY(EditAnywhere, Category="Advanced")
	bool bCurrentlyInSurfaceVolume = false;

	FVector LastWorldLocation;
	float LastSizeX;
	float LastSizeY;
	float LastAngle;

	bool bAddedToBpSky = false;

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		AGameSky Sky = AGameSky::Get();
		if(Sky == nullptr)
			return;
		
		Sky.DynamicWaterEffectControllerComponent.Decals.Remove(this);
		bAddedToBpSky = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		AGameSky Sky = AGameSky::Get();
		if (Sky == nullptr)
			return;
		
		Sky.DynamicWaterEffectControllerComponent.Decals.AddUnique(this);
		bAddedToBpSky = true;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		AGameSky Sky = AGameSky::Get();
		if(Sky == nullptr)
			return;
		
		Sky.DynamicWaterEffectControllerComponent.Decals.Remove(this);
		bAddedToBpSky = false;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AGameSky Sky = AGameSky::Get();
		if(Sky == nullptr)
			return;
		
		if (!Owner.IsActorDisabled())
		{
			Sky.DynamicWaterEffectControllerComponent.Decals.AddUnique(this);
			bAddedToBpSky = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// tick once
		SetComponentTickEnabled(false);

		if(!bAddedToBpSky)
		{
			AGameSky Sky = AGameSky::Get();
			if(Sky == nullptr)
				return;
			Sky.DynamicWaterEffectControllerComponent.Decals.AddUnique(this);
			bAddedToBpSky = true;
		}
	}
}

#if EDITOR
class UDynamicWaterEffectDecalComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDynamicWaterEffectDecalComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const auto WaterEffect = Cast<UDynamicWaterEffectDecalComponent>(Component);
		if(WaterEffect == nullptr)
			return;

		FVector Extents = FVector(100 * WaterEffect.WorldScale.X, 100 * WaterEffect.WorldScale.Y, 0);
		FRotator Rotation = FRotator(0, WaterEffect.WorldRotation.Yaw, 0);

		if(WaterEffect.bCircle)
		{
			DrawCircle(WaterEffect.WorldLocation, Extents.X, FLinearColor::LucBlue, 3, FVector::UpVector);
		}
		else
		{
			DrawWireBox(WaterEffect.WorldLocation, Extents, Rotation.Quaternion(), FLinearColor::LucBlue, 3);
		}

		if(WaterEffect.Type == EDynamicWaterEffectDecalType::Barrier)
		{
			FVector Location = WaterEffect.WorldLocation;
			Location.Z += WaterEffect.Height * 100;

			DrawArrow(WaterEffect.WorldLocation, Location, FLinearColor::Blue, 10, 3);

			if(WaterEffect.bCircle)
			{
				DrawCircle(Location, 100 * WaterEffect.WorldScale.X, FLinearColor::Blue, 3, FVector::UpVector);
			}
			else
			{
				DrawWireBox(Location, Extents, Rotation.Quaternion(), FLinearColor::Blue, 3);
			}
		}
	}
}
#endif

class ADynamicWaterEffectDecal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDynamicWaterEffectDecalComponent DynamicWaterEffectDecalComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
	
#if EDITOR
    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;
	default Billboard.bUseInEditorScaling = true;

    UPROPERTY(EditAnywhere)
	float EditorBillboardScale = 1.0;

	UPROPERTY(DefaultComponent)
	UBoxComponent Box;
	default Box.bIsEditorOnly = true;
	default Box.bHiddenInGame = true;
	default Box.bGenerateOverlapEvents = false;
	default Box.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Box.SetBoxExtent(FVector(100, 100, 0));
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Box.SetWorldLocation(GetActorLocation());
		Box.SetWorldRotation(GetActorRotation());
		Box.SetBoxExtent(FVector(75, 75, 0));
		Box.SetRelativeScale3D(FVector::OneVector);

		Billboard.SetWorldLocation(GetActorLocation());
		Billboard.SetWorldRotation(GetActorRotation());
		Billboard.SetWorldScale3D(FVector::OneVector*EditorBillboardScale);
		
		DynamicWaterEffectDecalComponent.SetRelativeScale3D(FVector::OneVector);
		DynamicWaterEffectDecalComponent.SetRelativeLocation(FVector::ZeroVector);
		DynamicWaterEffectDecalComponent.SetRelativeRotation(FRotator::ZeroRotator);

		SetActorRotation(FRotator(0, GetActorRotation().Yaw, 0));
	}
#endif
}

class ADynamicWaterEffectSurface : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UBoxComponent BoxComponent;
	default BoxComponent.BoxExtent = FVector(1000.0, 1000.0, 100.0);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
}
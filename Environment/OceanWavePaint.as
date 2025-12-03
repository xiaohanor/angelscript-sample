

struct FWaveData
{
	// input position moved down to sit on the surface of the water
	UPROPERTY()
	FVector PointOnWave;

	// normal at input position
	UPROPERTY()
	FVector PointOnWaveNormal;
}
struct FWaveInput
{
	FVector SamplerPosition;
	FVector SampleDirection;
}

struct FOceanWaveSmoothDelaySeconds
{
	private const int DELAY_COUNT = 10;
	private TArray<float> Delays;
	private float SmoothDelay = 0;

	FOceanWaveSmoothDelaySeconds()
	{
		Delays.Reserve(DELAY_COUNT);
	}

	void AddCurrentDelay(float Delay)
	{
		// Make sure there are never too many delay samples
		while(Delays.Num() >= DELAY_COUNT)
			Delays.RemoveAt(0);

		Delays.Add(Delay);

		// Average out all of the samples
		SmoothDelay = 0;
		
		for(int i = 0; i < Delays.Num(); i++)
			SmoothDelay += Delays[i];

		SmoothDelay /= Delays.Num();
	}

	float GetValue() const
	{
		return SmoothDelay;
	}
}

UCLASS(Abstract)
class AOceanWavePaint : AHazeActor 
{
	// I have created a monster,
	// This blueprint reads what the artist painted on a landscape and draws it to a big rendertexture.
	// That big rendertexture is then used in another rendertexture for wave height and direction used in VFX and shaders.
	// Then little parts of that second render texture are drawn to a raelly small rendertexture that's then async-copied to the CPU for use in gameplay.
	
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.WorldScale3D = FVector(10);

	#if EDITOR
	UPROPERTY(DefaultComponent)
	UOceanWavePaintComponent OceanWavePaint;
	default OceanWavePaint.bIsEditorOnly = true;
	#endif

#if EDITOR
	UPROPERTY(DefaultComponent)
	UOceanWavePaintTimeLoggerComponent TimeLoggerComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActor;

	UPROPERTY(EditAnywhere)
	ALandscape TargetLandscape;

	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D TextureTarget;

	UPROPERTY()
	UMaterialParameterCollection GlobalParameters;
	
	UPROPERTY()
	UTextureRenderTarget2D OceanHeightTextureTarget;

    UPROPERTY(DefaultComponent)
	UHazeRenderTargetReadbackComponent ReadbackComp;

	UPROPERTY()
	ULandscapeLayerInfoObject LandscapeLayerR;

	UPROPERTY()
	ULandscapeLayerInfoObject LandscapeLayerG;

	UPROPERTY()
	ULandscapeLayerInfoObject LandscapeLayerB;

	UPROPERTY()
	ULandscapeLayerInfoObject LandscapeLayerA;

	UPROPERTY()
	UMaterialInterface SwizzleDrawMaterial;

	UPROPERTY()
	UMaterialInstanceDynamic SwizzleDrawMaterialInstanceDynamic;

	UPROPERTY()
	UMaterialInterface OceanHeightDrawMaterial;

	UPROPERTY()
	UMaterialInstanceDynamic OceanHeightDrawMaterialInstanceDynamic;

	UPROPERTY()
	UMaterialInterface OceanVectorsMaterial;
	
	UPROPERTY()
	UMaterialInstanceDynamic OceanVectorsMaterialInstanceDynamic;

	UPROPERTY()
	UTexture2D TestTexture;

	UPROPERTY()
	FLinearColor LandscapeTextureTransform;

	UPROPERTY()
	bool bDebug;

	UPROPERTY()
	TArray<FInstigator> WaterHeightInstigators;

	UPROPERTY(EditAnywhere)
	bool bOceanParameterOverrideEnabled;

	UPROPERTY(EditAnywhere)
	float AmplitudeOverride;

	UPROPERTY(EditAnywhere)
	float AmplitudePaintBlend;
	
	UPROPERTY(EditAnywhere, Interp)
	bool bOceanParameterOverrideShading;
	UPROPERTY(EditAnywhere, Interp)
	FLinearColor AbsorptionOverride;
	UPROPERTY(EditAnywhere, Interp)
	FLinearColor ScatteringOverride;

	UPROPERTY(EditAnywhere)
	UNiagaraParameterCollection GlobalNiagaraParameters;
	UNiagaraParameterCollectionInstance GlobalNiagaraParams_Inst;

	UPROPERTY(EditAnywhere)
	FVector WorldOffset;
		
	void SetOverrideParameters()
	{
		float Amplitude = Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).GetScalarParameterValue(n"waveData_Amplitude");
		float WorldOffsetX = Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).GetScalarParameterValue(n"waveData_WorldOffsetX");
		float WorldOffsetY = Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).GetScalarParameterValue(n"waveData_WorldOffsetY");
		FLinearColor Absorption = Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).GetVectorParameterValue(n"Absorption");
		FLinearColor Scattering = Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).GetVectorParameterValue(n"Scattering");

		if(bOceanParameterOverrideEnabled)
		{
			Amplitude = AmplitudeOverride;
			WorldOffsetX = WorldOffset.X;
			WorldOffsetY = WorldOffset.Y;
		}
		
		if(bOceanParameterOverrideShading)
		{
			Absorption = AbsorptionOverride;
			Scattering = ScatteringOverride;
		}
		
		TargetLandscape.SetLandscapeMaterialScalarParameterValue(n"waveData_Amplitude", Amplitude);
		TargetLandscape.SetLandscapeMaterialScalarParameterValue(n"waveData_WorldOffsetX", WorldOffsetX);
		TargetLandscape.SetLandscapeMaterialScalarParameterValue(n"waveData_WorldOffsetY", WorldOffsetY);
		TargetLandscape.SetLandscapeMaterialVectorParameterValue(n"Absorption", Absorption);
		TargetLandscape.SetLandscapeMaterialVectorParameterValue(n"Scattering", Scattering);

	}

	FLinearColor ChannelMaskFromIndex(int index)
	{
		if(index == 0)
			return FLinearColor(1, 0, 0, 0);
		if(index == 1)
			return FLinearColor(0, 1, 0, 0);
		if(index == 2)
			return FLinearColor(0, 0, 1, 0);
		if(index == 3)
			return FLinearColor(0, 0, 0, 1);

		return FLinearColor(0, 0, 0, 0);
	}

	int ChannelCount = 32;
	int InputDataHeight = 2;
	int OutputDataHeight = 2;
	bool bInitialized = false;

	UPROPERTY()
	float TextureScale = 128;

	UFUNCTION()
	void Init(bool bForce, bool resetInstigators)
	{
		if(TargetLandscape == nullptr)
			return;
		
		if(!bForce && bInitialized)
			return;
		
		FVector Origin;
		FVector Extent;
		TargetLandscape.GetActorBounds(false, Origin, Extent, false);
		
		int ResX = Math::Min(Math::FloorToInt(Extent.X / TextureScale), 2048);
		int ResY = Math::Min(Math::FloorToInt(Extent.Y / TextureScale), 2048);

		if(TextureTarget == nullptr)
		{
			TextureTarget = Rendering::CreateRenderTarget2D(ResX, ResY, ETextureRenderTargetFormat::RTF_RGBA8);
			TextureTarget.AddressX = TextureAddress::TA_Clamp;
			TextureTarget.AddressY = TextureAddress::TA_Clamp;
		}

		if(Output == nullptr)
		{
			Output = Rendering::CreateRenderTarget2D(ChannelCount, OutputDataHeight, ETextureRenderTargetFormat::RTF_RGBA32f);
			Output.AddressX = TextureAddress::TA_Clamp;
			Output.AddressY = TextureAddress::TA_Clamp;
		}

		SwizzleDrawMaterialInstanceDynamic = Material::CreateDynamicMaterialInstance(this, SwizzleDrawMaterial);
		OceanVectorsMaterialInstanceDynamic = Material::CreateDynamicMaterialInstance(this, OceanVectorsMaterial);
		OceanHeightDrawMaterialInstanceDynamic = Material::CreateDynamicMaterialInstance(this, OceanHeightDrawMaterial);

		if(Input == nullptr)
			Input = Rendering::CreateTexture2D(ChannelCount, InputDataHeight, TextureCompressionSettings::TC_HDR_F32);
		OceanVectorsMaterialInstanceDynamic.SetTextureParameterValue(n"InputTexture", Input);

		if(resetInstigators)
		{
			Inputs.Empty();
			Ready.Empty();
			Results.Empty();
			RequestFrames.Empty();
			for (int i = 0; i < ChannelCount; i++)
			{
				Ready.Add(false);
				RequestFrames.Add(0);
				Results.Add(FWaveData());
			}
			for (int i = 0; i < ChannelCount * InputDataHeight; i++)
			{
				Inputs.Add(FVector4f(0, 0, 0, 0));
			}
			
			WaterHeightInstigators.Reset(ChannelCount);
			for(int i = 0; i < ChannelCount; i++)
				WaterHeightInstigators.Add(FInstigator());
		}
		//SetDebugTexture(TextureTarget, 0);
		//SetDebugTexture(SmallTextureTarget, 1);
		//SetDebugTexture(OceanHeightTextureTarget, 2);
		//SetDebugTexture(TextureTarget, 3);
		
		if(GlobalNiagaraParameters != nullptr)
			GlobalNiagaraParams_Inst = Niagara::GetNiagaraParameterCollection(GlobalNiagaraParameters);

		bInitialized = true;
	}
	
	uint LatestReadbackFrame;
	float LatestReadbackGameTime;
	TArray<FVector4f> Inputs;
	UTexture2D Input;
	UTextureRenderTarget2D Output;

	TArray<uint> RequestFrames;
	TArray<bool> Ready;
	TArray<FWaveData> Results;
	uint CurrentDelayFrames = 0;
	float CurrentDelaySeconds = -1;
	FOceanWaveSmoothDelaySeconds SmoothDelaySeconds;

	bool bFirstTick = true;

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Init(true, true);
		RefreshAndRedraw();
	}
	#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Init(false, true);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Material::SetScalarParameterValue(GlobalParameters, n"OceanWavePaintGlobalTime", 0);
	}
	
	void CopyParameters(UMaterialInstanceDynamic To, UMaterialInstanceConstant From)
	{
		for (auto thing : From.ScalarParameterValues)
		{
			To.SetScalarParameterValue(thing.ParameterInfo.Name, thing.ParameterValue);
		}
		for (auto thing : From.VectorParameterValues)
		{
			To.SetVectorParameterValue(thing.ParameterInfo.Name, thing.ParameterValue);
		}
		for (auto thing : From.TextureParameterValues)
		{
			To.SetTextureParameterValue(thing.ParameterInfo.Name, thing.ParameterValue);
		}
	}
	
	UFUNCTION()
	void UpdateHeightTexture()
	{
		Material::SetScalarParameterValue(GlobalParameters, n"OceanWavePaintGlobalTime", Time::PredictedGlobalCrumbTrailTime);

		float Amplitude = Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).GetScalarParameterValue(n"waveData_Amplitude");
		float WorldOffsetX = Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).GetScalarParameterValue(n"waveData_WorldOffsetX");
		float WorldOffsetY = Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).GetScalarParameterValue(n"waveData_WorldOffsetY");

		SetOverrideParameters();
		
		TargetLandscape.SetLandscapeMaterialScalarParameterValue(n"waveData_Amplitude", Amplitude);
		TargetLandscape.SetLandscapeMaterialScalarParameterValue(n"waveData_WorldOffsetX", WorldOffsetX);
		TargetLandscape.SetLandscapeMaterialScalarParameterValue(n"waveData_WorldOffsetY", WorldOffsetY);

		OceanVectorsMaterialInstanceDynamic.SetTextureParameterValue(n"LandscapeDataTexture", TextureTarget);
		OceanVectorsMaterialInstanceDynamic.SetVectorParameterValue(n"LandscapeDataTextureTransform", LandscapeTextureTransform);

		if(GlobalNiagaraParams_Inst != nullptr)
			GlobalNiagaraParams_Inst.SetColorParameter(n"NPC.GlobalParameters_VFX.LandscapeDataTextureTransform", LandscapeTextureTransform);

		OceanVectorsMaterialInstanceDynamic.SetTextureParameterValue(n"HeightTexture", OceanHeightTextureTarget);
		OceanVectorsMaterialInstanceDynamic.SetScalarParameterValue(n"AmplitudePaintBlend", AmplitudePaintBlend);
		
		CopyParameters(OceanVectorsMaterialInstanceDynamic, Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial));
		Rendering::DrawMaterialToRenderTarget(Output, OceanVectorsMaterialInstanceDynamic);
		
		OceanHeightDrawMaterialInstanceDynamic.SetTextureParameterValue(n"LandscapeDataTexture", TextureTarget);
		OceanHeightDrawMaterialInstanceDynamic.SetVectorParameterValue(n"LandscapeDataTextureTransform", LandscapeTextureTransform);
		OceanHeightDrawMaterialInstanceDynamic.SetScalarParameterValue(n"AmplitudePaintBlend", AmplitudePaintBlend);
		CopyParameters(OceanHeightDrawMaterialInstanceDynamic, Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial));
		Rendering::DrawMaterialToRenderTarget(OceanHeightTextureTarget, OceanHeightDrawMaterialInstanceDynamic);
	}

	UPROPERTY()
	int ResetCount = 5; // reset 5 times
	UPROPERTY()
	float CurrentResetDelay = 5;

	float ResetDelay = 5;
	int DelayCount = 30;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// force init again, hacky, breaks in cooked if I don't do this. Not sure why, maybe the landscape textures are not streamed in yet?
		// Update, sometimes the landscape is far away, so we need to call this more over some time. (5 times over 25 seconds seems to be enough for twistytrain)
		CurrentResetDelay -= DeltaSeconds;
		DelayCount--;
		if((CurrentResetDelay < 0 && ResetCount > 0) || DelayCount == 0)
		{
			CurrentResetDelay = ResetDelay;
			Init(true, false);
			UpdateHeightTexture();
			Redraw();
			ResetCount--;
		}

		if(ResetCount != 5)
		{
			QueryWaveData(Game::Mio, Game::Mio.GetActorLocation());
			QueryWaveData(Game::Zoe, Game::Zoe.GetActorLocation());
			WaveDataMio = GetLatestWaveData(Game::Mio);
			WaveDataZoe = GetLatestWaveData(Game::Zoe);

			Rendering::UpdateTexture2D(Input, Inputs);

			UpdateHeightTexture();
			if (bFirstTick)
				Redraw();

			ReadbackComp.RequestReadback(Output);
			if (ReadbackComp.HasReadbackData())
			{
				LatestReadbackFrame = ReadbackComp.GetLatestReadbackFrame();
				LatestReadbackGameTime = ReadbackComp.GetLatestReadbackGameTime();
				CurrentDelayFrames = GFrameNumber - LatestReadbackFrame;
				CurrentDelaySeconds = Time::GameTimeSeconds - LatestReadbackGameTime;
				SmoothDelaySeconds.AddCurrentDelay(CurrentDelaySeconds);

				const TArray<FVector4f>& CpuSideData = ReadbackComp.GetLatestReadbackData();

				for (int i = 0; i < ChannelCount; i++)
				{
					if(RequestFrames[i] > LatestReadbackFrame)
					{
						Ready[i] = true;
					}
					else
					{
						Ready[i] = false;
					}

					FVector4f Location = CpuSideData[i] * 10000;
					FVector4f Normal   = CpuSideData[i + ChannelCount * 1] * 10000;
					Results[i].PointOnWave = FVector(Location.X, Location.Y, Location.Z);
					Results[i].PointOnWaveNormal = FVector(Normal.X, Normal.Y, Normal.Z).GetSafeNormal();
				}
			}

			bFirstTick = false;

			#if EDITOR
			FTemporalLog TemporalLog = TEMPORAL_LOG(this);
			TemporalLog.Value("Target Landscape", TargetLandscape);
			TemporalLog.Value("Delay;Current Delay in Frames", OceanWaves::GetCurrentDelayInFrames());
			TemporalLog.Value("Delay;Current Delay in Seconds", OceanWaves::GetCurrentDelayInSeconds());
			TemporalLog.Value("Delay;Smooth Delay in Seconds", OceanWaves::GetSmoothDelayInSeconds());

			for(int Channel = 0; Channel < ChannelCount; Channel++)
			{
				const FString ChannelCategory = f"{Channel:03}#Channel {Channel}";
				FTemporalLog ChannelLog = TemporalLog.Page("Channels");
				ChannelLog.Value(f"{ChannelCategory};Instigator", WaterHeightInstigators[Channel]);
				ChannelLog.Value(f"{ChannelCategory};Ready", Ready[Channel]);

				if(Ready[Channel])
				{
					FWaveData WaveData = Results[Channel];
					ChannelLog.Point(f"{ChannelCategory};WaveData;PointOnWave", WaveData.PointOnWave);
					ChannelLog.DirectionalArrow(f"{ChannelCategory};WaveData;PointOnWaveNormal", WaveData.PointOnWave, WaveData.PointOnWaveNormal * 300, 3, 100);
				}
			}
			#endif
		}
	}
	
	int InstigatorToChannel(FInstigator Instigator)
	{
		// Make sure that we are initialized
		if(!bInitialized)
			Init(false, true);

		if(Instigator == nullptr)
		{
			devError("OceanWavePaint needs a valid Instigator.");
			return -1;	
		}

		int Channel = WaterHeightInstigators.FindIndex(Instigator);
		if(Channel < 0)
		{
			for(int i = 0; i < WaterHeightInstigators.Num(); i++)
			{
				if(WaterHeightInstigators[i] == FInstigator())
				{
					WaterHeightInstigators[i] = Instigator;
					Channel = i;
					break;
				}
			}
		}
		
		check(Channel < ChannelCount);
		return Channel;
	}

	bool HasRequestedWaveData(FInstigator Instigator)
	{
		return InstigatorToChannel(Instigator) >= 0;
	}

	bool IsWaveDataReady(FInstigator Instigator)
	{
		return Ready[InstigatorToChannel(Instigator)];
	}

	void QueryWaveData(FInstigator Instigator, FVector WorldPos)
	{
		int Channel = InstigatorToChannel(Instigator);
		Inputs[Channel] = FVector4f(float32(WorldPos.X), float32(WorldPos.Y), float32(WorldPos.Z), 0);
		Inputs[ChannelCount + Channel] = FVector4f(0, 0, 0, 0);
		RequestFrames[Channel] = GFrameNumber + 1;
	}

	void QueryWaveDataRaycast(FInstigator Instigator, FVector Start, FVector Direction)
	{
		int Channel = InstigatorToChannel(Instigator);
		Inputs[Channel] = FVector4f(float32(Start.X), float32(Start.Y), float32(Start.Z), 0);
		Inputs[ChannelCount + Channel] = FVector4f(float32(Direction.X), float32(Direction.Y), float32(Direction.Z), 0);
		RequestFrames[Channel] = GFrameNumber + 1;
	}
	
	FWaveData GetLatestWaveData(FInstigator Instigator)
	{
		return Results[InstigatorToChannel(Instigator)];
	}

	FWaveData WaveDataMio;
	FWaveData WaveDataZoe;
	
	FWaveData GetWaveDataByPlayer(AHazePlayerCharacter Player)
	{
		if(Player == Game::Mio)
			return WaveDataMio;
		if(Player == Game::Zoe)
			return WaveDataZoe;
		return WaveDataMio;
	}

	void RemoveWaveDataInstigator(FInstigator Instigator)
	{
		int Channel = WaterHeightInstigators.FindIndex(Instigator);
		if(Channel >= 0)
		{
			WaterHeightInstigators[Channel] = FInstigator();
		}
	}

	UFUNCTION()
	void Redraw()
	{
		if(TargetLandscape == nullptr)
			return;

		FVector Origin;
		FVector Extent;
		TargetLandscape.GetActorBounds(false, Origin, Extent, false);
		
		SwizzleDrawMaterialInstanceDynamic.SetTextureParameterValue(n"WeightmapTexture0", TestTexture);
		SwizzleDrawMaterialInstanceDynamic.SetTextureParameterValue(n"WeightmapTexture1", TestTexture);
		SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelR", FLinearColor(1,0,0,0));
		SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelG", FLinearColor(0,1,0,0));
		SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelB", FLinearColor(0,0,1,0));
		SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelA", FLinearColor(0,0,0,1));

		TargetLandscape.SetLandscapeMaterialTextureParameterValue(n"LandscapeDataTexture", TextureTarget);

		LandscapeTextureTransform = FLinearColor(
			Origin.X - Extent.X,
			Origin.Y - Extent.Y,
			Extent.X * 2.0,
			Extent.Y * 2.0);
		
		TargetLandscape.SetLandscapeMaterialVectorParameterValue(n"LandscapeDataTextureTransform", LandscapeTextureTransform);
		Material::SetVectorParameterValue(GlobalParameters, n"LandscapeDataTextureTransform", LandscapeTextureTransform);
		
		Material::SetVectorParameterValue(GlobalParameters, n"OceanWavePaintDataTextureTransform", LandscapeTextureTransform);
		Material::SetScalarParameterValue(GlobalParameters, n"OceanWavePaintLandscapeHeight", TargetLandscape.GetActorLocation().Z);
		// Loop over landscape components, extract their textures and draw them to the big rendertexture.
		TArray<ULandscapeComponent> LandscapeComponents;
		TargetLandscape.GetComponentsByClass(LandscapeComponents);
		
		for (ULandscapeComponent LandscapeComponent : LandscapeComponents)
		{
			SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelR", FLinearColor(0,0,0,0));
			SwizzleDrawMaterialInstanceDynamic.SetScalarParameterValue(n"TextureR", 0);
			SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelG", FLinearColor(0,0,0,0));
			SwizzleDrawMaterialInstanceDynamic.SetScalarParameterValue(n"TextureG", 0);
			SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelB", FLinearColor(0,0,0,0));
			SwizzleDrawMaterialInstanceDynamic.SetScalarParameterValue(n"TextureB", 0);
			SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelA", FLinearColor(0,0,0,0));
			SwizzleDrawMaterialInstanceDynamic.SetScalarParameterValue(n"TextureA", 0);
			
			for (int i = 0; i < LandscapeComponent.WeightmapLayerAllocations.Num(); i++ )
			{
				auto Weightmap = LandscapeComponent.WeightmapLayerAllocations[i];
				
				if(Weightmap.LayerInfo == LandscapeLayerR)
				{
					SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelR", ChannelMaskFromIndex(Weightmap.WeightmapTextureChannel));
					SwizzleDrawMaterialInstanceDynamic.SetScalarParameterValue(n"TextureR", Weightmap.WeightmapTextureIndex);
				}
				if(Weightmap.LayerInfo == LandscapeLayerG)
				{
					SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelG", ChannelMaskFromIndex(Weightmap.WeightmapTextureChannel));
					SwizzleDrawMaterialInstanceDynamic.SetScalarParameterValue(n"TextureG", Weightmap.WeightmapTextureIndex);
				}
				if(Weightmap.LayerInfo == LandscapeLayerB)
				{
					SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelB", ChannelMaskFromIndex(Weightmap.WeightmapTextureChannel));
					SwizzleDrawMaterialInstanceDynamic.SetScalarParameterValue(n"TextureB", Weightmap.WeightmapTextureIndex);
				}
				if(Weightmap.LayerInfo == LandscapeLayerA)
				{
					SwizzleDrawMaterialInstanceDynamic.SetVectorParameterValue(n"ChannelA", ChannelMaskFromIndex(Weightmap.WeightmapTextureChannel));
					SwizzleDrawMaterialInstanceDynamic.SetScalarParameterValue(n"TextureA", Weightmap.WeightmapTextureIndex);
				}
			}
			
			for (int i = 0; i < LandscapeComponent.WeightmapTextures.Num(); i++)
			{
				SwizzleDrawMaterialInstanceDynamic.SetTextureParameterValue(FName("WeightmapTexture" + i), LandscapeComponent.WeightmapTextures[i].Get());
			}
			
			FVector2D WorldPos2D = FVector2D(LandscapeComponent.GetWorldLocation().X, LandscapeComponent.GetWorldLocation().Y);
			FVector2D ActorPos2D = FVector2D(Origin.X - Extent.X, Origin.Y - Extent.Y);
			FVector2D ComponentExtents2D = FVector2D(LandscapeComponent.BoundsExtent.X, LandscapeComponent.BoundsExtent.Y);
			FVector2D Extent2D = FVector2D(Extent.X, Extent.Y);
			
			FVector2D LocalPos = (WorldPos2D - ActorPos2D);
			FVector2D LocalExtents = (ComponentExtents2D / Extent2D);
			LocalPos /= FVector2D(Extent2D * 2.0);
			
			UCanvas Canvas;
			FDrawToRenderTargetContext Context;
			FVector2D Size;
			Rendering::BeginDrawCanvasToRenderTarget(TextureTarget, Canvas, Size, Context);
			Canvas.DrawMaterial(SwizzleDrawMaterialInstanceDynamic, Size * LocalPos, Size * LocalExtents, FVector2D(0, 0), FVector2D(1, 1));
			Rendering::EndDrawCanvasToRenderTarget(Context);
		}
		
		OceanHeightDrawMaterialInstanceDynamic.SetTextureParameterValue(n"LandscapeDataTexture", TextureTarget);
		OceanHeightDrawMaterialInstanceDynamic.SetVectorParameterValue(n"LandscapeDataTextureTransform", LandscapeTextureTransform);
		for (auto Thing : Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).ScalarParameterValues)
		{
			OceanHeightDrawMaterialInstanceDynamic.SetScalarParameterValue(Thing.ParameterInfo.Name, Thing.ParameterValue);
		}
		for (auto Thing : Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).VectorParameterValues)
		{
			OceanHeightDrawMaterialInstanceDynamic.SetVectorParameterValue(Thing.ParameterInfo.Name, Thing.ParameterValue);
		}
		for (auto Thing : Cast<UMaterialInstanceConstant>(TargetLandscape.LandscapeMaterial).TextureParameterValues)
		{
			OceanHeightDrawMaterialInstanceDynamic.SetTextureParameterValue(Thing.ParameterInfo.Name, Thing.ParameterValue);
		}
		Rendering::DrawMaterialToRenderTarget(OceanHeightTextureTarget, OceanHeightDrawMaterialInstanceDynamic);
	}

	#if EDITOR
	float LastRefreshTime = 0;
	const float RefreshesInterval = 0.05;
	void EditorTick(float DeltaTime)
	{
		if(Editor::IsPlaying())
			return;

		if(TargetLandscape == nullptr)
		{
			PrintToScreen(f"Unassigned TargetLandscape on {this}", 0, FLinearColor::Yellow);
			return;
		}
		
		SetOverrideParameters();
		UpdateHeightTexture();

		if(!Editor::IsLevelEditorModeActive(EHazeLevelEditorMode::Landscape))
			return;

		if(Time::GetRealTimeSince(LastRefreshTime) > RefreshesInterval)
		{
			LastRefreshTime = Time::RealTimeSeconds;
			RefreshAndRedraw();
		}
	}

	private void RefreshAndRedraw()
	{
		if(TargetLandscape == nullptr)
			return;
		
		Redraw();
		Material::SetScalarParameterValue(GlobalParameters, n"OceanWavePaintLandscapeHeight", TargetLandscape.GetActorLocation().Z);
	}
	#endif
}

#if EDITOR
class UOceanWavePaintComponent : USceneComponent 
{
	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Cast<AOceanWavePaint>(Owner).EditorTick(DeltaTime);
	}
}
#endif

#if EDITOR
UCLASS(HideCategories = "Rendering Cooking Activation ComponentTick Physics Lod Collision")
class UOceanWavePaintTimeLoggerComponent : UHazeTemporalLogScrubbableComponent
{
	TMap<int, float> FrameToTimeMap;

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogRecordedFrame(UHazeTemporalLog Log, int LogFrameNumber)
	{
		FrameToTimeMap.Add(LogFrameNumber, Time::PredictedGlobalCrumbTrailTime);
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogScrubbedToFrame(UHazeTemporalLog Log, int LogFrameNumber)
	{
		auto OceanWavePaint = OceanWaves::GetOceanWavePaint();
		if(OceanWavePaint == nullptr)
			return;

		float Time;
		if(FrameToTimeMap.Find(LogFrameNumber, Time))
		{
			Material::SetScalarParameterValue(OceanWaves::GetOceanWavePaint().GlobalParameters, n"OceanWavePaintGlobalTime", Time);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogStopScrubbing(UHazeTemporalLog Log)
	{
		auto OceanWavePaint = OceanWaves::GetOceanWavePaint();
		if(OceanWavePaint == nullptr)
			return;

		Material::SetScalarParameterValue(OceanWaves::GetOceanWavePaint().GlobalParameters, n"OceanWavePaintGlobalTime", Time::PredictedGlobalCrumbTrailTime);
	}
}
#endif
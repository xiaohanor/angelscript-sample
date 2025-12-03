
UCLASS(Abstract)
class AGPUCollision : AHazeActor
{
	// The behaviour of this blueprint goes like this:
	// 1. the Scene Capture Component is placed above the player looking downwards.
	// 2. the Scene Capture Component renders the scene depth to an 8x8 render-texture
	// 3. Readback (copy to cpu memory) of the 8x8 texture is requested
	// 4. (some frames later) we loop over each depth value in the texture, and transform it into a world-space position and save it in an array.
	// 5. Now the 'positions' array is avilable for sampling with `SampleGPUCollision()`

	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

    UPROPERTY(DefaultComponent)
    USceneCaptureComponent2D SceneCaptureComp0;
    UPROPERTY(DefaultComponent)
    USceneCaptureComponent2D SceneCaptureComp1;
	UPROPERTY()
	TArray<USceneCaptureComponent2D> SceneCaptureComps;

    UPROPERTY(DefaultComponent)
	UHazeRenderTargetReadbackComponent ReadbackComp0;
    UPROPERTY(DefaultComponent)
	UHazeRenderTargetReadbackComponent ReadbackComp1;
	UPROPERTY()
	TArray<UHazeRenderTargetReadbackComponent> ReadbackComps;

	UPROPERTY()
    UTextureRenderTarget2D TextureTarget0;
	UPROPERTY()
    UTextureRenderTarget2D TextureTarget1;
	UPROPERTY()
	TArray<UTextureRenderTarget2D> TextureTargets;

	UPROPERTY()
	int ResolutionWidth = 8;

	UPROPERTY()
	TArray<FVector> Positions0;
	UPROPERTY()
	TArray<FVector> Positions1;
	
	UPROPERTY()
	float CaptureWidth = 200;

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UPROPERTY(EditAnywhere)
	bool bDebug;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		#if EDITOR
		Init();
		#endif
    }
	
	void Init()
	{
		SceneCaptureComps.Empty();
		SceneCaptureComps.Add(SceneCaptureComp0);
		SceneCaptureComps.Add(SceneCaptureComp1);
		ReadbackComps.Empty();
		ReadbackComps.Add(ReadbackComp0);
		ReadbackComps.Add(ReadbackComp1);
		TextureTargets.Empty();
		TextureTargets.Add(TextureTarget0);
		TextureTargets.Add(TextureTarget1);
		Positions0.Empty();
		Positions0.SetNumZeroed(ResolutionWidth * ResolutionWidth);
		Positions1.Empty();
		Positions1.SetNumZeroed(ResolutionWidth * ResolutionWidth);
		
		for (int i = 0; i < 2; i++)
		{
			TextureTargets[i] = Rendering::CreateRenderTarget2D(ResolutionWidth, ResolutionWidth, ETextureRenderTargetFormat::RTF_RGBA16f);
				
			SceneCaptureComps[i].TextureTarget = TextureTargets[i];
			SceneCaptureComps[i].CaptureSource = ESceneCaptureSource::SCS_SceneDepth;
			SceneCaptureComps[i].WorldRotation = FRotator(-90, 0, 0);
			SceneCaptureComps[i].ProjectionType = ECameraProjectionMode::Orthographic;
			SceneCaptureComps[i].OrthoWidth = CaptureWidth + (CaptureWidth * (1.0 / ResolutionWidth));
			SceneCaptureComps[i].SetbCaptureEveryFrame(false);

			SceneCaptureComps[i].PrimitiveRenderMode = ESceneCapturePrimitiveRenderMode::PRM_UseShowOnlyList;
			SceneCaptureComps[i].ShowOnlyActors.Empty();
			SceneCaptureComps[i].ShowOnlyActors.Add(TargetActor);
		}
	}
	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Init();

		// Override the IK traces for the players
		// This should be done when a player starts walking on a giant, and un-bind onnce they leave the giant
		// for (auto Player : Game::GetPlayers())
		// {
		// 	const auto FootTraceComp = UAnimFootTraceComponent::GetOrCreate(Player);
		// 	FootTraceComp.OverrideTraceDelegate.BindUFunction(this, n"ExampleOverrideFootTraces");
		// 	FootTraceComp.DelegateOverrideSlopeWarp.BindUFunction(this, n"ExampleOverrideSlopeWarp");
		// }
	}

	// returns `true` if collision was found at `InLocation`, saves result in `OutLocation` and `OutNormal`
	UFUNCTION()
	bool SampleGPUCollision(FVector InLocation, FVector& OutLocation, FVector& OutNormal)
	{
		if(bDebug)
		{
			Debug::DrawDebugPoint(InLocation, 16, FLinearColor(1,1,0));
		}
		
		// 1. first get the nearest quad
		auto player = Game::GetClosestPlayer(InLocation);
		int playerIndex = int(player.Player);

		FVector ReadbackLocation = FVector::ZeroVector;
		if(playerIndex == 0)
			ReadbackLocation = ReadbackLocation0;
		if(playerIndex == 1)
			ReadbackLocation = ReadbackLocation1;

		// 2. get the UVs
		FVector UV = ((ReadbackLocation - InLocation) / ((CaptureWidth)*0.5)) * 0.5 + FVector(0.5);
		UV = FVector(1-UV.Y, UV.X, 0);

		if(UV.X <= 0 || UV.X >= 1.0 || UV.Y <= 0 || UV.Y >= 1.0)
		{
			// requested position was outside of the plane
			return false;
		}
		
		TArray<FVector> Positions;
		if(playerIndex == 0)
			Positions = Positions0;
		if(playerIndex == 1)
			Positions = Positions1;

		if(Positions.Num() == 0)
		{
			// failsafe at the edges
			return false;
		}

		// 3. get the 4 nearset points
		UV *= ResolutionWidth - 1;
		int Index0X = Math::FloorToInt(UV.X);
		int Index0Y = Math::FloorToInt(UV.Y);
		int Index1X = Math::FloorToInt(UV.X+1);
		int Index1Y = Math::FloorToInt(UV.Y+1);
		int Q = ResolutionWidth - 1;
		Index0X = (Index0X >= Q) ? Q : Index0X;
		Index0Y = (Index0Y >= Q) ? Q : Index0Y;
		Index1X = (Index1X >= Q) ? Q : Index1X;
		Index1Y = (Index1Y >= Q) ? Q : Index1Y;
		
		FVector Pos00 = Positions[Index0X + Index0Y * ResolutionWidth];
		FVector Pos10 = Positions[Index1X + Index0Y * ResolutionWidth];
		FVector Pos01 = Positions[Index0X + Index1Y * ResolutionWidth];
		FVector Pos11 = Positions[Index1X + Index1Y * ResolutionWidth];
		if(bDebug)
		{
			Debug::DrawDebugPoint(Pos00, 4, FLinearColor(1, 0, 1));
			Debug::DrawDebugPoint(Pos10, 4, FLinearColor(1, 0, 1));
			Debug::DrawDebugPoint(Pos01, 4, FLinearColor(1, 0, 1));
			Debug::DrawDebugPoint(Pos11, 4, FLinearColor(1, 0, 1));
		}
		OutNormal = (Pos10 - Pos00).CrossProduct(Pos01 - Pos00);
		OutNormal.Normalize();

		float FracX = Math::Frac(UV.X);
		float FracY = Math::Frac(UV.Y);

		// 4. interpolate
		OutLocation = Math::Lerp(Math::Lerp(Pos00, Pos10, FracX), Math::Lerp(Pos01, Pos11, FracX), FracY);
		if(bDebug)
		{
			Debug::DrawDebugPoint(OutLocation, 16, FLinearColor(1,0,0));
			Debug::DrawDebugLine(OutLocation, OutLocation+OutNormal*50, FLinearColor(1,0,0));
		}
		return true;
	}
	
	FVector ReadbackLocation0 = FVector::ZeroVector;
	FVector ReadbackLocation1 = FVector::ZeroVector;
	TMap<uint, FVector> Camera0Fames;
	TMap<uint, FVector> Camera1Fames;

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Keep track of the last 10 camera locations.
		Camera0Fames.Add(Time::FrameNumber, Game::GetPlayers()[0].GetActorLocation() + FVector(0, 0, 200));
		Camera1Fames.Add(Time::FrameNumber, Game::GetPlayers()[1].GetActorLocation() + FVector(0, 0, 200));
		TArray<uint> RemoveThese;
		RemoveThese.Empty();
		for (auto It : Camera0Fames)
		{
			// If it's 10 frames old, remove it.
			if(Math::Abs(It.Key - Time::FrameNumber) > 10)
			{
				RemoveThese.Add(It.Key);
			}
		}
		for (uint i : RemoveThese)
		{
			Camera0Fames.Remove(i);
		}
		RemoveThese.Empty();
		for (auto It : Camera1Fames)
		{
			// If it's 10 frames old, remove it.
			if(Math::Abs(It.Key - Time::FrameNumber) > 10)
			{
				RemoveThese.Add(It.Key);
			}
		}
		for (uint i : RemoveThese)
		{
			Camera1Fames.Remove(i);
		}
		
		Positions0.Empty();
		Positions1.Empty();


		for (int i = 0; i < 2; i++)
		{
			AHazePlayerCharacter Player = Game::GetPlayers()[i];
			
			SceneCaptureComps[i].SetWorldLocation(Player.GetActorLocation() + FVector(0, 0, 200));

			ReadbackComps[i].RequestReadback(TextureTargets[i]);
			if (ReadbackComps[i].HasReadbackData())
			{
				uint ReadbackFrame = ReadbackComps[i].GetLatestReadbackFrame();
				const TArray<FVector4f>& CpuSideData = ReadbackComps[i].GetLatestReadbackData();
				FVector ReadbackLocation = FVector::ZeroVector;
				if(i == 0)
				{
					ReadbackLocation0 = Camera0Fames[ReadbackFrame];
					ReadbackLocation = ReadbackLocation0;
				}
				if(i == 1)
				{
					ReadbackLocation1 = Camera1Fames[ReadbackFrame];
					ReadbackLocation = ReadbackLocation1;
				}
				
				for (int x = 0; x < ResolutionWidth; x++)
				{
					for (int y = 0; y < ResolutionWidth; y++)
					{
						int j = (x * ResolutionWidth) + (y);
						FVector Pos01 = FVector(x, y, 0) / (ResolutionWidth-1);
						Pos01 -= FVector::OneVector * 0.5;
						Pos01 *= FVector(1, -1, 1);
						Pos01 *= CaptureWidth;
						Pos01.Z = 0;
						
						FVector Pos = ReadbackLocation - Pos01;

						Pos -= FVector(0, 0, CpuSideData[j].X);
						if(i == 0)
							Positions0.Add(Pos);
						if(i == 1)
							Positions1.Add(Pos);
					}
				}
			}
		}

		if(bDebug)
		{
			for(FVector Vector : Positions0)
			{
				Debug::DrawDebugPoint(Vector, 8, FLinearColor(0,0,1));
			}
			for(FVector Vector : Positions1)
			{
				Debug::DrawDebugPoint(Vector, 8, FLinearColor(0,0,1));
			}

			FVector Location;
			FVector Normal;
			SampleGPUCollision(Game::GetPlayer(EHazePlayer::Mio).Mesh.GetSocketLocation(n"LeftFoot"), Location, Normal);
			SampleGPUCollision(Game::GetPlayer(EHazePlayer::Mio).Mesh.GetSocketLocation(n"RightFoot"), Location, Normal);
			SampleGPUCollision(Game::GetPlayer(EHazePlayer::Zoe).Mesh.GetSocketLocation(n"LeftFoot"), Location, Normal);
			SampleGPUCollision(Game::GetPlayer(EHazePlayer::Zoe).Mesh.GetSocketLocation(n"RightFoot"), Location, Normal);
		}


		
	}


	UFUNCTION()
	void ExampleOverrideFootTraces(FHazeAnimIKFeetPlacementTraceDataInput& TraceInputData, AHazeCharacter Character)
	{
		TraceInputData.TraceStartEndHeight.X = -50;
		TraceInputData.TraceStartEndHeight.Y = 50;

		for (auto& Data : TraceInputData.TraceData)
		{
			const FVector FootLocation = Character.Mesh.GetSocketLocation(Data.BoneName);

			const FVector Location = Math::LinePlaneIntersection(FootLocation, 
													   FootLocation - Character.ActorUpVector,
													   Character.ActorLocation,
													   Character.ActorUpVector 
													   );

			Data.GroundData.TraceStart = Location + (Character.ActorUpVector*(TraceInputData.TraceStartEndHeight.Y));
			Data.GroundData.TraceEnd = Location + (Character.ActorUpVector*(TraceInputData.TraceStartEndHeight.X));

			SampleGPUCollision(
				Data.GroundData.TraceStart,
			 	Data.GroundData.ImpactPoint, 
			 	Data.GroundData.ImpactNormal
			);

			Data.ComponentTransformAtTrace = Character.ActorTransform;
			Data.GroundData.bBlockingHit = true;
			Data.bInterpolatePositionInWS = false;
		}
	}

	UFUNCTION()
	void ExampleOverrideSlopeWarp(FHazeSlopeWarpingData &Data, AHazeCharacter Character)
	{
		bDebug = false;

		Data.ActorVelocity = Character.ActorVelocity;
		Data.bBlockingHit = true;
		Data.OverrideMaxStepHeight = 60;

		// TODO: We could sample 3-5 points and do an average for a smoother result if needed
		SampleGPUCollision(
			Character.ActorLocation,
			Data.ImpactPoint, 
			Data.ImpactNormal
		);

		// Clamp max distance to prevent it from disabling
		// TODO: This should probably be the default behaviour in the AnimNode?
		if ((Data.ImpactPoint - Character.ActorLocation).Size() > Data.OverrideMaxStepHeight)
			Data.ImpactPoint = Character.ActorLocation + (Data.ImpactPoint - Character.ActorLocation).GetUnsafeNormal() * (Data.OverrideMaxStepHeight - 1);
	}

}
class AGameShowArenaSceneCaptureMonitor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D WallSceneCaptureComp;
	default WallSceneCaptureComp.CaptureSource = ESceneCaptureSource::SCS_SceneDepth;
	default WallSceneCaptureComp.bCaptureEveryFrame = false;
	default WallSceneCaptureComp.bCaptureOnMovement = false;
	default WallSceneCaptureComp.FOVAngle = 60;
	default WallSceneCaptureComp.bConsiderUnrenderedOpaquePixelAsFullyTranslucent = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MonitorMesh;

	// Target that the camera draws to
	UTextureRenderTarget2D WallSceneCaptureTarget;

	UMaterialInstanceDynamic RenderTargetMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WallSceneCaptureTarget = Rendering::CreateRenderTarget2D(320, 180, ETextureRenderTargetFormat::RTF_RGB10A2);

		RenderTargetMaterial = MonitorMesh.CreateDynamicMaterialInstance(0);
		RenderTargetMaterial.SetTextureParameterValue(n"TexM2", WallSceneCaptureTarget);
		WallSceneCaptureComp.TextureTarget = WallSceneCaptureTarget;
		//Print(f"{WallSceneCaptureComp.FOVAngle=}", 5);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto ClosestBomb = GameShowArena::GetClosestEnabledBombToLocation(WallSceneCaptureComp.WorldLocation);
		if (ClosestBomb == nullptr)
			return;
		WallSceneCaptureComp.WorldRotation = FRotator::MakeFromXZ(ClosestBomb.ActorLocation - WallSceneCaptureComp.WorldLocation, FVector::UpVector);
		WallSceneCaptureComp.CaptureScene();
	}
};
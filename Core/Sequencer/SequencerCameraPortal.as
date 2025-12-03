
UCLASS(Abstract)
class ASequencerCameraPortal : AHazeActor 
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	
	UPROPERTY()
	AHazeLevelSequenceActor sequence;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USequencerCameraPortalComponent SequencerCameraPortalComponent;

	UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D PortalCamera;

	//UPROPERTY(EditAnywhere, meta = (MakeEditWidget))
    //FVector PortalWorldOrigin = FVector(0, 0, 0);

	UPROPERTY(EditAnywhere)
	AStaticMeshActor PortalMesh;

	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D PortalTexture;

	UPROPERTY(EditAnywhere)
	AActor WhitespaceCamera;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void Init()
	{
		if(PortalMesh == nullptr)
			return;
        FIntVector2 Resolution = FIntVector2(1920, 1080);
		PortalTexture = Rendering::CreateRenderTarget2D(Resolution.X, Resolution.Y, ETextureRenderTargetFormat::RTF_RGBA8);
		PortalCamera.TextureTarget = PortalTexture;
		
		PortalMesh.StaticMeshComponent.SetScalarParameterValueOnMaterials(n"Test", 0);
		for (auto Material : PortalMesh.StaticMeshComponent.GetMaterials())
		{
			auto DyamicMaterial =  Cast<UMaterialInstanceDynamic>(Material);
			DyamicMaterial.SetTextureParameterValue(n"TargetTexture", PortalTexture);
		}
	}

	UPROPERTY(EditAnywhere)
	bool bInitialized = false;
	
	void TickInEditor()
	{
		if(PortalMesh == nullptr)
		{
			bInitialized = false;
			return;
		}
		if(WhitespaceCamera == nullptr)
		{
			bInitialized = false;
			return;
		}
		
		if(!bInitialized)
		{
			bInitialized = true;
			Init();
		}
		
		FTransform WhitespaceToPortal = (WhitespaceCamera.GetActorTransform() * PortalMesh.GetActorTransform().Inverse());

		PortalCamera.SetWorldTransform(WhitespaceToPortal * this.GetActorTransform());

		//PortalCamera.SetWorldTransform(Game::Mio.GetViewTransform());
		//PortalCamera.SetWorldLocation(PortalWorldOrigin);
		//Transform newTransform 
		//PortalCamera.SetWorldTransform();
	}
}

class USequencerCameraPortalComponent : USceneComponent
{
	default bTickInEditor = true;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto SequencerGlobalPostProcess = Cast<ASequencerCameraPortal>(Owner);
		SequencerGlobalPostProcess.TickInEditor();
	}

};


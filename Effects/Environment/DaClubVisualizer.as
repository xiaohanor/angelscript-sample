UCLASS(Abstract)
class ADaClubVisualizer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDaClubVisualizerTickInEditorComponent TickInEditorComponent;

	UPROPERTY()
	bool bEnabled = false;

	UPROPERTY()
	UTextureRenderTarget2D Target;

	UPROPERTY()
	UTextureRenderTarget2D Current;

	UPROPERTY()
	UTextureRenderTarget2D Previous;
	
	UPROPERTY(EditAnywhere)
	UMaterialInterface SimulationStep;
	
	UPROPERTY()
	UMaterialInstanceDynamic SimulationStepDynamic;
	
	UPROPERTY(EditAnywhere)
    int ResolutionX = 1024;

	UPROPERTY(EditAnywhere)
    int ResolutionY = 256;
	
	void Start()
	{
		SimulationStepDynamic = Material::CreateDynamicMaterialInstance(this, SimulationStep);

		Current = Rendering::CreateRenderTarget2D(int(ResolutionX), int(ResolutionY));
		Current.AddressX = TextureAddress::TA_Clamp;
		Current.AddressY = TextureAddress::TA_Clamp;
		Rendering::ClearRenderTarget2D(Current, FLinearColor(0, 0, 0, 0));

		Previous = Rendering::CreateRenderTarget2D(int(ResolutionX), int(ResolutionY));
		Previous.AddressX = TextureAddress::TA_Clamp;
		Previous.AddressY = TextureAddress::TA_Clamp;
		Rendering::ClearRenderTarget2D(Previous, FLinearColor(0, 0, 0, 0));

		auto MusicManager = UHazeAudioMusicManager::Get();
		if(MusicManager != nullptr)
		{
			MusicManager.OnMainMusicBeat().AddUFunction(this, n"OnMusicBeat");
		}
			
	}

	float BeatStrength;
	UFUNCTION()
	void OnMusicBeat()
	{
		BeatStrength = 1.0;
	}

	void Update(float DeltaSeconds)
	{
		if(!bEnabled)
			return;
		
		if(Current == nullptr)
		{
			Start();
		}

		if(BeatStrength > 0)
			BeatStrength -= DeltaSeconds;
		else
			BeatStrength = 1;
			
		// swap
		UTextureRenderTarget2D Temp = Current;
		Current = Previous;
		Previous = Temp;

		SimulationStepDynamic.SetTextureParameterValue(n"Texture", Previous);
		SimulationStepDynamic.SetScalarParameterValue(n"BeatStrength", BeatStrength*BeatStrength);

		Rendering::DrawMaterialToRenderTarget(Current, SimulationStepDynamic);

		if(Target != nullptr)
			Rendering::DrawMaterialToRenderTarget(Target, SimulationStepDynamic);
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Start();
	}
	
	void TickInEditor(float DeltaSeconds)
	{
		Update(DeltaSeconds);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Update(DeltaSeconds);
	}
}

class UDaClubVisualizerTickInEditorComponent : USceneComponent
{
	default bTickInEditor = true;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto SequencerGlobalPostProcess = Cast<ADaClubVisualizer>(Owner);
		SequencerGlobalPostProcess.TickInEditor(DeltaSeconds);
	}

};

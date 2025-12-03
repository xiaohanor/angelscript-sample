
UCLASS(Abstract)
class UMovement_Foliage_SoundDef : UFoliage_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable, BlueprintReadWrite, Category = "Event Instance")
	FHazeAudioPostEventInstance CurrentFoliageEventInstance;

	UPROPERTY(EditDefaultsOnly, Category = "Events", DisplayName = "Event - Enter - Grass")
	UHazeAudioEvent EventEnterGrass;	

	UPROPERTY(EditDefaultsOnly, Category = "Events", DisplayName = "Event - Loop - Grass")
	UHazeAudioEvent EventLoopGrass;

	UPROPERTY(EditDefaultsOnly, Category = "Events", DisplayName = "Event - Enter - Bush")
	UHazeAudioEvent EventEnterBush;
	
	UPROPERTY(EditDefaultsOnly, Category = "Events", DisplayName = "Event - Loop - Bush")
	UHazeAudioEvent EventLoopBush;

	UPROPERTY(EditDefaultsOnly, Category = "Events", DisplayName = "Event - Enter - Plant")
	UHazeAudioEvent EventEnterPlant;
	
	UPROPERTY(EditDefaultsOnly, Category = "Events", DisplayName = "Event - Loop - Plant")
	UHazeAudioEvent EventLoopPlant;

	UPROPERTY(EditDefaultsOnly, Category = "Main")
	UHazeAudioActorMixer FoliageActorMixer;

	UPROPERTY(EditDefaultsOnly, Category = "Main", DisplayName = "Main - Foliage Gain", Meta = (ForceUnits = "db"))
	float MainFoliageGain;

	UPROPERTY(EditDefaultsOnly, Category = "Main", DisplayName = "Main - Foliage Pitch", Meta = (ForceUnits = "cent"))
	float MainFoliagePitch;

	UPROPERTY(EditDefaultsOnly, Category = "Logic|Velocity", DisplayName = "Velocity - Linear Normalization Range", Meta = (ForceUnits = "cm"))
	float LinearVelocityNormalizationRange = 750;

	UPROPERTY(EditDefaultsOnly, Category = "Logic|Velocity", DisplayName = "Velocity - Linear Delta Normalization Range", Meta = (ForceUnits = "cm"))
	float LinearVelocityDeltaNormalizationRange = 1000;

	UPROPERTY(EditDefaultsOnly, Category = "Logic|Velocity", DisplayName = "Velocity - Slew Attack", Meta = (ForceUnits = "seconds"))
	float VelocitySlewAttack = 0.1;

	UPROPERTY(EditDefaultsOnly, Category = "Logic|Velocity", DisplayName = "Velocity - Slew Release", Meta = (ForceUnits = "seconds"))
	float VelocitySlewRelease = 0.3;

	UPROPERTY(EditDefaultsOnly, Category = "Logic|Velocity", DisplayName = "Velocity - Gain Min", Meta = (ForceUnits = "times"))
	float LinearVelocityGainMin = 0;

	UPROPERTY(EditDefaultsOnly, Category = "Logic|Velocity", DisplayName = "Velocity - Gain Max", Meta = (ForceUnits = "times"))
	float LinearVelocityGainMax = 1;

	UPROPERTY(EditDefaultsOnly, Category = "Logic|Velocity", DisplayName = "Velocity - Pitch Min", Meta = (ForceUnits = "cent"))
	float LinearVelocityPitchMin = 0;

	UPROPERTY(EditDefaultsOnly, Category = "Logic|Velocity", DisplayName = "Velocity - Pitch Max", Meta = (ForceUnits = "cent"))
	float LinearVelocityPitchMax = 0;

	UPROPERTY(EditDefaultsOnly, Category = "Logic|Velocity", DisplayName = "Velocity - Delta Pitch Min", Meta = (ForceUnits = "cent"))
	float LinearVelocityDeltaPitchMin = 0;

	UPROPERTY(EditDefaultsOnly, Category = "Logic|Velocity", DisplayName = "Velocity - Delta Pitch Max", Meta = (ForceUnits = "cent"))
	float LinearVelocityDeltaPitchMax = 0;

	UPROPERTY(EditDefaultsOnly, Category = "Logic", DisplayName = "FadeOut - Grass", Meta = (ForceUnits = "ms"))
	int GrassFadeOutTimeMilliseconds = 500;
	
	UPROPERTY(EditDefaultsOnly, Category = "Logic", DisplayName = "FadeOut - Bush", Meta = (ForceUnits = "ms"))
	int BushFadeOutTimeMilliseconds = 500;

	UPROPERTY(EditDefaultsOnly, Category = "Logic", DisplayName = "FadeOut - Plant", Meta = (ForceUnits = "ms"))
	int PlantFadeOutTimeMilliseconds = 500;

	UPROPERTY(NotEditable, BlueprintReadWrite, Category = "Logic")
	int CurrentFadeOutTime;

	UPROPERTY(NotEditable, BlueprintReadWrite, Category = "Logic|Velocity")
	float LinearVelocityNormalized;

	UPROPERTY(NotEditable, BlueprintReadWrite, Category = "Logic|Velocity")
	float LinearVelocityDeltaNormalized;

	private FFoliageDetectionData CurrentFoliageData;
	private float PreviousMakeupAlpha = -1;
	FHazeAudioID Rtpc_Global_Shared_Foliage_Volume = FHazeAudioID("Rtpc_Global_Shared_Foliage_Volume");

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Super::ParentSetup();

		// Ensure PlayerOwner, SoundDef might live on some other actor
		if(PlayerOwner != nullptr)
			return;

		// Add component-specific lookups here, i.e for dragons, Tundra animals etc.
	}

	UFUNCTION(BlueprintOverride)
	void FoliageOverlapEvent(FFoliageDetectionData Data)
	{
		const bool bNewOverlap = !CurrentFoliageData.bIsOverlappingFoliage;

		CurrentFoliageData = Data;	
		OnFoliageOverlap(Data, bNewOverlap);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (FoliageComponent != nullptr && PreviousMakeupAlpha != FoliageComponent.MakeupGainAlpha)
		{
			DefaultEmitter.SetRTPC(Rtpc_Global_Shared_Foliage_Volume, FoliageComponent.MakeupGainAlpha, 100);
			PreviousMakeupAlpha = FoliageComponent.MakeupGainAlpha;
		}

		if(!CurrentFoliageData.bIsOverlappingFoliage)
			return;

		TickInFoliage(DeltaSeconds, CurrentFoliageData.Type);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFoliageOverlap(FFoliageDetectionData Data, bool bNewOverlap) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TickInFoliage(float DeltaSeconds, const EFoliageDetectionType& Type) {}
}
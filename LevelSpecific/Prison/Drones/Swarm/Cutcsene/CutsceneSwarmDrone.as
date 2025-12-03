

UCLASS(Abstract)
class ACutsceneSwarmDrone : AHazeCutscenePrisonDrone
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent MeshOffsetComponent;

	UPROPERTY(DefaultComponent, EditDefaultsOnly, Attach = MeshOffsetComponent)
	UHazeSkeletalMeshComponentBase SwarmGroupMeshComponent;
	default SwarmGroupMeshComponent.SetRelativeLocation(FVector::UpVector);
	default SwarmGroupMeshComponent.SetWorldScale3D(FVector::OneVector * Drone::CutsceneDroneScale);

	UPROPERTY(DefaultComponent)
	UPointLightComponent PointLightComponent;
	default	PointLightComponent.SetRelativeLocation(FVector::UpVector * 5.0);
	default PointLightComponent.SetCastShadows(false);


#if EDITOR
	default SwarmGroupMeshComponent.bUpdateAnimationInEditor = true;
#endif

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASwarmBot> SwarmBotClass;

	UPROPERTY(NotEditable, BlueprintHidden, Transient)
	TArray<FCutsceneSwarmBotData> SwarmBots;

	UPROPERTY(DefaultComponent)
	UCutsceneSwarmDroneMovementResponseComponent MovementResponseComponent;


	// Used to save and playback cutscene data
	UPROPERTY(EditInstanceOnly)
	UCutsceneSwarmDroneDataAsset CutsceneDataAsset = nullptr;


	uint CurrentRecordFrame = 1;

	const float SwarmDroneOriginalRadius = MagnetDrone::Radius;
	const float SwarmDroneVisualRadius = MagnetDrone::Radius * 0.5;

	float PointLightIntensity = 300.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
	}

	void Initialize()
	{
		PointLightIntensity = PointLightComponent.Intensity;

		SwarmBots.Empty();

		for (int i = 0; i < SwarmDrone::TotalBotCount; i++)
		{
			FCutsceneSwarmBotData SwarmBot(i);

			FVector RelativeLocation = SwarmDrone::GetSwarmBotRelativeLocationOnDroneMesh(i, SwarmDroneOriginalRadius);
			SwarmBot.OriginalRelativeTransform.SetLocation(RelativeLocation);
			SwarmBot.OriginalRelativeTransform.SetRotation(FQuat::MakeFromZ(RelativeLocation));
			SwarmBot.OriginalRelativeTransform.SetScale3D(FVector(SwarmBot.bRetracedInnerLayer ? 1.8 : SwarmDrone::SwarmBotScale));

			SwarmBot.RelativeTransform = SwarmBot.OriginalRelativeTransform;
			SwarmBot.AcceleratedRelativeRotation.SnapTo(SwarmBot.OriginalRelativeTransform.Rotation);

			SwarmBots.Add(SwarmBot);
		}

		InitializeAnimInstance();
		MovementResponseComponent.Initialize();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnSequencerRecordStart()
	{
		// // Eman TOOD: UXR hax
		// return;

		if (CutsceneDataAsset == nullptr)
			return;

		//if (!IsInitialized())
		Initialize();

		// Clear data asset
		CutsceneDataAsset.Reset();

		CurrentRecordFrame = 1;
		Modify();
	}

	UFUNCTION(BlueprintOverride)
	void OnSequencerRecord(FHazeSequencerRecordParams TickParams)
	{
		// // Eman TODO: Uxr hax
		// return;

		if (CutsceneDataAsset == nullptr)
			return;

		// Update actor transform and bots
		FCutsceneSwarmDroneMoveData MoveData;
		MoveData.DeltaTime = TickParams.DeltaTime;
		MovementResponseComponent.UpdateMovement(MoveData);

		// Make'n save frame
		// FCutsceneSwarmDroneFrame Frame(CurrentRecordFrame, TickParams);
		// Frame.RecordActorInfo(SwarmGroupMeshComponent.WorldTransform);
		// Frame.RecordBotInfo(SwarmBots);
		// CutsceneDataAsset.WriteFrame(Frame);

		// Light solution test
		{
			CutsceneDataAsset.WriteFrame_Light(SwarmBots, FRotator3f(SwarmGroupMeshComponent.WorldRotation), TickParams.TimeFromSectionStart);
		}

		Console::ExecuteConsoleCommand("Frame: " + CurrentRecordFrame) ;

		CurrentRecordFrame++;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnSequencerEvaluation(FHazeSequencerEvalParams EvaluationParams)
	{
		// Eman TODO: UXR hax
		if (!IsInitialized())
			Initialize();

		// Use asset if we can
		if (CutsceneDataAsset != nullptr)
		{
			FCutsceneSwarmDroneFrame BlendedFrame = CutsceneDataAsset.GetFrameAtTime(EvaluationParams.TimeFromSectionStart);
			ApplyFrame(BlendedFrame);
		}
		// Otherwise just generate movement
		else
		{
			if (!IsInitialized())
				Initialize();

			FCutsceneSwarmDroneMoveData MoveData;
			MoveData.DeltaTime = EvaluationParams.DeltaTime;
			MovementResponseComponent.UpdateMovement(MoveData);
		}

		// Update point light
		float Intensity = Math::Max(PointLightIntensity * 0.33, Math::Abs(Math::Sin(EvaluationParams.TimeFromSectionStart)) * PointLightIntensity);
		PointLightComponent.SetIntensity(Intensity);
	}

	private void ApplyFrame(FCutsceneSwarmDroneFrame Frame)
	{
		// Load frame data onto actor
		Frame.LoadFrame(this);
	}

	FVector GetDroneCenter() const property
	{
		return SwarmGroupMeshComponent.WorldLocation;
	}

	bool IsInitialized() const
	{
		return !SwarmBots.IsEmpty() && MovementResponseComponent.IsInitialized();
	}
}

asset Sheet_Prison_Drones_CutsceneSwarmDrone of UHazeCapabilitySheet
{
	// Capabilities.Add(UCutsceneSwarmDroneGroupMeshUpdateCapability);
	// Capabilities.Add(UCutsceneSwarmDroneBotMovementCapability);
	// Capabilities.Add(UCutsceneSwarmDroneUpdateMeshRotationCapability);
	// Capabilities.Add(UCutsceneSwarmDroneDebugCapability);
}
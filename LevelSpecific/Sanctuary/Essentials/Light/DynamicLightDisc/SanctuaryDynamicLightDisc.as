UCLASS(Abstract)
class ASanctuaryDynamicLightDisc : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USanctuaryDynamicLightDiscComponent DynamicLightDiscComponent;

	UPROPERTY(DefaultComponent)
	UPointLightComponent PointLightComponent;

	UPROPERTY(DefaultComponent)
	UHazeSphereComponent HazeSphereComponent;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryLightDiscMeshAudioComponent AudioMeshComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	/**
	 * By default, movement only follows light discs vertically.
	 * This allows us to run on top of the light surface without following the actual socket.
	 */
	UPROPERTY(EditAnywhere, Category = "Light Disc")
	bool bFollowHorizontally = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird Response")
	bool bListenToParentLightBirdResponse = true;

	FHazeAcceleratedFloat AcceleratedFloat;

	UMaterialInstanceDynamic MID;
	FLinearColor Color;
	FLinearColor Color_02;
	float InitialLightIntensity = 0.0;
	float InitialHazeSphereOpacity = 0.0;

	bool bIsActivated = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		if (GetWorld() != nullptr)
			DynamicLightDiscComponent.Preview();
#endif

		HazeSphereComponent.ConstructionScript_Hack();

		if(bFollowHorizontally)
			DynamicLightDiscComponent.AddTag(ComponentTags::InheritHorizontalMovementIfGround);
		else
			DynamicLightDiscComponent.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		if (bListenToParentLightBirdResponse && AttachParentActor != nullptr)
			LightBirdResponseComponent.AddListenToResponseActor(AttachParentActor);

		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");

//		PointLightComponent.SetVisibility(false);
//		HazeSphereComponent.SetVisibility(false);

		MID = DynamicLightDiscComponent.CreateDynamicMaterialInstance(0);
		Color = MID.GetVectorParameterValue(n"Color");
		Color_02 = MID.GetVectorParameterValue(n"Color_02");

		InitialLightIntensity = PointLightComponent.Intensity;
		InitialHazeSphereOpacity = HazeSphereComponent.Opacity;

		for(auto Player : Game::Players)
			Player.ApplyResolverExtension(USanctuaryDynamicLightDiscResolverExtension, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(auto Player : Game::Players)
			Player.ClearResolverExtension(USanctuaryDynamicLightDiscResolverExtension, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedFloat.AccelerateTo((bIsActivated ? 1.0 : 0.0), (bIsActivated ? 0.5 : 0.25), DeltaSeconds);
		MID.SetVectorParameterValue(n"Color", Color * AcceleratedFloat.Value);
		MID.SetVectorParameterValue(n"Color_02", Color_02 * AcceleratedFloat.Value);
		PointLightComponent.SetIntensity(InitialLightIntensity * AcceleratedFloat.Value);
		HazeSphereComponent.SetOpacityValue(InitialHazeSphereOpacity * AcceleratedFloat.Value);
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		bIsActivated = true;

		DynamicLightDiscComponent.Enable();		
//		PointLightComponent.SetVisibility(true);
//		HazeSphereComponent.SetVisibility(true);
	}

	UFUNCTION()
	private void OnUnilluminated()
	{
		bIsActivated = false;

		DynamicLightDiscComponent.Disable();
//		PointLightComponent.SetVisibility(false);
//		HazeSphereComponent.SetVisibility(false);
	}
}

class USanctuaryLightDiscMeshAudioComponent : USanctuaryLightMeshAudioComponent
{
	ASanctuaryDynamicLightDisc LightDisc;
	private TPerPlayer<FVector> PreviousPlayerPos;
	FHazeRuntimeSpline PositionSpline;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightDisc = Cast<ASanctuaryDynamicLightDisc>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void GetLightMeshAudioPositions(TArray<FAkSoundPosition>& outPositions)
	{
		outPositions.Empty();

		for(auto Player : Game::GetPlayers())
		{
			if(!TrackPlayer[Player])
				continue;

			float ClosestPlayerPosSqrd = MAX_flt;		
			int NumVertices = LightDisc.DynamicLightDiscComponent.GetVertices().Num();
			int ClosestVertIndex = -1;

			for(int i = 1; i < NumVertices; ++i)
			{
				auto Vertex = LightDisc.DynamicLightDiscComponent.GetVertices()[i];		

				auto VertexWorldPos = LightDisc.ActorLocation + Vertex;
				auto DistSqrd = VertexWorldPos.DistSquared(Player.ActorLocation);
				if(DistSqrd < ClosestPlayerPosSqrd)
				{
					ClosestPlayerPosSqrd = DistSqrd;
					ClosestVertIndex = i;
				}
			}

			auto ClosestVertex = LightDisc.ActorLocation + LightDisc.DynamicLightDiscComponent.GetVertices()[ClosestVertIndex];
			auto VertToCenterDistSqrd = ClosestVertex.DistSquared(LightDisc.ActorLocation);
			auto PlayerToCenterDistSqrd = Player.ActorLocation.DistSquared(LightDisc.ActorLocation);

			FVector ClosestPlayerPos;
			if(PlayerToCenterDistSqrd < VertToCenterDistSqrd)
				ClosestPlayerPos = Player.ActorLocation;
			else
			{
				auto PrevVertIndex = ClosestVertIndex != 1 ? ClosestVertIndex - 1 : NumVertices - 1;
				auto NextVertIndex = ClosestVertIndex < NumVertices - 1 ? ClosestVertIndex + 1 : 1;

				auto PreviousVert = LightDisc.ActorLocation + LightDisc.DynamicLightDiscComponent.GetVertices()[PrevVertIndex];
				auto NextVert = LightDisc.ActorLocation + LightDisc.DynamicLightDiscComponent.GetVertices()[NextVertIndex];
				TArray<FVector> SplinePoints;

				SplinePoints.Add(PreviousVert);
				SplinePoints.Add(ClosestVertex);
				SplinePoints.Add(NextVert);			

				PositionSpline.SetPoints(SplinePoints);
				ClosestPlayerPos = PositionSpline.GetClosestLocationToLocation(Player.ActorLocation);							
			}

			ClosestPlayerPos.Z = LightDisc.ActorLocation.Z;
			outPositions.Add(FAkSoundPosition(ClosestPlayerPos));

			PreviousPlayerPos[Player] = ClosestPlayerPos;
		}		
	}
}
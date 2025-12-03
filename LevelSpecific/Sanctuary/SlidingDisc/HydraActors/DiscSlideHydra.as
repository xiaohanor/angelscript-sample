class ADiscSlideHydra : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkeletalMesh; 

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent TriggerComp;

	UPROPERTY(EditAnywhere)
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(DefaultComponent)
    UHazeMeshPoseDebugComponent MeshPoseDebugComponent;

	UPROPERTY(EditInstanceOnly)
	bool bHasDiscCollision = false;

	UPROPERTY(EditInstanceOnly)
	bool bMouthKill = false;

	UPROPERTY(EditAnywhere)
	float GrindRadius = 2000.0;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh, AttachSocket = "Tongue8")
	USphereComponent MouthDeathSphere;
	default MouthDeathSphere.CollisionEnabled = ECollisionEnabled::NoCollision;
	default MouthDeathSphere.AddLocalOffset(FVector(0.0, 0.0, 200.0));
	default MouthDeathSphere.SphereRadius = 1300.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ADiscSlideHydraSurface> SurfaceActorClass;

	UPROPERTY(BlueprintReadWrite)
	ADiscSlideHydraSurface SurfaceActor = nullptr;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeSkeletalMeshActor> AdditionalAnimActors;

	UDiscSlideHydraGrindComponent TriggerGrindingComp = nullptr;

	ASlidingDisc CachedSlidingDisc = nullptr;

	bool bHasGrindSplineAlongBack = false;
	bool bManuallyHopOffGrind = false;

	UPROPERTY(EditInstanceOnly)
	TArray<FDiscSlideHydraEffectData> SperringLevelEffects;
	UHazeActionQueueComponent QueueComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggerBeginOverlap");
		TriggerGrindingComp = UDiscSlideHydraGrindComponent::Get(this);
		bHasGrindSplineAlongBack = TriggerGrindingComp != nullptr;
		if (bHasGrindSplineAlongBack || bHasDiscCollision)
		{
			if (SurfaceActorClass.IsValid())
			{
				// not networked!
				SurfaceActor = SpawnActor(SurfaceActorClass, SkeletalMesh.WorldLocation, SkeletalMesh.WorldRotation);
				SurfaceActor.bHasSpline = bHasGrindSplineAlongBack;
				SurfaceActor.GrindRadius = GrindRadius;
				if (!bHasDiscCollision)
					SurfaceActor.SkeletalMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			}
		}
		OnBeginPlay();
		QueueComp = UHazeActionQueueComponent::Create(this, n"AnimationEffectsQueue");
	}

	UFUNCTION(BlueprintPure)
	bool HasSurfaceActor() const
	{
		return SurfaceActor != nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void OnBeginPlay() {}

	UFUNCTION()
	void TriggerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		BP_Triggered();

		for (AHazeSkeletalMeshActor SkeletalMeshActor : AdditionalAnimActors)
		{
			if (SkeletalMeshActor != nullptr)
			{
				SkeletalMeshActor.PlaySlotAnimation(Cast<UAnimSequence>(SkeletalMeshActor.Mesh.AnimationData.AnimToPlay), FHazeSlotAnimSettings());
			}
		}
		QueueEffectEvents();
	}

	private void QueueEffectEvents()
	{
		if (!QueueComp.IsEmpty())
			return;
		TArray<FDiscSlideHydraEffectEventData> EventDatas;
		for (FDiscSlideHydraEffectData EffectsData : SperringLevelEffects)
		{
			if (EffectsData.Effect == nullptr)
				continue;
			if (EffectsData.AnimationActivateTime >= -KINDA_SMALL_NUMBER)
			{
				FDiscSlideHydraEffectEventData ActivateData;
				ActivateData.Effect = EffectsData.Effect;
				ActivateData.HydraOptionalBoneName = EffectsData.HydraOptionalBoneName;
				ActivateData.EventTime = EffectsData.AnimationActivateTime;
				ActivateData.bActivate = true;
				EventDatas.Add(ActivateData);
			}
			if (EffectsData.AnimationDeactivateTime >= -KINDA_SMALL_NUMBER)
			{
				FDiscSlideHydraEffectEventData ActivateData;
				ActivateData.Effect = EffectsData.Effect;
				ActivateData.EventTime = EffectsData.AnimationDeactivateTime;
				ActivateData.bActivate = false;
				EventDatas.Add(ActivateData);
			}
		}
		EventDatas.Sort();
		float CurrentTime = 0.0;
		for (int iEvent = 0; iEvent < EventDatas.Num(); ++iEvent)
		{
			FDiscSlideHydraEffectEventData EventData = EventDatas[iEvent];
			float TimeDiff = EventData.EventTime - CurrentTime;
			if (TimeDiff > KINDA_SMALL_NUMBER)
				QueueComp.Idle(TimeDiff);
			QueueComp.Event(this, n"TriggerEffectEvent", EventData);
			CurrentTime = EventData.EventTime;
		}
	}

	UFUNCTION()
	private void TriggerEffectEvent(FDiscSlideHydraEffectEventData EffectEventData)
	{
		if (EffectEventData.Effect == nullptr)
			return;

		if (!EffectEventData.HydraOptionalBoneName.IsNone())
			EffectEventData.Effect.AttachToComponent(SkeletalMesh, EffectEventData.HydraOptionalBoneName);

		if (EffectEventData.bActivate)
			EffectEventData.Effect.NiagaraComponent0.Activate();
		else
			EffectEventData.Effect.NiagaraComponent0.Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Triggered() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bMouthKill)
			HandleMouthKilling();
	}

	private void HandleMouthKilling()
	{
		if (CachedSlidingDisc == nullptr)
		{
			TListedActors<ASlidingDisc> SlidingDiscs;
			CachedSlidingDisc = SlidingDiscs.Single;
		}
		
		if (CachedSlidingDisc == nullptr || CachedSlidingDisc.bDisintegrated)
			return;

		if (CachedSlidingDisc.ActorLocation.Distance(MouthDeathSphere.WorldLocation) < MouthDeathSphere.SphereRadius)
			CachedSlidingDisc.DisintegrateHahahaha();

		if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
			Debug::DrawDebugSphere(MouthDeathSphere.WorldLocation, MouthDeathSphere.SphereRadius, 12, ColorDebug::Ruby, 5.0, 0.0, true);
	}
}
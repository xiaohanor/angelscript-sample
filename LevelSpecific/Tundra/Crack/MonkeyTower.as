UCLASS(Abstract)
class AMonkeyTower : ATundraStickObstacle
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent CollisionComp;
	default CollisionComp.CollisionProfileName = n"OverlapAllDynamic";
	default CollisionComp.RelativeLocation = FVector(0.0, 0.0, 8990.0);
	default CollisionComp.SphereRadius = 6000.0;

	UPROPERTY(DefaultComponent)
	UScenepointComponent SpawnArea;
	default SpawnArea.RelativeLocation = FVector(0.0, 0.0, 8700.0);
	default SpawnArea.Radius = 2000.0;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"TundraGnatPlayerAnnoyedCapability");

	UPROPERTY()
	TSubclassOf<AAITundraGnat> GnapeClass;

	// Add gnape skeletal mesh components to get more gnapes launched
	UPROPERTY(VisibleInstanceOnly)
	int NumGnapes = 0;

	TArray<UHazeSkeletalMeshComponentBase> PreviewMeshes;
	bool bBroken = false;
	ATundraWalkingStick HitByWalkingStick = nullptr;
	TArray<float> LaunchDelays;
	TArray<AAITundraGnat> Gnapes;
	int NumLaunchedGnapes = 0;
	float LaunchTime = BIG_NUMBER;

	// We use spawn pool directly here. See TundraBeaverSpear for an example using spawnercomp and pattern instead, which is a bit nicer.
	UHazeActorNetworkedSpawnPoolComponent SpawnPool;	

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		NumGnapes = GetGnapeMeshes(PreviewMeshes);
	}

	int GetGnapeMeshes(TArray<UHazeSkeletalMeshComponentBase>& OutMeshes)
	{
		TArray<UHazeSkeletalMeshComponentBase> SkelMeshes;
		GetComponentsByClass(SkelMeshes);
		OutMeshes.Reset(SkelMeshes.Num());

		if (!GnapeClass.IsValid())
			return 0;
		
		AAITundraGnat Template = Cast<AAITundraGnat>(GnapeClass.DefaultObject);
		if (Template == nullptr)
			return 0;

		for (UHazeSkeletalMeshComponentBase Mesh : SkelMeshes)
		{
			if (Mesh == nullptr)
				continue;
			if (Mesh.SkeletalMeshAsset == Template.Mesh.SkeletalMeshAsset)
				OutMeshes.Add(Mesh);
		}
		return OutMeshes.Num();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnBreakObstacle.AddUFunction(this, n"OnBreak");		
		CollisionComp.OnComponentBeginOverlap.AddUFunction(this, n"OnCollisionOverlap");

		if (GnapeClass.IsValid())
		{
			SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(GnapeClass, this);
			SpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSpawnedGnape");

			NumGnapes = GetGnapeMeshes(PreviewMeshes);
			if (HasControl())
			{
				// Spawn gnapes to launch at the tree guardian. We replace any preview skelmeshes with these.
				TArray<FHazeActorSpawnParameters> ParamsSet;
				ParamsSet.SetNum(NumGnapes);
				for (int i = 0; i < ParamsSet.Num(); i++)
				{
					ParamsSet[i].Location = PreviewMeshes[i].WorldLocation;
					ParamsSet[i].Rotation = PreviewMeshes[i].WorldRotation;
					ParamsSet[i].Scenepoint = SpawnArea;
					ParamsSet[i].Spawner = this;
				}
				SpawnPool.SpawnBatchControl(ParamsSet);
			}
		}
	}

	UFUNCTION()
	private void OnCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (bBroken)
			return;
		if (OtherActor == nullptr)
			return;
		if (!HasControl())
			return;
		ATundraWalkingStick CollidingStick = Cast<ATundraWalkingStick>(OtherActor);
		if (CollidingStick != nullptr)
		{
			LaunchDelays.SetNum(NumGnapes);			
			for (int i = 0; i < LaunchDelays.Num(); i++)
			{
				LaunchDelays[i] = Math::RandRange(0.0, 0.1);
			}
			CrumbWalkingStickCollision(CollidingStick, LaunchDelays);
		}
	}

	UFUNCTION()
	private void OnBreak()
	{
		if (bBroken)
			return; // Already broken
		bBroken = true;
		AddActorCollisionBlock(this);

		if (HitByWalkingStick == nullptr)
		{
			// Broken by scream, gnapes fall off
			for (AAITundraGnat Gnape : Gnapes)
			{
				Gnape.GnatComp.bFallFromTower = true;
				ReleaseGnape(Gnape);
			}			
		}
	}
	
	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbWalkingStickCollision(ATundraWalkingStick CollidingStick, TArray<float> EntryDelays)
	{
		HitByWalkingStick = CollidingStick;
		LaunchDelays = EntryDelays;
		OnWalkingStickCollision();
	}

	UFUNCTION(BlueprintEvent)
	void OnWalkingStickCollision()
	{
		if (bBroken)
			return; // Already broken

		BreakObstacle();
		bBroken = true;
		if (LaunchDelays.Num() > 0)
		{
			LaunchTime = Time::GameTimeSeconds + LaunchDelays[0];
			SetActorTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!Gnapes.IsValidIndex(NumLaunchedGnapes))
			SetActorTickEnabled(false);
		else if (Time::GameTimeSeconds > LaunchTime)
			LaunchGnape(Gnapes[NumLaunchedGnapes]);
	}

	UFUNCTION()
	private void OnSpawnedGnape(AHazeActor Gnape, FHazeActorSpawnParameters Params)
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Gnape);
		RespawnComp.OnSpawned(this, Params);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedActor");
		RespawnComp.OnPostSpawned();

		// Gnape replaces a skeletal mesh and uses it's animation if any
		int iGnape = Gnapes.Num();
		Gnapes.Add(Cast<AAITundraGnat>(Gnape));
		UHazeSkeletalMeshComponentBase TemplateMesh = PreviewMeshes[iGnape % PreviewMeshes.Num()];
		TemplateMesh.AddComponentVisualsAndCollisionAndTickBlockers(this);
		Gnape.AttachToComponent(TemplateMesh, NAME_None, EAttachmentRule::SnapToTarget);
		Gnape.ActorScale3D = TemplateMesh.WorldScale;
		if (TemplateMesh.AnimationData.AnimToPlay != nullptr)
		{
			FHazeSlotAnimSettings Settings;
			Settings.bLoop = true;
			Settings.StartTime = TemplateMesh.AnimationData.SavedPosition;
			Gnape.PlaySlotAnimation(Cast<UAnimSequence>(TemplateMesh.AnimationData.AnimToPlay), Settings);
		}
		Gnape.BlockCapabilities(CapabilityTags::Movement, this);
		Gnape.BlockCapabilities(BasicAITags::Behaviour, this);
	}

	void LaunchGnape(AAITundraGnat Gnape)
	{
		// Launch towards tree guardian 
		auto GnapeComp = UTundraGnatComponent::Get(Gnape);
		GnapeComp.Host = HitByWalkingStick;
		GnapeComp.LeapEntryTarget = Game::Zoe;
		ReleaseGnape(Gnape);

		NumLaunchedGnapes++;
		if (NumLaunchedGnapes >= Gnapes.Num())
			SetActorTickEnabled(false);

		if (LaunchDelays.IsValidIndex(NumLaunchedGnapes))		
			LaunchTime += LaunchDelays[NumLaunchedGnapes];
	}

	void ReleaseGnape(AAITundraGnat Gnape)
	{
		Gnape.StopAllSlotAnimations();
		Gnape.DetachRootComponentFromParent(true);
		Gnape.UnblockCapabilities(CapabilityTags::Movement, this);
		Gnape.UnblockCapabilities(BasicAITags::Behaviour, this);
	}

	UFUNCTION()
	private void OnUnspawnedActor(AHazeActor Gnape)
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Gnape);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedActor");
		SpawnPool.UnSpawn(Gnape);
		UTundraGnatComponent::Get(Gnape).LeapEntryTarget = nullptr;
		Gnape.ActorScale3D = FVector::OneVector;
	}

	UFUNCTION()
	void HideMeshes()
	{
		TArray<UMeshComponent> Meshes;
		GetComponentsByClass(Meshes);
		for (UMeshComponent Mesh : Meshes)
		{
			Mesh.AddComponentVisualsBlocker(this);
		}
	}
}

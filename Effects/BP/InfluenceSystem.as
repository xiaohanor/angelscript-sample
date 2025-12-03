
/**
 * We will run a fluid sim in Niagara and influencle it with overlapping meshes and by sending points to it. 
 */

 UCLASS(Abstract)
 class AInfluenceSystem : AHazeActor
 {
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

#if EDITOR

	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "InfluenceSystem";
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	// We will add the niagara comp in BP, since it is unstable when declared from angelscript. 
	UNiagaraComponent Sim;

	// handles all the data transfers to niagara.
	FNiagaraInfluence SimInfluence;

	UPROPERTY(Category = "VFX", EditAnywhere, VisibleAnywhere)
	bool bRegisterWithKillParticleManager = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Start();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Start();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Stop();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Stop();
	}

	void Start()
	{
		SimInfluence.Reset();
		Sim = UNiagaraComponent::Get(this);
		SimInfluence.Init(Sim);
		if(bRegisterWithKillParticleManager)
		{
			KillParticleManager::RegisterNiagaraComponent(Sim);
		}
	}

	void Stop()
	{
		SimInfluence.Reset();
		if(Sim != nullptr)
		{
			KillParticleManager::UnregisterNiagaraComponent(Sim);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SimInfluence.Tick(DeltaSeconds);
	}

 }

// @TODO: temp for trying out the system. We might have more than 1 system active in a level so this won't work
namespace InfluenceSystem
{
	UFUNCTION(Category = "VFX")
	void RemoveSourceActor(AActor SourceActor)
	{
		AInfluenceSystem Manager = InfluenceSystem::FindInfluenceSystem();
		Manager.SimInfluence.RemoveSourceActor(SourceActor);
	}

	UFUNCTION(Category = "VFX")
	void AddSourceActor(AActor SourceActor)
	{
		AInfluenceSystem Manager = InfluenceSystem::FindInfluenceSystem();
		Manager.SimInfluence.AddSourceActor(SourceActor);
	}

	UFUNCTION(Category = "VFX")
	void AddPillarPointsForComp(USceneComponent Comp)
	{
		AInfluenceSystem Manager = InfluenceSystem::FindInfluenceSystem();
		Manager.SimInfluence.AddPillarPointsForComp(Comp);
	}

	UFUNCTION(Category = "VFX")
	void AddPoint(FNiagaraInfluencePoint Point)
	{
		AInfluenceSystem Manager = InfluenceSystem::FindInfluenceSystem();
		Manager.SimInfluence.AddPoint(Point);
	}

	UFUNCTION(Category = "VFX")
	void AddShockwave(FNiagaraInfluenceShockwaveData Shockwave)
	{
		AInfluenceSystem Manager = InfluenceSystem::FindInfluenceSystem();
		Manager.SimInfluence.AddPointsShockwave(Shockwave);
	}

	UFUNCTION(Category = "VFX")
	void AddPointsForPrimitiveCollision(UPrimitiveComponent Prim)
	{
		AInfluenceSystem Manager = InfluenceSystem::FindInfluenceSystem();
		Manager.SimInfluence.AddPointsForPrimitiveCollision(Prim);
	}

	UFUNCTION(Category = "VFX")
	void AddPointsForMeshBones(UHazeSkeletalMeshComponentBase Mesh)
	{
		AInfluenceSystem Manager = InfluenceSystem::FindInfluenceSystem();
		Manager.SimInfluence.AddPointsForMeshBones(Mesh);
	}

	UFUNCTION(Category = "VFX")
	void RemovePointsForComp(USceneComponent Comp)
	{
		AInfluenceSystem Manager = InfluenceSystem::FindInfluenceSystem();
		Manager.SimInfluence.RemovePointsForComp(Comp);
	}

	UFUNCTION(Category = "VFX", DisplayName = "Find Influence System")
	AInfluenceSystem FindInfluenceSystem(const bool bDebug = true) 
	{
		AInfluenceSystem System = TListedActors<AInfluenceSystem>().GetSingle();

#if EDITOR
		if(System == nullptr && bDebug)
		{
			// devError("Send screenshot to sydney pls. Couldn't find any InfluenceActor in the level");
			// devCheck(System != nullptr);
		}
#endif

		return System;
	}

}

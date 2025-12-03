
/**
 * System that sends volume bounds data to niagara, primarily for culling particles in undesireable places. 
 * 
 * The system flow: 
 * 	1. Volumes are placed in the level.
 *  2. Volumes registers with a Manager (and also spawns the manager if none can be found) on BeginPlay
 * 	3. Volumes and managers are _deactivate_ until they are needed.
 * 	4. Script Activates "Camera Particles" VFX, which registers the niagara comp with the Manager and _activates_ the manager.
 *  5. Manager stays activated and sends data to niagara comps as long as they are present.
 * 
 * TODO:
 *  - Optimize and test handling Static differently from Moveable volumes. 
 */

class AKillParticleVolume : AVolume
{
	default BrushColor = FLinearColor::Green;
	default BrushComponent.LineThickness = 5.0;
	default BrushComponent.GenerateOverlapEvents = false;
	default BrushComponent.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	// if this volume has managed to register with a manager yet
	bool bRegistered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RegisterWithManagers();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RegisterWithManagers();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UnregisterWithManagers();
	}

	void RegisterWithManagers()
	{
		auto ListedManagers = KillParticleManager::GetOrCreateManagers();
		for(auto IterManager : ListedManagers)
		{
			IterManager.RegisterVolume(this);
			bRegistered = true;
		}
		
		// poll managers on tick until we find one. Might happen due to streaming?
		SetActorTickEnabled(!bRegistered);
	}

	void UnregisterWithManagers()
	{
		auto ListedManagers = KillParticleManager::GetOrCreateManagers();
		for(auto IterManager : ListedManagers)
		{
			IterManager.UnregisterVolume(this);
		}
	}
}

class AKillParticleManager : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	// Volumes that we've found in the level
	TArray<AKillParticleVolume> StaticVolumes;
	TArray<AKillParticleVolume> MoveableVolumes;

	// niagara components that have subscribed to the manager
	private TArray<UNiagaraComponent> RegisteredNiagaraComponents;

	void RegisterVolume(AKillParticleVolume InVolume)
	{
		// for now just add everything as static volume until we have time to test out the optimization
		StaticVolumes.AddUnique(InVolume);

		// if(IterVolume.BrushComponent.Mobility != EComponentMobility::Movable)
		// StaticVolumes.AddUnique(InVolume);
		// else
		// 	MoveableVolumes.AddUnique(IterVolume);
	}

	void UnregisterVolume(AKillParticleVolume InVolume)
	{
		StaticVolumes.Remove(InVolume);
		MoveableVolumes.Remove(InVolume);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// stop ticking until we get a niagara component subscriber
		if(RegisteredNiagaraComponents.Num() <= 0)
			SetActorTickEnabled(false);
		
		// removed old niagara components..the lazy way (for now)
		for(int i = RegisteredNiagaraComponents.Num()-1; i >= 0; --i)
		{
			if(RegisteredNiagaraComponents[i] == nullptr || RegisteredNiagaraComponents[i].IsBeingDestroyed())
			{
				RegisteredNiagaraComponents.RemoveAt(i);
			}
		}

		//PrintToScreenScaled("Manager is ticking");

		HandleStaticVolumes();
		HandleMoveableVolumes();
	}

	void HandleStaticVolumes()
	{
		// if(StaticVolumes.Num() <= 0)
		// 	return;

		TArray<FVector> Origins;
		TArray<FVector> Extents;
		TArray<FQuat> Rotations;
		GetBoundsFromStaticVolumes(Origins, Extents, Rotations);

		for(UNiagaraComponent IterComp : RegisteredNiagaraComponents)
		{
			NiagaraDataInterfaceArray::SetNiagaraArrayVector(IterComp, n"StaticVolumeOrigins", Origins);
			NiagaraDataInterfaceArray::SetNiagaraArrayVector(IterComp, n"StaticVolumeExtents", Extents);
			NiagaraDataInterfaceArray::SetNiagaraArrayQuat(IterComp, n"StaticVolumeRotations", Rotations);
		}

		// we only want to handle them once. Lazy solution for it right now
		// StaticVolumes.Empty();
	}

	void HandleMoveableVolumes()
	{
		if(MoveableVolumes.Num() <= 0)
			return;

		TArray<FVector> Origins;
		TArray<FVector> Extents;
		TArray<FQuat> Rotations;
		GetBoundsFromMoveableVolumes(Origins, Extents, Rotations);

		for(UNiagaraComponent IterComp : RegisteredNiagaraComponents)
		{
			NiagaraDataInterfaceArray::SetNiagaraArrayVector(IterComp, n"MoveableVolumeOrigins", Origins);
			NiagaraDataInterfaceArray::SetNiagaraArrayVector(IterComp, n"MoveableVolumeExtents", Extents);
			NiagaraDataInterfaceArray::SetNiagaraArrayQuat(IterComp, n"MoveableVolumeRotations", Rotations);
		}

	}

	void GetBoundsFromMoveableVolumes(TArray<FVector>& Origins, TArray<FVector>& Extents, TArray<FQuat>& Rotations)
	{
		for(auto IterActor : MoveableVolumes)
		{
			if(IterActor == nullptr)
				continue;

			// @TODO: we should handle moveable ones differently.
			AddStaticBoundsFromVolume(IterActor, Origins, Extents, Rotations);
		}
	}

	void GetBoundsFromStaticVolumes(TArray<FVector>& Origins, TArray<FVector>& Extents, TArray<FQuat>& Rotations)
	{
		for(auto IterActor : StaticVolumes)
		{
			if(IterActor == nullptr)
				continue;

			AddStaticBoundsFromVolume(IterActor, Origins, Extents, Rotations);
		}
	}

	void AddStaticBoundsFromVolume(AKillParticleVolume InVolume, TArray<FVector>& Origins, TArray<FVector>& Extents, TArray<FQuat>& Rotations)
	{
		// @TODO: Clean this up. We want to get unrotated bounds but world bounds center.
		FVector Origin; FVector Extent; FVector DummyVector;
		InVolume.GetActorLocalBounds(false, Origin, Extent, false);
		InVolume.GetActorBounds(false, Origin, DummyVector, false);
		FVector WorldScale = InVolume.GetActorScale3D();
		Extent *= WorldScale;

		Origins.Add(Origin);
		Extents.Add(Extent*2.0);
		Rotations.Add(InVolume.GetActorQuat());

		// if(Extents.Num() > 0)
		// 	PrintToScreenScaled("Extents: " + Extents[0]);
		// Debug::DrawDebugBox(Origin, Extent*1.0, InVolume.GetActorQuat().Rotator(), FLinearColor::Yellow, 10);
	}

	void SendDataToNiagaraComps(TArray<FVector> Data, FName DataString)
	{
		for(UNiagaraComponent IterComp : RegisteredNiagaraComponents)
		{
			NiagaraDataInterfaceArray::SetNiagaraArrayVector(IterComp, DataString, Data);
		}
	}

	UFUNCTION()
	void RegisterNiagaraComponent(UNiagaraComponent NiagaraComp)
	{
		RegisteredNiagaraComponents.Add(NiagaraComp);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void UnregisterNiagaraComponent(UNiagaraComponent NiagaraComp)
	{
		RegisteredNiagaraComponents.Remove(NiagaraComp);
		if(RegisteredNiagaraComponents.Num() <= 0)
		{
			SetActorTickEnabled(false);
		}
	}

}

namespace KillParticleManager
{
	UFUNCTION(Category = "VFX", DisplayName = "Register Actor With Kill Particles Volume Manager")
	void RegisterNiagaraActor(AHazeActor InActor)
	{
		TArray<UNiagaraComponent> NiagaraComps;
		InActor.GetComponentsByClass(UNiagaraComponent, NiagaraComps);

		if(NiagaraComps.Num() <= 0)
			return;

		AKillParticleManager Manager = KillParticleManager::GetOrCreateManager();

		if(Manager == nullptr)
		{
			devCheck(Manager != nullptr, "Manager could not be found or created. Contact Sydney about this.");
			return;
		}

		for(auto IterNiagaraComp : NiagaraComps)
		{
			Manager.RegisterNiagaraComponent(IterNiagaraComp);
		}
	}

	UFUNCTION(Category = "VFX", DisplayName = "Unregister Actor from Kill Particles Volume Manager")
	void UnregisterNiagaraActor(AHazeActor InActor)
	{
		TArray<UNiagaraComponent> NiagaraComps;
		InActor.GetComponentsByClass(UNiagaraComponent, NiagaraComps);

		if(NiagaraComps.Num() <= 0)
			return;

		AKillParticleManager Manager = KillParticleManager::GetOrCreateManager();

		if(Manager == nullptr)
		{
			devCheck(Manager != nullptr, "Manager could not be found or created. Contact Sydney about this.");
			return;
		}

		for(auto IterNiagaraComp : NiagaraComps)
		{
			Manager.UnregisterNiagaraComponent(IterNiagaraComp);
		}
	}

	UFUNCTION(Category = "VFX", DisplayName = "Register Niagara Component With Kill Particles Volume Manager")
	void RegisterNiagaraComponent(UNiagaraComponent NiagaraComp)
	{
		AKillParticleManager Manager = KillParticleManager::GetOrCreateManager();
		if (Manager != nullptr)
			Manager.RegisterNiagaraComponent(NiagaraComp);
	}

	UFUNCTION(Category = "VFX", DisplayName = "Unregister Niagara Component from Kill Particles Volume Manager")
	void UnregisterNiagaraComponent(UNiagaraComponent NiagaraComp)
	{
		AKillParticleManager Manager = KillParticleManager::GetOrCreateManager();
		if (Manager != nullptr)
			Manager.UnregisterNiagaraComponent(NiagaraComp);
	}

	UFUNCTION(Category = "VFX")
	AKillParticleManager CreateManager() 
	{
		auto SpawnedActor = SpawnActor(AKillParticleManager);
		auto Manager = Cast<AKillParticleManager>(SpawnedActor);
		return Manager;
	}

	UFUNCTION(Category = "VFX", DisplayName = "Get Kill Particles Volume Manager")
	AKillParticleManager GetOrCreateManager() 
	{
		// ... @TODO: would be nicer with a singleton. But we'll do the first implementation 
		// with an actor for now so we can get it up and running asap.
		AKillParticleManager Manager = TListedActors<AKillParticleManager>().GetSingle();

		// create one if there aren't any
		if(Manager == nullptr)
			Manager = CreateManager();

		return Manager;
	}

	UFUNCTION(Category = "VFX", DisplayName = "Get Kill Particles Volume Managers")
	TArray<AKillParticleManager> GetOrCreateManagers() 
	{
		TArray<AKillParticleManager> Managers = TListedActors<AKillParticleManager>().GetArray();

		// create one if there aren't any
		if(Managers.Num() <= 0)
			CreateManager();

		Managers = TListedActors<AKillParticleManager>().GetArray();

		return Managers;
	}
}
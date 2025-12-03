/**
 * Spawns a ASkylineAttackShipThruster in BeginPlay, and attaches it to this component.
 * Will automatically copy over this components collision settings to the main mesh on the thruster actor.
 */
UCLASS(NotBlueprintable, HideCategories = "StaticMesh ComponentTick Physics Lighting Rendering Navigation Disable Debug Activation Cooking Events Tags LOD TextureStreaming MaterialParameters HLOD AssetUserData")
class USkylineAttackShipThrusterComponent : UStaticMeshComponent
{
	default CollisionProfileName = n"NoCollision";
	default bHiddenInGame = true;
	default bVisible = true;

	UPROPERTY(EditDefaultsOnly, Category = "Thruster Spawner")
	TSubclassOf<ASkylineAttackShipThruster> ThrusterClass;

	ASkylineAttackShipThruster Thruster;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(ThrusterClass.IsValid())
			SetStaticMesh(ThrusterClass.DefaultObject.ThrusterMeshComp.StaticMesh);
		else
			SetStaticMesh(nullptr);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Thruster = SpawnActor(ThrusterClass);
		Thruster.AttachToComponent(this);
		Thruster.MakeNetworked(this, n"ThrusterActor");
		Thruster.SetActorControlSide(Owner);

		// Copy the collision settings to the thruster
		Thruster.ThrusterMeshComp.SetCollisionProfileName(CollisionProfileName);
		Thruster.ThrusterMeshComp.SetCollisionEnabled(CollisionEnabled);
		Thruster.ThrusterMeshComp.SetCollisionObjectType(CollisionObjectType);

		// This seems to be overridden by a haze fix if the profile name was changed, so no need? Could mean we miss some settings, but it should be fine.
		// for(int i = 0; i < int(ECollisionChannel::ECC_MAX); i++)
		// {
		// 	ECollisionChannel CollisionChannel = ECollisionChannel(i);
		// 	Thruster.ThrusterMeshComp.SetCollisionResponseToChannel(
		// 		CollisionChannel, GetCollisionResponseToChannel(CollisionChannel)
		// 	);
		// }

		// Add ourself to our parents auto disable list (not really needed since we disable ourselves if needed, but this also shows up in the performance tab)
		auto ParentDisableComp = UDisableComponent::Get(Owner);
		if(ParentDisableComp != nullptr && ParentDisableComp.bAutoDisable)
			ParentDisableComp.LateAddAutoDisableLinkedActor(Thruster);

		// Add the thruster to the owners outlines if they should outline attached actors
		TArray<UTargetableOutlineComponent> OutlineComponents;
		Owner.GetComponentsByClass(OutlineComponents);
		for(UTargetableOutlineComponent OutlineComp : OutlineComponents)
		{
			if(OutlineComp.bOutlineAttachedActors)
				OutlineComp.AddActorToOutline(Thruster);
		}

		AddComponentVisualsAndCollisionAndTickBlockers(this);

		if(Owner.IsActorDisabled())
			Thruster.AddActorDisable(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Thruster.RemoveActorDisable(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Thruster.AddActorDisable(Owner);
	}
};
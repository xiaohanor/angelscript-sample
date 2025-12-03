class UDarkPortalFocusEffectComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Focus Effect")
	UMaterialInterface FocusMaterial;

	UPROPERTY(EditAnywhere, Category = "Focus Effect")
	FLinearColor FocusColor;

	float ScaleOffset = 0.02;

	UMaterialInstanceDynamic MID;

	FName ColorParameterName = n"BaseColor";
	FName OpacityParameterName = n"Opacity";
	FName EmissiveParameterName = n"EmissiveColor";

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PrintScaled("Focused", 1.0, FLinearColor::Green);
//		auto AttachPoint = SpawnActor(AActor, Owner.ActorLocation, Owner.ActorRotation);
//		AttachPoint.AttachToComponent(Owner.RootComponent);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// auto ResponseComp = UDarkPortalResponseComponent::GetOrCreate(Owner);
		// ResponseComp.OnFocused.AddUFunction(this, n"HandleFocused");
		// ResponseComp.OnUnfocused.AddUFunction(this, n"HandleUnfocused");
		// ResponseComp.OnReleased.AddUFunction(this, n"HandleUnfocused");

		TArray <UStaticMeshComponent> StaticMeshes;
		TArray<USceneComponent> Children;
		Owner.RootComponent.GetChildrenComponents(true, Children);
		for (auto Child : Children)
		{
			auto StaticMesh = Cast<UStaticMeshComponent>(Child);
			if (StaticMesh != nullptr)
				StaticMeshes.Add(StaticMesh);	
		}

/*
		TArray<AActor> AttachedActors;
		Owner.GetAttachedActors(AttachedActors, false);
		for (auto AttachedActor : AttachedActors)
			AttachedActor.GetAttachedActors(AttachedActors, false);

		auto FauxPhysicsComponent = UFauxPhysicsComponentBase::Get(Owner);
		if (FauxPhysicsComponent != nullptr)
			for (auto AttachedActor : AttachedActors)
				AttachedActor.AttachToComponent(FauxPhysicsComponent, AttachmentRule = EAttachmentRule::KeepWorld);

		// Create meshes
		TArray <UStaticMeshComponent> StaticMeshes;
		Owner.GetComponentsByClass(StaticMeshes);

		auto Actors = AttachedActors;
		Actors.Add(Owner);
		for (auto Actor : Actors)
		{
			TArray <UStaticMeshComponent> StaticMeshesToAdd;
			Actor.GetComponentsByClass(StaticMeshesToAdd);
			StaticMeshes.Append(StaticMeshesToAdd);
		}
*/

		// Setup Materials
		MID = Material::CreateDynamicMaterialInstance(this, FocusMaterial);
		MID.SetScalarParameterValue(OpacityParameterName, 0.0);
		MID.SetVectorParameterValue(ColorParameterName, FocusColor);
		MID.SetVectorParameterValue(EmissiveParameterName, FocusColor * 0.0);

		for (auto StaticMesh : StaticMeshes)
		{
			auto NewMesh = UStaticMeshComponent::Create(Owner);
			
			NewMesh.SetStaticMesh(StaticMesh.StaticMesh);
			NewMesh.AttachToComponent(StaticMesh.AttachParent);
			NewMesh.SetWorldTransform(StaticMesh.WorldTransform);
			NewMesh.SetWorldScale3D(NewMesh.WorldScale * (1.0 + ScaleOffset));
			NewMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			NewMesh.SetRenderedForPlayer(Game::Mio, false);

			for (int i = 0; i < NewMesh.NumMaterials; i++)
				NewMesh.SetMaterial(i, MID);
		}
	
	}

	UFUNCTION()
	private void HandleFocused(AHazeActor PortalActor, USceneComponent TargetComponent)
	{
		PrintScaled("Focused", 1.0, FLinearColor::Green);
		MID.SetScalarParameterValue(OpacityParameterName, 0.01);
		MID.SetVectorParameterValue(EmissiveParameterName, FocusColor * 0.5);
	}

	UFUNCTION()
	private void HandleUnfocused(AHazeActor PortalActor, USceneComponent TargetComponent)
	{
		PrintScaled("Unfocused", 1.0, FLinearColor::Green);
		MID.SetScalarParameterValue(OpacityParameterName, 0.0);
		MID.SetVectorParameterValue(EmissiveParameterName, FocusColor * 0.0);
	}
}
UCLASS(Abstract)
class AMagnetDroneSurfaceActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SurfaceRoot;

	UPROPERTY(DefaultComponent, Attach = SurfaceRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerAbilityZoe, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = SurfaceRoot)
	USceneComponent TargetablesRoot;

	UPROPERTY(DefaultComponent, Attach = TargetablesRoot)
	UDroneMagneticZoneComponent MagneticZoneComp;

	UPROPERTY(DefaultComponent, Attach = TargetablesRoot)
	UMagnetDroneAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach = SurfaceRoot)
	UNiagaraComponent EffectComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

#if EDITOR
	UPROPERTY(EditDefaultsOnly)
	UStaticMesh OldMesh;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh NewMesh;
#endif

	UPROPERTY(Category = "Magnet Drone Surface")
	FOnMagnetDroneStartAttraction OnMagnetDroneStartAttraction;
	
	UPROPERTY(Category = "Magnet Drone Surface")
	FOnMagnetDroneEndAttraction OnMagnetDroneEndAttraction;

	/* Executed when the player attaches to this actor. */
	UPROPERTY(Category = "Magnet Drone Surface")
    FOnMagnetDroneAttached OnMagnetDroneAttached;

	/* Executed when the player detaches from this actor. */
	UPROPERTY(Category = "Magnet Drone Surface")
    FOnMagnetDroneDetached OnMagnetDroneDetached;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticSurfaceComp.OnMagnetDroneStartAttraction.AddUFunction(this, n"MagnetDroneStartAttraction");
		MagneticSurfaceComp.OnMagnetDroneEndAttraction.AddUFunction(this, n"MagnetDroneEndAttraction");
		MagneticSurfaceComp.OnMagnetDroneAttached.AddUFunction(this, n"OnMagnetDroneAttachedInternal");
		MagneticSurfaceComp.OnMagnetDroneDetached.AddUFunction(this, n"OnMagnetDroneDetachedInternal");
	}

	UFUNCTION()
	private void MagnetDroneStartAttraction(FOnMagnetDroneStartAttractionParams Params)
	{
		OnMagnetDroneStartAttraction.Broadcast(Params);
	}

	UFUNCTION()
	private void MagnetDroneEndAttraction(FOnMagnetDroneEndAttractionParams Params)
	{
		OnMagnetDroneEndAttraction.Broadcast(Params);
	}

	UFUNCTION()
	private void OnMagnetDroneAttachedInternal(FOnMagnetDroneAttachedParams Params)
	{
		OnMagnetDroneAttached.Broadcast(Params);
	}

	UFUNCTION()
	private void OnMagnetDroneDetachedInternal(FOnMagnetDroneDetachedParams Params)
	{
		OnMagnetDroneDetached.Broadcast(Params);
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	private void ReplaceMeshes()
	{
		Modify();
		TArray<UStaticMeshComponent> MeshComps;
		MeshRoot.GetChildrenComponentsByClass(UStaticMeshComponent, true, MeshComps);
		for(auto Mesh : MeshComps)
		{
			Mesh.Modify();

			if(Mesh.StaticMesh != OldMesh)
				continue;
			
			Mesh.SetStaticMesh(NewMesh);

			if(Mesh.RelativeScale3D.Equals(FVector(0.2, 4.0, 4.0)))
				Mesh.SetRelativeScale3D(FVector::OneVector);
			else if(Mesh.RelativeScale3D.Equals(FVector(0.2, 3.0, 3.0)))
				Mesh.SetRelativeScale3D(FVector(0.75, 0.75, 1.0));
			else if(Mesh.RelativeScale3D.Equals(FVector(0.2, 3.592276, 3.592276)))
				Mesh.SetRelativeScale3D(FVector(0.89, 0.89, 1.0));
			else
				Mesh.SetRelativeScale3D(FVector::OneVector);

			if(Mesh.RelativeRotation.Equals(FRotator::ZeroRotator))
				Mesh.SetRelativeRotation(FRotator(-90, 0, 0));

			Mesh.MarkRenderStateDirty();
		}
	}

	UFUNCTION(CallInEditor)
	private void ReplaceAllMeshes()
	{
		TArray<AMagnetDroneSurfaceActor> Actors = Editor::GetAllEditorWorldActorsOfClass(AMagnetDroneSurfaceActor);
		for(auto Actor : Actors)
		{
			AMagnetDroneSurfaceActor Surface = Cast<AMagnetDroneSurfaceActor>(Actor);
			Surface.ReplaceMeshes();
		}
	}
#endif
}
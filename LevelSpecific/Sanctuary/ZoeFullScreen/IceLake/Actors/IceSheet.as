struct FIceSheetMesh
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UStaticMesh Mesh;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform RelativeTransform;
}

UCLASS(Abstract, HideCategories = "Rendering Collision Advanced Actor Cooking Debug")
class AIceSheet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, Category = "Ice Sheet")
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root", Category = "Ice Sheet")
	UStaticMeshComponent Mesh;

	//UPROPERTY(DefaultComponent, Category = "Ice Sheet")
	UWindDirectionResponseComponent WindDirectionResponseComp;

	UPROPERTY(EditAnywhere, Category = "Ice Sheets")
	bool bAffectedByWind = false;

	UPROPERTY(EditAnywhere, Category = "Ice Sheets")
	float Drag = 1.0;

	UPROPERTY(EditAnywhere, Category = "Ice Sheets")
	float MaxAffectDistance = 3000.0;

	UPROPERTY(EditAnywhere, Category = "Ice Sheet")
	int MeshIndex;

	UPROPERTY(EditDefaultsOnly, Category = "Ice Sheet")
	TArray<FIceSheetMesh> Meshes;

	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(Meshes.Num() == 0)
			return;

		MeshIndex = Math::Clamp(MeshIndex, 0, Meshes.Num() - 1);
		SetMesh(Meshes[MeshIndex]);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bAffectedByWind)
			WindDirectionResponseComp.OnWindDirectionChanged.AddUFunction(this, n"OnWindDirectionChanged");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bAffectedByWind)
		{
			const float IntegratedDragFactor = Math::Exp(-Drag);
			Velocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaSeconds);

			FVector Delta = Velocity * DeltaSeconds;
			AddActorWorldOffset(Delta);
		}
	}

	UFUNCTION()
	void OnWindDirectionChanged(FVector WindDirection, FVector Location)
	{
		const float Distance = ActorLocation.Distance(Location);
		const float Factor = 1.0 - Math::Saturate(Distance / MaxAffectDistance);
		Velocity += WindDirection * Factor;
	}

	UFUNCTION(CallInEditor, Category = "Ice Sheet")
	void RandomizeMesh()
	{
		if(Meshes.Num() <= 1)
			return;
		
		int OldMesh = MeshIndex;
		while(MeshIndex == OldMesh)
		{
			MeshIndex = Math::Rand() % Meshes.Num();
		}
		SetMesh(Meshes[MeshIndex]);
	}

	UFUNCTION(CallInEditor, Category = "Ice Sheet")
	void RandomizeRotation()
	{
		FRotator Rotation = FRotator(0., Math::RandRange(-180., 180.), 0.);
		SetActorRotation(Rotation);
	}

	UFUNCTION(CallInEditor, Category = "Ice Sheet")
	void RandomizeAll()
	{
		RandomizeMesh();
		RandomizeRotation();
	}

	private void SetMesh(FIceSheetMesh InMesh)
	{
		Mesh.SetStaticMesh(InMesh.Mesh);
		Mesh.SetRelativeTransform(InMesh.RelativeTransform);
	}
};
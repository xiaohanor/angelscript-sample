UCLASS(Abstract)
class AWhitespace_Crack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	UPROPERTY(DefaultComponent)
	USequencerWhitespaceCrack CrackTicker;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.bCastDynamicShadow = false;

	UPROPERTY(EditAnywhere)
	TArray<AActor> SphereMask;

	void Ticker()
	{
		//Print("Hejhej", 0);
		SphereMask_AS();
	}

	void SphereMask_AS()
	{

		//UStaticMeshComponent Mesh = UStaticMeshComponent::Get(this);

		if(Mesh == nullptr)
			return;
		
		for (int i = 0; i < SphereMask.Num(); i++)
		{
			FVector MeshScale = SphereMask[i].ActorRelativeScale3D;
			FVector Location = SphereMask[i].ActorLocation;
			FVector Right = SphereMask[i].ActorRightVector;
			FVector Up = SphereMask[i].ActorUpVector;
			FVector Forward = SphereMask[i].ActorForwardVector;

			FVector FinalScale = MeshScale * 50.0;

			Mesh.SetColorParameterValueOnMaterials(FName("Data1_"+i), FLinearColor(Location.X, Location.Y, Location.Z, FinalScale.X));
			Mesh.SetColorParameterValueOnMaterials(FName("Data2_"+i), FLinearColor(Forward.X, Forward.Y, Forward.Z, FinalScale.Y));
			Mesh.SetColorParameterValueOnMaterials(FName("Data3_"+i), FLinearColor(Right.X, Right.Y, Right.Z, FinalScale.Z));

		}

		//Print("Majs:  " + Location, 0.0);

	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SphereMask_AS();
	}

};

class USequencerWhitespaceCrack : USceneComponent
{
	default bTickInEditor = true;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Crack = Cast<AWhitespace_Crack>(Owner);
		Crack.Ticker();
	}
};


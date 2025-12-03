UCLASS(Abstract)
class ASketchbookDarkCaveShader : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	TArray<USketchbookDarkCaveCutoutComponent> CutoutComps;

	const int SupportedCutoutsCount = 20;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(TListedActors<ASketchbookDarkCaveShader>().Array.Num() > 1)
			devError("Only one instance of dark cave shader is supported");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(int i = 0; i < SupportedCutoutsCount; i++)
		{
			float Radius = 0;
			
			if(i < CutoutComps.Num())
			{
				if(CutoutComps[i] != nullptr && CutoutComps[i].Owner != nullptr)
				{
					Radius = CutoutComps[i].Radius;
					SetCutoutPosition(i, CutoutComps[i]);
				}
				else
				{
					CutoutComps.RemoveAt(i);
					i--;
					continue;
				}
			}

			SetCutoutRadius(i, Radius);
		}
	}

	void SetCutoutRadius(int Index, float Radius)
	{
		Mesh.SetScalarParameterValueOnMaterialIndex(
		0,
		FName("Radius" + Index),
		Radius);
	}

	void SetCutoutPosition(int Index, USketchbookDarkCaveCutoutComponent CutoutComp)
	{
		FVector Location = Math::LinePlaneIntersection(
			CutoutComp.WorldLocation,
			Game::Mio.ViewLocation,
			ActorLocation,
			ActorUpVector);

		Mesh.SetVectorParameterValueOnMaterialIndex(
					0,
					FName("Pos" + Index),
					Location);
	}

	UFUNCTION()
	void SetRadius(AHazePlayerCharacter Player, float Radius)
	{
		if (Player == nullptr)
			return;
		
		USketchbookDarkCaveCutoutComponent::GetOrCreate(Player).Radius = Radius;
		USketchbookDarkCaveCutoutComponent::Get(Player).RelativeLocation = FVector::UpVector * Player.ScaledCapsuleHalfHeight;
	}

	void AddCutoutComponent(USketchbookDarkCaveCutoutComponent CutoutComp)
	{
		if(CutoutComps.Num() == SupportedCutoutsCount)
		{
			PrintWarning("Cutouts exceeded max limit");
			
			float SmallestRadius = MAX_flt;
			int IndexToSwap = 0;

			for(int i = 0; i < CutoutComps.Num(); i++)
			{
				if(CutoutComps[i].Radius < SmallestRadius)
					IndexToSwap = i;
			}

			CutoutComps.RemoveAt(IndexToSwap);
		}

		CutoutComps.Add(CutoutComp);
	}
};

namespace Sketchbook
{
	UFUNCTION(BlueprintCallable)
	void SetUseFireArrows(bool bUseFire)
	{
		for(auto Player : Game::Players)
			USketchbookBowPlayerComponent::Get(Player).bUseFire = bUseFire;
	}
}
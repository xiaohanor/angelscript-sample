class USummitKnightPossessComponent : UActorComponent
{
	AHazeCharacter Character;
	UMaterialInterface OriginalMaterial1;
	UMaterialInterface OriginalMaterial2;

	UPROPERTY()
	UMaterialInterface InvisibleMaterial;

	UPROPERTY(EditAnywhere)
	ASplineActor IntroSpline;

	private bool bInitialized;
	bool bPossessed;

	private void Initialize()
	{
		if(bInitialized)
			return;
		bInitialized = true;
		Character = Cast<AHazeCharacter>(Owner);
		OriginalMaterial1 = Character.Mesh.Materials[1];
		OriginalMaterial2 = Character.Mesh.Materials[2];
		bPossessed = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
	}

	void DeactivateKnight()
	{
		Initialize();
		Character.Mesh.SetMaterial(1, InvisibleMaterial);
		Character.Mesh.SetMaterial(2, InvisibleMaterial);
		Character.Mesh.AddComponentTickBlocker(this);
		bPossessed = false;
	}

	void ActivateKnight()
	{
		Initialize();
		Character.Mesh.SetMaterial(1, OriginalMaterial1);
		Character.Mesh.SetMaterial(2, OriginalMaterial2);
		Character.Mesh.RemoveComponentTickBlocker(this);
		bPossessed = true;
	}

	void IntroMovement(float Fraction)
	{
		Character.ActorLocation = IntroSpline.Spline.GetWorldLocationAtSplineFraction(Fraction);
	}
}
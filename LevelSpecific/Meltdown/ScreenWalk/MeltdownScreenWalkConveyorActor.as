UCLASS(Abstract)
class AMeltdownScreenWalkConveyorActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	UMaterialInterface Material;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic MID;

	UPROPERTY()
	FName MaterialPanningParameter = n"PanningY";

	UPROPERTY()
	float PanningSpeed = 0.6;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MID = Material::CreateDynamicMaterialInstance(this, Material);

		SetPanningSpeed(PanningSpeed);
	}

	UFUNCTION()
	void SetPanningSpeed(float Speed)
	{
		PanningSpeed = Speed;

		MID.SetScalarParameterValue(MaterialPanningParameter, PanningSpeed);
	}
};

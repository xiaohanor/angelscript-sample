UCLASS(Abstract)
class AIslandRedBlueSidescrollerSpotlightActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Spotlight;
	default Spotlight.CollisionProfileName = n"NoCollision";

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface SpotlightMaterial;

	UPROPERTY(NotVisible)
	UMaterialInstanceDynamic DynamicMat;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(DynamicMat == nullptr)
			DynamicMat = Spotlight.CreateDynamicMaterialInstance(0, SpotlightMaterial);
	}

	void SetPlayerOwner(AHazePlayerCharacter Player)
	{
		PlayerOwner = Player;
	}

	void SetAngle(float Degrees)
	{
		DynamicMat.SetScalarParameterValue(n"AngleDegrees", Degrees * 2.0);
	}

	void SetEndLocation(FVector EndLocation)
	{
		FVector Delta = (EndLocation - ActorLocation);
		SetMaxLength(Delta.Size());
		ActorRotation = FRotator::MakeFromZ(Delta);
	}

	void SetInnerRadius(float Radius)
	{
		DynamicMat.SetScalarParameterValue(n"InnerRadius", Radius);
	}

	private void SetMaxLength(float Length)
	{
		float Scale = Length / 100.0;
		Spotlight.WorldScale3D = FVector(1.0, 1.0, Scale);
	}
}
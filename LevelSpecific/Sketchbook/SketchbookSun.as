UCLASS(Abstract)
class ASketchbookSun : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Sun;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StartPosition;

	FVector FinalPosition;
	FVector PlayerTargetPos;

	float LowestDistance = MAX_flt;

	FHazeAcceleratedFloat Alpha;

	UMaterialInstanceDynamic SunMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorTickEnabled = false;
		FinalPosition = ActorLocation;

		Alpha.SnapTo(1);

		SunMaterial = Material::CreateDynamicMaterialInstance(nullptr, Sun.GetMaterial(0));
		Sun.SetMaterial(0, SunMaterial);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float PlayerDistance = (((Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2) - PlayerTargetPos).Size();
		if (PlayerDistance < LowestDistance)
			LowestDistance = PlayerDistance;

		Alpha.AccelerateTo(
			Math::Clamp((LowestDistance - 170) / 9000, 0.0, 1.0),
			8, DeltaSeconds
		);

		Sun.WorldLocation = Math::Lerp(FinalPosition, StartPosition.WorldLocation, Alpha.Value);
		SunMaterial.SetScalarParameterValue(n"Alpha", Alpha.Value);
	}

	UFUNCTION(BlueprintCallable)
	void Activate(FVector PlayerTargetPosIn)
	{
		PlayerTargetPos = PlayerTargetPosIn;
		ActorTickEnabled = true;
	}

	UFUNCTION(BlueprintCallable)
	void Deactivate()
	{
		ActorTickEnabled = false;
	}
};

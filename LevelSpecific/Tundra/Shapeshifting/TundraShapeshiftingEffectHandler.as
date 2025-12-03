UCLASS(Abstract)
class UTundraShapeshiftingEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
	AHazePlayerCharacter Player;

	// Will get called the frame the player shapeshifts
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShapeshift(FTundraShapeshiftingEffectParams Params) {}

	// Will get called when the shapeshifting morph is done
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShapeshiftMorphDone(FTundraShapeshiftingEffectParams Params) {}

	// Will get called the frame the player tries to shapeshift, but it will fail
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShapeshiftFail(FTundraShapeshiftingEffectParams Params) {}

	private UTundraPlayerShapeshiftingComponent ShapeshiftingComp;

	UFUNCTION(BlueprintPure)
	AHazeCharacter GetShapeActorForType(ETundraShapeshiftShape Type)
	{
		return ShapeshiftingComp.GetShapeComponentForType(Type).GetShapeActor();
	}

	UFUNCTION(BlueprintPure)
	TArray<UHazeCharacterSkeletalMeshComponent> GetAllShapeMeshes(bool bIncludingPlayer = true)
	{
		auto SmallComp = ShapeshiftingComp.GetShapeComponentForType(ETundraShapeshiftShape::Small);
		auto BigComp = ShapeshiftingComp.GetShapeComponentForType(ETundraShapeshiftShape::Big);
		TArray<UHazeCharacterSkeletalMeshComponent> Meshes;
		Meshes.Add(SmallComp.GetShapeMesh());

		if(bIncludingPlayer)
			Meshes.Add(Player.Mesh);

		Meshes.Add(BigComp.GetShapeMesh());

		return Meshes;
	}
}

struct FTundraShapeshiftingEffectParams
{
	UPROPERTY()
	ETundraShapeshiftShape FromShape;

	UPROPERTY()
	ETundraShapeshiftShape ToShape;
}
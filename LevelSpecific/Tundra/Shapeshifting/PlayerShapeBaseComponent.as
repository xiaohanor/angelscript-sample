UCLASS(NotPlaceable)
class UTundraPlayerShapeBaseComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly, EditConst)
	ETundraShapeshiftShape ShapeType = ETundraShapeshiftShape::None;

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	AHazePlayerCharacter Player;

	AHazeCharacter GetShapeActor() const
	{
		devError("Not implemented");
		return nullptr;
	}

	UHazeCharacterSkeletalMeshComponent GetShapeMesh() const
	{
		devError("Not implemented");
		return nullptr;
	}

	/** Used during the morph to tint the materials of the characters */
	void GetMaterialTintColors(FLinearColor &PlayerColor, FLinearColor &ShapeColor) const {
		devError("Not implemented");
	}

	FVector2D GetShapeCollisionSize() const
	{
		devError("Not implemented");
		return FVector2D(-1.0, -1.0);
	}

	bool ShouldConsumeShapeshiftInput() const
	{
		return true;
	}

	float GetShapeGravityAmount() const
	{
		devError("Not implemented");
		return -1.0;
	}

	float GetShapeTerminalVelocity() const
	{
		devError("Not implemented");
		return -1.0;
	}

	float GetToShapeGravityBlendTime() const
	{
		return 0.5;
	}

	float GetFromShapeToPlayerGravityBlendTime() const
	{
		return 0.5;
	}

	bool ShouldSnapGravity() const
	{
		return ShapeshiftingComp.PlayerShouldSnapGravity();
	}

	float GetShapePoleClimbMaxHeightOffset() const
	{
		return 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftingComp.RegisterShape(this);
	}
}
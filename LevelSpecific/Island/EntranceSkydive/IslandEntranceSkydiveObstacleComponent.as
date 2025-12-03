enum EIslandEntranceSkydiveObstacleShapeType
{
	Box,
	Sphere
}

class UIslandEntranceSkydiveObstacleComponent : UHazeMovablePlayerTriggerComponent
{
	default EditorLineThickness = 10.0;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Auto Generation")
	bool bGenerateOnConstructionScript = true;

	UPROPERTY(EditInstanceOnly, Category = "Auto Generation")
	EIslandEntranceSkydiveObstacleShapeType ShapeToGenerate;

	UPROPERTY(EditInstanceOnly, Category = "Auto Generation")
	float ShapeMargins = 10.0;

	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		if(bGenerateOnConstructionScript)
			GenerateShape();
	}

	// Will generate shape based on the bounds of the parent component
	UFUNCTION(CallInEditor, Category = "Auto Generation")
	void GenerateShape()
	{
		FTransform TransformWithoutScale = FTransform(Owner.ActorRotation, Owner.ActorLocation);
		FBox BoundsBox = AttachParent.GetBoundingBoxRelativeToTransform(TransformWithoutScale);

		if(ShapeToGenerate == EIslandEntranceSkydiveObstacleShapeType::Sphere)
		{
			float LargestExtent = BoundsBox.Extent.X > BoundsBox.Extent.Y ? (BoundsBox.Extent.X > BoundsBox.Extent.Z ? BoundsBox.Extent.X : BoundsBox.Extent.Z) : BoundsBox.Extent.Y;
			ChangeShape(FHazeShapeSettings::MakeSphere(LargestExtent - ShapeMargins));
		}
		else if(ShapeToGenerate == EIslandEntranceSkydiveObstacleShapeType::Box)
		{
			ChangeShape(FHazeShapeSettings::MakeBox(BoundsBox.Extent - FVector(ShapeMargins)));
		}
		else
			devError("Forgot to add case");

		WorldLocation = Owner.ActorTransform.TransformPosition(BoundsBox.Center);
		WorldRotation = Owner.ActorRotation;
		WorldScale3D = FVector::OneVector;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		auto SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
		SkydiveComp.RequestHitReaction(WorldLocation);
	}
}
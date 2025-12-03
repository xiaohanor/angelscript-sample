USTRUCT()
struct FMoonMarketShapeshiftShapeData
{
	UPROPERTY()
	FString ShapeTag;

	UPROPERTY()
	bool bIsBubbleBlockingShape = true;
	
	UPROPERTY()
	bool bCancelByThunder = true;

	UPROPERTY()
	float Radius = 50;
	
	UPROPERTY()
	bool bUseCustomMovement = false;

	//Generic movement capability variables
	UPROPERTY()
	bool bCanBounce = true;

	UPROPERTY()
	bool bCanDash = false;

	UPROPERTY()
	bool bCanJump = false;

	UPROPERTY(Meta = (EditCondition != bUseCustomMovement, EditConditionHides))
	const float MoveSpeed = 400;

	UPROPERTY()
	float JumpStrength = 900;
}

event void FMoonMarketOnShapeshiftedEvent();

class UMoonMarketShapeshiftComponent : UActorComponent
{
	FMoonMarketOnShapeshiftedEvent OnShapeShift;
	
	AMoonMarketShapeshiftShapeHolder ShapeshiftShape;
	FMoonMarketShapeshiftShapeData ShapeData;
	bool bIsShapeshifting = false;

	int NetId = 0;

	bool CanShapeshift() const
	{	
		return true;	
		//return Time::GetGameTimeSince(UnmorphedTime) > Cooldown;
	}

	void Shapeshift(AHazeActor Shape, bool bDestroyOnUnshapeshift = true)
	{
		if(ShapeshiftShape != nullptr)
		{
			if(ShapeshiftShape.InteractingPlayer != nullptr)
				ShapeshiftShape.StopInteraction(ShapeshiftShape.InteractingPlayer);
			else
				ShapeshiftShape.DestroyActor();
		}
		// else
		// 	Player.Mesh.AddComponentVisualsBlocker(this);

		
		ShapeshiftShape = SpawnActor(AMoonMarketShapeshiftShapeHolder);
		ShapeshiftShape.MakeNetworked(this, NetId);
		NetId++;
		
		ShapeshiftShape.SetShape(Shape, Owner, bDestroyOnUnshapeshift);

		FMoonMarketShapeshiftShapeData NewShapeData;
		if(UMoonMarketPolymorphShapeComponent::Get(Shape) != nullptr)
			NewShapeData = UMoonMarketPolymorphShapeComponent::Get(Shape).ShapeData;
		else
			NewShapeData = FMoonMarketShapeshiftShapeData();

		SetCustomShapeData(NewShapeData);
		OnShapeShift.Broadcast();
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnMorph(Cast<AHazeActor>(Owner), FMoonMarketPolymorphEventParams(ShapeData.ShapeTag, Owner));
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnMorph(Shape, FMoonMarketPolymorphEventParams(ShapeData.ShapeTag, Owner));
	}

	private void SetCustomShapeData(FMoonMarketShapeshiftShapeData NewData)
	{
		ShapeData = NewData;
		
		if(ShapeshiftShape != nullptr)
			ShapeshiftShape.bCancelByThunder = ShapeData.bCancelByThunder;
	}

	void UnsetShape()
	{
		if(ShapeshiftShape != nullptr)
			ShapeshiftShape.DestroyActor();
		
		ShapeshiftShape = nullptr;
		SetCustomShapeData(FMoonMarketShapeshiftShapeData());

		auto AutoAimComp = UMoonMarketPolymorphAutoAimComponent::Get(Owner);
		if(AutoAimComp != nullptr)
		{
			AutoAimComp.SetRelativeLocation(AutoAimComp.OriginalRelativeLocation);
		}
	}

	bool IsShapeshiftActive() const
	{
		return ShapeshiftShape != nullptr;
	}

	AHazeActor GetShape() const
	{
		if(ShapeshiftShape == nullptr)
			return nullptr;
		
		return ShapeshiftShape.CurrentShape;
	}
};
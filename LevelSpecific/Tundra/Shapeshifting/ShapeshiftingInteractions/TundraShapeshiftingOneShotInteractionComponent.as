struct FTundraShapeshiftingOneShotShapeSettings
{
	UPROPERTY(EditAnywhere)
	FOneShotSettings SmallShape;

	UPROPERTY(EditAnywhere)
	FOneShotSettings BigShape;

	FOneShotSettings GetSettingsForShape(ETundraShapeshiftActiveShape Shape) const
	{
		switch(Shape)
		{
			case ETundraShapeshiftActiveShape::Small:
				return SmallShape;
			case ETundraShapeshiftActiveShape::Player:
				devError("Don't call this here since player settings are on the main component instead!");
				return FOneShotSettings();
			case ETundraShapeshiftActiveShape::Big:
				return BigShape;
		}
	}
}

class UTundraShapeshiftingOneShotInteractionComponent : UOneShotInteractionComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Meta=(EditCondition = "UsableByPlayers != EHazeSelectPlayer::Zoe", Bitmask, BitmaskEnum="/Script/Angelscript.ETundraShapeshiftActiveShape"), Category = "Targetable")
	int UsableByMioShape = 0;
	default UsableByMioShape |= 1 << int(ETundraShapeshiftActiveShape::Small);
	default UsableByMioShape |= 1 << int(ETundraShapeshiftActiveShape::Player);
	default UsableByMioShape |= 1 << int(ETundraShapeshiftActiveShape::Big);

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Meta=(EditCondition = "UsableByPlayers != EHazeSelectPlayer::Mio", Bitmask, BitmaskEnum="/Script/Angelscript.ETundraShapeshiftActiveShape"), Category = "Targetable")
	int UsableByZoeShape = 0; 
	default UsableByZoeShape |= 1 << int(ETundraShapeshiftActiveShape::Small);
	default UsableByZoeShape |= 1 << int(ETundraShapeshiftActiveShape::Player);
	default UsableByZoeShape |= 1 << int(ETundraShapeshiftActiveShape::Big);

	UPROPERTY(EditAnywhere, Category = "One Shot Interaction")
	TPerPlayer<FTundraShapeshiftingOneShotShapeSettings> OneShotShapeSettings;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		auto Shapeshift = UTundraPlayerShapeshiftingComponent::Get(Query.Player);
		if(Shapeshift != nullptr)
		{
			ETundraShapeshiftActiveShape ShapeType = Shapeshift.GetActiveShapeType();
			if(!IsUsableByShape(Query.Player, ShapeType))
				return false;
		}

		return Super::CheckTargetable(Query);
	}

	FOneShotSettings GetOneShotSettingsForPlayer(AHazePlayerCharacter Player) const override
	{
		auto Shapeshift = UTundraPlayerShapeshiftingComponent::Get(Player);
		if(Shapeshift != nullptr)
		{
			ETundraShapeshiftActiveShape ShapeType = Shapeshift.GetActiveShapeType();
			if(ShapeType != ETundraShapeshiftActiveShape::Player)
				return OneShotShapeSettings[Player].GetSettingsForShape(ShapeType);
		}

		return Super::GetOneShotSettingsForPlayer(Player);
	}

	UHazeSkeletalMeshComponentBase GetMeshForPlayer(AHazePlayerCharacter Player) const override
	{
		auto Shapeshift = UTundraPlayerShapeshiftingComponent::Get(Player);
		if(Shapeshift != nullptr)
		{
			ETundraShapeshiftShape ShapeType = Shapeshift.GetCurrentShapeType();

			if(ShapeType != ETundraShapeshiftShape::Player && ShapeType != ETundraShapeshiftShape::None)
				return Shapeshift.GetShapeComponentForType(ShapeType).GetShapeMesh();
		}

		return Super::GetMeshForPlayer(Player);
	}

	bool IsUsableByShape(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape Shape) const
	{
		int BitWiseShape = 1 << Shape;
		int BitWiseUsableBy = Player.IsMio() ? UsableByMioShape : UsableByZoeShape;
		if((BitWiseShape & BitWiseUsableBy) == 0)
			return false;

		return true;
	}
}
class UTundraShapeshiftingInteractionComponent : UInteractionComponent
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

	bool IsUsableByShape(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape Shape) const
	{
		int BitWiseShape = 1 << Shape;
		int BitWiseUsableBy = Player.IsMio() ? UsableByMioShape : UsableByZoeShape;
		if((BitWiseShape & BitWiseUsableBy) == 0)
			return false;

		return true;
	}
}
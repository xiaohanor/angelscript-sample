
event void FPlayerShapeTriggerEvent(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape ShapeType);

/**
 * Trigger volume that tracks when players in a specific shape are inside it.
 */ 
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class ATundraShapeshiftingTriggerBox : APlayerTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(1.00, 0.82, 0.58));

	default PrimaryActorTick.bStartWithTickEnabled = false;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(EditAnywhere, Meta=(EditCondition = bTriggerForMio, Bitmask, BitmaskEnum="/Script/Angelscript.ETundraShapeshiftActiveShape"), Category = "Player Trigger")
	int TriggerForMioShape = 0; 
	default TriggerForMioShape |= 1 << int(ETundraShapeshiftActiveShape::Small);
	default TriggerForMioShape |= 1 << int(ETundraShapeshiftActiveShape::Player);
	default TriggerForMioShape |= 1 << int(ETundraShapeshiftActiveShape::Big);

	UPROPERTY(EditAnywhere, Meta=(EditCondition = bTriggerForZoe, Bitmask, BitmaskEnum="/Script/Angelscript.ETundraShapeshiftActiveShape"), Category = "Player Trigger")
	int TriggerForZoeShape = 0; 
	default TriggerForZoeShape |= 1 << int(ETundraShapeshiftActiveShape::Small);
	default TriggerForZoeShape |= 1 << int(ETundraShapeshiftActiveShape::Player);
	default TriggerForZoeShape |= 1 << int(ETundraShapeshiftActiveShape::Big);

	// Deprecated logic until moved over to 'TriggerFor'
	UPROPERTY(VisibleInstanceOnly, Category = "DEPRECATED")
	ETundraShapeshiftShape ShapeToTriggerFor = ETundraShapeshiftShape::Player;

	// Deprecated logic until moved over to 'TriggerFor'
	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "DEPRECATED")
	ETundraShapeshiftShape AlternativeShapeToTriggerFor = ETundraShapeshiftShape::None;

	// Called when a shape enters the volume, or the player switchers shape
	// 'OnPlayerEnter' is always called when the player enters the zone, no matter the shape
    UPROPERTY(Category = "Player Trigger")
    FPlayerShapeTriggerEvent OnShapeEnter;

	// Called when a shape exits the volume, or the player switchers shape
	// 'OnPlayerLeave' is always called when the player leaves the zone, no matter the shape
    UPROPERTY(Category = "Player Trigger")
    FPlayerShapeTriggerEvent OnShapeLeave;

	private TPerPlayer<ETundraShapeshiftActiveShape> PerPlayerDataShape;
	private TArray<AHazePlayerCharacter> ActivePlayers;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : ActivePlayers)
		{
			auto Shapeshift = UTundraPlayerShapeshiftingComponent::Get(Player);
			if(Shapeshift != nullptr)
			{
				const ETundraShapeshiftActiveShape NewShapeType = Shapeshift.GetActiveShapeType();
				const ETundraShapeshiftActiveShape OldShape = PerPlayerDataShape[Player];
				if(NewShapeType == OldShape)
					continue;

				PerPlayerDataShape[Player] = NewShapeType;
				
				if(IsShapeEnabledForPlayer(Player, OldShape))
				{
					if(bTriggerLocally)
						TriggerOnShapeLeave(Player, OldShape);
					else if(Player.HasControl())
						CrumbShapeLeave(Player, OldShape);
				}

				if(IsShapeEnabledForPlayer(Player, NewShapeType))
				{
					if(bTriggerLocally)
						TriggerOnShapeEnter(Player, NewShapeType);
					else if(Player.HasControl())
						CrumbShapeEnter(Player, NewShapeType);
				}
			}
		}
	}

	protected void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);
		
		ActivePlayers.AddUnique(Player);
		SetActorTickEnabled(true);

		auto Shapeshift = UTundraPlayerShapeshiftingComponent::Get(Player);
		if(Shapeshift != nullptr)
		{
			ETundraShapeshiftActiveShape ShapeType = Shapeshift.GetActiveShapeType();
			if(IsShapeEnabledForPlayer(Player, ShapeType))
			{
				if(bTriggerLocally)
					TriggerOnShapeEnter(Player, ShapeType);
				else if(Player.HasControl())
					CrumbShapeEnter(Player, ShapeType);
			}

			PerPlayerDataShape[Player] = ShapeType;
		}
	}

	protected void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);
		
		ActivePlayers.RemoveSingleSwap(Player);
		SetActorTickEnabled(ActivePlayers.Num() > 0);

		ETundraShapeshiftActiveShape ShapeType = PerPlayerDataShape[Player];
		if(IsShapeEnabledForPlayer(Player, ShapeType))
		{
			if(bTriggerLocally)
				TriggerOnShapeLeave(Player, ShapeType);
			else if(Player.HasControl())
				CrumbShapeLeave(Player, ShapeType);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbShapeEnter(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape Shape)
	{
		TriggerOnShapeEnter(Player, Shape);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbShapeLeave(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape Shape)
	{
		TriggerOnShapeLeave(Player, Shape);
	}

	protected void TriggerOnShapeEnter(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape Shape)
	{
		OnShapeEnter.Broadcast(Player, Shape);
	}

	protected void TriggerOnShapeLeave(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape Shape)
	{
		OnShapeLeave.Broadcast(Player, Shape);
	}

	bool IsShapeEnabledForPlayer(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape Shape) const
	{
		int ActiveShape = 1 << uint(Shape);
		if (Player.IsMio())
		{
			return TriggerForMioShape & ActiveShape != 0;
		}
		else
		{
			return TriggerForZoeShape & ActiveShape != 0;
		}
	}	
}

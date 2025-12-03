enum EIslandShieldotronScenepointShape
{
	Circle,
	Rectangle,
	None
}

UCLASS(HideCategories = "Physics Debug Activation Cooking Tags LOD Collision Rendering Actor")
class UIslandShieldotronScenepointComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Scenepoint")
	EIslandShieldotronScenepointShape Shape;
	default Shape = EIslandShieldotronScenepointShape::Circle;

	UPROPERTY(EditAnywhere, Category = "Scenepoint", meta = (EditCondition="Shape == EIslandShieldotronScenepointShape::Circle", EditConditionHides))
	float Radius = 64.0;

	UPROPERTY(EditAnywhere, Category = "Scenepoint", meta = (EditCondition="Shape == EIslandShieldotronScenepointShape::Rectangle", EditConditionHides))
	FVector Extents = FVector(64, 64, 0);

	// Cooldown for claiming this scenepoint as a user. Set when scenepoint is released.
	UPROPERTY(EditAnywhere, Category = "Scenepoint|Users")
	private float CooldownDuration = 0;

	// Currently not in use
	UPROPERTY(EditAnywhere, Category = "Scenepoint|Users")
	private int MaxNumberOfUsers = 1;

	// Currently not in use
	private TArray<AHazeActor> Users;

	// Currently not in use
	// Internal cooldown timestamp
	private float CooldownTime;

	// Multiplies the movement speed in shuffle movement
	UPROPERTY(EditAnywhere, Category = "Scenepoint|Movement")
	float MovementSpeedFactor = 1.0;
	
	// The max number of seconds to move
	UPROPERTY(EditAnywhere, Category = "Scenepoint|Movement")
	float MovementMaxDuration = 1.0;

	// The min distance to new destination point
	UPROPERTY(EditAnywhere, Category = "Scenepoint|Movement")
	float MovementMinDistance = 100.0;

	// The min number of seconds to wait before finding a new destination
	UPROPERTY(EditAnywhere, Category = "Scenepoint|Movement|Cooldown")
	float NextMoveCooldownRangeMin = 3.0;
	// The max number of seconds to wait before finding a new destination
	UPROPERTY(EditAnywhere, Category = "Scenepoint|Movement|Cooldown")
	float NextMoveCooldownRangeMax = 4.5;

	// Currently not in use
	void Use(AHazeActor Actor)
	{
		Users.AddUnique(Actor);
	}

	// Currently not in use
	bool IsUsing(AHazeActor Actor)
	{
		return Users.Contains(Actor);
	}

	// Currently not in use
	void Release(AHazeActor Actor)
	{
		if (!IsUsing(Actor))
			return;
		Users.Remove(Actor);
		CooldownTime = Time::GetGameTimeSeconds() + CooldownDuration;
	}

	// Currently not in use
	bool CanUse(AHazeActor Actor, bool bIgnoreCooldown = false) const
	{
		if(Users.Contains(Actor))
			return true;
		if(!bIgnoreCooldown && (Time::GameTimeSeconds < CooldownTime))
			return false;
		if(Users.Num() >= MaxNumberOfUsers)
			return false;

		return true;
	}

	UFUNCTION()
	bool IsAt(AHazeActor Actor, float PredictTime = 0.0) const
	{
		if (Actor == nullptr)
			return false;

		if (Shape == EIslandShieldotronScenepointShape::Circle)
		{
			if (Actor.ActorLocation.DistSquared(WorldLocation) < Math::Square(Radius))
				return true;
		}
		else if (Shape == EIslandShieldotronScenepointShape::Rectangle)
		{
			FHazeShapeSettings BoxShape = FHazeShapeSettings::MakeBox(FVector(Extents.X, Extents.Y, 400.0)); // Shape ought to be placed on ground. Sets arbitrary Z extent for checking actor location within extents.
			if (BoxShape.IsPointInside(WorldTransform, Actor.ActorLocation))
				return true;
		}


		if (PredictTime != 0.0) // Allow checking for overshoot with negative prediction time
		{
			FVector DeltaMove = Actor.GetActorVelocity() * PredictTime;
			FVector ToSP = WorldLocation - Actor.ActorLocation;
			if (ToSP.DotProduct(DeltaMove) > 0.0)
			{	
				// We're moving towards sp
				FVector PredictedToSP = (WorldLocation - (Actor.ActorLocation + DeltaMove));
				if (PredictedToSP.DotProduct(DeltaMove) < 0.0)	
				{
					// We will pass sp during predicted time
					return true;
				}
			}
		}

		return false;
	}

	// Checks for actor location within extended range. That is, Radius + Range or closest point on rectangle + Range.
	UFUNCTION()
	bool IsShapeWithinRange(AHazeActor Actor, float Range) const
	{
		if (Shape == EIslandShieldotronScenepointShape::Circle)
		{
			if (Actor.ActorLocation.DistSquared(WorldLocation) < Math::Square(Radius + Range))
				return true;
		}
		else if (Shape == EIslandShieldotronScenepointShape::Rectangle)
		{			
			FHazeShapeSettings BoxShape = FHazeShapeSettings::MakeBox(Extents);
			FVector ClosestPoint = BoxShape.GetClosestPointToPoint(WorldTransform, Actor.ActorLocation);
			if (Actor.ActorLocation.DistSquared(ClosestPoint) < Math::Square(Range))
			{
				//Debug::DrawDebugLine(Actor.ActorCenterLocation, ClosestPoint, FLinearColor::Green, Duration = 5.0);
				return true;
			}
			else			
			{
				//Debug::DrawDebugLine(Actor.ActorCenterLocation, ClosestPoint, FLinearColor::Gray, Duration = 5.0);
			}

		}
		return false;
	}

	// Returns 0.0 if Location is within the shape.
	float GetDist2DToShape(FVector Location)
	{
		if (Shape == EIslandShieldotronScenepointShape::Circle)
		{
			float Dist2D = (Location - WorldLocation).Size2D();
			float DistToShape = Math::Max(Dist2D - Radius, 0.0);
			return DistToShape;
		}
		else if (Shape == EIslandShieldotronScenepointShape::Rectangle)
		{
			FVector CompareLocation = Location; // Set Location to same vertical level as shape. Shape has no height, it is a rectangle.
			CompareLocation.Z = WorldLocation.Z;
			FHazeShapeSettings BoxShape = FHazeShapeSettings::MakeBox(Extents);
			if (BoxShape.IsPointInside(WorldTransform, CompareLocation))
				return 0.0;
			FVector ClosestPoint = BoxShape.GetClosestPointToPoint(WorldTransform, CompareLocation);
			float Dist2D = (Location - ClosestPoint).Size2D();
			float DistToShape = Math::Max(Dist2D, 0.0); // failsafe
			return DistToShape;

		}
		Error("Shape is not valid!");
		return BIG_NUMBER;
	}
}

namespace IslandShieldotronScenepointStatics 
{
	UIslandShieldotronScenepointComponent GetRandom(const TArray<UIslandShieldotronScenepointComponent>& Scenepoints)
	{
		if (Scenepoints.Num() == 0)
			return nullptr;

		int i = Math::RandRange(0, Scenepoints.Num() - 1);
		return Scenepoints[i];
	}

	UIslandShieldotronScenepointComponent GetRandomInView(const TArray<UIslandShieldotronScenepointComponent>& Scenepoints)
	{
		AHazePlayerCharacter Zoe = Game::GetZoe();
		AHazePlayerCharacter Mio = Game::GetMio();
		if ((Zoe != nullptr) && (Mio != nullptr))
		{
			// Get random point in any players view
			TArray<UIslandShieldotronScenepointComponent> OnScreenPoints;
			for (UIslandShieldotronScenepointComponent Scenepoint : Scenepoints)
			{
				if (Scenepoint == nullptr)
					continue;

				FVector Loc = Scenepoint.GetWorldLocation();
				if (SceneView::IsInView(Zoe, Loc) || SceneView::IsInView(Mio, Loc))
					OnScreenPoints.Add(Scenepoint);
			}
			if (OnScreenPoints.Num() > 0)
				return GetRandom(OnScreenPoints);
		}
		return nullptr;
	}	

}

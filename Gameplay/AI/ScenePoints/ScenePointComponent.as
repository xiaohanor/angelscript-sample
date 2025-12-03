UCLASS(HideCategories = "Physics Debug Activation Cooking Tags LOD Collision Rendering Actor")
class UScenepointComponent : USceneComponent
{
	default bUseAttachParentBound = true;

	UPROPERTY(EditAnywhere, Category = "Scenepoint")
	float Radius = 64.0;

	UPROPERTY(EditAnywhere, Category = "Scenepoint")
	float AlignAngleDegrees = 180.0;

	UPROPERTY(EditAnywhere, Category = "Scenepoint")
	float CooldownDuration = 0;

	UPROPERTY(EditAnywhere, Category = "Scenepoint")
	int MaxNumberOfUsers = 1;

	UPROPERTY()
	private TArray<AHazeActor> Users;

	private float CooldownTime;

	void Use(AHazeActor Actor)
	{
		Users.AddUnique(Actor);
	}

	bool IsUsing(AHazeActor Actor)
	{
		return Users.Contains(Actor);
	}

	void Release(AHazeActor Actor)
	{
		if (!IsUsing(Actor))
			return;
		Users.Remove(Actor);
		CooldownTime = Time::GetGameTimeSeconds() + CooldownDuration;
	}

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

	TArray<AHazeActor> GetUsers()
	{
		return Users;
	}

	UFUNCTION()
	bool IsAt(AHazeActor Actor, float PredictTime = 0.0) const
	{
		if (Actor == nullptr)
			return false;

		if (Actor.ActorLocation.DistSquared(WorldLocation) < Math::Square(Radius))
			return true;

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

	UFUNCTION()
	bool IsAlignedWith(AHazeActor Actor) const
	{
		if (Actor == nullptr)
			return false;

		// We only need to align yaw in actor space
		float YawDiff = WorldRotation.Yaw - Actor.ActorRotation.Yaw;
		if (!Actor.ActorUpVector.Equals(FVector::UpVector, 0.01))
		{
			// More expensive and uncommon case
			FRotator LocalScenepointRotation = Actor.ActorTransform.InverseTransformRotation(WorldRotation);
			YawDiff = LocalScenepointRotation.Yaw;		
		}
			
		if (Math::Abs(FRotator::NormalizeAxis(YawDiff)) < AlignAngleDegrees + KINDA_SMALL_NUMBER)
			return true;
		return false;
	}
}

namespace ScenepointStatics 
{
	UScenepointComponent GetRandom(const TArray<UScenepointComponent>& Scenepoints)
	{
		if (Scenepoints.Num() == 0)
			return nullptr;

		int i = Math::RandRange(0, Scenepoints.Num() - 1);
		return Scenepoints[i];
	}

	UScenepointComponent GetRandomInView(const TArray<UScenepointComponent>& Scenepoints)
	{
		AHazePlayerCharacter Zoe = Game::GetZoe();
		AHazePlayerCharacter Mio = Game::GetMio();
		if ((Zoe != nullptr) && (Mio != nullptr))
		{
			// Get random point in any players view
			TArray<UScenepointComponent> OnScreenPoints;
			for (UScenepointComponent Scenepoint : Scenepoints)
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

struct FScenepointContainer
{
	TArray<UScenepointComponent> Scenepoints;
	private TArray<UScenepointComponent> UnusedScenepoints;
	private UScenepointComponent LastUsedScenepoint = nullptr;

	void Reset()
	{
		UnusedScenepoints.Empty();
		LastUsedScenepoint = nullptr;
	}

	void UpdateUsedScenepoints()
	{
		if (UnusedScenepoints.Num() == 0)
		{
			UnusedScenepoints = Scenepoints; 
			if (UnusedScenepoints.Num() > 1)
				UnusedScenepoints.Remove(LastUsedScenepoint);
		}
	}
	void MarkScenepointUsed(UScenepointComponent Scenepoint)
	{
		UnusedScenepoints.Remove(Scenepoint);
		LastUsedScenepoint = Scenepoint;
	}

	UScenepointComponent UseBestScenepoint()
	{
		UpdateUsedScenepoints();
		UScenepointComponent Scenepoint = ScenepointStatics::GetRandomInView(UnusedScenepoints);
		if (Scenepoint == nullptr)
			Scenepoint = ScenepointStatics::GetRandom(UnusedScenepoints);
		MarkScenepointUsed(Scenepoint);
		return Scenepoint;
	}	

	UScenepointComponent UseRandomInViewScenepoint()
	{
		UpdateUsedScenepoints();
		UScenepointComponent Scenepoint = ScenepointStatics::GetRandomInView(UnusedScenepoints);
		if (Scenepoint == nullptr)
			Scenepoint = ScenepointStatics::GetRandom(UnusedScenepoints);
		MarkScenepointUsed(Scenepoint);
		return Scenepoint;
	}	

	UScenepointComponent UseRandomScenepoint()
	{
		UpdateUsedScenepoints();
		UScenepointComponent Scenepoint = ScenepointStatics::GetRandom(UnusedScenepoints);
		MarkScenepointUsed(Scenepoint);
		return Scenepoint;
	}

	UScenepointComponent UseNextScenepoint()
	{
		UpdateUsedScenepoints();
		UScenepointComponent Scenepoint = UnusedScenepoints[0];
		if (Scenepoint == nullptr)
			Scenepoint = ScenepointStatics::GetRandom(UnusedScenepoints);
		MarkScenepointUsed(Scenepoint);
		return Scenepoint;
	}
}

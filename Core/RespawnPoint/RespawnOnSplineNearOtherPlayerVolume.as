/**
 * While a player is inside this volume, when they die they will respawn at the closest position
 * to the _other_ player on the specified spline.
 */
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class ARespawnOnSplineNearOtherPlayerVolume : APlayerTrigger
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(0.0, 1.0, 0.8, 1.0));
	default bTriggerLocally = true;

    /* Spline to respawn on */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Respawn")
    AHazeActor SplineActor;

    /**
	 * Optional additional splines to respawn on.
	 * If supplied, the closest one of SplineActor and AdditionalSplines to the other player will be used.
	 */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Respawn")
	TArray<AHazeActor> AdditionalSplines;

    /* If set, the respawning player will gain the same speed as the other player has, along the spline. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Respawn")
    bool bMatchOtherPlayerSpeedOnRespawn = false;

    /* The player will be given this speed along the spline when they respawn. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Respawn", Meta = (EditConditionHides, EditCondition = "!bMatchOtherPlayerSpeedOnRespawn"))
    float RespawnWithSpeed = 0.0;

	private TArray<UHazeSplineComponent> Splines;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Splines.Reserve(1 + AdditionalSplines.Num());

		const UHazeSplineComponent Spline = Spline::GetGameplaySpline(SplineActor);
		if(Spline != nullptr)
			Splines.Add(Spline);

		for(int i = 0; i < AdditionalSplines.Num(); i++)
		{
			Spline = Spline::GetGameplaySpline(AdditionalSplines[i]);
			if(Spline != nullptr)
				Splines.Add(Spline);
		}
	}

    void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
    {
		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"HandleRespawn");
		Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverride);
    }

    void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
    {
		Player.ClearRespawnPointOverride(this);
    }

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutResult)
	{
		UHazeSplineComponent SplineComp = GetRespawnSpline(Player);
		if (SplineComp == nullptr)
		{
			devError("No spline specified to respawn on for RespawnOnSplineNearOtherPlayerVolume");
			return false;
		}

		OutResult.RespawnPoint = nullptr;
		OutResult.RespawnRelativeTo = nullptr;
		OutResult.RespawnTransform = SplineComp.GetClosestSplineWorldTransformToWorldLocation(Player.OtherPlayer.ActorLocation);
		OutResult.bRecalculateOnRespawnTriggered = true;

		if (bMatchOtherPlayerSpeedOnRespawn)
			OutResult.RespawnWithVelocity = OutResult.RespawnTransform.Rotation.ForwardVector * Player.OtherPlayer.ActorVelocity.Size();
		else 
			OutResult.RespawnWithVelocity = OutResult.RespawnTransform.Rotation.ForwardVector * RespawnWithSpeed;

		return true;
	}

	UHazeSplineComponent GetRespawnSpline(AHazePlayerCharacter Player) const
	{
		if(Splines.Num() == 1)
		{
			return Splines[0];
		}
		else
		{
			FVector OtherPlayerLocation = Player.OtherPlayer.ActorLocation;
			int ClosestIndex = -1;
			float ClosestDistance = BIG_NUMBER;

			for(int i = 0; i < Splines.Num(); i++)
			{
				auto Spline = Splines[i];
				if(Spline == nullptr)
					continue;

				const float Distance = Spline.GetClosestSplineWorldLocationToWorldLocation(OtherPlayerLocation).DistSquared(OtherPlayerLocation);
				if(Distance < ClosestDistance)
				{
					ClosestIndex = i;
					ClosestDistance = Distance;
				}
			}

			if(ClosestIndex < 0)
				return nullptr;

			return Splines[ClosestIndex];
		}
	}
};
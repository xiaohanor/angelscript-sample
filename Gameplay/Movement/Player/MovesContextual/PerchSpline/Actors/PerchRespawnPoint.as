class APerchRespawnPoint : ARespawnPoint
{
	default bSnapToGround = false;
	default SecondPosition.Location = FVector(0.0, 100.0, 0.0);
	
	UPROPERTY(EditInstanceOnly, Category = "Respawn Point")
	AActor TargetPerchActor;

	UPROPERTY(EditInstanceOnly, Category = "Respawn Point" , Meta = (EditCondition = "bTargetPointHasSpline", EditConditionHides, ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0" , Delta = 0.05))
	bool bSnapToClosestPoint = true;

	UPROPERTY(EditInstanceOnly, Category = "Respawn Point" , Meta = (EditCondition = "bTargetPointHasSpline && !bSnapToClosestPoint", EditConditionHides, ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0" , Delta = 0.05))
	float SplineFraction = 0;

	UPROPERTY()
	private bool bTargetPointHasSpline = false;

	private UPerchPointComponent TargetPerchPoint;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();

		if(TargetPerchActor != nullptr)
		{
			UPerchPointComponent PerchPointComp = UPerchPointComponent::Get(TargetPerchActor);

			if(PerchPointComp == nullptr)
			{
				devErrorAlways("No PerchPointComponent found on actor");
				TargetPerchActor = nullptr;
				TargetPerchPoint = nullptr;
			}
			else
			{
				TargetPerchPoint = PerchPointComp;

				if(!PerchPointComp.bHasConnectedSpline)
				{
					bTargetPointHasSpline = false;
					SetActorLocation(PerchPointComp.WorldLocation);
				}
				else
				{
					bTargetPointHasSpline = true;
					
					FVector TargetLocation;
					if (bSnapToClosestPoint)
					{
						TargetLocation = PerchPointComp.ConnectedSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation).Location;
					}
					else
					{
						TargetLocation = PerchPointComp.ConnectedSpline.Spline.GetWorldLocationAtSplineFraction(SplineFraction);
					}
					SetActorLocation(TargetLocation);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UPerchPointComponent PerchPointComp = UPerchPointComponent::Get(TargetPerchActor);
		TargetPerchPoint = PerchPointComp;

		OnPlayerTeleportToRespawnPoint.AddUFunction(this, n"OnTeleportedToRespawnPoint");
	}

	FTransform GetPositionForPlayer(AHazePlayerCharacter Player) const override
	{
		return FTransform::Identity * Root.WorldTransform;
	}

	FTransform GetRelativePositionForPlayer(AHazePlayerCharacter Player) const override
	{
		return FTransform::Identity;
	}

	UFUNCTION()
	private void OnTeleportedToRespawnPoint(AHazePlayerCharacter TeleportingPlayer)
	{
		if(TargetPerchPoint == nullptr)
			return;
		
		if(TargetPerchPoint.bHasConnectedSpline)
		{
			APerchSpline TargetSpline = TargetPerchPoint.ConnectedSpline;
			FVector Location = TargetSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation);
			if (TeleportingPlayer.IsZoe() && bCanMioUse)
				Location = TargetSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorTransform.TransformPosition(SecondPosition.Location));

			float Fraction = TargetSpline.Spline.GetClosestSplineDistanceToWorldLocation(Location)/TargetSpline.Spline.SplineLength;
			UPlayerPerchComponent::Get(TeleportingPlayer).StartPerchingOnSplineFraction(TargetPerchPoint, Fraction);
		}
		else
		{
			UPlayerPerchComponent::Get(TeleportingPlayer).StartPerching(TargetPerchPoint, true);
		}
	}

	void OnRespawnTriggered(AHazePlayerCharacter Player) override
	{
		if(TargetPerchPoint == nullptr)
			return;

		if(TargetPerchPoint.bHasConnectedSpline)
		{
			APerchSpline TargetSpline = TargetPerchPoint.ConnectedSpline;
			FVector Location = TargetSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation);
			if (Player.IsZoe() && bCanMioUse)
				Location = TargetSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorTransform.TransformPosition(SecondPosition.Location));

			float Fraction = TargetSpline.Spline.GetClosestSplineDistanceToWorldLocation(Location)/TargetSpline.Spline.SplineLength;
			UPlayerPerchComponent::Get(Player).StartPerchingOnSplineFraction(TargetPerchPoint, Fraction);
		}
		else
		{
			UPlayerPerchComponent::Get(Player).StartPerching(TargetPerchPoint, true);
		}

		Super::OnRespawnTriggered(Player);
	}
};
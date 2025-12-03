
class ACoastTrainRoofGrapplePoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UGrapplePointComponent GrappleCompMio;

	UPROPERTY(DefaultComponent)
	UGrapplePointComponent GrappleCompZoe;

	UPROPERTY(DefaultComponent)
	UCoastTrainCartBasedDisableComponent CartDisableComp;
	default CartDisableComp.bAutoDisable = true;
	default CartDisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditAnywhere)
	float MaxOffset = 1500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrappleCompMio.Disable(this);
		GrappleCompZoe.Disable(this);
		
		//Snap to a good position
		CalculateForPlayer(Game::GetZoe(), GrappleCompZoe, 1, false);
		CalculateForPlayer(Game::GetMio(), GrappleCompMio, 1, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CalculateForPlayer(Game::GetZoe(), GrappleCompZoe, DeltaSeconds, true);
		CalculateForPlayer(Game::GetMio(), GrappleCompMio, DeltaSeconds, true);
	}


	void CalculateForPlayer(AHazePlayerCharacter Player, UGrapplePointComponent GrappleComp, float Delta, bool Interpolate)
	{
		FVector PlayerLocation = Player.ActorLocation;
		FVector DirectionToPlayer = PlayerLocation - GrappleComp.WorldLocation;

		float DotProduct = DirectionToPlayer.DotProduct(GrappleComp.GetRightVector());

		if (DotProduct <= -10.0)
		{
			// Debug::DrawDebugArrow(GrappleComp.WorldLocation, PlayerLocation);
			GrappleComp.EnableForPlayer(Player, this);
		}
		else
		{
			GrappleComp.DisableForPlayer(Player, this);
		}

		if (!Player.IsAnyCapabilityActive(n"GrappleMovement"))
		{
			FVector NearestPointOnLine1 = FVector::ZeroVector;
			FVector NearestPointOnLine2 = FVector::ZeroVector;
			FVector Line1Start = Player.ViewLocation;
			FVector Line1End = Line1Start + Player.ViewRotation.ForwardVector * 15000.0;
			FVector Line2Start = Spline.GetWorldLocationAtSplineDistance(0.0);
			FVector Line2End = Spline.GetWorldLocationAtSplineDistance(Spline.SplineLength);

			Math::FindNearestPointsOnLineSegments(Line1Start, Line1End, Line2Start, Line2End, NearestPointOnLine1, NearestPointOnLine2);
			
			
			float SplineDistancePlayer = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
			float SplineDistanceGrapplePoint = Spline.GetClosestSplineDistanceToWorldLocation(NearestPointOnLine2);
			float TotalSplineDistance = Spline.SplineLength;

			float LengthBetweenPoints = SplineDistanceGrapplePoint - SplineDistancePlayer;

			LengthBetweenPoints = Math::Clamp(LengthBetweenPoints, -MaxOffset, MaxOffset);

			float FinalDistance = SplineDistancePlayer + LengthBetweenPoints;

			FVector TargetLocation = Spline.GetWorldLocationAtSplineDistance(FinalDistance);

			FVector FinalLocation = TargetLocation;

			if (Interpolate)
				FinalLocation = Math::VInterpTo(GrappleComp.WorldLocation, TargetLocation, Delta, 6.0);

			GrappleComp.SetWorldLocation(FinalLocation);

			// // Debug stuff:
			// Debug::DrawDebugLine(Line1Start, Line1End, LineColor = FLinearColor::Red);
			// Debug::DrawDebugLine(Line2Start, Line2End, FLinearColor::Red);
			// Debug::DrawDebugSphere(TargetLocation, 60.0);
			// Debug::DrawDebugSphere(FinalLocation, 60.0, LineColor = FLinearColor::Red);
		}
	}
}
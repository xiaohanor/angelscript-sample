
/**
 * Respawn point that should be attached to a train cart, will automatically activate
 * once a player reaches past this part of the train.
 */
class ACoastTrainRespawnPoint : ARespawnPoint
{
	ACoastTrainCart AttachedToCart;

	// We count as having reached the point when within this distance along the cart from it
	UPROPERTY(EditAnywhere, Category = "Respawn")
	float ReachPointThreshold = 0.0;

	// Don't allow respawning here if the player's world up differs more than this angle from the respawn point's upvector
	UPROPERTY(EditAnywhere, Category = "Respawn")
	float MaximumUsableAngle = 20.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UCoastTrainRespawnPointDummyVisualizationComponent DummyVisComp;
#endif	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Register ourselves to the train cart we're attached to
		AActor AttachActor = GetAttachParentActor();
		while (AttachActor != nullptr)
		{
			auto Cart = Cast<ACoastTrainCart>(AttachActor);
			if (Cart != nullptr)
			{
				AttachedToCart = Cart;
				AttachedToCart.RespawnPoints.Add(this);
				break;
			}

			AttachActor = AttachActor.GetAttachParentActor();
		}
	}

	bool IsValidToRespawn(AHazePlayerCharacter Player) const override
	{
		FVector UpVectorToTest;
		if (AttachedToCart != nullptr)
		{
			FQuat SpinRotation = AttachedToCart.GetPredictedRotation(1.0);
			UpVectorToTest = SpinRotation.RotateVector(
				AttachedToCart.ActorQuat.UnrotateVector(
					ActorUpVector
				)
			);
		}
		else
		{
			UpVectorToTest = ActorUpVector;
		}

		if(UpVectorToTest.DotProduct(Player.MovementWorldUp) < 0.0)
			return false;

		float Angle = UpVectorToTest.GetAngleDegreesTo(Player.MovementWorldUp);

		if (Angle > MaximumUsableAngle)
			return false;
		else
			return true;
	}
};

#if EDITOR
class UCoastTrainRespawnPointDummyVisualizationComponent : UActorComponent 
{
}

class UCoastTrainRespawnPointVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCoastTrainRespawnPointDummyVisualizationComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		ACoastTrainRespawnPoint RespawnPoint = Cast<ACoastTrainRespawnPoint>(Component.Owner);
		FVector PointLoc = RespawnPoint.ActorLocation + RespawnPoint.ActorUpVector * 40.0;
		AActor TrainCart = RespawnPoint.AttachParentActor;
		if (TrainCart == nullptr)
		{
			DrawWorldString("Train respawn point needs to be attached to a train cart!", RespawnPoint.ActorLocation, FLinearColor::Red, 3.0);
			return;
		}

		FVector TrainCartSide = TrainCart.ActorRightVector * 1000.0;
		FVector ThresholdLoc = PointLoc - TrainCart.ActorForwardVector * RespawnPoint.ReachPointThreshold;
		if (RespawnPoint.ReachPointThreshold < 0.0)
		{
			// We need to pass some ways beyond respawn point before it will be used
			DrawDashedLine(ThresholdLoc - TrainCartSide, ThresholdLoc + TrainCartSide, FLinearColor::Green, 10.0, 3.0);
			DrawDashedLine(PointLoc, ThresholdLoc, FLinearColor::Red, 10.0, 3.0);
		}
		else
		{
			// Normal case
			DrawDashedLine(PointLoc - TrainCartSide, PointLoc + TrainCartSide, FLinearColor::Green, 10.0, 3.0);
			if (RespawnPoint.ReachPointThreshold > 0.0)
			{
				DrawDashedLine(ThresholdLoc - TrainCartSide, ThresholdLoc + TrainCartSide, FLinearColor::Green, 10.0, 3.0);
				DrawDashedLine(ThresholdLoc - TrainCartSide, PointLoc - TrainCartSide, FLinearColor::Green, 10.0, 3.0);
				DrawDashedLine(ThresholdLoc + TrainCartSide, PointLoc + TrainCartSide, FLinearColor::Green, 10.0, 3.0);
			}
		}
	}
}
#endif
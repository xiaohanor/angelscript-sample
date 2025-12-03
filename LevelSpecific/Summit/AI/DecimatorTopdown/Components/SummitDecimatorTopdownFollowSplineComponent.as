class USummitDecimatorTopdownFollowSplineComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly, Category = "Spline")
	ASplineActor Spline;

	TPerPlayer<FVector> PlayerMovementInput;
	TPerPlayer<FVector2D> PlayerRawInput;
	TPerPlayer<bool> HasBit;
}
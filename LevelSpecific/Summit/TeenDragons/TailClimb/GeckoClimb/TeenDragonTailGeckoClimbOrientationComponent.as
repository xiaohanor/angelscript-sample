class UTeenDragonTailGeckoClimbOrientationComponent : USceneComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DetachFromParent();
	}

	void SetOrientationAlongWall(FVector ClimbUp)
	{
		FVector Normal = ClimbUp;
		FVector HorizontalToWall = ClimbUp.CrossProduct(FVector::UpVector);
		FVector VerticalToWall = HorizontalToWall.CrossProduct(Normal);
		FRotator WallRotation = FRotator::MakeFromXZ(VerticalToWall, ClimbUp);
		WorldRotation = WallRotation;
	}
};
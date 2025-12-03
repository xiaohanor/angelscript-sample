event void FOnSanctuarySnakeShoot();

class USanctuarySnakeComponent : UActorComponent
{
	FVector WorldUp = FVector::UpVector;

	UPROPERTY()
	TSubclassOf<USanctuarySnakeTailSegmentComponent> SegmentClass;

//	UPROPERTY()
//	float SnakeLength = 0.0;

	UPROPERTY()
	bool bHasRider = false;

	UPROPERTY()
	bool bFollowTarget = false;

	UPROPERTY()
	bool bBurrow = false;

	UPROPERTY()
	bool bSelfCollision = false;

	UPROPERTY()
	AActor Target;

	UPROPERTY()
	FOnSanctuarySnakeShoot OnShoot;

	UPROPERTY()
	bool bShootAttack = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	PrintScaled("Burrow: " + bBurrow, 0.0);
	}
}
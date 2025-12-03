class USketchbookSmoothFollowComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	const float FollowSpeed = 100;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetAbsolute(true);
		SetWorldLocation(AttachParent.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetWorldLocation(Math::VInterpConstantTo(WorldLocation, AttachParent.WorldLocation, DeltaSeconds, FollowSpeed));
	}
};
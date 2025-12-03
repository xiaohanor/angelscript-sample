class ASoftSplitRotatingDoubleObstacle : AWorldLinkDoubleActor
{

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent Rotator;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		Super::BeginPlay();
	}
};
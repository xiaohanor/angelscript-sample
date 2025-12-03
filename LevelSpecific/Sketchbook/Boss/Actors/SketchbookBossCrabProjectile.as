UCLASS(Abstract)
class ASketchbookBossCrabProjectile : ASketchbookBossProjectile
{
	FVector TargetLaneLocation;
	FVector TargetOffscreenLocation;
	private const float TravelSpeed = 500;
	bool bReachedLane = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		FVector NewLocation;
		
		if(!bReachedLane)
		{
			NewLocation = Math::VInterpConstantTo(ActorLocation, TargetLaneLocation, DeltaSeconds, TravelSpeed * 2);
			if(Math::Abs(ActorLocation.Z - TargetLaneLocation.Z) < KINDA_SMALL_NUMBER)
				bReachedLane = true;
		}
		else
		{
			if(ActorLocation.Distance(TargetOffscreenLocation) < KINDA_SMALL_NUMBER)
				DestroyActor();

			NewLocation = Math::VInterpConstantTo(ActorLocation, TargetOffscreenLocation, DeltaSeconds, TravelSpeed);
		}

		SetActorLocation(NewLocation);
	}
};
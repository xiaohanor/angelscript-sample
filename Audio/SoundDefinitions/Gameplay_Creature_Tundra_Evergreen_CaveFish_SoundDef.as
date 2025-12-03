
UCLASS(Abstract)
class UGameplay_Creature_Tundra_Evergreen_CaveFish_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnBite(){}

	UFUNCTION(BlueprintEvent)
	void OnStopChase(){}

	UFUNCTION(BlueprintEvent)
	void OnStartChase(){}

	UFUNCTION(BlueprintEvent)
	void OnStopPatrol(){}

	UFUNCTION(BlueprintEvent)
	void OnStartPatrol(){}

	/* END OF AUTO-GENERATED CODE */

	AAITundraChasingFishie CaveFish;
	private FVector PreviousTailLocation;
	private FVector PreviousFishLocation;
	
	private float MIN_TAIL_SPEED = 600;
	private float MAX_TAIL_SPEED = 800;
	private float CachedTailSpeed = 0.0;

	FVector GetTailFinLocation() const property
	{
		return CaveFish.Mesh.GetSocketLocation(n"Tail8");
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		CaveFish = Cast<AAITundraChasingFishie>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector FinLocation = TailFinLocation;
		const FVector FishLocation = HazeOwner.GetActorLocation();

		const FVector Velo = FinLocation - PreviousTailLocation;	

		const float TailSpeed = Velo.Size() / DeltaSeconds;
		CachedTailSpeed = Math::GetMappedRangeValueClamped(FVector2D(MIN_TAIL_SPEED, MAX_TAIL_SPEED), FVector2D(0.0, 1.0), TailSpeed);		

		PreviousTailLocation = FinLocation;
		PreviousFishLocation = FishLocation;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Tail Speed"))
	float GetTailSpeed()
	{
		return CachedTailSpeed;
	}
}
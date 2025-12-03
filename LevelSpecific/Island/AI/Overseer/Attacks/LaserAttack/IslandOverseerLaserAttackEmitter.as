class UIslandOverseerLaserAttackEmitter : USceneComponent
{
	UPROPERTY()
	bool bLeft;
	UPROPERTY()
	FVector TrailStart;
	UPROPERTY()
	FVector InitialTrailLocal;
	UPROPERTY()
	FVector TrailEnd;
	UPROPERTY()
	FVector ImpactLocation;
	UPROPERTY()
	AHazePlayerCharacter Target;
	UPROPERTY()
	float BeamWidth;

	bool bActive;
	bool bPassedTarget;
	FHazeAcceleratedFloat AccBeamWidth;
	FVector Direction;
	FVector EndLocation;
	float Distance;
	float Sine;
	UTargetTrailComponent TargetTrail;
	float UpdateWidthTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
}
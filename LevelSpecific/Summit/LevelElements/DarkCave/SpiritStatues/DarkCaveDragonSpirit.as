event void FOnDarkCaveDragonSpiritReachedEnd();

class ADarkCaveDragonSpirit : AHazeActor
{
	FOnDarkCaveDragonSpiritReachedEnd OnDarkCaveDragonSpiritReachedEnd;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent TrailEffect;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"DarkCaveSpiritStatueCompleteCapability");


	float MoveSpeed = 8000.0;

	ASplineActor SplineActor;
	ADarkCaveDragonOrnament TargetDragonOrnament;
	ADarkCaveSpiritStatue OwningStatue;

	bool bSpiritCompletedJourney;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
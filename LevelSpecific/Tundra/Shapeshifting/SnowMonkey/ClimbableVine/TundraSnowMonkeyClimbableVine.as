UCLASS(Abstract)
class ATundraPlayerSnowMonkeyClimbableVine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraSnowMonkeyClimbableVineCableComponent CableComp;
	default CableComp.bAttachEnd = false;
	default CableComp.NumSegments = 20;
	default CableComp.SolverIterations = 3;
	default CableComp.CableWidth = 30.0;

	default CableComp.CableGravityScale = 5.0;
	default CableComp.CableFriction = 1.4;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	// 3466 is the width of the viewport in evergreen sidescroller, make the disable range 50% larger than that distance.
	default DisableComp.AutoDisableRange = 3466.0 * 1.5;

	UPROPERTY(EditAnywhere)
	float Length = 3500.0;

	/* How much downwards force to apply to the bottom most particle */
	UPROPERTY(EditAnywhere)
	float BottomGravityForce = 1000.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CableComp.CableLength = Length;
		CableComp.EndLocation = FVector(0.0, 0.0, -Length);
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CableComp.Particles[CableComp.Particles.Num() - 1].Force = FVector::DownVector * BottomGravityForce;
	}
}
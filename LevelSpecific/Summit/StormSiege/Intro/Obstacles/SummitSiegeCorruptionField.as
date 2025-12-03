#if EDITOR
class USummitSiegeCorruptionVisualizerComponent : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USummitSiegeCorruptionDudComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        USummitSiegeCorruptionDudComponent Comp = Cast<USummitSiegeCorruptionDudComponent>(Component);

        if (Comp == nullptr)
            return;

		ASummitSiegeCorruptionField CorruptionField = Cast<ASummitSiegeCorruptionField>(Comp.Owner);
		
		if (CorruptionField == nullptr)
            return;
		
		SetRenderForeground(false);
        DrawWireSphere(CorruptionField.ActorLocation, CorruptionField.DeathRadius, FLinearColor::Red, 10.0, 16.0);
        DrawWireSphere(CorruptionField.ActorLocation, CorruptionField.FloatRadius + CorruptionField.DeathRadius, FLinearColor::Green, 10.0, 16.0);
    }   
}
#endif

class USummitSiegeCorruptionDudComponent : USceneComponent
{

}

class ASummitSiegeCorruptionField : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USummitSiegeCorruptionDudComponent VisualizerDudComp;

	UPROPERTY(EditAnywhere)
	float DeathRadius = 1270.0;

	UPROPERTY(EditAnywhere)
	float FloatRadius = 1700.0;

	float MinDistance = 15.0;

	FVector StartLoc;
	FVector NextLoc;
	FHazeAcceleratedVector AccelVec;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = ActorLocation;
		SetRandomFloatLocation();
		AccelVec.SnapTo(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if ((NextLoc - ActorLocation).Size() < MinDistance)
			SetRandomFloatLocation();

		AccelVec.AccelerateTo(NextLoc, 7.0, DeltaSeconds);
		ActorLocation = AccelVec.Value;
	}

	void SetRandomFloatLocation()
	{
		float HalfRadius = FloatRadius / 2.0;
		FVector RandomOffset = FVector(Math::RandRange(-HalfRadius, HalfRadius), Math::RandRange(-HalfRadius, HalfRadius), Math::RandRange(-HalfRadius, HalfRadius));
		NextLoc = StartLoc + RandomOffset;
	}
}
UCLASS(NotBlueprintable)
class ADesertDistanceFromVortexCenter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDesertDistanceFromVortexCenterComponent DistanceComp;

	float InitialHeight;

	#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.SpriteName = "AutoAimTarget";
	default BillboardComp.WorldScale3D = FVector(20);
	#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialHeight = ActorLocation.Z;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Location = DistanceComp.CalculateLocation();
        Location.Z = InitialHeight;
        SetActorLocation(Location);
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	private void SnapToSpline()
	{
		DistanceComp.Initialize();
		float Height = ActorLocation.Z;
		FVector SnapLocation = DistanceComp.CalculateLocation();
		SnapLocation.Z = Height;

		FVector Offset = SnapLocation - ActorLocation;

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false, false);
		for(auto AttachedActor : AttachedActors)
		{
			AttachedActor.AddActorWorldOffset(-Offset);
		}

		SetActorLocation(SnapLocation);
	}
#endif
};
class ANightQueenShieldRotator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;

	UPROPERTY()
	TSubclassOf<ANightQueenShield> ShieldClass;

	UPROPERTY(EditAnywhere)
	float Size = 500.0;
	float MinSize = 400.0;

	TArray<UShieldSpawnPoint> SpawnPoints;

	float RotSpeed = 15.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(SpawnPoints);

		for (UShieldSpawnPoint Point : SpawnPoints)
		{
			FVector SpawnDirection = (Point.WorldLocation - ActorLocation).GetSafeNormal();
			FVector SpawnLoc = ActorLocation + SpawnDirection * Size;
			ANightQueenShield Shield = SpawnActor(ShieldClass, SpawnLoc);
			Shield.ActorRotation = SpawnDirection.ToOrientationRotator();
			Shield.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			float ScaleUp = Size / MinSize;
			Shield.SetActorScale3D(FVector(ScaleUp));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Root.AddRelativeRotation(FRotator(0.0, RotSpeed * DeltaSeconds, 0.0));
	}
}

class UShieldSpawnPoint : USceneComponent
{

}
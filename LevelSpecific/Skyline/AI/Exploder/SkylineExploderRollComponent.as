class USkylineExploderRollComponent : UActorComponent
{
	AAISkylineExploder Exploder;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Exploder = Cast<AAISkylineExploder>(Owner);
	}

	void MoveRotation(float Speed)
	{
		Exploder.Mesh.AddLocalRotation(FRotator(-Speed, 0, 0));
	}
}